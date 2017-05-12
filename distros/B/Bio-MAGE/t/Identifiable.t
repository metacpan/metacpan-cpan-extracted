##############################
#
# Identifiable.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Identifiable.t`

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
use Test::More tests => 146;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Identifiable') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;

use Bio::MAGE::QuantitationType::QuantitationType;
use Bio::MAGE::ArrayDesign::ArrayDesign;
use Bio::MAGE::Description::Database;
use Bio::MAGE::BioAssay::Image;
use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::DesignElement::DesignElement;
use Bio::MAGE::ArrayDesign::Zone;
use Bio::MAGE::AuditAndSecurity::SecurityGroup;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::ArrayDesign::DesignElementGroup;
use Bio::MAGE::BioAssayData::BioAssayData;
use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::Array::Array;
use Bio::MAGE::Array::ArrayGroup;
use Bio::MAGE::BioAssayData::BioAssayDimension;
use Bio::MAGE::Array::ArrayManufacture;
use Bio::MAGE::BioEvent::BioEvent;
use Bio::MAGE::Experiment::Experiment;
use Bio::MAGE::Experiment::ExperimentalFactor;
use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::Protocol::Parameter;
use Bio::MAGE::BioMaterial::BioMaterial;
use Bio::MAGE::BioMaterial::Compound;
use Bio::MAGE::BioSequence::BioSequence;
use Bio::MAGE::Protocol::Parameterizable;
use Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster;

# we test the new() method
my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $identifiable = Bio::MAGE::Identifiable->new();
}
isa_ok($identifiable, 'Bio::MAGE::Identifiable');

# test the package_name class method
is($identifiable->package_name(), q[MAGE],
  'package');

