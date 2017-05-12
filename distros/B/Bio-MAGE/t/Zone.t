##############################
#
# Zone.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Zone.t`

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
use Test::More tests => 137;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::Zone') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $zone;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zone = Bio::MAGE::ArrayDesign::Zone->new();
}
isa_ok($zone, 'Bio::MAGE::ArrayDesign::Zone');

# test the package_name class method
is($zone->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($zone->class_name(), q[Bio::MAGE::ArrayDesign::Zone],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zone = Bio::MAGE::ArrayDesign::Zone->new(lowerRightY => '1',
lowerRightX => '2',
upperLeftX => '3',
name => '4',
upperLeftY => '5',
identifier => '6',
row => '7',
column => '8');
}


#
# testing attribute lowerRightY
#

# test attribute values can be set in new()
is($zone->getLowerRightY(), '1',
  'lowerRightY new');

# test getter/setter
$zone->setLowerRightY('1');
is($zone->getLowerRightY(), '1',
  'lowerRightY getter/setter');

# test getter throws exception with argument
eval {$zone->getLowerRightY(1)};
ok($@, 'lowerRightY getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setLowerRightY()};
ok($@, 'lowerRightY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setLowerRightY('1', '1')};
ok($@, 'lowerRightY setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setLowerRightY(undef)};
ok((!$@ and not defined $zone->getLowerRightY()),
   'lowerRightY setter accepts undef');



#
# testing attribute lowerRightX
#

# test attribute values can be set in new()
is($zone->getLowerRightX(), '2',
  'lowerRightX new');

# test getter/setter
$zone->setLowerRightX('2');
is($zone->getLowerRightX(), '2',
  'lowerRightX getter/setter');

# test getter throws exception with argument
eval {$zone->getLowerRightX(1)};
ok($@, 'lowerRightX getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setLowerRightX()};
ok($@, 'lowerRightX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setLowerRightX('2', '2')};
ok($@, 'lowerRightX setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setLowerRightX(undef)};
ok((!$@ and not defined $zone->getLowerRightX()),
   'lowerRightX setter accepts undef');



#
# testing attribute upperLeftX
#

# test attribute values can be set in new()
is($zone->getUpperLeftX(), '3',
  'upperLeftX new');

# test getter/setter
$zone->setUpperLeftX('3');
is($zone->getUpperLeftX(), '3',
  'upperLeftX getter/setter');

# test getter throws exception with argument
eval {$zone->getUpperLeftX(1)};
ok($@, 'upperLeftX getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setUpperLeftX()};
ok($@, 'upperLeftX setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setUpperLeftX('3', '3')};
ok($@, 'upperLeftX setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setUpperLeftX(undef)};
ok((!$@ and not defined $zone->getUpperLeftX()),
   'upperLeftX setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($zone->getName(), '4',
  'name new');

# test getter/setter
$zone->setName('4');
is($zone->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$zone->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setName(undef)};
ok((!$@ and not defined $zone->getName()),
   'name setter accepts undef');



#
# testing attribute upperLeftY
#

# test attribute values can be set in new()
is($zone->getUpperLeftY(), '5',
  'upperLeftY new');

# test getter/setter
$zone->setUpperLeftY('5');
is($zone->getUpperLeftY(), '5',
  'upperLeftY getter/setter');

# test getter throws exception with argument
eval {$zone->getUpperLeftY(1)};
ok($@, 'upperLeftY getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setUpperLeftY()};
ok($@, 'upperLeftY setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setUpperLeftY('5', '5')};
ok($@, 'upperLeftY setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setUpperLeftY(undef)};
ok((!$@ and not defined $zone->getUpperLeftY()),
   'upperLeftY setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($zone->getIdentifier(), '6',
  'identifier new');

# test getter/setter
$zone->setIdentifier('6');
is($zone->getIdentifier(), '6',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$zone->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setIdentifier('6', '6')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setIdentifier(undef)};
ok((!$@ and not defined $zone->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute row
#

# test attribute values can be set in new()
is($zone->getRow(), '7',
  'row new');

# test getter/setter
$zone->setRow('7');
is($zone->getRow(), '7',
  'row getter/setter');

# test getter throws exception with argument
eval {$zone->getRow(1)};
ok($@, 'row getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setRow()};
ok($@, 'row setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setRow('7', '7')};
ok($@, 'row setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setRow(undef)};
ok((!$@ and not defined $zone->getRow()),
   'row setter accepts undef');



#
# testing attribute column
#

# test attribute values can be set in new()
is($zone->getColumn(), '8',
  'column new');

# test getter/setter
$zone->setColumn('8');
is($zone->getColumn(), '8',
  'column getter/setter');

# test getter throws exception with argument
eval {$zone->getColumn(1)};
ok($@, 'column getter throws exception with argument');

# test setter throws exception with no argument
eval {$zone->setColumn()};
ok($@, 'column setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zone->setColumn('8', '8')};
ok($@, 'column setter throws exception with too many argument');

# test setter accepts undef
eval {$zone->setColumn(undef)};
ok((!$@ and not defined $zone->getColumn()),
   'column setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::Zone->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zone = Bio::MAGE::ArrayDesign::Zone->new(distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
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


isa_ok($zone->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($zone->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($zone->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$zone->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$zone->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$zone->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$zone->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$zone->setDistanceUnit(undef)};
ok((!$@ and not defined $zone->getDistanceUnit()),
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


ok((UNIVERSAL::isa($zone->getDescriptions,'ARRAY')
 and scalar @{$zone->getDescriptions} == 1
 and UNIVERSAL::isa($zone->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($zone->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($zone->getDescriptions,'ARRAY')
 and scalar @{$zone->getDescriptions} == 1
 and $zone->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($zone->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($zone->getDescriptions,'ARRAY')
 and scalar @{$zone->getDescriptions} == 2
 and $zone->getDescriptions->[0] == $descriptions_assn
 and $zone->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$zone->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$zone->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$zone->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$zone->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$zone->setDescriptions([])};
ok((!$@ and defined $zone->getDescriptions()
    and UNIVERSAL::isa($zone->getDescriptions, 'ARRAY')
    and scalar @{$zone->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$zone->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$zone->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$zone->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$zone->setDescriptions(undef)};
ok((!$@ and not defined $zone->getDescriptions()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($zone->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($zone->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($zone->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$zone->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$zone->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$zone->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$zone->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$zone->setSecurity(undef)};
ok((!$@ and not defined $zone->getSecurity()),
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


ok((UNIVERSAL::isa($zone->getAuditTrail,'ARRAY')
 and scalar @{$zone->getAuditTrail} == 1
 and UNIVERSAL::isa($zone->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($zone->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($zone->getAuditTrail,'ARRAY')
 and scalar @{$zone->getAuditTrail} == 1
 and $zone->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($zone->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($zone->getAuditTrail,'ARRAY')
 and scalar @{$zone->getAuditTrail} == 2
 and $zone->getAuditTrail->[0] == $audittrail_assn
 and $zone->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$zone->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$zone->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$zone->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$zone->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$zone->setAuditTrail([])};
ok((!$@ and defined $zone->getAuditTrail()
    and UNIVERSAL::isa($zone->getAuditTrail, 'ARRAY')
    and scalar @{$zone->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$zone->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$zone->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$zone->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$zone->setAuditTrail(undef)};
ok((!$@ and not defined $zone->getAuditTrail()),
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


ok((UNIVERSAL::isa($zone->getPropertySets,'ARRAY')
 and scalar @{$zone->getPropertySets} == 1
 and UNIVERSAL::isa($zone->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($zone->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($zone->getPropertySets,'ARRAY')
 and scalar @{$zone->getPropertySets} == 1
 and $zone->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($zone->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($zone->getPropertySets,'ARRAY')
 and scalar @{$zone->getPropertySets} == 2
 and $zone->getPropertySets->[0] == $propertysets_assn
 and $zone->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$zone->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$zone->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$zone->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$zone->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$zone->setPropertySets([])};
ok((!$@ and defined $zone->getPropertySets()
    and UNIVERSAL::isa($zone->getPropertySets, 'ARRAY')
    and scalar @{$zone->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$zone->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$zone->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$zone->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$zone->setPropertySets(undef)};
ok((!$@ and not defined $zone->getPropertySets()),
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





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($zone, q[Bio::MAGE::Identifiable]);

