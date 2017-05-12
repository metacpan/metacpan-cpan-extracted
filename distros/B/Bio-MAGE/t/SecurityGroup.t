##############################
#
# SecurityGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SecurityGroup.t`

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
use Test::More tests => 107;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::SecurityGroup') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;


# we test the new() method
my $securitygroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $securitygroup = Bio::MAGE::AuditAndSecurity::SecurityGroup->new();
}
isa_ok($securitygroup, 'Bio::MAGE::AuditAndSecurity::SecurityGroup');

# test the package_name class method
is($securitygroup->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($securitygroup->class_name(), q[Bio::MAGE::AuditAndSecurity::SecurityGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $securitygroup = Bio::MAGE::AuditAndSecurity::SecurityGroup->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($securitygroup->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$securitygroup->setIdentifier('1');
is($securitygroup->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$securitygroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$securitygroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$securitygroup->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$securitygroup->setIdentifier(undef)};
ok((!$@ and not defined $securitygroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($securitygroup->getName(), '2',
  'name new');

# test getter/setter
$securitygroup->setName('2');
is($securitygroup->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$securitygroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$securitygroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$securitygroup->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$securitygroup->setName(undef)};
ok((!$@ and not defined $securitygroup->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::SecurityGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $securitygroup = Bio::MAGE::AuditAndSecurity::SecurityGroup->new(members => [Bio::MAGE::AuditAndSecurity::Contact->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association members
my $members_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $members_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($securitygroup->getMembers,'ARRAY')
 and scalar @{$securitygroup->getMembers} == 1
 and UNIVERSAL::isa($securitygroup->getMembers->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'members set in new()');

ok(eq_array($securitygroup->setMembers([$members_assn]), [$members_assn]),
   'setMembers returns correct value');

ok((UNIVERSAL::isa($securitygroup->getMembers,'ARRAY')
 and scalar @{$securitygroup->getMembers} == 1
 and $securitygroup->getMembers->[0] == $members_assn),
   'getMembers fetches correct value');

is($securitygroup->addMembers($members_assn), 2,
  'addMembers returns number of items in list');

ok((UNIVERSAL::isa($securitygroup->getMembers,'ARRAY')
 and scalar @{$securitygroup->getMembers} == 2
 and $securitygroup->getMembers->[0] == $members_assn
 and $securitygroup->getMembers->[1] == $members_assn),
  'addMembers adds correct value');

# test setMembers throws exception with non-array argument
eval {$securitygroup->setMembers(1)};
ok($@, 'setMembers throws exception with non-array argument');

# test setMembers throws exception with bad argument array
eval {$securitygroup->setMembers([1])};
ok($@, 'setMembers throws exception with bad argument array');

# test addMembers throws exception with no arguments
eval {$securitygroup->addMembers()};
ok($@, 'addMembers throws exception with no arguments');

# test addMembers throws exception with bad argument
eval {$securitygroup->addMembers(1)};
ok($@, 'addMembers throws exception with bad array');

# test setMembers accepts empty array ref
eval {$securitygroup->setMembers([])};
ok((!$@ and defined $securitygroup->getMembers()
    and UNIVERSAL::isa($securitygroup->getMembers, 'ARRAY')
    and scalar @{$securitygroup->getMembers} == 0),
   'setMembers accepts empty array ref');


# test getMembers throws exception with argument
eval {$securitygroup->getMembers(1)};
ok($@, 'getMembers throws exception with argument');

# test setMembers throws exception with no argument
eval {$securitygroup->setMembers()};
ok($@, 'setMembers throws exception with no argument');

# test setMembers throws exception with too many argument
eval {$securitygroup->setMembers(1,2)};
ok($@, 'setMembers throws exception with too many argument');

# test setMembers accepts undef
eval {$securitygroup->setMembers(undef)};
ok((!$@ and not defined $securitygroup->getMembers()),
   'setMembers accepts undef');

# test the meta-data for the assoication
$assn = $assns{members};
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
   'members->other() is a valid Bio::MAGE::Association::End'
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
   'members->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($securitygroup->getDescriptions,'ARRAY')
 and scalar @{$securitygroup->getDescriptions} == 1
 and UNIVERSAL::isa($securitygroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($securitygroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($securitygroup->getDescriptions,'ARRAY')
 and scalar @{$securitygroup->getDescriptions} == 1
 and $securitygroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($securitygroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($securitygroup->getDescriptions,'ARRAY')
 and scalar @{$securitygroup->getDescriptions} == 2
 and $securitygroup->getDescriptions->[0] == $descriptions_assn
 and $securitygroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$securitygroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$securitygroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$securitygroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$securitygroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$securitygroup->setDescriptions([])};
ok((!$@ and defined $securitygroup->getDescriptions()
    and UNIVERSAL::isa($securitygroup->getDescriptions, 'ARRAY')
    and scalar @{$securitygroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$securitygroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$securitygroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$securitygroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$securitygroup->setDescriptions(undef)};
ok((!$@ and not defined $securitygroup->getDescriptions()),
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


isa_ok($securitygroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($securitygroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($securitygroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$securitygroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$securitygroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$securitygroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$securitygroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$securitygroup->setSecurity(undef)};
ok((!$@ and not defined $securitygroup->getSecurity()),
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


ok((UNIVERSAL::isa($securitygroup->getAuditTrail,'ARRAY')
 and scalar @{$securitygroup->getAuditTrail} == 1
 and UNIVERSAL::isa($securitygroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($securitygroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($securitygroup->getAuditTrail,'ARRAY')
 and scalar @{$securitygroup->getAuditTrail} == 1
 and $securitygroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($securitygroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($securitygroup->getAuditTrail,'ARRAY')
 and scalar @{$securitygroup->getAuditTrail} == 2
 and $securitygroup->getAuditTrail->[0] == $audittrail_assn
 and $securitygroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$securitygroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$securitygroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$securitygroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$securitygroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$securitygroup->setAuditTrail([])};
ok((!$@ and defined $securitygroup->getAuditTrail()
    and UNIVERSAL::isa($securitygroup->getAuditTrail, 'ARRAY')
    and scalar @{$securitygroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$securitygroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$securitygroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$securitygroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$securitygroup->setAuditTrail(undef)};
ok((!$@ and not defined $securitygroup->getAuditTrail()),
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


ok((UNIVERSAL::isa($securitygroup->getPropertySets,'ARRAY')
 and scalar @{$securitygroup->getPropertySets} == 1
 and UNIVERSAL::isa($securitygroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($securitygroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($securitygroup->getPropertySets,'ARRAY')
 and scalar @{$securitygroup->getPropertySets} == 1
 and $securitygroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($securitygroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($securitygroup->getPropertySets,'ARRAY')
 and scalar @{$securitygroup->getPropertySets} == 2
 and $securitygroup->getPropertySets->[0] == $propertysets_assn
 and $securitygroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$securitygroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$securitygroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$securitygroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$securitygroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$securitygroup->setPropertySets([])};
ok((!$@ and defined $securitygroup->getPropertySets()
    and UNIVERSAL::isa($securitygroup->getPropertySets, 'ARRAY')
    and scalar @{$securitygroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$securitygroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$securitygroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$securitygroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$securitygroup->setPropertySets(undef)};
ok((!$@ and not defined $securitygroup->getPropertySets()),
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
isa_ok($securitygroup, q[Bio::MAGE::Identifiable]);

