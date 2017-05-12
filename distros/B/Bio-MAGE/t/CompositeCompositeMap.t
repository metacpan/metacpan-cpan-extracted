##############################
#
# CompositeCompositeMap.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompositeCompositeMap.t`

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
use Test::More tests => 139;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::CompositeCompositeMap') };

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::DesignElement::CompositePosition;
use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $compositecompositemap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositecompositemap = Bio::MAGE::DesignElement::CompositeCompositeMap->new();
}
isa_ok($compositecompositemap, 'Bio::MAGE::DesignElement::CompositeCompositeMap');

# test the package_name class method
is($compositecompositemap->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($compositecompositemap->class_name(), q[Bio::MAGE::DesignElement::CompositeCompositeMap],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositecompositemap = Bio::MAGE::DesignElement::CompositeCompositeMap->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($compositecompositemap->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$compositecompositemap->setIdentifier('1');
is($compositecompositemap->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$compositecompositemap->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositecompositemap->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositecompositemap->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$compositecompositemap->setIdentifier(undef)};
ok((!$@ and not defined $compositecompositemap->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($compositecompositemap->getName(), '2',
  'name new');

# test getter/setter
$compositecompositemap->setName('2');
is($compositecompositemap->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$compositecompositemap->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositecompositemap->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositecompositemap->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$compositecompositemap->setName(undef)};
ok((!$@ and not defined $compositecompositemap->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::CompositeCompositeMap->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositecompositemap = Bio::MAGE::DesignElement::CompositeCompositeMap->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
compositeSequence => Bio::MAGE::DesignElement::CompositeSequence->new(),
compositePositionSources => [Bio::MAGE::DesignElement::CompositePosition->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($compositecompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$compositecompositemap->getProtocolApplications} == 1
 and UNIVERSAL::isa($compositecompositemap->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($compositecompositemap->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($compositecompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$compositecompositemap->getProtocolApplications} == 1
 and $compositecompositemap->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($compositecompositemap->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($compositecompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$compositecompositemap->getProtocolApplications} == 2
 and $compositecompositemap->getProtocolApplications->[0] == $protocolapplications_assn
 and $compositecompositemap->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$compositecompositemap->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$compositecompositemap->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$compositecompositemap->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$compositecompositemap->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$compositecompositemap->setProtocolApplications([])};
ok((!$@ and defined $compositecompositemap->getProtocolApplications()
    and UNIVERSAL::isa($compositecompositemap->getProtocolApplications, 'ARRAY')
    and scalar @{$compositecompositemap->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$compositecompositemap->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$compositecompositemap->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$compositecompositemap->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$compositecompositemap->setProtocolApplications(undef)};
ok((!$@ and not defined $compositecompositemap->getProtocolApplications()),
   'setProtocolApplications accepts undef');

# test the meta-data for the assoication
$assn = $assns{protocolApplications};
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
   'protocolApplications->other() is a valid Bio::MAGE::Association::End'
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
   'protocolApplications->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($compositecompositemap->getDescriptions,'ARRAY')
 and scalar @{$compositecompositemap->getDescriptions} == 1
 and UNIVERSAL::isa($compositecompositemap->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($compositecompositemap->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($compositecompositemap->getDescriptions,'ARRAY')
 and scalar @{$compositecompositemap->getDescriptions} == 1
 and $compositecompositemap->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($compositecompositemap->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($compositecompositemap->getDescriptions,'ARRAY')
 and scalar @{$compositecompositemap->getDescriptions} == 2
 and $compositecompositemap->getDescriptions->[0] == $descriptions_assn
 and $compositecompositemap->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$compositecompositemap->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$compositecompositemap->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$compositecompositemap->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$compositecompositemap->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$compositecompositemap->setDescriptions([])};
ok((!$@ and defined $compositecompositemap->getDescriptions()
    and UNIVERSAL::isa($compositecompositemap->getDescriptions, 'ARRAY')
    and scalar @{$compositecompositemap->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$compositecompositemap->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$compositecompositemap->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$compositecompositemap->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$compositecompositemap->setDescriptions(undef)};
ok((!$@ and not defined $compositecompositemap->getDescriptions()),
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


ok((UNIVERSAL::isa($compositecompositemap->getAuditTrail,'ARRAY')
 and scalar @{$compositecompositemap->getAuditTrail} == 1
 and UNIVERSAL::isa($compositecompositemap->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($compositecompositemap->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($compositecompositemap->getAuditTrail,'ARRAY')
 and scalar @{$compositecompositemap->getAuditTrail} == 1
 and $compositecompositemap->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($compositecompositemap->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($compositecompositemap->getAuditTrail,'ARRAY')
 and scalar @{$compositecompositemap->getAuditTrail} == 2
 and $compositecompositemap->getAuditTrail->[0] == $audittrail_assn
 and $compositecompositemap->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$compositecompositemap->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$compositecompositemap->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$compositecompositemap->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$compositecompositemap->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$compositecompositemap->setAuditTrail([])};
ok((!$@ and defined $compositecompositemap->getAuditTrail()
    and UNIVERSAL::isa($compositecompositemap->getAuditTrail, 'ARRAY')
    and scalar @{$compositecompositemap->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$compositecompositemap->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$compositecompositemap->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$compositecompositemap->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$compositecompositemap->setAuditTrail(undef)};
ok((!$@ and not defined $compositecompositemap->getAuditTrail()),
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


isa_ok($compositecompositemap->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($compositecompositemap->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($compositecompositemap->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$compositecompositemap->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$compositecompositemap->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$compositecompositemap->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$compositecompositemap->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$compositecompositemap->setSecurity(undef)};
ok((!$@ and not defined $compositecompositemap->getSecurity()),
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


ok((UNIVERSAL::isa($compositecompositemap->getPropertySets,'ARRAY')
 and scalar @{$compositecompositemap->getPropertySets} == 1
 and UNIVERSAL::isa($compositecompositemap->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compositecompositemap->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compositecompositemap->getPropertySets,'ARRAY')
 and scalar @{$compositecompositemap->getPropertySets} == 1
 and $compositecompositemap->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compositecompositemap->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compositecompositemap->getPropertySets,'ARRAY')
 and scalar @{$compositecompositemap->getPropertySets} == 2
 and $compositecompositemap->getPropertySets->[0] == $propertysets_assn
 and $compositecompositemap->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compositecompositemap->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compositecompositemap->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compositecompositemap->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compositecompositemap->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compositecompositemap->setPropertySets([])};
ok((!$@ and defined $compositecompositemap->getPropertySets()
    and UNIVERSAL::isa($compositecompositemap->getPropertySets, 'ARRAY')
    and scalar @{$compositecompositemap->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compositecompositemap->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compositecompositemap->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compositecompositemap->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compositecompositemap->setPropertySets(undef)};
ok((!$@ and not defined $compositecompositemap->getPropertySets()),
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



# testing association compositeSequence
my $compositesequence_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequence_assn = Bio::MAGE::DesignElement::CompositeSequence->new();
}


isa_ok($compositecompositemap->getCompositeSequence, q[Bio::MAGE::DesignElement::CompositeSequence]);

is($compositecompositemap->setCompositeSequence($compositesequence_assn), $compositesequence_assn,
  'setCompositeSequence returns value');

ok($compositecompositemap->getCompositeSequence() == $compositesequence_assn,
   'getCompositeSequence fetches correct value');

# test setCompositeSequence throws exception with bad argument
eval {$compositecompositemap->setCompositeSequence(1)};
ok($@, 'setCompositeSequence throws exception with bad argument');


# test getCompositeSequence throws exception with argument
eval {$compositecompositemap->getCompositeSequence(1)};
ok($@, 'getCompositeSequence throws exception with argument');

# test setCompositeSequence throws exception with no argument
eval {$compositecompositemap->setCompositeSequence()};
ok($@, 'setCompositeSequence throws exception with no argument');

# test setCompositeSequence throws exception with too many argument
eval {$compositecompositemap->setCompositeSequence(1,2)};
ok($@, 'setCompositeSequence throws exception with too many argument');

# test setCompositeSequence accepts undef
eval {$compositecompositemap->setCompositeSequence(undef)};
ok((!$@ and not defined $compositecompositemap->getCompositeSequence()),
   'setCompositeSequence accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeSequence};
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
   'compositeSequence->other() is a valid Bio::MAGE::Association::End'
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
   'compositeSequence->self() is a valid Bio::MAGE::Association::End'
  );



# testing association compositePositionSources
my $compositepositionsources_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositepositionsources_assn = Bio::MAGE::DesignElement::CompositePosition->new();
}


ok((UNIVERSAL::isa($compositecompositemap->getCompositePositionSources,'ARRAY')
 and scalar @{$compositecompositemap->getCompositePositionSources} == 1
 and UNIVERSAL::isa($compositecompositemap->getCompositePositionSources->[0], q[Bio::MAGE::DesignElement::CompositePosition])),
  'compositePositionSources set in new()');

ok(eq_array($compositecompositemap->setCompositePositionSources([$compositepositionsources_assn]), [$compositepositionsources_assn]),
   'setCompositePositionSources returns correct value');

ok((UNIVERSAL::isa($compositecompositemap->getCompositePositionSources,'ARRAY')
 and scalar @{$compositecompositemap->getCompositePositionSources} == 1
 and $compositecompositemap->getCompositePositionSources->[0] == $compositepositionsources_assn),
   'getCompositePositionSources fetches correct value');

is($compositecompositemap->addCompositePositionSources($compositepositionsources_assn), 2,
  'addCompositePositionSources returns number of items in list');

ok((UNIVERSAL::isa($compositecompositemap->getCompositePositionSources,'ARRAY')
 and scalar @{$compositecompositemap->getCompositePositionSources} == 2
 and $compositecompositemap->getCompositePositionSources->[0] == $compositepositionsources_assn
 and $compositecompositemap->getCompositePositionSources->[1] == $compositepositionsources_assn),
  'addCompositePositionSources adds correct value');

# test setCompositePositionSources throws exception with non-array argument
eval {$compositecompositemap->setCompositePositionSources(1)};
ok($@, 'setCompositePositionSources throws exception with non-array argument');

# test setCompositePositionSources throws exception with bad argument array
eval {$compositecompositemap->setCompositePositionSources([1])};
ok($@, 'setCompositePositionSources throws exception with bad argument array');

# test addCompositePositionSources throws exception with no arguments
eval {$compositecompositemap->addCompositePositionSources()};
ok($@, 'addCompositePositionSources throws exception with no arguments');

# test addCompositePositionSources throws exception with bad argument
eval {$compositecompositemap->addCompositePositionSources(1)};
ok($@, 'addCompositePositionSources throws exception with bad array');

# test setCompositePositionSources accepts empty array ref
eval {$compositecompositemap->setCompositePositionSources([])};
ok((!$@ and defined $compositecompositemap->getCompositePositionSources()
    and UNIVERSAL::isa($compositecompositemap->getCompositePositionSources, 'ARRAY')
    and scalar @{$compositecompositemap->getCompositePositionSources} == 0),
   'setCompositePositionSources accepts empty array ref');


# test getCompositePositionSources throws exception with argument
eval {$compositecompositemap->getCompositePositionSources(1)};
ok($@, 'getCompositePositionSources throws exception with argument');

# test setCompositePositionSources throws exception with no argument
eval {$compositecompositemap->setCompositePositionSources()};
ok($@, 'setCompositePositionSources throws exception with no argument');

# test setCompositePositionSources throws exception with too many argument
eval {$compositecompositemap->setCompositePositionSources(1,2)};
ok($@, 'setCompositePositionSources throws exception with too many argument');

# test setCompositePositionSources accepts undef
eval {$compositecompositemap->setCompositePositionSources(undef)};
ok((!$@ and not defined $compositecompositemap->getCompositePositionSources()),
   'setCompositePositionSources accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositePositionSources};
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
   'compositePositionSources->other() is a valid Bio::MAGE::Association::End'
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
   'compositePositionSources->self() is a valid Bio::MAGE::Association::End'
  );





my $designelementmap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementmap = Bio::MAGE::BioAssayData::DesignElementMap->new();
}

# testing superclass DesignElementMap
isa_ok($designelementmap, q[Bio::MAGE::BioAssayData::DesignElementMap]);
isa_ok($compositecompositemap, q[Bio::MAGE::BioAssayData::DesignElementMap]);

