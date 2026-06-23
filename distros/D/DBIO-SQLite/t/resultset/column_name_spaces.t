use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Test that __strip_relcond handles column names with non-word characters
# This is the fix from DBIx::Class PR #129: changing (\w+) to (.+) in the
# regex that strips foreign/self prefixes from relationship conditions.

my $rsrc = $schema->source('Artist');

# __strip_relcond strips 'foreign.' and 'self.' prefixes from condition keys/values
# With the old \w+ regex, column names containing spaces or punctuation would
# fail to match, returning an empty hashref instead of the stripped column names.

# Test with normal column names (should always work)
{
  my $cond = { 'foreign.artistid' => 'self.artistid' };
  my $stripped = $rsrc->__strip_relcond($cond);
  is_deeply(
    $stripped,
    { 'artistid' => 'artistid' },
    '__strip_relcond works with normal column names',
  );
}

# Test with column names containing spaces
{
  my $cond = { 'foreign.foo bar' => 'self.baz quux' };
  my $stripped = $rsrc->__strip_relcond($cond);
  is_deeply(
    $stripped,
    { 'foo bar' => 'baz quux' },
    '__strip_relcond works with column names containing spaces',
  );
}

# Test with column names containing punctuation (like PunctuatedColumnName schema)
{
  my $cond = { q{foreign.foo ' bar} => q{self.bar/baz} };
  my $stripped = $rsrc->__strip_relcond($cond);
  is_deeply(
    $stripped,
    { q{foo ' bar} => q{bar/baz} },
    '__strip_relcond works with column names containing punctuation',
  );
}

# Test with column names containing semicolons
{
  my $cond = { 'foreign.baz;quux' => 'self.id' };
  my $stripped = $rsrc->__strip_relcond($cond);
  is_deeply(
    $stripped,
    { 'baz;quux' => 'id' },
    '__strip_relcond works with column names containing semicolons',
  );
}

# Test with multiple columns, some with special characters
{
  my $cond = {
    'foreign.normal_col'  => 'self.id',
    'foreign.spaced col'  => 'self.another col',
  };
  my $stripped = $rsrc->__strip_relcond($cond);
  is_deeply(
    $stripped,
    { 'normal_col' => 'id', 'spaced col' => 'another col' },
    '__strip_relcond works with mixed normal and spaced column names',
  );
}

done_testing;
