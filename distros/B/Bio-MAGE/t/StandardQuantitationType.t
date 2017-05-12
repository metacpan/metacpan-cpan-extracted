##############################
#
# StandardQuantitationType.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl StandardQuantitationType.t`

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
use Test::More tests => 183;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::QuantitationType::StandardQuantitationType') };

use Bio::MAGE::QuantitationType::ConfidenceIndicator;
use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;

use Bio::MAGE::QuantitationType::DerivedSignal;
use Bio::MAGE::QuantitationType::MeasuredSignal;
use Bio::MAGE::QuantitationType::Ratio;
use Bio::MAGE::QuantitationType::ConfidenceIndicator;
use Bio::MAGE::QuantitationType::PresentAbsent;
use Bio::MAGE::QuantitationType::Failed;

# we test the new() method
my $standardquantitationtype;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $standardquantitationtype = Bio::MAGE::QuantitationType::StandardQuantitationType->new();
}
isa_ok($standardquantitationtype, 'Bio::MAGE::QuantitationType::StandardQuantitationType');

# test the package_name class method
is($standardquantitationtype->package_name(), q[QuantitationType],
  'package');

# test the class_name class method
is($standardquantitationtype->class_name(), q[Bio::MAGE::QuantitationType::StandardQuantitationType],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $standardquantitationtype = Bio::MAGE::QuantitationType::StandardQuantitationType->new(isBackground => '1',
identifier => '2',
name => '3');
}


#
# testing attribute isBackground
#

# test attribute values can be set in new()
is($standardquantitationtype->getIsBackground(), '1',
  'isBackground new');

# test getter/setter
$standardquantitationtype->setIsBackground('1');
is($standardquantitationtype->getIsBackground(), '1',
  'isBackground getter/setter');

# test getter throws exception with argument
eval {$standardquantitationtype->getIsBackground(1)};
ok($@, 'isBackground getter throws exception with argument');

