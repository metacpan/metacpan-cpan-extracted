##############################
#
# PhysicalArrayDesign.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PhysicalArrayDesign.t`

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
use Test::More tests => 227;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::PhysicalArrayDesign') };

use Bio::MAGE::ArrayDesign::CompositeGroup;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::ArrayDesign::ReporterGroup;
use Bio::MAGE::ArrayDesign::FeatureGroup;
use Bio::MAGE::ArrayDesign::ZoneGroup;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $physicalarraydesign;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new();
}
isa_ok($physicalarraydesign, 'Bio::MAGE::ArrayDesign::PhysicalArrayDesign');

# test the package_name class method
is($physicalarraydesign->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($physicalarraydesign->class_name(), q[Bio::MAGE::ArrayDesign::PhysicalArrayDesign],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new(identifier => '1',
numberOfFeatures => '2',
version => '3',
name => '4');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($physicalarraydesign->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$physicalarraydesign->setIdentifier('1');
is($physicalarraydesign->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$physicalarraydesign->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalarraydesign->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalarraydesign->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalarraydesign->setIdentifier(undef)};
ok((!$@ and not defined $physicalarraydesign->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute numberOfFeatures
#

# test attribute values can be set in new()
is($physicalarraydesign->getNumberOfFeatures(), '2',
  'numberOfFeatures new');

# test getter/setter
$physicalarraydesign->setNumberOfFeatures('2');
is($physicalarraydesign->getNumberOfFeatures(), '2',
  'numberOfFeatures getter/setter');

# test getter throws exception with argument
eval {$physicalarraydesign->getNumberOfFeatures(1)};
ok($@, 'numberOfFeatures getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalarraydesign->setNumberOfFeatures()};
ok($@, 'numberOfFeatures setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalarraydesign->setNumberOfFeatures('2', '2')};
ok($@, 'numberOfFeatures setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalarraydesign->setNumberOfFeatures(undef)};
ok((!$@ and not defined $physicalarraydesign->getNumberOfFeatures()),
   'numberOfFeatures setter accepts undef');



#
# testing attribute version
#

# test attribute values can be set in new()
is($physicalarraydesign->getVersion(), '3',
  'version new');

# test getter/setter
$physicalarraydesign->setVersion('3');
is($physicalarraydesign->getVersion(), '3',
  'version getter/setter');

# test getter throws exception with argument
eval {$physicalarraydesign->getVersion(1)};
ok($@, 'version getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalarraydesign->setVersion()};
ok($@, 'version setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalarraydesign->setVersion('3', '3')};
ok($@, 'version setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalarraydesign->setVersion(undef)};
ok((!$@ and not defined $physicalarraydesign->getVersion()),
   'version setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($physicalarraydesign->getName(), '4',
  'name new');

# test getter/setter
$physicalarraydesign->setName('4');
is($physicalarraydesign->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$physicalarraydesign->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalarraydesign->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalarraydesign->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalarraydesign->setName(undef)};
ok((!$@ and not defined $physicalarraydesign->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new(auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
surfaceType => Bio::MAGE::Description::OntologyEntry->new(),
designProviders => [Bio::MAGE::AuditAndSecurity::Contact->new()],
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
reporterGroups => [Bio::MAGE::ArrayDesign::ReporterGroup->new()],
zoneGroups => [Bio::MAGE::ArrayDesign::ZoneGroup->new()],
featureGroups => [Bio::MAGE::ArrayDesign::FeatureGroup->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
compositeGroups => [Bio::MAGE::ArrayDesign::CompositeGroup->new()]);
}

my ($end, $assn);


# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getAuditTrail,'ARRAY')
 and scalar @{$physicalarraydesign->getAuditTrail} == 1
 and UNIVERSAL::isa($physicalarraydesign->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($physicalarraydesign->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getAuditTrail,'ARRAY')
 and scalar @{$physicalarraydesign->getAuditTrail} == 1
 and $physicalarraydesign->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($physicalarraydesign->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getAuditTrail,'ARRAY')
 and scalar @{$physicalarraydesign->getAuditTrail} == 2
 and $physicalarraydesign->getAuditTrail->[0] == $audittrail_assn
 and $physicalarraydesign->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$physicalarraydesign->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$physicalarraydesign->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$physicalarraydesign->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$physicalarraydesign->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$physicalarraydesign->setAuditTrail([])};
ok((!$@ and defined $physicalarraydesign->getAuditTrail()
    and UNIVERSAL::isa($physicalarraydesign->getAuditTrail, 'ARRAY')
    and scalar @{$physicalarraydesign->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$physicalarraydesign->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$physicalarraydesign->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$physicalarraydesign->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$physicalarraydesign->setAuditTrail(undef)};
ok((!$@ and not defined $physicalarraydesign->getAuditTrail()),
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


ok((UNIVERSAL::isa($physicalarraydesign->getPropertySets,'ARRAY')
 and scalar @{$physicalarraydesign->getPropertySets} == 1
 and UNIVERSAL::isa($physicalarraydesign->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($physicalarraydesign->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getPropertySets,'ARRAY')
 and scalar @{$physicalarraydesign->getPropertySets} == 1
 and $physicalarraydesign->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($physicalarraydesign->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getPropertySets,'ARRAY')
 and scalar @{$physicalarraydesign->getPropertySets} == 2
 and $physicalarraydesign->getPropertySets->[0] == $propertysets_assn
 and $physicalarraydesign->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$physicalarraydesign->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$physicalarraydesign->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$physicalarraydesign->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$physicalarraydesign->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$physicalarraydesign->setPropertySets([])};
ok((!$@ and defined $physicalarraydesign->getPropertySets()
    and UNIVERSAL::isa($physicalarraydesign->getPropertySets, 'ARRAY')
    and scalar @{$physicalarraydesign->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$physicalarraydesign->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$physicalarraydesign->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$physicalarraydesign->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$physicalarraydesign->setPropertySets(undef)};
ok((!$@ and not defined $physicalarraydesign->getPropertySets()),
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



# testing association surfaceType
my $surfacetype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $surfacetype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($physicalarraydesign->getSurfaceType, q[Bio::MAGE::Description::OntologyEntry]);

is($physicalarraydesign->setSurfaceType($surfacetype_assn), $surfacetype_assn,
  'setSurfaceType returns value');

ok($physicalarraydesign->getSurfaceType() == $surfacetype_assn,
   'getSurfaceType fetches correct value');

# test setSurfaceType throws exception with bad argument
eval {$physicalarraydesign->setSurfaceType(1)};
ok($@, 'setSurfaceType throws exception with bad argument');


# test getSurfaceType throws exception with argument
eval {$physicalarraydesign->getSurfaceType(1)};
ok($@, 'getSurfaceType throws exception with argument');

# test setSurfaceType throws exception with no argument
eval {$physicalarraydesign->setSurfaceType()};
ok($@, 'setSurfaceType throws exception with no argument');

# test setSurfaceType throws exception with too many argument
eval {$physicalarraydesign->setSurfaceType(1,2)};
ok($@, 'setSurfaceType throws exception with too many argument');

# test setSurfaceType accepts undef
eval {$physicalarraydesign->setSurfaceType(undef)};
ok((!$@ and not defined $physicalarraydesign->getSurfaceType()),
   'setSurfaceType accepts undef');

# test the meta-data for the assoication
$assn = $assns{surfaceType};
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
   'surfaceType->other() is a valid Bio::MAGE::Association::End'
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
   'surfaceType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association designProviders
my $designproviders_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designproviders_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getDesignProviders,'ARRAY')
 and scalar @{$physicalarraydesign->getDesignProviders} == 1
 and UNIVERSAL::isa($physicalarraydesign->getDesignProviders->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'designProviders set in new()');

ok(eq_array($physicalarraydesign->setDesignProviders([$designproviders_assn]), [$designproviders_assn]),
   'setDesignProviders returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getDesignProviders,'ARRAY')
 and scalar @{$physicalarraydesign->getDesignProviders} == 1
 and $physicalarraydesign->getDesignProviders->[0] == $designproviders_assn),
   'getDesignProviders fetches correct value');

is($physicalarraydesign->addDesignProviders($designproviders_assn), 2,
  'addDesignProviders returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getDesignProviders,'ARRAY')
 and scalar @{$physicalarraydesign->getDesignProviders} == 2
 and $physicalarraydesign->getDesignProviders->[0] == $designproviders_assn
 and $physicalarraydesign->getDesignProviders->[1] == $designproviders_assn),
  'addDesignProviders adds correct value');

# test setDesignProviders throws exception with non-array argument
eval {$physicalarraydesign->setDesignProviders(1)};
ok($@, 'setDesignProviders throws exception with non-array argument');

# test setDesignProviders throws exception with bad argument array
eval {$physicalarraydesign->setDesignProviders([1])};
ok($@, 'setDesignProviders throws exception with bad argument array');

# test addDesignProviders throws exception with no arguments
eval {$physicalarraydesign->addDesignProviders()};
ok($@, 'addDesignProviders throws exception with no arguments');

# test addDesignProviders throws exception with bad argument
eval {$physicalarraydesign->addDesignProviders(1)};
ok($@, 'addDesignProviders throws exception with bad array');

# test setDesignProviders accepts empty array ref
eval {$physicalarraydesign->setDesignProviders([])};
ok((!$@ and defined $physicalarraydesign->getDesignProviders()
    and UNIVERSAL::isa($physicalarraydesign->getDesignProviders, 'ARRAY')
    and scalar @{$physicalarraydesign->getDesignProviders} == 0),
   'setDesignProviders accepts empty array ref');


# test getDesignProviders throws exception with argument
eval {$physicalarraydesign->getDesignProviders(1)};
ok($@, 'getDesignProviders throws exception with argument');

# test setDesignProviders throws exception with no argument
eval {$physicalarraydesign->setDesignProviders()};
ok($@, 'setDesignProviders throws exception with no argument');

# test setDesignProviders throws exception with too many argument
eval {$physicalarraydesign->setDesignProviders(1,2)};
ok($@, 'setDesignProviders throws exception with too many argument');

# test setDesignProviders accepts undef
eval {$physicalarraydesign->setDesignProviders(undef)};
ok((!$@ and not defined $physicalarraydesign->getDesignProviders()),
   'setDesignProviders accepts undef');

# test the meta-data for the assoication
$assn = $assns{designProviders};
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
   'designProviders->other() is a valid Bio::MAGE::Association::End'
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
   'designProviders->self() is a valid Bio::MAGE::Association::End'
  );



# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$physicalarraydesign->getProtocolApplications} == 1
 and UNIVERSAL::isa($physicalarraydesign->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($physicalarraydesign->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$physicalarraydesign->getProtocolApplications} == 1
 and $physicalarraydesign->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($physicalarraydesign->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$physicalarraydesign->getProtocolApplications} == 2
 and $physicalarraydesign->getProtocolApplications->[0] == $protocolapplications_assn
 and $physicalarraydesign->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$physicalarraydesign->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$physicalarraydesign->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$physicalarraydesign->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$physicalarraydesign->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$physicalarraydesign->setProtocolApplications([])};
ok((!$@ and defined $physicalarraydesign->getProtocolApplications()
    and UNIVERSAL::isa($physicalarraydesign->getProtocolApplications, 'ARRAY')
    and scalar @{$physicalarraydesign->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$physicalarraydesign->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$physicalarraydesign->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$physicalarraydesign->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$physicalarraydesign->setProtocolApplications(undef)};
ok((!$@ and not defined $physicalarraydesign->getProtocolApplications()),
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



# testing association reporterGroups
my $reportergroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportergroups_assn = Bio::MAGE::ArrayDesign::ReporterGroup->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getReporterGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getReporterGroups} == 1
 and UNIVERSAL::isa($physicalarraydesign->getReporterGroups->[0], q[Bio::MAGE::ArrayDesign::ReporterGroup])),
  'reporterGroups set in new()');

ok(eq_array($physicalarraydesign->setReporterGroups([$reportergroups_assn]), [$reportergroups_assn]),
   'setReporterGroups returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getReporterGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getReporterGroups} == 1
 and $physicalarraydesign->getReporterGroups->[0] == $reportergroups_assn),
   'getReporterGroups fetches correct value');

is($physicalarraydesign->addReporterGroups($reportergroups_assn), 2,
  'addReporterGroups returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getReporterGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getReporterGroups} == 2
 and $physicalarraydesign->getReporterGroups->[0] == $reportergroups_assn
 and $physicalarraydesign->getReporterGroups->[1] == $reportergroups_assn),
  'addReporterGroups adds correct value');

# test setReporterGroups throws exception with non-array argument
eval {$physicalarraydesign->setReporterGroups(1)};
ok($@, 'setReporterGroups throws exception with non-array argument');

# test setReporterGroups throws exception with bad argument array
eval {$physicalarraydesign->setReporterGroups([1])};
ok($@, 'setReporterGroups throws exception with bad argument array');

# test addReporterGroups throws exception with no arguments
eval {$physicalarraydesign->addReporterGroups()};
ok($@, 'addReporterGroups throws exception with no arguments');

# test addReporterGroups throws exception with bad argument
eval {$physicalarraydesign->addReporterGroups(1)};
ok($@, 'addReporterGroups throws exception with bad array');

# test setReporterGroups accepts empty array ref
eval {$physicalarraydesign->setReporterGroups([])};
ok((!$@ and defined $physicalarraydesign->getReporterGroups()
    and UNIVERSAL::isa($physicalarraydesign->getReporterGroups, 'ARRAY')
    and scalar @{$physicalarraydesign->getReporterGroups} == 0),
   'setReporterGroups accepts empty array ref');


# test getReporterGroups throws exception with argument
eval {$physicalarraydesign->getReporterGroups(1)};
ok($@, 'getReporterGroups throws exception with argument');

# test setReporterGroups throws exception with no argument
eval {$physicalarraydesign->setReporterGroups()};
ok($@, 'setReporterGroups throws exception with no argument');

# test setReporterGroups throws exception with too many argument
eval {$physicalarraydesign->setReporterGroups(1,2)};
ok($@, 'setReporterGroups throws exception with too many argument');

# test setReporterGroups accepts undef
eval {$physicalarraydesign->setReporterGroups(undef)};
ok((!$@ and not defined $physicalarraydesign->getReporterGroups()),
   'setReporterGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporterGroups};
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
   'reporterGroups->other() is a valid Bio::MAGE::Association::End'
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
   'reporterGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association zoneGroups
my $zonegroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonegroups_assn = Bio::MAGE::ArrayDesign::ZoneGroup->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getZoneGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getZoneGroups} == 1
 and UNIVERSAL::isa($physicalarraydesign->getZoneGroups->[0], q[Bio::MAGE::ArrayDesign::ZoneGroup])),
  'zoneGroups set in new()');

ok(eq_array($physicalarraydesign->setZoneGroups([$zonegroups_assn]), [$zonegroups_assn]),
   'setZoneGroups returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getZoneGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getZoneGroups} == 1
 and $physicalarraydesign->getZoneGroups->[0] == $zonegroups_assn),
   'getZoneGroups fetches correct value');

is($physicalarraydesign->addZoneGroups($zonegroups_assn), 2,
  'addZoneGroups returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getZoneGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getZoneGroups} == 2
 and $physicalarraydesign->getZoneGroups->[0] == $zonegroups_assn
 and $physicalarraydesign->getZoneGroups->[1] == $zonegroups_assn),
  'addZoneGroups adds correct value');

# test setZoneGroups throws exception with non-array argument
eval {$physicalarraydesign->setZoneGroups(1)};
ok($@, 'setZoneGroups throws exception with non-array argument');

# test setZoneGroups throws exception with bad argument array
eval {$physicalarraydesign->setZoneGroups([1])};
ok($@, 'setZoneGroups throws exception with bad argument array');

# test addZoneGroups throws exception with no arguments
eval {$physicalarraydesign->addZoneGroups()};
ok($@, 'addZoneGroups throws exception with no arguments');

# test addZoneGroups throws exception with bad argument
eval {$physicalarraydesign->addZoneGroups(1)};
ok($@, 'addZoneGroups throws exception with bad array');

# test setZoneGroups accepts empty array ref
eval {$physicalarraydesign->setZoneGroups([])};
ok((!$@ and defined $physicalarraydesign->getZoneGroups()
    and UNIVERSAL::isa($physicalarraydesign->getZoneGroups, 'ARRAY')
    and scalar @{$physicalarraydesign->getZoneGroups} == 0),
   'setZoneGroups accepts empty array ref');


# test getZoneGroups throws exception with argument
eval {$physicalarraydesign->getZoneGroups(1)};
ok($@, 'getZoneGroups throws exception with argument');

# test setZoneGroups throws exception with no argument
eval {$physicalarraydesign->setZoneGroups()};
ok($@, 'setZoneGroups throws exception with no argument');

# test setZoneGroups throws exception with too many argument
eval {$physicalarraydesign->setZoneGroups(1,2)};
ok($@, 'setZoneGroups throws exception with too many argument');

# test setZoneGroups accepts undef
eval {$physicalarraydesign->setZoneGroups(undef)};
ok((!$@ and not defined $physicalarraydesign->getZoneGroups()),
   'setZoneGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{zoneGroups};
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
   'zoneGroups->other() is a valid Bio::MAGE::Association::End'
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
   'zoneGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureGroups
my $featuregroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroups_assn = Bio::MAGE::ArrayDesign::FeatureGroup->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getFeatureGroups} == 1
 and UNIVERSAL::isa($physicalarraydesign->getFeatureGroups->[0], q[Bio::MAGE::ArrayDesign::FeatureGroup])),
  'featureGroups set in new()');

ok(eq_array($physicalarraydesign->setFeatureGroups([$featuregroups_assn]), [$featuregroups_assn]),
   'setFeatureGroups returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getFeatureGroups} == 1
 and $physicalarraydesign->getFeatureGroups->[0] == $featuregroups_assn),
   'getFeatureGroups fetches correct value');

is($physicalarraydesign->addFeatureGroups($featuregroups_assn), 2,
  'addFeatureGroups returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getFeatureGroups} == 2
 and $physicalarraydesign->getFeatureGroups->[0] == $featuregroups_assn
 and $physicalarraydesign->getFeatureGroups->[1] == $featuregroups_assn),
  'addFeatureGroups adds correct value');

# test setFeatureGroups throws exception with non-array argument
eval {$physicalarraydesign->setFeatureGroups(1)};
ok($@, 'setFeatureGroups throws exception with non-array argument');

# test setFeatureGroups throws exception with bad argument array
eval {$physicalarraydesign->setFeatureGroups([1])};
ok($@, 'setFeatureGroups throws exception with bad argument array');

# test addFeatureGroups throws exception with no arguments
eval {$physicalarraydesign->addFeatureGroups()};
ok($@, 'addFeatureGroups throws exception with no arguments');

# test addFeatureGroups throws exception with bad argument
eval {$physicalarraydesign->addFeatureGroups(1)};
ok($@, 'addFeatureGroups throws exception with bad array');

# test setFeatureGroups accepts empty array ref
eval {$physicalarraydesign->setFeatureGroups([])};
ok((!$@ and defined $physicalarraydesign->getFeatureGroups()
    and UNIVERSAL::isa($physicalarraydesign->getFeatureGroups, 'ARRAY')
    and scalar @{$physicalarraydesign->getFeatureGroups} == 0),
   'setFeatureGroups accepts empty array ref');


# test getFeatureGroups throws exception with argument
eval {$physicalarraydesign->getFeatureGroups(1)};
ok($@, 'getFeatureGroups throws exception with argument');

# test setFeatureGroups throws exception with no argument
eval {$physicalarraydesign->setFeatureGroups()};
ok($@, 'setFeatureGroups throws exception with no argument');

# test setFeatureGroups throws exception with too many argument
eval {$physicalarraydesign->setFeatureGroups(1,2)};
ok($@, 'setFeatureGroups throws exception with too many argument');

# test setFeatureGroups accepts undef
eval {$physicalarraydesign->setFeatureGroups(undef)};
ok((!$@ and not defined $physicalarraydesign->getFeatureGroups()),
   'setFeatureGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureGroups};
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
   'featureGroups->other() is a valid Bio::MAGE::Association::End'
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
   'featureGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getDescriptions,'ARRAY')
 and scalar @{$physicalarraydesign->getDescriptions} == 1
 and UNIVERSAL::isa($physicalarraydesign->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($physicalarraydesign->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getDescriptions,'ARRAY')
 and scalar @{$physicalarraydesign->getDescriptions} == 1
 and $physicalarraydesign->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($physicalarraydesign->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getDescriptions,'ARRAY')
 and scalar @{$physicalarraydesign->getDescriptions} == 2
 and $physicalarraydesign->getDescriptions->[0] == $descriptions_assn
 and $physicalarraydesign->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$physicalarraydesign->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$physicalarraydesign->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$physicalarraydesign->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$physicalarraydesign->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$physicalarraydesign->setDescriptions([])};
ok((!$@ and defined $physicalarraydesign->getDescriptions()
    and UNIVERSAL::isa($physicalarraydesign->getDescriptions, 'ARRAY')
    and scalar @{$physicalarraydesign->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$physicalarraydesign->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$physicalarraydesign->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$physicalarraydesign->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$physicalarraydesign->setDescriptions(undef)};
ok((!$@ and not defined $physicalarraydesign->getDescriptions()),
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


isa_ok($physicalarraydesign->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($physicalarraydesign->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($physicalarraydesign->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$physicalarraydesign->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$physicalarraydesign->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$physicalarraydesign->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$physicalarraydesign->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$physicalarraydesign->setSecurity(undef)};
ok((!$@ and not defined $physicalarraydesign->getSecurity()),
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



# testing association compositeGroups
my $compositegroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositegroups_assn = Bio::MAGE::ArrayDesign::CompositeGroup->new();
}


ok((UNIVERSAL::isa($physicalarraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getCompositeGroups} == 1
 and UNIVERSAL::isa($physicalarraydesign->getCompositeGroups->[0], q[Bio::MAGE::ArrayDesign::CompositeGroup])),
  'compositeGroups set in new()');

ok(eq_array($physicalarraydesign->setCompositeGroups([$compositegroups_assn]), [$compositegroups_assn]),
   'setCompositeGroups returns correct value');

ok((UNIVERSAL::isa($physicalarraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getCompositeGroups} == 1
 and $physicalarraydesign->getCompositeGroups->[0] == $compositegroups_assn),
   'getCompositeGroups fetches correct value');

is($physicalarraydesign->addCompositeGroups($compositegroups_assn), 2,
  'addCompositeGroups returns number of items in list');

ok((UNIVERSAL::isa($physicalarraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$physicalarraydesign->getCompositeGroups} == 2
 and $physicalarraydesign->getCompositeGroups->[0] == $compositegroups_assn
 and $physicalarraydesign->getCompositeGroups->[1] == $compositegroups_assn),
  'addCompositeGroups adds correct value');

# test setCompositeGroups throws exception with non-array argument
eval {$physicalarraydesign->setCompositeGroups(1)};
ok($@, 'setCompositeGroups throws exception with non-array argument');

# test setCompositeGroups throws exception with bad argument array
eval {$physicalarraydesign->setCompositeGroups([1])};
ok($@, 'setCompositeGroups throws exception with bad argument array');

# test addCompositeGroups throws exception with no arguments
eval {$physicalarraydesign->addCompositeGroups()};
ok($@, 'addCompositeGroups throws exception with no arguments');

# test addCompositeGroups throws exception with bad argument
eval {$physicalarraydesign->addCompositeGroups(1)};
ok($@, 'addCompositeGroups throws exception with bad array');

# test setCompositeGroups accepts empty array ref
eval {$physicalarraydesign->setCompositeGroups([])};
ok((!$@ and defined $physicalarraydesign->getCompositeGroups()
    and UNIVERSAL::isa($physicalarraydesign->getCompositeGroups, 'ARRAY')
    and scalar @{$physicalarraydesign->getCompositeGroups} == 0),
   'setCompositeGroups accepts empty array ref');


# test getCompositeGroups throws exception with argument
eval {$physicalarraydesign->getCompositeGroups(1)};
ok($@, 'getCompositeGroups throws exception with argument');

# test setCompositeGroups throws exception with no argument
eval {$physicalarraydesign->setCompositeGroups()};
ok($@, 'setCompositeGroups throws exception with no argument');

# test setCompositeGroups throws exception with too many argument
eval {$physicalarraydesign->setCompositeGroups(1,2)};
ok($@, 'setCompositeGroups throws exception with too many argument');

# test setCompositeGroups accepts undef
eval {$physicalarraydesign->setCompositeGroups(undef)};
ok((!$@ and not defined $physicalarraydesign->getCompositeGroups()),
   'setCompositeGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeGroups};
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
   'compositeGroups->other() is a valid Bio::MAGE::Association::End'
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
   'compositeGroups->self() is a valid Bio::MAGE::Association::End'
  );





my $arraydesign;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $arraydesign = Bio::MAGE::ArrayDesign::ArrayDesign->new();
}

# testing superclass ArrayDesign
isa_ok($arraydesign, q[Bio::MAGE::ArrayDesign::ArrayDesign]);
isa_ok($physicalarraydesign, q[Bio::MAGE::ArrayDesign::ArrayDesign]);

