##############################
#
# BioAssayData.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayData.t`

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
use Test::More tests => 163;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioAssayData') };

use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::BioAssayDimension;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::BioAssayData::BioDataValues;
use Bio::MAGE::Description::Description;

use Bio::MAGE::BioAssayData::DerivedBioAssayData;
use Bio::MAGE::BioAssayData::MeasuredBioAssayData;

# we test the new() method
my $bioassaydata;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydata = Bio::MAGE::BioAssayData::BioAssayData->new();
}
isa_ok($bioassaydata, 'Bio::MAGE::BioAssayData::BioAssayData');

# test the package_name class method
is($bioassaydata->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($bioassaydata->class_name(), q[Bio::MAGE::BioAssayData::BioAssayData],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydata = Bio::MAGE::BioAssayData::BioAssayData->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaydata->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaydata->setIdentifier('1');
is($bioassaydata->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaydata->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydata->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydata->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydata->setIdentifier(undef)};
ok((!$@ and not defined $bioassaydata->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaydata->getName(), '2',
  'name new');

# test getter/setter
$bioassaydata->setName('2');
is($bioassaydata->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaydata->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydata->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydata->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydata->setName(undef)};
ok((!$@ and not defined $bioassaydata->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioAssayData->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydata = Bio::MAGE::BioAssayData::BioAssayData->new(bioAssayDimension => Bio::MAGE::BioAssayData::BioAssayDimension->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
summaryStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
designElementDimension => Bio::MAGE::BioAssayData::DesignElementDimension->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
bioDataValues => Bio::MAGE::BioAssayData::BioDataValues->new(),
quantitationTypeDimension => Bio::MAGE::BioAssayData::QuantitationTypeDimension->new());
}

my ($end, $assn);


# testing association bioAssayDimension
my $bioassaydimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension_assn = Bio::MAGE::BioAssayData::BioAssayDimension->new();
}


isa_ok($bioassaydata->getBioAssayDimension, q[Bio::MAGE::BioAssayData::BioAssayDimension]);

is($bioassaydata->setBioAssayDimension($bioassaydimension_assn), $bioassaydimension_assn,
  'setBioAssayDimension returns value');

ok($bioassaydata->getBioAssayDimension() == $bioassaydimension_assn,
   'getBioAssayDimension fetches correct value');

# test setBioAssayDimension throws exception with bad argument
eval {$bioassaydata->setBioAssayDimension(1)};
ok($@, 'setBioAssayDimension throws exception with bad argument');


# test getBioAssayDimension throws exception with argument
eval {$bioassaydata->getBioAssayDimension(1)};
ok($@, 'getBioAssayDimension throws exception with argument');

# test setBioAssayDimension throws exception with no argument
eval {$bioassaydata->setBioAssayDimension()};
ok($@, 'setBioAssayDimension throws exception with no argument');

# test setBioAssayDimension throws exception with too many argument
eval {$bioassaydata->setBioAssayDimension(1,2)};
ok($@, 'setBioAssayDimension throws exception with too many argument');

# test setBioAssayDimension accepts undef
eval {$bioassaydata->setBioAssayDimension(undef)};
ok((!$@ and not defined $bioassaydata->getBioAssayDimension()),
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


ok((UNIVERSAL::isa($bioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydata->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaydata->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaydata->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydata->getAuditTrail} == 1
 and $bioassaydata->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaydata->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaydata->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydata->getAuditTrail} == 2
 and $bioassaydata->getAuditTrail->[0] == $audittrail_assn
 and $bioassaydata->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaydata->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaydata->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaydata->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaydata->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaydata->setAuditTrail([])};
ok((!$@ and defined $bioassaydata->getAuditTrail()
    and UNIVERSAL::isa($bioassaydata->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaydata->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaydata->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaydata->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaydata->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaydata->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaydata->getAuditTrail()),
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


ok((UNIVERSAL::isa($bioassaydata->getPropertySets,'ARRAY')
 and scalar @{$bioassaydata->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaydata->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaydata->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaydata->getPropertySets,'ARRAY')
 and scalar @{$bioassaydata->getPropertySets} == 1
 and $bioassaydata->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaydata->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaydata->getPropertySets,'ARRAY')
 and scalar @{$bioassaydata->getPropertySets} == 2
 and $bioassaydata->getPropertySets->[0] == $propertysets_assn
 and $bioassaydata->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaydata->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaydata->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaydata->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaydata->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaydata->setPropertySets([])};
ok((!$@ and defined $bioassaydata->getPropertySets()
    and UNIVERSAL::isa($bioassaydata->getPropertySets, 'ARRAY')
    and scalar @{$bioassaydata->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaydata->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaydata->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaydata->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaydata->setPropertySets(undef)};
ok((!$@ and not defined $bioassaydata->getPropertySets()),
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


ok((UNIVERSAL::isa($bioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$bioassaydata->getSummaryStatistics} == 1
 and UNIVERSAL::isa($bioassaydata->getSummaryStatistics->[0], q[Bio::MAGE::NameValueType])),
  'summaryStatistics set in new()');

ok(eq_array($bioassaydata->setSummaryStatistics([$summarystatistics_assn]), [$summarystatistics_assn]),
   'setSummaryStatistics returns correct value');

ok((UNIVERSAL::isa($bioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$bioassaydata->getSummaryStatistics} == 1
 and $bioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn),
   'getSummaryStatistics fetches correct value');

is($bioassaydata->addSummaryStatistics($summarystatistics_assn), 2,
  'addSummaryStatistics returns number of items in list');

ok((UNIVERSAL::isa($bioassaydata->getSummaryStatistics,'ARRAY')
 and scalar @{$bioassaydata->getSummaryStatistics} == 2
 and $bioassaydata->getSummaryStatistics->[0] == $summarystatistics_assn
 and $bioassaydata->getSummaryStatistics->[1] == $summarystatistics_assn),
  'addSummaryStatistics adds correct value');

# test setSummaryStatistics throws exception with non-array argument
eval {$bioassaydata->setSummaryStatistics(1)};
ok($@, 'setSummaryStatistics throws exception with non-array argument');

# test setSummaryStatistics throws exception with bad argument array
eval {$bioassaydata->setSummaryStatistics([1])};
ok($@, 'setSummaryStatistics throws exception with bad argument array');

# test addSummaryStatistics throws exception with no arguments
eval {$bioassaydata->addSummaryStatistics()};
ok($@, 'addSummaryStatistics throws exception with no arguments');

# test addSummaryStatistics throws exception with bad argument
eval {$bioassaydata->addSummaryStatistics(1)};
ok($@, 'addSummaryStatistics throws exception with bad array');

# test setSummaryStatistics accepts empty array ref
eval {$bioassaydata->setSummaryStatistics([])};
ok((!$@ and defined $bioassaydata->getSummaryStatistics()
    and UNIVERSAL::isa($bioassaydata->getSummaryStatistics, 'ARRAY')
    and scalar @{$bioassaydata->getSummaryStatistics} == 0),
   'setSummaryStatistics accepts empty array ref');


# test getSummaryStatistics throws exception with argument
eval {$bioassaydata->getSummaryStatistics(1)};
ok($@, 'getSummaryStatistics throws exception with argument');

# test setSummaryStatistics throws exception with no argument
eval {$bioassaydata->setSummaryStatistics()};
ok($@, 'setSummaryStatistics throws exception with no argument');

# test setSummaryStatistics throws exception with too many argument
eval {$bioassaydata->setSummaryStatistics(1,2)};
ok($@, 'setSummaryStatistics throws exception with too many argument');

# test setSummaryStatistics accepts undef
eval {$bioassaydata->setSummaryStatistics(undef)};
ok((!$@ and not defined $bioassaydata->getSummaryStatistics()),
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


ok((UNIVERSAL::isa($bioassaydata->getDescriptions,'ARRAY')
 and scalar @{$bioassaydata->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaydata->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaydata->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaydata->getDescriptions,'ARRAY')
 and scalar @{$bioassaydata->getDescriptions} == 1
 and $bioassaydata->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaydata->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaydata->getDescriptions,'ARRAY')
 and scalar @{$bioassaydata->getDescriptions} == 2
 and $bioassaydata->getDescriptions->[0] == $descriptions_assn
 and $bioassaydata->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaydata->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaydata->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaydata->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaydata->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaydata->setDescriptions([])};
ok((!$@ and defined $bioassaydata->getDescriptions()
    and UNIVERSAL::isa($bioassaydata->getDescriptions, 'ARRAY')
    and scalar @{$bioassaydata->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaydata->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaydata->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaydata->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaydata->setDescriptions(undef)};
ok((!$@ and not defined $bioassaydata->getDescriptions()),
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


isa_ok($bioassaydata->getDesignElementDimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

is($bioassaydata->setDesignElementDimension($designelementdimension_assn), $designelementdimension_assn,
  'setDesignElementDimension returns value');

ok($bioassaydata->getDesignElementDimension() == $designelementdimension_assn,
   'getDesignElementDimension fetches correct value');

# test setDesignElementDimension throws exception with bad argument
eval {$bioassaydata->setDesignElementDimension(1)};
ok($@, 'setDesignElementDimension throws exception with bad argument');


# test getDesignElementDimension throws exception with argument
eval {$bioassaydata->getDesignElementDimension(1)};
ok($@, 'getDesignElementDimension throws exception with argument');

# test setDesignElementDimension throws exception with no argument
eval {$bioassaydata->setDesignElementDimension()};
ok($@, 'setDesignElementDimension throws exception with no argument');

# test setDesignElementDimension throws exception with too many argument
eval {$bioassaydata->setDesignElementDimension(1,2)};
ok($@, 'setDesignElementDimension throws exception with too many argument');

# test setDesignElementDimension accepts undef
eval {$bioassaydata->setDesignElementDimension(undef)};
ok((!$@ and not defined $bioassaydata->getDesignElementDimension()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($bioassaydata->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaydata->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaydata->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaydata->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaydata->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaydata->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaydata->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaydata->setSecurity(undef)};
ok((!$@ and not defined $bioassaydata->getSecurity()),
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


isa_ok($bioassaydata->getBioDataValues, q[Bio::MAGE::BioAssayData::BioDataValues]);

is($bioassaydata->setBioDataValues($biodatavalues_assn), $biodatavalues_assn,
  'setBioDataValues returns value');

ok($bioassaydata->getBioDataValues() == $biodatavalues_assn,
   'getBioDataValues fetches correct value');

# test setBioDataValues throws exception with bad argument
eval {$bioassaydata->setBioDataValues(1)};
ok($@, 'setBioDataValues throws exception with bad argument');


# test getBioDataValues throws exception with argument
eval {$bioassaydata->getBioDataValues(1)};
ok($@, 'getBioDataValues throws exception with argument');

# test setBioDataValues throws exception with no argument
eval {$bioassaydata->setBioDataValues()};
ok($@, 'setBioDataValues throws exception with no argument');

# test setBioDataValues throws exception with too many argument
eval {$bioassaydata->setBioDataValues(1,2)};
ok($@, 'setBioDataValues throws exception with too many argument');

# test setBioDataValues accepts undef
eval {$bioassaydata->setBioDataValues(undef)};
ok((!$@ and not defined $bioassaydata->getBioDataValues()),
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



# testing association quantitationTypeDimension
my $quantitationtypedimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypedimension_assn = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new();
}


isa_ok($bioassaydata->getQuantitationTypeDimension, q[Bio::MAGE::BioAssayData::QuantitationTypeDimension]);

is($bioassaydata->setQuantitationTypeDimension($quantitationtypedimension_assn), $quantitationtypedimension_assn,
  'setQuantitationTypeDimension returns value');

ok($bioassaydata->getQuantitationTypeDimension() == $quantitationtypedimension_assn,
   'getQuantitationTypeDimension fetches correct value');

# test setQuantitationTypeDimension throws exception with bad argument
eval {$bioassaydata->setQuantitationTypeDimension(1)};
ok($@, 'setQuantitationTypeDimension throws exception with bad argument');


# test getQuantitationTypeDimension throws exception with argument
eval {$bioassaydata->getQuantitationTypeDimension(1)};
ok($@, 'getQuantitationTypeDimension throws exception with argument');

# test setQuantitationTypeDimension throws exception with no argument
eval {$bioassaydata->setQuantitationTypeDimension()};
ok($@, 'setQuantitationTypeDimension throws exception with no argument');

# test setQuantitationTypeDimension throws exception with too many argument
eval {$bioassaydata->setQuantitationTypeDimension(1,2)};
ok($@, 'setQuantitationTypeDimension throws exception with too many argument');

# test setQuantitationTypeDimension accepts undef
eval {$bioassaydata->setQuantitationTypeDimension(undef)};
ok((!$@ and not defined $bioassaydata->getQuantitationTypeDimension()),
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




# create a subclass
my $derivedbioassaydata = Bio::MAGE::BioAssayData::DerivedBioAssayData->new();

# testing subclass DerivedBioAssayData
isa_ok($derivedbioassaydata, q[Bio::MAGE::BioAssayData::DerivedBioAssayData]);
isa_ok($derivedbioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);


# create a subclass
my $measuredbioassaydata = Bio::MAGE::BioAssayData::MeasuredBioAssayData->new();

# testing subclass MeasuredBioAssayData
isa_ok($measuredbioassaydata, q[Bio::MAGE::BioAssayData::MeasuredBioAssayData]);
isa_ok($measuredbioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($bioassaydata, q[Bio::MAGE::Identifiable]);

