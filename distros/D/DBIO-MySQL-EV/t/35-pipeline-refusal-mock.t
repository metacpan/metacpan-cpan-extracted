use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k52: what $storage->pipeline does on this transport.
#
# WHY IT MATTERS. This transport has no pipeline mode (ADR 0009): EV::MariaDB
# has nothing to bracket, so DBIO::MySQL::EV::Storage overrides none of core's
# _pipeline_enter / _pipeline_sync / _pipeline_exit seams. pipeline() is still
# inherited public API, and the README, the POD and ADR 0009 tell a caller what
# it gets from it: a FAILED FUTURE that names this transport, handed back
# before a connection is taken from the pool and without the batch running --
# not a croak. A caller chaining ->else on the result relies on exactly that,
# and so does a pool nobody has to get a connection back from.
#
# The answer is core's (DBIO::Storage::Async::_pipeline_refusal, core k218);
# what is claimed here is that this transport gives it. The claim fails when
# the transport grows a pipeline seam, or a pipeline() of its own, without
# these docs being rewritten, and on a core whose scaffold takes the
# connection first and croaks at the bare seam.
#
# The same answer on a transaction context ($ctx->pipeline) is held by
# t/txn-context-pipeline-mock.t.

use DBIO::Storage::Async;
use DBIO::MySQL::EV::Storage;

{
  # In place of the lazy EV::MariaDB pool: records every call, so a connection
  # taken for the refused batch shows up.
  package SpyPool;
  sub new      { bless { calls => [] }, shift }
  sub acquire  { push @{ $_[0]{calls} }, 'acquire'; $_[0]{future_class}->done('CONN') }
  sub release  { push @{ $_[0]{calls} }, 'release' }
  sub shutdown { }
}

my $EV = 'DBIO::MySQL::EV::Storage';

# --- 0. the premise: no pipeline seam, no pipeline() of its own --------------

is $EV->can('_pipeline_enter'), DBIO::Storage::Async->can('_pipeline_enter'),
  '_pipeline_enter is core\'s stub: this transport fills no pipeline seam';
is $EV->can('pipeline'), DBIO::Storage::Async->can('pipeline'),
  'pipeline is core\'s: this transport defines none of its own';

# --- 1. the call is refused through a failed Future --------------------------

my $storage = $EV->new(undef);
my $pool = SpyPool->new;
$pool->{future_class} = $storage->future_class;
$storage->{pool} = $pool;

my $ran = 0;
my $f = eval { $storage->pipeline(sub { $ran++ }) };
is $@, '', '$storage->pipeline does not throw';
isa_ok $f, 'DBIO::MySQL::EV::Future', 'it returns the transport\'s Future';
ok $f->is_ready,  '... already settled';
ok $f->is_failed, '... and failed';

my $error = $f->failure;
isa_ok $error, 'DBIO::Exception', 'the failure';
like "$error", qr/\QDBIO::MySQL::EV::Storage does not support pipeline()\E/,
  '... names this transport as unable to pipeline';

is $ran, 0, 'the batch never ran';
is_deeply $pool->{calls}, [],
  'no connection was taken from the pool, and none released';

done_testing;
