# ABSTRACT: an async layer that declares NO required_transport_capabilities
# is treated as requiring the default query seam (_query_async), so a transport that
# does not own the query path (Model A / forked shape) refuses the composition.
#
# The capability gate used to protect by DECLARATION, not by SEAM: a layer that
# declared a requirement and did not find it was stopped, but a layer that simply said
# nothing composed onto ANY transport without a word -- including one with no
# _query_async for it to wrap, which is exactly the silent feature loss ADR 0032 §5
# exists to prevent. "Says nothing" is now the safe case, not the unchecked one.
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
# Two transports of the two shapes the seam question distinguishes.
# ---------------------------------------------------------------------------

# Model B: owns the query path -- it overrides the _query_async seam, so a layer
# can wrap it. Every real pooled transport (DBIO::Async::Storage, the EV
# transports and everything derived from them) has this shape.
{
  package T::LDS::SeamTransport;
  use base 'DBIO::Storage::Async';
  use mro 'c3';
  sub future_class { 'DBIO::Future::Immediate' }
  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{recorded} ||= [] }, $sql;
    return DBIO::Future::Immediate->done([]);
  }
}

# Model A: the DBIO::Forked shape -- it overrides the six *_async entry points
# directly and runs the driver's ordinary sync CRUD elsewhere, so it inherits the
# abstract _query_async stub and there is NO seam for a layer to wrap.
{
  package T::LDS::ModelATransport;
  use base 'DBIO::Storage::Async';
  use mro 'c3';
  sub future_class        { 'DBIO::Future::Immediate' }
  sub select_async        { DBIO::Future::Immediate->done([]) }
  sub select_single_async { DBIO::Future::Immediate->done([]) }
  sub insert_async        { DBIO::Future::Immediate->done([]) }
  sub update_async        { DBIO::Future::Immediate->done(0)  }
  sub delete_async        { DBIO::Future::Immediate->done(0)  }
  sub txn_do_async        { DBIO::Future::Immediate->done(1)  }
}

# Sanity: the two transports really do differ in the one property under test.
my $abstract_seam = DBIO::Storage::Async->can('_query_async');
isnt( T::LDS::SeamTransport->can('_query_async'), $abstract_seam,
  'sanity: the Model B transport overrides the _query_async seam' );
is( T::LDS::ModelATransport->can('_query_async'), $abstract_seam,
  'sanity: the Model A transport inherits the abstract stub -- no seam' );

# ---------------------------------------------------------------------------
# Layers. "Silent" declares nothing at all; "Explicit" declares a real
# capability; "Nothing" declares an EXPLICIT empty list (the documented opt-out
# for a layer that genuinely needs nothing from the transport).
# ---------------------------------------------------------------------------
{ package T::LDS::Silent;          sub silent_sync { 1 } }
{ package T::LDS::Silent::Async;   sub silent_async { 1 } }

{ package T::LDS::Explicit;        sub explicit_sync { 1 } }
{
  package T::LDS::Explicit::Async;
  sub required_transport_capabilities { ('x') }
  sub explicit_async { 1 }
}

{ package T::LDS::Nothing;         sub nothing_sync { 1 } }
{
  package T::LDS::Nothing::Async;
  sub required_transport_capabilities { () }
  sub nothing_async { 1 }
}

# Build a fresh sync storage bound to a live schema carrying @layers, in the
# 'ram' mode the caller's storage class registered. Returns ($storage, $schema);
# the caller MUST hold $schema in scope (storage weakens its schema ref).
sub build_storage {
  my ($storage_class, @layers) = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->register_storage_layer($_) for @layers;
  my $storage = $storage_class->new($schema);
  $storage->connect_info([ 'dbi:LDSMock:', '', '', { async => 'ram' } ]);
  return ($storage, $schema);
}

# ===========================================================================
# (a) A layer that declares NOTHING composes over a transport that DOES provide
#     the default seam -- the overwhelmingly common case must stay silent.
# ===========================================================================
{
  package T::LDS::A::Storage; use base 'DBIO::Test::Storage'; use mro 'c3';
}
T::LDS::A::Storage->register_async_mode( ram => 'T::LDS::SeamTransport' );

