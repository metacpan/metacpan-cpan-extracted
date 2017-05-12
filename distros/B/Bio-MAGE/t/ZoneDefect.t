##############################
#
# ZoneDefect.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ZoneDefect.t`

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
use Test::More tests => 64;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::ZoneDefect') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Array::PositionDelta;
use Bio::MAGE::NameValueType;
use Bio::MAGE::ArrayDesign::Zone;


# we test the new() method
my $zonedefect;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonedefect = Bio::MAGE::Array::ZoneDefect->new();
}
isa_ok($zonedefect, 'Bio::MAGE::Array::ZoneDefect');

# test the package_name class method
is($zonedefect->package_name(), q[Array],
  'package');

# test the class_name class method
is($zonedefect->class_name(), q[Bio::MAGE::Array::ZoneDefect],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonedefect = Bio::MAGE::Array::ZoneDefect->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ZoneDefect->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonedefect = Bio::MAGE::Array::ZoneDefect->new(positionDelta => Bio::MAGE::Array::PositionDelta->new(),
zone => Bio::MAGE::ArrayDesign::Zone->new(),
defectType => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association positionDelta
my $positiondelta_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $positiondelta_assn = Bio::MAGE::Array::PositionDelta->new();
}


isa_ok($zonedefect->getPositionDelta, q[Bio::MAGE::Array::PositionDelta]);

is($zonedefect->setPositionDelta($positiondelta_assn), $positiondelta_assn,
  'setPositionDelta returns value');

ok($zonedefect->getPositionDelta() == $positiondelta_assn,
   'getPositionDelta fetches correct value');

# test setPositionDelta throws exception with bad argument
eval {$zonedefect->setPositionDelta(1)};
ok($@, 'setPositionDelta throws exception with bad argument');


# test getPositionDelta throws exception with argument
eval {$zonedefect->getPositionDelta(1)};
ok($@, 'getPositionDelta throws exception with argument');

# test setPositionDelta throws exception with no argument
eval {$zonedefect->setPositionDelta()};
ok($@, 'setPositionDelta throws exception with no argument');

# test setPositionDelta throws exception with too many argument
eval {$zonedefect->setPositionDelta(1,2)};
ok($@, 'setPositionDelta throws exception with too many argument');

# test setPositionDelta accepts undef
eval {$zonedefect->setPositionDelta(undef)};
ok((!$@ and not defined $zonedefect->getPositionDelta()),
   'setPositionDelta accepts undef');

# test the meta-data for the assoication
$assn = $assns{positionDelta};
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
   'positionDelta->other() is a valid Bio::MAGE::Association::End'
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
   'positionDelta->self() is a valid Bio::MAGE::Association::End'
  );



# testing association zone
my $zone_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zone_assn = Bio::MAGE::ArrayDesign::Zone->new();
}


isa_ok($zonedefect->getZone, q[Bio::MAGE::ArrayDesign::Zone]);

is($zonedefect->setZone($zone_assn), $zone_assn,
  'setZone returns value');

ok($zonedefect->getZone() == $zone_assn,
   'getZone fetches correct value');

# test setZone throws exception with bad argument
eval {$zonedefect->setZone(1)};
ok($@, 'setZone throws exception with bad argument');


# test getZone throws exception with argument
eval {$zonedefect->getZone(1)};
ok($@, 'getZone throws exception with argument');

# test setZone throws exception with no argument
eval {$zonedefect->setZone()};
ok($@, 'setZone throws exception with no argument');

# test setZone throws exception with too many argument
eval {$zonedefect->setZone(1,2)};
ok($@, 'setZone throws exception with too many argument');

# test setZone accepts undef
eval {$zonedefect->setZone(undef)};
ok((!$@ and not defined $zonedefect->getZone()),
   'setZone accepts undef');

# test the meta-data for the assoication
$assn = $assns{zone};
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
   'zone->other() is a valid Bio::MAGE::Association::End'
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
   'zone->self() is a valid Bio::MAGE::Association::End'
  );



# testing association defectType
my $defecttype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $defecttype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($zonedefect->getDefectType, q[Bio::MAGE::Description::OntologyEntry]);

is($zonedefect->setDefectType($defecttype_assn), $defecttype_assn,
  'setDefectType returns value');

ok($zonedefect->getDefectType() == $defecttype_assn,
   'getDefectType fetches correct value');

# test setDefectType throws exception with bad argument
eval {$zonedefect->setDefectType(1)};
ok($@, 'setDefectType throws exception with bad argument');


# test getDefectType throws exception with argument
eval {$zonedefect->getDefectType(1)};
ok($@, 'getDefectType throws exception with argument');

# test setDefectType throws exception with no argument
eval {$zonedefect->setDefectType()};
ok($@, 'setDefectType throws exception with no argument');

# test setDefectType throws exception with too many argument
eval {$zonedefect->setDefectType(1,2)};
ok($@, 'setDefectType throws exception with too many argument');

# test setDefectType accepts undef
eval {$zonedefect->setDefectType(undef)};
ok((!$@ and not defined $zonedefect->getDefectType()),
   'setDefectType accepts undef');

# test the meta-data for the assoication
$assn = $assns{defectType};
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
   'defectType->other() is a valid Bio::MAGE::Association::End'
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
   'defectType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($zonedefect->getPropertySets,'ARRAY')
 and scalar @{$zonedefect->getPropertySets} == 1
 and UNIVERSAL::isa($zonedefect->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($zonedefect->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($zonedefect->getPropertySets,'ARRAY')
 and scalar @{$zonedefect->getPropertySets} == 1
 and $zonedefect->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($zonedefect->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($zonedefect->getPropertySets,'ARRAY')
 and scalar @{$zonedefect->getPropertySets} == 2
 and $zonedefect->getPropertySets->[0] == $propertysets_assn
 and $zonedefect->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$zonedefect->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$zonedefect->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$zonedefect->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$zonedefect->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$zonedefect->setPropertySets([])};
ok((!$@ and defined $zonedefect->getPropertySets()
    and UNIVERSAL::isa($zonedefect->getPropertySets, 'ARRAY')
    and scalar @{$zonedefect->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$zonedefect->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$zonedefect->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$zonedefect->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$zonedefect->setPropertySets(undef)};
ok((!$@ and not defined $zonedefect->getPropertySets()),
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





my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($zonedefect, q[Bio::MAGE::Extendable]);

