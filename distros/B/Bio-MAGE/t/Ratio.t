##############################
#
# Ratio.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ratio.t`

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
use Test::More tests => 171;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::QuantitationType::Ratio') };

use Bio::MAGE::QuantitationType::ConfidenceIndicator;
use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $ratio;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ratio = Bio::MAGE::QuantitationType::Ratio->new();
}
isa_ok($ratio, 'Bio::MAGE::QuantitationType::Ratio');

# test the package_name class method
is($ratio->package_name(), q[QuantitationType],
  'package');

# test the class_name class method
is($ratio->class_name(), q[Bio::MAGE::QuantitationType::Ratio],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ratio = Bio::MAGE::QuantitationType::Ratio->new(isBackground => '1',
identifier => '2',
name => '3');
}


#
# testing attribute isBackground
#

# test attribute values can be set in new()
is($ratio->getIsBackground(), '1',
  'isBackground new');

# test getter/setter
$ratio->setIsBackground('1');
is($ratio->getIsBackground(), '1',
  'isBackground getter/setter');

# test getter throws exception with argument
eval {$ratio->getIsBackground(1)};
ok($@, 'isBackground getter throws exception with argument');

# test setter throws exception with no argument
eval {$ratio->setIsBackground()};
ok($@, 'isBackground setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ratio->setIsBackground('1', '1')};
ok($@, 'isBackground setter throws exception with too many argument');

# test setter accepts undef
eval {$ratio->setIsBackground(undef)};
ok((!$@ and not defined $ratio->getIsBackground()),
   'isBackground setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($ratio->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$ratio->setIdentifier('2');
is($ratio->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$ratio->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$ratio->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ratio->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$ratio->setIdentifier(undef)};
ok((!$@ and not defined $ratio->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($ratio->getName(), '3',
  'name new');

# test getter/setter
$ratio->setName('3');
is($ratio->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$ratio->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$ratio->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ratio->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$ratio->setName(undef)};
ok((!$@ and not defined $ratio->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::QuantitationType::Ratio->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ratio = Bio::MAGE::QuantitationType::Ratio->new(dataType => Bio::MAGE::Description::OntologyEntry->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
scale => Bio::MAGE::Description::OntologyEntry->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
channel => Bio::MAGE::BioAssay::Channel->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
confidenceIndicators => [Bio::MAGE::QuantitationType::ConfidenceIndicator->new()],
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


isa_ok($ratio->getDataType, q[Bio::MAGE::Description::OntologyEntry]);

is($ratio->setDataType($datatype_assn), $datatype_assn,
  'setDataType returns value');

ok($ratio->getDataType() == $datatype_assn,
   'getDataType fetches correct value');

# test setDataType throws exception with bad argument
eval {$ratio->setDataType(1)};
ok($@, 'setDataType throws exception with bad argument');


# test getDataType throws exception with argument
eval {$ratio->getDataType(1)};
ok($@, 'getDataType throws exception with argument');

# test setDataType throws exception with no argument
eval {$ratio->setDataType()};
ok($@, 'setDataType throws exception with no argument');

# test setDataType throws exception with too many argument
eval {$ratio->setDataType(1,2)};
ok($@, 'setDataType throws exception with too many argument');

# test setDataType accepts undef
eval {$ratio->setDataType(undef)};
ok((!$@ and not defined $ratio->getDataType()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($ratio->getDescriptions,'ARRAY')
 and scalar @{$ratio->getDescriptions} == 1
 and UNIVERSAL::isa($ratio->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($ratio->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($ratio->getDescriptions,'ARRAY')
 and scalar @{$ratio->getDescriptions} == 1
 and $ratio->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($ratio->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($ratio->getDescriptions,'ARRAY')
 and scalar @{$ratio->getDescriptions} == 2
 and $ratio->getDescriptions->[0] == $descriptions_assn
 and $ratio->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$ratio->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$ratio->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$ratio->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$ratio->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$ratio->setDescriptions([])};
ok((!$@ and defined $ratio->getDescriptions()
    and UNIVERSAL::isa($ratio->getDescriptions, 'ARRAY')
    and scalar @{$ratio->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$ratio->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$ratio->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$ratio->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$ratio->setDescriptions(undef)};
ok((!$@ and not defined $ratio->getDescriptions()),
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



# testing association scale
my $scale_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $scale_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($ratio->getScale, q[Bio::MAGE::Description::OntologyEntry]);

is($ratio->setScale($scale_assn), $scale_assn,
  'setScale returns value');

ok($ratio->getScale() == $scale_assn,
   'getScale fetches correct value');

# test setScale throws exception with bad argument
eval {$ratio->setScale(1)};
ok($@, 'setScale throws exception with bad argument');


# test getScale throws exception with argument
eval {$ratio->getScale(1)};
ok($@, 'getScale throws exception with argument');

# test setScale throws exception with no argument
eval {$ratio->setScale()};
ok($@, 'setScale throws exception with no argument');

# test setScale throws exception with too many argument
eval {$ratio->setScale(1,2)};
ok($@, 'setScale throws exception with too many argument');

# test setScale accepts undef
eval {$ratio->setScale(undef)};
ok((!$@ and not defined $ratio->getScale()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($ratio->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($ratio->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($ratio->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$ratio->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$ratio->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$ratio->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$ratio->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$ratio->setSecurity(undef)};
ok((!$@ and not defined $ratio->getSecurity()),
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



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($ratio->getAuditTrail,'ARRAY')
 and scalar @{$ratio->getAuditTrail} == 1
 and UNIVERSAL::isa($ratio->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($ratio->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($ratio->getAuditTrail,'ARRAY')
 and scalar @{$ratio->getAuditTrail} == 1
 and $ratio->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($ratio->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($ratio->getAuditTrail,'ARRAY')
 and scalar @{$ratio->getAuditTrail} == 2
 and $ratio->getAuditTrail->[0] == $audittrail_assn
 and $ratio->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$ratio->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$ratio->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$ratio->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$ratio->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$ratio->setAuditTrail([])};
ok((!$@ and defined $ratio->getAuditTrail()
    and UNIVERSAL::isa($ratio->getAuditTrail, 'ARRAY')
    and scalar @{$ratio->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$ratio->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$ratio->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$ratio->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$ratio->setAuditTrail(undef)};
ok((!$@ and not defined $ratio->getAuditTrail()),
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



# testing association channel
my $channel_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channel_assn = Bio::MAGE::BioAssay::Channel->new();
}


isa_ok($ratio->getChannel, q[Bio::MAGE::BioAssay::Channel]);

is($ratio->setChannel($channel_assn), $channel_assn,
  'setChannel returns value');

ok($ratio->getChannel() == $channel_assn,
   'getChannel fetches correct value');

# test setChannel throws exception with bad argument
eval {$ratio->setChannel(1)};
ok($@, 'setChannel throws exception with bad argument');


# test getChannel throws exception with argument
eval {$ratio->getChannel(1)};
ok($@, 'getChannel throws exception with argument');

# test setChannel throws exception with no argument
eval {$ratio->setChannel()};
ok($@, 'setChannel throws exception with no argument');

# test setChannel throws exception with too many argument
eval {$ratio->setChannel(1,2)};
ok($@, 'setChannel throws exception with too many argument');

# test setChannel accepts undef
eval {$ratio->setChannel(undef)};
ok((!$@ and not defined $ratio->getChannel()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($ratio->getPropertySets,'ARRAY')
 and scalar @{$ratio->getPropertySets} == 1
 and UNIVERSAL::isa($ratio->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($ratio->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($ratio->getPropertySets,'ARRAY')
 and scalar @{$ratio->getPropertySets} == 1
 and $ratio->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($ratio->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($ratio->getPropertySets,'ARRAY')
 and scalar @{$ratio->getPropertySets} == 2
 and $ratio->getPropertySets->[0] == $propertysets_assn
 and $ratio->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$ratio->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$ratio->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$ratio->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$ratio->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$ratio->setPropertySets([])};
ok((!$@ and defined $ratio->getPropertySets()
    and UNIVERSAL::isa($ratio->getPropertySets, 'ARRAY')
    and scalar @{$ratio->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$ratio->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$ratio->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$ratio->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$ratio->setPropertySets(undef)};
ok((!$@ and not defined $ratio->getPropertySets()),
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



# testing association confidenceIndicators
my $confidenceindicators_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $confidenceindicators_assn = Bio::MAGE::QuantitationType::ConfidenceIndicator->new();
}


ok((UNIVERSAL::isa($ratio->getConfidenceIndicators,'ARRAY')
 and scalar @{$ratio->getConfidenceIndicators} == 1
 and UNIVERSAL::isa($ratio->getConfidenceIndicators->[0], q[Bio::MAGE::QuantitationType::ConfidenceIndicator])),
  'confidenceIndicators set in new()');

ok(eq_array($ratio->setConfidenceIndicators([$confidenceindicators_assn]), [$confidenceindicators_assn]),
   'setConfidenceIndicators returns correct value');

ok((UNIVERSAL::isa($ratio->getConfidenceIndicators,'ARRAY')
 and scalar @{$ratio->getConfidenceIndicators} == 1
 and $ratio->getConfidenceIndicators->[0] == $confidenceindicators_assn),
   'getConfidenceIndicators fetches correct value');

is($ratio->addConfidenceIndicators($confidenceindicators_assn), 2,
  'addConfidenceIndicators returns number of items in list');

ok((UNIVERSAL::isa($ratio->getConfidenceIndicators,'ARRAY')
 and scalar @{$ratio->getConfidenceIndicators} == 2
 and $ratio->getConfidenceIndicators->[0] == $confidenceindicators_assn
 and $ratio->getConfidenceIndicators->[1] == $confidenceindicators_assn),
  'addConfidenceIndicators adds correct value');

# test setConfidenceIndicators throws exception with non-array argument
eval {$ratio->setConfidenceIndicators(1)};
ok($@, 'setConfidenceIndicators throws exception with non-array argument');

# test setConfidenceIndicators throws exception with bad argument array
eval {$ratio->setConfidenceIndicators([1])};
ok($@, 'setConfidenceIndicators throws exception with bad argument array');

# test addConfidenceIndicators throws exception with no arguments
eval {$ratio->addConfidenceIndicators()};
ok($@, 'addConfidenceIndicators throws exception with no arguments');

# test addConfidenceIndicators throws exception with bad argument
eval {$ratio->addConfidenceIndicators(1)};
ok($@, 'addConfidenceIndicators throws exception with bad array');

# test setConfidenceIndicators accepts empty array ref
eval {$ratio->setConfidenceIndicators([])};
ok((!$@ and defined $ratio->getConfidenceIndicators()
    and UNIVERSAL::isa($ratio->getConfidenceIndicators, 'ARRAY')
    and scalar @{$ratio->getConfidenceIndicators} == 0),
   'setConfidenceIndicators accepts empty array ref');


# test getConfidenceIndicators throws exception with argument
eval {$ratio->getConfidenceIndicators(1)};
ok($@, 'getConfidenceIndicators throws exception with argument');

# test setConfidenceIndicators throws exception with no argument
eval {$ratio->setConfidenceIndicators()};
ok($@, 'setConfidenceIndicators throws exception with no argument');

# test setConfidenceIndicators throws exception with too many argument
eval {$ratio->setConfidenceIndicators(1,2)};
ok($@, 'setConfidenceIndicators throws exception with too many argument');

# test setConfidenceIndicators accepts undef
eval {$ratio->setConfidenceIndicators(undef)};
ok((!$@ and not defined $ratio->getConfidenceIndicators()),
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


ok((UNIVERSAL::isa($ratio->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$ratio->getQuantitationTypeMaps} == 1
 and UNIVERSAL::isa($ratio->getQuantitationTypeMaps->[0], q[Bio::MAGE::BioAssayData::QuantitationTypeMap])),
  'quantitationTypeMaps set in new()');

ok(eq_array($ratio->setQuantitationTypeMaps([$quantitationtypemaps_assn]), [$quantitationtypemaps_assn]),
   'setQuantitationTypeMaps returns correct value');

ok((UNIVERSAL::isa($ratio->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$ratio->getQuantitationTypeMaps} == 1
 and $ratio->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn),
   'getQuantitationTypeMaps fetches correct value');

is($ratio->addQuantitationTypeMaps($quantitationtypemaps_assn), 2,
  'addQuantitationTypeMaps returns number of items in list');

ok((UNIVERSAL::isa($ratio->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$ratio->getQuantitationTypeMaps} == 2
 and $ratio->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn
 and $ratio->getQuantitationTypeMaps->[1] == $quantitationtypemaps_assn),
  'addQuantitationTypeMaps adds correct value');

# test setQuantitationTypeMaps throws exception with non-array argument
eval {$ratio->setQuantitationTypeMaps(1)};
ok($@, 'setQuantitationTypeMaps throws exception with non-array argument');

# test setQuantitationTypeMaps throws exception with bad argument array
eval {$ratio->setQuantitationTypeMaps([1])};
ok($@, 'setQuantitationTypeMaps throws exception with bad argument array');

# test addQuantitationTypeMaps throws exception with no arguments
eval {$ratio->addQuantitationTypeMaps()};
ok($@, 'addQuantitationTypeMaps throws exception with no arguments');

# test addQuantitationTypeMaps throws exception with bad argument
eval {$ratio->addQuantitationTypeMaps(1)};
ok($@, 'addQuantitationTypeMaps throws exception with bad array');

# test setQuantitationTypeMaps accepts empty array ref
eval {$ratio->setQuantitationTypeMaps([])};
ok((!$@ and defined $ratio->getQuantitationTypeMaps()
    and UNIVERSAL::isa($ratio->getQuantitationTypeMaps, 'ARRAY')
    and scalar @{$ratio->getQuantitationTypeMaps} == 0),
   'setQuantitationTypeMaps accepts empty array ref');


# test getQuantitationTypeMaps throws exception with argument
eval {$ratio->getQuantitationTypeMaps(1)};
ok($@, 'getQuantitationTypeMaps throws exception with argument');

# test setQuantitationTypeMaps throws exception with no argument
eval {$ratio->setQuantitationTypeMaps()};
ok($@, 'setQuantitationTypeMaps throws exception with no argument');

# test setQuantitationTypeMaps throws exception with too many argument
eval {$ratio->setQuantitationTypeMaps(1,2)};
ok($@, 'setQuantitationTypeMaps throws exception with too many argument');

# test setQuantitationTypeMaps accepts undef
eval {$ratio->setQuantitationTypeMaps(undef)};
ok((!$@ and not defined $ratio->getQuantitationTypeMaps()),
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





my $standardquantitationtype;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $standardquantitationtype = Bio::MAGE::QuantitationType::StandardQuantitationType->new();
}

# testing superclass StandardQuantitationType
isa_ok($standardquantitationtype, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);
isa_ok($ratio, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);

