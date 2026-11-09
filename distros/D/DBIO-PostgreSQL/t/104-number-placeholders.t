use strict;
use warnings;
use Test::More;

# OFFLINE test for DBIO::PostgreSQL::Util::number_placeholders (karr k120,
# from dbio-postgresql-ev k84): the one implementation of "a ? is a placeholder
# where PostgreSQL reads SQL", and the future_io transport's _transform_sql,
# which answers through it.
#
# WHY IT MATTERS: the shared DBIO::PostgreSQL::SQLMaker emits '?', which the
# sync DBI driver needs, and a transport that sends '$N' numbers them itself.
# The dbh of the same schema hands a statement to DBD::Pg, which looks for a '?'
# only where PostgreSQL's scanner reads SQL. A '?' in a dollar-quoted body, in a
# comment or behind the backslashed quote of an E'' string is text. Numbered, it
# either changes a literal or leaves the statement with one $N more than it has
# binds -- and a $1 that came up inside a comment makes DBD::Pg refuse the
# statement outright ("must start at $1") -- so a statement that runs over the
# dbh fails over the transport. Each case holds the exact text and how many $N
# the numbering added: one per bind, no more. The measure is PostgreSQL's
# scanner (src/backend/parser/scan.l).
#
# The rule was written for the native ev transport (dbio-postgresql-ev, commit
# bfcd0da, its t/03-positional-placeholders.t) and is the same text here, so
# that transport can take this function over. It does not inherit the future_io
# storage and must be able to load the helper without dbio-async or Future::IO;
# that is pinned too.

use DBIO::PostgreSQL::Util ();
my %LOADED_WITH_UTIL;
BEGIN { %LOADED_WITH_UTIL = %INC }
use DBIO::PostgreSQL::SQLMaker;

# -----------------------------------------------------------------------
# 0. Loading the helper pulls in nothing of DBIO and no transport
# -----------------------------------------------------------------------
is_deeply
  [ grep { m{\A(?:DBIO|Future|DBI|DBD)(?:/|\.pm\z)} && $_ ne 'DBIO/PostgreSQL/Util.pm' } sort keys %LOADED_WITH_UTIL ],
  [],
  'loading DBIO::PostgreSQL::Util loads no other DBIO module, no DBI and no Future';

{
  package NoImport;
  use DBIO::PostgreSQL::Util;
}
ok !NoImport->can('number_placeholders'), 'number_placeholders is not exported by default';
{
  package OnRequest;
  ::ok eval { DBIO::PostgreSQL::Util->import('number_placeholders'); 1 }, '... but on request'
    or ::diag $@;
}
ok +OnRequest->can('number_placeholders'), '... and is there then';

# -----------------------------------------------------------------------
# The two readers every case goes through: the function, and the transport
# seam that delegates to it. The seam needs dbio-async (recommends only).
# -----------------------------------------------------------------------
my $PG = 'DBIO::PostgreSQL::Storage::Async';
my $HAVE_TRANSPORT = eval { require DBIO::PostgreSQL::Storage::Async; 1 };

my @READERS = (
  [ 'number_placeholders' => sub { DBIO::PostgreSQL::Util::number_placeholders($_[0]) } ],
);
if ($HAVE_TRANSPORT) {
  push @READERS, [ '_transform_sql' => sub { $PG->_transform_sql($_[0]) } ];
}
else {
  diag 'DBIO::Async not installed (recommends only) -- cases run against the function alone';
}

# Number $sql through one reader; a die is a failed case, not a dead file.
sub number {
  my ($reader, $sql) = @_;
  my $got = eval { $reader->[1]->($sql) };
  diag "$reader->[0] died: $@" unless defined $got;
  return $got;
}

