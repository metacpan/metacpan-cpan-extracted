use strict;
use warnings;

use Test::More;
use DBIO::Test;

# with_deferred_fk_checks defers constraints for the length of a transaction.
# In Informix, constraint mode ends with the transaction: SET CONSTRAINTS ALL
# IMMEDIATE after the COMMIT dies with -255 "Not in transaction" (measured
# against Informix 15.0.1, karr k20). So the switch back to IMMEDIATE has to
# come before the COMMIT, where it also makes the deferred checks run.

my @log;
{
  package Test::Txn;
  sub commit { push @log, 'COMMIT' }
}

{
  package Test::Informix::Storage;
  use base 'DBIO::Informix::Storage';
  sub txn_scope_guard { bless {}, 'Test::Txn' }
  sub _do_query { push @log, $_[1] }
}

my $declared = DBIO::Test::Schema->clone(
  storage_type => '+Test::Informix::Storage',
);
my $storage = $declared->connect(sub { die 'no connect expected' })->storage;

my $got = $storage->with_deferred_fk_checks(sub { push @log, 'BODY'; 42 });
is $got, 42, 'the return value of the body is passed on';

is_deeply \@log, [
  'SET CONSTRAINTS ALL DEFERRED',
  'BODY',
  'SET CONSTRAINTS ALL IMMEDIATE',
  'COMMIT',
], 'IMMEDIATE comes before COMMIT, not after it';

done_testing;
