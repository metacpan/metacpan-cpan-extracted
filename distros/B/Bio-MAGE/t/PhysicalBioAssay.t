##############################
#
# PhysicalBioAssay.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PhysicalBioAssay.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssay::PhysicalBioAssay') };

use Bio::MAGE::BioAssay::BioAssayTreatment;
use Bio::MAGE::BioAssay::Image;
use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::BioAssay::BioAssayCreation;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $physicalbioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new();
}
isa_ok($physicalbioassay, 'Bio::MAGE::BioAssay::PhysicalBioAssay');

# test the package_name class method
is($physicalbioassay->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($physicalbioassay->class_name(), q[Bio::MAGE::BioAssay::PhysicalBioAssay],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($physicalbioassay->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$physicalbioassay->setIdentifier('1');
is($physicalbioassay->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$physicalbioassay->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalbioassay->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalbioassay->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalbioassay->setIdentifier(undef)};
ok((!$@ and not defined $physicalbioassay->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($physicalbioassay->getName(), '2',
  'name new');

# test getter/setter
$physicalbioassay->setName('2');
is($physicalbioassay->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$physicalbioassay->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$physicalbioassay->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$physicalbioassay->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$physicalbioassay->setName(undef)};
ok((!$@ and not defined $physicalbioassay->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::PhysicalBioAssay->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new(channels => [Bio::MAGE::BioAssay::Channel->new()],
bioAssayCreation => Bio::MAGE::BioAssay::BioAssayCreation->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
physicalBioAssayData => [Bio::MAGE::BioAssay::Image->new()],
bioAssayFactorValues => [Bio::MAGE::Experiment::FactorValue->new()],
bioAssayTreatments => [Bio::MAGE::BioAssay::BioAssayTreatment->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new());
}

my ($end, $assn);


# testing association channels
my $channels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channels_assn = Bio::MAGE::BioAssay::Channel->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getChannels,'ARRAY')
 and scalar @{$physicalbioassay->getChannels} == 1
 and UNIVERSAL::isa($physicalbioassay->getChannels->[0], q[Bio::MAGE::BioAssay::Channel])),
  'channels set in new()');

ok(eq_array($physicalbioassay->setChannels([$channels_assn]), [$channels_assn]),
   'setChannels returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getChannels,'ARRAY')
 and scalar @{$physicalbioassay->getChannels} == 1
 and $physicalbioassay->getChannels->[0] == $channels_assn),
   'getChannels fetches correct value');

is($physicalbioassay->addChannels($channels_assn), 2,
  'addChannels returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getChannels,'ARRAY')
 and scalar @{$physicalbioassay->getChannels} == 2
 and $physicalbioassay->getChannels->[0] == $channels_assn
 and $physicalbioassay->getChannels->[1] == $channels_assn),
  'addChannels adds correct value');

# test setChannels throws exception with non-array argument
eval {$physicalbioassay->setChannels(1)};
ok($@, 'setChannels throws exception with non-array argument');

# test setChannels throws exception with bad argument array
eval {$physicalbioassay->setChannels([1])};
ok($@, 'setChannels throws exception with bad argument array');

# test addChannels throws exception with no arguments
eval {$physicalbioassay->addChannels()};
ok($@, 'addChannels throws exception with no arguments');

# test addChannels throws exception with bad argument
eval {$physicalbioassay->addChannels(1)};
ok($@, 'addChannels throws exception with bad array');

# test setChannels accepts empty array ref
eval {$physicalbioassay->setChannels([])};
ok((!$@ and defined $physicalbioassay->getChannels()
    and UNIVERSAL::isa($physicalbioassay->getChannels, 'ARRAY')
    and scalar @{$physicalbioassay->getChannels} == 0),
   'setChannels accepts empty array ref');


# test getChannels throws exception with argument
eval {$physicalbioassay->getChannels(1)};
ok($@, 'getChannels throws exception with argument');

# test setChannels throws exception with no argument
eval {$physicalbioassay->setChannels()};
ok($@, 'setChannels throws exception with no argument');

# test setChannels throws exception with too many argument
eval {$physicalbioassay->setChannels(1,2)};
ok($@, 'setChannels throws exception with too many argument');

# test setChannels accepts undef
eval {$physicalbioassay->setChannels(undef)};
ok((!$@ and not defined $physicalbioassay->getChannels()),
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



# testing association bioAssayCreation
my $bioassaycreation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaycreation_assn = Bio::MAGE::BioAssay::BioAssayCreation->new();
}


isa_ok($physicalbioassay->getBioAssayCreation, q[Bio::MAGE::BioAssay::BioAssayCreation]);

is($physicalbioassay->setBioAssayCreation($bioassaycreation_assn), $bioassaycreation_assn,
  'setBioAssayCreation returns value');

ok($physicalbioassay->getBioAssayCreation() == $bioassaycreation_assn,
   'getBioAssayCreation fetches correct value');

# test setBioAssayCreation throws exception with bad argument
eval {$physicalbioassay->setBioAssayCreation(1)};
ok($@, 'setBioAssayCreation throws exception with bad argument');


# test getBioAssayCreation throws exception with argument
eval {$physicalbioassay->getBioAssayCreation(1)};
ok($@, 'getBioAssayCreation throws exception with argument');

# test setBioAssayCreation throws exception with no argument
eval {$physicalbioassay->setBioAssayCreation()};
ok($@, 'setBioAssayCreation throws exception with no argument');

# test setBioAssayCreation throws exception with too many argument
eval {$physicalbioassay->setBioAssayCreation(1,2)};
ok($@, 'setBioAssayCreation throws exception with too many argument');

# test setBioAssayCreation accepts undef
eval {$physicalbioassay->setBioAssayCreation(undef)};
ok((!$@ and not defined $physicalbioassay->getBioAssayCreation()),
   'setBioAssayCreation accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayCreation};
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
   'bioAssayCreation->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayCreation->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getAuditTrail,'ARRAY')
 and scalar @{$physicalbioassay->getAuditTrail} == 1
 and UNIVERSAL::isa($physicalbioassay->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($physicalbioassay->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getAuditTrail,'ARRAY')
 and scalar @{$physicalbioassay->getAuditTrail} == 1
 and $physicalbioassay->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($physicalbioassay->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getAuditTrail,'ARRAY')
 and scalar @{$physicalbioassay->getAuditTrail} == 2
 and $physicalbioassay->getAuditTrail->[0] == $audittrail_assn
 and $physicalbioassay->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$physicalbioassay->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$physicalbioassay->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$physicalbioassay->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$physicalbioassay->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$physicalbioassay->setAuditTrail([])};
ok((!$@ and defined $physicalbioassay->getAuditTrail()
    and UNIVERSAL::isa($physicalbioassay->getAuditTrail, 'ARRAY')
    and scalar @{$physicalbioassay->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$physicalbioassay->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$physicalbioassay->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$physicalbioassay->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$physicalbioassay->setAuditTrail(undef)};
ok((!$@ and not defined $physicalbioassay->getAuditTrail()),
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


ok((UNIVERSAL::isa($physicalbioassay->getPropertySets,'ARRAY')
 and scalar @{$physicalbioassay->getPropertySets} == 1
 and UNIVERSAL::isa($physicalbioassay->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($physicalbioassay->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getPropertySets,'ARRAY')
 and scalar @{$physicalbioassay->getPropertySets} == 1
 and $physicalbioassay->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($physicalbioassay->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getPropertySets,'ARRAY')
 and scalar @{$physicalbioassay->getPropertySets} == 2
 and $physicalbioassay->getPropertySets->[0] == $propertysets_assn
 and $physicalbioassay->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$physicalbioassay->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$physicalbioassay->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$physicalbioassay->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$physicalbioassay->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$physicalbioassay->setPropertySets([])};
ok((!$@ and defined $physicalbioassay->getPropertySets()
    and UNIVERSAL::isa($physicalbioassay->getPropertySets, 'ARRAY')
    and scalar @{$physicalbioassay->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$physicalbioassay->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$physicalbioassay->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$physicalbioassay->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$physicalbioassay->setPropertySets(undef)};
ok((!$@ and not defined $physicalbioassay->getPropertySets()),
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



# testing association physicalBioAssayData
my $physicalbioassaydata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassaydata_assn = Bio::MAGE::BioAssay::Image->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getPhysicalBioAssayData,'ARRAY')
 and scalar @{$physicalbioassay->getPhysicalBioAssayData} == 1
 and UNIVERSAL::isa($physicalbioassay->getPhysicalBioAssayData->[0], q[Bio::MAGE::BioAssay::Image])),
  'physicalBioAssayData set in new()');

ok(eq_array($physicalbioassay->setPhysicalBioAssayData([$physicalbioassaydata_assn]), [$physicalbioassaydata_assn]),
   'setPhysicalBioAssayData returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getPhysicalBioAssayData,'ARRAY')
 and scalar @{$physicalbioassay->getPhysicalBioAssayData} == 1
 and $physicalbioassay->getPhysicalBioAssayData->[0] == $physicalbioassaydata_assn),
   'getPhysicalBioAssayData fetches correct value');

is($physicalbioassay->addPhysicalBioAssayData($physicalbioassaydata_assn), 2,
  'addPhysicalBioAssayData returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getPhysicalBioAssayData,'ARRAY')
 and scalar @{$physicalbioassay->getPhysicalBioAssayData} == 2
 and $physicalbioassay->getPhysicalBioAssayData->[0] == $physicalbioassaydata_assn
 and $physicalbioassay->getPhysicalBioAssayData->[1] == $physicalbioassaydata_assn),
  'addPhysicalBioAssayData adds correct value');

# test setPhysicalBioAssayData throws exception with non-array argument
eval {$physicalbioassay->setPhysicalBioAssayData(1)};
ok($@, 'setPhysicalBioAssayData throws exception with non-array argument');

# test setPhysicalBioAssayData throws exception with bad argument array
eval {$physicalbioassay->setPhysicalBioAssayData([1])};
ok($@, 'setPhysicalBioAssayData throws exception with bad argument array');

# test addPhysicalBioAssayData throws exception with no arguments
eval {$physicalbioassay->addPhysicalBioAssayData()};
ok($@, 'addPhysicalBioAssayData throws exception with no arguments');

# test addPhysicalBioAssayData throws exception with bad argument
eval {$physicalbioassay->addPhysicalBioAssayData(1)};
ok($@, 'addPhysicalBioAssayData throws exception with bad array');

# test setPhysicalBioAssayData accepts empty array ref
eval {$physicalbioassay->setPhysicalBioAssayData([])};
ok((!$@ and defined $physicalbioassay->getPhysicalBioAssayData()
    and UNIVERSAL::isa($physicalbioassay->getPhysicalBioAssayData, 'ARRAY')
    and scalar @{$physicalbioassay->getPhysicalBioAssayData} == 0),
   'setPhysicalBioAssayData accepts empty array ref');


# test getPhysicalBioAssayData throws exception with argument
eval {$physicalbioassay->getPhysicalBioAssayData(1)};
ok($@, 'getPhysicalBioAssayData throws exception with argument');

# test setPhysicalBioAssayData throws exception with no argument
eval {$physicalbioassay->setPhysicalBioAssayData()};
ok($@, 'setPhysicalBioAssayData throws exception with no argument');

# test setPhysicalBioAssayData throws exception with too many argument
eval {$physicalbioassay->setPhysicalBioAssayData(1,2)};
ok($@, 'setPhysicalBioAssayData throws exception with too many argument');

# test setPhysicalBioAssayData accepts undef
eval {$physicalbioassay->setPhysicalBioAssayData(undef)};
ok((!$@ and not defined $physicalbioassay->getPhysicalBioAssayData()),
   'setPhysicalBioAssayData accepts undef');

# test the meta-data for the assoication
$assn = $assns{physicalBioAssayData};
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
   'physicalBioAssayData->other() is a valid Bio::MAGE::Association::End'
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
   'physicalBioAssayData->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssayFactorValues
my $bioassayfactorvalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassayfactorvalues_assn = Bio::MAGE::Experiment::FactorValue->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayFactorValues} == 1
 and UNIVERSAL::isa($physicalbioassay->getBioAssayFactorValues->[0], q[Bio::MAGE::Experiment::FactorValue])),
  'bioAssayFactorValues set in new()');

ok(eq_array($physicalbioassay->setBioAssayFactorValues([$bioassayfactorvalues_assn]), [$bioassayfactorvalues_assn]),
   'setBioAssayFactorValues returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayFactorValues} == 1
 and $physicalbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn),
   'getBioAssayFactorValues fetches correct value');

is($physicalbioassay->addBioAssayFactorValues($bioassayfactorvalues_assn), 2,
  'addBioAssayFactorValues returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayFactorValues} == 2
 and $physicalbioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn
 and $physicalbioassay->getBioAssayFactorValues->[1] == $bioassayfactorvalues_assn),
  'addBioAssayFactorValues adds correct value');

# test setBioAssayFactorValues throws exception with non-array argument
eval {$physicalbioassay->setBioAssayFactorValues(1)};
ok($@, 'setBioAssayFactorValues throws exception with non-array argument');

# test setBioAssayFactorValues throws exception with bad argument array
eval {$physicalbioassay->setBioAssayFactorValues([1])};
ok($@, 'setBioAssayFactorValues throws exception with bad argument array');

# test addBioAssayFactorValues throws exception with no arguments
eval {$physicalbioassay->addBioAssayFactorValues()};
ok($@, 'addBioAssayFactorValues throws exception with no arguments');

# test addBioAssayFactorValues throws exception with bad argument
eval {$physicalbioassay->addBioAssayFactorValues(1)};
ok($@, 'addBioAssayFactorValues throws exception with bad array');

# test setBioAssayFactorValues accepts empty array ref
eval {$physicalbioassay->setBioAssayFactorValues([])};
ok((!$@ and defined $physicalbioassay->getBioAssayFactorValues()
    and UNIVERSAL::isa($physicalbioassay->getBioAssayFactorValues, 'ARRAY')
    and scalar @{$physicalbioassay->getBioAssayFactorValues} == 0),
   'setBioAssayFactorValues accepts empty array ref');


# test getBioAssayFactorValues throws exception with argument
eval {$physicalbioassay->getBioAssayFactorValues(1)};
ok($@, 'getBioAssayFactorValues throws exception with argument');

# test setBioAssayFactorValues throws exception with no argument
eval {$physicalbioassay->setBioAssayFactorValues()};
ok($@, 'setBioAssayFactorValues throws exception with no argument');

# test setBioAssayFactorValues throws exception with too many argument
eval {$physicalbioassay->setBioAssayFactorValues(1,2)};
ok($@, 'setBioAssayFactorValues throws exception with too many argument');

# test setBioAssayFactorValues accepts undef
eval {$physicalbioassay->setBioAssayFactorValues(undef)};
ok((!$@ and not defined $physicalbioassay->getBioAssayFactorValues()),
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



# testing association bioAssayTreatments
my $bioassaytreatments_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaytreatments_assn = Bio::MAGE::BioAssay::BioAssayTreatment->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getBioAssayTreatments,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayTreatments} == 1
 and UNIVERSAL::isa($physicalbioassay->getBioAssayTreatments->[0], q[Bio::MAGE::BioAssay::BioAssayTreatment])),
  'bioAssayTreatments set in new()');

