use strict;
use warnings;
use Test::More;

# Offline unit test for _transform_sql: the translation of SQL-standard '?'
# placeholders into PostgreSQL positional '$N' placeholders that libpq
# (EV::Pg->query_params) requires. No database needed.
#
# WHY this matters: the shared DBIO::PostgreSQL::SQLMaker emits '?' (needed by
# the sync DBI driver). libpq does not understand '?'. If the async CRUD path
# fed '?' straight to query_params, every bound WHERE/SET/VALUES would die with
# a PostgreSQL syntax error. These cases pin down the exact '?' shapes the maker
# can emit and prove each is translated correctly -- and, just as important,
# that the jsonpath operator the maker writes as '@\?' reaches the server as
# '@?' and that a '?' inside a string literal stays text.

use DBIO::PostgreSQL::EV::Storage;

my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
my $sm      = $storage->sql_maker;

# Helper: round-trip a maker call through the translator.
sub xlate {
  my (@maker_args) = @_;
  my ($sql) = $sm->select(@maker_args);
  return $storage->_transform_sql($sql);
}

# (a) simple WHERE with multiple binds -> $1, $2 numbered left-to-right.
{
  my ($sql) = $sm->select('artist', ['name'], { id => 1, name => 'Miles' });
  my $pos = $storage->_transform_sql($sql);
  unlike $pos, qr/\?/, 'no bare ? left after translation (multi-bind WHERE)';
  like $pos, qr/\$1\b/, 'first placeholder is $1';
  like $pos, qr/\$2\b/, 'second placeholder is $2';
  # numbering follows left-to-right ? order, matching the maker's @bind order
  ok index($pos, '$1') < index($pos, '$2'),
    '$1 appears before $2 (left-to-right numbering)';
}

# insert / update / delete also translate cleanly.
{
  my ($sql) = $sm->insert('artist', { id => 2, name => 'X' });
  my $pos = $storage->_transform_sql($sql);
  is $pos, 'INSERT INTO "artist" ("id", "name") VALUES ($1, $2)',
    'INSERT VALUES placeholders -> $1, $2';
}
{
  my ($sql) = $sm->update('artist', { name => 'Y' }, { id => 3 });
  my $pos = $storage->_transform_sql($sql);
  is $pos, 'UPDATE "artist" SET "name" = $1 WHERE "id" = $2',
    'UPDATE SET + WHERE placeholders numbered across the whole statement';
}
{
  my ($sql) = $sm->delete('artist', { id => 4 });
  my $pos = $storage->_transform_sql($sql);
  is $pos, 'DELETE FROM "artist" WHERE "id" = $1', 'DELETE WHERE -> $1';
}

# IN list -> one $N per element.
{
  my $pos = xlate('artist', ['name'], { id => { -in => [1, 2, 3] } });
  like $pos, qr/IN \( \$1, \$2, \$3 \)/, 'IN list -> $1, $2, $3';
}

# (b) the jsonpath operator: the maker writes it '@\?', the server gets '@?'
# without the backslash; its '?::jsonpath' placeholder -> $N.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@?' => '$.status == "active"' } });
  like $pos, qr/\@\? \$1::jsonpath/,
    '@? reaches the server as @? while its placeholder becomes $1::jsonpath';
  unlike $pos, qr/\@\$/, 'the ? of the operator was NOT numbered into @$';
  unlike $pos, qr/\\/, 'no backslash is left for the server';
}

# The jsonpath operator plus a separate bound column: '@?' for the server, both
# real placeholders numbered left-to-right.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@?' => '$.x' }, id => 7 });
  like $pos, qr/\@\? \$\d+::jsonpath/, '@? reaches the server as @? alongside a bound column';
  like $pos, qr/"id" = \$1/, 'bound column id = $1 (leftmost placeholder)';
  like $pos, qr/\@\? \$2::jsonpath/, 'jsonpath placeholder numbered $2';
}

# '@@' jsonpath match: no '?' in the operator, only the real placeholder.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@@' => '$.score > 10' } });
  like $pos, qr/\@\@ \$1::jsonpath/, '@@ operator + $1::jsonpath placeholder';
}

