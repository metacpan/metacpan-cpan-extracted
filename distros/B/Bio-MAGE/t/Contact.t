##############################
#
# Contact.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Contact.t`

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
use Test::More tests => 147;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::Contact') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;

use Bio::MAGE::AuditAndSecurity::Person;
use Bio::MAGE::AuditAndSecurity::Organization;

# we test the new() method
my $contact;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $contact = Bio::MAGE::AuditAndSecurity::Contact->new();
}
isa_ok($contact, 'Bio::MAGE::AuditAndSecurity::Contact');

# test the package_name class method
is($contact->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($contact->class_name(), q[Bio::MAGE::AuditAndSecurity::Contact],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $contact = Bio::MAGE::AuditAndSecurity::Contact->new(email => '1',
URI => '2',
identifier => '3',
tollFreePhone => '4',
fax => '5',
name => '6',
address => '7',
phone => '8');
}


#
# testing attribute email
#

# test attribute values can be set in new()
is($contact->getEmail(), '1',
  'email new');

# test getter/setter
$contact->setEmail('1');
is($contact->getEmail(), '1',
  'email getter/setter');

# test getter throws exception with argument
eval {$contact->getEmail(1)};
ok($@, 'email getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setEmail()};
ok($@, 'email setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setEmail('1', '1')};
ok($@, 'email setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setEmail(undef)};
ok((!$@ and not defined $contact->getEmail()),
   'email setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($contact->getURI(), '2',
  'URI new');

# test getter/setter
$contact->setURI('2');
is($contact->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$contact->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setURI(undef)};
ok((!$@ and not defined $contact->getURI()),
   'URI setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($contact->getIdentifier(), '3',
  'identifier new');

# test getter/setter
$contact->setIdentifier('3');
is($contact->getIdentifier(), '3',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$contact->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setIdentifier('3', '3')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setIdentifier(undef)};
ok((!$@ and not defined $contact->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute tollFreePhone
#

# test attribute values can be set in new()
is($contact->getTollFreePhone(), '4',
  'tollFreePhone new');

# test getter/setter
$contact->setTollFreePhone('4');
is($contact->getTollFreePhone(), '4',
  'tollFreePhone getter/setter');

# test getter throws exception with argument
eval {$contact->getTollFreePhone(1)};
ok($@, 'tollFreePhone getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setTollFreePhone()};
ok($@, 'tollFreePhone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setTollFreePhone('4', '4')};
ok($@, 'tollFreePhone setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setTollFreePhone(undef)};
ok((!$@ and not defined $contact->getTollFreePhone()),
   'tollFreePhone setter accepts undef');



#
# testing attribute fax
#

# test attribute values can be set in new()
is($contact->getFax(), '5',
  'fax new');

# test getter/setter
$contact->setFax('5');
is($contact->getFax(), '5',
  'fax getter/setter');

# test getter throws exception with argument
eval {$contact->getFax(1)};
ok($@, 'fax getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setFax()};
ok($@, 'fax setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setFax('5', '5')};
ok($@, 'fax setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setFax(undef)};
ok((!$@ and not defined $contact->getFax()),
   'fax setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($contact->getName(), '6',
  'name new');

# test getter/setter
$contact->setName('6');
is($contact->getName(), '6',
  'name getter/setter');

# test getter throws exception with argument
eval {$contact->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setName('6', '6')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setName(undef)};
ok((!$@ and not defined $contact->getName()),
   'name setter accepts undef');



#
# testing attribute address
#

# test attribute values can be set in new()
is($contact->getAddress(), '7',
  'address new');

# test getter/setter
$contact->setAddress('7');
is($contact->getAddress(), '7',
  'address getter/setter');

# test getter throws exception with argument
eval {$contact->getAddress(1)};
ok($@, 'address getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setAddress()};
ok($@, 'address setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setAddress('7', '7')};
ok($@, 'address setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setAddress(undef)};
ok((!$@ and not defined $contact->getAddress()),
   'address setter accepts undef');



#
# testing attribute phone
#

# test attribute values can be set in new()
is($contact->getPhone(), '8',
  'phone new');

# test getter/setter
$contact->setPhone('8');
is($contact->getPhone(), '8',
  'phone getter/setter');

# test getter throws exception with argument
eval {$contact->getPhone(1)};
ok($@, 'phone getter throws exception with argument');

# test setter throws exception with no argument
eval {$contact->setPhone()};
ok($@, 'phone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$contact->setPhone('8', '8')};
ok($@, 'phone setter throws exception with too many argument');

# test setter accepts undef
eval {$contact->setPhone(undef)};
ok((!$@ and not defined $contact->getPhone()),
   'phone setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::Contact->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $contact = Bio::MAGE::AuditAndSecurity::Contact->new(roles => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association roles
my $roles_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $roles_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($contact->getRoles,'ARRAY')
 and scalar @{$contact->getRoles} == 1
 and UNIVERSAL::isa($contact->getRoles->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'roles set in new()');

ok(eq_array($contact->setRoles([$roles_assn]), [$roles_assn]),
   'setRoles returns correct value');

ok((UNIVERSAL::isa($contact->getRoles,'ARRAY')
 and scalar @{$contact->getRoles} == 1
 and $contact->getRoles->[0] == $roles_assn),
   'getRoles fetches correct value');

is($contact->addRoles($roles_assn), 2,
  'addRoles returns number of items in list');

ok((UNIVERSAL::isa($contact->getRoles,'ARRAY')
 and scalar @{$contact->getRoles} == 2
 and $contact->getRoles->[0] == $roles_assn
 and $contact->getRoles->[1] == $roles_assn),
  'addRoles adds correct value');

# test setRoles throws exception with non-array argument
eval {$contact->setRoles(1)};
ok($@, 'setRoles throws exception with non-array argument');

# test setRoles throws exception with bad argument array
eval {$contact->setRoles([1])};
ok($@, 'setRoles throws exception with bad argument array');

# test addRoles throws exception with no arguments
eval {$contact->addRoles()};
ok($@, 'addRoles throws exception with no arguments');

# test addRoles throws exception with bad argument
eval {$contact->addRoles(1)};
ok($@, 'addRoles throws exception with bad array');

# test setRoles accepts empty array ref
eval {$contact->setRoles([])};
ok((!$@ and defined $contact->getRoles()
    and UNIVERSAL::isa($contact->getRoles, 'ARRAY')
    and scalar @{$contact->getRoles} == 0),
   'setRoles accepts empty array ref');


# test getRoles throws exception with argument
eval {$contact->getRoles(1)};
ok($@, 'getRoles throws exception with argument');

# test setRoles throws exception with no argument
eval {$contact->setRoles()};
ok($@, 'setRoles throws exception with no argument');

# test setRoles throws exception with too many argument
eval {$contact->setRoles(1,2)};
ok($@, 'setRoles throws exception with too many argument');

# test setRoles accepts undef
eval {$contact->setRoles(undef)};
ok((!$@ and not defined $contact->getRoles()),
   'setRoles accepts undef');

# test the meta-data for the assoication
$assn = $assns{roles};
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
   'roles->other() is a valid Bio::MAGE::Association::End'
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
   'roles->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($contact->getDescriptions,'ARRAY')
 and scalar @{$contact->getDescriptions} == 1
 and UNIVERSAL::isa($contact->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($contact->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($contact->getDescriptions,'ARRAY')
 and scalar @{$contact->getDescriptions} == 1
 and $contact->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($contact->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($contact->getDescriptions,'ARRAY')
 and scalar @{$contact->getDescriptions} == 2
 and $contact->getDescriptions->[0] == $descriptions_assn
 and $contact->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$contact->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$contact->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$contact->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$contact->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$contact->setDescriptions([])};
ok((!$@ and defined $contact->getDescriptions()
    and UNIVERSAL::isa($contact->getDescriptions, 'ARRAY')
    and scalar @{$contact->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$contact->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$contact->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$contact->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$contact->setDescriptions(undef)};
ok((!$@ and not defined $contact->getDescriptions()),
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


isa_ok($contact->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($contact->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($contact->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$contact->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$contact->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$contact->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$contact->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$contact->setSecurity(undef)};
ok((!$@ and not defined $contact->getSecurity()),
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


ok((UNIVERSAL::isa($contact->getAuditTrail,'ARRAY')
 and scalar @{$contact->getAuditTrail} == 1
 and UNIVERSAL::isa($contact->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($contact->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($contact->getAuditTrail,'ARRAY')
 and scalar @{$contact->getAuditTrail} == 1
 and $contact->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($contact->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($contact->getAuditTrail,'ARRAY')
 and scalar @{$contact->getAuditTrail} == 2
 and $contact->getAuditTrail->[0] == $audittrail_assn
 and $contact->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$contact->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$contact->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$contact->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$contact->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$contact->setAuditTrail([])};
ok((!$@ and defined $contact->getAuditTrail()
    and UNIVERSAL::isa($contact->getAuditTrail, 'ARRAY')
    and scalar @{$contact->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$contact->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$contact->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$contact->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$contact->setAuditTrail(undef)};
ok((!$@ and not defined $contact->getAuditTrail()),
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


ok((UNIVERSAL::isa($contact->getPropertySets,'ARRAY')
 and scalar @{$contact->getPropertySets} == 1
 and UNIVERSAL::isa($contact->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($contact->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($contact->getPropertySets,'ARRAY')
 and scalar @{$contact->getPropertySets} == 1
 and $contact->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($contact->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($contact->getPropertySets,'ARRAY')
 and scalar @{$contact->getPropertySets} == 2
 and $contact->getPropertySets->[0] == $propertysets_assn
 and $contact->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$contact->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$contact->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$contact->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$contact->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$contact->setPropertySets([])};
ok((!$@ and defined $contact->getPropertySets()
    and UNIVERSAL::isa($contact->getPropertySets, 'ARRAY')
    and scalar @{$contact->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$contact->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$contact->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$contact->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$contact->setPropertySets(undef)};
ok((!$@ and not defined $contact->getPropertySets()),
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




# create a subclass
my $person = Bio::MAGE::AuditAndSecurity::Person->new();

# testing subclass Person
isa_ok($person, q[Bio::MAGE::AuditAndSecurity::Person]);
isa_ok($person, q[Bio::MAGE::AuditAndSecurity::Contact]);


# create a subclass
my $organization = Bio::MAGE::AuditAndSecurity::Organization->new();

# testing subclass Organization
isa_ok($organization, q[Bio::MAGE::AuditAndSecurity::Organization]);
isa_ok($organization, q[Bio::MAGE::AuditAndSecurity::Contact]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($contact, q[Bio::MAGE::Identifiable]);

