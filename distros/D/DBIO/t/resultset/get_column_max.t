use strict;
use warnings;

use Test::More;

use DBIO::Test;

# Backs the DBIO::ResultSetColumn SYNOPSIS end-to-end:
#
#   $rs        = $schema->resultset('CD')->search({ artist => ... });
#   $rs_column = $rs->get_column('year');
#   $max_year  = $rs_column->max;   # returns the latest year (a SCALAR)
#
# Adjacent coverage (t/resultset/as_query.t) exercises ->as_query / the *_rs
# resultset builders, but nothing asserted the scalar aggregate *return value*
# the SYNOPSIS actually shows. This does -- mock-only: the MAX(...) query is
# intercepted and its single scalar comes back through ->max.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my $rs     = $schema->resultset('CD')->search({ artist => 1 });
my $rscol  = $rs->get_column('year');
isa_ok $rscol, 'DBIO::ResultSetColumn', 'get_column';

subtest 'max returns the scalar aggregate value (SYNOPSIS)' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT\s+MAX\s*\(/is, [ [ '2001' ] ]);

  my $max_year = $rscol->max;
  is $max_year, '2001', '->max returns the latest year as a plain scalar';

  my ($q) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $q, 'a select was issued for the aggregate';
  like $q->{sql}, qr/MAX\(\s*"me"\."year"\s*\)/i, 'the query aggregates with MAX(year)';
};

subtest 'max returns undef when the aggregate yields no rows' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT\s+MAX\s*\(/is, []);

  is $rscol->max, undef, '->max is undef over an empty set, per the docs';
};

done_testing;
