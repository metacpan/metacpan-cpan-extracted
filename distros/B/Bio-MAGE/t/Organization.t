##############################
#
# Organization.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Organization.t`

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
use Test::More tests => 156;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::Organization') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::AuditAndSecurity::Organization;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $organization;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $organization = Bio::MAGE::AuditAndSecurity::Organization->new();
}
isa_ok($organization, 'Bio::MAGE::AuditAndSecurity::Organization');

# test the package_name class method
is($organization->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($organization->class_name(), q[Bio::MAGE::AuditAndSecurity::Organization],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $organization = Bio::MAGE::AuditAndSecurity::Organization->new(email => '1',
identifier => '2',
URI => '3',
fax => '4',
tollFreePhone => '5',
name => '6',
address => '7',
phone => '8');
}


#
# testing attribute email
#

# test attribute values can be set in new()
is($organization->getEmail(), '1',
  'email new');

# test getter/setter
$organization->setEmail('1');
is($organization->getEmail(), '1',
  'email getter/setter');

# test getter throws exception with argument
eval {$organization->getEmail(1)};
ok($@, 'email getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setEmail()};
ok($@, 'email setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setEmail('1', '1')};
ok($@, 'email setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setEmail(undef)};
ok((!$@ and not defined $organization->getEmail()),
   'email setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($organization->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$organization->setIdentifier('2');
is($organization->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$organization->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setIdentifier(undef)};
ok((!$@ and not defined $organization->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($organization->getURI(), '3',
  'URI new');

# test getter/setter
$organization->setURI('3');
is($organization->getURI(), '3',
  'URI getter/setter');

# test getter throws exception with argument
eval {$organization->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setURI('3', '3')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setURI(undef)};
ok((!$@ and not defined $organization->getURI()),
   'URI setter accepts undef');



#
# testing attribute fax
#

# test attribute values can be set in new()
is($organization->getFax(), '4',
  'fax new');

# test getter/setter
$organization->setFax('4');
is($organization->getFax(), '4',
  'fax getter/setter');

# test getter throws exception with argument
eval {$organization->getFax(1)};
ok($@, 'fax getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setFax()};
ok($@, 'fax setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setFax('4', '4')};
ok($@, 'fax setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setFax(undef)};
ok((!$@ and not defined $organization->getFax()),
   'fax setter accepts undef');



#
# testing attribute tollFreePhone
#

# test attribute values can be set in new()
is($organization->getTollFreePhone(), '5',
  'tollFreePhone new');

# test getter/setter
$organization->setTollFreePhone('5');
is($organization->getTollFreePhone(), '5',
  'tollFreePhone getter/setter');

# test getter throws exception with argument
eval {$organization->getTollFreePhone(1)};
ok($@, 'tollFreePhone getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setTollFreePhone()};
ok($@, 'tollFreePhone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setTollFreePhone('5', '5')};
ok($@, 'tollFreePhone setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setTollFreePhone(undef)};
ok((!$@ and not defined $organization->getTollFreePhone()),
   'tollFreePhone setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($organization->getName(), '6',
  'name new');

# test getter/setter
$organization->setName('6');
is($organization->getName(), '6',
  'name getter/setter');

# test getter throws exception with argument
eval {$organization->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setName('6', '6')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setName(undef)};
ok((!$@ and not defined $organization->getName()),
   'name setter accepts undef');



#
# testing attribute address
#

# test attribute values can be set in new()
is($organization->getAddress(), '7',
  'address new');

# test getter/setter
$organization->setAddress('7');
is($organization->getAddress(), '7',
  'address getter/setter');

# test getter throws exception with argument
eval {$organization->getAddress(1)};
ok($@, 'address getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setAddress()};
ok($@, 'address setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setAddress('7', '7')};
ok($@, 'address setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setAddress(undef)};
ok((!$@ and not defined $organization->getAddress()),
   'address setter accepts undef');



#
# testing attribute phone
#

# test attribute values can be set in new()
is($organization->getPhone(), '8',
  'phone new');

# test getter/setter
$organization->setPhone('8');
is($organization->getPhone(), '8',
  'phone getter/setter');

# test getter throws exception with argument
eval {$organization->getPhone(1)};
ok($@, 'phone getter throws exception with argument');

# test setter throws exception with no argument
eval {$organization->setPhone()};
ok($@, 'phone setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$organization->setPhone('8', '8')};
ok($@, 'phone setter throws exception with too many argument');

# test setter accepts undef
eval {$organization->setPhone(undef)};
ok((!$@ and not defined $organization->getPhone()),
   'phone setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::Organization->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $organization = Bio::MAGE::AuditAndSecurity::Organization->new(roles => [Bio::MAGE::Description::OntologyEntry->new()],
parent => Bio::MAGE::AuditAndSecurity::Organization->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
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


ok((UNIVERSAL::isa($organization->getRoles,'ARRAY')
 and scalar @{$organization->getRoles} == 1
 and UNIVERSAL::isa($organization->getRoles->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'roles set in new()');

ok(eq_array($organization->setRoles([$roles_assn]), [$roles_assn]),
   'setRoles returns correct value');

ok((UNIVERSAL::isa($organization->getRoles,'ARRAY')
 and scalar @{$organization->getRoles} == 1
 and $organization->getRoles->[0] == $roles_assn),
   'getRoles fetches correct value');

is($organization->addRoles($roles_assn), 2,
  'addRoles returns number of items in list');

ok((UNIVERSAL::isa($organization->getRoles,'ARRAY')
 and scalar @{$organization->getRoles} == 2
 and $organization->getRoles->[0] == $roles_assn
 and $organization->getRoles->[1] == $roles_assn),
  'addRoles adds correct value');

# test setRoles throws exception with non-array argument
eval {$organization->setRoles(1)};
ok($@, 'setRoles throws exception with non-array argument');

# test setRoles throws exception with bad argument array
eval {$organization->setRoles([1])};
ok($@, 'setRoles throws exception with bad argument array');

# test addRoles throws exception with no arguments
eval {$organization->addRoles()};
ok($@, 'addRoles throws exception with no arguments');

# test addRoles throws exception with bad argument
eval {$organization->addRoles(1)};
ok($@, 'addRoles throws exception with bad array');

# test setRoles accepts empty array ref
eval {$organization->setRoles([])};
ok((!$@ and defined $organization->getRoles()
    and UNIVERSAL::isa($organization->getRoles, 'ARRAY')
    and scalar @{$organization->getRoles} == 0),
   'setRoles accepts empty array ref');


# test getRoles throws exception with argument
eval {$organization->getRoles(1)};
ok($@, 'getRoles throws exception with argument');

# test setRoles throws exception with no argument
eval {$organization->setRoles()};
ok($@, 'setRoles throws exception with no argument');

# test setRoles throws exception with too many argument
eval {$organization->setRoles(1,2)};
ok($@, 'setRoles throws exception with too many argument');

# test setRoles accepts undef
eval {$organization->setRoles(undef)};
ok((!$@ and not defined $organization->getRoles()),
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



# testing association parent
my $parent_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parent_assn = Bio::MAGE::AuditAndSecurity::Organization->new();
}


isa_ok($organization->getParent, q[Bio::MAGE::AuditAndSecurity::Organization]);

is($organization->setParent($parent_assn), $parent_assn,
  'setParent returns value');

ok($organization->getParent() == $parent_assn,
   'getParent fetches correct value');

# test setParent throws exception with bad argument
eval {$organization->setParent(1)};
ok($@, 'setParent throws exception with bad argument');


# test getParent throws exception with argument
eval {$organization->getParent(1)};
ok($@, 'getParent throws exception with argument');

# test setParent throws exception with no argument
eval {$organization->setParent()};
ok($@, 'setParent throws exception with no argument');

# test setParent throws exception with too many argument
eval {$organization->setParent(1,2)};
ok($@, 'setParent throws exception with too many argument');

# test setParent accepts undef
eval {$organization->setParent(undef)};
ok((!$@ and not defined $organization->getParent()),
   'setParent accepts undef');

# test the meta-data for the assoication
$assn = $assns{parent};
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
   'parent->other() is a valid Bio::MAGE::Association::End'
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
   'parent->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($organization->getDescriptions,'ARRAY')
 and scalar @{$organization->getDescriptions} == 1
 and UNIVERSAL::isa($organization->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($organization->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($organization->getDescriptions,'ARRAY')
 and scalar @{$organization->getDescriptions} == 1
 and $organization->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($organization->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($organization->getDescriptions,'ARRAY')
 and scalar @{$organization->getDescriptions} == 2
 and $organization->getDescriptions->[0] == $descriptions_assn
 and $organization->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$organization->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$organization->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$organization->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$organization->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$organization->setDescriptions([])};
ok((!$@ and defined $organization->getDescriptions()
    and UNIVERSAL::isa($organization->getDescriptions, 'ARRAY')
    and scalar @{$organization->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$organization->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$organization->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$organization->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$organization->setDescriptions(undef)};
ok((!$@ and not defined $organization->getDescriptions()),
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


ok((UNIVERSAL::isa($organization->getAuditTrail,'ARRAY')
 and scalar @{$organization->getAuditTrail} == 1
 and UNIVERSAL::isa($organization->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($organization->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($organization->getAuditTrail,'ARRAY')
 and scalar @{$organization->getAuditTrail} == 1
 and $organization->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($organization->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($organization->getAuditTrail,'ARRAY')
 and scalar @{$organization->getAuditTrail} == 2
 and $organization->getAuditTrail->[0] == $audittrail_assn
 and $organization->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$organization->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$organization->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$organization->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$organization->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$organization->setAuditTrail([])};
ok((!$@ and defined $organization->getAuditTrail()
    and UNIVERSAL::isa($organization->getAuditTrail, 'ARRAY')
    and scalar @{$organization->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$organization->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$organization->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$organization->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$organization->setAuditTrail(undef)};
ok((!$@ and not defined $organization->getAuditTrail()),
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


isa_ok($organization->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($organization->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($organization->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$organization->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$organization->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$organization->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$organization->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$organization->setSecurity(undef)};
ok((!$@ and not defined $organization->getSecurity()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($organization->getPropertySets,'ARRAY')
 and scalar @{$organization->getPropertySets} == 1
 and UNIVERSAL::isa($organization->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($organization->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($organization->getPropertySets,'ARRAY')
 and scalar @{$organization->getPropertySets} == 1
 and $organization->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($organization->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($organization->getPropertySets,'ARRAY')
 and scalar @{$organization->getPropertySets} == 2
 and $organization->getPropertySets->[0] == $propertysets_assn
 and $organization->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$organization->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$organization->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$organization->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$organization->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$organization->setPropertySets([])};
ok((!$@ and defined $organization->getPropertySets()
    and UNIVERSAL::isa($organization->getPropertySets, 'ARRAY')
    and scalar @{$organization->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$organization->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$organization->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$organization->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$organization->setPropertySets(undef)};
ok((!$@ and not defined $organization->getPropertySets()),
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
isa_ok($organization, q[Bio::MAGE::AuditAndSecurity::Contact]);