# test setter throws exception with no argument
eval {$standardquantitationtype->setIsBackground()};
ok($@, 'isBackground setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$standardquantitationtype->setIsBackground('1', '1')};
ok($@, 'isBackground setter throws exception with too many argument');

# test setter accepts undef
eval {$standardquantitationtype->setIsBackground(undef)};
ok((!$@ and not defined $standardquantitationtype->getIsBackground()),
   'isBackground setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($standardquantitationtype->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$standardquantitationtype->setIdentifier('2');
is($standardquantitationtype->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$standardquantitationtype->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$standardquantitationtype->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$standardquantitationtype->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$standardquantitationtype->setIdentifier(undef)};
ok((!$@ and not defined $standardquantitationtype->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($standardquantitationtype->getName(), '3',
  'name new');

# test getter/setter
$standardquantitationtype->setName('3');
is($standardquantitationtype->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$standardquantitationtype->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$standardquantitationtype->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$standardquantitationtype->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$standardquantitationtype->setName(undef)};
ok((!$@ and not defined $standardquantitationtype->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::QuantitationType::StandardQuantitationType->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $standardquantitationtype = Bio::MAGE::QuantitationType::StandardQuantitationType->new(descriptions => [Bio::MAGE::Description::Description->new()],
dataType => Bio::MAGE::Description::OntologyEntry->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
scale => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
channel => Bio::MAGE::BioAssay::Channel->new(),
confidenceIndicators => [Bio::MAGE::QuantitationType::ConfidenceIndicator->new()],
quantitationTypeMaps => [Bio::MAGE::BioAssayData::QuantitationTypeMap->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($standardquantitationtype->getDescriptions,'ARRAY')
 and scalar @{$standardquantitationtype->getDescriptions} == 1
 and UNIVERSAL::isa($standardquantitationtype->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($standardquantitationtype->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($standardquantitationtype->getDescriptions,'ARRAY')
 and scalar @{$standardquantitationtype->getDescriptions} == 1
 and $standardquantitationtype->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($standardquantitationtype->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($standardquantitationtype->getDescriptions,'ARRAY')
 and scalar @{$standardquantitationtype->getDescriptions} == 2
 and $standardquantitationtype->getDescriptions->[0] == $descriptions_assn
 and $standardquantitationtype->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$standardquantitationtype->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$standardquantitationtype->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$standardquantitationtype->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$standardquantitationtype->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$standardquantitationtype->setDescriptions([])};
ok((!$@ and defined $standardquantitationtype->getDescriptions()
    and UNIVERSAL::isa($standardquantitationtype->getDescriptions, 'ARRAY')
    and scalar @{$standardquantitationtype->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$standardquantitationtype->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$standardquantitationtype->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$standardquantitationtype->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$standardquantitationtype->setDescriptions(undef)};
ok((!$@ and not defined $standardquantitationtype->getDescriptions()),
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



# testing association dataType
my $datatype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $datatype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($standardquantitationtype->getDataType, q[Bio::MAGE::Description::OntologyEntry]);

is($standardquantitationtype->setDataType($datatype_assn), $datatype_assn,
  'setDataType returns value');

ok($standardquantitationtype->getDataType() == $datatype_assn,
   'getDataType fetches correct value');

# test setDataType throws exception with bad argument
eval {$standardquantitationtype->setDataType(1)};
ok($@, 'setDataType throws exception with bad argument');


# test getDataType throws exception with argument
eval {$standardquantitationtype->getDataType(1)};
ok($@, 'getDataType throws exception with argument');

# test setDataType throws exception with no argument
eval {$standardquantitationtype->setDataType()};
ok($@, 'setDataType throws exception with no argument');

# test setDataType throws exception with too many argument
eval {$standardquantitationtype->setDataType(1,2)};
ok($@, 'setDataType throws exception with too many argument');

# test setDataType accepts undef
eval {$standardquantitationtype->setDataType(undef)};
ok((!$@ and not defined $standardquantitationtype->getDataType()),
   'setDataType accepts undef');

# test the meta-data for the assoication
$assn = $assns{dataType};
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
   'dataType->other() is a valid Bio::MAGE::Association::End'
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
   'dataType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($standardquantitationtype->getAuditTrail,'ARRAY')
 and scalar @{$standardquantitationtype->getAuditTrail} == 1
 and UNIVERSAL::isa($standardquantitationtype->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($standardquantitationtype->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($standardquantitationtype->getAuditTrail,'ARRAY')
 and scalar @{$standardquantitationtype->getAuditTrail} == 1
 and $standardquantitationtype->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($standardquantitationtype->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($standardquantitationtype->getAuditTrail,'ARRAY')
 and scalar @{$standardquantitationtype->getAuditTrail} == 2
 and $standardquantitationtype->getAuditTrail->[0] == $audittrail_assn
 and $standardquantitationtype->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$standardquantitationtype->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$standardquantitationtype->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$standardquantitationtype->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$standardquantitationtype->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$standardquantitationtype->setAuditTrail([])};
ok((!$@ and defined $standardquantitationtype->getAuditTrail()
    and UNIVERSAL::isa($standardquantitationtype->getAuditTrail, 'ARRAY')
    and scalar @{$standardquantitationtype->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$standardquantitationtype->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$standardquantitationtype->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$standardquantitationtype->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$standardquantitationtype->setAuditTrail(undef)};
ok((!$@ and not defined $standardquantitationtype->getAuditTrail()),
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


isa_ok($standardquantitationtype->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($standardquantitationtype->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($standardquantitationtype->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$standardquantitationtype->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$standardquantitationtype->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$standardquantitationtype->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$standardquantitationtype->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$standardquantitationtype->setSecurity(undef)};
ok((!$@ and not defined $standardquantitationtype->getSecurity()),
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



# testing association scale
my $scale_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $scale_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($standardquantitationtype->getScale, q[Bio::MAGE::Description::OntologyEntry]);

is($standardquantitationtype->setScale($scale_assn), $scale_assn,
  'setScale returns value');

ok($standardquantitationtype->getScale() == $scale_assn,
   'getScale fetches correct value');

# test setScale throws exception with bad argument
eval {$standardquantitationtype->setScale(1)};
ok($@, 'setScale throws exception with bad argument');


# test getScale throws exception with argument
eval {$standardquantitationtype->getScale(1)};
ok($@, 'getScale throws exception with argument');

# test setScale throws exception with no argument
eval {$standardquantitationtype->setScale()};
ok($@, 'setScale throws exception with no argument');

# test setScale throws exception with too many argument
eval {$standardquantitationtype->setScale(1,2)};
ok($@, 'setScale throws exception with too many argument');

# test setScale accepts undef
eval {$standardquantitationtype->setScale(undef)};
ok((!$@ and not defined $standardquantitationtype->getScale()),
   'setScale accepts undef');

# test the meta-data for the assoication
$assn = $assns{scale};
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
   'scale->other() is a valid Bio::MAGE::Association::End'
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
   'scale->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($standardquantitationtype->getPropertySets,'ARRAY')
 and scalar @{$standardquantitationtype->getPropertySets} == 1
 and UNIVERSAL::isa($standardquantitationtype->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($standardquantitationtype->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($standardquantitationtype->getPropertySets,'ARRAY')
 and scalar @{$standardquantitationtype->getPropertySets} == 1
 and $standardquantitationtype->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($standardquantitationtype->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($standardquantitationtype->getPropertySets,'ARRAY')
 and scalar @{$standardquantitationtype->getPropertySets} == 2
 and $standardquantitationtype->getPropertySets->[0] == $propertysets_assn
 and $standardquantitationtype->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$standardquantitationtype->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$standardquantitationtype->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$standardquantitationtype->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$standardquantitationtype->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$standardquantitationtype->setPropertySets([])};
ok((!$@ and defined $standardquantitationtype->getPropertySets()
    and UNIVERSAL::isa($standardquantitationtype->getPropertySets, 'ARRAY')
    and scalar @{$standardquantitationtype->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$standardquantitationtype->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$standardquantitationtype->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$standardquantitationtype->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$standardquantitationtype->setPropertySets(undef)};
ok((!$@ and not defined $standardquantitationtype->getPropertySets()),
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



# testing association channel
my $channel_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channel_assn = Bio::MAGE::BioAssay::Channel->new();
}


isa_ok($standardquantitationtype->getChannel, q[Bio::MAGE::BioAssay::Channel]);

is($standardquantitationtype->setChannel($channel_assn), $channel_assn,
  'setChannel returns value');

ok($standardquantitationtype->getChannel() == $channel_assn,
   'getChannel fetches correct value');

# test setChannel throws exception with bad argument
eval {$standardquantitationtype->setChannel(1)};
ok($@, 'setChannel throws exception with bad argument');


# test getChannel throws exception with argument
eval {$standardquantitationtype->getChannel(1)};
ok($@, 'getChannel throws exception with argument');

# test setChannel throws exception with no argument
eval {$standardquantitationtype->setChannel()};
ok($@, 'setChannel throws exception with no argument');

# test setChannel throws exception with too many argument
eval {$standardquantitationtype->setChannel(1,2)};
ok($@, 'setChannel throws exception with too many argument');

# test setChannel accepts undef
eval {$standardquantitationtype->setChannel(undef)};
ok((!$@ and not defined $standardquantitationtype->getChannel()),
   'setChannel accepts undef');

# test the meta-data for the assoication
$assn = $assns{channel};
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
   'channel->other() is a valid Bio::MAGE::Association::End'
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
   'channel->self() is a valid Bio::MAGE::Association::End'
  );



# testing association confidenceIndicators
my $confidenceindicators_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $confidenceindicators_assn = Bio::MAGE::QuantitationType::ConfidenceIndicator->new();
}


ok((UNIVERSAL::isa($standardquantitationtype->getConfidenceIndicators,'ARRAY')
 and scalar @{$standardquantitationtype->getConfidenceIndicators} == 1
 and UNIVERSAL::isa($standardquantitationtype->getConfidenceIndicators->[0], q[Bio::MAGE::QuantitationType::ConfidenceIndicator])),
  'confidenceIndicators set in new()');

ok(eq_array($standardquantitationtype->setConfidenceIndicators([$confidenceindicators_assn]), [$confidenceindicators_assn]),
   'setConfidenceIndicators returns correct value');

ok((UNIVERSAL::isa($standardquantitationtype->getConfidenceIndicators,'ARRAY')
 and scalar @{$standardquantitationtype->getConfidenceIndicators} == 1
 and $standardquantitationtype->getConfidenceIndicators->[0] == $confidenceindicators_assn),
   'getConfidenceIndicators fetches correct value');

is($standardquantitationtype->addConfidenceIndicators($confidenceindicators_assn), 2,
  'addConfidenceIndicators returns number of items in list');

ok((UNIVERSAL::isa($standardquantitationtype->getConfidenceIndicators,'ARRAY')
 and scalar @{$standardquantitationtype->getConfidenceIndicators} == 2
 and $standardquantitationtype->getConfidenceIndicators->[0] == $confidenceindicators_assn
 and $standardquantitationtype->getConfidenceIndicators->[1] == $confidenceindicators_assn),
  'addConfidenceIndicators adds correct value');

# test setConfidenceIndicators throws exception with non-array argument
eval {$standardquantitationtype->setConfidenceIndicators(1)};
ok($@, 'setConfidenceIndicators throws exception with non-array argument');

# test setConfidenceIndicators throws exception with bad argument array
eval {$standardquantitationtype->setConfidenceIndicators([1])};
ok($@, 'setConfidenceIndicators throws exception with bad argument array');

# test addConfidenceIndicators throws exception with no arguments
eval {$standardquantitationtype->addConfidenceIndicators()};
ok($@, 'addConfidenceIndicators throws exception with no arguments');

# test addConfidenceIndicators throws exception with bad argument
eval {$standardquantitationtype->addConfidenceIndicators(1)};
ok($@, 'addConfidenceIndicators throws exception with bad array');

# test setConfidenceIndicators accepts empty array ref
eval {$standardquantitationtype->setConfidenceIndicators([])};
ok((!$@ and defined $standardquantitationtype->getConfidenceIndicators()
    and UNIVERSAL::isa($standardquantitationtype->getConfidenceIndicators, 'ARRAY')
    and scalar @{$standardquantitationtype->getConfidenceIndicators} == 0),
   'setConfidenceIndicators accepts empty array ref');


# test getConfidenceIndicators throws exception with argument
eval {$standardquantitationtype->getConfidenceIndicators(1)};
ok($@, 'getConfidenceIndicators throws exception with argument');

# test setConfidenceIndicators throws exception with no argument
eval {$standardquantitationtype->setConfidenceIndicators()};
ok($@, 'setConfidenceIndicators throws exception with no argument');

# test setConfidenceIndicators throws exception with too many argument
eval {$standardquantitationtype->setConfidenceIndicators(1,2)};
ok($@, 'setConfidenceIndicators throws exception with too many argument');

# test setConfidenceIndicators accepts undef
eval {$standardquantitationtype->setConfidenceIndicators(undef)};
ok((!$@ and not defined $standardquantitationtype->getConfidenceIndicators()),
   'setConfidenceIndicators accepts undef');

# test the meta-data for the assoication
$assn = $assns{confidenceIndicators};
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
   'confidenceIndicators->other() is a valid Bio::MAGE::Association::End'
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
   'confidenceIndicators->self() is a valid Bio::MAGE::Association::End'
  );



# testing association quantitationTypeMaps
my $quantitationtypemaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemaps_assn = Bio::MAGE::BioAssayData::QuantitationTypeMap->new();
}


ok((UNIVERSAL::isa($standardquantitationtype->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$standardquantitationtype->getQuantitationTypeMaps} == 1
 and UNIVERSAL::isa($standardquantitationtype->getQuantitationTypeMaps->[0], q[Bio::MAGE::BioAssayData::QuantitationTypeMap])),
  'quantitationTypeMaps set in new()');

ok(eq_array($standardquantitationtype->setQuantitationTypeMaps([$quantitationtypemaps_assn]), [$quantitationtypemaps_assn]),
   'setQuantitationTypeMaps returns correct value');

ok((UNIVERSAL::isa($standardquantitationtype->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$standardquantitationtype->getQuantitationTypeMaps} == 1
 and $standardquantitationtype->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn),
   'getQuantitationTypeMaps fetches correct value');

is($standardquantitationtype->addQuantitationTypeMaps($quantitationtypemaps_assn), 2,
  'addQuantitationTypeMaps returns number of items in list');

ok((UNIVERSAL::isa($standardquantitationtype->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$standardquantitationtype->getQuantitationTypeMaps} == 2
 and $standardquantitationtype->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn
 and $standardquantitationtype->getQuantitationTypeMaps->[1] == $quantitationtypemaps_assn),
  'addQuantitationTypeMaps adds correct value');

# test setQuantitationTypeMaps throws exception with non-array argument
eval {$standardquantitationtype->setQuantitationTypeMaps(1)};
ok($@, 'setQuantitationTypeMaps throws exception with non-array argument');

# test setQuantitationTypeMaps throws exception with bad argument array
eval {$standardquantitationtype->setQuantitationTypeMaps([1])};
ok($@, 'setQuantitationTypeMaps throws exception with bad argument array');

# test addQuantitationTypeMaps throws exception with no arguments
eval {$standardquantitationtype->addQuantitationTypeMaps()};
ok($@, 'addQuantitationTypeMaps throws exception with no arguments');

# test addQuantitationTypeMaps throws exception with bad argument
eval {$standardquantitationtype->addQuantitationTypeMaps(1)};
ok($@, 'addQuantitationTypeMaps throws exception with bad array');

# test setQuantitationTypeMaps accepts empty array ref
eval {$standardquantitationtype->setQuantitationTypeMaps([])};
ok((!$@ and defined $standardquantitationtype->getQuantitationTypeMaps()
    and UNIVERSAL::isa($standardquantitationtype->getQuantitationTypeMaps, 'ARRAY')
    and scalar @{$standardquantitationtype->getQuantitationTypeMaps} == 0),
   'setQuantitationTypeMaps accepts empty array ref');


# test getQuantitationTypeMaps throws exception with argument
eval {$standardquantitationtype->getQuantitationTypeMaps(1)};
ok($@, 'getQuantitationTypeMaps throws exception with argument');

# test setQuantitationTypeMaps throws exception with no argument
eval {$standardquantitationtype->setQuantitationTypeMaps()};
ok($@, 'setQuantitationTypeMaps throws exception with no argument');

# test setQuantitationTypeMaps throws exception with too many argument
eval {$standardquantitationtype->setQuantitationTypeMaps(1,2)};
ok($@, 'setQuantitationTypeMaps throws exception with too many argument');

# test setQuantitationTypeMaps accepts undef
eval {$standardquantitationtype->setQuantitationTypeMaps(undef)};
ok((!$@ and not defined $standardquantitationtype->getQuantitationTypeMaps()),
   'setQuantitationTypeMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationTypeMaps};
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
   'quantitationTypeMaps->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationTypeMaps->self() is a valid Bio::MAGE::Association::End'
  );




# create a subclass
my $derivedsignal = Bio::MAGE::QuantitationType::DerivedSignal->new();

# testing subclass DerivedSignal
isa_ok($derivedsignal, q[Bio::MAGE::QuantitationType::DerivedSignal]);
isa_ok($derivedsignal, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);


# create a subclass
my $measuredsignal = Bio::MAGE::QuantitationType::MeasuredSignal->new();

# testing subclass MeasuredSignal
isa_ok($measuredsignal, q[Bio::MAGE::QuantitationType::MeasuredSignal]);
isa_ok($measuredsignal, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);


# create a subclass
my $ratio = Bio::MAGE::QuantitationType::Ratio->new();

# testing subclass Ratio
isa_ok($ratio, q[Bio::MAGE::QuantitationType::Ratio]);
isa_ok($ratio, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);


# create a subclass
my $confidenceindicator = Bio::MAGE::QuantitationType::ConfidenceIndicator->new();

# testing subclass ConfidenceIndicator
isa_ok($confidenceindicator, q[Bio::MAGE::QuantitationType::ConfidenceIndicator]);
isa_ok($confidenceindicator, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);


# create a subclass
my $presentabsent = Bio::MAGE::QuantitationType::PresentAbsent->new();

# testing subclass PresentAbsent
isa_ok($presentabsent, q[Bio::MAGE::QuantitationType::PresentAbsent]);
isa_ok($presentabsent, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);


# create a subclass
my $failed = Bio::MAGE::QuantitationType::Failed->new();

# testing subclass Failed
isa_ok($failed, q[Bio::MAGE::QuantitationType::Failed]);
isa_ok($failed, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);



my $quantitationtype;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $quantitationtype = Bio::MAGE::QuantitationType::QuantitationType->new();
}

# testing superclass QuantitationType
isa_ok($quantitationtype, q[Bio::MAGE::QuantitationType::QuantitationType]);
isa_ok($standardquantitationtype, q[Bio::MAGE::QuantitationType::QuantitationType]);

