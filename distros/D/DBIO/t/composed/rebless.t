# ABSTRACT: karr #70 WP1 -- driver rebless keeps a composed storage's layers
use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;

# --- a fake driver storage + two plain layers ----------------------------
{
  package T::RB::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub driver_marker { 'driver' }
}
{ package T::RB::LayerA; sub tag_a { 'a' } }
{ package T::RB::LayerB; sub tag_b { 'b' } }

# Register the fake driver against a fake DBD name so driver determination
# can resolve it from a DSN string -- no real DBD, no connection.
DBIO::Storage::DBI->register_driver('FakeReblessDrv' => 'T::RB::DriverStorage');

my $schema = DBIO::Test->init_schema;

# --- a composed GENERIC storage (base == DBIO::Storage::DBI) -------------
my $composed_class = DBIO::Storage::Composed->compose(
  'DBIO::Storage::DBI', [ 'T::RB::LayerA', 'T::RB::LayerB' ]
);
my $storage = $composed_class->new($schema);
# DSN-only connect info: _extract_driver_from_connect_info reads the driver
# name off the string without ever connecting.
$storage->connect_info([ 'dbi:FakeReblessDrv:', '', '' ]);

# --- the rebless: composed generic -> driver, layers preserved ----------
$storage->_determine_driver;

isa_ok $storage, 'T::RB::DriverStorage', 'reblessed into the driver storage';
isa_ok $storage, 'T::RB::LayerA', 'rebless kept layer A';
isa_ok $storage, 'T::RB::LayerB', 'rebless kept layer B';
can_ok $storage, 'driver_marker';
can_ok $storage, 'tag_a';
can_ok $storage, 'tag_b';

my $entry = DBIO::Storage::Composed->composition_of(ref $storage);
ok $entry, 'reblessed storage is itself a registered composition';
is $entry->{base}, 'T::RB::DriverStorage',
  'the driver class became the composition base';
is_deeply [ DBIO::Storage::Composed->layers_of(ref $storage) ],
  [ 'T::RB::LayerA', 'T::RB::LayerB' ],
  'the same layers, in order, were re-composed over the driver';

# --- a NON-composed generic storage still reblesses exactly as before ----
my $plain = DBIO::Storage::DBI->new($schema);
$plain->connect_info([ 'dbi:FakeReblessDrv:', '', '' ]);
$plain->_determine_driver;

is ref($plain), 'T::RB::DriverStorage',
  'a bare generic storage reblesses straight to the driver class (unchanged behaviour)';
ok !DBIO::Storage::Composed->composition_of(ref $plain),
  'the bare instance stays non-composed';

done_testing;
