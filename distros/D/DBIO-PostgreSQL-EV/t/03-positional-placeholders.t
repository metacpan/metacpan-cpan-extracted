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
# that the '@?' jsonpath OPERATOR and '?' inside string literals are NOT.

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

# (b) '@?' jsonpath operator preserved; its '?::jsonpath' placeholder -> $N.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@?' => '$.status == "active"' } });
  like $pos, qr/\@\? \$1::jsonpath/,
    '@? operator kept intact while its placeholder becomes $1::jsonpath';
  unlike $pos, qr/\@\$/, '@? was NOT corrupted into @$';
}

# '@?' operator plus a separate bound column: operator stays, both real
# placeholders numbered left-to-right.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@?' => '$.x' }, id => 7 });
  like $pos, qr/\@\? \$\d+::jsonpath/, '@? operator preserved alongside a bound column';
  like $pos, qr/"id" = \$1/, 'bound column id = $1 (leftmost placeholder)';
  like $pos, qr/\@\? \$2::jsonpath/, 'jsonpath placeholder numbered $2';
}

# '@@' jsonpath match: no '?' in the operator, only the real placeholder.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '@@' => '$.score > 10' } });
  like $pos, qr/\@\@ \$1::jsonpath/, '@@ operator + $1::jsonpath placeholder';
}

# (c) jsonb_exists_any(col, ARRAY[?, ?]) -> ARRAY[$1, $2]; each gets its own $N.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?|' => ['email', 'phone'] } });
  like $pos, qr/jsonb_exists_any\("me"\."data", ARRAY\[\$1, \$2\]\)/,
    'jsonb_exists_any ARRAY[?, ?] -> ARRAY[$1, $2]';
}
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?&' => ['name', 'email'] } });
  like $pos, qr/jsonb_exists_all\("me"\."data", ARRAY\[\$1, \$2\]\)/,
    'jsonb_exists_all ARRAY[?, ?] -> ARRAY[$1, $2]';
}

# jsonb_exists (single key) -> $1.
{
  my $pos = xlate('t', ['*'], { 'me.data' => { '?' => 'email' } });
  like $pos, qr/jsonb_exists\("me"\."data", \$1\)/, 'jsonb_exists(col, ?) -> $1';
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

done_testing;
