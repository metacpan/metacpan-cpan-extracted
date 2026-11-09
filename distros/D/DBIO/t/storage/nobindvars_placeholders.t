use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Storage::DBI::NoBindVars;

# NoBindVars writes the bind values into the statement in place of its
# placeholders. Only a free ? is a placeholder: a ? inside a quoted identifier
# or a string literal belongs to the name or the text, and the number of
# placeholders has to equal the number of binds.

{
  package My::QuoteDbh;
  sub new   { bless {}, shift }
  sub quote { my $v = $_[1]; $v =~ s/'/''/g; "'$v'" }

  package My::NBV::Storage;
  our @ISA = ('DBIO::Storage::DBI::NoBindVars');
  sub _get_dbh { My::QuoteDbh->new }
}

my $storage = bless {}, 'My::NBV::Storage';

sub run {
  my ($sql, @vals) = @_;
  my ($out, $bind) = $storage->_interpolate_bind_values(
    $sql, [ map { [ {}, $_ ] } @vals ],
  );
  is_deeply $bind, [], 'no binds left';
  return $out;
}

is run('SELECT a FROM t WHERE b = ? AND c = ?', 1, 'x'),
  q{SELECT a FROM t WHERE b = '1' AND c = 'x'},
  'free ? are replaced in order';

is run('SELECT 1 FROM t WHERE "a?" = ? AND "secret" = ?', 'x', 'y'),
  q{SELECT 1 FROM t WHERE "a?" = 'x' AND "secret" = 'y'},
  'a ? in a quoted identifier is part of the name';

is run('SELECT 1 FROM t WHERE `a?` = ? AND [b?] = ?', 'x', 'y'),
  q{SELECT 1 FROM t WHERE `a?` = 'x' AND [b?] = 'y'},
  'backtick and bracket identifiers too';

is run(q{SELECT 1 FROM t WHERE note = '?' AND c = ?}, 'z'),
  q{SELECT 1 FROM t WHERE note = '?' AND c = 'z'},
  'a ? in a string literal is text';

is run(q{SELECT 1 FROM t WHERE note LIKE 'it''s ?' AND c = ?}, 'z'),
  q{SELECT 1 FROM t WHERE note LIKE 'it''s ?' AND c = 'z'},
  'a doubled quote does not end the literal';

is run('SELECT 1 FROM t WHERE "a?" = ? AND "secret" = ?', q{x" OR "1"="1}, q{y'z}),
  q{SELECT 1 FROM t WHERE "a?" = 'x" OR "1"="1' AND "secret" = 'y''z'},
  'bind values with " and \' land in their own place';

is run('SELECT 1 FROM t WHERE x = ?', 'v') , q{SELECT 1 FROM t WHERE x = 'v'},
  'a trailing placeholder';

throws_ok { run('SELECT 1 FROM t WHERE a = ? AND b = ?', 1) }
  qr/placeholder count 2 does not match bind count 1/,
  'fewer binds than placeholders throws';

throws_ok { run('SELECT 1 FROM t WHERE "a?" = 1', 1) }
  qr/placeholder count 0 does not match bind count 1/,
  'more binds than free placeholders throws';

throws_ok { run('SELECT 1 FROM t WHERE a = ?', 'secret-value', 'other') }
  qr/placeholder count 1 does not match bind count 2(?!.*(?:secret-value|other))/s,
  'the message names counts, never a value';

is_deeply [ DBIO::Storage::DBI::NoBindVars::split_at_placeholders(q{a "?" ? 'x?' ?}) ],
  [ q{a "?" }, q{ 'x?' }, '' ],
  'split_at_placeholders returns the text around the free ?';

# Comments: a ? in `-- ...` (to end of line) or `/* ... */` is text.
is run("SELECT 1 FROM t -- why? really?\nWHERE a = ?", 'x'),
  "SELECT 1 FROM t -- why? really?\nWHERE a = 'x'",
  'a ? in a line comment is text';

is run('SELECT /* which? */ 1 FROM t WHERE a = ? /* and? */ AND b = ?', 1, 2),
  q{SELECT /* which? */ 1 FROM t WHERE a = '1' /* and? */ AND b = '2'},
  'a ? in a block comment is text';

is run(q{SELECT 1 FROM t WHERE a = '--' AND b = ?}, 'x'),
  q{SELECT 1 FROM t WHERE a = '--' AND b = 'x'},
  '-- in a string literal is no comment';

is run(q{SELECT "a--b" FROM t WHERE b = ?}, 'x'),
  q{SELECT "a--b" FROM t WHERE b = 'x'},
  '-- in a quoted identifier is no comment';

is run(q{SELECT '/*' FROM t WHERE b = ? AND c = '*/'}, 'x'),
  q{SELECT '/*' FROM t WHERE b = 'x' AND c = '*/'},
  '/* in a string literal is no comment';

is run('SELECT 1 FROM t WHERE a = ? -- trailing ?', 'x'),
  q{SELECT 1 FROM t WHERE a = 'x' -- trailing ?},
  'an open line comment at the end stays text';

is run('SELECT 1 FROM t WHERE a = ? /* open ?', 'x'),
  q{SELECT 1 FROM t WHERE a = 'x' /* open ?},
  'an open block comment at the end stays text';

is_deeply [ DBIO::Storage::DBI::NoBindVars::split_at_placeholders("a -- ?\n? /* ? */ ?") ],
  [ "a -- ?\n", ' /* ? */ ', '' ],
  'split_at_placeholders skips comments';

for my $sql (
  'SELECT 1 WHERE a = ? AND b = ?',
  q{SELECT '?' "?" -- ?\n/* ? */ WHERE a = ? AND [x?] = ?},
  'SELECT ? /* ? */ , ? -- ?',
  'SELECT 1',
) {
  my @off  = DBIO::Storage::DBI::NoBindVars::placeholder_offsets($sql);
  my @part = DBIO::Storage::DBI::NoBindVars::split_at_placeholders($sql);
  is scalar(@off), $#part, 'offset count equals placeholder count';
  is join('', map { substr($sql, $_, 1) } @off), '?' x @off, 'every offset points at a ?';
  my ($pos, $rebuilt) = (0, '');
  for my $o (@off) { $rebuilt .= substr($sql, $pos, $o - $pos); $pos = $o + 1; $rebuilt .= "\0" }
  $rebuilt .= substr($sql, $pos);
  is $rebuilt, join("\0", @part), 'offsets cut the statement where split_at_placeholders does';
}

is run("SELECT ? -- a?\n, ? /* b? */", 1, 2),
  "SELECT '1' -- a?\n, '2' /* b? */",
  '_interpolate_bind_values with comments in the statement';

done_testing;
