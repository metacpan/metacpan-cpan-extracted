##############################
#
# BioAssayCreation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayCreation.t`

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
use Test::More tests => 154;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::BioAssayCreation') };

use Bio::MAGE::Array::Array;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioMaterial::BioMaterialMeasurement;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssay::PhysicalBioAssay;
use Bio::MAGE::Description::Description;

use Bio::MAGE::BioAssay::Hybridization;

# we test the new() method
my $bioassaycreation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaycreation = Bio::MAGE::BioAssay::BioAssayCreation->new();
}
isa_ok($bioassaycreation, 'Bio::MAGE::BioAssay::BioAssayCreation');

# test the package_name class method
is($bioassaycreation->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($bioassaycreation->class_name(), q[Bio::MAGE::BioAssay::BioAssayCreation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaycreation = Bio::MAGE::BioAssay::BioAssayCreation->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaycreation->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaycreation->setIdentifier('1');
is($bioassaycreation->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaycreation->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaycreation->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaycreation->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaycreation->setIdentifier(undef)};
ok((!$@ and not defined $bioassaycreation->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaycreation->getName(), '2',
  'name new');

# test getter/setter
$bioassaycreation->setName('2');
is($bioassaycreation->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaycreation->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaycreation->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaycreation->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaycreation->setName(undef)};
ok((!$@ and not defined $bioassaycreation->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::BioAssayCreation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaycreation = Bio::MAGE::BioAssay::BioAssayCreation->new(sourceBioMaterialMeasurements => [Bio::MAGE::BioMaterial::BioMaterialMeasurement->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
array => Bio::MAGE::Array::Array->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
physicalBioAssayTarget => Bio::MAGE::BioAssay::PhysicalBioAssay->new());
}

my ($end, $assn);


# testing association sourceBioMaterialMeasurements
my $sourcebiomaterialmeasurements_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sourcebiomaterialmeasurements_assn = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new();
}


ok((UNIVERSAL::isa($bioassaycreation->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$bioassaycreation->getSourceBioMaterialMeasurements} == 1
 and UNIVERSAL::isa($bioassaycreation->getSourceBioMaterialMeasurements->[0], q[Bio::MAGE::BioMaterial::BioMaterialMeasurement])),
  'sourceBioMaterialMeasurements set in new()');

ok(eq_array($bioassaycreation->setSourceBioMaterialMeasurements([$sourcebiomaterialmeasurements_assn]), [$sourcebiomaterialmeasurements_assn]),
   'setSourceBioMaterialMeasurements returns correct value');

ok((UNIVERSAL::isa($bioassaycreation->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$bioassaycreation->getSourceBioMaterialMeasurements} == 1
 and $bioassaycreation->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn),
   'getSourceBioMaterialMeasurements fetches correct value');

is($bioassaycreation->addSourceBioMaterialMeasurements($sourcebiomaterialmeasurements_assn), 2,
  'addSourceBioMaterialMeasurements returns number of items in list');

ok((UNIVERSAL::isa($bioassaycreation->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$bioassaycreation->getSourceBioMaterialMeasurements} == 2
 and $bioassaycreation->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn
 and $bioassaycreation->getSourceBioMaterialMeasurements->[1] == $sourcebiomaterialmeasurements_assn),
  'addSourceBioMaterialMeasurements adds correct value');

# test setSourceBioMaterialMeasurements throws exception with non-array argument
eval {$bioassaycreation->setSourceBioMaterialMeasurements(1)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with non-array argument');

# test setSourceBioMaterialMeasurements throws exception with bad argument array
eval {$bioassaycreation->setSourceBioMaterialMeasurements([1])};
ok($@, 'setSourceBioMaterialMeasurements throws exception with bad argument array');

# test addSourceBioMaterialMeasurements throws exception with no arguments
eval {$bioassaycreation->addSourceBioMaterialMeasurements()};
ok($@, 'addSourceBioMaterialMeasurements throws exception with no arguments');

# test addSourceBioMaterialMeasurements throws exception with bad argument
eval {$bioassaycreation->addSourceBioMaterialMeasurements(1)};
ok($@, 'addSourceBioMaterialMeasurements throws exception with bad array');

# test setSourceBioMaterialMeasurements accepts empty array ref
eval {$bioassaycreation->setSourceBioMaterialMeasurements([])};
ok((!$@ and defined $bioassaycreation->getSourceBioMaterialMeasurements()
    and UNIVERSAL::isa($bioassaycreation->getSourceBioMaterialMeasurements, 'ARRAY')
    and scalar @{$bioassaycreation->getSourceBioMaterialMeasurements} == 0),
   'setSourceBioMaterialMeasurements accepts empty array ref');


# test getSourceBioMaterialMeasurements throws exception with argument
eval {$bioassaycreation->getSourceBioMaterialMeasurements(1)};
ok($@, 'getSourceBioMaterialMeasurements throws exception with argument');

# test setSourceBioMaterialMeasurements throws exception with no argument
eval {$bioassaycreation->setSourceBioMaterialMeasurements()};
ok($@, 'setSourceBioMaterialMeasurements throws exception with no argument');

# test setSourceBioMaterialMeasurements throws exception with too many argument
eval {$bioassaycreation->setSourceBioMaterialMeasurements(1,2)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with too many argument');

# test setSourceBioMaterialMeasurements accepts undef
eval {$bioassaycreation->setSourceBioMaterialMeasurements(undef)};
ok((!$@ and not defined $bioassaycreation->getSourceBioMaterialMeasurements()),
   'setSourceBioMaterialMeasurements accepts undef');

# test the meta-data for the assoication
$assn = $assns{sourceBioMaterialMeasurements};
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
   'sourceBioMaterialMeasurements->other() is a valid Bio::MAGE::Association::End'
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
   'sourceBioMaterialMeasurements->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($bioassaycreation->getAuditTrail,'ARRAY')
 and scalar @{$bioassaycreation->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaycreation->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaycreation->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaycreation->getAuditTrail,'ARRAY')
 and scalar @{$bioassaycreation->getAuditTrail} == 1
 and $bioassaycreation->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaycreation->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaycreation->getAuditTrail,'ARRAY')
 and scalar @{$bioassaycreation->getAuditTrail} == 2
 and $bioassaycreation->getAuditTrail->[0] == $audittrail_assn
 and $bioassaycreation->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaycreation->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaycreation->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaycreation->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaycreation->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaycreation->setAuditTrail([])};
ok((!$@ and defined $bioassaycreation->getAuditTrail()
    and UNIVERSAL::isa($bioassaycreation->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaycreation->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaycreation->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaycreation->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaycreation->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaycreation->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaycreation->getAuditTrail()),
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


ok((UNIVERSAL::isa($bioassaycreation->getPropertySets,'ARRAY')
 and scalar @{$bioassaycreation->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaycreation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaycreation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaycreation->getPropertySets,'ARRAY')
 and scalar @{$bioassaycreation->getPropertySets} == 1
 and $bioassaycreation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaycreation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaycreation->getPropertySets,'ARRAY')
 and scalar @{$bioassaycreation->getPropertySets} == 2
 and $bioassaycreation->getPropertySets->[0] == $propertysets_assn
 and $bioassaycreation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaycreation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaycreation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaycreation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaycreation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaycreation->setPropertySets([])};
ok((!$@ and defined $bioassaycreation->getPropertySets()
    and UNIVERSAL::isa($bioassaycreation->getPropertySets, 'ARRAY')
    and scalar @{$bioassaycreation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaycreation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaycreation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaycreation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaycreation->setPropertySets(undef)};
ok((!$@ and not defined $bioassaycreation->getPropertySets()),
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



# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($bioassaycreation->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaycreation->getProtocolApplications} == 1
 and UNIVERSAL::isa($bioassaycreation->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($bioassaycreation->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($bioassaycreation->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaycreation->getProtocolApplications} == 1
 and $bioassaycreation->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($bioassaycreation->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($bioassaycreation->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaycreation->getProtocolApplications} == 2
 and $bioassaycreation->getProtocolApplications->[0] == $protocolapplications_assn
 and $bioassaycreation->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$bioassaycreation->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$bioassaycreation->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$bioassaycreation->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$bioassaycreation->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$bioassaycreation->setProtocolApplications([])};
ok((!$@ and defined $bioassaycreation->getProtocolApplications()
    and UNIVERSAL::isa($bioassaycreation->getProtocolApplications, 'ARRAY')
    and scalar @{$bioassaycreation->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$bioassaycreation->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$bioassaycreation->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$bioassaycreation->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$bioassaycreation->setProtocolApplications(undef)};
ok((!$@ and not defined $bioassaycreation->getProtocolApplications()),
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



# testing association array
my $array_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $array_assn = Bio::MAGE::Array::Array->new();
}


isa_ok($bioassaycreation->getArray, q[Bio::MAGE::Array::Array]);

is($bioassaycreation->setArray($array_assn), $array_assn,
  'setArray returns value');

ok($bioassaycreation->getArray() == $array_assn,
   'getArray fetches correct value');

# test setArray throws exception with bad argument
eval {$bioassaycreation->setArray(1)};
ok($@, 'setArray throws exception with bad argument');


# test getArray throws exception with argument
eval {$bioassaycreation->getArray(1)};
ok($@, 'getArray throws exception with argument');

# test setArray throws exception with no argument
eval {$bioassaycreation->setArray()};
ok($@, 'setArray throws exception with no argument');

# test setArray throws exception with too many argument
eval {$bioassaycreation->setArray(1,2)};
ok($@, 'setArray throws exception with too many argument');

# test setArray accepts undef
eval {$bioassaycreation->setArray(undef)};
ok((!$@ and not defined $bioassaycreation->getArray()),
   'setArray accepts undef');

# test the meta-data for the assoication
$assn = $assns{array};
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
   'array->other() is a valid Bio::MAGE::Association::End'
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
   'array->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bioassaycreation->getDescriptions,'ARRAY')
 and scalar @{$bioassaycreation->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaycreation->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaycreation->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaycreation->getDescriptions,'ARRAY')
 and scalar @{$bioassaycreation->getDescriptions} == 1
 and $bioassaycreation->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaycreation->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaycreation->getDescriptions,'ARRAY')
 and scalar @{$bioassaycreation->getDescriptions} == 2
 and $bioassaycreation->getDescriptions->[0] == $descriptions_assn
 and $bioassaycreation->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaycreation->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaycreation->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaycreation->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaycreation->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaycreation->setDescriptions([])};
ok((!$@ and defined $bioassaycreation->getDescriptions()
    and UNIVERSAL::isa($bioassaycreation->getDescriptions, 'ARRAY')
    and scalar @{$bioassaycreation->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaycreation->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaycreation->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaycreation->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaycreation->setDescriptions(undef)};
ok((!$@ and not defined $bioassaycreation->getDescriptions()),
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


isa_ok($bioassaycreation->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaycreation->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaycreation->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaycreation->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaycreation->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaycreation->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaycreation->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaycreation->setSecurity(undef)};
ok((!$@ and not defined $bioassaycreation->getSecurity()),
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



# testing association physicalBioAssayTarget
my $physicalbioassaytarget_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassaytarget_assn = Bio::MAGE::BioAssay::PhysicalBioAssay->new();
}


isa_ok($bioassaycreation->getPhysicalBioAssayTarget, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);

is($bioassaycreation->setPhysicalBioAssayTarget($physicalbioassaytarget_assn), $physicalbioassaytarget_assn,
  'setPhysicalBioAssayTarget returns value');

ok($bioassaycreation->getPhysicalBioAssayTarget() == $physicalbioassaytarget_assn,
   'getPhysicalBioAssayTarget fetches correct value');

# test setPhysicalBioAssayTarget throws exception with bad argument
eval {$bioassaycreation->setPhysicalBioAssayTarget(1)};
ok($@, 'setPhysicalBioAssayTarget throws exception with bad argument');


# test getPhysicalBioAssayTarget throws exception with argument
eval {$bioassaycreation->getPhysicalBioAssayTarget(1)};
ok($@, 'getPhysicalBioAssayTarget throws exception with argument');

# test setPhysicalBioAssayTarget throws exception with no argument
eval {$bioassaycreation->setPhysicalBioAssayTarget()};
ok($@, 'setPhysicalBioAssayTarget throws exception with no argument');

# test setPhysicalBioAssayTarget throws exception with too many argument
eval {$bioassaycreation->setPhysicalBioAssayTarget(1,2)};
ok($@, 'setPhysicalBioAssayTarget throws exception with too many argument');

# test setPhysicalBioAssayTarget accepts undef
eval {$bioassaycreation->setPhysicalBioAssayTarget(undef)};
ok((!$@ and not defined $bioassaycreation->getPhysicalBioAssayTarget()),
   'setPhysicalBioAssayTarget accepts undef');

# test the meta-data for the assoication
$assn = $assns{physicalBioAssayTarget};
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
   'physicalBioAssayTarget->other() is a valid Bio::MAGE::Association::End'
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
   'physicalBioAssayTarget->self() is a valid Bio::MAGE::Association::End'
  );




# create a subclass
my $hybridization = Bio::MAGE::BioAssay::Hybridization->new();

# testing subclass Hybridization
isa_ok($hybridization, q[Bio::MAGE::BioAssay::Hybridization]);
isa_ok($hybridization, q[Bio::MAGE::BioAssay::BioAssayCreation]);



my $bioevent;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioevent = Bio::MAGE::BioEvent::BioEvent->new();
}

# testing superclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($bioassaycreation, q[Bio::MAGE::BioEvent::BioEvent]);

