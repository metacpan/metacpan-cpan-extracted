use strict;
use warnings;

use Test::More;
use Test::Warn;

use DBIO::SQLite::Test ':DiffSQL';

my $schema = DBIO::SQLite::Test->init_schema();

my $sql_maker = $schema->storage->sql_maker;

# SQL::Abstract v2 handles -nest internally without going through
# ClassicExtensions' _where_op_NEST, so no deprecation warning is emitted.
# Just verify the SQL is correct.
for my $pass (1, 2) {
  my ($sql, @bind) = $sql_maker->select ('foo', undef, { -nest => \ 'bar' } );
  is_same_sql_bind (
    $sql, \@bind,
    'SELECT * FROM "foo" WHERE ( bar )', [],
    "-nest still works (pass $pass)"
  );
}

done_testing;