# test the class_name class method
is($identifiable->class_name(), q[Bio::MAGE::Identifiable],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $identifiable = Bio::MAGE::Identifiable->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($identifiable->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$identifiable->setIdentifier('1');
is($identifiable->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$identifiable->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$identifiable->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$identifiable->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$identifiable->setIdentifier(undef)};
ok((!$@ and not defined $identifiable->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($identifiable->getName(), '2',
  'name new');

# test getter/setter
$identifiable->setName('2');
is($identifiable->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$identifiable->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$identifiable->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$identifiable->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$identifiable->setName(undef)};
ok((!$@ and not defined $identifiable->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Identifiable->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $identifiable = Bio::MAGE::Identifiable->new(descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($identifiable->getDescriptions,'ARRAY')
 and scalar @{$identifiable->getDescriptions} == 1
 and UNIVERSAL::isa($identifiable->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($identifiable->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($identifiable->getDescriptions,'ARRAY')
 and scalar @{$identifiable->getDescriptions} == 1
 and $identifiable->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($identifiable->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($identifiable->getDescriptions,'ARRAY')
 and scalar @{$identifiable->getDescriptions} == 2
 and $identifiable->getDescriptions->[0] == $descriptions_assn
 and $identifiable->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$identifiable->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$identifiable->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$identifiable->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$identifiable->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$identifiable->setDescriptions([])};
ok((!$@ and defined $identifiable->getDescriptions()
    and UNIVERSAL::isa($identifiable->getDescriptions, 'ARRAY')
    and scalar @{$identifiable->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$identifiable->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$identifiable->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$identifiable->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$identifiable->setDescriptions(undef)};
ok((!$@ and not defined $identifiable->getDescriptions()),
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



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($identifiable->getAuditTrail,'ARRAY')
 and scalar @{$identifiable->getAuditTrail} == 1
 and UNIVERSAL::isa($identifiable->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($identifiable->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($identifiable->getAuditTrail,'ARRAY')
 and scalar @{$identifiable->getAuditTrail} == 1
 and $identifiable->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($identifiable->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($identifiable->getAuditTrail,'ARRAY')
 and scalar @{$identifiable->getAuditTrail} == 2
 and $identifiable->getAuditTrail->[0] == $audittrail_assn
 and $identifiable->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$identifiable->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$identifiable->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$identifiable->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$identifiable->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$identifiable->setAuditTrail([])};
ok((!$@ and defined $identifiable->getAuditTrail()
    and UNIVERSAL::isa($identifiable->getAuditTrail, 'ARRAY')
    and scalar @{$identifiable->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$identifiable->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$identifiable->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$identifiable->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$identifiable->setAuditTrail(undef)};
ok((!$@ and not defined $identifiable->getAuditTrail()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($identifiable->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($identifiable->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($identifiable->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$identifiable->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$identifiable->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$identifiable->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$identifiable->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$identifiable->setSecurity(undef)};
ok((!$@ and not defined $identifiable->getSecurity()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($identifiable->getPropertySets,'ARRAY')
 and scalar @{$identifiable->getPropertySets} == 1
 and UNIVERSAL::isa($identifiable->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($identifiable->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($identifiable->getPropertySets,'ARRAY')
 and scalar @{$identifiable->getPropertySets} == 1
 and $identifiable->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($identifiable->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($identifiable->getPropertySets,'ARRAY')
 and scalar @{$identifiable->getPropertySets} == 2
 and $identifiable->getPropertySets->[0] == $propertysets_assn
 and $identifiable->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$identifiable->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$identifiable->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$identifiable->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$identifiable->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$identifiable->setPropertySets([])};
ok((!$@ and defined $identifiable->getPropertySets()
    and UNIVERSAL::isa($identifiable->getPropertySets, 'ARRAY')
    and scalar @{$identifiable->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$identifiable->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$identifiable->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$identifiable->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$identifiable->setPropertySets(undef)};
ok((!$@ and not defined $identifiable->getPropertySets()),
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




# create a subclass
my $quantitationtype = Bio::MAGE::QuantitationType::QuantitationType->new();

# testing subclass QuantitationType
isa_ok($quantitationtype, q[Bio::MAGE::QuantitationType::QuantitationType]);
isa_ok($quantitationtype, q[Bio::MAGE::Identifiable]);


# create a subclass
my $arraydesign = Bio::MAGE::ArrayDesign::ArrayDesign->new();

# testing subclass ArrayDesign
isa_ok($arraydesign, q[Bio::MAGE::ArrayDesign::ArrayDesign]);
isa_ok($arraydesign, q[Bio::MAGE::Identifiable]);


# create a subclass
my $database = Bio::MAGE::Description::Database->new();

# testing subclass Database
isa_ok($database, q[Bio::MAGE::Description::Database]);
isa_ok($database, q[Bio::MAGE::Identifiable]);


# create a subclass
my $image = Bio::MAGE::BioAssay::Image->new();

# testing subclass Image
isa_ok($image, q[Bio::MAGE::BioAssay::Image]);
isa_ok($image, q[Bio::MAGE::Identifiable]);


# create a subclass
my $bioassay = Bio::MAGE::BioAssay::BioAssay->new();

# testing subclass BioAssay
isa_ok($bioassay, q[Bio::MAGE::BioAssay::BioAssay]);
isa_ok($bioassay, q[Bio::MAGE::Identifiable]);


# create a subclass
my $channel = Bio::MAGE::BioAssay::Channel->new();

# testing subclass Channel
isa_ok($channel, q[Bio::MAGE::BioAssay::Channel]);
isa_ok($channel, q[Bio::MAGE::Identifiable]);


# create a subclass
my $security = Bio::MAGE::AuditAndSecurity::Security->new();

# testing subclass Security
isa_ok($security, q[Bio::MAGE::AuditAndSecurity::Security]);
isa_ok($security, q[Bio::MAGE::Identifiable]);


# create a subclass
my $designelement = Bio::MAGE::DesignElement::DesignElement->new();

# testing subclass DesignElement
isa_ok($designelement, q[Bio::MAGE::DesignElement::DesignElement]);
isa_ok($designelement, q[Bio::MAGE::Identifiable]);


# create a subclass
my $zone = Bio::MAGE::ArrayDesign::Zone->new();

# testing subclass Zone
isa_ok($zone, q[Bio::MAGE::ArrayDesign::Zone]);
isa_ok($zone, q[Bio::MAGE::Identifiable]);


# create a subclass
my $securitygroup = Bio::MAGE::AuditAndSecurity::SecurityGroup->new();

# testing subclass SecurityGroup
isa_ok($securitygroup, q[Bio::MAGE::AuditAndSecurity::SecurityGroup]);
isa_ok($securitygroup, q[Bio::MAGE::Identifiable]);


# create a subclass
my $contact = Bio::MAGE::AuditAndSecurity::Contact->new();

# testing subclass Contact
isa_ok($contact, q[Bio::MAGE::AuditAndSecurity::Contact]);
isa_ok($contact, q[Bio::MAGE::Identifiable]);


# create a subclass
my $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new();

# testing subclass DesignElementGroup
isa_ok($designelementgroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);
isa_ok($designelementgroup, q[Bio::MAGE::Identifiable]);


# create a subclass
my $bioassaydata = Bio::MAGE::BioAssayData::BioAssayData->new();

# testing subclass BioAssayData
isa_ok($bioassaydata, q[Bio::MAGE::BioAssayData::BioAssayData]);
isa_ok($bioassaydata, q[Bio::MAGE::Identifiable]);


# create a subclass
my $quantitationtypedimension = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new();

# testing subclass QuantitationTypeDimension
isa_ok($quantitationtypedimension, q[Bio::MAGE::BioAssayData::QuantitationTypeDimension]);
isa_ok($quantitationtypedimension, q[Bio::MAGE::Identifiable]);


# create a subclass
my $designelementdimension = Bio::MAGE::BioAssayData::DesignElementDimension->new();

# testing subclass DesignElementDimension
isa_ok($designelementdimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);
isa_ok($designelementdimension, q[Bio::MAGE::Identifiable]);


# create a subclass
my $array = Bio::MAGE::Array::Array->new();

# testing subclass Array
isa_ok($array, q[Bio::MAGE::Array::Array]);
isa_ok($array, q[Bio::MAGE::Identifiable]);


# create a subclass
my $arraygroup = Bio::MAGE::Array::ArrayGroup->new();

# testing subclass ArrayGroup
isa_ok($arraygroup, q[Bio::MAGE::Array::ArrayGroup]);
isa_ok($arraygroup, q[Bio::MAGE::Identifiable]);


# create a subclass
my $bioassaydimension = Bio::MAGE::BioAssayData::BioAssayDimension->new();

# testing subclass BioAssayDimension
isa_ok($bioassaydimension, q[Bio::MAGE::BioAssayData::BioAssayDimension]);
isa_ok($bioassaydimension, q[Bio::MAGE::Identifiable]);


# create a subclass
my $arraymanufacture = Bio::MAGE::Array::ArrayManufacture->new();

# testing subclass ArrayManufacture
isa_ok($arraymanufacture, q[Bio::MAGE::Array::ArrayManufacture]);
isa_ok($arraymanufacture, q[Bio::MAGE::Identifiable]);


# create a subclass
my $bioevent = Bio::MAGE::BioEvent::BioEvent->new();

# testing subclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($bioevent, q[Bio::MAGE::Identifiable]);


# create a subclass
my $experiment = Bio::MAGE::Experiment::Experiment->new();

# testing subclass Experiment
isa_ok($experiment, q[Bio::MAGE::Experiment::Experiment]);
isa_ok($experiment, q[Bio::MAGE::Identifiable]);


# create a subclass
my $experimentalfactor = Bio::MAGE::Experiment::ExperimentalFactor->new();

# testing subclass ExperimentalFactor
isa_ok($experimentalfactor, q[Bio::MAGE::Experiment::ExperimentalFactor]);
isa_ok($experimentalfactor, q[Bio::MAGE::Identifiable]);


# create a subclass
my $factorvalue = Bio::MAGE::Experiment::FactorValue->new();

# testing subclass FactorValue
isa_ok($factorvalue, q[Bio::MAGE::Experiment::FactorValue]);
isa_ok($factorvalue, q[Bio::MAGE::Identifiable]);


# create a subclass
my $parameter = Bio::MAGE::Protocol::Parameter->new();

# testing subclass Parameter
isa_ok($parameter, q[Bio::MAGE::Protocol::Parameter]);
isa_ok($parameter, q[Bio::MAGE::Identifiable]);


# create a subclass
my $biomaterial = Bio::MAGE::BioMaterial::BioMaterial->new();

# testing subclass BioMaterial
isa_ok($biomaterial, q[Bio::MAGE::BioMaterial::BioMaterial]);
isa_ok($biomaterial, q[Bio::MAGE::Identifiable]);


# create a subclass
my $compound = Bio::MAGE::BioMaterial::Compound->new();

# testing subclass Compound
isa_ok($compound, q[Bio::MAGE::BioMaterial::Compound]);
isa_ok($compound, q[Bio::MAGE::Identifiable]);


# create a subclass
my $biosequence = Bio::MAGE::BioSequence::BioSequence->new();

# testing subclass BioSequence
isa_ok($biosequence, q[Bio::MAGE::BioSequence::BioSequence]);
isa_ok($biosequence, q[Bio::MAGE::Identifiable]);


# create a subclass
my $parameterizable = Bio::MAGE::Protocol::Parameterizable->new();

# testing subclass Parameterizable
isa_ok($parameterizable, q[Bio::MAGE::Protocol::Parameterizable]);
isa_ok($parameterizable, q[Bio::MAGE::Identifiable]);


# create a subclass
my $bioassaydatacluster = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new();

# testing subclass BioAssayDataCluster
isa_ok($bioassaydatacluster, q[Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster]);
isa_ok($bioassaydatacluster, q[Bio::MAGE::Identifiable]);



my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($identifiable, q[Bio::MAGE::Describable]);