ok(eq_array($physicalbioassay->setBioAssayTreatments([$bioassaytreatments_assn]), [$bioassaytreatments_assn]),
   'setBioAssayTreatments returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getBioAssayTreatments,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayTreatments} == 1
 and $physicalbioassay->getBioAssayTreatments->[0] == $bioassaytreatments_assn),
   'getBioAssayTreatments fetches correct value');

is($physicalbioassay->addBioAssayTreatments($bioassaytreatments_assn), 2,
  'addBioAssayTreatments returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getBioAssayTreatments,'ARRAY')
 and scalar @{$physicalbioassay->getBioAssayTreatments} == 2
 and $physicalbioassay->getBioAssayTreatments->[0] == $bioassaytreatments_assn
 and $physicalbioassay->getBioAssayTreatments->[1] == $bioassaytreatments_assn),
  'addBioAssayTreatments adds correct value');

# test setBioAssayTreatments throws exception with non-array argument
eval {$physicalbioassay->setBioAssayTreatments(1)};
ok($@, 'setBioAssayTreatments throws exception with non-array argument');

# test setBioAssayTreatments throws exception with bad argument array
eval {$physicalbioassay->setBioAssayTreatments([1])};
ok($@, 'setBioAssayTreatments throws exception with bad argument array');

