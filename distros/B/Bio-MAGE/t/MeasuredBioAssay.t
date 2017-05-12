##############################
#
# MeasuredBioAssay.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MeasuredBioAssay.t`

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
use Test::More tests => 158;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::MeasuredBioAssay') };

use Bio::MAGE::BioAssayData::MeasuredBioAssayData;
use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssay::FeatureExtraction;
use Bio::MAGE::Description::Description;


# we test the new() method
my $measuredbioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassay = Bio::MAGE::BioAssay::MeasuredBioAssay->new();
}
isa_ok($measuredbioassay, 'Bio::MAGE::BioAssay::MeasuredBioAssay');

# test the package_name class method
is($measuredbioassay->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($measuredbioassay->class_name(), q[Bio::MAGE::BioAssay::MeasuredBioAssay],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassay = Bio::MAGE::BioAssay::MeasuredBioAssay->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($measuredbioassay->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$measuredbioassay->setIdentifier('1');
is($measuredbioassay->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$measuredbioassay->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$measuredbioassay->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measuredbioassay->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$measuredbioassay->setIdentifier(undef)};
ok((!$@ and not defined $measuredbioassay->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($measuredbioassay->getName(), '2',
  'name new');

# test getter/setter
$measuredbioassay->setName('2');
is($measuredbioassay->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$measuredbioassay->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$measuredbioassay->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measuredbioassay->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$measuredbioassay->setName(undef)};
ok((!$@ and not defined $measuredbioassay->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::MeasuredBioAssay->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassay = Bio::MAGE::BioAssay::MeasuredBioAssay->new(channels => [Bio::MAGE::BioAssay::Channel->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
bioAssayFactorValues => [Bio::MAGE::Experiment::FactorValue->new()],
featureExtraction => Bio::MAGE::BioAssay::FeatureExtraction->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
measuredBioAssayData => [Bio::MAGE::BioAssayData::MeasuredBioAssayData->new()]);
}

my ($end, $assn);


# testing association channels
my $channels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channels_assn = Bio::MAGE::BioAssay::Channel->new();
}


ok((UNIVERSAL::isa($measuredbioassay->getChannels,'ARRAY')
 and scalar @{$measuredbioassay->getChannels} == 1
 and UNIVERSAL::isa($measuredbioassay->getChannels->[0], q[Bio::MAGE::BioAssay::Channel])),
  'channels set in new()');

ok(eq_array($measuredbioassay->setChannels([$channels_assn]), [$channels_assn]),
   'setChannels returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getChannels,'ARRAY')
 and scalar @{$measuredbioassay->getChannels} == 1
 and $measuredbioassay->getChannels->[0] == $channels_assn),
   'getChannels fetches correct value');

is($measuredbioassay->addChannels($channels_assn), 2,
  'addChannels returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getChannels,'ARRAY')
 and scalar @{$measuredbioassay->getChannels} == 2
 and $measuredbioassay->getChannels->[0] == $channels_assn
 and $measuredbioassay->getChannels->[1] == $channels_assn),
  'addChannels adds correct value');

# test setChannels throws exception with non-array argument
eval {$measuredbioassay->setChannels(1)};
ok($@, 'setChannels throws exception with non-array argument');

# test setChannels throws exception with bad argument array
eval {$measuredbioassay->setChannels([1])};
ok($@, 'setChannels throws exception with bad argument array');

# test addChannels throws exception with no arguments
eval {$measuredbioassay->addChannels()};
ok($@, 'addChannels throws exception with no arguments');

# test addChannels throws exception with bad argument
eval {$measuredbioassay->addChannels(1)};
ok($@, 'addChannels throws exception with bad array');

# test setChannels accepts empty array ref
eval {$measuredbioassay->setChannels([])};
ok((!$@ and defined $measuredbioassay->getChannels()
    and UNIVERSAL::isa($measuredbioassay->getChannels, 'ARRAY')
    and scalar @{$measuredbioassay->getChannels} == 0),
   'setChannels accepts empty array ref');


# test getChannels throws exception with argument
eval {$measuredbioassay->getChannels(1)};
ok($@, 'getChannels throws exception with argument');

# test setChannels throws exception with no argument
eval {$measuredbioassay->setChannels()};
ok($@, 'setChannels throws exception with no argument');

# test setChannels throws exception with too many argument
eval {$measuredbioassay->setChannels(1,2)};
ok($@, 'setChannels throws exception with too many argument');

# test setChannels accepts undef
eval {$measuredbioassay->setChannels(undef)};
ok((!$@ and not defined $measuredbioassay->getChannels()),
   'setChannels accepts undef');

# test the meta-data for the assoication
$assn = $assns{channels};
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
   'channels->other() is a valid Bio::MAGE::Association::End'
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
   'channels->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($measuredbioassay->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassay->getAuditTrail} == 1
 and UNIVERSAL::isa($measuredbioassay->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($measuredbioassay->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassay->getAuditTrail} == 1
 and $measuredbioassay->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($measuredbioassay->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getAuditTrail,'ARRAY')
 and scalar @{$measuredbioassay->getAuditTrail} == 2
 and $measuredbioassay->getAuditTrail->[0] == $audittrail_assn
 and $measuredbioassay->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$measuredbioassay->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$measuredbioassay->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$measuredbioassay->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$measuredbioassay->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$measuredbioassay->setAuditTrail([])};
ok((!$@ and defined $measuredbioassay->getAuditTrail()
    and UNIVERSAL::isa($measuredbioassay->getAuditTrail, 'ARRAY')
    and scalar @{$measuredbioassay->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$measuredbioassay->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$measuredbioassay->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$measuredbioassay->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$measuredbioassay->setAuditTrail(undef)};
ok((!$@ and not defined $measuredbioassay->getAuditTrail()),
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


ok((UNIVERSAL::isa($measuredbioassay->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassay->getPropertySets} == 1
 and UNIVERSAL::isa($measuredbioassay->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($measuredbioassay->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassay->getPropertySets} == 1
 and $measuredbioassay->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($measuredbioassay->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getPropertySets,'ARRAY')
 and scalar @{$measuredbioassay->getPropertySets} == 2
 and $measuredbioassay->getPropertySets->[0] == $propertysets_assn
 and $measuredbioassay->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$measuredbioassay->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$measuredbioassay->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$measuredbioassay->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$measuredbioassay->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$measuredbioassay->setPropertySets([])};
ok((!$@ and defined $measuredbioassay->getPropertySets()
    and UNIVERSAL::isa($measuredbioassay->getPropertySets, 'ARRAY')
    and scalar @{$measuredbioassay->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$measuredbioassay->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$measuredbioassay->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$measuredbioassay->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$measuredbioassay->setPropertySets(undef)};
ok((!$@ and not defined $measuredbioassay->getPropertySets()),
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



# testing association bioAssayFactorValues
my $bioassayfactorvalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassayfactorvalues_assn = Bio::MAGE::Experiment::FactorValue->new();
}


ok((UNIVERSAL::isa($measuredbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$measuredbioassay->getBioAssayFactorValues} == 1
 and UNIVERSAL::isa($measuredbioassay->getBioAssayFactorValues->[0], q[Bio::MAGE::Experiment::FactorValue])),
  'bioAssayFactorValues set in new()');

ok(eq_array($measuredbioassay->setBioAssayFactorValues([$bioassayfactorvalues_assn]), [$bioassayfactorvalues_assn]),
   'setBioAssayFactorValues returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$measuredbioassay->getBioAssayFactorValues} == 1
 and $measuredbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn),
   'getBioAssayFactorValues fetches correct value');

is($measuredbioassay->addBioAssayFactorValues($bioassayfactorvalues_assn), 2,
  'addBioAssayFactorValues returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$measuredbioassay->getBioAssayFactorValues} == 2
 and $measuredbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn
 and $measuredbioassay->getBioAssayFactorValues->[1] == $bioassayfactorvalues_assn),
  'addBioAssayFactorValues adds correct value');

# test setBioAssayFactorValues throws exception with non-array argument
eval {$measuredbioassay->setBioAssayFactorValues(1)};
ok($@, 'setBioAssayFactorValues throws exception with non-array argument');

# test setBioAssayFactorValues throws exception with bad argument array
eval {$measuredbioassay->setBioAssayFactorValues([1])};
ok($@, 'setBioAssayFactorValues throws exception with bad argument array');

# test addBioAssayFactorValues throws exception with no arguments
eval {$measuredbioassay->addBioAssayFactorValues()};
ok($@, 'addBioAssayFactorValues throws exception with no arguments');

# test addBioAssayFactorValues throws exception with bad argument
eval {$measuredbioassay->addBioAssayFactorValues(1)};
ok($@, 'addBioAssayFactorValues throws exception with bad array');

# test setBioAssayFactorValues accepts empty array ref
eval {$measuredbioassay->setBioAssayFactorValues([])};
ok((!$@ and defined $measuredbioassay->getBioAssayFactorValues()
    and UNIVERSAL::isa($measuredbioassay->getBioAssayFactorValues, 'ARRAY')
    and scalar @{$measuredbioassay->getBioAssayFactorValues} == 0),
   'setBioAssayFactorValues accepts empty array ref');


# test getBioAssayFactorValues throws exception with argument
eval {$measuredbioassay->getBioAssayFactorValues(1)};
ok($@, 'getBioAssayFactorValues throws exception with argument');

# test setBioAssayFactorValues throws exception with no argument
eval {$measuredbioassay->setBioAssayFactorValues()};
ok($@, 'setBioAssayFactorValues throws exception with no argument');

# test setBioAssayFactorValues throws exception with too many argument
eval {$measuredbioassay->setBioAssayFactorValues(1,2)};
ok($@, 'setBioAssayFactorValues throws exception with too many argument');

# test setBioAssayFactorValues accepts undef
eval {$measuredbioassay->setBioAssayFactorValues(undef)};
ok((!$@ and not defined $measuredbioassay->getBioAssayFactorValues()),
   'setBioAssayFactorValues accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayFactorValues};
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
   'bioAssayFactorValues->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayFactorValues->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureExtraction
my $featureextraction_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureextraction_assn = Bio::MAGE::BioAssay::FeatureExtraction->new();
}


isa_ok($measuredbioassay->getFeatureExtraction, q[Bio::MAGE::BioAssay::FeatureExtraction]);

is($measuredbioassay->setFeatureExtraction($featureextraction_assn), $featureextraction_assn,
  'setFeatureExtraction returns value');

ok($measuredbioassay->getFeatureExtraction() == $featureextraction_assn,
   'getFeatureExtraction fetches correct value');

# test setFeatureExtraction throws exception with bad argument
eval {$measuredbioassay->setFeatureExtraction(1)};
ok($@, 'setFeatureExtraction throws exception with bad argument');


# test getFeatureExtraction throws exception with argument
eval {$measuredbioassay->getFeatureExtraction(1)};
ok($@, 'getFeatureExtraction throws exception with argument');

# test setFeatureExtraction throws exception with no argument
eval {$measuredbioassay->setFeatureExtraction()};
ok($@, 'setFeatureExtraction throws exception with no argument');

# test setFeatureExtraction throws exception with too many argument
eval {$measuredbioassay->setFeatureExtraction(1,2)};
ok($@, 'setFeatureExtraction throws exception with too many argument');

# test setFeatureExtraction accepts undef
eval {$measuredbioassay->setFeatureExtraction(undef)};
ok((!$@ and not defined $measuredbioassay->getFeatureExtraction()),
   'setFeatureExtraction accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureExtraction};
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
   'featureExtraction->other() is a valid Bio::MAGE::Association::End'
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
   'featureExtraction->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($measuredbioassay->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassay->getDescriptions} == 1
 and UNIVERSAL::isa($measuredbioassay->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($measuredbioassay->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassay->getDescriptions} == 1
 and $measuredbioassay->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($measuredbioassay->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getDescriptions,'ARRAY')
 and scalar @{$measuredbioassay->getDescriptions} == 2
 and $measuredbioassay->getDescriptions->[0] == $descriptions_assn
 and $measuredbioassay->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$measuredbioassay->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$measuredbioassay->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$measuredbioassay->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$measuredbioassay->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$measuredbioassay->setDescriptions([])};
ok((!$@ and defined $measuredbioassay->getDescriptions()
    and UNIVERSAL::isa($measuredbioassay->getDescriptions, 'ARRAY')
    and scalar @{$measuredbioassay->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$measuredbioassay->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$measuredbioassay->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$measuredbioassay->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$measuredbioassay->setDescriptions(undef)};
ok((!$@ and not defined $measuredbioassay->getDescriptions()),
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


isa_ok($measuredbioassay->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($measuredbioassay->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($measuredbioassay->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$measuredbioassay->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$measuredbioassay->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$measuredbioassay->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$measuredbioassay->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$measuredbioassay->setSecurity(undef)};
ok((!$@ and not defined $measuredbioassay->getSecurity()),
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



# testing association measuredBioAssayData
my $measuredbioassaydata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassaydata_assn = Bio::MAGE::BioAssayData::MeasuredBioAssayData->new();
}


ok((UNIVERSAL::isa($measuredbioassay->getMeasuredBioAssayData,'ARRAY')
 and scalar @{$measuredbioassay->getMeasuredBioAssayData} == 1
 and UNIVERSAL::isa($measuredbioassay->getMeasuredBioAssayData->[0], q[Bio::MAGE::BioAssayData::MeasuredBioAssayData])),
  'measuredBioAssayData set in new()');

ok(eq_array($measuredbioassay->setMeasuredBioAssayData([$measuredbioassaydata_assn]), [$measuredbioassaydata_assn]),
   'setMeasuredBioAssayData returns correct value');

ok((UNIVERSAL::isa($measuredbioassay->getMeasuredBioAssayData,'ARRAY')
 and scalar @{$measuredbioassay->getMeasuredBioAssayData} == 1
 and $measuredbioassay->getMeasuredBioAssayData->[0] == $measuredbioassaydata_assn),
   'getMeasuredBioAssayData fetches correct value');

is($measuredbioassay->addMeasuredBioAssayData($measuredbioassaydata_assn), 2,
  'addMeasuredBioAssayData returns number of items in list');

ok((UNIVERSAL::isa($measuredbioassay->getMeasuredBioAssayData,'ARRAY')
 and scalar @{$measuredbioassay->getMeasuredBioAssayData} == 2
 and $measuredbioassay->getMeasuredBioAssayData->[0] == $measuredbioassaydata_assn
 and $measuredbioassay->getMeasuredBioAssayData->[1] == $measuredbioassaydata_assn),
  'addMeasuredBioAssayData adds correct value');

# test setMeasuredBioAssayData throws exception with non-array argument
eval {$measuredbioassay->setMeasuredBioAssayData(1)};
ok($@, 'setMeasuredBioAssayData throws exception with non-array argument');

# test setMeasuredBioAssayData throws exception with bad argument array
eval {$measuredbioassay->setMeasuredBioAssayData([1])};
ok($@, 'setMeasuredBioAssayData throws exception with bad argument array');

# test addMeasuredBioAssayData throws exception with no arguments
eval {$measuredbioassay->addMeasuredBioAssayData()};
ok($@, 'addMeasuredBioAssayData throws exception with no arguments');

# test addMeasuredBioAssayData throws exception with bad argument
eval {$measuredbioassay->addMeasuredBioAssayData(1)};
ok($@, 'addMeasuredBioAssayData throws exception with bad array');

# test setMeasuredBioAssayData accepts empty array ref
eval {$measuredbioassay->setMeasuredBioAssayData([])};
ok((!$@ and defined $measuredbioassay->getMeasuredBioAssayData()
    and UNIVERSAL::isa($measuredbioassay->getMeasuredBioAssayData, 'ARRAY')
    and scalar @{$measuredbioassay->getMeasuredBioAssayData} == 0),
   'setMeasuredBioAssayData accepts empty array ref');


# test getMeasuredBioAssayData throws exception with argument
eval {$measuredbioassay->getMeasuredBioAssayData(1)};
ok($@, 'getMeasuredBioAssayData throws exception with argument');

# test setMeasuredBioAssayData throws exception with no argument
eval {$measuredbioassay->setMeasuredBioAssayData()};
ok($@, 'setMeasuredBioAssayData throws exception with no argument');

# test setMeasuredBioAssayData throws exception with too many argument
eval {$measuredbioassay->setMeasuredBioAssayData(1,2)};
ok($@, 'setMeasuredBioAssayData throws exception with too many argument');

# test setMeasuredBioAssayData accepts undef
eval {$measuredbioassay->setMeasuredBioAssayData(undef)};
ok((!$@ and not defined $measuredbioassay->getMeasuredBioAssayData()),
   'setMeasuredBioAssayData accepts undef');

# test the meta-data for the assoication
$assn = $assns{measuredBioAssayData};
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
   'measuredBioAssayData->other() is a valid Bio::MAGE::Association::End'
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
   'measuredBioAssayData->self() is a valid Bio::MAGE::Association::End'
  );





my $bioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioassay = Bio::MAGE::BioAssay::BioAssay->new();
}

# testing superclass BioAssay
isa_ok($bioassay, q[Bio::MAGE::BioAssay::BioAssay]);
isa_ok($measuredbioassay, q[Bio::MAGE::BioAssay::BioAssay]);

