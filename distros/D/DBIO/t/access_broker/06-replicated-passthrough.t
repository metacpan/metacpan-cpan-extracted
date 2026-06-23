# ABSTRACT: AccessBroker survives the Replicated connect paths + HostBound shared lease
use strict;
use warnings;

use Test::More;
use Scalar::Util 'refaddr';

use DBIO::Test;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;

# A broker that hands back a dbi:Test DSN arrayref (the shape DBIO::Test::Storage
# understands without a real driver), so we can drive it through Replicated.
{
  package DSNBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { dsn => $_[1] }, $_[0] }
  sub connect_info_for { [ $_[0]->{dsn}, '', '', {} ] }
}

# A broker that counts credential rotations, for the HostBound shared-lease test.
{
  package CountingBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { refreshes => 0 }, $_[0] }
  sub connect_info_for { { dbname => 'app', user => 'u', password => 'p' } }
  sub needs_refresh { 0 }
  sub refresh { $_[0]->{refreshes}++ }
  sub has_rotating_credentials { 1 }
}

my $schema = DBIO::Test->init_schema(
  no_deploy => 1,
  storage_type => {
    '+DBIO::Replicated::Storage' => {
      backend_storage_class => 'DBIO::Test::Storage',
      balancer_type         => 'DBIO::Replicated::Balancer::First',
    },
  },
);
my $rstorage = $schema->storage;

# ---------------------------------------------------------------------------
# Guard unit tests: a broker is a CredentialSource, not an options hash. The
# Replicated connect paths must pass it through by identity, never copy/merge
# it (which would splat the blessed object into key/value pairs).
# ---------------------------------------------------------------------------
{
  my $broker = DBIO::AccessBroker::Static->new(
    dbname => 'app', username => 'u', password => 'p',
  );

  my ($filtered, $opts) = $rstorage->_parse_connect_info([$broker]);
  is scalar(@$filtered), 1, '_parse_connect_info keeps the broker as a single element';
  is refaddr($filtered->[0]), refaddr($broker),
    '_parse_connect_info passes the broker through by identity (not shredded)';
  ok $filtered->[0]->isa('DBIO::AccessBroker'), 'still a blessed broker after parse';
  is_deeply $opts->{master_connect_opts}, {},
    'broker guts were not splatted into master_connect_opts';

  # Master opts that the merge would normally fold into a replicant options hash.
  $rstorage->_master_connect_info_opts({ AutoCommit => 1 });
  my $merged = $rstorage->_merge_replicant_connect_info([$broker]);
  is scalar(@$merged), 1, '_merge_replicant_connect_info keeps the broker single';
  is refaddr($merged->[0]), refaddr($broker),
    '_merge_replicant_connect_info passes the broker through by identity (no master-opt merge)';
}

# ---------------------------------------------------------------------------
# Integration: a broker as the master CredentialSource, and a mixed replicant
# pool (one broker-backed, one plain DSN). Each backend Storage consumes its
# own broker; the plain-DSN replicant has none.
# ---------------------------------------------------------------------------
{
  my $master_broker = DSNBroker->new('dbi:Test:master');
  $rstorage->connect_info([$master_broker]);

  is refaddr($rstorage->master->storage->access_broker), refaddr($master_broker),
    'master backend consumed the broker as its CredentialSource';

  my $rep_broker = DSNBroker->new('dbi:Test:rep_one');
  my @reps = $rstorage->connect_replicants(
    [$rep_broker],
    ['dbi:Test:rep_two', '', '', { AutoCommit => 1 }],
  );

  is scalar(@reps), 2, 'both replicants connected (broker + plain DSN)';
  is refaddr($reps[0]->storage->access_broker), refaddr($rep_broker),
    'broker-backed replicant consumed its own broker';
  ok defined($reps[0]->id), 'broker-backed replicant got a non-undef pool key';
  ok !$reps[1]->storage->access_broker,
    'plain-DSN replicant has no broker attached';
  is $reps[1]->id, 'rep_two', 'plain-DSN replicant keyed from its DSN';
}

# ---------------------------------------------------------------------------
# HostBound: one credential, many hosts. Views share a single lease and
# rotation schedule; only the host they inject differs.
# ---------------------------------------------------------------------------
{
  my $cred = CountingBroker->new;
  my $view_a = $cred->for_host('host-a');
  my $view_b = $cred->for_host({ host => 'host-b', port => 5433 });

  isa_ok $view_a, 'DBIO::AccessBroker::HostBound', 'for_host returns a HostBound view';
  isa_ok $view_a, 'DBIO::AccessBroker', 'a HostBound view is itself a broker';

  is refaddr($view_a->underlying_broker), refaddr($cred),
    'view A wraps the shared CredentialSource';
  is refaddr($view_b->underlying_broker), refaddr($cred),
    'view B wraps the same CredentialSource';

  $view_a->refresh;
  is $cred->{refreshes}, 1, 'refresh through view A rotates the shared lease';
  $view_b->refresh;
  is $cred->{refreshes}, 2, 'refresh through view B rotates the same lease';

  ok $view_a->has_rotating_credentials, 'view reports the underlying rotation';
  ok !$view_a->is_transaction_safe, 'a rotating broker view is not transaction-safe';

  my $info_a = $view_a->connect_info_for;
  is $info_a->{host}, 'host-a', 'view A binds host-a into the connect info';
  is $info_a->{dbname}, 'app', 'credentials still come from the shared broker';

  my $info_b = $view_b->connect_info_for;
  is $info_b->{host}, 'host-b', 'view B binds host-b';
  is $info_b->{port}, 5433, 'view B binds its port too';
}

done_testing;
