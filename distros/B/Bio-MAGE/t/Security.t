##############################
#
# Security.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Security.t`

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
use Test::More tests => 126;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::Security') };

use Bio::MAGE::AuditAndSecurity::SecurityGroup;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;


# we test the new() method
my $security;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security = Bio::MAGE::AuditAndSecurity::Security->new();
}
isa_ok($security, 'Bio::MAGE::AuditAndSecurity::Security');

# test the package_name class method
is($security->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($security->class_name(), q[Bio::MAGE::AuditAndSecurity::Security],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security = Bio::MAGE::AuditAndSecurity::Security->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($security->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$security->setIdentifier('1');
is($security->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$security->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$security->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$security->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$security->setIdentifier(undef)};
ok((!$@ and not defined $security->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($security->getName(), '2',
  'name new');

# test getter/setter
$security->setName('2');
is($security->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$security->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$security->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$security->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$security->setName(undef)};
ok((!$@ and not defined $security->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::Security->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security = Bio::MAGE::AuditAndSecurity::Security->new(owner => [Bio::MAGE::AuditAndSecurity::Contact->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
securityGroups => [Bio::MAGE::AuditAndSecurity::SecurityGroup->new()]);
}

my ($end, $assn);


# testing association owner
my $owner_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $owner_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($security->getOwner,'ARRAY')
 and scalar @{$security->getOwner} == 1
 and UNIVERSAL::isa($security->getOwner->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'owner set in new()');

ok(eq_array($security->setOwner([$owner_assn]), [$owner_assn]),
   'setOwner returns correct value');

ok((UNIVERSAL::isa($security->getOwner,'ARRAY')
 and scalar @{$security->getOwner} == 1
 and $security->getOwner->[0] == $owner_assn),
   'getOwner fetches correct value');

is($security->addOwner($owner_assn), 2,
  'addOwner returns number of items in list');

ok((UNIVERSAL::isa($security->getOwner,'ARRAY')
 and scalar @{$security->getOwner} == 2
 and $security->getOwner->[0] == $owner_assn
 and $security->getOwner->[1] == $owner_assn),
  'addOwner adds correct value');

# test setOwner throws exception with non-array argument
eval {$security->setOwner(1)};
ok($@, 'setOwner throws exception with non-array argument');

# test setOwner throws exception with bad argument array
eval {$security->setOwner([1])};
ok($@, 'setOwner throws exception with bad argument array');

# test addOwner throws exception with no arguments
eval {$security->addOwner()};
ok($@, 'addOwner throws exception with no arguments');

# test addOwner throws exception with bad argument
eval {$security->addOwner(1)};
ok($@, 'addOwner throws exception with bad array');

# test setOwner accepts empty array ref
eval {$security->setOwner([])};
ok((!$@ and defined $security->getOwner()
    and UNIVERSAL::isa($security->getOwner, 'ARRAY')
    and scalar @{$security->getOwner} == 0),
   'setOwner accepts empty array ref');


# test getOwner throws exception with argument
eval {$security->getOwner(1)};
ok($@, 'getOwner throws exception with argument');

# test setOwner throws exception with no argument
eval {$security->setOwner()};
ok($@, 'setOwner throws exception with no argument');

# test setOwner throws exception with too many argument
eval {$security->setOwner(1,2)};
ok($@, 'setOwner throws exception with too many argument');

# test setOwner accepts undef
eval {$security->setOwner(undef)};
ok((!$@ and not defined $security->getOwner()),
   'setOwner accepts undef');

# test the meta-data for the assoication
$assn = $assns{owner};
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
   'owner->other() is a valid Bio::MAGE::Association::End'
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
   'owner->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($security->getDescriptions,'ARRAY')
 and scalar @{$security->getDescriptions} == 1
 and UNIVERSAL::isa($security->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($security->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($security->getDescriptions,'ARRAY')
 and scalar @{$security->getDescriptions} == 1
 and $security->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($security->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($security->getDescriptions,'ARRAY')
 and scalar @{$security->getDescriptions} == 2
 and $security->getDescriptions->[0] == $descriptions_assn
 and $security->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$security->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$security->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$security->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$security->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$security->setDescriptions([])};
ok((!$@ and defined $security->getDescriptions()
    and UNIVERSAL::isa($security->getDescriptions, 'ARRAY')
    and scalar @{$security->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$security->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$security->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$security->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$security->setDescriptions(undef)};
ok((!$@ and not defined $security->getDescriptions()),
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


isa_ok($security->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($security->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($security->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$security->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$security->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$security->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$security->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$security->setSecurity(undef)};
ok((!$@ and not defined $security->getSecurity()),
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


ok((UNIVERSAL::isa($security->getAuditTrail,'ARRAY')
 and scalar @{$security->getAuditTrail} == 1
 and UNIVERSAL::isa($security->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($security->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($security->getAuditTrail,'ARRAY')
 and scalar @{$security->getAuditTrail} == 1
 and $security->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($security->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($security->getAuditTrail,'ARRAY')
 and scalar @{$security->getAuditTrail} == 2
 and $security->getAuditTrail->[0] == $audittrail_assn
 and $security->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$security->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$security->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$security->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$security->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$security->setAuditTrail([])};
ok((!$@ and defined $security->getAuditTrail()
    and UNIVERSAL::isa($security->getAuditTrail, 'ARRAY')
    and scalar @{$security->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$security->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$security->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$security->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$security->setAuditTrail(undef)};
ok((!$@ and not defined $security->getAuditTrail()),
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


ok((UNIVERSAL::isa($security->getPropertySets,'ARRAY')
 and scalar @{$security->getPropertySets} == 1
 and UNIVERSAL::isa($security->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($security->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($security->getPropertySets,'ARRAY')
 and scalar @{$security->getPropertySets} == 1
 and $security->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($security->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($security->getPropertySets,'ARRAY')
 and scalar @{$security->getPropertySets} == 2
 and $security->getPropertySets->[0] == $propertysets_assn
 and $security->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$security->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$security->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$security->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$security->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$security->setPropertySets([])};
ok((!$@ and defined $security->getPropertySets()
    and UNIVERSAL::isa($security->getPropertySets, 'ARRAY')
    and scalar @{$security->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$security->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$security->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$security->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$security->setPropertySets(undef)};
ok((!$@ and not defined $security->getPropertySets()),
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



# testing association securityGroups
my $securitygroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $securitygroups_assn = Bio::MAGE::AuditAndSecurity::SecurityGroup->new();
}


ok((UNIVERSAL::isa($security->getSecurityGroups,'ARRAY')
 and scalar @{$security->getSecurityGroups} == 1
 and UNIVERSAL::isa($security->getSecurityGroups->[0], q[Bio::MAGE::AuditAndSecurity::SecurityGroup])),
  'securityGroups set in new()');

ok(eq_array($security->setSecurityGroups([$securitygroups_assn]), [$securitygroups_assn]),
   'setSecurityGroups returns correct value');

ok((UNIVERSAL::isa($security->getSecurityGroups,'ARRAY')
 and scalar @{$security->getSecurityGroups} == 1
 and $security->getSecurityGroups->[0] == $securitygroups_assn),
   'getSecurityGroups fetches correct value');

is($security->addSecurityGroups($securitygroups_assn), 2,
  'addSecurityGroups returns number of items in list');

ok((UNIVERSAL::isa($security->getSecurityGroups,'ARRAY')
 and scalar @{$security->getSecurityGroups} == 2
 and $security->getSecurityGroups->[0] == $securitygroups_assn
 and $security->getSecurityGroups->[1] == $securitygroups_assn),
  'addSecurityGroups adds correct value');

# test setSecurityGroups throws exception with non-array argument
eval {$security->setSecurityGroups(1)};
ok($@, 'setSecurityGroups throws exception with non-array argument');

# test setSecurityGroups throws exception with bad argument array
eval {$security->setSecurityGroups([1])};
ok($@, 'setSecurityGroups throws exception with bad argument array');

# test addSecurityGroups throws exception with no arguments
eval {$security->addSecurityGroups()};
ok($@, 'addSecurityGroups throws exception with no arguments');

# test addSecurityGroups throws exception with bad argument
eval {$security->addSecurityGroups(1)};
ok($@, 'addSecurityGroups throws exception with bad array');

# test setSecurityGroups accepts empty array ref
eval {$security->setSecurityGroups([])};
ok((!$@ and defined $security->getSecurityGroups()
    and UNIVERSAL::isa($security->getSecurityGroups, 'ARRAY')
    and scalar @{$security->getSecurityGroups} == 0),
   'setSecurityGroups accepts empty array ref');


# test getSecurityGroups throws exception with argument
eval {$security->getSecurityGroups(1)};
ok($@, 'getSecurityGroups throws exception with argument');

# test setSecurityGroups throws exception with no argument
eval {$security->setSecurityGroups()};
ok($@, 'setSecurityGroups throws exception with no argument');

# test setSecurityGroups throws exception with too many argument
eval {$security->setSecurityGroups(1,2)};
ok($@, 'setSecurityGroups throws exception with too many argument');

# test setSecurityGroups accepts undef
eval {$security->setSecurityGroups(undef)};
ok((!$@ and not defined $security->getSecurityGroups()),
   'setSecurityGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{securityGroups};
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
   'securityGroups->other() is a valid Bio::MAGE::Association::End'
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
   'securityGroups->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($security, q[Bio::MAGE::Identifiable]);

