use strict;
use warnings;

use Test::More;
use DBIO::Test ':DiffSQL';

my $schema = DBIO::Test->init_schema;

# captured_queries / reset_captured
{
  $schema->storage->reset_captured;
  is scalar($schema->storage->captured_queries), 0, 'no queries after reset';

  $schema->resultset('Artist')->search({ name => 'x' })->all;
  my @q = $schema->storage->captured_queries;
  is scalar @q, 1, 'one query captured after ->all';
  is $q[0]{op}, 'select', 'captured op is select';
  like $q[0]{sql}, qr/SELECT.*FROM artist/i, 'captured SQL is a SELECT on artist';
}

# captured_sql_bind
{
  $schema->storage->reset_captured;
  $schema->resultset('CD')->search({ title => 'test' })->all;
  my @pairs = $schema->storage->captured_sql_bind;
  is scalar @pairs, 1, 'one sql_bind pair';
  like $pairs[0][0], qr/SELECT.*FROM cd/i, 'sql_bind SQL correct';
}

# Multiple queries
{
  $schema->storage->reset_captured;
  $schema->resultset('Artist')->search({ name => 'a' })->all;
  $schema->resultset('CD')->search({ title => 'b' })->all;
  $schema->resultset('Track')->search({ position => 1 })->all;

  my @q = $schema->storage->captured_queries;
  is scalar @q, 3, 'three queries captured';
  like $q[0]{sql}, qr/artist/i, 'first query on artist';
  like $q[1]{sql}, qr/cd/i, 'second query on cd';
  like $q[2]{sql}, qr/track/i, 'third query on track';
}

# INSERT capture
{
  $schema->storage->reset_captured;
  eval { $schema->resultset('Artist')->create({ name => 'New Artist' }) };
  my @q = $schema->storage->captured_queries;
  ok scalar @q >= 1, 'insert captured';
  is $q[0]{op}, 'insert', 'captured op is insert';
  like $q[0]{sql}, qr/INSERT INTO artist/i, 'captured INSERT SQL';
}

# capture_executed_sql_bind on schema
{
  my $sqlbinds = $schema->capture_executed_sql_bind(sub {
    $schema->resultset('Artist')->search({ rank => 5 })->all;
  });

  ok @$sqlbinds >= 1, 'capture_executed_sql_bind captured queries';
  like $sqlbinds->[0][1][0], qr/SELECT.*FROM artist.*WHERE/i,
    'captured SQL has WHERE clause';
}

done_testing;
