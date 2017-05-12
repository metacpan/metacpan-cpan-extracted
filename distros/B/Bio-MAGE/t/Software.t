##############################
#
# Software.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Software.t`

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
use Test::More tests => 177;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::Software') };

use Bio::MAGE::Protocol::Software;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Protocol::Hardware;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Protocol::Parameter;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;


# we test the new() method
my $software;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $software = Bio::MAGE::Protocol::Software->new();
}
isa_ok($software, 'Bio::MAGE::Protocol::Software');

# test the package_name class method
is($software->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($software->class_name(), q[Bio::MAGE::Protocol::Software],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $software = Bio::MAGE::Protocol::Software->new(identifier => '1',
URI => '2',
name => '3');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($software->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$software->setIdentifier('1');
is($software->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$software->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$software->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$software->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$software->setIdentifier(undef)};
ok((!$@ and not defined $software->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($software->getURI(), '2',
  'URI new');

# test getter/setter
$software->setURI('2');
is($software->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$software->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$software->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$software->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$software->setURI(undef)};
ok((!$@ and not defined $software->getURI()),
   'URI setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($software->getName(), '3',
  'name new');

# test getter/setter
$software->setName('3');
is($software->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$software->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$software->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$software->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$software->setName(undef)};
ok((!$@ and not defined $software->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::Software->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $software = Bio::MAGE::Protocol::Software->new(softwareManufacturers => [Bio::MAGE::AuditAndSecurity::Contact->new()],
parameterTypes => [Bio::MAGE::Protocol::Parameter->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
softwares => [Bio::MAGE::Protocol::Software->new()],
hardware => Bio::MAGE::Protocol::Hardware->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
type => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association softwareManufacturers
my $softwaremanufacturers_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwaremanufacturers_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($software->getSoftwareManufacturers,'ARRAY')
 and scalar @{$software->getSoftwareManufacturers} == 1
 and UNIVERSAL::isa($software->getSoftwareManufacturers->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'softwareManufacturers set in new()');

ok(eq_array($software->setSoftwareManufacturers([$softwaremanufacturers_assn]), [$softwaremanufacturers_assn]),
   'setSoftwareManufacturers returns correct value');

ok((UNIVERSAL::isa($software->getSoftwareManufacturers,'ARRAY')
 and scalar @{$software->getSoftwareManufacturers} == 1
 and $software->getSoftwareManufacturers->[0] == $softwaremanufacturers_assn),
   'getSoftwareManufacturers fetches correct value');

is($software->addSoftwareManufacturers($softwaremanufacturers_assn), 2,
  'addSoftwareManufacturers returns number of items in list');

ok((UNIVERSAL::isa($software->getSoftwareManufacturers,'ARRAY')
 and scalar @{$software->getSoftwareManufacturers} == 2
 and $software->getSoftwareManufacturers->[0] == $softwaremanufacturers_assn
 and $software->getSoftwareManufacturers->[1] == $softwaremanufacturers_assn),
  'addSoftwareManufacturers adds correct value');

# test setSoftwareManufacturers throws exception with non-array argument
eval {$software->setSoftwareManufacturers(1)};
ok($@, 'setSoftwareManufacturers throws exception with non-array argument');

# test setSoftwareManufacturers throws exception with bad argument array
eval {$software->setSoftwareManufacturers([1])};
ok($@, 'setSoftwareManufacturers throws exception with bad argument array');

# test addSoftwareManufacturers throws exception with no arguments
eval {$software->addSoftwareManufacturers()};
ok($@, 'addSoftwareManufacturers throws exception with no arguments');

# test addSoftwareManufacturers throws exception with bad argument
eval {$software->addSoftwareManufacturers(1)};
ok($@, 'addSoftwareManufacturers throws exception with bad array');

# test setSoftwareManufacturers accepts empty array ref
eval {$software->setSoftwareManufacturers([])};
ok((!$@ and defined $software->getSoftwareManufacturers()
    and UNIVERSAL::isa($software->getSoftwareManufacturers, 'ARRAY')
    and scalar @{$software->getSoftwareManufacturers} == 0),
   'setSoftwareManufacturers accepts empty array ref');


# test getSoftwareManufacturers throws exception with argument
eval {$software->getSoftwareManufacturers(1)};
ok($@, 'getSoftwareManufacturers throws exception with argument');

# test setSoftwareManufacturers throws exception with no argument
eval {$software->setSoftwareManufacturers()};
ok($@, 'setSoftwareManufacturers throws exception with no argument');

# test setSoftwareManufacturers throws exception with too many argument
eval {$software->setSoftwareManufacturers(1,2)};
ok($@, 'setSoftwareManufacturers throws exception with too many argument');

# test setSoftwareManufacturers accepts undef
eval {$software->setSoftwareManufacturers(undef)};
ok((!$@ and not defined $software->getSoftwareManufacturers()),
   'setSoftwareManufacturers accepts undef');

# test the meta-data for the assoication
$assn = $assns{softwareManufacturers};
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
   'softwareManufacturers->other() is a valid Bio::MAGE::Association::End'
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
   'softwareManufacturers->self() is a valid Bio::MAGE::Association::End'
  );



# testing association parameterTypes
my $parametertypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametertypes_assn = Bio::MAGE::Protocol::Parameter->new();
}


ok((UNIVERSAL::isa($software->getParameterTypes,'ARRAY')
 and scalar @{$software->getParameterTypes} == 1
 and UNIVERSAL::isa($software->getParameterTypes->[0], q[Bio::MAGE::Protocol::Parameter])),
  'parameterTypes set in new()');

ok(eq_array($software->setParameterTypes([$parametertypes_assn]), [$parametertypes_assn]),
   'setParameterTypes returns correct value');

ok((UNIVERSAL::isa($software->getParameterTypes,'ARRAY')
 and scalar @{$software->getParameterTypes} == 1
 and $software->getParameterTypes->[0] == $parametertypes_assn),
   'getParameterTypes fetches correct value');

is($software->addParameterTypes($parametertypes_assn), 2,
  'addParameterTypes returns number of items in list');

ok((UNIVERSAL::isa($software->getParameterTypes,'ARRAY')
 and scalar @{$software->getParameterTypes} == 2
 and $software->getParameterTypes->[0] == $parametertypes_assn
 and $software->getParameterTypes->[1] == $parametertypes_assn),
  'addParameterTypes adds correct value');

# test setParameterTypes throws exception with non-array argument
eval {$software->setParameterTypes(1)};
ok($@, 'setParameterTypes throws exception with non-array argument');

# test setParameterTypes throws exception with bad argument array
eval {$software->setParameterTypes([1])};
ok($@, 'setParameterTypes throws exception with bad argument array');

# test addParameterTypes throws exception with no arguments
eval {$software->addParameterTypes()};
ok($@, 'addParameterTypes throws exception with no arguments');

# test addParameterTypes throws exception with bad argument
eval {$software->addParameterTypes(1)};
ok($@, 'addParameterTypes throws exception with bad array');

# test setParameterTypes accepts empty array ref
eval {$software->setParameterTypes([])};
ok((!$@ and defined $software->getParameterTypes()
    and UNIVERSAL::isa($software->getParameterTypes, 'ARRAY')
    and scalar @{$software->getParameterTypes} == 0),
   'setParameterTypes accepts empty array ref');


# test getParameterTypes throws exception with argument
eval {$software->getParameterTypes(1)};
ok($@, 'getParameterTypes throws exception with argument');

# test setParameterTypes throws exception with no argument
eval {$software->setParameterTypes()};
ok($@, 'setParameterTypes throws exception with no argument');

# test setParameterTypes throws exception with too many argument
eval {$software->setParameterTypes(1,2)};
ok($@, 'setParameterTypes throws exception with too many argument');

# test setParameterTypes accepts undef
eval {$software->setParameterTypes(undef)};
ok((!$@ and not defined $software->getParameterTypes()),
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


ok((UNIVERSAL::isa($software->getAuditTrail,'ARRAY')
 and scalar @{$software->getAuditTrail} == 1
 and UNIVERSAL::isa($software->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($software->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($software->getAuditTrail,'ARRAY')
 and scalar @{$software->getAuditTrail} == 1
 and $software->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($software->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($software->getAuditTrail,'ARRAY')
 and scalar @{$software->getAuditTrail} == 2
 and $software->getAuditTrail->[0] == $audittrail_assn
 and $software->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$software->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$software->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$software->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$software->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$software->setAuditTrail([])};
ok((!$@ and defined $software->getAuditTrail()
    and UNIVERSAL::isa($software->getAuditTrail, 'ARRAY')
    and scalar @{$software->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$software->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$software->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$software->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$software->setAuditTrail(undef)};
ok((!$@ and not defined $software->getAuditTrail()),
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


ok((UNIVERSAL::isa($software->getPropertySets,'ARRAY')
 and scalar @{$software->getPropertySets} == 1
 and UNIVERSAL::isa($software->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($software->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($software->getPropertySets,'ARRAY')
 and scalar @{$software->getPropertySets} == 1
 and $software->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($software->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($software->getPropertySets,'ARRAY')
 and scalar @{$software->getPropertySets} == 2
 and $software->getPropertySets->[0] == $propertysets_assn
 and $software->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$software->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$software->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$software->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$software->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$software->setPropertySets([])};
ok((!$@ and defined $software->getPropertySets()
    and UNIVERSAL::isa($software->getPropertySets, 'ARRAY')
    and scalar @{$software->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$software->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$software->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$software->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$software->setPropertySets(undef)};
ok((!$@ and not defined $software->getPropertySets()),
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


ok((UNIVERSAL::isa($software->getDescriptions,'ARRAY')
 and scalar @{$software->getDescriptions} == 1
 and UNIVERSAL::isa($software->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($software->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($software->getDescriptions,'ARRAY')
 and scalar @{$software->getDescriptions} == 1
 and $software->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($software->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($software->getDescriptions,'ARRAY')
 and scalar @{$software->getDescriptions} == 2
 and $software->getDescriptions->[0] == $descriptions_assn
 and $software->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$software->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$software->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$software->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$software->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$software->setDescriptions([])};
ok((!$@ and defined $software->getDescriptions()
    and UNIVERSAL::isa($software->getDescriptions, 'ARRAY')
    and scalar @{$software->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$software->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$software->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$software->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$software->setDescriptions(undef)};
ok((!$@ and not defined $software->getDescriptions()),
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


ok((UNIVERSAL::isa($software->getSoftwares,'ARRAY')
 and scalar @{$software->getSoftwares} == 1
 and UNIVERSAL::isa($software->getSoftwares->[0], q[Bio::MAGE::Protocol::Software])),
  'softwares set in new()');

ok(eq_array($software->setSoftwares([$softwares_assn]), [$softwares_assn]),
   'setSoftwares returns correct value');

ok((UNIVERSAL::isa($software->getSoftwares,'ARRAY')
 and scalar @{$software->getSoftwares} == 1
 and $software->getSoftwares->[0] == $softwares_assn),
   'getSoftwares fetches correct value');

is($software->addSoftwares($softwares_assn), 2,
  'addSoftwares returns number of items in list');

ok((UNIVERSAL::isa($software->getSoftwares,'ARRAY')
 and scalar @{$software->getSoftwares} == 2
 and $software->getSoftwares->[0] == $softwares_assn
 and $software->getSoftwares->[1] == $softwares_assn),
  'addSoftwares adds correct value');

# test setSoftwares throws exception with non-array argument
eval {$software->setSoftwares(1)};
ok($@, 'setSoftwares throws exception with non-array argument');

# test setSoftwares throws exception with bad argument array
eval {$software->setSoftwares([1])};
ok($@, 'setSoftwares throws exception with bad argument array');

# test addSoftwares throws exception with no arguments
eval {$software->addSoftwares()};
ok($@, 'addSoftwares throws exception with no arguments');

# test addSoftwares throws exception with bad argument
eval {$software->addSoftwares(1)};
ok($@, 'addSoftwares throws exception with bad array');

# test setSoftwares accepts empty array ref
eval {$software->setSoftwares([])};
ok((!$@ and defined $software->getSoftwares()
    and UNIVERSAL::isa($software->getSoftwares, 'ARRAY')
    and scalar @{$software->getSoftwares} == 0),
   'setSoftwares accepts empty array ref');


# test getSoftwares throws exception with argument
eval {$software->getSoftwares(1)};
ok($@, 'getSoftwares throws exception with argument');

# test setSoftwares throws exception with no argument
eval {$software->setSoftwares()};
ok($@, 'setSoftwares throws exception with no argument');

# test setSoftwares throws exception with too many argument
eval {$software->setSoftwares(1,2)};
ok($@, 'setSoftwares throws exception with too many argument');

# test setSoftwares accepts undef
eval {$software->setSoftwares(undef)};
ok((!$@ and not defined $software->getSoftwares()),
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



# testing association hardware
my $hardware_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardware_assn = Bio::MAGE::Protocol::Hardware->new();
}


isa_ok($software->getHardware, q[Bio::MAGE::Protocol::Hardware]);

is($software->setHardware($hardware_assn), $hardware_assn,
  'setHardware returns value');

ok($software->getHardware() == $hardware_assn,
   'getHardware fetches correct value');

# test setHardware throws exception with bad argument
eval {$software->setHardware(1)};
ok($@, 'setHardware throws exception with bad argument');


# test getHardware throws exception with argument
eval {$software->getHardware(1)};
ok($@, 'getHardware throws exception with argument');

# test setHardware throws exception with no argument
eval {$software->setHardware()};
ok($@, 'setHardware throws exception with no argument');

# test setHardware throws exception with too many argument
eval {$software->setHardware(1,2)};
ok($@, 'setHardware throws exception with too many argument');

# test setHardware accepts undef
eval {$software->setHardware(undef)};
ok((!$@ and not defined $software->getHardware()),
   'setHardware accepts undef');

# test the meta-data for the assoication
$assn = $assns{hardware};
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
   'hardware->other() is a valid Bio::MAGE::Association::End'
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
   'hardware->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($software->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($software->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($software->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$software->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$software->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$software->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$software->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$software->setSecurity(undef)};
ok((!$@ and not defined $software->getSecurity()),
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


isa_ok($software->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($software->setType($type_assn), $type_assn,
  'setType returns value');

ok($software->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$software->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$software->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$software->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$software->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$software->setType(undef)};
ok((!$@ and not defined $software->getType()),
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
isa_ok($software, q[Bio::MAGE::Protocol::Parameterizable]);

