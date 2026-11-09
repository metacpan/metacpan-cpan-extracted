use strict;
use warnings;
use Test::More;

use DBIO::Test;

# karr k331 (finding "ResultSet::pager counts unbound"): the count resultset
# that ResultSet::pager builds for the lazy total_entries is bound to the same
# async context as the paged resultset, as the Pager ASYNC recipe does by
# hand. An unbound resultset is unchanged. Mock only; in the 'immediate' mode
# the context is the storage itself.

my $schema  = DBIO::Test->init_schema;
my $storage = $schema->storage;
is $storage->_async_mode, 'immediate', 'the fake storage is in the immediate mode';

# What the count resultset is bound to when the pager asks for the total.
my @counted;
{
  no warnings 'redefine';
  my $count = \&DBIO::ResultSet::count;
  local *DBIO::ResultSet::count = sub {
    push @counted, $_[0]->_async_context;
    goto &$count;
  };

  $storage->mock(qr/COUNT/i, [[ 7 ]]);

  # bound: the count goes through the context
  my ($ctx_seen, $pager);
  $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx_seen = $ctx;
    my $rs = $schema->resultset('Artist')->search(undef, { rows => 3 })
      ->page(2)->with_context($ctx);
    $pager = $rs->pager;
    @counted = ();
    is $pager->total_entries, 7, 'bound: the pager yields the total';
    return 1;
  })->get;

  is scalar(@counted), 1, 'bound: one count ran for the total';
  ok defined $counted[0] && $counted[0] == $ctx_seen,
    'bound: the count resultset is bound to the context of the paged one';

  # unbound: nothing changes
  $storage->mock(qr/COUNT/i, [[ 7 ]]);
  @counted = ();
  my $plain = $schema->resultset('Artist')->search(undef, { rows => 3 })->page(1)->pager;
  is $plain->total_entries, 7, 'unbound: the pager yields the total';
  is scalar(@counted), 1, 'unbound: one count ran for the total';
  ok !defined $counted[0], 'unbound: the count resultset carries no context';
}

done_testing;
