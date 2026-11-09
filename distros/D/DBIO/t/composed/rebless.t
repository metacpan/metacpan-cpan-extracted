# ABSTRACT: driver determination of a composed storage -- generic base refused, declared base keeps its layers
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;

# What this file claims (ADR 0067, replacing the generic rebless of ADR 0032
# section 3):
#   1. A storage composed over the generic DBIO::Storage::DBI has no driver,
#      like the bare generic storage: its driver determination is refused,
#      even with a DSN whose DBD a driver is registered for, and the storage
#      stays in the class it had, undetermined -- it is never moved into the
#      registered driver.
#   2. A storage composed over a declared driver class keeps that class and
#      its layers through driver determination.

# --- a fake driver storage + two plain layers ----------------------------
{
  package T::RB::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub driver_marker { 'driver' }
}
{ package T::RB::LayerA; sub tag_a { 'a' } }
{ package T::RB::LayerB; sub tag_b { 'b' } }

# Registered against a fake DBD name: if anything still found a driver from
# the DSN, it would be this one. No real DBD, no connection.
DBIO::Storage::DBI->register_driver('FakeReblessDrv' => 'T::RB::DriverStorage');

my $schema = DBIO::Test->init_schema;

# --- 1. composed over the generic base: refused --------------------------
my $composed_class = DBIO::Storage::Composed->compose(
  'DBIO::Storage::DBI', [ 'T::RB::LayerA', 'T::RB::LayerB' ]
);
my $storage = $composed_class->new($schema);
$storage->connect_info([ 'dbi:FakeReblessDrv:', '', '' ]);

throws_ok { $storage->_determine_driver } qr/DBIO::Storage::DBI has no driver/,
  'a composed generic storage: driver determination is refused';
like "$@", qr/ADR 0067/, '... naming the decision';
is ref($storage), $composed_class, '... the storage stays in the class it had';
ok !$storage->isa('T::RB::DriverStorage'), '... never the driver the DBD is registered for';
ok !$storage->_driver_determined, '... and undetermined';

my $plain = DBIO::Storage::DBI->new($schema);
$plain->connect_info([ 'dbi:FakeReblessDrv:', '', '' ]);
throws_ok { $plain->_determine_driver } qr/DBIO::Storage::DBI has no driver/,
  'a bare generic storage: refused the same way';
is ref($plain), 'DBIO::Storage::DBI', '... and stays the generic class';

# --- 2. composed over a declared driver: class and layers kept -----------
my $declared_class = DBIO::Storage::Composed->compose(
  'T::RB::DriverStorage', [ 'T::RB::LayerA', 'T::RB::LayerB' ]
);
my $declared = $declared_class->new($schema);
$declared->connect_info([ 'dbi:FakeReblessDrv:', '', '' ]);
lives_ok { $declared->_determine_driver } 'a composed declared storage: determined';

is ref($declared), $declared_class, '... the class it had';
isa_ok $declared, 'T::RB::DriverStorage', '... the declared driver';
can_ok $declared, qw( driver_marker tag_a tag_b );
is_deeply [ DBIO::Storage::Composed->layers_of(ref $declared) ],
  [ 'T::RB::LayerA', 'T::RB::LayerB' ],
  '... with the same layers, in order';

done_testing;
