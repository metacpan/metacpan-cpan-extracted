##############################
#
# ArrayGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayGroup.t`

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
use Test::More tests => 205;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::ArrayGroup') };

use Bio::MAGE::Array::Array;
use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Array::Fiducial;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $arraygroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraygroup = Bio::MAGE::Array::ArrayGroup->new();
}
isa_ok($arraygroup, 'Bio::MAGE::Array::ArrayGroup');

# test the package_name class method
is($arraygroup->package_name(), q[Array],
  'package');

# test the class_name class method
is($arraygroup->class_name(), q[Bio::MAGE::Array::ArrayGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraygroup = Bio::MAGE::Array::ArrayGroup->new(arraySpacingY => '1',
numArrays => '2',
width => '3',
orientationMarkPosition => 'top',
arraySpacingX => '5',
name => '6',
barcode => '7',
orientationMark => '8',
identifier => '9',
length => '10');
}


#
# testing attribute arraySpacingY
#

# test attribute values can be set in new()
is($arraygroup->getArraySpacingY(), '1',
  'arraySpacingY new');

# test getter/setter
$arraygroup->setArraySpacingY('1');
is($arraygroup->getArraySpacingY(), '1',
  'arraySpacingY getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getArraySpacingY(1)};
ok($@, 'arraySpacingY getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setArraySpacingY()};
ok($@, 'arraySpacingY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setArraySpacingY('1', '1')};
ok($@, 'arraySpacingY setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setArraySpacingY(undef)};
ok((!$@ and not defined $arraygroup->getArraySpacingY()),
   'arraySpacingY setter accepts undef');



#
# testing attribute numArrays
#

# test attribute values can be set in new()
is($arraygroup->getNumArrays(), '2',
  'numArrays new');

# test getter/setter
$arraygroup->setNumArrays('2');
is($arraygroup->getNumArrays(), '2',
  'numArrays getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getNumArrays(1)};
ok($@, 'numArrays getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setNumArrays()};
ok($@, 'numArrays setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setNumArrays('2', '2')};
ok($@, 'numArrays setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setNumArrays(undef)};
ok((!$@ and not defined $arraygroup->getNumArrays()),
   'numArrays setter accepts undef');



#
# testing attribute width
#

# test attribute values can be set in new()
is($arraygroup->getWidth(), '3',
  'width new');

# test getter/setter
$arraygroup->setWidth('3');
is($arraygroup->getWidth(), '3',
  'width getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getWidth(1)};
ok($@, 'width getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setWidth()};
ok($@, 'width setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setWidth('3', '3')};
ok($@, 'width setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setWidth(undef)};
ok((!$@ and not defined $arraygroup->getWidth()),
   'width setter accepts undef');



#
# testing attribute orientationMarkPosition
#

# test attribute values can be set in new()
is($arraygroup->getOrientationMarkPosition(), 'top',
  'orientationMarkPosition new');

# test getter/setter
$arraygroup->setOrientationMarkPosition('top');
is($arraygroup->getOrientationMarkPosition(), 'top',
  'orientationMarkPosition getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getOrientationMarkPosition(1)};
ok($@, 'orientationMarkPosition getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setOrientationMarkPosition()};
ok($@, 'orientationMarkPosition setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setOrientationMarkPosition('top', 'top')};
ok($@, 'orientationMarkPosition setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setOrientationMarkPosition(undef)};
ok((!$@ and not defined $arraygroup->getOrientationMarkPosition()),
   'orientationMarkPosition setter accepts undef');


# test setter throws exception with bad argument
eval {$arraygroup->setOrientationMarkPosition(1)};
ok($@, 'orientationMarkPosition setter throws exception with bad argument');


# test setter accepts enumerated value: top

eval {$arraygroup->setOrientationMarkPosition('top')};
ok((not $@ and $arraygroup->getOrientationMarkPosition() eq 'top'),
   'orientationMarkPosition accepts top');


# test setter accepts enumerated value: bottom

eval {$arraygroup->setOrientationMarkPosition('bottom')};
ok((not $@ and $arraygroup->getOrientationMarkPosition() eq 'bottom'),
   'orientationMarkPosition accepts bottom');


# test setter accepts enumerated value: left

eval {$arraygroup->setOrientationMarkPosition('left')};
ok((not $@ and $arraygroup->getOrientationMarkPosition() eq 'left'),
   'orientationMarkPosition accepts left');


# test setter accepts enumerated value: right

eval {$arraygroup->setOrientationMarkPosition('right')};
ok((not $@ and $arraygroup->getOrientationMarkPosition() eq 'right'),
   'orientationMarkPosition accepts right');



#
# testing attribute arraySpacingX
#

# test attribute values can be set in new()
is($arraygroup->getArraySpacingX(), '5',
  'arraySpacingX new');

# test getter/setter
$arraygroup->setArraySpacingX('5');
is($arraygroup->getArraySpacingX(), '5',
  'arraySpacingX getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getArraySpacingX(1)};
ok($@, 'arraySpacingX getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setArraySpacingX()};
ok($@, 'arraySpacingX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setArraySpacingX('5', '5')};
ok($@, 'arraySpacingX setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setArraySpacingX(undef)};
ok((!$@ and not defined $arraygroup->getArraySpacingX()),
   'arraySpacingX setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($arraygroup->getName(), '6',
  'name new');

# test getter/setter
$arraygroup->setName('6');
is($arraygroup->getName(), '6',
  'name getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setName('6', '6')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setName(undef)};
ok((!$@ and not defined $arraygroup->getName()),
   'name setter accepts undef');



#
# testing attribute barcode
#

# test attribute values can be set in new()
is($arraygroup->getBarcode(), '7',
  'barcode new');

# test getter/setter
$arraygroup->setBarcode('7');
is($arraygroup->getBarcode(), '7',
  'barcode getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getBarcode(1)};
ok($@, 'barcode getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setBarcode()};
ok($@, 'barcode setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setBarcode('7', '7')};
ok($@, 'barcode setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setBarcode(undef)};
ok((!$@ and not defined $arraygroup->getBarcode()),
   'barcode setter accepts undef');



#
# testing attribute orientationMark
#

# test attribute values can be set in new()
is($arraygroup->getOrientationMark(), '8',
  'orientationMark new');

# test getter/setter
$arraygroup->setOrientationMark('8');
is($arraygroup->getOrientationMark(), '8',
  'orientationMark getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getOrientationMark(1)};
ok($@, 'orientationMark getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setOrientationMark()};
ok($@, 'orientationMark setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setOrientationMark('8', '8')};
ok($@, 'orientationMark setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setOrientationMark(undef)};
ok((!$@ and not defined $arraygroup->getOrientationMark()),
   'orientationMark setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($arraygroup->getIdentifier(), '9',
  'identifier new');

# test getter/setter
$arraygroup->setIdentifier('9');
is($arraygroup->getIdentifier(), '9',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setIdentifier('9', '9')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setIdentifier(undef)};
ok((!$@ and not defined $arraygroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute length
#

# test attribute values can be set in new()
is($arraygroup->getLength(), '10',
  'length new');

# test getter/setter
$arraygroup->setLength('10');
is($arraygroup->getLength(), '10',
  'length getter/setter');

# test getter throws exception with argument
eval {$arraygroup->getLength(1)};
ok($@, 'length getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraygroup->setLength()};
ok($@, 'length setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraygroup->setLength('10', '10')};
ok($@, 'length setter throws exception with too many argument');

# test setter accepts undef
eval {$arraygroup->setLength(undef)};
ok((!$@ and not defined $arraygroup->getLength()),
   'length setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ArrayGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraygroup = Bio::MAGE::Array::ArrayGroup->new(arrays => [Bio::MAGE::Array::Array->new()],
distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
substrateType => Bio::MAGE::Description::OntologyEntry->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
fiducials => [Bio::MAGE::Array::Fiducial->new()]);
}

my ($end, $assn);


# testing association arrays
my $arrays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arrays_assn = Bio::MAGE::Array::Array->new();
}


ok((UNIVERSAL::isa($arraygroup->getArrays,'ARRAY')
 and scalar @{$arraygroup->getArrays} == 1
 and UNIVERSAL::isa($arraygroup->getArrays->[0], q[Bio::MAGE::Array::Array])),
  'arrays set in new()');

ok(eq_array($arraygroup->setArrays([$arrays_assn]), [$arrays_assn]),
   'setArrays returns correct value');

ok((UNIVERSAL::isa($arraygroup->getArrays,'ARRAY')
 and scalar @{$arraygroup->getArrays} == 1
 and $arraygroup->getArrays->[0] == $arrays_assn),
   'getArrays fetches correct value');

is($arraygroup->addArrays($arrays_assn), 2,
  'addArrays returns number of items in list');

ok((UNIVERSAL::isa($arraygroup->getArrays,'ARRAY')
 and scalar @{$arraygroup->getArrays} == 2
 and $arraygroup->getArrays->[0] == $arrays_assn
 and $arraygroup->getArrays->[1] == $arrays_assn),
  'addArrays adds correct value');

# test setArrays throws exception with non-array argument
eval {$arraygroup->setArrays(1)};
ok($@, 'setArrays throws exception with non-array argument');

# test setArrays throws exception with bad argument array
eval {$arraygroup->setArrays([1])};
ok($@, 'setArrays throws exception with bad argument array');

# test addArrays throws exception with no arguments
eval {$arraygroup->addArrays()};
ok($@, 'addArrays throws exception with no arguments');

# test addArrays throws exception with bad argument
eval {$arraygroup->addArrays(1)};
ok($@, 'addArrays throws exception with bad array');

# test setArrays accepts empty array ref
eval {$arraygroup->setArrays([])};
ok((!$@ and defined $arraygroup->getArrays()
    and UNIVERSAL::isa($arraygroup->getArrays, 'ARRAY')
    and scalar @{$arraygroup->getArrays} == 0),
   'setArrays accepts empty array ref');


# test getArrays throws exception with argument
eval {$arraygroup->getArrays(1)};
ok($@, 'getArrays throws exception with argument');

# test setArrays throws exception with no argument
eval {$arraygroup->setArrays()};
ok($@, 'setArrays throws exception with no argument');

# test setArrays throws exception with too many argument
eval {$arraygroup->setArrays(1,2)};
ok($@, 'setArrays throws exception with too many argument');

# test setArrays accepts undef
eval {$arraygroup->setArrays(undef)};
ok((!$@ and not defined $arraygroup->getArrays()),
   'setArrays accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrays};
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
   'arrays->other() is a valid Bio::MAGE::Association::End'
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
   'arrays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($arraygroup->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($arraygroup->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($arraygroup->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$arraygroup->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$arraygroup->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$arraygroup->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$arraygroup->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$arraygroup->setDistanceUnit(undef)};
ok((!$@ and not defined $arraygroup->getDistanceUnit()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($arraygroup->getDescriptions,'ARRAY')
 and scalar @{$arraygroup->getDescriptions} == 1
 and UNIVERSAL::isa($arraygroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($arraygroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($arraygroup->getDescriptions,'ARRAY')
 and scalar @{$arraygroup->getDescriptions} == 1
 and $arraygroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($arraygroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($arraygroup->getDescriptions,'ARRAY')
 and scalar @{$arraygroup->getDescriptions} == 2
 and $arraygroup->getDescriptions->[0] == $descriptions_assn
 and $arraygroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$arraygroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$arraygroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$arraygroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$arraygroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$arraygroup->setDescriptions([])};
ok((!$@ and defined $arraygroup->getDescriptions()
    and UNIVERSAL::isa($arraygroup->getDescriptions, 'ARRAY')
    and scalar @{$arraygroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$arraygroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$arraygroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$arraygroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$arraygroup->setDescriptions(undef)};
ok((!$@ and not defined $arraygroup->getDescriptions()),
   'setDescriptions accepts undef');

# test the meta-data for the assoication
$assn = $assns{descriptions};
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
   'descriptions->other() is a valid Bio::MAGE::Association::End'
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
   'descriptions->self() is a valid Bio::MAGE::Association::End'
  );



# testing association substrateType
my $substratetype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $substratetype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($arraygroup->getSubstrateType, q[Bio::MAGE::Description::OntologyEntry]);

is($arraygroup->setSubstrateType($substratetype_assn), $substratetype_assn,
  'setSubstrateType returns value');

ok($arraygroup->getSubstrateType() == $substratetype_assn,
   'getSubstrateType fetches correct value');

# test setSubstrateType throws exception with bad argument
eval {$arraygroup->setSubstrateType(1)};
ok($@, 'setSubstrateType throws exception with bad argument');


# test getSubstrateType throws exception with argument
eval {$arraygroup->getSubstrateType(1)};
ok($@, 'getSubstrateType throws exception with argument');

# test setSubstrateType throws exception with no argument
eval {$arraygroup->setSubstrateType()};
ok($@, 'setSubstrateType throws exception with no argument');

# test setSubstrateType throws exception with too many argument
eval {$arraygroup->setSubstrateType(1,2)};
ok($@, 'setSubstrateType throws exception with too many argument');

# test setSubstrateType accepts undef
eval {$arraygroup->setSubstrateType(undef)};
ok((!$@ and not defined $arraygroup->getSubstrateType()),
   'setSubstrateType accepts undef');

# test the meta-data for the assoication
$assn = $assns{substrateType};
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
   'substrateType->other() is a valid Bio::MAGE::Association::End'
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
   'substrateType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($arraygroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($arraygroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($arraygroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$arraygroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$arraygroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$arraygroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$arraygroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$arraygroup->setSecurity(undef)};
ok((!$@ and not defined $arraygroup->getSecurity()),
   'setSecurity accepts undef');

# test the meta-data for the assoication
$assn = $assns{security};
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
   'security->other() is a valid Bio::MAGE::Association::End'
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
   'security->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($arraygroup->getAuditTrail,'ARRAY')
 and scalar @{$arraygroup->getAuditTrail} == 1
 and UNIVERSAL::isa($arraygroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($arraygroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($arraygroup->getAuditTrail,'ARRAY')
 and scalar @{$arraygroup->getAuditTrail} == 1
 and $arraygroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($arraygroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($arraygroup->getAuditTrail,'ARRAY')
 and scalar @{$arraygroup->getAuditTrail} == 2
 and $arraygroup->getAuditTrail->[0] == $audittrail_assn
 and $arraygroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$arraygroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$arraygroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$arraygroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$arraygroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$arraygroup->setAuditTrail([])};
ok((!$@ and defined $arraygroup->getAuditTrail()
    and UNIVERSAL::isa($arraygroup->getAuditTrail, 'ARRAY')
    and scalar @{$arraygroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$arraygroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$arraygroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$arraygroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$arraygroup->setAuditTrail(undef)};
ok((!$@ and not defined $arraygroup->getAuditTrail()),
   'setAuditTrail accepts undef');

# test the meta-data for the assoication
$assn = $assns{auditTrail};
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
   'auditTrail->other() is a valid Bio::MAGE::Association::End'
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
   'auditTrail->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($arraygroup->getPropertySets,'ARRAY')
 and scalar @{$arraygroup->getPropertySets} == 1
 and UNIVERSAL::isa($arraygroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($arraygroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($arraygroup->getPropertySets,'ARRAY')
 and scalar @{$arraygroup->getPropertySets} == 1
 and $arraygroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($arraygroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($arraygroup->getPropertySets,'ARRAY')
 and scalar @{$arraygroup->getPropertySets} == 2
 and $arraygroup->getPropertySets->[0] == $propertysets_assn
 and $arraygroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$arraygroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$arraygroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$arraygroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$arraygroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$arraygroup->setPropertySets([])};
ok((!$@ and defined $arraygroup->getPropertySets()
    and UNIVERSAL::isa($arraygroup->getPropertySets, 'ARRAY')
    and scalar @{$arraygroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$arraygroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$arraygroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$arraygroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$arraygroup->setPropertySets(undef)};
ok((!$@ and not defined $arraygroup->getPropertySets()),
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



# testing association fiducials
my $fiducials_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $fiducials_assn = Bio::MAGE::Array::Fiducial->new();
}


ok((UNIVERSAL::isa($arraygroup->getFiducials,'ARRAY')
 and scalar @{$arraygroup->getFiducials} == 1
 and UNIVERSAL::isa($arraygroup->getFiducials->[0], q[Bio::MAGE::Array::Fiducial])),
  'fiducials set in new()');

ok(eq_array($arraygroup->setFiducials([$fiducials_assn]), [$fiducials_assn]),
   'setFiducials returns correct value');

ok((UNIVERSAL::isa($arraygroup->getFiducials,'ARRAY')
 and scalar @{$arraygroup->getFiducials} == 1
 and $arraygroup->getFiducials->[0] == $fiducials_assn),
   'getFiducials fetches correct value');

is($arraygroup->addFiducials($fiducials_assn), 2,
  'addFiducials returns number of items in list');

ok((UNIVERSAL::isa($arraygroup->getFiducials,'ARRAY')
 and scalar @{$arraygroup->getFiducials} == 2
 and $arraygroup->getFiducials->[0] == $fiducials_assn
 and $arraygroup->getFiducials->[1] == $fiducials_assn),
  'addFiducials adds correct value');

# test setFiducials throws exception with non-array argument
eval {$arraygroup->setFiducials(1)};
ok($@, 'setFiducials throws exception with non-array argument');

# test setFiducials throws exception with bad argument array
eval {$arraygroup->setFiducials([1])};
ok($@, 'setFiducials throws exception with bad argument array');

# test addFiducials throws exception with no arguments
eval {$arraygroup->addFiducials()};
ok($@, 'addFiducials throws exception with no arguments');

# test addFiducials throws exception with bad argument
eval {$arraygroup->addFiducials(1)};
ok($@, 'addFiducials throws exception with bad array');

# test setFiducials accepts empty array ref
eval {$arraygroup->setFiducials([])};
ok((!$@ and defined $arraygroup->getFiducials()
    and UNIVERSAL::isa($arraygroup->getFiducials, 'ARRAY')
    and scalar @{$arraygroup->getFiducials} == 0),
   'setFiducials accepts empty array ref');


# test getFiducials throws exception with argument
eval {$arraygroup->getFiducials(1)};
ok($@, 'getFiducials throws exception with argument');

# test setFiducials throws exception with no argument
eval {$arraygroup->setFiducials()};
ok($@, 'setFiducials throws exception with no argument');

# test setFiducials throws exception with too many argument
eval {$arraygroup->setFiducials(1,2)};
ok($@, 'setFiducials throws exception with too many argument');

# test setFiducials accepts undef
eval {$arraygroup->setFiducials(undef)};
ok((!$@ and not defined $arraygroup->getFiducials()),
   'setFiducials accepts undef');

# test the meta-data for the assoication
$assn = $assns{fiducials};
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
   'fiducials->other() is a valid Bio::MAGE::Association::End'
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
   'fiducials->self() is a valid Bio::MAGE::Association::End'
  );





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($arraygroup, q[Bio::MAGE::Identifiable]);

