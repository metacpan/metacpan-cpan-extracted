##############################
#
# Transformation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Transformation.t`

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
use Test::More tests => 178;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::Transformation') };

use Bio::MAGE::BioAssayData::DerivedBioAssayData;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::BioAssayData::BioAssayData;
use Bio::MAGE::BioAssayData::DesignElementMapping;
use Bio::MAGE::BioAssayData::BioAssayMapping;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioAssayData::QuantitationTypeMapping;
use Bio::MAGE::Description::Description;


# we test the new() method
my $transformation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $transformation = Bio::MAGE::BioAssayData::Transformation->new();
}
isa_ok($transformation, 'Bio::MAGE::BioAssayData::Transformation');

# test the package_name class method
is($transformation->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($transformation->class_name(), q[Bio::MAGE::BioAssayData::Transformation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $transformation = Bio::MAGE::BioAssayData::Transformation->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($transformation->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$transformation->setIdentifier('1');
is($transformation->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$transformation->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$transformation->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$transformation->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$transformation->setIdentifier(undef)};
ok((!$@ and not defined $transformation->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($transformation->getName(), '2',
  'name new');

# test getter/setter
$transformation->setName('2');
is($transformation->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$transformation->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$transformation->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$transformation->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$transformation->setName(undef)};
ok((!$@ and not defined $transformation->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::Transformation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $transformation = Bio::MAGE::BioAssayData::Transformation->new(quantitationTypeMapping => Bio::MAGE::BioAssayData::QuantitationTypeMapping->new(),
designElementMapping => Bio::MAGE::BioAssayData::DesignElementMapping->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
bioAssayDataSources => [Bio::MAGE::BioAssayData::BioAssayData->new()],
derivedBioAssayDataTarget => Bio::MAGE::BioAssayData::DerivedBioAssayData->new(),
bioAssayMapping => Bio::MAGE::BioAssayData::BioAssayMapping->new());
}

my ($end, $assn);


# testing association quantitationTypeMapping
my $quantitationtypemapping_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemapping_assn = Bio::MAGE::BioAssayData::QuantitationTypeMapping->new();
}


isa_ok($transformation->getQuantitationTypeMapping, q[Bio::MAGE::BioAssayData::QuantitationTypeMapping]);

is($transformation->setQuantitationTypeMapping($quantitationtypemapping_assn), $quantitationtypemapping_assn,
  'setQuantitationTypeMapping returns value');

ok($transformation->getQuantitationTypeMapping() == $quantitationtypemapping_assn,
   'getQuantitationTypeMapping fetches correct value');

# test setQuantitationTypeMapping throws exception with bad argument
eval {$transformation->setQuantitationTypeMapping(1)};
ok($@, 'setQuantitationTypeMapping throws exception with bad argument');


# test getQuantitationTypeMapping throws exception with argument
eval {$transformation->getQuantitationTypeMapping(1)};
ok($@, 'getQuantitationTypeMapping throws exception with argument');

# test setQuantitationTypeMapping throws exception with no argument
eval {$transformation->setQuantitationTypeMapping()};
ok($@, 'setQuantitationTypeMapping throws exception with no argument');

# test setQuantitationTypeMapping throws exception with too many argument
eval {$transformation->setQuantitationTypeMapping(1,2)};
ok($@, 'setQuantitationTypeMapping throws exception with too many argument');

# test setQuantitationTypeMapping accepts undef
eval {$transformation->setQuantitationTypeMapping(undef)};
ok((!$@ and not defined $transformation->getQuantitationTypeMapping()),
   'setQuantitationTypeMapping accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationTypeMapping};
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
   'quantitationTypeMapping->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationTypeMapping->self() is a valid Bio::MAGE::Association::End'
  );



# testing association designElementMapping
my $designelementmapping_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementmapping_assn = Bio::MAGE::BioAssayData::DesignElementMapping->new();
}


isa_ok($transformation->getDesignElementMapping, q[Bio::MAGE::BioAssayData::DesignElementMapping]);

is($transformation->setDesignElementMapping($designelementmapping_assn), $designelementmapping_assn,
  'setDesignElementMapping returns value');

ok($transformation->getDesignElementMapping() == $designelementmapping_assn,
   'getDesignElementMapping fetches correct value');

# test setDesignElementMapping throws exception with bad argument
eval {$transformation->setDesignElementMapping(1)};
ok($@, 'setDesignElementMapping throws exception with bad argument');


# test getDesignElementMapping throws exception with argument
eval {$transformation->getDesignElementMapping(1)};
ok($@, 'getDesignElementMapping throws exception with argument');

# test setDesignElementMapping throws exception with no argument
eval {$transformation->setDesignElementMapping()};
ok($@, 'setDesignElementMapping throws exception with no argument');

# test setDesignElementMapping throws exception with too many argument
eval {$transformation->setDesignElementMapping(1,2)};
ok($@, 'setDesignElementMapping throws exception with too many argument');

# test setDesignElementMapping accepts undef
eval {$transformation->setDesignElementMapping(undef)};
ok((!$@ and not defined $transformation->getDesignElementMapping()),
   'setDesignElementMapping accepts undef');

# test the meta-data for the assoication
$assn = $assns{designElementMapping};
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
   'designElementMapping->other() is a valid Bio::MAGE::Association::End'
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
   'designElementMapping->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($transformation->getAuditTrail,'ARRAY')
 and scalar @{$transformation->getAuditTrail} == 1
 and UNIVERSAL::isa($transformation->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($transformation->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($transformation->getAuditTrail,'ARRAY')
 and scalar @{$transformation->getAuditTrail} == 1
 and $transformation->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($transformation->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($transformation->getAuditTrail,'ARRAY')
 and scalar @{$transformation->getAuditTrail} == 2
 and $transformation->getAuditTrail->[0] == $audittrail_assn
 and $transformation->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$transformation->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$transformation->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$transformation->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$transformation->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$transformation->setAuditTrail([])};
ok((!$@ and defined $transformation->getAuditTrail()
    and UNIVERSAL::isa($transformation->getAuditTrail, 'ARRAY')
    and scalar @{$transformation->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$transformation->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$transformation->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$transformation->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$transformation->setAuditTrail(undef)};
ok((!$@ and not defined $transformation->getAuditTrail()),
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


ok((UNIVERSAL::isa($transformation->getPropertySets,'ARRAY')
 and scalar @{$transformation->getPropertySets} == 1
 and UNIVERSAL::isa($transformation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($transformation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($transformation->getPropertySets,'ARRAY')
 and scalar @{$transformation->getPropertySets} == 1
 and $transformation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($transformation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($transformation->getPropertySets,'ARRAY')
 and scalar @{$transformation->getPropertySets} == 2
 and $transformation->getPropertySets->[0] == $propertysets_assn
 and $transformation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$transformation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$transformation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$transformation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$transformation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$transformation->setPropertySets([])};
ok((!$@ and defined $transformation->getPropertySets()
    and UNIVERSAL::isa($transformation->getPropertySets, 'ARRAY')
    and scalar @{$transformation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$transformation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$transformation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$transformation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$transformation->setPropertySets(undef)};
ok((!$@ and not defined $transformation->getPropertySets()),
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


ok((UNIVERSAL::isa($transformation->getProtocolApplications,'ARRAY')
 and scalar @{$transformation->getProtocolApplications} == 1
 and UNIVERSAL::isa($transformation->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($transformation->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($transformation->getProtocolApplications,'ARRAY')
 and scalar @{$transformation->getProtocolApplications} == 1
 and $transformation->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($transformation->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($transformation->getProtocolApplications,'ARRAY')
 and scalar @{$transformation->getProtocolApplications} == 2
 and $transformation->getProtocolApplications->[0] == $protocolapplications_assn
 and $transformation->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$transformation->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$transformation->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$transformation->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$transformation->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$transformation->setProtocolApplications([])};
ok((!$@ and defined $transformation->getProtocolApplications()
    and UNIVERSAL::isa($transformation->getProtocolApplications, 'ARRAY')
    and scalar @{$transformation->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$transformation->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$transformation->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$transformation->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$transformation->setProtocolApplications(undef)};
ok((!$@ and not defined $transformation->getProtocolApplications()),
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


ok((UNIVERSAL::isa($transformation->getDescriptions,'ARRAY')
 and scalar @{$transformation->getDescriptions} == 1
 and UNIVERSAL::isa($transformation->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($transformation->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($transformation->getDescriptions,'ARRAY')
 and scalar @{$transformation->getDescriptions} == 1
 and $transformation->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($transformation->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($transformation->getDescriptions,'ARRAY')
 and scalar @{$transformation->getDescriptions} == 2
 and $transformation->getDescriptions->[0] == $descriptions_assn
 and $transformation->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$transformation->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$transformation->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$transformation->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$transformation->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$transformation->setDescriptions([])};
ok((!$@ and defined $transformation->getDescriptions()
    and UNIVERSAL::isa($transformation->getDescriptions, 'ARRAY')
    and scalar @{$transformation->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$transformation->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$transformation->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$transformation->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$transformation->setDescriptions(undef)};
ok((!$@ and not defined $transformation->getDescriptions()),
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


isa_ok($transformation->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($transformation->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($transformation->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$transformation->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$transformation->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$transformation->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$transformation->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$transformation->setSecurity(undef)};
ok((!$@ and not defined $transformation->getSecurity()),
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



# testing association bioAssayDataSources
my $bioassaydatasources_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatasources_assn = Bio::MAGE::BioAssayData::BioAssayData->new();
}


ok((UNIVERSAL::isa($transformation->getBioAssayDataSources,'ARRAY')
 and scalar @{$transformation->getBioAssayDataSources} == 1
 and UNIVERSAL::isa($transformation->getBioAssayDataSources->[0], q[Bio::MAGE::BioAssayData::BioAssayData])),
  'bioAssayDataSources set in new()');

ok(eq_array($transformation->setBioAssayDataSources([$bioassaydatasources_assn]), [$bioassaydatasources_assn]),
   'setBioAssayDataSources returns correct value');

ok((UNIVERSAL::isa($transformation->getBioAssayDataSources,'ARRAY')
 and scalar @{$transformation->getBioAssayDataSources} == 1
 and $transformation->getBioAssayDataSources->[0] == $bioassaydatasources_assn),
   'getBioAssayDataSources fetches correct value');

is($transformation->addBioAssayDataSources($bioassaydatasources_assn), 2,
  'addBioAssayDataSources returns number of items in list');

ok((UNIVERSAL::isa($transformation->getBioAssayDataSources,'ARRAY')
 and scalar @{$transformation->getBioAssayDataSources} == 2
 and $transformation->getBioAssayDataSources->[0] == $bioassaydatasources_assn
 and $transformation->getBioAssayDataSources->[1] == $bioassaydatasources_assn),
  'addBioAssayDataSources adds correct value');

# test setBioAssayDataSources throws exception with non-array argument
eval {$transformation->setBioAssayDataSources(1)};
ok($@, 'setBioAssayDataSources throws exception with non-array argument');

# test setBioAssayDataSources throws exception with bad argument array
eval {$transformation->setBioAssayDataSources([1])};
ok($@, 'setBioAssayDataSources throws exception with bad argument array');

# test addBioAssayDataSources throws exception with no arguments
eval {$transformation->addBioAssayDataSources()};
ok($@, 'addBioAssayDataSources throws exception with no arguments');

# test addBioAssayDataSources throws exception with bad argument
eval {$transformation->addBioAssayDataSources(1)};
ok($@, 'addBioAssayDataSources throws exception with bad array');

# test setBioAssayDataSources accepts empty array ref
eval {$transformation->setBioAssayDataSources([])};
ok((!$@ and defined $transformation->getBioAssayDataSources()
    and UNIVERSAL::isa($transformation->getBioAssayDataSources, 'ARRAY')
    and scalar @{$transformation->getBioAssayDataSources} == 0),
   'setBioAssayDataSources accepts empty array ref');


# test getBioAssayDataSources throws exception with argument
eval {$transformation->getBioAssayDataSources(1)};
ok($@, 'getBioAssayDataSources throws exception with argument');

# test setBioAssayDataSources throws exception with no argument
eval {$transformation->setBioAssayDataSources()};
ok($@, 'setBioAssayDataSources throws exception with no argument');

# test setBioAssayDataSources throws exception with too many argument
eval {$transformation->setBioAssayDataSources(1,2)};
ok($@, 'setBioAssayDataSources throws exception with too many argument');

# test setBioAssayDataSources accepts undef
eval {$transformation->setBioAssayDataSources(undef)};
ok((!$@ and not defined $transformation->getBioAssayDataSources()),
   'setBioAssayDataSources accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayDataSources};
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
   'bioAssayDataSources->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayDataSources->self() is a valid Bio::MAGE::Association::End'
  );



# testing association derivedBioAssayDataTarget
my $derivedbioassaydatatarget_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $derivedbioassaydatatarget_assn = Bio::MAGE::BioAssayData::DerivedBioAssayData->new();
}


isa_ok($transformation->getDerivedBioAssayDataTarget, q[Bio::MAGE::BioAssayData::DerivedBioAssayData]);

is($transformation->setDerivedBioAssayDataTarget($derivedbioassaydatatarget_assn), $derivedbioassaydatatarget_assn,
  'setDerivedBioAssayDataTarget returns value');

ok($transformation->getDerivedBioAssayDataTarget() == $derivedbioassaydatatarget_assn,
   'getDerivedBioAssayDataTarget fetches correct value');

# test setDerivedBioAssayDataTarget throws exception with bad argument
eval {$transformation->setDerivedBioAssayDataTarget(1)};
ok($@, 'setDerivedBioAssayDataTarget throws exception with bad argument');


# test getDerivedBioAssayDataTarget throws exception with argument
eval {$transformation->getDerivedBioAssayDataTarget(1)};
ok($@, 'getDerivedBioAssayDataTarget throws exception with argument');

# test setDerivedBioAssayDataTarget throws exception with no argument
eval {$transformation->setDerivedBioAssayDataTarget()};
ok($@, 'setDerivedBioAssayDataTarget throws exception with no argument');

# test setDerivedBioAssayDataTarget throws exception with too many argument
eval {$transformation->setDerivedBioAssayDataTarget(1,2)};
ok($@, 'setDerivedBioAssayDataTarget throws exception with too many argument');

# test setDerivedBioAssayDataTarget accepts undef
eval {$transformation->setDerivedBioAssayDataTarget(undef)};
ok((!$@ and not defined $transformation->getDerivedBioAssayDataTarget()),
   'setDerivedBioAssayDataTarget accepts undef');

# test the meta-data for the assoication
$assn = $assns{derivedBioAssayDataTarget};
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
   'derivedBioAssayDataTarget->other() is a valid Bio::MAGE::Association::End'
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
   'derivedBioAssayDataTarget->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssayMapping
my $bioassaymapping_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymapping_assn = Bio::MAGE::BioAssayData::BioAssayMapping->new();
}


isa_ok($transformation->getBioAssayMapping, q[Bio::MAGE::BioAssayData::BioAssayMapping]);

is($transformation->setBioAssayMapping($bioassaymapping_assn), $bioassaymapping_assn,
  'setBioAssayMapping returns value');

ok($transformation->getBioAssayMapping() == $bioassaymapping_assn,
   'getBioAssayMapping fetches correct value');

# test setBioAssayMapping throws exception with bad argument
eval {$transformation->setBioAssayMapping(1)};
ok($@, 'setBioAssayMapping throws exception with bad argument');


# test getBioAssayMapping throws exception with argument
eval {$transformation->getBioAssayMapping(1)};
ok($@, 'getBioAssayMapping throws exception with argument');

# test setBioAssayMapping throws exception with no argument
eval {$transformation->setBioAssayMapping()};
ok($@, 'setBioAssayMapping throws exception with no argument');

# test setBioAssayMapping throws exception with too many argument
eval {$transformation->setBioAssayMapping(1,2)};
ok($@, 'setBioAssayMapping throws exception with too many argument');

# test setBioAssayMapping accepts undef
eval {$transformation->setBioAssayMapping(undef)};
ok((!$@ and not defined $transformation->getBioAssayMapping()),
   'setBioAssayMapping accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayMapping};
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
   'bioAssayMapping->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayMapping->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($transformation, q[Bio::MAGE::BioEvent::BioEvent]);

