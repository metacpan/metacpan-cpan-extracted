##############################
#
# DerivedBioAssay.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DerivedBioAssay.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssay::DerivedBioAssay') };

use Bio::MAGE::BioAssayData::DerivedBioAssayData;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::BioAssayData::BioAssayMap;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $derivedbioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassay = Bio::MAGE::BioAssay::DerivedBioAssay->new();
}
isa_ok($derivedbioassay, 'Bio::MAGE::BioAssay::DerivedBioAssay');

# test the package_name class method
is($derivedbioassay->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($derivedbioassay->class_name(), q[Bio::MAGE::BioAssay::DerivedBioAssay],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassay = Bio::MAGE::BioAssay::DerivedBioAssay->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($derivedbioassay->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$derivedbioassay->setIdentifier('1');
is($derivedbioassay->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$derivedbioassay->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$derivedbioassay->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$derivedbioassay->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$derivedbioassay->setIdentifier(undef)};
ok((!$@ and not defined $derivedbioassay->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($derivedbioassay->getName(), '2',
  'name new');

# test getter/setter
$derivedbioassay->setName('2');
is($derivedbioassay->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$derivedbioassay->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$derivedbioassay->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$derivedbioassay->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$derivedbioassay->setName(undef)};
ok((!$@ and not defined $derivedbioassay->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::DerivedBioAssay->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassay = Bio::MAGE::BioAssay::DerivedBioAssay->new(channels => [Bio::MAGE::BioAssay::Channel->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
bioAssayFactorValues => [Bio::MAGE::Experiment::FactorValue->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
derivedBioAssayMap => [Bio::MAGE::BioAssayData::BioAssayMap->new()],
type => Bio::MAGE::Description::OntologyEntry->new(),
derivedBioAssayData => [Bio::MAGE::BioAssayData::DerivedBioAssayData->new()]);
}

my ($end, $assn);


# testing association channels
my $channels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channels_assn = Bio::MAGE::BioAssay::Channel->new();
}


ok((UNIVERSAL::isa($derivedbioassay->getChannels,'ARRAY')
 and scalar @{$derivedbioassay->getChannels} == 1
 and UNIVERSAL::isa($derivedbioassay->getChannels->[0], q[Bio::MAGE::BioAssay::Channel])),
  'channels set in new()');

ok(eq_array($derivedbioassay->setChannels([$channels_assn]), [$channels_assn]),
   'setChannels returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getChannels,'ARRAY')
 and scalar @{$derivedbioassay->getChannels} == 1
 and $derivedbioassay->getChannels->[0] == $channels_assn),
   'getChannels fetches correct value');

is($derivedbioassay->addChannels($channels_assn), 2,
  'addChannels returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getChannels,'ARRAY')
 and scalar @{$derivedbioassay->getChannels} == 2
 and $derivedbioassay->getChannels->[0] == $channels_assn
 and $derivedbioassay->getChannels->[1] == $channels_assn),
  'addChannels adds correct value');

# test setChannels throws exception with non-array argument
eval {$derivedbioassay->setChannels(1)};
ok($@, 'setChannels throws exception with non-array argument');

# test setChannels throws exception with bad argument array
eval {$derivedbioassay->setChannels([1])};
ok($@, 'setChannels throws exception with bad argument array');

# test addChannels throws exception with no arguments
eval {$derivedbioassay->addChannels()};
ok($@, 'addChannels throws exception with no arguments');

# test addChannels throws exception with bad argument
eval {$derivedbioassay->addChannels(1)};
ok($@, 'addChannels throws exception with bad array');

# test setChannels accepts empty array ref
eval {$derivedbioassay->setChannels([])};
ok((!$@ and defined $derivedbioassay->getChannels()
    and UNIVERSAL::isa($derivedbioassay->getChannels, 'ARRAY')
    and scalar @{$derivedbioassay->getChannels} == 0),
   'setChannels accepts empty array ref');


# test getChannels throws exception with argument
eval {$derivedbioassay->getChannels(1)};
ok($@, 'getChannels throws exception with argument');

# test setChannels throws exception with no argument
eval {$derivedbioassay->setChannels()};
ok($@, 'setChannels throws exception with no argument');

# test setChannels throws exception with too many argument
eval {$derivedbioassay->setChannels(1,2)};
ok($@, 'setChannels throws exception with too many argument');

# test setChannels accepts undef
eval {$derivedbioassay->setChannels(undef)};
ok((!$@ and not defined $derivedbioassay->getChannels()),
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


ok((UNIVERSAL::isa($derivedbioassay->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassay->getAuditTrail} == 1
 and UNIVERSAL::isa($derivedbioassay->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($derivedbioassay->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassay->getAuditTrail} == 1
 and $derivedbioassay->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($derivedbioassay->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getAuditTrail,'ARRAY')
 and scalar @{$derivedbioassay->getAuditTrail} == 2
 and $derivedbioassay->getAuditTrail->[0] == $audittrail_assn
 and $derivedbioassay->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$derivedbioassay->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$derivedbioassay->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$derivedbioassay->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$derivedbioassay->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$derivedbioassay->setAuditTrail([])};
ok((!$@ and defined $derivedbioassay->getAuditTrail()
    and UNIVERSAL::isa($derivedbioassay->getAuditTrail, 'ARRAY')
    and scalar @{$derivedbioassay->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$derivedbioassay->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$derivedbioassay->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$derivedbioassay->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$derivedbioassay->setAuditTrail(undef)};
ok((!$@ and not defined $derivedbioassay->getAuditTrail()),
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


ok((UNIVERSAL::isa($derivedbioassay->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassay->getPropertySets} == 1
 and UNIVERSAL::isa($derivedbioassay->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($derivedbioassay->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassay->getPropertySets} == 1
 and $derivedbioassay->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($derivedbioassay->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getPropertySets,'ARRAY')
 and scalar @{$derivedbioassay->getPropertySets} == 2
 and $derivedbioassay->getPropertySets->[0] == $propertysets_assn
 and $derivedbioassay->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$derivedbioassay->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$derivedbioassay->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$derivedbioassay->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$derivedbioassay->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$derivedbioassay->setPropertySets([])};
ok((!$@ and defined $derivedbioassay->getPropertySets()
    and UNIVERSAL::isa($derivedbioassay->getPropertySets, 'ARRAY')
    and scalar @{$derivedbioassay->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$derivedbioassay->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$derivedbioassay->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$derivedbioassay->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$derivedbioassay->setPropertySets(undef)};
ok((!$@ and not defined $derivedbioassay->getPropertySets()),
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


ok((UNIVERSAL::isa($derivedbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$derivedbioassay->getBioAssayFactorValues} == 1
 and UNIVERSAL::isa($derivedbioassay->getBioAssayFactorValues->[0], q[Bio::MAGE::Experiment::FactorValue])),
  'bioAssayFactorValues set in new()');

ok(eq_array($derivedbioassay->setBioAssayFactorValues([$bioassayfactorvalues_assn]), [$bioassayfactorvalues_assn]),
   'setBioAssayFactorValues returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$derivedbioassay->getBioAssayFactorValues} == 1
 and $derivedbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn),
   'getBioAssayFactorValues fetches correct value');

is($derivedbioassay->addBioAssayFactorValues($bioassayfactorvalues_assn), 2,
  'addBioAssayFactorValues returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$derivedbioassay->getBioAssayFactorValues} == 2
 and $derivedbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn
 and $derivedbioassay->getBioAssayFactorValues->[1] == $bioassayfactorvalues_assn),
  'addBioAssayFactorValues adds correct value');

# test setBioAssayFactorValues throws exception with non-array argument
eval {$derivedbioassay->setBioAssayFactorValues(1)};
ok($@, 'setBioAssayFactorValues throws exception with non-array argument');

# test setBioAssayFactorValues throws exception with bad argument array
eval {$derivedbioassay->setBioAssayFactorValues([1])};
ok($@, 'setBioAssayFactorValues throws exception with bad argument array');

# test addBioAssayFactorValues throws exception with no arguments
eval {$derivedbioassay->addBioAssayFactorValues()};
ok($@, 'addBioAssayFactorValues throws exception with no arguments');

# test addBioAssayFactorValues throws exception with bad argument
eval {$derivedbioassay->addBioAssayFactorValues(1)};
ok($@, 'addBioAssayFactorValues throws exception with bad array');

# test setBioAssayFactorValues accepts empty array ref
eval {$derivedbioassay->setBioAssayFactorValues([])};
ok((!$@ and defined $derivedbioassay->getBioAssayFactorValues()
    and UNIVERSAL::isa($derivedbioassay->getBioAssayFactorValues, 'ARRAY')
    and scalar @{$derivedbioassay->getBioAssayFactorValues} == 0),
   'setBioAssayFactorValues accepts empty array ref');


# test getBioAssayFactorValues throws exception with argument
eval {$derivedbioassay->getBioAssayFactorValues(1)};
ok($@, 'getBioAssayFactorValues throws exception with argument');

# test setBioAssayFactorValues throws exception with no argument
eval {$derivedbioassay->setBioAssayFactorValues()};
ok($@, 'setBioAssayFactorValues throws exception with no argument');

# test setBioAssayFactorValues throws exception with too many argument
eval {$derivedbioassay->setBioAssayFactorValues(1,2)};
ok($@, 'setBioAssayFactorValues throws exception with too many argument');

# test setBioAssayFactorValues accepts undef
eval {$derivedbioassay->setBioAssayFactorValues(undef)};
ok((!$@ and not defined $derivedbioassay->getBioAssayFactorValues()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($derivedbioassay->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassay->getDescriptions} == 1
 and UNIVERSAL::isa($derivedbioassay->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($derivedbioassay->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassay->getDescriptions} == 1
 and $derivedbioassay->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($derivedbioassay->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getDescriptions,'ARRAY')
 and scalar @{$derivedbioassay->getDescriptions} == 2
 and $derivedbioassay->getDescriptions->[0] == $descriptions_assn
 and $derivedbioassay->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$derivedbioassay->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$derivedbioassay->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$derivedbioassay->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$derivedbioassay->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$derivedbioassay->setDescriptions([])};
ok((!$@ and defined $derivedbioassay->getDescriptions()
    and UNIVERSAL::isa($derivedbioassay->getDescriptions, 'ARRAY')
    and scalar @{$derivedbioassay->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$derivedbioassay->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$derivedbioassay->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$derivedbioassay->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$derivedbioassay->setDescriptions(undef)};
ok((!$@ and not defined $derivedbioassay->getDescriptions()),
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


isa_ok($derivedbioassay->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($derivedbioassay->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($derivedbioassay->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$derivedbioassay->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$derivedbioassay->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$derivedbioassay->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$derivedbioassay->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$derivedbioassay->setSecurity(undef)};
ok((!$@ and not defined $derivedbioassay->getSecurity()),
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



# testing association derivedBioAssayMap
my $derivedbioassaymap_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaymap_assn = Bio::MAGE::BioAssayData::BioAssayMap->new();
}


ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayMap,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayMap} == 1
 and UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayMap->[0], q[Bio::MAGE::BioAssayData::BioAssayMap])),
  'derivedBioAssayMap set in new()');

ok(eq_array($derivedbioassay->setDerivedBioAssayMap([$derivedbioassaymap_assn]), [$derivedbioassaymap_assn]),
   'setDerivedBioAssayMap returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayMap,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayMap} == 1
 and $derivedbioassay->getDerivedBioAssayMap->[0] == $derivedbioassaymap_assn),
   'getDerivedBioAssayMap fetches correct value');

is($derivedbioassay->addDerivedBioAssayMap($derivedbioassaymap_assn), 2,
  'addDerivedBioAssayMap returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayMap,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayMap} == 2
 and $derivedbioassay->getDerivedBioAssayMap->[0] == $derivedbioassaymap_assn
 and $derivedbioassay->getDerivedBioAssayMap->[1] == $derivedbioassaymap_assn),
  'addDerivedBioAssayMap adds correct value');

# test setDerivedBioAssayMap throws exception with non-array argument
eval {$derivedbioassay->setDerivedBioAssayMap(1)};
ok($@, 'setDerivedBioAssayMap throws exception with non-array argument');

# test setDerivedBioAssayMap throws exception with bad argument array
eval {$derivedbioassay->setDerivedBioAssayMap([1])};
ok($@, 'setDerivedBioAssayMap throws exception with bad argument array');

# test addDerivedBioAssayMap throws exception with no arguments
eval {$derivedbioassay->addDerivedBioAssayMap()};
ok($@, 'addDerivedBioAssayMap throws exception with no arguments');

# test addDerivedBioAssayMap throws exception with bad argument
eval {$derivedbioassay->addDerivedBioAssayMap(1)};
ok($@, 'addDerivedBioAssayMap throws exception with bad array');

# test setDerivedBioAssayMap accepts empty array ref
eval {$derivedbioassay->setDerivedBioAssayMap([])};
ok((!$@ and defined $derivedbioassay->getDerivedBioAssayMap()
    and UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayMap, 'ARRAY')
    and scalar @{$derivedbioassay->getDerivedBioAssayMap} == 0),
   'setDerivedBioAssayMap accepts empty array ref');


# test getDerivedBioAssayMap throws exception with argument
eval {$derivedbioassay->getDerivedBioAssayMap(1)};
ok($@, 'getDerivedBioAssayMap throws exception with argument');

# test setDerivedBioAssayMap throws exception with no argument
eval {$derivedbioassay->setDerivedBioAssayMap()};
ok($@, 'setDerivedBioAssayMap throws exception with no argument');

# test setDerivedBioAssayMap throws exception with too many argument
eval {$derivedbioassay->setDerivedBioAssayMap(1,2)};
ok($@, 'setDerivedBioAssayMap throws exception with too many argument');

# test setDerivedBioAssayMap accepts undef
eval {$derivedbioassay->setDerivedBioAssayMap(undef)};
ok((!$@ and not defined $derivedbioassay->getDerivedBioAssayMap()),
   'setDerivedBioAssayMap accepts undef');

# test the meta-data for the assoication
$assn = $assns{derivedBioAssayMap};
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
   'derivedBioAssayMap->other() is a valid Bio::MAGE::Association::End'
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
   'derivedBioAssayMap->self() is a valid Bio::MAGE::Association::End'
  );



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($derivedbioassay->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($derivedbioassay->setType($type_assn), $type_assn,
  'setType returns value');

ok($derivedbioassay->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$derivedbioassay->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$derivedbioassay->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$derivedbioassay->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$derivedbioassay->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$derivedbioassay->setType(undef)};
ok((!$@ and not defined $derivedbioassay->getType()),
   'setType accepts undef');

# test the meta-data for the assoication
$assn = $assns{type};
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
   'type->other() is a valid Bio::MAGE::Association::End'
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
   'type->self() is a valid Bio::MAGE::Association::End'
  );



# testing association derivedBioAssayData
my $derivedbioassaydata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaydata_assn = Bio::MAGE::BioAssayData::DerivedBioAssayData->new();
}


ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayData,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayData} == 1
 and UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayData->[0], q[Bio::MAGE::BioAssayData::DerivedBioAssayData])),
  'derivedBioAssayData set in new()');

ok(eq_array($derivedbioassay->setDerivedBioAssayData([$derivedbioassaydata_assn]), [$derivedbioassaydata_assn]),
   'setDerivedBioAssayData returns correct value');

ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayData,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayData} == 1
 and $derivedbioassay->getDerivedBioAssayData->[0] == $derivedbioassaydata_assn),
   'getDerivedBioAssayData fetches correct value');

is($derivedbioassay->addDerivedBioAssayData($derivedbioassaydata_assn), 2,
  'addDerivedBioAssayData returns number of items in list');

ok((UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayData,'ARRAY')
 and scalar @{$derivedbioassay->getDerivedBioAssayData} == 2
 and $derivedbioassay->getDerivedBioAssayData->[0] == $derivedbioassaydata_assn
 and $derivedbioassay->getDerivedBioAssayData->[1] == $derivedbioassaydata_assn),
  'addDerivedBioAssayData adds correct value');

# test setDerivedBioAssayData throws exception with non-array argument
eval {$derivedbioassay->setDerivedBioAssayData(1)};
ok($@, 'setDerivedBioAssayData throws exception with non-array argument');

# test setDerivedBioAssayData throws exception with bad argument array
eval {$derivedbioassay->setDerivedBioAssayData([1])};
ok($@, 'setDerivedBioAssayData throws exception with bad argument array');

# test addDerivedBioAssayData throws exception with no arguments
eval {$derivedbioassay->addDerivedBioAssayData()};
ok($@, 'addDerivedBioAssayData throws exception with no arguments');

# test addDerivedBioAssayData throws exception with bad argument
eval {$derivedbioassay->addDerivedBioAssayData(1)};
ok($@, 'addDerivedBioAssayData throws exception with bad array');

# test setDerivedBioAssayData accepts empty array ref
eval {$derivedbioassay->setDerivedBioAssayData([])};
ok((!$@ and defined $derivedbioassay->getDerivedBioAssayData()
    and UNIVERSAL::isa($derivedbioassay->getDerivedBioAssayData, 'ARRAY')
    and scalar @{$derivedbioassay->getDerivedBioAssayData} == 0),
   'setDerivedBioAssayData accepts empty array ref');


# test getDerivedBioAssayData throws exception with argument
eval {$derivedbioassay->getDerivedBioAssayData(1)};
ok($@, 'getDerivedBioAssayData throws exception with argument');

# test setDerivedBioAssayData throws exception with no argument
eval {$derivedbioassay->setDerivedBioAssayData()};
ok($@, 'setDerivedBioAssayData throws exception with no argument');

# test setDerivedBioAssayData throws exception with too many argument
eval {$derivedbioassay->setDerivedBioAssayData(1,2)};
ok($@, 'setDerivedBioAssayData throws exception with too many argument');

# test setDerivedBioAssayData accepts undef
eval {$derivedbioassay->setDerivedBioAssayData(undef)};
ok((!$@ and not defined $derivedbioassay->getDerivedBioAssayData()),
   'setDerivedBioAssayData accepts undef');

# test the meta-data for the assoication
$assn = $assns{derivedBioAssayData};
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
   'derivedBioAssayData->other() is a valid Bio::MAGE::Association::End'
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
   'derivedBioAssayData->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($derivedbioassay, q[Bio::MAGE::BioAssay::BioAssay]);

