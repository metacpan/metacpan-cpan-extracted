##############################
#
# PositionDelta.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PositionDelta.t`

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
use Test::More tests => 50;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::PositionDelta') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::NameValueType;


# we test the new() method
my $positiondelta;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $positiondelta = Bio::MAGE::Array::PositionDelta->new();
}
isa_ok($positiondelta, 'Bio::MAGE::Array::PositionDelta');

# test the package_name class method
is($positiondelta->package_name(), q[Array],
  'package');

# test the class_name class method
is($positiondelta->class_name(), q[Bio::MAGE::Array::PositionDelta],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $positiondelta = Bio::MAGE::Array::PositionDelta->new(deltaX => '1',
deltaY => '2');
}


#
# testing attribute deltaX
#

# test attribute values can be set in new()
is($positiondelta->getDeltaX(), '1',
  'deltaX new');

# test getter/setter
$positiondelta->setDeltaX('1');
is($positiondelta->getDeltaX(), '1',
  'deltaX getter/setter');

# test getter throws exception with argument
eval {$positiondelta->getDeltaX(1)};
ok($@, 'deltaX getter throws exception with argument');

# test setter throws exception with no argument
eval {$positiondelta->setDeltaX()};
ok($@, 'deltaX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$positiondelta->setDeltaX('1', '1')};
ok($@, 'deltaX setter throws exception with too many argument');

# test setter accepts undef
eval {$positiondelta->setDeltaX(undef)};
ok((!$@ and not defined $positiondelta->getDeltaX()),
   'deltaX setter accepts undef');



#
# testing attribute deltaY
#

# test attribute values can be set in new()
is($positiondelta->getDeltaY(), '2',
  'deltaY new');

# test getter/setter
$positiondelta->setDeltaY('2');
is($positiondelta->getDeltaY(), '2',
  'deltaY getter/setter');

# test getter throws exception with argument
eval {$positiondelta->getDeltaY(1)};
ok($@, 'deltaY getter throws exception with argument');

# test setter throws exception with no argument
eval {$positiondelta->setDeltaY()};
ok($@, 'deltaY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$positiondelta->setDeltaY('2', '2')};
ok($@, 'deltaY setter throws exception with too many argument');

# test setter accepts undef
eval {$positiondelta->setDeltaY(undef)};
ok((!$@ and not defined $positiondelta->getDeltaY()),
   'deltaY setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::PositionDelta->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $positiondelta = Bio::MAGE::Array::PositionDelta->new(distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($positiondelta->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($positiondelta->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($positiondelta->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$positiondelta->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$positiondelta->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$positiondelta->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$positiondelta->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$positiondelta->setDistanceUnit(undef)};
ok((!$@ and not defined $positiondelta->getDistanceUnit()),
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


ok((UNIVERSAL::isa($positiondelta->getPropertySets,'ARRAY')
 and scalar @{$positiondelta->getPropertySets} == 1
 and UNIVERSAL::isa($positiondelta->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($positiondelta->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($positiondelta->getPropertySets,'ARRAY')
 and scalar @{$positiondelta->getPropertySets} == 1
 and $positiondelta->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($positiondelta->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($positiondelta->getPropertySets,'ARRAY')
 and scalar @{$positiondelta->getPropertySets} == 2
 and $positiondelta->getPropertySets->[0] == $propertysets_assn
 and $positiondelta->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$positiondelta->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$positiondelta->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$positiondelta->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$positiondelta->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$positiondelta->setPropertySets([])};
ok((!$@ and defined $positiondelta->getPropertySets()
    and UNIVERSAL::isa($positiondelta->getPropertySets, 'ARRAY')
    and scalar @{$positiondelta->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$positiondelta->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$positiondelta->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$positiondelta->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$positiondelta->setPropertySets(undef)};
ok((!$@ and not defined $positiondelta->getPropertySets()),
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
isa_ok($positiondelta, q[Bio::MAGE::Extendable]);