sub numbers_to {
  my ($sql, $want, $binds, $name) = @_;
  for my $reader (@READERS) {
    my $got = number($reader, $sql);
    is $got, $want, "$reader->[0]: $name";
    my $before = () = $sql =~ /\$\d+/g;
    my $after  = () = ($got // '') =~ /\$\d+/g;
    is $after - $before, $binds, "$reader->[0]: $name: $binds placeholder(s) numbered";
  }
}

my $sm = DBIO::PostgreSQL::SQLMaker->new(
  quote_char    => '"',
  name_sep      => '.',
  limit_dialect => 'LimitOffset',
);

# -----------------------------------------------------------------------
# 1. What the SQL maker emits: every ? a placeholder, numbered left to right
# -----------------------------------------------------------------------
{
  my ($sql) = $sm->select('artist', ['name'], { id => 1, name => 'Miles' });
  for my $reader (@READERS) {
    my $pos = number($reader, $sql) // '';
    unlike $pos, qr/\?/, "$reader->[0]: no bare ? left (multi-bind WHERE)";
    like $pos, qr/\$1\b.*\$2\b/s, "$reader->[0]: \$1 before \$2, left to right";
  }
}
{
  my ($sql) = $sm->insert('artist', { id => 2, name => 'X' });
  numbers_to($sql, 'INSERT INTO "artist" ("id", "name") VALUES ($1, $2)',
    2, 'INSERT VALUES placeholders');
}
{
  my ($sql) = $sm->update('artist', { name => 'Y' }, { id => 3 });
  numbers_to($sql, 'UPDATE "artist" SET "name" = $1 WHERE "id" = $2',
    2, 'UPDATE SET and WHERE numbered across the whole statement');
}
{
  my ($sql) = $sm->delete('artist', { id => 4 });
  numbers_to($sql, 'DELETE FROM "artist" WHERE "id" = $1', 1, 'DELETE WHERE');
}

# The shapes with a ? in or beside an operator. The maker writes the jsonpath
# operator as '@\?' (section 7): numbered, it stands as the server reads it,
# '@?' and no backslash, and the placeholder behind it is numbered; the
# ?-family of key existence operators is written the same way ('\?', '\?|',
# '\?&', karr k121) and reaches the server as ?, ?| and ?&.
for my $case (
  [ { id => { -in => [ 1, 2, 3 ] } },
    qr/IN \( \$1, \$2, \$3 \)/, 'IN list: one $N per element' ],
  [ { 'me.data' => { '@?' => '$.status == "active"' } },
    qr/\@\? \$1::jsonpath/, '@? reaches the server as @?, its placeholder is $1::jsonpath' ],
  [ { 'me.data' => { '@?' => '$.x' }, id => 7 },
    qr/"id" = \$1.*\@\? \$2::jsonpath/s, '@? beside a bound column: $1 and $2' ],
  [ { 'me.data' => { '@@' => '$.score > 10' } },
    qr/\@\@ \$1::jsonpath/, '@@ and its $1::jsonpath' ],
  [ { 'me.data' => { '@>' => { status => 'active' } } },
    qr/\@> \$1::jsonb/, '@> ?::jsonb cast is $1::jsonb' ],
  [ { 'me.data' => { '?' => 'email' } },
    qr/"me"\."data" \? \$1\b/, '? reaches the server as ?, its placeholder is $1' ],
  [ { 'me.data' => { '?|' => [ 'email', 'phone' ] } },
    qr/"me"\."data" \?\| ARRAY\[\$1, \$2\]/, '?| reaches the server as ?|, ARRAY[$1, $2]' ],
  [ { 'me.data' => { '?&' => [ 'name', 'email' ] } },
    qr/"me"\."data" \?& ARRAY\[\$1, \$2\]/, '?& reaches the server as ?&, ARRAY[$1, $2]' ],
) {
  my ($where, $re, $name) = @$case;
  my ($sql) = $sm->select('t', ['*'], $where);
  for my $reader (@READERS) {
    my $pos = number($reader, $sql) // '';
    like $pos, $re, "$reader->[0]: $name";
    unlike $pos, qr/\@\$/, "$reader->[0]: $name: no operator turned into \@\$";
    unlike $pos, qr/\\/, "$reader->[0]: $name: no backslash is left for the server";
  }
}

# To the character, and one $N per bind. The input is the maker's own
# statement, held here as well: were the operator written bare, its ? would be
# numbered ($1) and the statement would have two parameters for one bind.
{
  my ($sql, @bind) = $sm->select('t', ['*'], { 'me.data' => { '@?' => '$.a' } });
  is $sql, q{SELECT * FROM "t" WHERE ( "me"."data" @\? ?::jsonpath )},
    'the maker writes the jsonpath operator as @\?';
  is scalar(@bind), 1, '... with one bind';
  numbers_to(
    $sql,
    q{SELECT * FROM "t" WHERE ( "me"."data" @? $1::jsonpath )},
    1, 'maker output: the @? operator and its placeholder, to the character',
  );
}
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
  # every ? is numbered; a \? is the question mark it stands for
  my $i = 0;
  (my $want = $sql) =~ s/(\\?)\?/$1 ? '?' : '$' . ++$i/ge;
  numbers_to($sql, $want, scalar(@bind), "maker output: $want");
}

