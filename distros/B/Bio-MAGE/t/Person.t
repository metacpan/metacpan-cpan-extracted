##############################
#
# Person.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Person.t`

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
use Test::More tests => 174;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::Person') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::AuditAndSecurity::Organization;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $person;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $person = Bio::MAGE::AuditAndSecurity::Person->new();
}
isa_ok($person, 'Bio::MAGE::AuditAndSecurity::Person');

# test the package_name class method
is($person->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($person->class_name(), q[Bio::MAGE::AuditAndSecurity::Person],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $person = Bio::MAGE::AuditAndSecurity::Person->new(firstName => '1',
URI => '2',
name => '3',
midInitials => '4',
phone => '5',
email => '6',
identifier => '7',
tollFreePhone => '8',
fax => '9',
lastName => '10',
address => '11');
}


#
# testing attribute firstName
#

# test attribute values can be set in new()
is($person->getFirstName(), '1',
  'firstName new');

# test getter/setter
$person->setFirstName('1');
is($person->getFirstName(), '1',
  'firstName getter/setter');

# test getter throws exception with argument
eval {$person->getFirstName(1)};
ok($@, 'firstName getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setFirstName()};
ok($@, 'firstName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setFirstName('1', '1')};
ok($@, 'firstName setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setFirstName(undef)};
ok((!$@ and not defined $person->getFirstName()),
   'firstName setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($person->getURI(), '2',
  'URI new');

# test getter/setter
$person->setURI('2');
is($person->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$person->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setURI(undef)};
ok((!$@ and not defined $person->getURI()),
   'URI setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($person->getName(), '3',
  'name new');

# test getter/setter
$person->setName('3');
is($person->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$person->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setName(undef)};
ok((!$@ and not defined $person->getName()),
   'name setter accepts undef');



#
# testing attribute midInitials
#

# test attribute values can be set in new()
is($person->getMidInitials(), '4',
  'midInitials new');

# test getter/setter
$person->setMidInitials('4');
is($person->getMidInitials(), '4',
  'midInitials getter/setter');

# test getter throws exception with argument
eval {$person->getMidInitials(1)};
ok($@, 'midInitials getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setMidInitials()};
ok($@, 'midInitials setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setMidInitials('4', '4')};
ok($@, 'midInitials setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setMidInitials(undef)};
ok((!$@ and not defined $person->getMidInitials()),
   'midInitials setter accepts undef');



#
# testing attribute phone
#

# test attribute values can be set in new()
is($person->getPhone(), '5',
  'phone new');

# test getter/setter
$person->setPhone('5');
is($person->getPhone(), '5',
  'phone getter/setter');

# test getter throws exception with argument
eval {$person->getPhone(1)};
ok($@, 'phone getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setPhone()};
ok($@, 'phone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setPhone('5', '5')};
ok($@, 'phone setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setPhone(undef)};
ok((!$@ and not defined $person->getPhone()),
   'phone setter accepts undef');



#
# testing attribute email
#

# test attribute values can be set in new()
is($person->getEmail(), '6',
  'email new');

# test getter/setter
$person->setEmail('6');
is($person->getEmail(), '6',
  'email getter/setter');

# test getter throws exception with argument
eval {$person->getEmail(1)};
ok($@, 'email getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setEmail()};
ok($@, 'email setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setEmail('6', '6')};
ok($@, 'email setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setEmail(undef)};
ok((!$@ and not defined $person->getEmail()),
   'email setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($person->getIdentifier(), '7',
  'identifier new');

# test getter/setter
$person->setIdentifier('7');
is($person->getIdentifier(), '7',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$person->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setIdentifier('7', '7')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setIdentifier(undef)};
ok((!$@ and not defined $person->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute tollFreePhone
#

# test attribute values can be set in new()
is($person->getTollFreePhone(), '8',
  'tollFreePhone new');

# test getter/setter
$person->setTollFreePhone('8');
is($person->getTollFreePhone(), '8',
  'tollFreePhone getter/setter');

# test getter throws exception with argument
eval {$person->getTollFreePhone(1)};
ok($@, 'tollFreePhone getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setTollFreePhone()};
ok($@, 'tollFreePhone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setTollFreePhone('8', '8')};
ok($@, 'tollFreePhone setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setTollFreePhone(undef)};
ok((!$@ and not defined $person->getTollFreePhone()),
   'tollFreePhone setter accepts undef');



#
# testing attribute fax
#

# test attribute values can be set in new()
is($person->getFax(), '9',
  'fax new');

# test getter/setter
$person->setFax('9');
is($person->getFax(), '9',
  'fax getter/setter');

# test getter throws exception with argument
eval {$person->getFax(1)};
ok($@, 'fax getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setFax()};
ok($@, 'fax setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setFax('9', '9')};
ok($@, 'fax setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setFax(undef)};
ok((!$@ and not defined $person->getFax()),
   'fax setter accepts undef');



#
# testing attribute lastName
#

# test attribute values can be set in new()
is($person->getLastName(), '10',
  'lastName new');

# test getter/setter
$person->setLastName('10');
is($person->getLastName(), '10',
  'lastName getter/setter');

# test getter throws exception with argument
eval {$person->getLastName(1)};
ok($@, 'lastName getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setLastName()};
ok($@, 'lastName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setLastName('10', '10')};
ok($@, 'lastName setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setLastName(undef)};
ok((!$@ and not defined $person->getLastName()),
   'lastName setter accepts undef');



#
# testing attribute address
#

# test attribute values can be set in new()
is($person->getAddress(), '11',
  'address new');

# test getter/setter
$person->setAddress('11');
is($person->getAddress(), '11',
  'address getter/setter');

# test getter throws exception with argument
eval {$person->getAddress(1)};
ok($@, 'address getter throws exception with argument');

# test setter throws exception with no argument
eval {$person->setAddress()};
ok($@, 'address setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$person->setAddress('11', '11')};
ok($@, 'address setter throws exception with too many argument');

# test setter accepts undef
eval {$person->setAddress(undef)};
ok((!$@ and not defined $person->getAddress()),
   'address setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::Person->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $person = Bio::MAGE::AuditAndSecurity::Person->new(roles => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
affiliation => Bio::MAGE::AuditAndSecurity::Organization->new(),
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


ok((UNIVERSAL::isa($person->getRoles,'ARRAY')
 and scalar @{$person->getRoles} == 1
 and UNIVERSAL::isa($person->getRoles->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'roles set in new()');

ok(eq_array($person->setRoles([$roles_assn]), [$roles_assn]),
   'setRoles returns correct value');

ok((UNIVERSAL::isa($person->getRoles,'ARRAY')
 and scalar @{$person->getRoles} == 1
 and $person->getRoles->[0] == $roles_assn),
   'getRoles fetches correct value');

is($person->addRoles($roles_assn), 2,
  'addRoles returns number of items in list');

ok((UNIVERSAL::isa($person->getRoles,'ARRAY')
 and scalar @{$person->getRoles} == 2
 and $person->getRoles->[0] == $roles_assn
 and $person->getRoles->[1] == $roles_assn),
  'addRoles adds correct value');

# test setRoles throws exception with non-array argument
eval {$person->setRoles(1)};
ok($@, 'setRoles throws exception with non-array argument');

# test setRoles throws exception with bad argument array
eval {$person->setRoles([1])};
ok($@, 'setRoles throws exception with bad argument array');

# test addRoles throws exception with no arguments
eval {$person->addRoles()};
ok($@, 'addRoles throws exception with no arguments');

# test addRoles throws exception with bad argument
eval {$person->addRoles(1)};
ok($@, 'addRoles throws exception with bad array');

# test setRoles accepts empty array ref
eval {$person->setRoles([])};
ok((!$@ and defined $person->getRoles()
    and UNIVERSAL::isa($person->getRoles, 'ARRAY')
    and scalar @{$person->getRoles} == 0),
   'setRoles accepts empty array ref');


# test getRoles throws exception with argument
eval {$person->getRoles(1)};
ok($@, 'getRoles throws exception with argument');

# test setRoles throws exception with no argument
eval {$person->setRoles()};
ok($@, 'setRoles throws exception with no argument');

# test setRoles throws exception with too many argument
eval {$person->setRoles(1,2)};
ok($@, 'setRoles throws exception with too many argument');

# test setRoles accepts undef
eval {$person->setRoles(undef)};
ok((!$@ and not defined $person->getRoles()),
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


ok((UNIVERSAL::isa($person->getDescriptions,'ARRAY')
 and scalar @{$person->getDescriptions} == 1
 and UNIVERSAL::isa($person->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($person->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($person->getDescriptions,'ARRAY')
 and scalar @{$person->getDescriptions} == 1
 and $person->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($person->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($person->getDescriptions,'ARRAY')
 and scalar @{$person->getDescriptions} == 2
 and $person->getDescriptions->[0] == $descriptions_assn
 and $person->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$person->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$person->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$person->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$person->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$person->setDescriptions([])};
ok((!$@ and defined $person->getDescriptions()
    and UNIVERSAL::isa($person->getDescriptions, 'ARRAY')
    and scalar @{$person->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$person->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$person->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$person->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$person->setDescriptions(undef)};
ok((!$@ and not defined $person->getDescriptions()),
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



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($person->getAuditTrail,'ARRAY')
 and scalar @{$person->getAuditTrail} == 1
 and UNIVERSAL::isa($person->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($person->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($person->getAuditTrail,'ARRAY')
 and scalar @{$person->getAuditTrail} == 1
 and $person->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($person->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($person->getAuditTrail,'ARRAY')
 and scalar @{$person->getAuditTrail} == 2
 and $person->getAuditTrail->[0] == $audittrail_assn
 and $person->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$person->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$person->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$person->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$person->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$person->setAuditTrail([])};
ok((!$@ and defined $person->getAuditTrail()
    and UNIVERSAL::isa($person->getAuditTrail, 'ARRAY')
    and scalar @{$person->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$person->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$person->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$person->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$person->setAuditTrail(undef)};
ok((!$@ and not defined $person->getAuditTrail()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($person->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($person->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($person->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$person->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$person->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$person->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$person->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$person->setSecurity(undef)};
ok((!$@ and not defined $person->getSecurity()),
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



# testing association affiliation
my $affiliation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $affiliation_assn = Bio::MAGE::AuditAndSecurity::Organization->new();
}


isa_ok($person->getAffiliation, q[Bio::MAGE::AuditAndSecurity::Organization]);

is($person->setAffiliation($affiliation_assn), $affiliation_assn,
  'setAffiliation returns value');

ok($person->getAffiliation() == $affiliation_assn,
   'getAffiliation fetches correct value');

# test setAffiliation throws exception with bad argument
eval {$person->setAffiliation(1)};
ok($@, 'setAffiliation throws exception with bad argument');


# test getAffiliation throws exception with argument
eval {$person->getAffiliation(1)};
ok($@, 'getAffiliation throws exception with argument');

# test setAffiliation throws exception with no argument
eval {$person->setAffiliation()};
ok($@, 'setAffiliation throws exception with no argument');

# test setAffiliation throws exception with too many argument
eval {$person->setAffiliation(1,2)};
ok($@, 'setAffiliation throws exception with too many argument');

# test setAffiliation accepts undef
eval {$person->setAffiliation(undef)};
ok((!$@ and not defined $person->getAffiliation()),
   'setAffiliation accepts undef');

# test the meta-data for the assoication
$assn = $assns{affiliation};
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
   'affiliation->other() is a valid Bio::MAGE::Association::End'
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
   'affiliation->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($person->getPropertySets,'ARRAY')
 and scalar @{$person->getPropertySets} == 1
 and UNIVERSAL::isa($person->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($person->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($person->getPropertySets,'ARRAY')
 and scalar @{$person->getPropertySets} == 1
 and $person->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($person->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($person->getPropertySets,'ARRAY')
 and scalar @{$person->getPropertySets} == 2
 and $person->getPropertySets->[0] == $propertysets_assn
 and $person->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$person->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$person->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$person->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$person->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$person->setPropertySets([])};
ok((!$@ and defined $person->getPropertySets()
    and UNIVERSAL::isa($person->getPropertySets, 'ARRAY')
    and scalar @{$person->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$person->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$person->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$person->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$person->setPropertySets(undef)};
ok((!$@ and not defined $person->getPropertySets()),
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





my $contact;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $contact = Bio::MAGE::AuditAndSecurity::Contact->new();
}

# testing superclass Contact
isa_ok($contact, q[Bio::MAGE::AuditAndSecurity::Contact]);
isa_ok($person, q[Bio::MAGE::AuditAndSecurity::Contact]);