# (c) col \?| ARRAY[?, ?] -> ARRAY[$1, $2]; each gets its own $N, the operator's
# backslash-?  is no placeholder and reaches the server as a bare ?.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?|' => ['email', 'phone'] } });
  like $pos, qr/"me"\."data" \?\| ARRAY\[\$1, \$2\]/,
    '\?| ARRAY[?, ?] -> ?| ARRAY[$1, $2]';
}
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?&' => ['name', 'email'] } });
  like $pos, qr/"me"\."data" \?& ARRAY\[\$1, \$2\]/,
    '\?& ARRAY[?, ?] -> ?& ARRAY[$1, $2]';
}

# the single-key operator \? -> $1.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?' => 'email' } });
  like $pos, qr/"me"\."data" \? \$1/, '\? ? -> ? $1';
}

# (e) '?::jsonb' cast (from @>) -> $N::jsonb.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@>' => { status => 'active' } } });
  like $pos, qr/\@> \$1::jsonb/, '@> ?::jsonb cast -> $1::jsonb';
}

# (d) a single-quoted literal containing a literal '?' is left untouched while
# a real placeholder beside it is still translated. This is the corruption case
# the translator must defend against: an inlined literal like 'what?' must not
# steal a placeholder number, and a real '?' must still become $1.
{
  # The maker inlines the \[...] literal verbatim; { name => 'a' } binds.
  my ($sql) = $sm->select('t', ['*'], { -or => [ { name => 'a' }, \q{col = 'what?'} ] });
  like $sql, qr/'what\?'/, 'maker really did inline a literal containing ?';
  my $pos = $storage->_transform_sql($sql);
  like $pos, qr/'what\?'/, "literal 'what?' left untouched (its ? is data)";
  like $pos, qr/"name" = \$1/, 'the real placeholder still became $1';
  # Only ONE positional placeholder should exist.
  my @nums = $pos =~ /\$(\d+)/g;
  is_deeply \@nums, [1], 'exactly one positional placeholder ($1), literal ? not counted';
}

# Double-quoted identifier containing a '?' is skipped (defensive). The maker
# would not normally emit such an identifier, so we feed the translator directly.
{
  my $pos = $storage->_transform_sql(q{SELECT "od?d" FROM t WHERE x = ?});
  is $pos, q{SELECT "od?d" FROM t WHERE x = $1},
    'double-quoted identifier ? skipped, real placeholder -> $1';
}

# Doubled-quote escaping inside a literal: '' stays inside the string, the ?
# after it is still data.
{
  my $pos = $storage->_transform_sql(q{SELECT * FROM t WHERE a = 'it''s a ?' AND b = ?});
  is $pos, q{SELECT * FROM t WHERE a = 'it''s a ?' AND b = $1},
    'doubled \'\' escape handled; ? inside literal untouched, real ? -> $1';
}

# A statement with no placeholders is returned unchanged.
{
  is $storage->_transform_sql('SELECT 1'), 'SELECT 1', 'no placeholders -> unchanged';
}

# --- karr k84: text PostgreSQL does not read as SQL ------------------------------
#
# WHY: the dbh of the same schema hands the statement to DBD::Pg, which looks
# for '?' only where PostgreSQL's scanner reads SQL. A '?' in a dollar-quoted
# body, in a comment or behind a backslashed quote of an E'' string is text.
# Numbered here, it either changes a literal or leaves the statement with one
# $N more than it has binds, and the statement that runs over the dbh fails
# over this transport. Each case holds the exact text and how many $N the
# translation added: one per bind, no more. The measure is PostgreSQL's scanner
# (scan.l); where DBD::Pg 3.20.2 reads less than the server -- nested comments,
# a lowercase e, a continued E'' string, a '$' inside an identifier -- the
# server's reading is held.

sub transforms_to {
  my ($sql, $want, $binds, $name) = @_;
  my $got = $storage->_transform_sql($sql);
  is $got, $want, $name;
  my $before = () = $sql =~ /\$\d+/g;
  my $after  = () = $got =~ /\$\d+/g;
  is $after - $before, $binds, "$name: $binds placeholder(s) numbered";
}