# -----------------------------------------------------------------------
# 2. Strings and quoted identifiers, as held before the lexer too
# -----------------------------------------------------------------------
{
  # The maker inlines the literal verbatim; { name => 'a' } binds.
  my ($sql) = $sm->select('t', ['*'], { -or => [ { name => 'a' }, \q{col = 'what?'} ] });
  like $sql, qr/'what\?'/, 'the maker really did inline a literal containing ?';
  (my $want = $sql) =~ s/"name" = \?/"name" = \$1/;
  numbers_to($sql, $want, 1, q{an inlined literal 'what?' keeps its ?, the bind beside it is $1});
}
numbers_to(
  q{WHERE "x" = 'lit ? eral' AND "y" = ?},
  q{WHERE "x" = 'lit ? eral' AND "y" = $1},
  1, 'a ? inside a string literal is text',
);
numbers_to(
  q{SELECT "od?d" FROM t WHERE x = ?},
  q{SELECT "od?d" FROM t WHERE x = $1},
  1, 'a ? inside a quoted identifier is its name',
);
numbers_to(
  q{SELECT * FROM t WHERE a = 'it''s a ?' AND b = ?},
  q{SELECT * FROM t WHERE a = 'it''s a ?' AND b = $1},
  1, q{a doubled '' stays inside the string},
);
numbers_to('SELECT 1', 'SELECT 1', 0, 'a statement without a placeholder is returned as it is');
numbers_to('', '', 0, 'the empty statement');

# -----------------------------------------------------------------------
# 3. Text PostgreSQL does not read as SQL
#
#    Where DBD::Pg 3.20.2 reads less than the server -- nested comments, a
#    lowercase e, a continued E'' string, a '$' inside an identifier -- the
#    server's reading is held.
# -----------------------------------------------------------------------

# The four statements of the card, as it gives them.
numbers_to(
  q{SELECT $body$ what? $body$ WHERE id = ?},
  q{SELECT $body$ what? $body$ WHERE id = $1},
  1, 'a ? in a tagged dollar-quoted body is text',
);
numbers_to(
  "SELECT 1 -- really?\n WHERE id = ?",
  "SELECT 1 -- really?\n WHERE id = \$1",
  1, 'a ? in a -- comment is text',
);
numbers_to(
  q{SELECT /* why? */ 1 WHERE id = ?},
  q{SELECT /* why? */ 1 WHERE id = $1},
  1, 'a ? in a /* */ comment is text',
);
numbers_to(
  q{SELECT E'it\'s ?' , ?},
  q{SELECT E'it\'s ?' , $1},
  1, q{a backslashed quote does not end an E'' string},
);

