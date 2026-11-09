use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::MySQL::EV::Storage;

# OFFLINE: what the REAL EV transport does with $txn_ctx->pipeline (karr k42,
# after core karr k213). The context now runs core's pipeline scaffold on its
# pinned txn connection via _pipeline_on_conn, without a release coderef. This
# transport overrides none of _pipeline_enter/_sync/_exit (ADR 0009: EV::MariaDB
# has no pipeline-mode API to bracket). Since core karr k218 the context asks the
# storage's _pipeline_refusal first, so the call is refused BEFORE the scaffold
# (_pipeline_on_conn) is entered -- as a FAILED Future carrying a DBIO::Exception
# that says the transport does not support pipeline(), not a throw -- and it must
# do so without borrowing a pool connection and without releasing the txn
# connection (that belongs to the COMMIT/ROLLBACK boundary). Before k218 the
# failure came from inside the scaffold, at the base _pipeline_enter croak (karr
# k43 moved the claim to the refusal). t/transaction-context.t pins
# the context's routing against a mock storage; this pins the transport's
# answer to it.

{
  package DBIO::MySQL::EV::Test::PipelineSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  __PACKAGE__->load_classes({ 'DBIO::Test::Schema' => [qw(Artist)] });
}
{
  # Pre-wired in place of the lazy EV::MariaDB pool: records every call, so any
  # acquire (a second connection) or release (of the txn connection) shows up.
  package DBIO::MySQL::EV::Test::SpyPool;
  sub new     { bless { calls => [] }, shift }
  sub acquire { push @{ $_[0]{calls} }, 'acquire'; Future->done('POOLED_CONN') }
  sub release { push @{ $_[0]{calls} }, [ release => $_[1] ] }
  sub shutdown { }
}
{
  package DBIO::MySQL::EV::Test::FakeConn;
  sub new { bless {}, shift }
}

# Driver resolution is lazy: connect, then force the EV backend through the
# sync storage so owner + generation token are wired (as in
# t/with-context-ownership-mock.t). No socket is opened.
my $schema = DBIO::MySQL::EV::Test::PipelineSchema->connect(
  'dbi:mysql:database=t;host=localhost', 'u', 'p', { async => 'ev' },
);
my $backend = $schema->storage->_async_storage;
isa_ok $backend, 'DBIO::MySQL::EV::Storage', 'resolved EV backend';

my $pool = DBIO::MySQL::EV::Test::SpyPool->new;
$backend->{pool} = $pool;

my $conn = DBIO::MySQL::EV::Test::FakeConn->new;
my $ctx  = $backend->_txn_context_class->new(
  storage  => $backend,
  txn_conn => $conn,
);
isa_ok $ctx, 'DBIO::MySQL::EV::TransactionContext';

my $ran = 0;
my $scaffold = 0;
my $f;
{
  # Count scaffold entries without changing what it does: the refusal must
  # come before it, so a pre-k218 failure from inside the scaffold fails here.
  no warnings 'redefine';
  my $orig = DBIO::Storage::Async->can('_pipeline_on_conn');
  local *DBIO::Storage::Async::_pipeline_on_conn = sub { $scaffold++; $orig->(@_) };
  lives_ok { $f = $ctx->pipeline(sub { $ran++ }) }
    '$txn_ctx->pipeline does not throw synchronously';
}
isa_ok $f, 'Future';
ok $f->is_failed, '... it returns a FAILED Future (no pipeline seam here)';
isa_ok scalar $f->failure, 'DBIO::Exception', '... carrying a DBIO::Exception';
like scalar $f->failure,
  qr/DBIO::MySQL::EV::Storage does not support pipeline\(\)/,
  '... that names this transport as unable to pipeline';
is $scaffold, 0, '... refused before the pipeline scaffold is entered';
ok !$ran, 'the batch coderef never runs';
is_deeply $pool->{calls}, [],
  'no pool connection acquired, and the txn connection is not released';
ok $ctx->_context_active, 'the txn context is still active afterwards';

done_testing;
