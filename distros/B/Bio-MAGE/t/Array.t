##############################
#
# Array.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Array.t`

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
use Test::More tests => 170;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::Array') };

use Bio::MAGE::Array::ArrayManufactureDeviation;
use Bio::MAGE::ArrayDesign::ArrayDesign;
use Bio::MAGE::NameValueType;
use Bio::MAGE::Array::ArrayManufacture;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Array::ArrayGroup;


# we test the new() method
my $array;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $array = Bio::MAGE::Array::Array->new();
}
isa_ok($array, 'Bio::MAGE::Array::Array');

# test the package_name class method
is($array->package_name(), q[Array],
  'package');

# test the class_name class method
is($array->class_name(), q[Bio::MAGE::Array::Array],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $array = Bio::MAGE::Array::Array->new(identifier => '1',
arrayXOrigin => '2',
arrayYOrigin => '3',
name => '4',
arrayIdentifier => '5',
originRelativeTo => '6');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($array->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$array->setIdentifier('1');
is($array->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$array->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setIdentifier(undef)};
ok((!$@ and not defined $array->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute arrayXOrigin
#

# test attribute values can be set in new()
is($array->getArrayXOrigin(), '2',
  'arrayXOrigin new');

# test getter/setter
$array->setArrayXOrigin('2');
is($array->getArrayXOrigin(), '2',
  'arrayXOrigin getter/setter');

# test getter throws exception with argument
eval {$array->getArrayXOrigin(1)};
ok($@, 'arrayXOrigin getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setArrayXOrigin()};
ok($@, 'arrayXOrigin setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setArrayXOrigin('2', '2')};
ok($@, 'arrayXOrigin setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setArrayXOrigin(undef)};
ok((!$@ and not defined $array->getArrayXOrigin()),
   'arrayXOrigin setter accepts undef');



#
# testing attribute arrayYOrigin
#

# test attribute values can be set in new()
is($array->getArrayYOrigin(), '3',
  'arrayYOrigin new');

# test getter/setter
$array->setArrayYOrigin('3');
is($array->getArrayYOrigin(), '3',
  'arrayYOrigin getter/setter');

# test getter throws exception with argument
eval {$array->getArrayYOrigin(1)};
ok($@, 'arrayYOrigin getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setArrayYOrigin()};
ok($@, 'arrayYOrigin setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setArrayYOrigin('3', '3')};
ok($@, 'arrayYOrigin setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setArrayYOrigin(undef)};
ok((!$@ and not defined $array->getArrayYOrigin()),
   'arrayYOrigin setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($array->getName(), '4',
  'name new');

# test getter/setter
$array->setName('4');
is($array->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$array->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setName(undef)};
ok((!$@ and not defined $array->getName()),
   'name setter accepts undef');



#
# testing attribute arrayIdentifier
#

# test attribute values can be set in new()
is($array->getArrayIdentifier(), '5',
  'arrayIdentifier new');

# test getter/setter
$array->setArrayIdentifier('5');
is($array->getArrayIdentifier(), '5',
  'arrayIdentifier getter/setter');

# test getter throws exception with argument
eval {$array->getArrayIdentifier(1)};
ok($@, 'arrayIdentifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setArrayIdentifier()};
ok($@, 'arrayIdentifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setArrayIdentifier('5', '5')};
ok($@, 'arrayIdentifier setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setArrayIdentifier(undef)};
ok((!$@ and not defined $array->getArrayIdentifier()),
   'arrayIdentifier setter accepts undef');



#
# testing attribute originRelativeTo
#

# test attribute values can be set in new()
is($array->getOriginRelativeTo(), '6',
  'originRelativeTo new');

# test getter/setter
$array->setOriginRelativeTo('6');
is($array->getOriginRelativeTo(), '6',
  'originRelativeTo getter/setter');

# test getter throws exception with argument
eval {$array->getOriginRelativeTo(1)};
ok($@, 'originRelativeTo getter throws exception with argument');

# test setter throws exception with no argument
eval {$array->setOriginRelativeTo()};
ok($@, 'originRelativeTo setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$array->setOriginRelativeTo('6', '6')};
ok($@, 'originRelativeTo setter throws exception with too many argument');

# test setter accepts undef
eval {$array->setOriginRelativeTo(undef)};
ok((!$@ and not defined $array->getOriginRelativeTo()),
   'originRelativeTo setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::Array->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $array = Bio::MAGE::Array::Array->new(arrayGroup => Bio::MAGE::Array::ArrayGroup->new(),
arrayDesign => Bio::MAGE::ArrayDesign::ArrayDesign->new(),
information => Bio::MAGE::Array::ArrayManufacture->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
arrayManufactureDeviations => [Bio::MAGE::Array::ArrayManufactureDeviation->new()]);
}

my ($end, $assn);


# testing association arrayGroup
my $arraygroup_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraygroup_assn = Bio::MAGE::Array::ArrayGroup->new();
}


isa_ok($array->getArrayGroup, q[Bio::MAGE::Array::ArrayGroup]);

is($array->setArrayGroup($arraygroup_assn), $arraygroup_assn,
  'setArrayGroup returns value');

ok($array->getArrayGroup() == $arraygroup_assn,
   'getArrayGroup fetches correct value');

# test setArrayGroup throws exception with bad argument
eval {$array->setArrayGroup(1)};
ok($@, 'setArrayGroup throws exception with bad argument');


# test getArrayGroup throws exception with argument
eval {$array->getArrayGroup(1)};
ok($@, 'getArrayGroup throws exception with argument');

# test setArrayGroup throws exception with no argument
eval {$array->setArrayGroup()};
ok($@, 'setArrayGroup throws exception with no argument');

# test setArrayGroup throws exception with too many argument
eval {$array->setArrayGroup(1,2)};
ok($@, 'setArrayGroup throws exception with too many argument');

# test setArrayGroup accepts undef
eval {$array->setArrayGroup(undef)};
ok((!$@ and not defined $array->getArrayGroup()),
   'setArrayGroup accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrayGroup};
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
   'arrayGroup->other() is a valid Bio::MAGE::Association::End'
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
   'arrayGroup->self() is a valid Bio::MAGE::Association::End'
  );



# testing association arrayDesign
my $arraydesign_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraydesign_assn = Bio::MAGE::ArrayDesign::ArrayDesign->new();
}


isa_ok($array->getArrayDesign, q[Bio::MAGE::ArrayDesign::ArrayDesign]);

is($array->setArrayDesign($arraydesign_assn), $arraydesign_assn,
  'setArrayDesign returns value');

ok($array->getArrayDesign() == $arraydesign_assn,
   'getArrayDesign fetches correct value');

# test setArrayDesign throws exception with bad argument
eval {$array->setArrayDesign(1)};
ok($@, 'setArrayDesign throws exception with bad argument');


# test getArrayDesign throws exception with argument
eval {$array->getArrayDesign(1)};
ok($@, 'getArrayDesign throws exception with argument');

# test setArrayDesign throws exception with no argument
eval {$array->setArrayDesign()};
ok($@, 'setArrayDesign throws exception with no argument');

# test setArrayDesign throws exception with too many argument
eval {$array->setArrayDesign(1,2)};
ok($@, 'setArrayDesign throws exception with too many argument');

# test setArrayDesign accepts undef
eval {$array->setArrayDesign(undef)};
ok((!$@ and not defined $array->getArrayDesign()),
   'setArrayDesign accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrayDesign};
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
   'arrayDesign->other() is a valid Bio::MAGE::Association::End'
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
   'arrayDesign->self() is a valid Bio::MAGE::Association::End'
  );



# testing association information
my $information_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $information_assn = Bio::MAGE::Array::ArrayManufacture->new();
}


isa_ok($array->getInformation, q[Bio::MAGE::Array::ArrayManufacture]);

is($array->setInformation($information_assn), $information_assn,
  'setInformation returns value');

ok($array->getInformation() == $information_assn,
   'getInformation fetches correct value');

# test setInformation throws exception with bad argument
eval {$array->setInformation(1)};
ok($@, 'setInformation throws exception with bad argument');


# test getInformation throws exception with argument
eval {$array->getInformation(1)};
ok($@, 'getInformation throws exception with argument');

# test setInformation throws exception with no argument
eval {$array->setInformation()};
ok($@, 'setInformation throws exception with no argument');

# test setInformation throws exception with too many argument
eval {$array->setInformation(1,2)};
ok($@, 'setInformation throws exception with too many argument');

# test setInformation accepts undef
eval {$array->setInformation(undef)};
ok((!$@ and not defined $array->getInformation()),
   'setInformation accepts undef');

# test the meta-data for the assoication
$assn = $assns{information};
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
   'information->other() is a valid Bio::MAGE::Association::End'
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
   'information->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($array->getAuditTrail,'ARRAY')
 and scalar @{$array->getAuditTrail} == 1
 and UNIVERSAL::isa($array->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($array->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($array->getAuditTrail,'ARRAY')
 and scalar @{$array->getAuditTrail} == 1
 and $array->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($array->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($array->getAuditTrail,'ARRAY')
 and scalar @{$array->getAuditTrail} == 2
 and $array->getAuditTrail->[0] == $audittrail_assn
 and $array->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$array->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$array->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$array->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$array->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$array->setAuditTrail([])};
ok((!$@ and defined $array->getAuditTrail()
    and UNIVERSAL::isa($array->getAuditTrail, 'ARRAY')
    and scalar @{$array->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$array->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$array->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$array->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$array->setAuditTrail(undef)};
ok((!$@ and not defined $array->getAuditTrail()),
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


ok((UNIVERSAL::isa($array->getPropertySets,'ARRAY')
 and scalar @{$array->getPropertySets} == 1
 and UNIVERSAL::isa($array->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($array->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($array->getPropertySets,'ARRAY')
 and scalar @{$array->getPropertySets} == 1
 and $array->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($array->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($array->getPropertySets,'ARRAY')
 and scalar @{$array->getPropertySets} == 2
 and $array->getPropertySets->[0] == $propertysets_assn
 and $array->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$array->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$array->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$array->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$array->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$array->setPropertySets([])};
ok((!$@ and defined $array->getPropertySets()
    and UNIVERSAL::isa($array->getPropertySets, 'ARRAY')
    and scalar @{$array->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$array->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$array->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$array->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$array->setPropertySets(undef)};
ok((!$@ and not defined $array->getPropertySets()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($array->getDescriptions,'ARRAY')
 and scalar @{$array->getDescriptions} == 1
 and UNIVERSAL::isa($array->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($array->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($array->getDescriptions,'ARRAY')
 and scalar @{$array->getDescriptions} == 1
 and $array->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($array->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($array->getDescriptions,'ARRAY')
 and scalar @{$array->getDescriptions} == 2
 and $array->getDescriptions->[0] == $descriptions_assn
 and $array->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$array->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$array->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$array->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$array->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$array->setDescriptions([])};
ok((!$@ and defined $array->getDescriptions()
    and UNIVERSAL::isa($array->getDescriptions, 'ARRAY')
    and scalar @{$array->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$array->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$array->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$array->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$array->setDescriptions(undef)};
ok((!$@ and not defined $array->getDescriptions()),
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


isa_ok($array->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($array->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($array->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$array->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$array->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$array->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$array->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$array->setSecurity(undef)};
ok((!$@ and not defined $array->getSecurity()),
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



# testing association arrayManufactureDeviations
my $arraymanufacturedeviations_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacturedeviations_assn = Bio::MAGE::Array::ArrayManufactureDeviation->new();
}


ok((UNIVERSAL::isa($array->getArrayManufactureDeviations,'ARRAY')
 and scalar @{$array->getArrayManufactureDeviations} == 1
 and UNIVERSAL::isa($array->getArrayManufactureDeviations->[0], q[Bio::MAGE::Array::ArrayManufactureDeviation])),
  'arrayManufactureDeviations set in new()');

ok(eq_array($array->setArrayManufactureDeviations([$arraymanufacturedeviations_assn]), [$arraymanufacturedeviations_assn]),
   'setArrayManufactureDeviations returns correct value');

ok((UNIVERSAL::isa($array->getArrayManufactureDeviations,'ARRAY')
 and scalar @{$array->getArrayManufactureDeviations} == 1
 and $array->getArrayManufactureDeviations->[0] == $arraymanufacturedeviations_assn),
   'getArrayManufactureDeviations fetches correct value');

is($array->addArrayManufactureDeviations($arraymanufacturedeviations_assn), 2,
  'addArrayManufactureDeviations returns number of items in list');

ok((UNIVERSAL::isa($array->getArrayManufactureDeviations,'ARRAY')
 and scalar @{$array->getArrayManufactureDeviations} == 2
 and $array->getArrayManufactureDeviations->[0] == $arraymanufacturedeviations_assn
 and $array->getArrayManufactureDeviations->[1] == $arraymanufacturedeviations_assn),
  'addArrayManufactureDeviations adds correct value');

# test setArrayManufactureDeviations throws exception with non-array argument
eval {$array->setArrayManufactureDeviations(1)};
ok($@, 'setArrayManufactureDeviations throws exception with non-array argument');

# test setArrayManufactureDeviations throws exception with bad argument array
eval {$array->setArrayManufactureDeviations([1])};
ok($@, 'setArrayManufactureDeviations throws exception with bad argument array');

# test addArrayManufactureDeviations throws exception with no arguments
eval {$array->addArrayManufactureDeviations()};
ok($@, 'addArrayManufactureDeviations throws exception with no arguments');

# test addArrayManufactureDeviations throws exception with bad argument
eval {$array->addArrayManufactureDeviations(1)};
ok($@, 'addArrayManufactureDeviations throws exception with bad array');

# test setArrayManufactureDeviations accepts empty array ref
eval {$array->setArrayManufactureDeviations([])};
ok((!$@ and defined $array->getArrayManufactureDeviations()
    and UNIVERSAL::isa($array->getArrayManufactureDeviations, 'ARRAY')
    and scalar @{$array->getArrayManufactureDeviations} == 0),
   'setArrayManufactureDeviations accepts empty array ref');


# test getArrayManufactureDeviations throws exception with argument
eval {$array->getArrayManufactureDeviations(1)};
ok($@, 'getArrayManufactureDeviations throws exception with argument');

# test setArrayManufactureDeviations throws exception with no argument
eval {$array->setArrayManufactureDeviations()};
ok($@, 'setArrayManufactureDeviations throws exception with no argument');

# test setArrayManufactureDeviations throws exception with too many argument
eval {$array->setArrayManufactureDeviations(1,2)};
ok($@, 'setArrayManufactureDeviations throws exception with too many argument');

# test setArrayManufactureDeviations accepts undef
eval {$array->setArrayManufactureDeviations(undef)};
ok((!$@ and not defined $array->getArrayManufactureDeviations()),
   'setArrayManufactureDeviations accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrayManufactureDeviations};
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
   'arrayManufactureDeviations->other() is a valid Bio::MAGE::Association::End'
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
   'arrayManufactureDeviations->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($array, q[Bio::MAGE::Identifiable]);

