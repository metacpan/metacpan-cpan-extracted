##############################
#
# Treatment.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Treatment.t`

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
use Test::More tests => 177;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::Treatment') };

use Bio::MAGE::BioMaterial::CompoundMeasurement;
use Bio::MAGE::Measurement::Measurement;
use Bio::MAGE::NameValueType;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::BioMaterial::BioMaterialMeasurement;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $treatment;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $treatment = Bio::MAGE::BioMaterial::Treatment->new();
}
isa_ok($treatment, 'Bio::MAGE::BioMaterial::Treatment');

# test the package_name class method
is($treatment->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($treatment->class_name(), q[Bio::MAGE::BioMaterial::Treatment],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $treatment = Bio::MAGE::BioMaterial::Treatment->new(identifier => '1',
order => '2',
name => '3');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($treatment->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$treatment->setIdentifier('1');
is($treatment->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$treatment->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$treatment->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$treatment->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$treatment->setIdentifier(undef)};
ok((!$@ and not defined $treatment->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute order
#

# test attribute values can be set in new()
is($treatment->getOrder(), '2',
  'order new');

# test getter/setter
$treatment->setOrder('2');
is($treatment->getOrder(), '2',
  'order getter/setter');

# test getter throws exception with argument
eval {$treatment->getOrder(1)};
ok($@, 'order getter throws exception with argument');

# test setter throws exception with no argument
eval {$treatment->setOrder()};
ok($@, 'order setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$treatment->setOrder('2', '2')};
ok($@, 'order setter throws exception with too many argument');

# test setter accepts undef
eval {$treatment->setOrder(undef)};
ok((!$@ and not defined $treatment->getOrder()),
   'order setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($treatment->getName(), '3',
  'name new');

# test getter/setter
$treatment->setName('3');
is($treatment->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$treatment->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$treatment->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$treatment->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$treatment->setName(undef)};
ok((!$@ and not defined $treatment->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::Treatment->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $treatment = Bio::MAGE::BioMaterial::Treatment->new(sourceBioMaterialMeasurements => [Bio::MAGE::BioMaterial::BioMaterialMeasurement->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
action => Bio::MAGE::Description::OntologyEntry->new(),
actionMeasurement => Bio::MAGE::Measurement::Measurement->new(),
compoundMeasurements => [Bio::MAGE::BioMaterial::CompoundMeasurement->new()]);
}

my ($end, $assn);


# testing association sourceBioMaterialMeasurements
my $sourcebiomaterialmeasurements_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sourcebiomaterialmeasurements_assn = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new();
}


ok((UNIVERSAL::isa($treatment->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$treatment->getSourceBioMaterialMeasurements} == 1
 and UNIVERSAL::isa($treatment->getSourceBioMaterialMeasurements->[0], q[Bio::MAGE::BioMaterial::BioMaterialMeasurement])),
  'sourceBioMaterialMeasurements set in new()');

ok(eq_array($treatment->setSourceBioMaterialMeasurements([$sourcebiomaterialmeasurements_assn]), [$sourcebiomaterialmeasurements_assn]),
   'setSourceBioMaterialMeasurements returns correct value');

ok((UNIVERSAL::isa($treatment->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$treatment->getSourceBioMaterialMeasurements} == 1
 and $treatment->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn),
   'getSourceBioMaterialMeasurements fetches correct value');

is($treatment->addSourceBioMaterialMeasurements($sourcebiomaterialmeasurements_assn), 2,
  'addSourceBioMaterialMeasurements returns number of items in list');

ok((UNIVERSAL::isa($treatment->getSourceBioMaterialMeasurements,'ARRAY')
 and scalar @{$treatment->getSourceBioMaterialMeasurements} == 2
 and $treatment->getSourceBioMaterialMeasurements->[0] == $sourcebiomaterialmeasurements_assn
 and $treatment->getSourceBioMaterialMeasurements->[1] == $sourcebiomaterialmeasurements_assn),
  'addSourceBioMaterialMeasurements adds correct value');

# test setSourceBioMaterialMeasurements throws exception with non-array argument
eval {$treatment->setSourceBioMaterialMeasurements(1)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with non-array argument');

# test setSourceBioMaterialMeasurements throws exception with bad argument array
eval {$treatment->setSourceBioMaterialMeasurements([1])};
ok($@, 'setSourceBioMaterialMeasurements throws exception with bad argument array');

# test addSourceBioMaterialMeasurements throws exception with no arguments
eval {$treatment->addSourceBioMaterialMeasurements()};
ok($@, 'addSourceBioMaterialMeasurements throws exception with no arguments');

# test addSourceBioMaterialMeasurements throws exception with bad argument
eval {$treatment->addSourceBioMaterialMeasurements(1)};
ok($@, 'addSourceBioMaterialMeasurements throws exception with bad array');

# test setSourceBioMaterialMeasurements accepts empty array ref
eval {$treatment->setSourceBioMaterialMeasurements([])};
ok((!$@ and defined $treatment->getSourceBioMaterialMeasurements()
    and UNIVERSAL::isa($treatment->getSourceBioMaterialMeasurements, 'ARRAY')
    and scalar @{$treatment->getSourceBioMaterialMeasurements} == 0),
   'setSourceBioMaterialMeasurements accepts empty array ref');


# test getSourceBioMaterialMeasurements throws exception with argument
eval {$treatment->getSourceBioMaterialMeasurements(1)};
ok($@, 'getSourceBioMaterialMeasurements throws exception with argument');

# test setSourceBioMaterialMeasurements throws exception with no argument
eval {$treatment->setSourceBioMaterialMeasurements()};
ok($@, 'setSourceBioMaterialMeasurements throws exception with no argument');

# test setSourceBioMaterialMeasurements throws exception with too many argument
eval {$treatment->setSourceBioMaterialMeasurements(1,2)};
ok($@, 'setSourceBioMaterialMeasurements throws exception with too many argument');

# test setSourceBioMaterialMeasurements accepts undef
eval {$treatment->setSourceBioMaterialMeasurements(undef)};
ok((!$@ and not defined $treatment->getSourceBioMaterialMeasurements()),
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


ok((UNIVERSAL::isa($treatment->getAuditTrail,'ARRAY')
 and scalar @{$treatment->getAuditTrail} == 1
 and UNIVERSAL::isa($treatment->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($treatment->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($treatment->getAuditTrail,'ARRAY')
 and scalar @{$treatment->getAuditTrail} == 1
 and $treatment->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($treatment->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($treatment->getAuditTrail,'ARRAY')
 and scalar @{$treatment->getAuditTrail} == 2
 and $treatment->getAuditTrail->[0] == $audittrail_assn
 and $treatment->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$treatment->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$treatment->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$treatment->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$treatment->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$treatment->setAuditTrail([])};
ok((!$@ and defined $treatment->getAuditTrail()
    and UNIVERSAL::isa($treatment->getAuditTrail, 'ARRAY')
    and scalar @{$treatment->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$treatment->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$treatment->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$treatment->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$treatment->setAuditTrail(undef)};
ok((!$@ and not defined $treatment->getAuditTrail()),
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


ok((UNIVERSAL::isa($treatment->getPropertySets,'ARRAY')
 and scalar @{$treatment->getPropertySets} == 1
 and UNIVERSAL::isa($treatment->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($treatment->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($treatment->getPropertySets,'ARRAY')
 and scalar @{$treatment->getPropertySets} == 1
 and $treatment->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($treatment->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($treatment->getPropertySets,'ARRAY')
 and scalar @{$treatment->getPropertySets} == 2
 and $treatment->getPropertySets->[0] == $propertysets_assn
 and $treatment->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$treatment->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$treatment->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$treatment->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$treatment->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$treatment->setPropertySets([])};
ok((!$@ and defined $treatment->getPropertySets()
    and UNIVERSAL::isa($treatment->getPropertySets, 'ARRAY')
    and scalar @{$treatment->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$treatment->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$treatment->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$treatment->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$treatment->setPropertySets(undef)};
ok((!$@ and not defined $treatment->getPropertySets()),
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


ok((UNIVERSAL::isa($treatment->getProtocolApplications,'ARRAY')
 and scalar @{$treatment->getProtocolApplications} == 1
 and UNIVERSAL::isa($treatment->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($treatment->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($treatment->getProtocolApplications,'ARRAY')
 and scalar @{$treatment->getProtocolApplications} == 1
 and $treatment->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($treatment->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($treatment->getProtocolApplications,'ARRAY')
 and scalar @{$treatment->getProtocolApplications} == 2
 and $treatment->getProtocolApplications->[0] == $protocolapplications_assn
 and $treatment->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$treatment->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$treatment->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$treatment->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$treatment->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$treatment->setProtocolApplications([])};
ok((!$@ and defined $treatment->getProtocolApplications()
    and UNIVERSAL::isa($treatment->getProtocolApplications, 'ARRAY')
    and scalar @{$treatment->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$treatment->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$treatment->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$treatment->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$treatment->setProtocolApplications(undef)};
ok((!$@ and not defined $treatment->getProtocolApplications()),
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


ok((UNIVERSAL::isa($treatment->getDescriptions,'ARRAY')
 and scalar @{$treatment->getDescriptions} == 1
 and UNIVERSAL::isa($treatment->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($treatment->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($treatment->getDescriptions,'ARRAY')
 and scalar @{$treatment->getDescriptions} == 1
 and $treatment->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($treatment->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($treatment->getDescriptions,'ARRAY')
 and scalar @{$treatment->getDescriptions} == 2
 and $treatment->getDescriptions->[0] == $descriptions_assn
 and $treatment->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$treatment->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$treatment->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$treatment->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$treatment->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$treatment->setDescriptions([])};
ok((!$@ and defined $treatment->getDescriptions()
    and UNIVERSAL::isa($treatment->getDescriptions, 'ARRAY')
    and scalar @{$treatment->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$treatment->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$treatment->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$treatment->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$treatment->setDescriptions(undef)};
ok((!$@ and not defined $treatment->getDescriptions()),
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


isa_ok($treatment->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($treatment->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($treatment->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$treatment->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$treatment->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$treatment->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$treatment->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$treatment->setSecurity(undef)};
ok((!$@ and not defined $treatment->getSecurity()),
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



# testing association action
my $action_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $action_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($treatment->getAction, q[Bio::MAGE::Description::OntologyEntry]);

is($treatment->setAction($action_assn), $action_assn,
  'setAction returns value');

ok($treatment->getAction() == $action_assn,
   'getAction fetches correct value');

# test setAction throws exception with bad argument
eval {$treatment->setAction(1)};
ok($@, 'setAction throws exception with bad argument');


# test getAction throws exception with argument
eval {$treatment->getAction(1)};
ok($@, 'getAction throws exception with argument');

# test setAction throws exception with no argument
eval {$treatment->setAction()};
ok($@, 'setAction throws exception with no argument');

# test setAction throws exception with too many argument
eval {$treatment->setAction(1,2)};
ok($@, 'setAction throws exception with too many argument');

# test setAction accepts undef
eval {$treatment->setAction(undef)};
ok((!$@ and not defined $treatment->getAction()),
   'setAction accepts undef');

# test the meta-data for the assoication
$assn = $assns{action};
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
   'action->other() is a valid Bio::MAGE::Association::End'
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
   'action->self() is a valid Bio::MAGE::Association::End'
  );



# testing association actionMeasurement
my $actionmeasurement_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $actionmeasurement_assn = Bio::MAGE::Measurement::Measurement->new();
}


isa_ok($treatment->getActionMeasurement, q[Bio::MAGE::Measurement::Measurement]);

is($treatment->setActionMeasurement($actionmeasurement_assn), $actionmeasurement_assn,
  'setActionMeasurement returns value');

ok($treatment->getActionMeasurement() == $actionmeasurement_assn,
   'getActionMeasurement fetches correct value');

# test setActionMeasurement throws exception with bad argument
eval {$treatment->setActionMeasurement(1)};
ok($@, 'setActionMeasurement throws exception with bad argument');


# test getActionMeasurement throws exception with argument
eval {$treatment->getActionMeasurement(1)};
ok($@, 'getActionMeasurement throws exception with argument');

# test setActionMeasurement throws exception with no argument
eval {$treatment->setActionMeasurement()};
ok($@, 'setActionMeasurement throws exception with no argument');

# test setActionMeasurement throws exception with too many argument
eval {$treatment->setActionMeasurement(1,2)};
ok($@, 'setActionMeasurement throws exception with too many argument');

# test setActionMeasurement accepts undef
eval {$treatment->setActionMeasurement(undef)};
ok((!$@ and not defined $treatment->getActionMeasurement()),
   'setActionMeasurement accepts undef');

# test the meta-data for the assoication
$assn = $assns{actionMeasurement};
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
   'actionMeasurement->other() is a valid Bio::MAGE::Association::End'
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
   'actionMeasurement->self() is a valid Bio::MAGE::Association::End'
  );



# testing association compoundMeasurements
my $compoundmeasurements_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compoundmeasurements_assn = Bio::MAGE::BioMaterial::CompoundMeasurement->new();
}


ok((UNIVERSAL::isa($treatment->getCompoundMeasurements,'ARRAY')
 and scalar @{$treatment->getCompoundMeasurements} == 1
 and UNIVERSAL::isa($treatment->getCompoundMeasurements->[0], q[Bio::MAGE::BioMaterial::CompoundMeasurement])),
  'compoundMeasurements set in new()');

ok(eq_array($treatment->setCompoundMeasurements([$compoundmeasurements_assn]), [$compoundmeasurements_assn]),
   'setCompoundMeasurements returns correct value');

ok((UNIVERSAL::isa($treatment->getCompoundMeasurements,'ARRAY')
 and scalar @{$treatment->getCompoundMeasurements} == 1
 and $treatment->getCompoundMeasurements->[0] == $compoundmeasurements_assn),
   'getCompoundMeasurements fetches correct value');

is($treatment->addCompoundMeasurements($compoundmeasurements_assn), 2,
  'addCompoundMeasurements returns number of items in list');

ok((UNIVERSAL::isa($treatment->getCompoundMeasurements,'ARRAY')
 and scalar @{$treatment->getCompoundMeasurements} == 2
 and $treatment->getCompoundMeasurements->[0] == $compoundmeasurements_assn
 and $treatment->getCompoundMeasurements->[1] == $compoundmeasurements_assn),
  'addCompoundMeasurements adds correct value');

# test setCompoundMeasurements throws exception with non-array argument
eval {$treatment->setCompoundMeasurements(1)};
ok($@, 'setCompoundMeasurements throws exception with non-array argument');

# test setCompoundMeasurements throws exception with bad argument array
eval {$treatment->setCompoundMeasurements([1])};
ok($@, 'setCompoundMeasurements throws exception with bad argument array');

# test addCompoundMeasurements throws exception with no arguments
eval {$treatment->addCompoundMeasurements()};
ok($@, 'addCompoundMeasurements throws exception with no arguments');

# test addCompoundMeasurements throws exception with bad argument
eval {$treatment->addCompoundMeasurements(1)};
ok($@, 'addCompoundMeasurements throws exception with bad array');

# test setCompoundMeasurements accepts empty array ref
eval {$treatment->setCompoundMeasurements([])};
ok((!$@ and defined $treatment->getCompoundMeasurements()
    and UNIVERSAL::isa($treatment->getCompoundMeasurements, 'ARRAY')
    and scalar @{$treatment->getCompoundMeasurements} == 0),
   'setCompoundMeasurements accepts empty array ref');


# test getCompoundMeasurements throws exception with argument
eval {$treatment->getCompoundMeasurements(1)};
ok($@, 'getCompoundMeasurements throws exception with argument');

# test setCompoundMeasurements throws exception with no argument
eval {$treatment->setCompoundMeasurements()};
ok($@, 'setCompoundMeasurements throws exception with no argument');

# test setCompoundMeasurements throws exception with too many argument
eval {$treatment->setCompoundMeasurements(1,2)};
ok($@, 'setCompoundMeasurements throws exception with too many argument');

# test setCompoundMeasurements accepts undef
eval {$treatment->setCompoundMeasurements(undef)};
ok((!$@ and not defined $treatment->getCompoundMeasurements()),
   'setCompoundMeasurements accepts undef');

# test the meta-data for the assoication
$assn = $assns{compoundMeasurements};
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
   'compoundMeasurements->other() is a valid Bio::MAGE::Association::End'
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
   'compoundMeasurements->self() is a valid Bio::MAGE::Association::End'
  );





my $bioevent;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioevent = Bio::MAGE::BioEvent::BioEvent->new();
}

# testing superclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($treatment, q[Bio::MAGE::BioEvent::BioEvent]);