{
  my ($storage, $schema) = build_storage('T::LDS::A::Storage', 'T::LDS::Silent');
  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'an undeclared layer composes over a transport that owns the query path'
    or diag "died with: $err";
  isa_ok $async, 'T::LDS::Silent::Async', 'the undeclared layer was composed in';
  isa_ok $async, 'T::LDS::SeamTransport', 'over the seam-providing transport';
  can_ok $async, 'silent_async';
}

# ===========================================================================
# (b) The SAME layer over a Model A transport -- no _query_async to wrap -- is
#     refused, and the message has to be self-explaining: it must say the layer
#     declared nothing, name the seam it is therefore taken to require, name the
#     transport, and tell the author what to do instead.
# ===========================================================================
{
  package T::LDS::B::Storage; use base 'DBIO::Test::Storage'; use mro 'c3';
}
T::LDS::B::Storage->register_async_mode( ram => 'T::LDS::ModelATransport' );

{
  my ($storage, $schema) = build_storage('T::LDS::B::Storage', 'T::LDS::Silent');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err,
    'the same undeclared layer is REFUSED over a transport with no query seam';
  like $err, qr/\QT::LDS::Silent::Async\E/,     '... naming the async layer';
  like $err, qr/\Qrequired_transport_capabilities\E/,
    '... saying the layer declared no required_transport_capabilities';
  like $err, qr/\Q_query_async\E/,              '... naming the missing seam';
  like $err, qr/\QT::LDS::ModelATransport\E/,   '... naming the transport';
  like $err, qr/declare/,
    '... telling the layer author to declare what it actually needs';
  like $err, qr/choose another async mode/,     '... with the choose-a-mode hint';
}

# ===========================================================================
# (c) A layer that DOES declare keeps the older behaviour exactly: the
#     declaration is the whole question, and the implicit seam rule does not
#     apply on top of it.
# ===========================================================================

# (c1) declares 'x', transport lacks it -> the unchanged capability croak.
{
  package T::LDS::C1::Storage;   use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::LDS::C1::Transport; use base 'T::LDS::SeamTransport'; use mro 'c3';
}
T::LDS::C1::Storage->register_async_mode( ram => 'T::LDS::C1::Transport' );

{
  my ($storage, $schema) = build_storage('T::LDS::C1::Storage', 'T::LDS::Explicit');
  eval { $storage->async };
  my $err = $@;
  ok $err, 'a declared capability the transport lacks still croaks';
  like $err, qr/\QT::LDS::Explicit::Async\E/, '... naming the async layer';
  like $err, qr/requires transport capability/,
    '... with the capability wording, not the seam wording';
  unlike $err, qr/\Q_query_async\E/,
    '... the implicit seam rule does not apply to a layer that declared';
}

# (c2) declares 'x', transport provides it -> composes, unchanged.
{
  package T::LDS::C2::Storage;   use base 'DBIO::Test::Storage'; use mro 'c3';
  package T::LDS::C2::Transport; use base 'T::LDS::SeamTransport'; use mro 'c3';
  sub transport_capabilities { ('x') }
}
T::LDS::C2::Storage->register_async_mode( ram => 'T::LDS::C2::Transport' );

{
  my ($storage, $schema) = build_storage('T::LDS::C2::Storage', 'T::LDS::Explicit');
  my $async = eval { $storage->async };
  ok $async, 'a declared capability the transport provides still composes'
    or diag "died with: $@";
  isa_ok $async, 'T::LDS::Explicit::Async', 'the declaring layer was composed in';
}

# (c3) declares an EXPLICIT empty list over a seam-less Model A transport ->
#      composes. Stating "I need nothing" is a declaration, and the author owns
#      it; only saying nothing at all is now treated as needing the seam.
{
  package T::LDS::C3::Storage; use base 'DBIO::Test::Storage'; use mro 'c3';
}
T::LDS::C3::Storage->register_async_mode( ram => 'T::LDS::ModelATransport' );

{
  my ($storage, $schema) = build_storage('T::LDS::C3::Storage', 'T::LDS::Nothing');
  my $async = eval { $storage->async };
  ok $async, 'an explicitly empty declaration composes even without the seam'
    or diag "died with: $@";
  isa_ok $async, 'T::LDS::Nothing::Async', 'the opt-out layer was composed in';
  isa_ok $async, 'T::LDS::ModelATransport', 'over the seam-less transport';
}

done_testing;
