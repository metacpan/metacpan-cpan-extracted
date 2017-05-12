##############################
#
# Hardware.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Hardware.t`

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
use Test::More tests => 176;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::Hardware') };

use Bio::MAGE::Protocol::Software;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Protocol::Parameter;
use Bio::MAGE::Description::Description;


# we test the new() method
my $hardware;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardware = Bio::MAGE::Protocol::Hardware->new();
}
isa_ok($hardware, 'Bio::MAGE::Protocol::Hardware');

# test the package_name class method
is($hardware->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($hardware->class_name(), q[Bio::MAGE::Protocol::Hardware],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardware = Bio::MAGE::Protocol::Hardware->new(make => '1',
identifier => '2',
URI => '3',
model => '4',
name => '5');
}


#
# testing attribute make
#

# test attribute values can be set in new()
is($hardware->getMake(), '1',
  'make new');

# test getter/setter
$hardware->setMake('1');
is($hardware->getMake(), '1',
  'make getter/setter');

# test getter throws exception with argument
eval {$hardware->getMake(1)};
ok($@, 'make getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardware->setMake()};
ok($@, 'make setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardware->setMake('1', '1')};
ok($@, 'make setter throws exception with too many argument');

# test setter accepts undef
eval {$hardware->setMake(undef)};
ok((!$@ and not defined $hardware->getMake()),
   'make setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($hardware->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$hardware->setIdentifier('2');
is($hardware->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$hardware->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardware->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardware->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$hardware->setIdentifier(undef)};
ok((!$@ and not defined $hardware->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($hardware->getURI(), '3',
  'URI new');

# test getter/setter
$hardware->setURI('3');
is($hardware->getURI(), '3',
  'URI getter/setter');

# test getter throws exception with argument
eval {$hardware->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardware->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardware->setURI('3', '3')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$hardware->setURI(undef)};
ok((!$@ and not defined $hardware->getURI()),
   'URI setter accepts undef');



#
# testing attribute model
#

# test attribute values can be set in new()
is($hardware->getModel(), '4',
  'model new');

# test getter/setter
$hardware->setModel('4');
is($hardware->getModel(), '4',
  'model getter/setter');

# test getter throws exception with argument
eval {$hardware->getModel(1)};
ok($@, 'model getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardware->setModel()};
ok($@, 'model setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardware->setModel('4', '4')};
ok($@, 'model setter throws exception with too many argument');

# test setter accepts undef
eval {$hardware->setModel(undef)};
ok((!$@ and not defined $hardware->getModel()),
   'model setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($hardware->getName(), '5',
  'name new');

# test getter/setter
$hardware->setName('5');
is($hardware->getName(), '5',
  'name getter/setter');

# test getter throws exception with argument
eval {$hardware->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardware->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardware->setName('5', '5')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$hardware->setName(undef)};
ok((!$@ and not defined $hardware->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::Hardware->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardware = Bio::MAGE::Protocol::Hardware->new(parameterTypes => [Bio::MAGE::Protocol::Parameter->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
hardwareManufacturers => [Bio::MAGE::AuditAndSecurity::Contact->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
softwares => [Bio::MAGE::Protocol::Software->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
type => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association parameterTypes
my $parametertypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametertypes_assn = Bio::MAGE::Protocol::Parameter->new();
}


ok((UNIVERSAL::isa($hardware->getParameterTypes,'ARRAY')
 and scalar @{$hardware->getParameterTypes} == 1
 and UNIVERSAL::isa($hardware->getParameterTypes->[0], q[Bio::MAGE::Protocol::Parameter])),
  'parameterTypes set in new()');

ok(eq_array($hardware->setParameterTypes([$parametertypes_assn]), [$parametertypes_assn]),
   'setParameterTypes returns correct value');

ok((UNIVERSAL::isa($hardware->getParameterTypes,'ARRAY')
 and scalar @{$hardware->getParameterTypes} == 1
 and $hardware->getParameterTypes->[0] == $parametertypes_assn),
   'getParameterTypes fetches correct value');

is($hardware->addParameterTypes($parametertypes_assn), 2,
  'addParameterTypes returns number of items in list');

ok((UNIVERSAL::isa($hardware->getParameterTypes,'ARRAY')
 and scalar @{$hardware->getParameterTypes} == 2
 and $hardware->getParameterTypes->[0] == $parametertypes_assn
 and $hardware->getParameterTypes->[1] == $parametertypes_assn),
  'addParameterTypes adds correct value');

# test setParameterTypes throws exception with non-array argument
eval {$hardware->setParameterTypes(1)};
ok($@, 'setParameterTypes throws exception with non-array argument');

# test setParameterTypes throws exception with bad argument array
eval {$hardware->setParameterTypes([1])};
ok($@, 'setParameterTypes throws exception with bad argument array');

# test addParameterTypes throws exception with no arguments
eval {$hardware->addParameterTypes()};
ok($@, 'addParameterTypes throws exception with no arguments');

# test addParameterTypes throws exception with bad argument
eval {$hardware->addParameterTypes(1)};
ok($@, 'addParameterTypes throws exception with bad array');

# test setParameterTypes accepts empty array ref
eval {$hardware->setParameterTypes([])};
ok((!$@ and defined $hardware->getParameterTypes()
    and UNIVERSAL::isa($hardware->getParameterTypes, 'ARRAY')
    and scalar @{$hardware->getParameterTypes} == 0),
   'setParameterTypes accepts empty array ref');


# test getParameterTypes throws exception with argument
eval {$hardware->getParameterTypes(1)};
ok($@, 'getParameterTypes throws exception with argument');

# test setParameterTypes throws exception with no argument
eval {$hardware->setParameterTypes()};
ok($@, 'setParameterTypes throws exception with no argument');

# test setParameterTypes throws exception with too many argument
eval {$hardware->setParameterTypes(1,2)};
ok($@, 'setParameterTypes throws exception with too many argument');

# test setParameterTypes accepts undef
eval {$hardware->setParameterTypes(undef)};
ok((!$@ and not defined $hardware->getParameterTypes()),
   'setParameterTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameterTypes};
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
   'parameterTypes->other() is a valid Bio::MAGE::Association::End'
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
   'parameterTypes->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($hardware->getAuditTrail,'ARRAY')
 and scalar @{$hardware->getAuditTrail} == 1
 and UNIVERSAL::isa($hardware->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($hardware->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($hardware->getAuditTrail,'ARRAY')
 and scalar @{$hardware->getAuditTrail} == 1
 and $hardware->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($hardware->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($hardware->getAuditTrail,'ARRAY')
 and scalar @{$hardware->getAuditTrail} == 2
 and $hardware->getAuditTrail->[0] == $audittrail_assn
 and $hardware->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$hardware->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$hardware->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$hardware->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$hardware->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$hardware->setAuditTrail([])};
ok((!$@ and defined $hardware->getAuditTrail()
    and UNIVERSAL::isa($hardware->getAuditTrail, 'ARRAY')
    and scalar @{$hardware->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$hardware->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$hardware->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$hardware->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$hardware->setAuditTrail(undef)};
ok((!$@ and not defined $hardware->getAuditTrail()),
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


ok((UNIVERSAL::isa($hardware->getPropertySets,'ARRAY')
 and scalar @{$hardware->getPropertySets} == 1
 and UNIVERSAL::isa($hardware->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($hardware->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($hardware->getPropertySets,'ARRAY')
 and scalar @{$hardware->getPropertySets} == 1
 and $hardware->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($hardware->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($hardware->getPropertySets,'ARRAY')
 and scalar @{$hardware->getPropertySets} == 2
 and $hardware->getPropertySets->[0] == $propertysets_assn
 and $hardware->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$hardware->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$hardware->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$hardware->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$hardware->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$hardware->setPropertySets([])};
ok((!$@ and defined $hardware->getPropertySets()
    and UNIVERSAL::isa($hardware->getPropertySets, 'ARRAY')
    and scalar @{$hardware->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$hardware->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$hardware->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$hardware->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$hardware->setPropertySets(undef)};
ok((!$@ and not defined $hardware->getPropertySets()),
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



# testing association hardwareManufacturers
my $hardwaremanufacturers_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwaremanufacturers_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($hardware->getHardwareManufacturers,'ARRAY')
 and scalar @{$hardware->getHardwareManufacturers} == 1
 and UNIVERSAL::isa($hardware->getHardwareManufacturers->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'hardwareManufacturers set in new()');

ok(eq_array($hardware->setHardwareManufacturers([$hardwaremanufacturers_assn]), [$hardwaremanufacturers_assn]),
   'setHardwareManufacturers returns correct value');

ok((UNIVERSAL::isa($hardware->getHardwareManufacturers,'ARRAY')
 and scalar @{$hardware->getHardwareManufacturers} == 1
 and $hardware->getHardwareManufacturers->[0] == $hardwaremanufacturers_assn),
   'getHardwareManufacturers fetches correct value');

is($hardware->addHardwareManufacturers($hardwaremanufacturers_assn), 2,
  'addHardwareManufacturers returns number of items in list');

ok((UNIVERSAL::isa($hardware->getHardwareManufacturers,'ARRAY')
 and scalar @{$hardware->getHardwareManufacturers} == 2
 and $hardware->getHardwareManufacturers->[0] == $hardwaremanufacturers_assn
 and $hardware->getHardwareManufacturers->[1] == $hardwaremanufacturers_assn),
  'addHardwareManufacturers adds correct value');

# test setHardwareManufacturers throws exception with non-array argument
eval {$hardware->setHardwareManufacturers(1)};
ok($@, 'setHardwareManufacturers throws exception with non-array argument');

# test setHardwareManufacturers throws exception with bad argument array
eval {$hardware->setHardwareManufacturers([1])};
ok($@, 'setHardwareManufacturers throws exception with bad argument array');

# test addHardwareManufacturers throws exception with no arguments
eval {$hardware->addHardwareManufacturers()};
ok($@, 'addHardwareManufacturers throws exception with no arguments');

# test addHardwareManufacturers throws exception with bad argument
eval {$hardware->addHardwareManufacturers(1)};
ok($@, 'addHardwareManufacturers throws exception with bad array');

# test setHardwareManufacturers accepts empty array ref
eval {$hardware->setHardwareManufacturers([])};
ok((!$@ and defined $hardware->getHardwareManufacturers()
    and UNIVERSAL::isa($hardware->getHardwareManufacturers, 'ARRAY')
    and scalar @{$hardware->getHardwareManufacturers} == 0),
   'setHardwareManufacturers accepts empty array ref');


# test getHardwareManufacturers throws exception with argument
eval {$hardware->getHardwareManufacturers(1)};
ok($@, 'getHardwareManufacturers throws exception with argument');

# test setHardwareManufacturers throws exception with no argument
eval {$hardware->setHardwareManufacturers()};
ok($@, 'setHardwareManufacturers throws exception with no argument');

# test setHardwareManufacturers throws exception with too many argument
eval {$hardware->setHardwareManufacturers(1,2)};
ok($@, 'setHardwareManufacturers throws exception with too many argument');

# test setHardwareManufacturers accepts undef
eval {$hardware->setHardwareManufacturers(undef)};
ok((!$@ and not defined $hardware->getHardwareManufacturers()),
   'setHardwareManufacturers accepts undef');

# test the meta-data for the assoication
$assn = $assns{hardwareManufacturers};
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
   'hardwareManufacturers->other() is a valid Bio::MAGE::Association::End'
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
   'hardwareManufacturers->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($hardware->getDescriptions,'ARRAY')
 and scalar @{$hardware->getDescriptions} == 1
 and UNIVERSAL::isa($hardware->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($hardware->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($hardware->getDescriptions,'ARRAY')
 and scalar @{$hardware->getDescriptions} == 1
 and $hardware->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($hardware->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($hardware->getDescriptions,'ARRAY')
 and scalar @{$hardware->getDescriptions} == 2
 and $hardware->getDescriptions->[0] == $descriptions_assn
 and $hardware->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$hardware->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$hardware->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$hardware->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$hardware->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$hardware->setDescriptions([])};
ok((!$@ and defined $hardware->getDescriptions()
    and UNIVERSAL::isa($hardware->getDescriptions, 'ARRAY')
    and scalar @{$hardware->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$hardware->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$hardware->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$hardware->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$hardware->setDescriptions(undef)};
ok((!$@ and not defined $hardware->getDescriptions()),
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



# testing association softwares
my $softwares_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwares_assn = Bio::MAGE::Protocol::Software->new();
}


ok((UNIVERSAL::isa($hardware->getSoftwares,'ARRAY')
 and scalar @{$hardware->getSoftwares} == 1
 and UNIVERSAL::isa($hardware->getSoftwares->[0], q[Bio::MAGE::Protocol::Software])),
  'softwares set in new()');

ok(eq_array($hardware->setSoftwares([$softwares_assn]), [$softwares_assn]),
   'setSoftwares returns correct value');

ok((UNIVERSAL::isa($hardware->getSoftwares,'ARRAY')
 and scalar @{$hardware->getSoftwares} == 1
 and $hardware->getSoftwares->[0] == $softwares_assn),
   'getSoftwares fetches correct value');

is($hardware->addSoftwares($softwares_assn), 2,
  'addSoftwares returns number of items in list');

ok((UNIVERSAL::isa($hardware->getSoftwares,'ARRAY')
 and scalar @{$hardware->getSoftwares} == 2
 and $hardware->getSoftwares->[0] == $softwares_assn
 and $hardware->getSoftwares->[1] == $softwares_assn),
  'addSoftwares adds correct value');

# test setSoftwares throws exception with non-array argument
eval {$hardware->setSoftwares(1)};
ok($@, 'setSoftwares throws exception with non-array argument');

# test setSoftwares throws exception with bad argument array
eval {$hardware->setSoftwares([1])};
ok($@, 'setSoftwares throws exception with bad argument array');

# test addSoftwares throws exception with no arguments
eval {$hardware->addSoftwares()};
ok($@, 'addSoftwares throws exception with no arguments');

# test addSoftwares throws exception with bad argument
eval {$hardware->addSoftwares(1)};
ok($@, 'addSoftwares throws exception with bad array');

# test setSoftwares accepts empty array ref
eval {$hardware->setSoftwares([])};
ok((!$@ and defined $hardware->getSoftwares()
    and UNIVERSAL::isa($hardware->getSoftwares, 'ARRAY')
    and scalar @{$hardware->getSoftwares} == 0),
   'setSoftwares accepts empty array ref');


# test getSoftwares throws exception with argument
eval {$hardware->getSoftwares(1)};
ok($@, 'getSoftwares throws exception with argument');

# test setSoftwares throws exception with no argument
eval {$hardware->setSoftwares()};
ok($@, 'setSoftwares throws exception with no argument');

# test setSoftwares throws exception with too many argument
eval {$hardware->setSoftwares(1,2)};
ok($@, 'setSoftwares throws exception with too many argument');

# test setSoftwares accepts undef
eval {$hardware->setSoftwares(undef)};
ok((!$@ and not defined $hardware->getSoftwares()),
   'setSoftwares accepts undef');

# test the meta-data for the assoication
$assn = $assns{softwares};
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
   'softwares->other() is a valid Bio::MAGE::Association::End'
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
   'softwares->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($hardware->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($hardware->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($hardware->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$hardware->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$hardware->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$hardware->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$hardware->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$hardware->setSecurity(undef)};
ok((!$@ and not defined $hardware->getSecurity()),
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



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($hardware->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($hardware->setType($type_assn), $type_assn,
  'setType returns value');

ok($hardware->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$hardware->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$hardware->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$hardware->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$hardware->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$hardware->setType(undef)};
ok((!$@ and not defined $hardware->getType()),
   'setType accepts undef');

# test the meta-data for the assoication
$assn = $assns{type};
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
   'type->other() is a valid Bio::MAGE::Association::End'
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
   'type->self() is a valid Bio::MAGE::Association::End'
  );





my $parameterizable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $parameterizable = Bio::MAGE::Protocol::Parameterizable->new();
}

# testing superclass Parameterizable
isa_ok($parameterizable, q[Bio::MAGE::Protocol::Parameterizable]);
isa_ok($hardware, q[Bio::MAGE::Protocol::Parameterizable]);

