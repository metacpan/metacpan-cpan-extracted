use strict;
use warnings;
use Test::More;

# OFFLINE guard for the 'ev' async-mode resolution. No EV::Pg, no real DB.
#
# THE GAP THIS CLOSES (karr k33): until now nothing offline asserted that
# { async => 'ev' } actually reaches DBIO::PostgreSQL::EV::Storage. Every
# offline test builds EV::Storage->new(undef) DIRECTLY, so the registry hop --
# the one thing a user's connect() depends on -- was exercised only by the live
# suite (t/21-deploy-async-live.t). A rename or a dropped registration would
# have left the whole offline suite green and failed first against a real
# server, in someone else's dist.
#
# It is a CROSS-DIST contract on purpose: the registration lives in
# dbio-postgresql (DBIO::PostgreSQL::Storage), the class it names lives here.
# That is exactly why it is worth pinning from this side -- neither dist's
# suite covers the join otherwise, and this dist is the one that breaks when
# the name drifts.
#
# ORDER IS LOAD BEARING in this file: the %INC assertions below must run
# BEFORE anything pulls DBIO::PostgreSQL::EV::Storage in.

require DBIO::PostgreSQL::Storage;

my $SYNC = 'DBIO::PostgreSQL::Storage';
my $EV   = 'DBIO::PostgreSQL::EV::Storage';

# --- 1. The registry hop itself ----------------------------------------------

can_ok $SYNC, '_resolve_async_mode_class';
is $SYNC->_resolve_async_mode_class('ev'), $EV,
  "the sync driver resolves the 'ev' mode to $EV";

# --- 2. Resolution NAMES the class, it does not LOAD it ----------------------
# ADR 0030 §3 / DBIO::PostgreSQL::EV DESCRIPTION: "No compile-time dependency on
# EV is added to the sync driver." A registry that loaded its target would make
# every sync dbi:Pg: user pay for EV::Pg. Asserted here because it is invisible
# in normal use -- it only shows up as an install-time dependency surprise.

ok !$INC{'DBIO/PostgreSQL/EV/Storage.pm'},
  'resolving the mode did NOT load the transport class';
ok !$INC{'EV/Pg.pm'},
  'resolving the mode did NOT load EV::Pg';

# --- 3. An unknown mode does not silently fall back --------------------------
# ADR 0030 §3 is "explicit or it croaks": a typo must not degrade to a working
# sync connection that the caller believes is async.

is $SYNC->_resolve_async_mode_class('nonesuch'), undef,
  'an unregistered async mode resolves to undef, not to a fallback';

# --- 4. The registration is on the STORAGE class, not on the component -------
# ADR 0032 §7: an extension never determines the driver. DBIO::PostgreSQL::EV is
# the distribution's overview module, loadable as a component that defines no
# methods; if it ever grew the registry API, loading a component would start
# deciding transports again -- the exact regression that rule exists for.

require DBIO::PostgreSQL::EV;
ok !DBIO::PostgreSQL::EV->can('register_async_mode'),
  'DBIO::PostgreSQL::EV does not carry register_async_mode';
ok !DBIO::PostgreSQL::EV->can('_resolve_async_mode_class'),
  'DBIO::PostgreSQL::EV does not resolve async modes';

# --- 5. The name the registry hands back is usable ---------------------------
# Without this the four assertions above could all pass on a dangling name.

require DBIO::PostgreSQL::EV::Storage;
isa_ok $EV, 'DBIO::Storage::Async',
  'the resolved transport class';

done_testing;
