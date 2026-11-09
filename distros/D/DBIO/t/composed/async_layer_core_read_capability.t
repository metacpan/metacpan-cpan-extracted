# ABSTRACT: an async layer that requires broker_connect_options -- a capability
# core reads, not layers -- over a transport with no query seam (karr k268)
#
# The layer gate in DBIO::Storage::DBI::_async_storage answers "does this
# transport offer what the layer needs" from transport_capabilities, all of
# them. One of those names is not about layers: broker_connect_options says the
# transport applies the connect options given beside an AccessBroker to every
# connection it opens, and core reads it for that (karr k243). It describes no
# query path. Since DBIO::Forked declares it (dbio-forked k12), a layer naming
# it as its requirement passes the gate on a Model A transport -- one that does
# not own the query path -- and composes over nothing it could wrap.
#
# k268 (decision 2026-10-09): core-read names are kept out of the layer gate.
# A layer requiring one is refused on every transport, Model A and B alike.
# No layer in the family asks for that name.
use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::Composed;
use DBIO::Future::Immediate;

# ---------------------------------------------------------------------------
# Transports. Model A is the DBIO::Forked shape: it overrides the *_async entry
# points and inherits the abstract _query_async stub -- no seam for a layer.
# ---------------------------------------------------------------------------
{
  package T::K268::ModelA;
  use base 'DBIO::Storage::Async';
  use mro 'c3';
  our @SELECTED;
  sub future_class        { 'DBIO::Future::Immediate' }
  sub select_async        { push @SELECTED, $_[1]; DBIO::Future::Immediate->done([ 1, 'row' ]) }
  sub select_single_async { DBIO::Future::Immediate->done([]) }
  sub insert_async        { DBIO::Future::Immediate->done([]) }
  sub update_async        { DBIO::Future::Immediate->done(0)  }
  sub delete_async        { DBIO::Future::Immediate->done(0)  }
  sub txn_do_async        { DBIO::Future::Immediate->done(1)  }
}

# Model A, taking connect options beside a broker: DBIO::Forked since k12.
{
  package T::K268::ModelA::Declaring;
  use base 'T::K268::ModelA';
  use mro 'c3';
  sub transport_capabilities { ('broker_connect_options') }
}

# Model B: owns the query path, and declares the same.
{
  package T::K268::ModelB::Declaring;
  use base 'DBIO::Storage::Async';
  use mro 'c3';
  sub future_class           { 'DBIO::Future::Immediate' }
  sub transport_capabilities { ('broker_connect_options') }
  sub _query_async           { DBIO::Future::Immediate->done([]) }
}

# ---------------------------------------------------------------------------
# Layers. "Asking" requires the core-read name and wraps the query seam, which
# is all an async layer can do; "Silent" declares nothing.
# ---------------------------------------------------------------------------
{ package T::K268::Asking; sub asking_sync { 1 } }
{
  package T::K268::Asking::Async;
  use mro 'c3';
  our $WRAPPED = 0;
  sub required_transport_capabilities { ('broker_connect_options') }
  sub _query_async { my $self = shift; $WRAPPED++; return $self->next::method(@_) }
}

{ package T::K268::Silent;        sub silent_sync  { 1 } }
{ package T::K268::Silent::Async; sub silent_async { 1 } }

# Sanity: the transports differ in the property under test.
my $abstract_seam = DBIO::Storage::Async->can('_query_async');
is( T::K268::ModelA::Declaring->can('_query_async'), $abstract_seam,
  'sanity: the Model A transport inherits the abstract stub -- no seam' );
isnt( T::K268::ModelB::Declaring->can('_query_async'), $abstract_seam,
  'sanity: the Model B transport overrides the _query_async seam' );

# A fresh sync storage of $storage_class, bound to a live schema carrying
# @layers, in the 'ram' mode that class registered. The caller holds $schema.
sub build_storage {
  my ($storage_class, @layers) = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer($_) for @layers;
  my $storage = $storage_class->new($schema);
  $storage->connect_info([ 'dbi:K268Mock:', '', '', { async => 'ram' } ]);
  return ($storage, $schema);
}

{
  package T::K268::A::Storage;  use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::K268::AD::Storage; use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::K268::BD::Storage; use base 'DBIO::Test::Storage'; use mro 'c3';
}
T::K268::A::Storage->register_async_mode(  ram => 'T::K268::ModelA' );
T::K268::AD::Storage->register_async_mode( ram => 'T::K268::ModelA::Declaring' );
T::K268::BD::Storage->register_async_mode( ram => 'T::K268::ModelB::Declaring' );

# ===========================================================================
# The case of the card: Model A declaring the core-read name, and a layer
# requiring it.
# ===========================================================================
{
  my ($storage, $schema) = build_storage('T::K268::AD::Storage', 'T::K268::Asking');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !$async && $err, 'the layer is refused over a transport with no query seam'
    or diag "composed instead";
  like $err, qr/\QT::K268::Asking::Async\E/, '... naming the async layer';
  like $err, qr/\QT::K268::ModelA::Declaring\E/, '... and the transport';
  like $err, qr/read by core, not by layers/,
    '... saying the name is core-read and does not count as a layer capability';
}

# ===========================================================================
# Around it, what the gate does today and k268 does not ask to change.
# ===========================================================================

# The same transport refuses a layer that declares nothing: it has no seam.
{
  my ($storage, $schema) = build_storage('T::K268::AD::Storage', 'T::K268::Silent');
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !defined($async) && $err,
    'a layer declaring nothing is refused over the same transport: it has no query seam';
  like $err, qr/\Q_query_async\E/, '... the refusal naming the seam';
  like $err, qr/\QT::K268::ModelA::Declaring\E/, '... and the transport';
}

# Model A not declaring the name refuses the layer for the missing capability.
{
  my ($storage, $schema) = build_storage('T::K268::A::Storage', 'T::K268::Asking');
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !defined($async) && $err,
    'the layer is refused over a Model A transport that does not declare the name';
  like $err, qr/requires transport capability 'broker_connect_options'/,
    '... for the capability it asked for';
}

# What the name is for: core reads it off the transport, layers or none.
ok( T::K268::ModelA::Declaring->_takes_broker_connect_options,
  'core reads broker_connect_options off the declaring transport' );
ok( !T::K268::ModelA->_takes_broker_connect_options,
  '... and not off the one that does not declare it' );

# The name is core-read on every transport, so a layer requiring it is refused
# on a transport that owns the query path too (karr k268, maintainer decision
# 2026-10-09): it is not a layer capability there either.
{
  my ($storage, $schema) = build_storage('T::K268::BD::Storage', 'T::K268::Asking');
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !defined($async) && $err,
    'over a Model B transport declaring the name, the layer is refused as well';
  like $err, qr/\QT::K268::BD\E|\QT::K268::ModelB::Declaring\E/, '... naming the transport';
}

done_testing;
