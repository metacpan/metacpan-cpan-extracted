use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib qw(t/lib);   # DBIO::Shortcut::tsc + DBIO::TSC::Result + DBIO::ZDrv fixtures
use DBIO::ZDrv ();   # a "driver" with NO Shortcut stub, loaded for tier-2 test

# --- Role auto-detection: ::Result:: -> Core ---

{
  package TestPragma::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/id name/);
  __PACKAGE__->set_primary_key('id');
}

ok(TestPragma::Schema::Result::Artist->isa('DBIO::Core'),
  '::Result:: package auto-detects Core role');
is(TestPragma::Schema::Result::Artist->table, 'artist',
  'DBIO::Core methods work on auto-Core class');

# --- Role auto-detection: ::ResultSet:: -> ResultSet ---

{
  package TestPragma::Schema::ResultSet::Artist;
  use DBIO;
}

ok(TestPragma::Schema::ResultSet::Artist->isa('DBIO::ResultSet'),
  '::ResultSet:: package auto-detects ResultSet role');

# --- Explicit role: Schema ---

{
  package TestPragma::Schema;
  use DBIO 'Schema';
}

ok(TestPragma::Schema->isa('DBIO::Schema'),
  "use DBIO 'Schema' installs DBIO::Schema as base");

# --- Explicit override: Core in a ::ResultSet:: package ---

{
  package TestPragma::Schema::ResultSet::Overriden;
  use DBIO 'Core';
}

ok(TestPragma::Schema::ResultSet::Overriden->isa('DBIO::Core'),
  'explicit role overrides package-name heuristic');
ok(!TestPragma::Schema::ResultSet::Overriden->isa('DBIO::ResultSet'),
  'overridden class does not pick up auto-detected role');

# --- Ambivalent namespace defaults to Core ---

{
  package TestPragma::Random::Thing;
  use DBIO;
}

ok(TestPragma::Random::Thing->isa('DBIO::Core'),
  'ambivalent package name defaults to Core role');

# --- Idempotency: use DBIO twice -> no duplicate @ISA entries ---

{
  package TestPragma::Schema::Result::Twice;
  use DBIO;
  use DBIO;
}

my @isa = do { no strict 'refs'; @{'TestPragma::Schema::Result::Twice::ISA'} };
my @core_hits = grep { $_ eq 'DBIO::Core' } @isa;
is(scalar(@core_hits), 1,
  'double use DBIO results in only one DBIO::Core in @ISA');

# --- Coexistence: use base 'DBIO::Core' + use DBIO does not double ---

{
  package TestPragma::Schema::Result::Coexist;
  use base 'DBIO::Core';
  use DBIO;
}

my @isa2 = do { no strict 'refs'; @{'TestPragma::Schema::Result::Coexist::ISA'} };
my @core_hits2 = grep { $_ eq 'DBIO::Core' } @isa2;
is(scalar(@core_hits2), 1,
  'use base + use DBIO coexist without duplicate DBIO::Core in @ISA');

# --- Unknown role dies with helpful message ---

throws_ok {
  eval q{
    package TestPragma::Broken::Role;
    use DBIO 'NonsenseRole';
  };
  die $@ if $@;
} qr/cannot load DBIO::NonsenseRole/i,
  "use DBIO 'NonsenseRole' dies with helpful error";

# --- Unknown shortcut dies with helpful message ---

throws_ok {
  eval q{
    package TestPragma::Broken::Shortcut;
    use DBIO -totally_unknown;
  };
  die $@ if $@;
} qr/unknown shortcut/i,
  'use DBIO -unknown dies with helpful error';

# --- Driver-owned shortcut via DBIO::Shortcut::<key> stub ---
# Core knows no driver names: it lazy-loads DBIO::Shortcut::tsc (t/lib fixture)
# and calls its apply($caller), which load_components('TSC::Result').

{
  package TestPragma::Schema::Result::WithShortcut;
  use DBIO 'Core', -tsc;
  __PACKAGE__->table('ws');
  __PACKAGE__->add_columns(qw/id/);
}

ok(TestPragma::Schema::Result::WithShortcut->can('tsc_marker'),
  '-tsc lazy-loads DBIO::Shortcut::tsc and runs its apply()');
is(TestPragma::Schema::Result::WithShortcut->tsc_marker, 42,
  'component pulled in by the stub apply() is callable');

# Schema context: the SAME stub sets the storage driver instead of a component.
# This is how every driver -- even those without a ::Result component -- gets a
# shortcut: apply() inspects the caller and does driver-level setup on a Schema.

{
  package TestPragma::Schema::WithDriverShortcut;
  use DBIO 'Schema', -tsc;
}

is(TestPragma::Schema::WithDriverShortcut->storage_type, '+DBIO::TSC::Storage',
  '-tsc on a Schema sets storage_type via apply() (driver-level, any driver)');

# --- Tier 2: canonical name resolves to an already-loaded driver, no stub ---
# DBIO::ZDrv is loaded (above) and has DBIO::ZDrv::Storage but ships NO
# DBIO::Shortcut::zdrv. -zdrv must still resolve, casing taken from the symbol
# table (zdrv -> ZDrv).

{
  package TestPragma::Schema::ViaLoadedDriver;
  use DBIO 'Schema', -zdrv;
}

is(TestPragma::Schema::ViaLoadedDriver->storage_type, '+DBIO::ZDrv::Storage',
  '-zdrv (no stub) resolves to the loaded DBIO::ZDrv driver via tier-2 fallback');

# --- A canonical name with no stub AND no loaded driver dies ---

throws_ok {
  eval q{
    package TestPragma::Broken::NotLoaded;
    use DBIO -neverloadeddriver;
  };
  die $@ if $@;
} qr/unknown shortcut/i,
  'canonical name with no stub and no loaded driver dies helpfully';

# --- Path-traversal / junk shortcut keys are rejected before any require ---

throws_ok {
  eval q{
    package TestPragma::Broken::Traversal;
    use DBIO '-../evil';
  };
  die $@ if $@;
} qr/invalid shortcut/i,
  'shortcut key with non-word chars is rejected (no arbitrary require)';

# --- DBIO::Base is the meta-infra parent of every internal class ---

ok(DBIO::Core->isa('DBIO::Base'),
  'DBIO::Core inherits from DBIO::Base (meta-infra split)');
ok(DBIO::Schema->isa('DBIO::Base'),
  'DBIO::Schema inherits from DBIO::Base');
ok(DBIO::ResultSet->isa('DBIO::Base'),
  'DBIO::ResultSet inherits from DBIO::Base');

# --- DBIO.pm is NOT in the MRO of anything (no leakage) ---

ok(!TestPragma::Schema::Result::Artist->isa('DBIO'),
  'result class does not inherit from DBIO.pm itself (no MRO leak)');
ok(!DBIO::Core->isa('DBIO'),
  'DBIO::Core does not inherit from DBIO.pm');

done_testing();