# test addBioAssayTreatments throws exception with no arguments
eval {$physicalbioassay->addBioAssayTreatments()};
ok($@, 'addBioAssayTreatments throws exception with no arguments');

# test addBioAssayTreatments throws exception with bad argument
eval {$physicalbioassay->addBioAssayTreatments(1)};
ok($@, 'addBioAssayTreatments throws exception with bad array');

# test setBioAssayTreatments accepts empty array ref
eval {$physicalbioassay->setBioAssayTreatments([])};
ok((!$@ and defined $physicalbioassay->getBioAssayTreatments()
    and UNIVERSAL::isa($physicalbioassay->getBioAssayTreatments, 'ARRAY')
    and scalar @{$physicalbioassay->getBioAssayTreatments} == 0),
   'setBioAssayTreatments accepts empty array ref');


# test getBioAssayTreatments throws exception with argument
eval {$physicalbioassay->getBioAssayTreatments(1)};
ok($@, 'getBioAssayTreatments throws exception with argument');

# test setBioAssayTreatments throws exception with no argument
eval {$physicalbioassay->setBioAssayTreatments()};
ok($@, 'setBioAssayTreatments throws exception with no argument');

# test setBioAssayTreatments throws exception with too many argument
eval {$physicalbioassay->setBioAssayTreatments(1,2)};
ok($@, 'setBioAssayTreatments throws exception with too many argument');

