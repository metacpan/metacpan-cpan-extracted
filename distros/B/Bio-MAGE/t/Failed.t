##############################
#
# Failed.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Failed.t`

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

BEGIN { use_ok('Bio::MAGE::QuantitationType::Failed') };

use Bio::MAGE::QuantitationType::ConfidenceIndicator;
use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $failed;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $failed = Bio::MAGE::QuantitationType::Failed->new();
}
isa_ok($failed, 'Bio::MAGE::QuantitationType::Failed');

# test the package_name class method
is($failed->package_name(), q[QuantitationType],
  'package');

# test the class_name class method
is($failed->class_name(), q[Bio::MAGE::QuantitationType::Failed],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $failed = Bio::MAGE::QuantitationType::Failed->new(isBackground => '1',
identifier => '2',
name => '3');
}


#
# testing attribute isBackground
#

# test attribute values can be set in new()
is($failed->getIsBackground(), '1',
  'isBackground new');

# test getter/setter
$failed->setIsBackground('1');
is($failed->getIsBackground(), '1',
  'isBackground getter/setter');

# test getter throws exception with argument
eval {$failed->getIsBackground(1)};
ok($@, 'isBackground getter throws exception with argument');

# test setter throws exception with no argument
eval {$failed->setIsBackground()};
ok($@, 'isBackground setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$failed->setIsBackground('1', '1')};
ok($@, 'isBackground setter throws exception with too many argument');

# test setter accepts undef
eval {$failed->setIsBackground(undef)};
ok((!$@ and not defined $failed->getIsBackground()),
   'isBackground setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($failed->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$failed->setIdentifier('2');
is($failed->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$failed->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$failed->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$failed->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$failed->setIdentifier(undef)};
ok((!$@ and not defined $failed->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($failed->getName(), '3',
  'name new');

# test getter/setter
$failed->setName('3');
is($failed->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$failed->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$failed->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$failed->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$failed->setName(undef)};
ok((!$@ and not defined $failed->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::QuantitationType::Failed->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $failed = Bio::MAGE::QuantitationType::Failed->new(dataType => Bio::MAGE::Description::OntologyEntry->new(),
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


isa_ok($failed->getDataType, q[Bio::MAGE::Description::OntologyEntry]);

is($failed->setDataType($datatype_assn), $datatype_assn,
  'setDataType returns value');

ok($failed->getDataType() == $datatype_assn,
   'getDataType fetches correct value');

# test setDataType throws exception with bad argument
eval {$failed->setDataType(1)};
ok($@, 'setDataType throws exception with bad argument');


# test getDataType throws exception with argument
eval {$failed->getDataType(1)};
ok($@, 'getDataType throws exception with argument');

# test setDataType throws exception with no argument
eval {$failed->setDataType()};
ok($@, 'setDataType throws exception with no argument');

# test setDataType throws exception with too many argument
eval {$failed->setDataType(1,2)};
ok($@, 'setDataType throws exception with too many argument');

# test setDataType accepts undef
eval {$failed->setDataType(undef)};
ok((!$@ and not defined $failed->getDataType()),
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


ok((UNIVERSAL::isa($failed->getDescriptions,'ARRAY')
 and scalar @{$failed->getDescriptions} == 1
 and UNIVERSAL::isa($failed->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($failed->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($failed->getDescriptions,'ARRAY')
 and scalar @{$failed->getDescriptions} == 1
 and $failed->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($failed->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($failed->getDescriptions,'ARRAY')
 and scalar @{$failed->getDescriptions} == 2
 and $failed->getDescriptions->[0] == $descriptions_assn
 and $failed->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$failed->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$failed->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$failed->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$failed->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$failed->setDescriptions([])};
ok((!$@ and defined $failed->getDescriptions()
    and UNIVERSAL::isa($failed->getDescriptions, 'ARRAY')
    and scalar @{$failed->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$failed->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$failed->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$failed->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$failed->setDescriptions(undef)};
ok((!$@ and not defined $failed->getDescriptions()),
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


isa_ok($failed->getScale, q[Bio::MAGE::Description::OntologyEntry]);

is($failed->setScale($scale_assn), $scale_assn,
  'setScale returns value');

ok($failed->getScale() == $scale_assn,
   'getScale fetches correct value');

# test setScale throws exception with bad argument
eval {$failed->setScale(1)};
ok($@, 'setScale throws exception with bad argument');


# test getScale throws exception with argument
eval {$failed->getScale(1)};
ok($@, 'getScale throws exception with argument');

# test setScale throws exception with no argument
eval {$failed->setScale()};
ok($@, 'setScale throws exception with no argument');

# test setScale throws exception with too many argument
eval {$failed->setScale(1,2)};
ok($@, 'setScale throws exception with too many argument');

# test setScale accepts undef
eval {$failed->setScale(undef)};
ok((!$@ and not defined $failed->getScale()),
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


isa_ok($failed->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($failed->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($failed->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$failed->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$failed->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$failed->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$failed->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$failed->setSecurity(undef)};
ok((!$@ and not defined $failed->getSecurity()),
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


ok((UNIVERSAL::isa($failed->getAuditTrail,'ARRAY')
 and scalar @{$failed->getAuditTrail} == 1
 and UNIVERSAL::isa($failed->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($failed->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($failed->getAuditTrail,'ARRAY')
 and scalar @{$failed->getAuditTrail} == 1
 and $failed->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($failed->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($failed->getAuditTrail,'ARRAY')
 and scalar @{$failed->getAuditTrail} == 2
 and $failed->getAuditTrail->[0] == $audittrail_assn
 and $failed->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$failed->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$failed->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$failed->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$failed->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$failed->setAuditTrail([])};
ok((!$@ and defined $failed->getAuditTrail()
    and UNIVERSAL::isa($failed->getAuditTrail, 'ARRAY')
    and scalar @{$failed->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$failed->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$failed->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$failed->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$failed->setAuditTrail(undef)};
ok((!$@ and not defined $failed->getAuditTrail()),
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


isa_ok($failed->getChannel, q[Bio::MAGE::BioAssay::Channel]);

is($failed->setChannel($channel_assn), $channel_assn,
  'setChannel returns value');

ok($failed->getChannel() == $channel_assn,
   'getChannel fetches correct value');

# test setChannel throws exception with bad argument
eval {$failed->setChannel(1)};
ok($@, 'setChannel throws exception with bad argument');


# test getChannel throws exception with argument
eval {$failed->getChannel(1)};
ok($@, 'getChannel throws exception with argument');

# test setChannel throws exception with no argument
eval {$failed->setChannel()};
ok($@, 'setChannel throws exception with no argument');

# test setChannel throws exception with too many argument
eval {$failed->setChannel(1,2)};
ok($@, 'setChannel throws exception with too many argument');

# test setChannel accepts undef
eval {$failed->setChannel(undef)};
ok((!$@ and not defined $failed->getChannel()),
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


ok((UNIVERSAL::isa($failed->getPropertySets,'ARRAY')
 and scalar @{$failed->getPropertySets} == 1
 and UNIVERSAL::isa($failed->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($failed->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($failed->getPropertySets,'ARRAY')
 and scalar @{$failed->getPropertySets} == 1
 and $failed->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($failed->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($failed->getPropertySets,'ARRAY')
 and scalar @{$failed->getPropertySets} == 2
 and $failed->getPropertySets->[0] == $propertysets_assn
 and $failed->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$failed->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$failed->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$failed->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$failed->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$failed->setPropertySets([])};
ok((!$@ and defined $failed->getPropertySets()
    and UNIVERSAL::isa($failed->getPropertySets, 'ARRAY')
    and scalar @{$failed->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$failed->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$failed->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$failed->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$failed->setPropertySets(undef)};
ok((!$@ and not defined $failed->getPropertySets()),
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


ok((UNIVERSAL::isa($failed->getConfidenceIndicators,'ARRAY')
 and scalar @{$failed->getConfidenceIndicators} == 1
 and UNIVERSAL::isa($failed->getConfidenceIndicators->[0], q[Bio::MAGE::QuantitationType::ConfidenceIndicator])),
  'confidenceIndicators set in new()');

ok(eq_array($failed->setConfidenceIndicators([$confidenceindicators_assn]), [$confidenceindicators_assn]),
   'setConfidenceIndicators returns correct value');

ok((UNIVERSAL::isa($failed->getConfidenceIndicators,'ARRAY')
 and scalar @{$failed->getConfidenceIndicators} == 1
 and $failed->getConfidenceIndicators->[0] == $confidenceindicators_assn),
   'getConfidenceIndicators fetches correct value');

is($failed->addConfidenceIndicators($confidenceindicators_assn), 2,
  'addConfidenceIndicators returns number of items in list');

ok((UNIVERSAL::isa($failed->getConfidenceIndicators,'ARRAY')
 and scalar @{$failed->getConfidenceIndicators} == 2
 and $failed->getConfidenceIndicators->[0] == $confidenceindicators_assn
 and $failed->getConfidenceIndicators->[1] == $confidenceindicators_assn),
  'addConfidenceIndicators adds correct value');

# test setConfidenceIndicators throws exception with non-array argument
eval {$failed->setConfidenceIndicators(1)};
ok($@, 'setConfidenceIndicators throws exception with non-array argument');

# test setConfidenceIndicators throws exception with bad argument array
eval {$failed->setConfidenceIndicators([1])};
ok($@, 'setConfidenceIndicators throws exception with bad argument array');

# test addConfidenceIndicators throws exception with no arguments
eval {$failed->addConfidenceIndicators()};
ok($@, 'addConfidenceIndicators throws exception with no arguments');

# test addConfidenceIndicators throws exception with bad argument
eval {$failed->addConfidenceIndicators(1)};
ok($@, 'addConfidenceIndicators throws exception with bad array');

# test setConfidenceIndicators accepts empty array ref
eval {$failed->setConfidenceIndicators([])};
ok((!$@ and defined $failed->getConfidenceIndicators()
    and UNIVERSAL::isa($failed->getConfidenceIndicators, 'ARRAY')
    and scalar @{$failed->getConfidenceIndicators} == 0),
   'setConfidenceIndicators accepts empty array ref');


# test getConfidenceIndicators throws exception with argument
eval {$failed->getConfidenceIndicators(1)};
ok($@, 'getConfidenceIndicators throws exception with argument');

# test setConfidenceIndicators throws exception with no argument
eval {$failed->setConfidenceIndicators()};
ok($@, 'setConfidenceIndicators throws exception with no argument');

# test setConfidenceIndicators throws exception with too many argument
eval {$failed->setConfidenceIndicators(1,2)};
ok($@, 'setConfidenceIndicators throws exception with too many argument');

# test setConfidenceIndicators accepts undef
eval {$failed->setConfidenceIndicators(undef)};
ok((!$@ and not defined $failed->getConfidenceIndicators()),
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


ok((UNIVERSAL::isa($failed->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$failed->getQuantitationTypeMaps} == 1
 and UNIVERSAL::isa($failed->getQuantitationTypeMaps->[0], q[Bio::MAGE::BioAssayData::QuantitationTypeMap])),
  'quantitationTypeMaps set in new()');

ok(eq_array($failed->setQuantitationTypeMaps([$quantitationtypemaps_assn]), [$quantitationtypemaps_assn]),
   'setQuantitationTypeMaps returns correct value');

ok((UNIVERSAL::isa($failed->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$failed->getQuantitationTypeMaps} == 1
 and $failed->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn),
   'getQuantitationTypeMaps fetches correct value');

is($failed->addQuantitationTypeMaps($quantitationtypemaps_assn), 2,
  'addQuantitationTypeMaps returns number of items in list');

ok((UNIVERSAL::isa($failed->getQuantitationTypeMaps,'ARRAY')
 and scalar @{$failed->getQuantitationTypeMaps} == 2
 and $failed->getQuantitationTypeMaps->[0] == $quantitationtypemaps_assn
 and $failed->getQuantitationTypeMaps->[1] == $quantitationtypemaps_assn),
  'addQuantitationTypeMaps adds correct value');

# test setQuantitationTypeMaps throws exception with non-array argument
eval {$failed->setQuantitationTypeMaps(1)};
ok($@, 'setQuantitationTypeMaps throws exception with non-array argument');

# test setQuantitationTypeMaps throws exception with bad argument array
eval {$failed->setQuantitationTypeMaps([1])};
ok($@, 'setQuantitationTypeMaps throws exception with bad argument array');

# test addQuantitationTypeMaps throws exception with no arguments
eval {$failed->addQuantitationTypeMaps()};
ok($@, 'addQuantitationTypeMaps throws exception with no arguments');

# test addQuantitationTypeMaps throws exception with bad argument
eval {$failed->addQuantitationTypeMaps(1)};
ok($@, 'addQuantitationTypeMaps throws exception with bad array');

# test setQuantitationTypeMaps accepts empty array ref
eval {$failed->setQuantitationTypeMaps([])};
ok((!$@ and defined $failed->getQuantitationTypeMaps()
    and UNIVERSAL::isa($failed->getQuantitationTypeMaps, 'ARRAY')
    and scalar @{$failed->getQuantitationTypeMaps} == 0),
   'setQuantitationTypeMaps accepts empty array ref');


# test getQuantitationTypeMaps throws exception with argument
eval {$failed->getQuantitationTypeMaps(1)};
ok($@, 'getQuantitationTypeMaps throws exception with argument');

# test setQuantitationTypeMaps throws exception with no argument
eval {$failed->setQuantitationTypeMaps()};
ok($@, 'setQuantitationTypeMaps throws exception with no argument');

# test setQuantitationTypeMaps throws exception with too many argument
eval {$failed->setQuantitationTypeMaps(1,2)};
ok($@, 'setQuantitationTypeMaps throws exception with too many argument');

# test setQuantitationTypeMaps accepts undef
eval {$failed->setQuantitationTypeMaps(undef)};
ok((!$@ and not defined $failed->getQuantitationTypeMaps()),
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
isa_ok($failed, q[Bio::MAGE::QuantitationType::StandardQuantitationType]);