# Dollar quoting.
numbers_to(
  q{SELECT $$ a? $$, ?},
  q{SELECT $$ a? $$, $1},
  1, 'dollar: the empty tag',
);
numbers_to(
  q{SELECT $_t1$ a? $_t1$, ?},
  q{SELECT $_t1$ a? $_t1$, $1},
  1, 'dollar: a tag of underscore, letters and digits',
);
numbers_to(
  "SELECT \$\x{fc}\$ a? \$\x{fc}\$, ?",
  "SELECT \$\x{fc}\$ a? \$\x{fc}\$, \$1",
  1, 'dollar: a tag with a letter outside ASCII',
);
numbers_to(
  q{SELECT $a$ x $b$ ? $b$ ? $a$, ?},
  q{SELECT $a$ x $b$ ? $b$ ? $a$, $1},
  1, 'dollar: another tag inside the body is body text',
);
numbers_to(
  q{SELECT $a$ $$ ? $a$, ?, $$ ? $$},
  q{SELECT $a$ $$ ? $a$, $1, $$ ? $$},
  1, 'dollar: $$ inside a tagged body does not open or close anything',
);
numbers_to(
  q{SELECT $body$ ?$bod$ ? $body $ ? $Body$ ? $body$, ?},
  q{SELECT $body$ ?$bod$ ? $body $ ? $Body$ ? $body$, $1},
  1, 'dollar: only the very same tag closes the body',
);
numbers_to(
  q{SELECT $$ -- ' /* " ? $$, ?},
  q{SELECT $$ -- ' /* " ? $$, $1},
  1, 'dollar: comment and quote starts inside the body are body text',
);
numbers_to(
  q{SELECT $q$ never closed ? and ?},
  q{SELECT $q$ never closed ? and ?},
  0, 'dollar: a body that is never closed runs to the end',
);
# Held before the lexer as well: these keep the dollar-quote reading from going
# too far.
numbers_to(
  q{SELECT $1::int, $2::text},
  q{SELECT $1::int, $2::text},
  0, 'dollar: $N passes through',
);
# A digit starts no tag: '$1$ ? $1$' is a parameter, a '?' and a parameter, not a
# quote around the '?'. Since a $N beside a ? is refused (section 7), the
# refusal is what shows it: read as a quote, the '?' would be text and nothing
# would mix.
for my $reader (@READERS) {
  my $got = eval { $reader->[1]->(q{SELECT $1$ ? $1$ ?}) };
  ok !defined $got && $@ =~ /mixes/,
    "$reader->[0]: dollar: a digit starts no tag, \$1\$ ... \$1\$ is no quote (read as parameters, refused)";
}
numbers_to(
  q{SELECT a$b$ FROM t WHERE x = ? AND c$b$ = ?},
  q{SELECT a$b$ FROM t WHERE x = $1 AND c$b$ = $2},
  2, 'dollar: a $ inside an identifier opens no quote',
);
numbers_to(
  q{SELECT e$x$, ?, E$x$},
  q{SELECT e$x$, $1, E$x$},
  1, 'dollar: nor inside one that starts with the letter of the escape string',
);
numbers_to(
  q{SELECT 5 -?, 6 /?, $'a?', ?},
  q{SELECT 5 -$1, 6 /$2, $'a?', $3},
  3, 'a lone -, / or $ opens nothing and hides nothing behind it',
);

# Comments.
numbers_to(
  "SELECT 1 -- it's ?\n, ?, 'x?'",
  "SELECT 1 -- it's ?\n, \$1, 'x?'",
  1, 'comment: a quote inside a -- comment opens no string',
);
numbers_to(
  q{SELECT /* it's "?" */ ?, 'x?'},
  q{SELECT /* it's "?" */ $1, 'x?'},
  1, 'comment: a quote inside a /* */ comment opens no string',
);
numbers_to(
  "SELECT 1 -- a?\r, ?",
  "SELECT 1 -- a?\r, \$1",
  1, 'comment: a carriage return ends a -- comment',
);
numbers_to(
  q{SELECT ? -- trailing? no newline?},
  q{SELECT $1 -- trailing? no newline?},
  1, 'comment: a -- comment without a newline runs to the end',
);
numbers_to(
  "SELECT 2 *-- twice?\n ?",
  "SELECT 2 *-- twice?\n \$1",
  1, 'comment: -- right behind an operator character starts a comment',
);
numbers_to(
  q{SELECT /* a /* b? */ c? */ ?},
  q{SELECT /* a /* b? */ c? */ $1},
  1, 'comment: /* */ nests',
);
numbers_to(
  q{SELECT /* 1 /* 2 /* 3? */ ? */ ? */ ?},
  q{SELECT /* 1 /* 2 /* 3? */ ? */ ? */ $1},
  1, 'comment: /* */ nests three deep',
);
numbers_to(
  q{SELECT /*/ ? */ ?},
  q{SELECT /*/ ? */ $1},
  1, 'comment: /*/ does not close itself',
);
numbers_to(
  q{SELECT /* open ? and ?},
  q{SELECT /* open ? and ?},
  0, 'comment: a /* that is never closed runs to the end',
);
numbers_to(
  q{SELECT /* a /* b */ ? and ?},
  q{SELECT /* a /* b */ ? and ?},
  0, 'comment: so does a nested one whose outer level is never closed',
);
# Held before the lexer as well: these keep the comment reading from going too
# far.
numbers_to(
  q{SELECT '-- no comment', ?, '/* nor this', ?, '*/'},
  q{SELECT '-- no comment', $1, '/* nor this', $2, '*/'},
  2, 'comment: a comment start inside a string is string text',
);
numbers_to(
  "SELECT 1 -- \$\$\n, ?, /* \$\$ */ ?",
  "SELECT 1 -- \$\$\n, \$1, /* \$\$ */ \$2",
  2, 'comment: a $$ inside a comment opens no dollar quote',
);

# Escape strings. In q{} a doubled backslash is one backslash.
numbers_to(
  q{SELECT e'it\'s ?' , ?},
  q{SELECT e'it\'s ?' , $1},
  1, q{E'': a lowercase e opens an escape string too},
);
numbers_to(
  q{SELECT E'it''s \' ?', ?},
  q{SELECT E'it''s \' ?', $1},
  1, q{E'': a doubled quote and a backslashed one in one string},
);
numbers_to(
  q{SELECT E'open \' ? and ?},
  q{SELECT E'open \' ? and ?},
  0, q{E'': a string that is never closed runs to the end},
);
numbers_to(
  "SELECT E'a'\n  'b\\'c ?', ?",
  "SELECT E'a'\n  'b\\'c ?', \$1",
  1, q{E'': the string continued on the next line is an escape string too},
);
numbers_to(
  "SELECT E'a' -- more?\n 'b\\'c ?', ?",
  "SELECT E'a' -- more?\n 'b\\'c ?', \$1",
  1, q{E'': continued across a -- comment},
);
# Held before the lexer as well: these keep the escape-string reading from
# going too far, and the reading of every other quoted run where it was.
numbers_to(
  q{SELECT E'a\\\\', ?, 'b?'},
  q{SELECT E'a\\\\', $1, 'b?'},
  1, q{E'': a backslashed backslash does not escape the quote behind it},
);
numbers_to(
  q{SELECT E'open \' and \' ? and ?},
  q{SELECT E'open \' and \' ? and ?},
  0, q{E'': never closed, with two backslashed quotes before the ?},
);
numbers_to(
  q{SELECT E'a' 'b\' , ?, 'x?'},
  q{SELECT E'a' 'b\' , $1, 'x?'},
  1, q{E'': without a newline in between the next string is not its continuation},
);
numbers_to(
  q{SELECT dome'a\', ?, 'b?'},
  q{SELECT dome'a\', $1, 'b?'},
  1, q{E'': a word that only ends in e opens a plain string},
);
numbers_to(
  q{SELECT N'a\', ?, B'01', X'1F', U&'d\0061?', 'x?'},
  q{SELECT N'a\', $1, B'01', X'1F', U&'d\0061?', 'x?'},
  1, q{N'', B'', X'' and U&'' have no backslashed quote},
);
numbers_to(
  q{SELECT 'back\', ?, 'x?'},
  q{SELECT 'back\', $1, 'x?'},
  1, q{a backslash in a plain '' string is text (standard_conforming_strings on)},
);
numbers_to(
  q{SELECT "a--b", "c$$d", "e/*f", ?, "g$$"},
  q{SELECT "a--b", "c$$d", "e/*f", $1, "g$$"},
  1, 'comment and dollar-quote starts inside a quoted identifier are its name',
);
numbers_to(
  q{SELECT ?, 'open ? and ?},
  q{SELECT $1, 'open ? and ?},
  1, q{a '' string that is never closed runs to the end},
);
numbers_to(
  q{SELECT ?, "open ? and ?},
  q{SELECT $1, "open ? and ?},
  1, 'a quoted identifier that is never closed runs to the end',
);

# -----------------------------------------------------------------------
# 4. Numbered SQL numbered again is the same text
# -----------------------------------------------------------------------
for my $sql (
  q{SELECT $body$ what? $body$ WHERE id = ?},
  q{SELECT /* a /* b? */ c? */ ?, E'it\'s ?', ? -- end?},
  q{SELECT * FROM "t" WHERE "me"."data" @> ?::jsonb AND "id" = ?},
) {
  for my $reader (@READERS) {
    my $once = number($reader, $sql);
    is number($reader, $once // ''), $once, "$reader->[0]: numbering is idempotent: $sql";
    like $once // '', qr/\$1/, "$reader->[0]: ... and it did number: $sql";
  }
}

# A statement with a \? is numbered once and no more: the backslash is gone
# from what comes back, so the ? it left is a placeholder to a second pass.
# Beside a $N that pass is refused (the mix, section 7) -- the maker's jsonpath
# statement shaped twice fails loudly, it does not reach the server as '@$2'.
# Alone it is numbered: the statement is not the same text any more.
for my $reader (@READERS) {
  my $once = number($reader, q{SELECT * FROM "t" WHERE "me"."data" @\? ?::jsonpath});
  is $once, q{SELECT * FROM "t" WHERE "me"."data" @? $1::jsonpath},
    "$reader->[0]: a statement with \\? numbered once";
  my $twice = eval { $reader->[1]->($once // '') };
  ok !defined $twice && $@ =~ /mixes/,
    "$reader->[0]: ... numbered a second time it is refused: its ? stands beside a \$N"
    or diag 'got: ' . ($twice // $@);

  is number($reader, number($reader, q{SELECT a @\? '$.a'}) // ''), q{SELECT a @$1 '$.a'},
    "$reader->[0]: a \\? alone, numbered a second time, is a placeholder";
}

# The argument is the caller's and stays as it was.
{
  my $sql = q{SELECT $$ a? $$, ?, ?};
  for my $reader (@READERS) {
    number($reader, $sql);
    is $sql, q{SELECT $$ a? $$, ?, ?}, "$reader->[0]: the argument is left as it was";
    is pos($sql), undef, "$reader->[0]: ... and so is its match position";
  }
}

# -----------------------------------------------------------------------
# 5. A ? behind an @ is a placeholder like every other
#
#    The numbering knows no operator: a ? outside a string, a body and a
#    comment is a placeholder wherever it stands -- behind '<@', '@@' and '~@'
#    and behind a lone '@' alike. That is how DBD::Pg reads the statement at
#    the dbh, so literal SQL means the same over both ways: '@? ?' is two
#    parameters there and two here. The jsonpath operator is written '@\?'
#    (section 7), by the maker and in literal SQL (karr k120, maintainer's
#    decision 2026-10-12).
# -----------------------------------------------------------------------
for my $case (
  # behind an '@' that ends another operator
  [ q{SELECT * FROM t WHERE tags <@?},        q{SELECT * FROM t WHERE tags <@$1},        '<@ and a placeholder' ],
  [ q{SELECT ARRAY[1] <@?::int[]},            q{SELECT ARRAY[1] <@$1::int[]},            '<@ glued to its cast' ],
  [ q{SELECT '{"a":1}'::jsonb @@?::jsonpath}, q{SELECT '{"a":1}'::jsonb @@$1::jsonpath}, '@@ and a placeholder' ],
  [ q{SELECT a ~@?},                          q{SELECT a ~@$1},                          '~@ and a placeholder' ],
  [ q{SELECT a -@?},                          q{SELECT a -@$1},                          '-@ and a placeholder' ],
  [ q{SELECT a<@?},                           q{SELECT a<@$1},                           '<@ with no space before it' ],
  # behind a lone '@': a placeholder as well, whatever stands before the '@'
  [ q{@? ?::jsonpath},                        q{@$1 $2::jsonpath},                       '@? at the start of the statement' ],
  [ q{@?},                                    q{@$1},                                    '@? alone' ],
  [ q{SELECT (a @? ?::jsonpath)},             q{SELECT (a @$1 $2::jsonpath)},            '@? after a space' ],
  [ q{SELECT (@? ?::jsonpath)},               q{SELECT (@$1 $2::jsonpath)},              '@? right behind an opening parenthesis' ],
  [ q{SELECT (a)@? ?::jsonpath},              q{SELECT (a)@$1 $2::jsonpath},             '@? right behind a closing parenthesis' ],
  [ q{SELECT data@? ?::jsonpath},             q{SELECT data@$1 $2::jsonpath},            '@? right behind an identifier' ],
  [ q{SELECT "data"@? ?::jsonpath},           q{SELECT "data"@$1 $2::jsonpath},          '@? right behind a quoted identifier' ],
  [ q{SELECT data->>'x'@? ?::jsonpath},       q{SELECT data->>'x'@$1 $2::jsonpath},      '@? right behind a string literal' ],
  [ q{SELECT data->'x' @? ?::jsonpath},       q{SELECT data->'x' @$1 $2::jsonpath},      '@? after ->' ],
  [ q{SELECT a,@? ?::jsonpath},               q{SELECT a,@$1 $2::jsonpath},              '@? right behind a comma' ],
  [ q{SELECT a @?'$.a'},                      q{SELECT a @$1'$.a'},                      '@? with a literal glued' ],
  [ q{SELECT a @??},                          q{SELECT a @$1$2},                         '@?? is two placeholders' ],
  [ q{SELECT a @? '$.a ? (@ == 1)' AND b = ?}, q{SELECT a @$1 '$.a ? (@ == 1)' AND b = $2}, 'the ? in the jsonpath literal is text, the one behind @ is not' ],
  # the operator, written as it is written: '@\?'
  [ q{@\? ?::jsonpath},                       q{@? $1::jsonpath},                        '@\? at the start of the statement' ],
  [ q{SELECT data@\? ?::jsonpath},            q{SELECT data@? $1::jsonpath},             '@\? right behind an identifier' ],
  [ q{SELECT "data"@\? ?::jsonpath},          q{SELECT "data"@? $1::jsonpath},           '@\? right behind a quoted identifier' ],
  [ q{SELECT a @\?'$.a'},                     q{SELECT a @?'$.a'},                       '@\? with its literal glued' ],
  [ q{SELECT a @\??},                         q{SELECT a @?$1},                          '@\?? is the operator, then a placeholder' ],
  [ q{SELECT a @\? '$.a ? (@ == 1)' AND b = ?}, q{SELECT a @? '$.a ? (@ == 1)' AND b = $1}, '@\? beside a jsonpath literal with a ? of its own' ],
) {
  my ($sql, $want, $name) = @$case;
  for my $reader (@READERS) {
    is number($reader, $sql), $want, "$reader->[0]: $name";
  }
}

# -----------------------------------------------------------------------
# 6. The future_io transport answers through the function: one implementation
#
#    Equal answers in every case above would also come from a second copy of
#    the lexer; the point is that there is none.
# -----------------------------------------------------------------------
SKIP: {
  skip 'DBIO::Async not installed (recommends only) -- future_io transport unavailable', 2
    unless $HAVE_TRANSPORT;

  my @seen;
  {
    no warnings 'redefine';
    local *DBIO::PostgreSQL::Util::number_placeholders = sub { push @seen, $_[0]; 'spy' };
    is $PG->_transform_sql('SELECT ?'), 'spy',
      '_transform_sql delegates to DBIO::PostgreSQL::Util::number_placeholders';
  }
  is_deeply \@seen, ['SELECT ?'], '... handing the statement through unchanged';
}

# -----------------------------------------------------------------------
# 7. \? is a literal question mark; $N and ? in one statement is refused
#
#    DBD::Pg takes "\?" outside a string as a '?' that is no placeholder and
#    sends it without the backslash (DBD::Pg 3.5.0): the way to write the
#    operators '?', '?|' and '?&' and '@?' over the dbh. A transport that
#    sends the statement itself has no DBD::Pg to strip the backslash, so the
#    numbering does: the output holds a bare '?', which is also what DBD::Pg
#    under pg_placeholder_dollaronly leaves standing. DBD::Pg refuses a
#    statement that mixes $N and ? ("Cannot mix placeholder styles"); the
#    numbering refuses it the same way instead of numbering both to $1 (karr
#    k120, maintainer's decision 2026-10-12).
# -----------------------------------------------------------------------
for my $case (
  [ q{SELECT a @\? ?::jsonpath},        q{SELECT a @? $1::jsonpath},      1, '@\? is the operator, the next ? a placeholder' ],
  [ q{SELECT a \? ?},                   q{SELECT a ? $1},                 1, '\? literal, ? numbered' ],
  [ q{SELECT a \?| ARRAY[?, ?]},        q{SELECT a ?| ARRAY[$1, $2]},     2, '\?| is the operator' ],
  [ q{SELECT a \?& ARRAY[?]},           q{SELECT a ?& ARRAY[$1]},         1, '\?& is the operator' ],
  [ q{SELECT a \? 'x'},                 q{SELECT a ? 'x'},                0, '\? alone: nothing numbered' ],
  [ q{SELECT a<@\?::int[]},             q{SELECT a<@?::int[]},            0, '\? glued to an operator and a cast' ],
  [ q{SELECT a \? ? AND b \? ?},        q{SELECT a ? $1 AND b ? $2},      2, 'several \? and ? in order' ],
  # in a string, a body or a comment the backslash is text and stays
  [ q{SELECT '\?', ?},                  q{SELECT '\?', $1},               1, '\? in a string stays' ],
  [ q{SELECT $$\?$$, ?},                q{SELECT $$\?$$, $1},             1, '\? in a dollar-quoted body stays' ],
  [ q{SELECT 1 -- \?} . "\n" . q{, ?},  q{SELECT 1 -- \?} . "\n" . q{, $1}, 1, '\? in a -- comment stays' ],
  [ q{SELECT /* \? */ ?},               q{SELECT /* \? */ $1},            1, '\? in a block comment stays' ],
  [ q{SELECT E'\?', ?},                 q{SELECT E'\?', $1},              1, '\? in an escape string stays' ],
  # one backslash goes, no more
  [ q{SELECT a \\\\? ?},                q{SELECT a \\? $1},                1, 'only the backslash directly before the ? goes' ],
  # $N where PostgreSQL does not read it counts as nothing
  [ q{SELECT '$1', ?},                  q{SELECT '$1', $1},               1, '$1 in a string is text, not a style' ],
  [ q{SELECT $$ $1 $$, ?},              q{SELECT $$ $1 $$, $1},           1, '$1 in a dollar-quoted body is text' ],
  [ q{SELECT ? -- $1} . "\n",           q{SELECT $1 -- $1} . "\n",        1, '$1 in a comment is text' ],
  [ q{SELECT /* $2 */ ?},               q{SELECT /* $2 */ $1},            1, '$2 in a block comment is text' ],
  [ q{SELECT a$1, ?},                   q{SELECT a$1, $1},                1, 'a $ inside an identifier is no parameter' ],
  # a ? that is no placeholder does not mix
  [ q{SELECT a @\? $1::jsonpath},       q{SELECT a @? $1::jsonpath},      0, '@\? and $N: the ? is the operator' ],
  [ q{SELECT $1, $2 \? 'x'},            q{SELECT $1, $2 ? 'x'},           0, '$N and \? do not mix' ],
  [ q{SELECT $1 WHERE a = '?'},         q{SELECT $1 WHERE a = '?'},       0, '$N and a ? in a string do not mix' ],
) {
  my ($sql, $want, $binds, $name) = @$case;
  for my $reader (@READERS) {
    my $got = number($reader, $sql);
    is $got, $want, "$reader->[0]: $name ($binds numbered)";
  }
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
  for my $reader (@READERS) {
    my $got = eval { $reader->[1]->($sql) };
    my $err = $@;
    ok !defined $got, "$reader->[0]: $name: refused";
    like $err, qr/mix.*\$N.*\?|\?.*\$N.*mix/is, "$reader->[0]: $name: the message names the mix";
    unlike $err, qr/SELECT|jsonpath/, "$reader->[0]: $name: ... and does not repeat the statement";
  }
}

# -----------------------------------------------------------------------
# 8. No statement is refused, as the other helpers refuse what is no value
#
#    An undefined statement used to warn and come back as '' -- an empty
#    query the server answers without complaint -- and a reference came back
#    as its address, 'ARRAY(0x...)', which the server reads as SQL. Neither is
#    a statement anybody wrote. They are refused the way quote_literal,
#    quote_ident and quote_dsn_value refuse an undefined value and a
#    reference: by throwing, in words of the same form, and before anything
#    is read (karr k120, maintainer's decision 2026-10-16).
# -----------------------------------------------------------------------
for my $case (
  [ undef,              'an undefined statement' ],
  [ [ 'SELECT ?' ],     'an arrayref' ],
  [ \'SELECT ?',        'a scalar reference' ],
  [ { sql => 'SELECT ?' }, 'a hashref' ],
) {
  my ($sql, $name) = @$case;
  for my $reader (@READERS) {
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my $got = eval { $reader->[1]->($sql) };
    my $err = $@;
    ok !defined $got, "$reader->[0]: $name: refused, nothing comes back"
      or diag 'got: ' . $got;
    like "$err", qr/a statement must be a defined, plain value/,
      "$reader->[0]: $name: ... saying what a statement must be";
    is_deeply \@warned, [], "$reader->[0]: $name: ... and nothing is warned instead";
  }
}

# The words follow the other helpers': the same sentence, of another value.
{
  my %said;
  for my $helper (qw( quote_literal quote_dsn_value number_placeholders )) {
    eval { DBIO::PostgreSQL::Util->can($helper)->(undef) };
    ($said{$helper} = $@) =~ s/ at .*\z//s;
  }
  like $said{quote_literal},   qr/\Aa literal must be a defined, plain value\z/,
    'control: quote_literal refuses undef in these words';
  like $said{quote_dsn_value}, qr/\Aa connection parameter value must be a defined, plain value\z/,
    'control: ... and so does quote_dsn_value, of its value';
  is $said{number_placeholders}, 'a statement must be a defined, plain value',
    'number_placeholders says the same of a statement';
}

# The function's refusal names its caller, as croak does: this file.
{
  my $line = __LINE__ + 1;
  eval { DBIO::PostgreSQL::Util::number_placeholders(undef) };
  like $@, qr/ at \Q${\ __FILE__}\E line $line\.$/m,
    'the refusal of the function names the place that called it';
}

done_testing;
