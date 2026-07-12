use strict;
use warnings;

use Test::More;

use DBIO::Test;

# Backs the identical SYNOPSIS of both DBIO::Cursor and
# DBIO::Storage::DBI::Cursor: the public $rs->cursor() API yields *raw*
# column-value lists (not inflated Row objects) in resultset select order.
#
#   my $cursor = $schema->resultset('CD')->cursor;
#   my @next_cd_column_values = $cursor->next;   # one row, as a flat list
#   my @all_cds_column_values = $cursor->all;     # all rows, as arrayrefs
#
# Mock-only (CLAUDE.md): DBIO::Test::Storage's fake cursor returns exactly the
# raw arrayrefs registered via ->mock, after routing the select args through
# $storage->_select_args (karr #55), so the round trip we assert is the same
# raw-value contract a real DBIO::Storage::DBI::Cursor exposes.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

# Pin the select order so "raw values in select order" is a concrete claim.
my @cols = qw/cdid title year/;

subtest 'cursor->next yields one raw column-value list in select order' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM cd\b/is, [ [ 1, 'Spoonful of bees', '1999' ] ]);

  my $cursor = $schema->resultset('CD')->search(undef, { columns => \@cols })->cursor;
  isa_ok $cursor, 'DBIO::Cursor', 'the resultset cursor';

  my @vals = $cursor->next;
  is_deeply \@vals, [ 1, 'Spoonful of bees', '1999' ],
    'next returns the raw values of the first row as a flat list';
  is scalar(@vals), scalar(@cols), 'one raw value per selected column';

  is_deeply [ $cursor->next ], [], 'next returns empty once the rows are exhausted';
};

subtest 'cursor->all yields every row as an arrayref of raw values' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM cd\b/is, [
    [ 1, 'Spoonful of bees', '1999' ],
    [ 2, 'Forkful of bees',  '2001' ],
    [ 3, "Caterwaulin' Blues", undef ],
  ]);

  my $cursor = $schema->resultset('CD')->search(undef, { columns => \@cols })->cursor;
  my @all = $cursor->all;

  is_deeply \@all, [
    [ 1, 'Spoonful of bees', '1999' ],
    [ 2, 'Forkful of bees',  '2001' ],
    [ 3, "Caterwaulin' Blues", undef ],
  ], 'all returns the full row set, each row a raw-value arrayref';
};

subtest 'the captured SQL is the SQL a real cursor would have run (karr #55)' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*FROM cd\b/is, [ [ 1, 'x', '1999' ] ]);

  my $rs = $schema->resultset('CD')->search(undef, { columns => \@cols });
  my $cursor = $rs->cursor;
  $cursor->next;

  my ($q) = grep { $_->{op} eq 'select' } $storage->captured_queries;
  ok $q, 'the cursor captured a select';

  # as_query renders the same select wrapped as a subquery -- strip the
  # wrapping parens to compare the captured cursor SQL against it.
  (my $as_query_sql = ${ $rs->as_query }->[0]) =~ s/\A\((.*)\)\z/$1/s;
  is $q->{sql}, $as_query_sql,
    'fake-cursor SQL equals the resultset as_query SQL';
};

done_testing;
