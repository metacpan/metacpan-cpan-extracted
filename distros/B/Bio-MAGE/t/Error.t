##############################
#
# Error.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Error.t`

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
use Test::More tests => 184;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::QuantitationType::Error') };

use Bio::MAGE::QuantitationType::ConfidenceIndicator;
use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::QuantitationType::QuantitationType;
use Bio::MAGE::Description::Description;


# we test the new() method
my $error;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $error = Bio::MAGE::QuantitationType::Error->new();
}
isa_ok($error, 'Bio::MAGE::QuantitationType::Error');

# test the package_name class method
is($error->package_name(), q[QuantitationType],
  'package');

# test the class_name class method
is($error->class_name(), q[Bio::MAGE::QuantitationType::Error],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $error = Bio::MAGE::QuantitationType::Error->new(isBackground => '1',
identifier => '2',
name => '3');
}


#
# testing attribute isBackground
#

# test attribute values can be set in new()
is($error->getIsBackground(), '1',
  'isBackground new');

# test getter/setter
$error->setIsBackground('1');
is($error->getIsBackground(), '1',
  'isBackground getter/setter');

# test getter throws exception with argument
eval {$error->getIsBackground(1)};
ok($@, 'isBackground getter throws exception with argument');

# test setter throws exception with no argument
eval {$error->setIsBackground()};
ok($@, 'isBackground setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$error->setIsBackground('1', '1')};
ok($@, 'isBackground setter throws exception with too many argument');

# test setter accepts undef
eval {$error->setIsBackground(undef)};
ok((!$@ and not defined $error->getIsBackground()),
   'isBackground setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($error->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$error->setIdentifier('2');
is($error->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$error->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$error->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$error->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$error->setIdentifier(undef)};
ok((!$@ and not defined $error->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($error->getName(), '3',
  'name new');

# test getter/setter
$error->setName('3');
is($error->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$error->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$error->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$error->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$error->setName(undef)};
ok((!$@ and not defined $error->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::QuantitationType::Error->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $error = Bio::MAGE::QuantitationType::Error->new(dataType => Bio::MAGE::Description::OntologyEntry->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
channel => Bio::MAGE::BioAssay::Channel->new(),
confidenceIndicators => [Bio::MAGE::QuantitationType::ConfidenceIndicator->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
scale => Bio::MAGE::Description::OntologyEntry->new(),
targetQuantitationType => Bio::MAGE::QuantitationType::QuantitationType->new(),
quantitationTypeMaps => [Bio::MAGE::BioAssayData::QuantitationTypeMap->new()]);
}

my ($end, $assn);


# testing association dataType
my $datatype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $datatype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($error->getDataType, q[Bio::MAGE::Description::OntologyEntry]);

is($error->setDataType($datatype_assn), $datatype_assn,
  'setDataType returns value');

ok($error->getDataType() == $datatype_assn,
   'getDataType fetches correct value');

# test setDataType throws exception with bad argument
eval {$error->setDataType(1)};
ok($@, 'setDataType throws exception with bad argument');


# test getDataType throws exception with argument
eval {$error->getDataType(1)};
ok($@, 'getDataType throws exception with argument');

# test setDataType throws exception with no argument
eval {$error->setDataType()};
ok($@, 'setDataType throws exception with no argument');

# test setDataType throws exception with too many argument
eval {$error->setDataType(1,2)};
ok($@, 'setDataType throws exception with too many argument');

# test setDataType accepts undef
eval {$error->setDataType(undef)};
ok((!$@ and not defined $error->getDataType()),
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


ok((UNIVERSAL::isa($error->getAuditTrail,'ARRAY')
 and scalar @{$error->getAuditTrail} == 1
 and UNIVERSAL::isa($error->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($error->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($error->getAuditTrail,'ARRAY')
 and scalar @{$error->getAuditTrail} == 1
 and $error->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($error->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($error->getAuditTrail,'ARRAY')
 and scalar @{$error->getAuditTrail} == 2
 and $error->getAuditTrail->[0] == $audittrail_assn
 and $error->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$error->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$error->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$error->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$error->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$error->setAuditTrail([])};
ok((!$@ and defined $error->getAuditTrail()
    and UNIVERSAL::isa($error->getAuditTrail, 'ARRAY')
    and scalar @{$error->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$error->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$error->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$error->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$error->setAuditTrail(undef)};
ok((!$@ and not defined $error->getAuditTrail()),
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


ok((UNIVERSAL::isa($error->getPropertySets,'ARRAY')
 and scalar @{$error->getPropertySets} == 1
 and UNIVERSAL::isa($error->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($error->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($error->getPropertySets,'ARRAY')
 and scalar @{$error->getPropertySets} == 1
 and $error->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($error->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($error->getPropertySets,'ARRAY')
 and scalar @{$error->getPropertySets} == 2
 and $error->getPropertySets->[0] == $propertysets_assn
 and $error->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$error->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$error->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$error->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$error->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$error->setPropertySets([])};
ok((!$@ and defined $error->getPropertySets()
    and UNIVERSAL::isa($error->getPropertySets, 'ARRAY')
    and scalar @{$error->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$error->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$error->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$error->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$error->setPropertySets(undef)};
ok((!$@ and not defined $error->getPropertySets()),
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


isa_ok($error->getChannel, q[Bio::MAGE::BioAssay::Channel]);

is($error->setChannel($channel_assn), $channel_assn,
  'setChannel returns value');

ok($error->getChannel() == $channel_assn,
   'getChannel fetches correct value');

# test setChannel throws exception with bad argument
eval {$error->setChannel(1)};
ok($@, 'setChannel throws exception with bad argument');


# test getChannel throws exception with argument
eval {$error->getChannel(1)};
ok($@, 'getChannel throws exception with argument');

# test setChannel throws exception with no argument
eval {$error->setChannel()};
ok($@, 'setChannel throws exception with no argument');

# test setChannel throws exception with too many argument
eval {$error->setChannel(1,2)};
ok($@, 'setChannel throws exception with too many argument');

# test setChannel accepts undef
eval {$error->setChannel(undef)};
ok((!$@ and not defined $error->getChannel()),
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


ok((UNIVERSAL::isa($error->getConfidenceIndicators,'ARRAY')
 and scalar @{$error->getConfidenceIndicators} == 1
 and UNIVERSAL::isa($error->getConfidenceIndicators->[0], q[Bio::MAGE::QuantitationType::ConfidenceIndicator])),
  'confidenceIndicators set in new()');

ok(eq_array($error->setConfidenceIndicators([$confidenceindicators_assn]), [$confidenceindicators_assn]),
   'setConfidenceIndicators returns correct value');

ok((UNIVERSAL::isa($error->getConfidenceIndicators,'ARRAY')
 and scalar @{$error->getConfidenceIndicators} == 1
 and $error->getConfidenceIndicators->[0] == $confidenceindicators_assn),
   'getConfidenceIndicators fetches correct value');

is($error->addConfidenceIndicators($confidenceindicators_assn), 2,
  'addConfidenceIndicators returns number of items in list');

ok((UNIVERSAL::isa($error->getConfidenceIndicators,'ARRAY')
 and scalar @{$error->getConfidenceIndicators} == 2
 and $error->getConfidenceIndicators->[0] == $confidenceindicators_assn
 and $error->getConfidenceIndicators->[1] == $confidenceindicators_assn),
  'addConfidenceIndicators adds correct value');

# test setConfidenceIndicators throws exception with non-array argument
eval {$error->setConfidenceIndicators(1)};
ok($@, 'setConfidenceIndicators throws exception with non-array argument');

# test setConfidenceIndicators throws exception with bad argument array
eval {$error->setConfidenceIndicators([1])};
ok($@, 'setConfidenceIndicators throws exception with bad argument array');

# test addConfidenceIndicators throws exception with no arguments
eval {$error->addConfidenceIndicators()};
ok($@, 'addConfidenceIndicators throws exception with no arguments');

# test addConfidenceIndicators throws exception with bad argument
eval {$error->addConfidenceIndicators(1)};
ok($@, 'addConfidenceIndicators throws exception with bad array');

# test setConfidenceIndicators accepts empty array ref
eval {$error->setConfidenceIndicators([])};
ok((!$@ and defined $error->getConfidenceIndicators()
    and UNIVERSAL::isa($error->getConfidenceIndicators, 'ARRAY')
    and scalar @{$error->getConfidenceIndicators} == 0),
   'setConfidenceIndicators accepts empty array ref');


# test getConfidenceIndicators throws exception with argument
eval {$error->getConfidenceIndicators(1)};
ok($@, 'getConfidenceIndicators throws exception with argument');

# test setConfidenceIndicators throws exception with no argument
eval {$error->setConfidenceIndicators()};
ok($@, 'setConfidenceIndicators throws exception with no argument');

# test setConfidenceIndicators throws exception with too many argument
eval {$error->setConfidenceIndicators(1,2)};
ok($@, 'setConfidenceIndicators throws exception with too many argument');

# test setConfidenceIndicators accepts undef
eval {$error->setConfidenceIndicators(undef)};
ok((!$@ and not defined $error->getConfidenceIndicators()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($error->getDescriptions,'ARRAY')
 and scalar @{$error->getDescriptions} == 1
 and UNIVERSAL::isa($error->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($error->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($error->getDescriptions,'ARRAY')
 and scalar @{$error->getDescriptions} == 1
 and $error->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($error->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($error->getDescriptions,'ARRAY')
 and scalar @{$error->getDescriptions} == 2
 and $error->getDescriptions->[0] == $descriptions_assn
 and $error->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$error->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$error->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$error->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$error->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$error->setDescriptions([])};
ok((!$@ and defined $error->getDescriptions()
    and UNIVERSAL::isa($error->getDescriptions, 'ARRAY')
    and scalar @{$error->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$error->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$error->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$error->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$error->setDescriptions(undef)};
ok((!$@ and not defined $error->getDescriptions()),
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


isa_ok($error->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($error->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($error->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$error->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$error->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$error->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$error->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$error->setSecurity(undef)};
ok((!$@ and not defined $error->getSecurity()),
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


isa_ok($error->getScale, q[Bio::MAGE::Description::OntologyEntry]);

is($error->setScale($scale_assn), $scale_assn,
  'setScale returns value');

ok($error->getScale() == $scale_assn,
   'getScale fetches correct value');

# test setScale throws exception with bad argument
eval {$error->setScale(1)};
ok($@, 'setScale throws exception with bad argument');


# test getScale throws exception with argument
eval {$error->getScale(1)};
ok($@, 'getScale throws exception with argument');

# test setScale throws exception with no argument
eval {$error->setScale()};
ok($@, 'setScale throws exception with no argument');

# test setScale throws exception with too many argument
eval {$error->setScale(1,2)};
ok($@, 'setScale throws exception with too many argument');

# test setScale accepts undef
eval {$error->setScale(undef)};
ok((!$@ and not defined $error->getScale()),
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



# testing association targetQuantitationType
my $targetquantitationtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $targetquantitationtype_assn = Bio::MAGE::QuantitationType::QuantitationType->new();
}


isa_ok($error->getTargetQuantitationType, q[Bio::MAGE::QuantitationType::QuantitationType]);

is($error->setTargetQuantitationType($targetquantitationtype_assn), $targetquantitationtype_assn,
  'setTargetQuantitationType returns value');

ok($error->getTargetQuantitationType() == $targetquantitationtype_assn,
   'getTargetQuantitationType fetches correct value');

# test setTargetQuantitationType throws exception with bad argument
eval {$error->setTargetQuantitationType(1)};
ok($@, 'setTargetQuantitationType throws exception with bad argument');


# test getTargetQuantitationType throws exception with argument
eval {$error->getTargetQuantitationType(1)};
ok($@, 'getTargetQuantitationType throws exception with argument');

# test setTargetQuantitationType throws exception with no argument
eval {$error->setTargetQuantitationType()};
ok($@, 'setTargetQuantitationType throws exception with no argument');

# test setTargetQuantitationType throws exception with too many argument
eval {$error->setTargetQuantitationType(1,2)};
ok($@, 'setTargetQuantitationType throws exception with too many argument');

# test setTargetQuantitationType accepts undef
eval {$error->setTargetQuantitationType(undef)};
ok((!$@ and not defined $error->getTargetQuantitationType()),
   'setTargetQuantitationType accepts undef');

# test the meta-data for the assoication
$assn = $assns{targetQuantitationType};
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
   'targetQuantitationType->other() is a valid Bio::MAGE::Association::End'
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
   'targetQuantitationType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association quantitationTypeMaps
my $quantitationtypemaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemaps_assn = Bio::MAGE::BioAssayData::QuantitationTypeMap->new();
}


ok((UNIVERSAL::isa($error->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$error->getQuantitationTypeMaps} == 1
 and UNIVERSAL::isa($error->getQuantitationTypeMaps->[0], q[Bio::MAGE::BioAssayData::QuantitationTypeMap])),
  'quantitationTypeMaps set in new()');

ok(eq_array($error->setQuantitationTypeMaps([$quantitationtypemaps_assn]), [$quantitationtypemaps_assn]),
   'setQuantitationTypeMaps returns correct value');

ok((UNIVERSAL::isa($error->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$error->getQuantitationTypeMaps} == 1
 and $error->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn),
   'getQuantitationTypeMaps fetches correct value');

is($error->addQuantitationTypeMaps($quantitationtypemaps_assn), 2,
  'addQuantitationTypeMaps returns number of items in list');

ok((UNIVERSAL::isa($error->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$error->getQuantitationTypeMaps} == 2
 and $error->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn
 and $error->getQuantitationTypeMaps->[1] == $quantitationtypemaps_assn),
  'addQuantitationTypeMaps adds correct value');

# test setQuantitationTypeMaps throws exception with non-array argument
eval {$error->setQuantitationTypeMaps(1)};
ok($@, 'setQuantitationTypeMaps throws exception with non-array argument');

# test setQuantitationTypeMaps throws exception with bad argument array
eval {$error->setQuantitationTypeMaps([1])};
ok($@, 'setQuantitationTypeMaps throws exception with bad argument array');

# test addQuantitationTypeMaps throws exception with no arguments
eval {$error->addQuantitationTypeMaps()};
ok($@, 'addQuantitationTypeMaps throws exception with no arguments');

# test addQuantitationTypeMaps throws exception with bad argument
eval {$error->addQuantitationTypeMaps(1)};
ok($@, 'addQuantitationTypeMaps throws exception with bad array');

# test setQuantitationTypeMaps accepts empty array ref
eval {$error->setQuantitationTypeMaps([])};
ok((!$@ and defined $error->getQuantitationTypeMaps()
    and UNIVERSAL::isa($error->getQuantitationTypeMaps, 'ARRAY')
    and scalar @{$error->getQuantitationTypeMaps} == 0),
   'setQuantitationTypeMaps accepts empty array ref');


# test getQuantitationTypeMaps throws exception with argument
eval {$error->getQuantitationTypeMaps(1)};
ok($@, 'getQuantitationTypeMaps throws exception with argument');

# test setQuantitationTypeMaps throws exception with no argument
eval {$error->setQuantitationTypeMaps()};
ok($@, 'setQuantitationTypeMaps throws exception with no argument');

# test setQuantitationTypeMaps throws exception with too many argument
eval {$error->setQuantitationTypeMaps(1,2)};
ok($@, 'setQuantitationTypeMaps throws exception with too many argument');

# test setQuantitationTypeMaps accepts undef
eval {$error->setQuantitationTypeMaps(undef)};
ok((!$@ and not defined $error->getQuantitationTypeMaps()),
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





my $confidenceindicator;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $confidenceindicator = Bio::MAGE::QuantitationType::ConfidenceIndicator->new();
}

# testing superclass ConfidenceIndicator
isa_ok($confidenceindicator, q[Bio::MAGE::QuantitationType::ConfidenceIndicator]);
isa_ok($error, q[Bio::MAGE::QuantitationType::ConfidenceIndicator]);

