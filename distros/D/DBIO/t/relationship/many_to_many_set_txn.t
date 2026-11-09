use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# many_to_many set_* (karr k393) replaces the links in one transaction: the
# delete of the old links and the add_* of the new ones commit together or
# not at all.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

my $cd = $schema->resultset('CD')->new_result({ cdid => 1, artist => 1, title => 'T', year => 2000 });
$cd->in_storage(1);

subtest 'a failing add_* rolls the delete back' => sub {
  $storage->reset_captured;
  throws_ok { $cd->set_producers([ { no_such_column => 1 } ]) } qr/no_such_column/,
    'add_* with a bad column throws';

  my @ops = map { $_->{op} } $storage->captured_queries;
  ok( (grep { $_ eq 'delete' } @ops), 'the old links were deleted' );
  ok( (grep { $_ eq 'txn_begin' } @ops), 'inside a transaction' )
    or diag explain \@ops;
  ok( (grep { $_ eq 'txn_rollback' } @ops), 'which was rolled back' );
  ok( !(grep { $_ eq 'txn_commit' } @ops), 'and not committed' );
  is $storage->transaction_depth, 0, 'no transaction is left open';
};

subtest 'a successful set_* commits delete and adds together' => sub {
  $storage->reset_captured;
  $storage->mock(qr/SELECT/i, []);
  lives_ok { $cd->set_producers([ { producerid => 5, name => 'P' } ]) }
    'set_producers works';
  my @ops = map { $_->{op} } $storage->captured_queries;
  is( (scalar grep { $_ eq 'txn_commit' } @ops), 1, 'one commit' )
    or diag explain \@ops;
};

done_testing;