# test setBioAssayTreatments accepts undef
eval {$physicalbioassay->setBioAssayTreatments(undef)};
ok((!$@ and not defined $physicalbioassay->getBioAssayTreatments()),
   'setBioAssayTreatments accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayTreatments};
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
   'bioAssayTreatments->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayTreatments->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($physicalbioassay->getDescriptions,'ARRAY')
 and scalar @{$physicalbioassay->getDescriptions} == 1
 and UNIVERSAL::isa($physicalbioassay->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($physicalbioassay->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($physicalbioassay->getDescriptions,'ARRAY')
 and scalar @{$physicalbioassay->getDescriptions} == 1
 and $physicalbioassay->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($physicalbioassay->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($physicalbioassay->getDescriptions,'ARRAY')
 and scalar @{$physicalbioassay->getDescriptions} == 2
 and $physicalbioassay->getDescriptions->[0] == $descriptions_assn
 and $physicalbioassay->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$physicalbioassay->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$physicalbioassay->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$physicalbioassay->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$physicalbioassay->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$physicalbioassay->setDescriptions([])};
ok((!$@ and defined $physicalbioassay->getDescriptions()
    and UNIVERSAL::isa($physicalbioassay->getDescriptions, 'ARRAY')
    and scalar @{$physicalbioassay->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$physicalbioassay->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$physicalbioassay->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$physicalbioassay->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$physicalbioassay->setDescriptions(undef)};
ok((!$@ and not defined $physicalbioassay->getDescriptions()),
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


isa_ok($physicalbioassay->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($physicalbioassay->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($physicalbioassay->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$physicalbioassay->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$physicalbioassay->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$physicalbioassay->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$physicalbioassay->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$physicalbioassay->setSecurity(undef)};
ok((!$@ and not defined $physicalbioassay->getSecurity()),
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





my $bioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioassay = Bio::MAGE::BioAssay::BioAssay->new();
}

# testing superclass BioAssay
isa_ok($bioassay, q[Bio::MAGE::BioAssay::BioAssay]);
isa_ok($physicalbioassay, q[Bio::MAGE::BioAssay::BioAssay]);

