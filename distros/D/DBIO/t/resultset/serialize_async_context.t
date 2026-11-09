use strict;
use warnings;

use Test::More;
use Storable qw(nfreeze thaw);

use DBIO::Test;
use DBIO::Test::Future ();

# karr k331: STORABLE_freeze dropped the cursor and the parsers but kept the
# async context a resultset was bound to with_context. A context is a live
# object (a storage, a transaction connection); it is what made the frozen
# form of a bound resultset ~30 times the size of an unbound one, and it
# cannot mean anything after thaw. A frozen resultset is unbound.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $unbound = $schema->resultset('Artist')->search({ rank => 13 });

my $bound;
$schema->storage->txn_do_async(sub {
  $bound = $unbound->with_context($_[0]);
  return DBIO::Test::Future->done(1);
});
ok $bound->_async_context, 'the resultset is bound to a context';

local $DBIO::ResultSource::thaw_schema = $schema;

my $frozen_unbound = nfreeze($unbound);
my $frozen_bound   = nfreeze($bound);

cmp_ok length($frozen_bound), '<=', length($frozen_unbound) + 16,
  'a frozen bound resultset is no larger than the unbound one'
  or diag sprintf 'bound %d bytes, unbound %d', length $frozen_bound, length $frozen_unbound;

my $thawed = thaw($frozen_bound);
isa_ok $thawed, 'DBIO::ResultSet';
is $thawed->_async_context, undef, 'the thawed resultset is unbound';
is_deeply $thawed->{cond}, { rank => 13 }, 'the rest of the resultset survived';

done_testing;
