use strict;
use warnings;

use Test::More;
use Test::Warn;

use DBIO::SQLite::Test;

# Regression test for RT#169546
# DBIO incorrectly warns about missing primary key values when using
# scalar references for database functions (like \'UUID()', \'RANDOM()', etc.)

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Create a test table with a non-auto-increment primary key
$schema->storage->dbh->do(q{
  CREATE TABLE test_scalar_ref (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(100)
  )
});

{
  package DBIO::Test::Schema::TestScalarRef;
  use base 'DBIO::Core';

  __PACKAGE__->table('test_scalar_ref');
  __PACKAGE__->add_columns(
    id => {
      data_type => 'integer',
      is_nullable => 0,
    },
    name => {
      data_type => 'varchar',
      size => 100,
      is_nullable => 1,
    },
  );
  __PACKAGE__->set_primary_key('id');
}

# Register the test table as a result source
$schema->register_class(
  TestScalarRef => 'DBIO::Test::Schema::TestScalarRef'
);

# Test 1: Scalar reference for database function should NOT warn (RT#169546)
warning_is {
  my $row = $schema->resultset('TestScalarRef')->create({
    id => \'ABS(RANDOM())',
    name => 'Test Record',
  });
  isa_ok($row, 'DBIO::Test::Schema::TestScalarRef', 'Row created with scalar ref');
} undef,
  'RT#169546: Scalar reference for database function should not warn about missing PK';

# Test 2: Truly missing primary key SHOULD warn
warning_like {
  my $row = $schema->resultset('TestScalarRef')->create({
    name => 'Test Record 2',
  });
} qr/Missing value for primary key/,
  'Missing primary key correctly generates warning';

# Test 3: Explicit value should not warn
warning_is {
  my $row = $schema->resultset('TestScalarRef')->create({
    id => 12345,
    name => 'Test Record 3',
  });
} undef, 'Explicit primary key value does not warn';

done_testing();
