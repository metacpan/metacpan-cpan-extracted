##############################
#
# ZoneGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ZoneGroup.t`

##############################
# C O P Y R I G H T   N O T I C E
#  Copyright (c) 2001-2006 by:
#    * The MicroArray Gene Expression Database Society (MGED)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.



use Carp;
# use blib;
use Test::More tests => 94;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::ZoneGroup') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::NameValueType;
use Bio::MAGE::ArrayDesign::ZoneLayout;
use Bio::MAGE::ArrayDesign::Zone;


# we test the new() method
my $zonegroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonegroup = Bio::MAGE::ArrayDesign::ZoneGroup->new();
}
isa_ok($zonegroup, 'Bio::MAGE::ArrayDesign::ZoneGroup');

# test the package_name class method
is($zonegroup->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($zonegroup->class_name(), q[Bio::MAGE::ArrayDesign::ZoneGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonegroup = Bio::MAGE::ArrayDesign::ZoneGroup->new(zonesPerY => '1',
zonesPerX => '2',
spacingsBetweenZonesX => '3',
spacingsBetweenZonesY => '4');
}


#
# testing attribute zonesPerY
#

# test attribute values can be set in new()
is($zonegroup->getZonesPerY(), '1',
  'zonesPerY new');

# test getter/setter
$zonegroup->setZonesPerY('1');
is($zonegroup->getZonesPerY(), '1',
  'zonesPerY getter/setter');

# test getter throws exception with argument
eval {$zonegroup->getZonesPerY(1)};
ok($@, 'zonesPerY getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonegroup->setZonesPerY()};
ok($@, 'zonesPerY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonegroup->setZonesPerY('1', '1')};
ok($@, 'zonesPerY setter throws exception with too many argument');

# test setter accepts undef
eval {$zonegroup->setZonesPerY(undef)};
ok((!$@ and not defined $zonegroup->getZonesPerY()),
   'zonesPerY setter accepts undef');



#
# testing attribute zonesPerX
#

# test attribute values can be set in new()
is($zonegroup->getZonesPerX(), '2',
  'zonesPerX new');

# test getter/setter
$zonegroup->setZonesPerX('2');
is($zonegroup->getZonesPerX(), '2',
  'zonesPerX getter/setter');

# test getter throws exception with argument
eval {$zonegroup->getZonesPerX(1)};
ok($@, 'zonesPerX getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonegroup->setZonesPerX()};
ok($@, 'zonesPerX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonegroup->setZonesPerX('2', '2')};
ok($@, 'zonesPerX setter throws exception with too many argument');

# test setter accepts undef
eval {$zonegroup->setZonesPerX(undef)};
ok((!$@ and not defined $zonegroup->getZonesPerX()),
   'zonesPerX setter accepts undef');



#
# testing attribute spacingsBetweenZonesX
#

# test attribute values can be set in new()
is($zonegroup->getSpacingsBetweenZonesX(), '3',
  'spacingsBetweenZonesX new');

# test getter/setter
$zonegroup->setSpacingsBetweenZonesX('3');
is($zonegroup->getSpacingsBetweenZonesX(), '3',
  'spacingsBetweenZonesX getter/setter');

# test getter throws exception with argument
eval {$zonegroup->getSpacingsBetweenZonesX(1)};
ok($@, 'spacingsBetweenZonesX getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonegroup->setSpacingsBetweenZonesX()};
ok($@, 'spacingsBetweenZonesX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonegroup->setSpacingsBetweenZonesX('3', '3')};
ok($@, 'spacingsBetweenZonesX setter throws exception with too many argument');

# test setter accepts undef
eval {$zonegroup->setSpacingsBetweenZonesX(undef)};
ok((!$@ and not defined $zonegroup->getSpacingsBetweenZonesX()),
   'spacingsBetweenZonesX setter accepts undef');



#
# testing attribute spacingsBetweenZonesY
#

# test attribute values can be set in new()
is($zonegroup->getSpacingsBetweenZonesY(), '4',
  'spacingsBetweenZonesY new');

# test getter/setter
$zonegroup->setSpacingsBetweenZonesY('4');
is($zonegroup->getSpacingsBetweenZonesY(), '4',
  'spacingsBetweenZonesY getter/setter');

# test getter throws exception with argument
eval {$zonegroup->getSpacingsBetweenZonesY(1)};
ok($@, 'spacingsBetweenZonesY getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonegroup->setSpacingsBetweenZonesY()};
ok($@, 'spacingsBetweenZonesY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonegroup->setSpacingsBetweenZonesY('4', '4')};
ok($@, 'spacingsBetweenZonesY setter throws exception with too many argument');

# test setter accepts undef
eval {$zonegroup->setSpacingsBetweenZonesY(undef)};
ok((!$@ and not defined $zonegroup->getSpacingsBetweenZonesY()),
   'spacingsBetweenZonesY setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::ZoneGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonegroup = Bio::MAGE::ArrayDesign::ZoneGroup->new(zoneLayout => Bio::MAGE::ArrayDesign::ZoneLayout->new(),
distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
zoneLocations => [Bio::MAGE::ArrayDesign::Zone->new()]);
}

my ($end, $assn);


# testing association zoneLayout
my $zonelayout_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonelayout_assn = Bio::MAGE::ArrayDesign::ZoneLayout->new();
}


isa_ok($zonegroup->getZoneLayout, q[Bio::MAGE::ArrayDesign::ZoneLayout]);

is($zonegroup->setZoneLayout($zonelayout_assn), $zonelayout_assn,
  'setZoneLayout returns value');

ok($zonegroup->getZoneLayout() == $zonelayout_assn,
   'getZoneLayout fetches correct value');

# test setZoneLayout throws exception with bad argument
eval {$zonegroup->setZoneLayout(1)};
ok($@, 'setZoneLayout throws exception with bad argument');


# test getZoneLayout throws exception with argument
eval {$zonegroup->getZoneLayout(1)};
ok($@, 'getZoneLayout throws exception with argument');

# test setZoneLayout throws exception with no argument
eval {$zonegroup->setZoneLayout()};
ok($@, 'setZoneLayout throws exception with no argument');

# test setZoneLayout throws exception with too many argument
eval {$zonegroup->setZoneLayout(1,2)};
ok($@, 'setZoneLayout throws exception with too many argument');

# test setZoneLayout accepts undef
eval {$zonegroup->setZoneLayout(undef)};
ok((!$@ and not defined $zonegroup->getZoneLayout()),
   'setZoneLayout accepts undef');

# test the meta-data for the assoication
$assn = $assns{zoneLayout};
isa_ok($assn, 'Bio::MAGE::Association');
$end = $assn->other();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->rank(),
   and $end->rank(),
   and defined $end->ordered(),
   and ($end->ordered() == 0 or $end->ordered() == 1),
   and defined $end->class_name(),
   and $end->class_name(),
   and defined $end->name(),
   and $end->name()),
   'zoneLayout->other() is a valid Bio::MAGE::Association::End'
  );

$end = $assn->self();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->class_name(),
   and $end->class_name()),
   'zoneLayout->self() is a valid Bio::MAGE::Association::End'
  );



# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($zonegroup->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($zonegroup->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($zonegroup->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$zonegroup->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$zonegroup->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$zonegroup->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$zonegroup->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$zonegroup->setDistanceUnit(undef)};
ok((!$@ and not defined $zonegroup->getDistanceUnit()),
   'setDistanceUnit accepts undef');

# test the meta-data for the assoication
$assn = $assns{distanceUnit};
isa_ok($assn, 'Bio::MAGE::Association');
$end = $assn->other();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->rank(),
   and $end->rank(),
   and defined $end->ordered(),
   and ($end->ordered() == 0 or $end->ordered() == 1),
   and defined $end->class_name(),
   and $end->class_name(),
   and defined $end->name(),
   and $end->name()),
   'distanceUnit->other() is a valid Bio::MAGE::Association::End'
  );

$end = $assn->self();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->class_name(),
   and $end->class_name()),
   'distanceUnit->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($zonegroup->getPropertySets,'ARRAY')
 and scalar @{$zonegroup->getPropertySets} == 1
 and UNIVERSAL::isa($zonegroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($zonegroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($zonegroup->getPropertySets,'ARRAY')
 and scalar @{$zonegroup->getPropertySets} == 1
 and $zonegroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($zonegroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($zonegroup->getPropertySets,'ARRAY')
 and scalar @{$zonegroup->getPropertySets} == 2
 and $zonegroup->getPropertySets->[0] == $propertysets_assn
 and $zonegroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$zonegroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$zonegroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$zonegroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$zonegroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$zonegroup->setPropertySets([])};
ok((!$@ and defined $zonegroup->getPropertySets()
    and UNIVERSAL::isa($zonegroup->getPropertySets, 'ARRAY')
    and scalar @{$zonegroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$zonegroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$zonegroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$zonegroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$zonegroup->setPropertySets(undef)};
ok((!$@ and not defined $zonegroup->getPropertySets()),
   'setPropertySets accepts undef');

# test the meta-data for the assoication
$assn = $assns{propertySets};
isa_ok($assn, 'Bio::MAGE::Association');
$end = $assn->other();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->rank(),
   and $end->rank(),
   and defined $end->ordered(),
   and ($end->ordered() == 0 or $end->ordered() == 1),
   and defined $end->class_name(),
   and $end->class_name(),
   and defined $end->name(),
   and $end->name()),
   'propertySets->other() is a valid Bio::MAGE::Association::End'
  );

$end = $assn->self();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->class_name(),
   and $end->class_name()),
   'propertySets->self() is a valid Bio::MAGE::Association::End'
  );



# testing association zoneLocations
my $zonelocations_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonelocations_assn = Bio::MAGE::ArrayDesign::Zone->new();
}


