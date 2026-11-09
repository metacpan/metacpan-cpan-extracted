use strict;
use warnings;
use Test::More;
use Test::Exception;

# PostGIS declares itself sync-only (k8, core k159, ADR 0032 addendum
# 2026-09-25, form A'). The layer DEFINES async_layer_class and answers undef:
# that is the stated opt-out of core's async-mirror resolver. A layer that
# says nothing is only skipped by a transitional silent path that core step 3
# turns into a refusal -- so without this declaration PostGIS would stop
# connecting under any { async => ... } mode.
#
# Offline: a DBIO::Test::Storage subclass plus a dummy transport, modelled on
# core t/composed/async_mirror.t scenario 3. No DSN, no event loop.

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::Composed;
use DBIO::SQLMaker;
use DBIO::PostgreSQL::PostGIS::Storage;

my $LAYER = 'DBIO::PostgreSQL::PostGIS::Storage';

# ===========================================================================
# (a) The declaration is the layer's OWN: defined in its symbol table, not
#     merely reachable through can() via some inherited class.
# ===========================================================================
{
  no strict 'refs';
  ok defined &{"${LAYER}::async_layer_class"},
    'the PostGIS layer defines async_layer_class itself (stated, not silent)';
}

# ===========================================================================
# (b) It answers undef for every async mode -- the family's registered modes
#     and an unknown one alike, so a future mode is sync-only by default too.
# ===========================================================================
for my $mode (qw( ev future_io forked immediate some_future_mode )) {
  my $answer = eval { [ scalar $LAYER->async_layer_class($mode) ] };
  is_deeply $answer, [ undef ],
    "async_layer_class('$mode') is undef: deliberately sync-only";
}

# ===========================================================================
# (c) The core resolver honours it: under an async mode the transport still
#     resolves, no PostGIS async layer is composed, nothing croaks -- and the
#     convention sibling ${LAYER}::Async is never even probed from disk. That
#     last assertion is what separates "stated" from the transitional silent
#     skip: a silent layer would trigger the require.
# ===========================================================================
{
  package T::PG55::Transport;
  use base 'DBIO::Storage::Async';
  use mro 'c3';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _query_async     { DBIO::Test::Future->done }

  package T::PG55::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
T::PG55::Storage->register_async_mode( ram => 'T::PG55::Transport' );

{
  my @attempts;
  local @INC = (
    sub {
      my (undef, $file) = @_;
      push @attempts, $file if $file eq 'DBIO/PostgreSQL/PostGIS/Storage/Async.pm';
      return;
    },
    @INC,
  );

  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer($LAYER);
  my $storage = T::PG55::Storage->new($schema);
  $storage->connect_info([ 'dbi:PG55Mock:', '', '', { async => 'ram' } ]);

  my $async;
  lives_ok { $async = $storage->async }
    'async backend resolves with the PostGIS layer registered (no croak)';
  isa_ok $async, 'T::PG55::Transport', 'async backend';
  ok !$async->isa($LAYER),
    'the sync PostGIS layer is not carried into the async backend';
  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ], [],
    'no async layer is composed for PostGIS';
  is_deeply \@attempts, [],
    "the resolver never probed ${LAYER}::Async -- the opt-out is stated";
}

done_testing;