# The four statements of the card, as it gives them.
transforms_to(
  q{SELECT $body$ what? $body$ WHERE id = ?},
  q{SELECT $body$ what? $body$ WHERE id = $1},
  1, 'k84: a ? in a tagged dollar-quoted body is text',
);
transforms_to(
  "SELECT 1 -- really?\n WHERE id = ?",
  "SELECT 1 -- really?\n WHERE id = \$1",
  1, 'k84: a ? in a -- comment is text',
);
transforms_to(
  q{SELECT /* why? */ 1 WHERE id = ?},
  q{SELECT /* why? */ 1 WHERE id = $1},
  1, 'k84: a ? in a /* */ comment is text',
);
transforms_to(
  q{SELECT E'it\'s ?' , ?},
  q{SELECT E'it\'s ?' , $1},
  1, q{k84: a backslashed quote does not end an E'' string},
);

# Dollar quoting.
transforms_to(
  q{SELECT $$ a? $$, ?},
  q{SELECT $$ a? $$, $1},
  1, 'k84 dollar: the empty tag',
);
transforms_to(
  q{SELECT $_t1$ a? $_t1$, ?},
  q{SELECT $_t1$ a? $_t1$, $1},
  1, 'k84 dollar: a tag of underscore, letters and digits',
);
transforms_to(
  "SELECT \$\x{fc}\$ a? \$\x{fc}\$, ?",
  "SELECT \$\x{fc}\$ a? \$\x{fc}\$, \$1",
  1, 'k84 dollar: a tag with a letter outside ASCII',
);
transforms_to(
  q{SELECT $a$ x $b$ ? $b$ ? $a$, ?},
  q{SELECT $a$ x $b$ ? $b$ ? $a$, $1},
  1, 'k84 dollar: another tag inside the body is body text',
);
transforms_to(
  q{SELECT $a$ $$ ? $a$, ?, $$ ? $$},
  q{SELECT $a$ $$ ? $a$, $1, $$ ? $$},
  1, 'k84 dollar: $$ inside a tagged body does not open or close anything',
);
transforms_to(
  q{SELECT $body$ ?$bod$ ? $body $ ? $Body$ ? $body$, ?},
  q{SELECT $body$ ?$bod$ ? $body $ ? $Body$ ? $body$, $1},
  1, 'k84 dollar: only the very same tag closes the body',
);
transforms_to(
  q{SELECT $$ -- ' /* " ? $$, ?},
  q{SELECT $$ -- ' /* " ? $$, $1},
  1, 'k84 dollar: comment and quote starts inside the body are body text',
);
transforms_to(
  q{SELECT $q$ never closed ? and ?},
  q{SELECT $q$ never closed ? and ?},
  0, 'k84 dollar: a body that is never closed runs to the end',
);
# Held before k84 as well: these keep the dollar-quote reading from going too far.
transforms_to(
  q{SELECT $1::int, $2::text},
  q{SELECT $1::int, $2::text},
  0, 'k84 dollar: $N passes through',
);
# A digit starts no tag: '$1$ ? $1$' is a parameter, a '?' and a parameter, not a
# quote around the '?'. A $N beside a ? is refused (dbio-postgresql k120, the
# section at the end), and the refusal is what shows it: read as a quote, the
# '?' would be text and nothing would mix. Before the refusal both '?' were
# numbered $1 and $2 beside a $1 already there.
{
  my $got = eval { $storage->_transform_sql(q{SELECT $1$ ? $1$ ?}) };
  ok !defined $got && $@ =~ /mixes/,
    'k84 dollar: a digit starts no tag, $1$ ... $1$ is no quote (read as parameters, refused)';
}
transforms_to(
  q{SELECT a$b$ FROM t WHERE x = ? AND c$b$ = ?},
  q{SELECT a$b$ FROM t WHERE x = $1 AND c$b$ = $2},
  2, 'k84 dollar: a $ inside an identifier opens no quote',
);
transforms_to(
  q{SELECT e$x$, ?, E$x$},
  q{SELECT e$x$, $1, E$x$},
  1, 'k84 dollar: nor inside one that starts with the letter of the escape string',
);
transforms_to(
  q{SELECT 5 -?, 6 /?, $'a?', ?},
  q{SELECT 5 -$1, 6 /$2, $'a?', $3},
  3, 'k84: a lone -, / or $ opens nothing and hides nothing behind it',
);

# Comments.
transforms_to(
  "SELECT 1 -- it's ?\n, ?, 'x?'",
  "SELECT 1 -- it's ?\n, \$1, 'x?'",
  1, 'k84 comment: a quote inside a -- comment opens no string',
);
transforms_to(
  q{SELECT /* it's "?" */ ?, 'x?'},
  q{SELECT /* it's "?" */ $1, 'x?'},
  1, 'k84 comment: a quote inside a /* */ comment opens no string',
);
transforms_to(
  "SELECT 1 -- a?\r, ?",
  "SELECT 1 -- a?\r, \$1",
  1, 'k84 comment: a carriage return ends a -- comment',
);
transforms_to(
  q{SELECT ? -- trailing? no newline?},
  q{SELECT $1 -- trailing? no newline?},
  1, 'k84 comment: a -- comment without a newline runs to the end',
);
transforms_to(
  "SELECT 2 *-- twice?\n ?",
  "SELECT 2 *-- twice?\n \$1",
  1, 'k84 comment: -- right behind an operator character starts a comment',
);
transforms_to(
  q{SELECT /* a /* b? */ c? */ ?},
  q{SELECT /* a /* b? */ c? */ $1},
  1, 'k84 comment: /* */ nests',
);
transforms_to(
  q{SELECT /* 1 /* 2 /* 3? */ ? */ ? */ ?},
  q{SELECT /* 1 /* 2 /* 3? */ ? */ ? */ $1},
  1, 'k84 comment: /* */ nests three deep',
);
transforms_to(
  q{SELECT /*/ ? */ ?},
  q{SELECT /*/ ? */ $1},
  1, 'k84 comment: /*/ does not close itself',
);
transforms_to(
  q{SELECT /* open ? and ?},
  q{SELECT /* open ? and ?},
  0, 'k84 comment: a /* that is never closed runs to the end',
);
transforms_to(
  q{SELECT /* a /* b */ ? and ?},
  q{SELECT /* a /* b */ ? and ?},
  0, 'k84 comment: so does a nested one whose outer level is never closed',
);
# Held before k84 as well: these keep the comment reading from going too far.
transforms_to(
  q{SELECT '-- no comment', ?, '/* nor this', ?, '*/'},
  q{SELECT '-- no comment', $1, '/* nor this', $2, '*/'},
  2, 'k84 comment: a comment start inside a string is string text',
);
transforms_to(
  "SELECT 1 -- \$\$\n, ?, /* \$\$ */ ?",
  "SELECT 1 -- \$\$\n, \$1, /* \$\$ */ \$2",
  2, 'k84 comment: a $$ inside a comment opens no dollar quote',
);

# Escape strings. In q{} a doubled backslash is one backslash.
transforms_to(
  q{SELECT e'it\'s ?' , ?},
  q{SELECT e'it\'s ?' , $1},
  1, q{k84 E'': a lowercase e opens an escape string too},
);
transforms_to(
  q{SELECT E'it''s \' ?', ?},
  q{SELECT E'it''s \' ?', $1},
  1, q{k84 E'': a doubled quote and a backslashed one in one string},
);
transforms_to(
  q{SELECT E'open \' ? and ?},
  q{SELECT E'open \' ? and ?},
  0, q{k84 E'': a string that is never closed runs to the end},
);
transforms_to(
  "SELECT E'a'\n  'b\\'c ?', ?",
  "SELECT E'a'\n  'b\\'c ?', \$1",
  1, q{k84 E'': the string continued on the next line is an escape string too},
);
transforms_to(
  "SELECT E'a' -- more?\n 'b\\'c ?', ?",
  "SELECT E'a' -- more?\n 'b\\'c ?', \$1",
  1, q{k84 E'': continued across a -- comment},
);
# Held before k84 as well: these keep the escape-string reading from going too
# far, and the reading of every other quoted run where it was.
transforms_to(
  q{SELECT E'a\\\\', ?, 'b?'},
  q{SELECT E'a\\\\', $1, 'b?'},
  1, q{k84 E'': a backslashed backslash does not escape the quote behind it},
);
transforms_to(
  q{SELECT E'open \' and \' ? and ?},
  q{SELECT E'open \' and \' ? and ?},
  0, q{k84 E'': never closed, with two backslashed quotes before the ?},
);
transforms_to(
  q{SELECT E'a' 'b\' , ?, 'x?'},
  q{SELECT E'a' 'b\' , $1, 'x?'},
  1, q{k84 E'': without a newline in between the next string is not its continuation},
);
transforms_to(
  q{SELECT dome'a\', ?, 'b?'},
  q{SELECT dome'a\', $1, 'b?'},
  1, q{k84 E'': a word that only ends in e opens a plain string},
);
transforms_to(
  q{SELECT N'a\', ?, B'01', X'1F', U&'d\0061?', 'x?'},
  q{SELECT N'a\', $1, B'01', X'1F', U&'d\0061?', 'x?'},
  1, q{k84: N'', B'', X'' and U&'' have no backslashed quote},
);
transforms_to(
  q{SELECT 'back\', ?, 'x?'},
  q{SELECT 'back\', $1, 'x?'},
  1, q{k84: a backslash in a plain '' string is text (standard_conforming_strings on)},
);
transforms_to(
  q{SELECT "a--b", "c$$d", "e/*f", ?, "g$$"},
  q{SELECT "a--b", "c$$d", "e/*f", $1, "g$$"},
  1, 'k84: comment and dollar-quote starts inside a quoted identifier are its name',
);
transforms_to(
  q{SELECT ?, 'open ? and ?},
  q{SELECT $1, 'open ? and ?},
  1, q{k84: a '' string that is never closed runs to the end},
);
transforms_to(
  q{SELECT ?, "open ? and ?},
  q{SELECT $1, "open ? and ?},
  1, 'k84: a quoted identifier that is never closed runs to the end',
);

# What the maker emits, to the character. It writes the jsonpath operator as
# '@\?': numbered, that is '@?' with the backslash gone and the placeholder
# behind it $1. The input is the maker's own statement, held here as well:
# written bare, the ? of the operator is a placeholder too, and the statement
# has two parameters for its one bind.
{
  my ($sql, @bind) = $sm->select('t', ['*'], { 'me.data' => { '@?' => '$.a' } });
  is $sql, q{SELECT * FROM "t" WHERE ( "me"."data" @\? ?::jsonpath )},
    'k120 the maker writes the jsonpath operator as @\?';
  is scalar(@bind), 1, 'k120 ... with one bind';
  transforms_to(
    $sql,
    q{SELECT * FROM "t" WHERE ( "me"."data" @? $1::jsonpath )},
    1, 'k120 maker output: the @? operator and its placeholder, to the character',
  );
}
transforms_to(
  q{SELECT * FROM "t" WHERE ( "me"."data" @? ?::jsonpath )},
  q{SELECT * FROM "t" WHERE ( "me"."data" @$1 $2::jsonpath )},
  2, 'k120 the same statement with a bare @?: two placeholders',
);

# Its SQL holds no literal and no comment: every ? in it is a placeholder but
# the one written '\?', which is the question mark it stands for, and there is
# one $N per bind.
for my $where (
  { 'me.data' => { '@?' => '$.a' } },
  { 'me.data' => { '@?' => '$.a' }, id => 7 },
  { 'me.data' => { '@@' => '$.a > 1' } },
  { 'me.data' => { '@>' => { a => 1 } }, id => 1 },
  { 'me.data' => { '<@' => { a => 1 } } },
  { 'me.data' => { '?'  => 'a' } },
  { 'me.data' => { '?|' => [qw( a b )] } },
  { 'me.data' => { '?&' => [qw( a b c )] } },
  { id => { -in => [ 1, 2, 3 ] }, name => { -like => 'a%' } },
) {
  my ($sql, @bind) = $sm->select('t', ['*'], $where);
  my $i = 0;
  (my $want = $sql) =~ s/(\\?)\?/$1 ? '?' : '$' . ++$i/ge;
  is $storage->_transform_sql($sql), $want, "k84 maker output: $want";
  is $i, scalar(@bind), "k84 maker output: $i placeholder(s) for its $i bind(s)";
}

# Shaped SQL shaped again is the same text.
for my $sql (
  q{SELECT $body$ what? $body$ WHERE id = ?},
  q{SELECT /* a /* b? */ c? */ ?, E'it\'s ?', ? -- end?},
  q{SELECT * FROM "t" WHERE "me"."data" @> ?::jsonb AND "id" = ?},
) {
  my $once = $storage->_transform_sql($sql);
  is $storage->_transform_sql($once), $once, "k84: shaping is idempotent: $once";
}

# A statement with a \? is shaped once and no more: the backslash is gone from
# what comes back, so the ? it left is a placeholder to a second pass. Beside a
# $N that pass is refused (the mix, the section at the end) -- the maker's
# jsonpath statement shaped twice fails loudly, it does not reach the server as
# '@$2'. Alone it is numbered: the statement is not the same text any more.
{
  my $once = $storage->_transform_sql(q{SELECT * FROM "t" WHERE "me"."data" @\? ?::jsonpath});
  is $once, q{SELECT * FROM "t" WHERE "me"."data" @? $1::jsonpath},
    'k120: a statement with \? shaped once';
  my $twice = eval { $storage->_transform_sql($once) };
  ok !defined $twice && $@ =~ /mixes/,
    'k120: ... shaped a second time it is refused: its ? stands beside a $N'
    or diag 'got: ' . ($twice // $@);

  is $storage->_transform_sql($storage->_transform_sql(q{SELECT a @\? '$.a'})),
    q{SELECT a @$1 '$.a'},
    'k120: a \? alone, shaped a second time, is a placeholder';
}

# --- a ? behind an @ is a placeholder like every other --------------------------
#
# The numbering knows no operator: a '?' outside a string, a body and a comment
# is a placeholder wherever it stands -- behind '<@', '@@' and '~@' and behind a
# lone '@' alike. That is how DBD::Pg reads the statement at the dbh, so literal
# SQL means the same over both ways: '@? ?' is two parameters there and two
# here, and the server reads '<@$1' as '<@' and a parameter. The jsonpath
# operator is written '@\?', by the maker and in literal SQL (dbio-postgresql
# k120, maintainer's decision 2026-10-12).
for my $case (
  # behind an '@' that ends another operator
  [ q{SELECT * FROM t WHERE tags <@?},          q{SELECT * FROM t WHERE tags <@$1},
    'a ? glued to <@ is a placeholder' ],
  [ q{SELECT * FROM t WHERE tsv @@?},           q{SELECT * FROM t WHERE tsv @@$1},
    'a ? glued to @@ is a placeholder' ],
  [ q{SELECT * FROM t WHERE tags ~@?},          q{SELECT * FROM t WHERE tags ~@$1},
    'a ? glued to ~@ is a placeholder' ],
  # behind a lone '@': a placeholder as well, whatever stands before the '@'
  [ q{SELECT * FROM t WHERE "data" @? ?::jsonpath},
    q{SELECT * FROM t WHERE "data" @$1 $2::jsonpath},
    'a ? behind a lone @ is a placeholder, the ? after it the next one' ],
  [ q{SELECT * FROM t WHERE data@? ?::jsonpath AND id = ?},
    q{SELECT * FROM t WHERE data@$1 $2::jsonpath AND id = $3},
    'an identifier directly before the @ changes nothing about it' ],
  [ q{SELECT a @? '$.a ? (@ == 1)' AND b = ?},
    q{SELECT a @$1 '$.a ? (@ == 1)' AND b = $2},
    'the ? in the jsonpath literal is text, the one behind @ is not' ],
  # the operator, written as it is written: '@\?'
  [ q{SELECT * FROM t WHERE "data" @\? ?::jsonpath},
    q{SELECT * FROM t WHERE "data" @? $1::jsonpath},
    '@\? is the operator, the ? after it is $1' ],
  [ q{SELECT * FROM t WHERE data@\? ?::jsonpath AND id = ?},
    q{SELECT * FROM t WHERE data@? $1::jsonpath AND id = $2},
    '@\? right behind an identifier' ],
  [ q{SELECT a @\? '$.a ? (@ == 1)' AND b = ?},
    q{SELECT a @? '$.a ? (@ == 1)' AND b = $1},
    '@\? beside a jsonpath literal with a ? of its own' ],
) {
  my ($sql, $want, $name) = @$case;
  is $storage->_transform_sql($sql), $want, $name;
}

# --- \? is a literal question mark; $N and ? in one statement is refused -------
#
# dbio-postgresql k120 (maintainer's decision 2026-10-12), kept once in
# DBIO::PostgreSQL::Util::number_placeholders. DBD::Pg takes "\?" outside a
# string as a '?' that is no placeholder and sends it without the backslash;
# this transport sends the statement itself, so the numbering drops the
# backslash and leaves a bare '?'. DBD::Pg refuses a statement that mixes $N
# and ? ("Cannot mix placeholder styles"); so does the numbering. A '?' or $N
# that PostgreSQL does not read as SQL, and a '\?', is no style; a '?' behind
# an '@' is a placeholder and mixes like every other.
for my $case (
  [ q{SELECT a \? ?},                   q{SELECT a ? $1},                  1, '\? literal, ? numbered' ],
  [ q{SELECT a \?| ARRAY[?, ?]},        q{SELECT a ?| ARRAY[$1, $2]},      2, '\?| is the operator' ],
  [ q{SELECT a \? 'x'},                 q{SELECT a ? 'x'},                 0, '\? alone: nothing numbered' ],
  [ q{SELECT '\?', ?},                  q{SELECT '\?', $1},                1, '\? in a string stays' ],
  [ q{SELECT $$\?$$, ?},                q{SELECT $$\?$$, $1},              1, '\? in a dollar-quoted body stays' ],
  [ q{SELECT /* \? */ ?},               q{SELECT /* \? */ $1},             1, '\? in a block comment stays' ],
  [ q{SELECT '$1', ?},                  q{SELECT '$1', $1},                1, '$1 in a string is text, not a style' ],
  [ q{SELECT $$ $1 $$, ?},              q{SELECT $$ $1 $$, $1},            1, '$1 in a dollar-quoted body is text' ],
  [ q{SELECT a @\? $1::jsonpath},       q{SELECT a @? $1::jsonpath},       0, '@\? and $N: the ? is the operator' ],
  [ q{SELECT $1, $2 \? 'x'},            q{SELECT $1, $2 ? 'x'},            0, '$N and \? do not mix' ],
) {
  my ($sql, $want, $binds, $name) = @$case;
  transforms_to($sql, $want, $binds, "k120 $name");
}

for my $case (
  [ q{SELECT $1, ?},                    'a $N before a ?' ],
  [ q{SELECT ?, $1},                    'a ? before a $N' ],
  [ q{SELECT $2::int + ?::int},         'the shape that ran with one value twice' ],
  [ q{SELECT a <@? , $1},               '<@? is a placeholder, and mixes' ],
  [ q{SELECT a @\? ?::jsonpath, $1},    'the placeholder behind @\? mixes' ],
  [ q{SELECT a @? $1::jsonpath},        'a ? behind @ is a placeholder, and mixes' ],
) {
  my ($sql, $name) = @$case;
  my $got = eval { $storage->_transform_sql($sql) };
  my $err = $@;
  ok !defined $got, "k120 $name: refused";
  like $err, qr/mix.*\$N.*\?|\?.*\$N.*mix/is, "k120 $name: the message names the mix";
  unlike $err, qr/SELECT|jsonpath/, "k120 $name: ... and does not repeat the statement";
}

done_testing;