ok((UNIVERSAL::isa($zonegroup->getZoneLocations,'ARRAY')
 and scalar @{$zonegroup->getZoneLocations} == 1
 and UNIVERSAL::isa($zonegroup->getZoneLocations->[0], q[Bio::MAGE::ArrayDesign::Zone])),
  'zoneLocations set in new()');

ok(eq_array($zonegroup->setZoneLocations([$zonelocations_assn]), [$zonelocations_assn]),
   'setZoneLocations returns correct value');

ok((UNIVERSAL::isa($zonegroup->getZoneLocations,'ARRAY')
 and scalar @{$zonegroup->getZoneLocations} == 1
 and $zonegroup->getZoneLocations->[0] == $zonelocations_assn),
   'getZoneLocations fetches correct value');

is($zonegroup->addZoneLocations($zonelocations_assn), 2,
  'addZoneLocations returns number of items in list');

ok((UNIVERSAL::isa($zonegroup->getZoneLocations,'ARRAY')
 and scalar @{$zonegroup->getZoneLocations} == 2
 and $zonegroup->getZoneLocations->[0] == $zonelocations_assn
 and $zonegroup->getZoneLocations->[1] == $zonelocations_assn),
  'addZoneLocations adds correct value');

# test setZoneLocations throws exception with non-array argument
eval {$zonegroup->setZoneLocations(1)};
ok($@, 'setZoneLocations throws exception with non-array argument');

