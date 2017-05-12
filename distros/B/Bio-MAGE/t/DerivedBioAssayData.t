##############################
#
# DerivedBioAssayData.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DerivedBioAssayData.t`

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
use Test::More tests => 172;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::DerivedBioAssayData') };

use Bio::MAGE::BioAssayData::Transformation;
use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::BioAssayDimension;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssayData::BioDataValues;
use Bio::MAGE::Description::Description;


# we test the new() method
my $derivedbioassaydata;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaydata = Bio::MAGE::BioAssayData::DerivedBioAssayData->new();
}
isa_ok($derivedbioassaydata, 'Bio::MAGE::BioAssayData::DerivedBioAssayData');

# test the package_name class method
is($derivedbioassaydata->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($derivedbioassaydata->class_name(), q[Bio::MAGE::BioAssayData::DerivedBioAssayData],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaydata = Bio::MAGE::BioAssayData::DerivedBioAssayData->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($derivedbioassaydata->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$derivedbioassaydata->setIdentifier('1');
is($derivedbioassaydata->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$derivedbioassaydata->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$derivedbioassaydata->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$derivedbioassaydata->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$derivedbioassaydata->setIdentifier(undef)};
ok((!$@ and not defined $derivedbioassaydata->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($derivedbioassaydata->getName(), '2',
  'name new');

# test getter/setter
$derivedbioassaydata->setName('2');
is($derivedbioassaydata->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$derivedbioassaydata->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$derivedbioassaydata->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$derivedbioassaydata->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$derivedbioassaydata->setName(undef)};
ok((!$@ and not defined $derivedbioassaydata->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::DerivedBioAssayData->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaydata = Bio::MAGE::BioAssayData::DerivedBioAssayData->new(producerTransformation => Bio::MAGE::BioAssayData::Transformation->new(),
bioAssayDimension => Bio::MAGE::BioAssayData::BioAssayDimension->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
summaryStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
designElementDimension => Bio::MAGE::BioAssayData::DesignElementDimension->new(),
quantitationTypeDimension => Bio::MAGE::BioAssayData::QuantitationTypeDimension->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
bioDataValues => Bio::MAGE::BioAssayData::BioDataValues->new());
}

my ($end, $assn);


# testing association producerTransformation
my $producertransformation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $producertransformation_assn = Bio::MAGE::BioAssayData::Transformation->new();
}


isa_ok($derivedbioassaydata->getProducerTransformation, q[Bio::MAGE::BioAssayData::Transformation]);

is($derivedbioassaydata->setProducerTransformation($producertransformation_assn), $producertransformation_assn,
  'setProducerTransformation returns value');

ok($derivedbioassaydata->getProducerTransformation() == $producertransformation_assn,
   'getProducerTransformation fetches correct value');

# test setProducerTransformation throws exception with bad argument
eval {$derivedbioassaydata->setProducerTransformation(1)};
ok($@, 'setProducerTransformation throws exception with bad argument');


# test getProducerTransformation throws exception with argument
eval {$derivedbioassaydata->getProducerTransformation(1)};
ok($@, 'getProducerTransformation throws exception with argument');

# test setProducerTransformation throws exception with no argument
eval {$derivedbioassaydata->setProducerTransformation()};
ok($@, 'setProducerTransformation throws exception with no argument');

# test setProducerTransformation throws exception with too many argument
eval {$derivedbioassaydata->setProducerTransformation(1,2)};
ok($@, 'setProducerTransformation throws exception with too many argument');

# test setProducerTransformation accepts undef
eval {$derivedbioassaydata->setProducerTransformation(undef)};
ok((!$@ and not defined $derivedbioassaydata->getProducerTransformation()),
   'setProducerTransformation accepts undef');

# test the meta-data for the assoication
$assn = $assns{producerTransformation};
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
   'producerTransformation->other() is a valid Bio::MAGE::Association::End'
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
   'producerTransformation->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssayDimension
my $bioassaydimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension_assn = Bio::MAGE::BioAssayData::BioAssayDimension->new();
}


isa_ok($derivedbioassaydata->getBioAssayDimension, q[Bio::MAGE::BioAssayData::BioAssayDimension]);

is($derivedbioassaydata->setBioAssayDimension($bioassaydimension_assn), $bioassaydimension_assn,
  'setBioAssayDimension returns value');

ok($derivedbioassaydata->getBioAssayDimension() == $bioassaydimension_assn,
   'getBioAssayDimension fetches correct value');

# test setBioAssayDimension throws exception with bad argument
eval {$derivedbioassaydata->setBioAssayDimension(1)};
ok($@, 'setBioAssayDimension throws exception with bad argument');


# test getBioAssayDimension throws exception with argument
eval {$derivedbioassaydata->getBioAssayDimension(1)};
ok($@, 'getBioAssayDimension throws exception with argument');

# test setBioAssayDimension throws exception with no argument
eval {$derivedbioassaydata->setBioAssayDimension()};
ok($@, 'setBioAssayDimension throws exception with no argument');

# test setBioAssayDimension throws exception with too many argument
eval {$derivedbioassaydata->setBioAssayDimension(1,2)};
ok($@, 'setBioAssayDimension throws exception with too many argument');

# test setBioAssayDimension accepts undef
eval {$derivedbioassaydata->setBioAssayDimension(undef)};
ok((!$@ and not defined $derivedbioassaydata->getBioAssayDimension()),
   'setBioAssayDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayDimension};
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
   'bioAssayDimension->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayDimension->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($derivedbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassaydata->getAuditTrail} == 1
 and UNIVERSAL::isa($derivedbioassaydata->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($derivedbioassaydata->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($derivedbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassaydata->getAuditTrail} == 1
 and $derivedbioassaydata->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($derivedbioassaydata->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassaydata->getAuditTrail} == 2
 and $derivedbioassaydata->getAuditTrail->[0] == $audittrail_assn
 and $derivedbioassaydata->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$derivedbioassaydata->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$derivedbioassaydata->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$derivedbioassaydata->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$derivedbioassaydata->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$derivedbioassaydata->setAuditTrail([])};
ok((!$@ and defined $derivedbioassaydata->getAuditTrail()
    and UNIVERSAL::isa($derivedbioassaydata->getAuditTrail, 'ARRAY')
    and scalar @{$derivedbioassaydata->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$derivedbioassaydata->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$derivedbioassaydata->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$derivedbioassaydata->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$derivedbioassaydata->setAuditTrail(undef)};
ok((!$@ and not defined $derivedbioassaydata->getAuditTrail()),
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


ok((UNIVERSAL::isa($derivedbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassaydata->getPropertySets} == 1
 and UNIVERSAL::isa($derivedbioassaydata->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($derivedbioassaydata->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($derivedbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassaydata->getPropertySets} == 1
 and $derivedbioassaydata->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($derivedbioassaydata->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassaydata->getPropertySets} == 2
 and $derivedbioassaydata->getPropertySets->[0] == $propertysets_assn
 and $derivedbioassaydata->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$derivedbioassaydata->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$derivedbioassaydata->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$derivedbioassaydata->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$derivedbioassaydata->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$derivedbioassaydata->setPropertySets([])};
ok((!$@ and defined $derivedbioassaydata->getPropertySets()
    and UNIVERSAL::isa($derivedbioassaydata->getPropertySets, 'ARRAY')
    and scalar @{$derivedbioassaydata->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$derivedbioassaydata->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$derivedbioassaydata->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$derivedbioassaydata->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$derivedbioassaydata->setPropertySets(undef)};
ok((!$@ and not defined $derivedbioassaydata->getPropertySets()),
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



# testing association summaryStatistics
my $summarystatistics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $summarystatistics_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($derivedbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$derivedbioassaydata->getSummaryStatistics} == 1
 and UNIVERSAL::isa($derivedbioassaydata->getSummaryStatistics->[0], q[Bio::MAGE::NameValueType])),
  'summaryStatistics set in new()');

ok(eq_array($derivedbioassaydata->setSummaryStatistics([$summarystatistics_assn]), [$summarystatistics_assn]),
   'setSummaryStatistics returns correct value');

ok((UNIVERSAL::isa($derivedbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$derivedbioassaydata->getSummaryStatistics} == 1
 and $derivedbioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn),
   'getSummaryStatistics fetches correct value');

is($derivedbioassaydata->addSummaryStatistics($summarystatistics_assn), 2,
  'addSummaryStatistics returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$derivedbioassaydata->getSummaryStatistics} == 2
 and $derivedbioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn
 and $derivedbioassaydata->getSummaryStatistics->[1] == $summarystatistics_assn),
  'addSummaryStatistics adds correct value');

# test setSummaryStatistics throws exception with non-array argument
eval {$derivedbioassaydata->setSummaryStatistics(1)};
ok($@, 'setSummaryStatistics throws exception with non-array argument');

# test setSummaryStatistics throws exception with bad argument array
eval {$derivedbioassaydata->setSummaryStatistics([1])};
ok($@, 'setSummaryStatistics throws exception with bad argument array');

# test addSummaryStatistics throws exception with no arguments
eval {$derivedbioassaydata->addSummaryStatistics()};
ok($@, 'addSummaryStatistics throws exception with no arguments');

# test addSummaryStatistics throws exception with bad argument
eval {$derivedbioassaydata->addSummaryStatistics(1)};
ok($@, 'addSummaryStatistics throws exception with bad array');

# test setSummaryStatistics accepts empty array ref
eval {$derivedbioassaydata->setSummaryStatistics([])};
ok((!$@ and defined $derivedbioassaydata->getSummaryStatistics()
    and UNIVERSAL::isa($derivedbioassaydata->getSummaryStatistics, 'ARRAY')
    and scalar @{$derivedbioassaydata->getSummaryStatistics} == 0),
   'setSummaryStatistics accepts empty array ref');


# test getSummaryStatistics throws exception with argument
eval {$derivedbioassaydata->getSummaryStatistics(1)};
ok($@, 'getSummaryStatistics throws exception with argument');

# test setSummaryStatistics throws exception with no argument
eval {$derivedbioassaydata->setSummaryStatistics()};
ok($@, 'setSummaryStatistics throws exception with no argument');

# test setSummaryStatistics throws exception with too many argument
eval {$derivedbioassaydata->setSummaryStatistics(1,2)};
ok($@, 'setSummaryStatistics throws exception with too many argument');

# test setSummaryStatistics accepts undef
eval {$derivedbioassaydata->setSummaryStatistics(undef)};
ok((!$@ and not defined $derivedbioassaydata->getSummaryStatistics()),
   'setSummaryStatistics accepts undef');

# test the meta-data for the assoication
$assn = $assns{summaryStatistics};
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
   'summaryStatistics->other() is a valid Bio::MAGE::Association::End'
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
   'summaryStatistics->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($derivedbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassaydata->getDescriptions} == 1
 and UNIVERSAL::isa($derivedbioassaydata->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($derivedbioassaydata->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($derivedbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassaydata->getDescriptions} == 1
 and $derivedbioassaydata->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($derivedbioassaydata->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassaydata->getDescriptions} == 2
 and $derivedbioassaydata->getDescriptions->[0] == $descriptions_assn
 and $derivedbioassaydata->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$derivedbioassaydata->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$derivedbioassaydata->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$derivedbioassaydata->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$derivedbioassaydata->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$derivedbioassaydata->setDescriptions([])};
ok((!$@ and defined $derivedbioassaydata->getDescriptions()
    and UNIVERSAL::isa($derivedbioassaydata->getDescriptions, 'ARRAY')
    and scalar @{$derivedbioassaydata->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$derivedbioassaydata->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$derivedbioassaydata->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$derivedbioassaydata->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$derivedbioassaydata->setDescriptions(undef)};
ok((!$@ and not defined $derivedbioassaydata->getDescriptions()),
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



# testing association designElementDimension
my $designelementdimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementdimension_assn = Bio::MAGE::BioAssayData::DesignElementDimension->new();
}


isa_ok($derivedbioassaydata->getDesignElementDimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

is($derivedbioassaydata->setDesignElementDimension($designelementdimension_assn), $designelementdimension_assn,
  'setDesignElementDimension returns value');

ok($derivedbioassaydata->getDesignElementDimension() == $designelementdimension_assn,
   'getDesignElementDimension fetches correct value');

# test setDesignElementDimension throws exception with bad argument
eval {$derivedbioassaydata->setDesignElementDimension(1)};
ok($@, 'setDesignElementDimension throws exception with bad argument');


# test getDesignElementDimension throws exception with argument
eval {$derivedbioassaydata->getDesignElementDimension(1)};
ok($@, 'getDesignElementDimension throws exception with argument');

# test setDesignElementDimension throws exception with no argument
eval {$derivedbioassaydata->setDesignElementDimension()};
ok($@, 'setDesignElementDimension throws exception with no argument');

# test setDesignElementDimension throws exception with too many argument
eval {$derivedbioassaydata->setDesignElementDimension(1,2)};
ok($@, 'setDesignElementDimension throws exception with too many argument');

# test setDesignElementDimension accepts undef
eval {$derivedbioassaydata->setDesignElementDimension(undef)};
ok((!$@ and not defined $derivedbioassaydata->getDesignElementDimension()),
   'setDesignElementDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{designElementDimension};
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
   'designElementDimension->other() is a valid Bio::MAGE::Association::End'
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
   'designElementDimension->self() is a valid Bio::MAGE::Association::End'
  );



# testing association quantitationTypeDimension
my $quantitationtypedimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypedimension_assn = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new();
}


isa_ok($derivedbioassaydata->getQuantitationTypeDimension, q[Bio::MAGE::BioAssayData::QuantitationTypeDimension]);

is($derivedbioassaydata->setQuantitationTypeDimension($quantitationtypedimension_assn), $quantitationtypedimension_assn,
  'setQuantitationTypeDimension returns value');

ok($derivedbioassaydata->getQuantitationTypeDimension() == $quantitationtypedimension_assn,
   'getQuantitationTypeDimension fetches correct value');

# test setQuantitationTypeDimension throws exception with bad argument
eval {$derivedbioassaydata->setQuantitationTypeDimension(1)};
ok($@, 'setQuantitationTypeDimension throws exception with bad argument');


# test getQuantitationTypeDimension throws exception with argument
eval {$derivedbioassaydata->getQuantitationTypeDimension(1)};
ok($@, 'getQuantitationTypeDimension throws exception with argument');

# test setQuantitationTypeDimension throws exception with no argument
eval {$derivedbioassaydata->setQuantitationTypeDimension()};
ok($@, 'setQuantitationTypeDimension throws exception with no argument');

# test setQuantitationTypeDimension throws exception with too many argument
eval {$derivedbioassaydata->setQuantitationTypeDimension(1,2)};
ok($@, 'setQuantitationTypeDimension throws exception with too many argument');

# test setQuantitationTypeDimension accepts undef
eval {$derivedbioassaydata->setQuantitationTypeDimension(undef)};
ok((!$@ and not defined $derivedbioassaydata->getQuantitationTypeDimension()),
   'setQuantitationTypeDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationTypeDimension};
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
   'quantitationTypeDimension->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationTypeDimension->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($derivedbioassaydata->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($derivedbioassaydata->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($derivedbioassaydata->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$derivedbioassaydata->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$derivedbioassaydata->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$derivedbioassaydata->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$derivedbioassaydata->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$derivedbioassaydata->setSecurity(undef)};
ok((!$@ and not defined $derivedbioassaydata->getSecurity()),
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



# testing association bioDataValues
my $biodatavalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatavalues_assn = Bio::MAGE::BioAssayData::BioDataValues->new();
}


isa_ok($derivedbioassaydata->getBioDataValues, q[Bio::MAGE::BioAssayData::BioDataValues]);

is($derivedbioassaydata->setBioDataValues($biodatavalues_assn), $biodatavalues_assn,
  'setBioDataValues returns value');

ok($derivedbioassaydata->getBioDataValues() == $biodatavalues_assn,
   'getBioDataValues fetches correct value');

# test setBioDataValues throws exception with bad argument
eval {$derivedbioassaydata->setBioDataValues(1)};
ok($@, 'setBioDataValues throws exception with bad argument');


# test getBioDataValues throws exception with argument
eval {$derivedbioassaydata->getBioDataValues(1)};
ok($@, 'getBioDataValues throws exception with argument');

# test setBioDataValues throws exception with no argument
eval {$derivedbioassaydata->setBioDataValues()};
ok($@, 'setBioDataValues throws exception with no argument');

# test setBioDataValues throws exception with too many argument
eval {$derivedbioassaydata->setBioDataValues(1,2)};
ok($@, 'setBioDataValues throws exception with too many argument');

# test setBioDataValues accepts undef
eval {$derivedbioassaydata->setBioDataValues(undef)};
ok((!$@ and not defined $derivedbioassaydata->getBioDataValues()),
   'setBioDataValues accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioDataValues};
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
   'bioDataValues->other() is a valid Bio::MAGE::Association::End'
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
   'bioDataValues->self() is a valid Bio::MAGE::Association::End'
  );





my $bioassaydata;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioassaydata = Bio::MAGE::BioAssayData::BioAssayData->new();
}

# testing superclass BioAssayData
isa_ok($bioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);
isa_ok($derivedbioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);

