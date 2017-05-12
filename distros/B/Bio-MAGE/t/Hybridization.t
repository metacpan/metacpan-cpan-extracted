##############################
#
# Hybridization.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Hybridization.t`

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
use Test::More tests => 152;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::Hybridization') };

use Bio::MAGE::Array::Array;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioMaterial::BioMaterialMeasurement;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssay::PhysicalBioAssay;
use Bio::MAGE::Description::Description;


# we test the new() method
my $hybridization;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hybridization = Bio::MAGE::BioAssay::Hybridization->new();
}
isa_ok($hybridization, 'Bio::MAGE::BioAssay::Hybridization');

# test the package_name class method
is($hybridization->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($hybridization->class_name(), q[Bio::MAGE::BioAssay::Hybridization],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hybridization = Bio::MAGE::BioAssay::Hybridization->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($hybridization->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$hybridization->setIdentifier('1');
is($hybridization->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$hybridization->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$hybridization->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hybridization->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$hybridization->setIdentifier(undef)};
ok((!$@ and not defined $hybridization->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($hybridization->getName(), '2',
  'name new');

# test getter/setter
$hybridization->setName('2');
is($hybridization->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$hybridization->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$hybridization->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hybridization->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$hybridization->setName(undef)};
ok((!$@ and not defined $hybridization->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::Hybridization->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hybridization = Bio::MAGE::BioAssay::Hybridization->new(sourceBioMaterialMeasurements => [Bio::MAGE::BioMaterial::BioMaterialMeasurement->new()],
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


ok((UNIVERSAL::isa($hybridization->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$hybridization->getSourceBioMaterialMeasurements} == 1
 and UNIVERSAL::isa($hybridization->getSourceBioMaterialMeasurements->[0], q[Bio::MAGE::BioMaterial::BioMaterialMeasurement])),
  'sourceBioMaterialMeasurements set in new()');

ok(eq_array($hybridization->setSourceBioMaterialMeasurements([$sourcebiomaterialmeasurements_assn]), [$sourcebiomaterialmeasurements_assn]),
   'setSourceBioMaterialMeasurements returns correct value');

ok((UNIVERSAL::isa($hybridization->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$hybridization->getSourceBioMaterialMeasurements} == 1
 and $hybridization->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn),
   'getSourceBioMaterialMeasurements fetches correct value');

is($hybridization->addSourceBioMaterialMeasurements($sourcebiomaterialmeasurements_assn), 2,
  'addSourceBioMaterialMeasurements returns number of items in list');

ok((UNIVERSAL::isa($hybridization->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$hybridization->getSourceBioMaterialMeasurements} == 2
 and $hybridization->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn
 and $hybridization->getSourceBioMaterialMeasurements->[1] == $sourcebiomaterialmeasurements_assn),
  'addSourceBioMaterialMeasurements adds correct value');

# test setSourceBioMaterialMeasurements throws exception with non-array argument
eval {$hybridization->setSourceBioMaterialMeasurements(1)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with non-array argument');

# test setSourceBioMaterialMeasurements throws exception with bad argument array
eval {$hybridization->setSourceBioMaterialMeasurements([1])};
ok($@, 'setSourceBioMaterialMeasurements throws exception with bad argument array');

# test addSourceBioMaterialMeasurements throws exception with no arguments
eval {$hybridization->addSourceBioMaterialMeasurements()};
ok($@, 'addSourceBioMaterialMeasurements throws exception with no arguments');

# test addSourceBioMaterialMeasurements throws exception with bad argument
eval {$hybridization->addSourceBioMaterialMeasurements(1)};
ok($@, 'addSourceBioMaterialMeasurements throws exception with bad array');

# test setSourceBioMaterialMeasurements accepts empty array ref
eval {$hybridization->setSourceBioMaterialMeasurements([])};
ok((!$@ and defined $hybridization->getSourceBioMaterialMeasurements()
    and UNIVERSAL::isa($hybridization->getSourceBioMaterialMeasurements, 'ARRAY')
    and scalar @{$hybridization->getSourceBioMaterialMeasurements} == 0),
   'setSourceBioMaterialMeasurements accepts empty array ref');


# test getSourceBioMaterialMeasurements throws exception with argument
eval {$hybridization->getSourceBioMaterialMeasurements(1)};
ok($@, 'getSourceBioMaterialMeasurements throws exception with argument');

# test setSourceBioMaterialMeasurements throws exception with no argument
eval {$hybridization->setSourceBioMaterialMeasurements()};
ok($@, 'setSourceBioMaterialMeasurements throws exception with no argument');

# test setSourceBioMaterialMeasurements throws exception with too many argument
eval {$hybridization->setSourceBioMaterialMeasurements(1,2)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with too many argument');

# test setSourceBioMaterialMeasurements accepts undef
eval {$hybridization->setSourceBioMaterialMeasurements(undef)};
ok((!$@ and not defined $hybridization->getSourceBioMaterialMeasurements()),
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


ok((UNIVERSAL::isa($hybridization->getAuditTrail,'ARRAY')
 and scalar @{$hybridization->getAuditTrail} == 1
 and UNIVERSAL::isa($hybridization->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($hybridization->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($hybridization->getAuditTrail,'ARRAY')
 and scalar @{$hybridization->getAuditTrail} == 1
 and $hybridization->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($hybridization->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($hybridization->getAuditTrail,'ARRAY')
 and scalar @{$hybridization->getAuditTrail} == 2
 and $hybridization->getAuditTrail->[0] == $audittrail_assn
 and $hybridization->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$hybridization->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$hybridization->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$hybridization->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$hybridization->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$hybridization->setAuditTrail([])};
ok((!$@ and defined $hybridization->getAuditTrail()
    and UNIVERSAL::isa($hybridization->getAuditTrail, 'ARRAY')
    and scalar @{$hybridization->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$hybridization->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$hybridization->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$hybridization->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$hybridization->setAuditTrail(undef)};
ok((!$@ and not defined $hybridization->getAuditTrail()),
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


ok((UNIVERSAL::isa($hybridization->getPropertySets,'ARRAY')
 and scalar @{$hybridization->getPropertySets} == 1
 and UNIVERSAL::isa($hybridization->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($hybridization->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($hybridization->getPropertySets,'ARRAY')
 and scalar @{$hybridization->getPropertySets} == 1
 and $hybridization->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($hybridization->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($hybridization->getPropertySets,'ARRAY')
 and scalar @{$hybridization->getPropertySets} == 2
 and $hybridization->getPropertySets->[0] == $propertysets_assn
 and $hybridization->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$hybridization->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$hybridization->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$hybridization->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$hybridization->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$hybridization->setPropertySets([])};
ok((!$@ and defined $hybridization->getPropertySets()
    and UNIVERSAL::isa($hybridization->getPropertySets, 'ARRAY')
    and scalar @{$hybridization->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$hybridization->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$hybridization->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$hybridization->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$hybridization->setPropertySets(undef)};
ok((!$@ and not defined $hybridization->getPropertySets()),
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


ok((UNIVERSAL::isa($hybridization->getProtocolApplications,'ARRAY')
 and scalar @{$hybridization->getProtocolApplications} == 1
 and UNIVERSAL::isa($hybridization->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($hybridization->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($hybridization->getProtocolApplications,'ARRAY')
 and scalar @{$hybridization->getProtocolApplications} == 1
 and $hybridization->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($hybridization->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($hybridization->getProtocolApplications,'ARRAY')
 and scalar @{$hybridization->getProtocolApplications} == 2
 and $hybridization->getProtocolApplications->[0] == $protocolapplications_assn
 and $hybridization->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$hybridization->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$hybridization->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$hybridization->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$hybridization->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$hybridization->setProtocolApplications([])};
ok((!$@ and defined $hybridization->getProtocolApplications()
    and UNIVERSAL::isa($hybridization->getProtocolApplications, 'ARRAY')
    and scalar @{$hybridization->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$hybridization->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$hybridization->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$hybridization->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$hybridization->setProtocolApplications(undef)};
ok((!$@ and not defined $hybridization->getProtocolApplications()),
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


isa_ok($hybridization->getArray, q[Bio::MAGE::Array::Array]);

is($hybridization->setArray($array_assn), $array_assn,
  'setArray returns value');

ok($hybridization->getArray() == $array_assn,
   'getArray fetches correct value');

# test setArray throws exception with bad argument
eval {$hybridization->setArray(1)};
ok($@, 'setArray throws exception with bad argument');


# test getArray throws exception with argument
eval {$hybridization->getArray(1)};
ok($@, 'getArray throws exception with argument');

# test setArray throws exception with no argument
eval {$hybridization->setArray()};
ok($@, 'setArray throws exception with no argument');

# test setArray throws exception with too many argument
eval {$hybridization->setArray(1,2)};
ok($@, 'setArray throws exception with too many argument');

# test setArray accepts undef
eval {$hybridization->setArray(undef)};
ok((!$@ and not defined $hybridization->getArray()),
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


ok((UNIVERSAL::isa($hybridization->getDescriptions,'ARRAY')
 and scalar @{$hybridization->getDescriptions} == 1
 and UNIVERSAL::isa($hybridization->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($hybridization->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($hybridization->getDescriptions,'ARRAY')
 and scalar @{$hybridization->getDescriptions} == 1
 and $hybridization->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($hybridization->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($hybridization->getDescriptions,'ARRAY')
 and scalar @{$hybridization->getDescriptions} == 2
 and $hybridization->getDescriptions->[0] == $descriptions_assn
 and $hybridization->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$hybridization->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$hybridization->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$hybridization->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$hybridization->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$hybridization->setDescriptions([])};
ok((!$@ and defined $hybridization->getDescriptions()
    and UNIVERSAL::isa($hybridization->getDescriptions, 'ARRAY')
    and scalar @{$hybridization->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$hybridization->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$hybridization->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$hybridization->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$hybridization->setDescriptions(undef)};
ok((!$@ and not defined $hybridization->getDescriptions()),
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


isa_ok($hybridization->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($hybridization->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($hybridization->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$hybridization->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$hybridization->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$hybridization->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$hybridization->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$hybridization->setSecurity(undef)};
ok((!$@ and not defined $hybridization->getSecurity()),
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


isa_ok($hybridization->getPhysicalBioAssayTarget, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);

is($hybridization->setPhysicalBioAssayTarget($physicalbioassaytarget_assn), $physicalbioassaytarget_assn,
  'setPhysicalBioAssayTarget returns value');

ok($hybridization->getPhysicalBioAssayTarget() == $physicalbioassaytarget_assn,
   'getPhysicalBioAssayTarget fetches correct value');

# test setPhysicalBioAssayTarget throws exception with bad argument
eval {$hybridization->setPhysicalBioAssayTarget(1)};
ok($@, 'setPhysicalBioAssayTarget throws exception with bad argument');


# test getPhysicalBioAssayTarget throws exception with argument
eval {$hybridization->getPhysicalBioAssayTarget(1)};
ok($@, 'getPhysicalBioAssayTarget throws exception with argument');

# test setPhysicalBioAssayTarget throws exception with no argument
eval {$hybridization->setPhysicalBioAssayTarget()};
ok($@, 'setPhysicalBioAssayTarget throws exception with no argument');

# test setPhysicalBioAssayTarget throws exception with too many argument
eval {$hybridization->setPhysicalBioAssayTarget(1,2)};
ok($@, 'setPhysicalBioAssayTarget throws exception with too many argument');

# test setPhysicalBioAssayTarget accepts undef
eval {$hybridization->setPhysicalBioAssayTarget(undef)};
ok((!$@ and not defined $hybridization->getPhysicalBioAssayTarget()),
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





my $bioassaycreation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioassaycreation = Bio::MAGE::BioAssay::BioAssayCreation->new();
}

# testing superclass BioAssayCreation
isa_ok($bioassaycreation, q[Bio::MAGE::BioAssay::BioAssayCreation]);
isa_ok($hybridization, q[Bio::MAGE::BioAssay::BioAssayCreation]);

