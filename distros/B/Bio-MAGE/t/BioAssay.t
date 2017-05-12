##############################
#
# BioAssay.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssay.t`

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
use Test::More tests => 132;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::BioAssay') };

use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;

use Bio::MAGE::BioAssay::PhysicalBioAssay;
use Bio::MAGE::BioAssay::DerivedBioAssay;
use Bio::MAGE::BioAssay::MeasuredBioAssay;

# we test the new() method
my $bioassay;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassay = Bio::MAGE::BioAssay::BioAssay->new();
}
isa_ok($bioassay, 'Bio::MAGE::BioAssay::BioAssay');

# test the package_name class method
is($bioassay->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($bioassay->class_name(), q[Bio::MAGE::BioAssay::BioAssay],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassay = Bio::MAGE::BioAssay::BioAssay->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassay->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassay->setIdentifier('1');
is($bioassay->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassay->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassay->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassay->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassay->setIdentifier(undef)};
ok((!$@ and not defined $bioassay->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassay->getName(), '2',
  'name new');

# test getter/setter
$bioassay->setName('2');
is($bioassay->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassay->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassay->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassay->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassay->setName(undef)};
ok((!$@ and not defined $bioassay->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::BioAssay->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassay = Bio::MAGE::BioAssay::BioAssay->new(bioAssayFactorValues => [Bio::MAGE::Experiment::FactorValue->new()],
channels => [Bio::MAGE::BioAssay::Channel->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association bioAssayFactorValues
my $bioassayfactorvalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassayfactorvalues_assn = Bio::MAGE::Experiment::FactorValue->new();
}


ok((UNIVERSAL::isa($bioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$bioassay->getBioAssayFactorValues} == 1
 and UNIVERSAL::isa($bioassay->getBioAssayFactorValues->[0], q[Bio::MAGE::Experiment::FactorValue])),
  'bioAssayFactorValues set in new()');

ok(eq_array($bioassay->setBioAssayFactorValues([$bioassayfactorvalues_assn]), [$bioassayfactorvalues_assn]),
   'setBioAssayFactorValues returns correct value');

ok((UNIVERSAL::isa($bioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$bioassay->getBioAssayFactorValues} == 1
 and $bioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn),
   'getBioAssayFactorValues fetches correct value');

is($bioassay->addBioAssayFactorValues($bioassayfactorvalues_assn), 2,
  'addBioAssayFactorValues returns number of items in list');

ok((UNIVERSAL::isa($bioassay->getBioAssayFactorValues,'ARRAY')
 and scalar @{$bioassay->getBioAssayFactorValues} == 2
 and $bioassay->getBioAssayFactorValues->[0] == $bioassayfactorvalues_assn
 and $bioassay->getBioAssayFactorValues->[1] == $bioassayfactorvalues_assn),
  'addBioAssayFactorValues adds correct value');

# test setBioAssayFactorValues throws exception with non-array argument
eval {$bioassay->setBioAssayFactorValues(1)};
ok($@, 'setBioAssayFactorValues throws exception with non-array argument');

# test setBioAssayFactorValues throws exception with bad argument array
eval {$bioassay->setBioAssayFactorValues([1])};
ok($@, 'setBioAssayFactorValues throws exception with bad argument array');

# test addBioAssayFactorValues throws exception with no arguments
eval {$bioassay->addBioAssayFactorValues()};
ok($@, 'addBioAssayFactorValues throws exception with no arguments');

# test addBioAssayFactorValues throws exception with bad argument
eval {$bioassay->addBioAssayFactorValues(1)};
ok($@, 'addBioAssayFactorValues throws exception with bad array');

# test setBioAssayFactorValues accepts empty array ref
eval {$bioassay->setBioAssayFactorValues([])};
ok((!$@ and defined $bioassay->getBioAssayFactorValues()
    and UNIVERSAL::isa($bioassay->getBioAssayFactorValues, 'ARRAY')
    and scalar @{$bioassay->getBioAssayFactorValues} == 0),
   'setBioAssayFactorValues accepts empty array ref');


# test getBioAssayFactorValues throws exception with argument
eval {$bioassay->getBioAssayFactorValues(1)};
ok($@, 'getBioAssayFactorValues throws exception with argument');

# test setBioAssayFactorValues throws exception with no argument
eval {$bioassay->setBioAssayFactorValues()};
ok($@, 'setBioAssayFactorValues throws exception with no argument');

# test setBioAssayFactorValues throws exception with too many argument
eval {$bioassay->setBioAssayFactorValues(1,2)};
ok($@, 'setBioAssayFactorValues throws exception with too many argument');

# test setBioAssayFactorValues accepts undef
eval {$bioassay->setBioAssayFactorValues(undef)};
ok((!$@ and not defined $bioassay->getBioAssayFactorValues()),
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



# testing association channels
my $channels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channels_assn = Bio::MAGE::BioAssay::Channel->new();
}


ok((UNIVERSAL::isa($bioassay->getChannels,'ARRAY')
 and scalar @{$bioassay->getChannels} == 1
 and UNIVERSAL::isa($bioassay->getChannels->[0], q[Bio::MAGE::BioAssay::Channel])),
  'channels set in new()');

ok(eq_array($bioassay->setChannels([$channels_assn]), [$channels_assn]),
   'setChannels returns correct value');

ok((UNIVERSAL::isa($bioassay->getChannels,'ARRAY')
 and scalar @{$bioassay->getChannels} == 1
 and $bioassay->getChannels->[0] == $channels_assn),
   'getChannels fetches correct value');

is($bioassay->addChannels($channels_assn), 2,
  'addChannels returns number of items in list');

ok((UNIVERSAL::isa($bioassay->getChannels,'ARRAY')
 and scalar @{$bioassay->getChannels} == 2
 and $bioassay->getChannels->[0] == $channels_assn
 and $bioassay->getChannels->[1] == $channels_assn),
  'addChannels adds correct value');

# test setChannels throws exception with non-array argument
eval {$bioassay->setChannels(1)};
ok($@, 'setChannels throws exception with non-array argument');

# test setChannels throws exception with bad argument array
eval {$bioassay->setChannels([1])};
ok($@, 'setChannels throws exception with bad argument array');

# test addChannels throws exception with no arguments
eval {$bioassay->addChannels()};
ok($@, 'addChannels throws exception with no arguments');

# test addChannels throws exception with bad argument
eval {$bioassay->addChannels(1)};
ok($@, 'addChannels throws exception with bad array');

# test setChannels accepts empty array ref
eval {$bioassay->setChannels([])};
ok((!$@ and defined $bioassay->getChannels()
    and UNIVERSAL::isa($bioassay->getChannels, 'ARRAY')
    and scalar @{$bioassay->getChannels} == 0),
   'setChannels accepts empty array ref');


# test getChannels throws exception with argument
eval {$bioassay->getChannels(1)};
ok($@, 'getChannels throws exception with argument');

# test setChannels throws exception with no argument
eval {$bioassay->setChannels()};
ok($@, 'setChannels throws exception with no argument');

# test setChannels throws exception with too many argument
eval {$bioassay->setChannels(1,2)};
ok($@, 'setChannels throws exception with too many argument');

# test setChannels accepts undef
eval {$bioassay->setChannels(undef)};
ok((!$@ and not defined $bioassay->getChannels()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bioassay->getDescriptions,'ARRAY')
 and scalar @{$bioassay->getDescriptions} == 1
 and UNIVERSAL::isa($bioassay->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassay->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassay->getDescriptions,'ARRAY')
 and scalar @{$bioassay->getDescriptions} == 1
 and $bioassay->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassay->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassay->getDescriptions,'ARRAY')
 and scalar @{$bioassay->getDescriptions} == 2
 and $bioassay->getDescriptions->[0] == $descriptions_assn
 and $bioassay->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassay->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassay->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassay->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassay->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassay->setDescriptions([])};
ok((!$@ and defined $bioassay->getDescriptions()
    and UNIVERSAL::isa($bioassay->getDescriptions, 'ARRAY')
    and scalar @{$bioassay->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassay->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassay->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassay->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassay->setDescriptions(undef)};
ok((!$@ and not defined $bioassay->getDescriptions()),
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


isa_ok($bioassay->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassay->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassay->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassay->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassay->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassay->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassay->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassay->setSecurity(undef)};
ok((!$@ and not defined $bioassay->getSecurity()),
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


ok((UNIVERSAL::isa($bioassay->getAuditTrail,'ARRAY')
 and scalar @{$bioassay->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassay->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassay->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassay->getAuditTrail,'ARRAY')
 and scalar @{$bioassay->getAuditTrail} == 1
 and $bioassay->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassay->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassay->getAuditTrail,'ARRAY')
 and scalar @{$bioassay->getAuditTrail} == 2
 and $bioassay->getAuditTrail->[0] == $audittrail_assn
 and $bioassay->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassay->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassay->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassay->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassay->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassay->setAuditTrail([])};
ok((!$@ and defined $bioassay->getAuditTrail()
    and UNIVERSAL::isa($bioassay->getAuditTrail, 'ARRAY')
    and scalar @{$bioassay->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassay->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassay->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassay->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassay->setAuditTrail(undef)};
ok((!$@ and not defined $bioassay->getAuditTrail()),
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


ok((UNIVERSAL::isa($bioassay->getPropertySets,'ARRAY')
 and scalar @{$bioassay->getPropertySets} == 1
 and UNIVERSAL::isa($bioassay->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassay->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassay->getPropertySets,'ARRAY')
 and scalar @{$bioassay->getPropertySets} == 1
 and $bioassay->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassay->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassay->getPropertySets,'ARRAY')
 and scalar @{$bioassay->getPropertySets} == 2
 and $bioassay->getPropertySets->[0] == $propertysets_assn
 and $bioassay->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassay->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassay->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassay->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassay->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassay->setPropertySets([])};
ok((!$@ and defined $bioassay->getPropertySets()
    and UNIVERSAL::isa($bioassay->getPropertySets, 'ARRAY')
    and scalar @{$bioassay->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassay->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassay->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassay->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassay->setPropertySets(undef)};
ok((!$@ and not defined $bioassay->getPropertySets()),
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
my $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new();

# testing subclass PhysicalBioAssay
isa_ok($physicalbioassay, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);
isa_ok($physicalbioassay, q[Bio::MAGE::BioAssay::BioAssay]);


# create a subclass
my $derivedbioassay = Bio::MAGE::BioAssay::DerivedBioAssay->new();

# testing subclass DerivedBioAssay
isa_ok($derivedbioassay, q[Bio::MAGE::BioAssay::DerivedBioAssay]);
isa_ok($derivedbioassay, q[Bio::MAGE::BioAssay::BioAssay]);


# create a subclass
my $measuredbioassay = Bio::MAGE::BioAssay::MeasuredBioAssay->new();

# testing subclass MeasuredBioAssay
isa_ok($measuredbioassay, q[Bio::MAGE::BioAssay::MeasuredBioAssay]);
isa_ok($measuredbioassay, q[Bio::MAGE::BioAssay::BioAssay]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($bioassay, q[Bio::MAGE::Identifiable]);