# test setZoneLocations throws exception with bad argument array
eval {$zonegroup->setZoneLocations([1])};
ok($@, 'setZoneLocations throws exception with bad argument array');

# test addZoneLocations throws exception with no arguments
eval {$zonegroup->addZoneLocations()};
ok($@, 'addZoneLocations throws exception with no arguments');

# test addZoneLocations throws exception with bad argument
eval {$zonegroup->addZoneLocations(1)};
ok($@, 'addZoneLocations throws exception with bad array');

# test setZoneLocations accepts empty array ref
eval {$zonegroup->setZoneLocations([])};
ok((!$@ and defined $zonegroup->getZoneLocations()
    and UNIVERSAL::isa($zonegroup->getZoneLocations, 'ARRAY')
    and scalar @{$zonegroup->getZoneLocations} == 0),
   'setZoneLocations accepts empty array ref');


# test getZoneLocations throws exception with argument
eval {$zonegroup->getZoneLocations(1)};
ok($@, 'getZoneLocations throws exception with argument');

# test setZoneLocations throws exception with no argument
eval {$zonegroup->setZoneLocations()};
ok($@, 'setZoneLocations throws exception with no argument');

# test setZoneLocations throws exception with too many argument
eval {$zonegroup->setZoneLocations(1,2)};
ok($@, 'setZoneLocations throws exception with too many argument');

# test setZoneLocations accepts undef
eval {$zonegroup->setZoneLocations(undef)};
ok((!$@ and not defined $zonegroup->getZoneLocations()),
   'setZoneLocations accepts undef');

# test the meta-data for the assoication
$assn = $assns{zoneLocations};
isa_ok($assn, 'Bio::MAGE::Association');
$end = $assn->other();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->rank(),
   and $end->rank(),
   and defined $end->ordered(),
   and ($end->ordered() == 0 or $end->ordered() == 1),
   and defined $end->class_name(),
   and $end->class_name(),
   and defined $end->name(),
   and $end->name()),
   'zoneLocations->other() is a valid Bio::MAGE::Association::End'
  );

$end = $assn->self();
isa_ok($end, 'Bio::MAGE::Association::End');
ok((defined $end
   and defined $end->documentation(),
   and defined $end->cardinality(),
   and grep {$_ eq $end->cardinality} ('0..1','1','1..N','0..N'),
   and defined $end->is_ref(),
   and ($end->is_ref() == 0 or $end->is_ref() == 1),
   and defined $end->class_name(),
   and $end->class_name()),
   'zoneLocations->self() is a valid Bio::MAGE::Association::End'
  );





my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($zonegroup, q[Bio::MAGE::Extendable]);

