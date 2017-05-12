##############################
#
# MeasuredBioAssayData.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MeasuredBioAssayData.t`

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
use Test::More tests => 159;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::MeasuredBioAssayData') };

use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::BioAssayDimension;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssayData::BioDataValues;
use Bio::MAGE::Description::Description;


# we test the new() method
my $measuredbioassaydata;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassaydata = Bio::MAGE::BioAssayData::MeasuredBioAssayData->new();
}
isa_ok($measuredbioassaydata, 'Bio::MAGE::BioAssayData::MeasuredBioAssayData');

# test the package_name class method
is($measuredbioassaydata->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($measuredbioassaydata->class_name(), q[Bio::MAGE::BioAssayData::MeasuredBioAssayData],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassaydata = Bio::MAGE::BioAssayData::MeasuredBioAssayData->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($measuredbioassaydata->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$measuredbioassaydata->setIdentifier('1');
is($measuredbioassaydata->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$measuredbioassaydata->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$measuredbioassaydata->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measuredbioassaydata->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$measuredbioassaydata->setIdentifier(undef)};
ok((!$@ and not defined $measuredbioassaydata->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($measuredbioassaydata->getName(), '2',
  'name new');

# test getter/setter
$measuredbioassaydata->setName('2');
is($measuredbioassaydata->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$measuredbioassaydata->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$measuredbioassaydata->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measuredbioassaydata->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$measuredbioassaydata->setName(undef)};
ok((!$@ and not defined $measuredbioassaydata->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::MeasuredBioAssayData->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassaydata = Bio::MAGE::BioAssayData::MeasuredBioAssayData->new(bioAssayDimension => Bio::MAGE::BioAssayData::BioAssayDimension->new(),
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


# testing association bioAssayDimension
my $bioassaydimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension_assn = Bio::MAGE::BioAssayData::BioAssayDimension->new();
}


isa_ok($measuredbioassaydata->getBioAssayDimension, q[Bio::MAGE::BioAssayData::BioAssayDimension]);

is($measuredbioassaydata->setBioAssayDimension($bioassaydimension_assn), $bioassaydimension_assn,
  'setBioAssayDimension returns value');

ok($measuredbioassaydata->getBioAssayDimension() == $bioassaydimension_assn,
   'getBioAssayDimension fetches correct value');

# test setBioAssayDimension throws exception with bad argument
eval {$measuredbioassaydata->setBioAssayDimension(1)};
ok($@, 'setBioAssayDimension throws exception with bad argument');


# test getBioAssayDimension throws exception with argument
eval {$measuredbioassaydata->getBioAssayDimension(1)};
ok($@, 'getBioAssayDimension throws exception with argument');

# test setBioAssayDimension throws exception with no argument
eval {$measuredbioassaydata->setBioAssayDimension()};
ok($@, 'setBioAssayDimension throws exception with no argument');

# test setBioAssayDimension throws exception with too many argument
eval {$measuredbioassaydata->setBioAssayDimension(1,2)};
ok($@, 'setBioAssayDimension throws exception with too many argument');

# test setBioAssayDimension accepts undef
eval {$measuredbioassaydata->setBioAssayDimension(undef)};
ok((!$@ and not defined $measuredbioassaydata->getBioAssayDimension()),
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


ok((UNIVERSAL::isa($measuredbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassaydata->getAuditTrail} == 1
 and UNIVERSAL::isa($measuredbioassaydata->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($measuredbioassaydata->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($measuredbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassaydata->getAuditTrail} == 1
 and $measuredbioassaydata->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($measuredbioassaydata->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassaydata->getAuditTrail} == 2
 and $measuredbioassaydata->getAuditTrail->[0] == $audittrail_assn
 and $measuredbioassaydata->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$measuredbioassaydata->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$measuredbioassaydata->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$measuredbioassaydata->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$measuredbioassaydata->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$measuredbioassaydata->setAuditTrail([])};
ok((!$@ and defined $measuredbioassaydata->getAuditTrail()
    and UNIVERSAL::isa($measuredbioassaydata->getAuditTrail, 'ARRAY')
    and scalar @{$measuredbioassaydata->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$measuredbioassaydata->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$measuredbioassaydata->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$measuredbioassaydata->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$measuredbioassaydata->setAuditTrail(undef)};
ok((!$@ and not defined $measuredbioassaydata->getAuditTrail()),
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


ok((UNIVERSAL::isa($measuredbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassaydata->getPropertySets} == 1
 and UNIVERSAL::isa($measuredbioassaydata->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($measuredbioassaydata->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($measuredbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassaydata->getPropertySets} == 1
 and $measuredbioassaydata->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($measuredbioassaydata->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassaydata->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassaydata->getPropertySets} == 2
 and $measuredbioassaydata->getPropertySets->[0] == $propertysets_assn
 and $measuredbioassaydata->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$measuredbioassaydata->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$measuredbioassaydata->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$measuredbioassaydata->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$measuredbioassaydata->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$measuredbioassaydata->setPropertySets([])};
ok((!$@ and defined $measuredbioassaydata->getPropertySets()
    and UNIVERSAL::isa($measuredbioassaydata->getPropertySets, 'ARRAY')
    and scalar @{$measuredbioassaydata->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$measuredbioassaydata->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$measuredbioassaydata->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$measuredbioassaydata->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$measuredbioassaydata->setPropertySets(undef)};
ok((!$@ and not defined $measuredbioassaydata->getPropertySets()),
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


ok((UNIVERSAL::isa($measuredbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$measuredbioassaydata->getSummaryStatistics} == 1
 and UNIVERSAL::isa($measuredbioassaydata->getSummaryStatistics->[0], q[Bio::MAGE::NameValueType])),
  'summaryStatistics set in new()');

ok(eq_array($measuredbioassaydata->setSummaryStatistics([$summarystatistics_assn]), [$summarystatistics_assn]),
   'setSummaryStatistics returns correct value');

ok((UNIVERSAL::isa($measuredbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$measuredbioassaydata->getSummaryStatistics} == 1
 and $measuredbioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn),
   'getSummaryStatistics fetches correct value');

is($measuredbioassaydata->addSummaryStatistics($summarystatistics_assn), 2,
  'addSummaryStatistics returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$measuredbioassaydata->getSummaryStatistics} == 2
 and $measuredbioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn
 and $measuredbioassaydata->getSummaryStatistics->[1] == $summarystatistics_assn),
  'addSummaryStatistics adds correct value');

# test setSummaryStatistics throws exception with non-array argument
eval {$measuredbioassaydata->setSummaryStatistics(1)};
ok($@, 'setSummaryStatistics throws exception with non-array argument');

# test setSummaryStatistics throws exception with bad argument array
eval {$measuredbioassaydata->setSummaryStatistics([1])};
ok($@, 'setSummaryStatistics throws exception with bad argument array');

# test addSummaryStatistics throws exception with no arguments
eval {$measuredbioassaydata->addSummaryStatistics()};
ok($@, 'addSummaryStatistics throws exception with no arguments');

# test addSummaryStatistics throws exception with bad argument
eval {$measuredbioassaydata->addSummaryStatistics(1)};
ok($@, 'addSummaryStatistics throws exception with bad array');

# test setSummaryStatistics accepts empty array ref
eval {$measuredbioassaydata->setSummaryStatistics([])};
ok((!$@ and defined $measuredbioassaydata->getSummaryStatistics()
    and UNIVERSAL::isa($measuredbioassaydata->getSummaryStatistics, 'ARRAY')
    and scalar @{$measuredbioassaydata->getSummaryStatistics} == 0),
   'setSummaryStatistics accepts empty array ref');


# test getSummaryStatistics throws exception with argument
eval {$measuredbioassaydata->getSummaryStatistics(1)};
ok($@, 'getSummaryStatistics throws exception with argument');

# test setSummaryStatistics throws exception with no argument
eval {$measuredbioassaydata->setSummaryStatistics()};
ok($@, 'setSummaryStatistics throws exception with no argument');

# test setSummaryStatistics throws exception with too many argument
eval {$measuredbioassaydata->setSummaryStatistics(1,2)};
ok($@, 'setSummaryStatistics throws exception with too many argument');

# test setSummaryStatistics accepts undef
eval {$measuredbioassaydata->setSummaryStatistics(undef)};
ok((!$@ and not defined $measuredbioassaydata->getSummaryStatistics()),
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


ok((UNIVERSAL::isa($measuredbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassaydata->getDescriptions} == 1
 and UNIVERSAL::isa($measuredbioassaydata->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($measuredbioassaydata->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($measuredbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassaydata->getDescriptions} == 1
 and $measuredbioassaydata->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($measuredbioassaydata->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassaydata->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassaydata->getDescriptions} == 2
 and $measuredbioassaydata->getDescriptions->[0] == $descriptions_assn
 and $measuredbioassaydata->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$measuredbioassaydata->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$measuredbioassaydata->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$measuredbioassaydata->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$measuredbioassaydata->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$measuredbioassaydata->setDescriptions([])};
ok((!$@ and defined $measuredbioassaydata->getDescriptions()
    and UNIVERSAL::isa($measuredbioassaydata->getDescriptions, 'ARRAY')
    and scalar @{$measuredbioassaydata->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$measuredbioassaydata->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$measuredbioassaydata->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$measuredbioassaydata->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$measuredbioassaydata->setDescriptions(undef)};
ok((!$@ and not defined $measuredbioassaydata->getDescriptions()),
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


isa_ok($measuredbioassaydata->getDesignElementDimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

is($measuredbioassaydata->setDesignElementDimension($designelementdimension_assn), $designelementdimension_assn,
  'setDesignElementDimension returns value');

ok($measuredbioassaydata->getDesignElementDimension() == $designelementdimension_assn,
   'getDesignElementDimension fetches correct value');

# test setDesignElementDimension throws exception with bad argument
eval {$measuredbioassaydata->setDesignElementDimension(1)};
ok($@, 'setDesignElementDimension throws exception with bad argument');


# test getDesignElementDimension throws exception with argument
eval {$measuredbioassaydata->getDesignElementDimension(1)};
ok($@, 'getDesignElementDimension throws exception with argument');

# test setDesignElementDimension throws exception with no argument
eval {$measuredbioassaydata->setDesignElementDimension()};
ok($@, 'setDesignElementDimension throws exception with no argument');

# test setDesignElementDimension throws exception with too many argument
eval {$measuredbioassaydata->setDesignElementDimension(1,2)};
ok($@, 'setDesignElementDimension throws exception with too many argument');

# test setDesignElementDimension accepts undef
eval {$measuredbioassaydata->setDesignElementDimension(undef)};
ok((!$@ and not defined $measuredbioassaydata->getDesignElementDimension()),
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


isa_ok($measuredbioassaydata->getQuantitationTypeDimension, q[Bio::MAGE::BioAssayData::QuantitationTypeDimension]);

is($measuredbioassaydata->setQuantitationTypeDimension($quantitationtypedimension_assn), $quantitationtypedimension_assn,
  'setQuantitationTypeDimension returns value');

ok($measuredbioassaydata->getQuantitationTypeDimension() == $quantitationtypedimension_assn,
   'getQuantitationTypeDimension fetches correct value');

# test setQuantitationTypeDimension throws exception with bad argument
eval {$measuredbioassaydata->setQuantitationTypeDimension(1)};
ok($@, 'setQuantitationTypeDimension throws exception with bad argument');


# test getQuantitationTypeDimension throws exception with argument
eval {$measuredbioassaydata->getQuantitationTypeDimension(1)};
ok($@, 'getQuantitationTypeDimension throws exception with argument');

# test setQuantitationTypeDimension throws exception with no argument
eval {$measuredbioassaydata->setQuantitationTypeDimension()};
ok($@, 'setQuantitationTypeDimension throws exception with no argument');

# test setQuantitationTypeDimension throws exception with too many argument
eval {$measuredbioassaydata->setQuantitationTypeDimension(1,2)};
ok($@, 'setQuantitationTypeDimension throws exception with too many argument');

# test setQuantitationTypeDimension accepts undef
eval {$measuredbioassaydata->setQuantitationTypeDimension(undef)};
ok((!$@ and not defined $measuredbioassaydata->getQuantitationTypeDimension()),
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


isa_ok($measuredbioassaydata->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($measuredbioassaydata->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($measuredbioassaydata->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$measuredbioassaydata->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$measuredbioassaydata->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$measuredbioassaydata->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$measuredbioassaydata->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$measuredbioassaydata->setSecurity(undef)};
ok((!$@ and not defined $measuredbioassaydata->getSecurity()),
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


isa_ok($measuredbioassaydata->getBioDataValues, q[Bio::MAGE::BioAssayData::BioDataValues]);

is($measuredbioassaydata->setBioDataValues($biodatavalues_assn), $biodatavalues_assn,
  'setBioDataValues returns value');

ok($measuredbioassaydata->getBioDataValues() == $biodatavalues_assn,
   'getBioDataValues fetches correct value');

# test setBioDataValues throws exception with bad argument
eval {$measuredbioassaydata->setBioDataValues(1)};
ok($@, 'setBioDataValues throws exception with bad argument');


# test getBioDataValues throws exception with argument
eval {$measuredbioassaydata->getBioDataValues(1)};
ok($@, 'getBioDataValues throws exception with argument');

# test setBioDataValues throws exception with no argument
eval {$measuredbioassaydata->setBioDataValues()};
ok($@, 'setBioDataValues throws exception with no argument');

# test setBioDataValues throws exception with too many argument
eval {$measuredbioassaydata->setBioDataValues(1,2)};
ok($@, 'setBioDataValues throws exception with too many argument');

# test setBioDataValues accepts undef
eval {$measuredbioassaydata->setBioDataValues(undef)};
ok((!$@ and not defined $measuredbioassaydata->getBioDataValues()),
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
isa_ok($measuredbioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);

