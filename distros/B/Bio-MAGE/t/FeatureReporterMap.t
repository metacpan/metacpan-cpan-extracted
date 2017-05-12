##############################
#
# FeatureReporterMap.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureReporterMap.t`

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

BEGIN { use_ok('Bio::MAGE::DesignElement::FeatureReporterMap') };

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::DesignElement::Reporter;
use Bio::MAGE::DesignElement::FeatureInformation;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $featurereportermap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurereportermap = Bio::MAGE::DesignElement::FeatureReporterMap->new();
}
isa_ok($featurereportermap, 'Bio::MAGE::DesignElement::FeatureReporterMap');

# test the package_name class method
is($featurereportermap->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($featurereportermap->class_name(), q[Bio::MAGE::DesignElement::FeatureReporterMap],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurereportermap = Bio::MAGE::DesignElement::FeatureReporterMap->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($featurereportermap->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$featurereportermap->setIdentifier('1');
is($featurereportermap->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$featurereportermap->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$featurereportermap->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featurereportermap->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$featurereportermap->setIdentifier(undef)};
ok((!$@ and not defined $featurereportermap->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($featurereportermap->getName(), '2',
  'name new');

# test getter/setter
$featurereportermap->setName('2');
is($featurereportermap->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$featurereportermap->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$featurereportermap->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featurereportermap->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$featurereportermap->setName(undef)};
ok((!$@ and not defined $featurereportermap->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::FeatureReporterMap->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurereportermap = Bio::MAGE::DesignElement::FeatureReporterMap->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
reporter => Bio::MAGE::DesignElement::Reporter->new(),
featureInformationSources => [Bio::MAGE::DesignElement::FeatureInformation->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($featurereportermap->getProtocolApplications,'ARRAY')
 and scalar @{$featurereportermap->getProtocolApplications} == 1
 and UNIVERSAL::isa($featurereportermap->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($featurereportermap->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($featurereportermap->getProtocolApplications,'ARRAY')
 and scalar @{$featurereportermap->getProtocolApplications} == 1
 and $featurereportermap->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($featurereportermap->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($featurereportermap->getProtocolApplications,'ARRAY')
 and scalar @{$featurereportermap->getProtocolApplications} == 2
 and $featurereportermap->getProtocolApplications->[0] == $protocolapplications_assn
 and $featurereportermap->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$featurereportermap->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$featurereportermap->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$featurereportermap->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$featurereportermap->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$featurereportermap->setProtocolApplications([])};
ok((!$@ and defined $featurereportermap->getProtocolApplications()
    and UNIVERSAL::isa($featurereportermap->getProtocolApplications, 'ARRAY')
    and scalar @{$featurereportermap->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$featurereportermap->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$featurereportermap->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$featurereportermap->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$featurereportermap->setProtocolApplications(undef)};
ok((!$@ and not defined $featurereportermap->getProtocolApplications()),
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


ok((UNIVERSAL::isa($featurereportermap->getDescriptions,'ARRAY')
 and scalar @{$featurereportermap->getDescriptions} == 1
 and UNIVERSAL::isa($featurereportermap->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($featurereportermap->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($featurereportermap->getDescriptions,'ARRAY')
 and scalar @{$featurereportermap->getDescriptions} == 1
 and $featurereportermap->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($featurereportermap->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($featurereportermap->getDescriptions,'ARRAY')
 and scalar @{$featurereportermap->getDescriptions} == 2
 and $featurereportermap->getDescriptions->[0] == $descriptions_assn
 and $featurereportermap->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$featurereportermap->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$featurereportermap->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$featurereportermap->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$featurereportermap->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$featurereportermap->setDescriptions([])};
ok((!$@ and defined $featurereportermap->getDescriptions()
    and UNIVERSAL::isa($featurereportermap->getDescriptions, 'ARRAY')
    and scalar @{$featurereportermap->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$featurereportermap->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$featurereportermap->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$featurereportermap->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$featurereportermap->setDescriptions(undef)};
ok((!$@ and not defined $featurereportermap->getDescriptions()),
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


ok((UNIVERSAL::isa($featurereportermap->getAuditTrail,'ARRAY')
 and scalar @{$featurereportermap->getAuditTrail} == 1
 and UNIVERSAL::isa($featurereportermap->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($featurereportermap->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($featurereportermap->getAuditTrail,'ARRAY')
 and scalar @{$featurereportermap->getAuditTrail} == 1
 and $featurereportermap->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($featurereportermap->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($featurereportermap->getAuditTrail,'ARRAY')
 and scalar @{$featurereportermap->getAuditTrail} == 2
 and $featurereportermap->getAuditTrail->[0] == $audittrail_assn
 and $featurereportermap->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$featurereportermap->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$featurereportermap->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$featurereportermap->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$featurereportermap->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$featurereportermap->setAuditTrail([])};
ok((!$@ and defined $featurereportermap->getAuditTrail()
    and UNIVERSAL::isa($featurereportermap->getAuditTrail, 'ARRAY')
    and scalar @{$featurereportermap->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$featurereportermap->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$featurereportermap->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$featurereportermap->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$featurereportermap->setAuditTrail(undef)};
ok((!$@ and not defined $featurereportermap->getAuditTrail()),
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


isa_ok($featurereportermap->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($featurereportermap->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($featurereportermap->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$featurereportermap->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$featurereportermap->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$featurereportermap->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$featurereportermap->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$featurereportermap->setSecurity(undef)};
ok((!$@ and not defined $featurereportermap->getSecurity()),
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


ok((UNIVERSAL::isa($featurereportermap->getPropertySets,'ARRAY')
 and scalar @{$featurereportermap->getPropertySets} == 1
 and UNIVERSAL::isa($featurereportermap->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featurereportermap->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featurereportermap->getPropertySets,'ARRAY')
 and scalar @{$featurereportermap->getPropertySets} == 1
 and $featurereportermap->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featurereportermap->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featurereportermap->getPropertySets,'ARRAY')
 and scalar @{$featurereportermap->getPropertySets} == 2
 and $featurereportermap->getPropertySets->[0] == $propertysets_assn
 and $featurereportermap->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featurereportermap->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featurereportermap->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featurereportermap->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featurereportermap->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featurereportermap->setPropertySets([])};
ok((!$@ and defined $featurereportermap->getPropertySets()
    and UNIVERSAL::isa($featurereportermap->getPropertySets, 'ARRAY')
    and scalar @{$featurereportermap->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featurereportermap->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featurereportermap->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featurereportermap->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featurereportermap->setPropertySets(undef)};
ok((!$@ and not defined $featurereportermap->getPropertySets()),
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



# testing association reporter
my $reporter_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporter_assn = Bio::MAGE::DesignElement::Reporter->new();
}


isa_ok($featurereportermap->getReporter, q[Bio::MAGE::DesignElement::Reporter]);

is($featurereportermap->setReporter($reporter_assn), $reporter_assn,
  'setReporter returns value');

ok($featurereportermap->getReporter() == $reporter_assn,
   'getReporter fetches correct value');

# test setReporter throws exception with bad argument
eval {$featurereportermap->setReporter(1)};
ok($@, 'setReporter throws exception with bad argument');


# test getReporter throws exception with argument
eval {$featurereportermap->getReporter(1)};
ok($@, 'getReporter throws exception with argument');

# test setReporter throws exception with no argument
eval {$featurereportermap->setReporter()};
ok($@, 'setReporter throws exception with no argument');

# test setReporter throws exception with too many argument
eval {$featurereportermap->setReporter(1,2)};
ok($@, 'setReporter throws exception with too many argument');

# test setReporter accepts undef
eval {$featurereportermap->setReporter(undef)};
ok((!$@ and not defined $featurereportermap->getReporter()),
   'setReporter accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporter};
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
   'reporter->other() is a valid Bio::MAGE::Association::End'
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
   'reporter->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureInformationSources
my $featureinformationsources_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureinformationsources_assn = Bio::MAGE::DesignElement::FeatureInformation->new();
}


ok((UNIVERSAL::isa($featurereportermap->getFeatureInformationSources,'ARRAY')
 and scalar @{$featurereportermap->getFeatureInformationSources} == 1
 and UNIVERSAL::isa($featurereportermap->getFeatureInformationSources->[0], q[Bio::MAGE::DesignElement::FeatureInformation])),
  'featureInformationSources set in new()');

ok(eq_array($featurereportermap->setFeatureInformationSources([$featureinformationsources_assn]), [$featureinformationsources_assn]),
   'setFeatureInformationSources returns correct value');

ok((UNIVERSAL::isa($featurereportermap->getFeatureInformationSources,'ARRAY')
 and scalar @{$featurereportermap->getFeatureInformationSources} == 1
 and $featurereportermap->getFeatureInformationSources->[0] == $featureinformationsources_assn),
   'getFeatureInformationSources fetches correct value');

is($featurereportermap->addFeatureInformationSources($featureinformationsources_assn), 2,
  'addFeatureInformationSources returns number of items in list');

ok((UNIVERSAL::isa($featurereportermap->getFeatureInformationSources,'ARRAY')
 and scalar @{$featurereportermap->getFeatureInformationSources} == 2
 and $featurereportermap->getFeatureInformationSources->[0] == $featureinformationsources_assn
 and $featurereportermap->getFeatureInformationSources->[1] == $featureinformationsources_assn),
  'addFeatureInformationSources adds correct value');

# test setFeatureInformationSources throws exception with non-array argument
eval {$featurereportermap->setFeatureInformationSources(1)};
ok($@, 'setFeatureInformationSources throws exception with non-array argument');

# test setFeatureInformationSources throws exception with bad argument array
eval {$featurereportermap->setFeatureInformationSources([1])};
ok($@, 'setFeatureInformationSources throws exception with bad argument array');

# test addFeatureInformationSources throws exception with no arguments
eval {$featurereportermap->addFeatureInformationSources()};
ok($@, 'addFeatureInformationSources throws exception with no arguments');

# test addFeatureInformationSources throws exception with bad argument
eval {$featurereportermap->addFeatureInformationSources(1)};
ok($@, 'addFeatureInformationSources throws exception with bad array');

# test setFeatureInformationSources accepts empty array ref
eval {$featurereportermap->setFeatureInformationSources([])};
ok((!$@ and defined $featurereportermap->getFeatureInformationSources()
    and UNIVERSAL::isa($featurereportermap->getFeatureInformationSources, 'ARRAY')
    and scalar @{$featurereportermap->getFeatureInformationSources} == 0),
   'setFeatureInformationSources accepts empty array ref');


# test getFeatureInformationSources throws exception with argument
eval {$featurereportermap->getFeatureInformationSources(1)};
ok($@, 'getFeatureInformationSources throws exception with argument');

# test setFeatureInformationSources throws exception with no argument
eval {$featurereportermap->setFeatureInformationSources()};
ok($@, 'setFeatureInformationSources throws exception with no argument');

# test setFeatureInformationSources throws exception with too many argument
eval {$featurereportermap->setFeatureInformationSources(1,2)};
ok($@, 'setFeatureInformationSources throws exception with too many argument');

# test setFeatureInformationSources accepts undef
eval {$featurereportermap->setFeatureInformationSources(undef)};
ok((!$@ and not defined $featurereportermap->getFeatureInformationSources()),
   'setFeatureInformationSources accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureInformationSources};
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
   'featureInformationSources->other() is a valid Bio::MAGE::Association::End'
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
   'featureInformationSources->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($featurereportermap, q[Bio::MAGE::BioAssayData::DesignElementMap]);

