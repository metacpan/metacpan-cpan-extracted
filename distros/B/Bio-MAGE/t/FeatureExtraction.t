##############################
#
# FeatureExtraction.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureExtraction.t`

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
use Test::More tests => 133;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::FeatureExtraction') };

use Bio::MAGE::BioAssay::MeasuredBioAssay;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::BioAssay::PhysicalBioAssay;


# we test the new() method
my $featureextraction;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureextraction = Bio::MAGE::BioAssay::FeatureExtraction->new();
}
isa_ok($featureextraction, 'Bio::MAGE::BioAssay::FeatureExtraction');

# test the package_name class method
is($featureextraction->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($featureextraction->class_name(), q[Bio::MAGE::BioAssay::FeatureExtraction],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureextraction = Bio::MAGE::BioAssay::FeatureExtraction->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($featureextraction->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$featureextraction->setIdentifier('1');
is($featureextraction->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$featureextraction->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$featureextraction->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featureextraction->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$featureextraction->setIdentifier(undef)};
ok((!$@ and not defined $featureextraction->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($featureextraction->getName(), '2',
  'name new');

# test getter/setter
$featureextraction->setName('2');
is($featureextraction->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$featureextraction->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$featureextraction->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featureextraction->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$featureextraction->setName(undef)};
ok((!$@ and not defined $featureextraction->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::FeatureExtraction->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureextraction = Bio::MAGE::BioAssay::FeatureExtraction->new(physicalBioAssaySource => Bio::MAGE::BioAssay::PhysicalBioAssay->new(),
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
measuredBioAssayTarget => Bio::MAGE::BioAssay::MeasuredBioAssay->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association physicalBioAssaySource
my $physicalbioassaysource_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassaysource_assn = Bio::MAGE::BioAssay::PhysicalBioAssay->new();
}


isa_ok($featureextraction->getPhysicalBioAssaySource, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);

is($featureextraction->setPhysicalBioAssaySource($physicalbioassaysource_assn), $physicalbioassaysource_assn,
  'setPhysicalBioAssaySource returns value');

ok($featureextraction->getPhysicalBioAssaySource() == $physicalbioassaysource_assn,
   'getPhysicalBioAssaySource fetches correct value');

# test setPhysicalBioAssaySource throws exception with bad argument
eval {$featureextraction->setPhysicalBioAssaySource(1)};
ok($@, 'setPhysicalBioAssaySource throws exception with bad argument');


# test getPhysicalBioAssaySource throws exception with argument
eval {$featureextraction->getPhysicalBioAssaySource(1)};
ok($@, 'getPhysicalBioAssaySource throws exception with argument');

# test setPhysicalBioAssaySource throws exception with no argument
eval {$featureextraction->setPhysicalBioAssaySource()};
ok($@, 'setPhysicalBioAssaySource throws exception with no argument');

# test setPhysicalBioAssaySource throws exception with too many argument
eval {$featureextraction->setPhysicalBioAssaySource(1,2)};
ok($@, 'setPhysicalBioAssaySource throws exception with too many argument');

# test setPhysicalBioAssaySource accepts undef
eval {$featureextraction->setPhysicalBioAssaySource(undef)};
ok((!$@ and not defined $featureextraction->getPhysicalBioAssaySource()),
   'setPhysicalBioAssaySource accepts undef');

# test the meta-data for the assoication
$assn = $assns{physicalBioAssaySource};
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
   'physicalBioAssaySource->other() is a valid Bio::MAGE::Association::End'
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
   'physicalBioAssaySource->self() is a valid Bio::MAGE::Association::End'
  );



# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($featureextraction->getProtocolApplications,'ARRAY')
 and scalar @{$featureextraction->getProtocolApplications} == 1
 and UNIVERSAL::isa($featureextraction->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($featureextraction->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($featureextraction->getProtocolApplications,'ARRAY')
 and scalar @{$featureextraction->getProtocolApplications} == 1
 and $featureextraction->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($featureextraction->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($featureextraction->getProtocolApplications,'ARRAY')
 and scalar @{$featureextraction->getProtocolApplications} == 2
 and $featureextraction->getProtocolApplications->[0] == $protocolapplications_assn
 and $featureextraction->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$featureextraction->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$featureextraction->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$featureextraction->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$featureextraction->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$featureextraction->setProtocolApplications([])};
ok((!$@ and defined $featureextraction->getProtocolApplications()
    and UNIVERSAL::isa($featureextraction->getProtocolApplications, 'ARRAY')
    and scalar @{$featureextraction->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$featureextraction->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$featureextraction->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$featureextraction->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$featureextraction->setProtocolApplications(undef)};
ok((!$@ and not defined $featureextraction->getProtocolApplications()),
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



# testing association measuredBioAssayTarget
my $measuredbioassaytarget_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measuredbioassaytarget_assn = Bio::MAGE::BioAssay::MeasuredBioAssay->new();
}


isa_ok($featureextraction->getMeasuredBioAssayTarget, q[Bio::MAGE::BioAssay::MeasuredBioAssay]);

is($featureextraction->setMeasuredBioAssayTarget($measuredbioassaytarget_assn), $measuredbioassaytarget_assn,
  'setMeasuredBioAssayTarget returns value');

ok($featureextraction->getMeasuredBioAssayTarget() == $measuredbioassaytarget_assn,
   'getMeasuredBioAssayTarget fetches correct value');

# test setMeasuredBioAssayTarget throws exception with bad argument
eval {$featureextraction->setMeasuredBioAssayTarget(1)};
ok($@, 'setMeasuredBioAssayTarget throws exception with bad argument');


# test getMeasuredBioAssayTarget throws exception with argument
eval {$featureextraction->getMeasuredBioAssayTarget(1)};
ok($@, 'getMeasuredBioAssayTarget throws exception with argument');

# test setMeasuredBioAssayTarget throws exception with no argument
eval {$featureextraction->setMeasuredBioAssayTarget()};
ok($@, 'setMeasuredBioAssayTarget throws exception with no argument');

# test setMeasuredBioAssayTarget throws exception with too many argument
eval {$featureextraction->setMeasuredBioAssayTarget(1,2)};
ok($@, 'setMeasuredBioAssayTarget throws exception with too many argument');

# test setMeasuredBioAssayTarget accepts undef
eval {$featureextraction->setMeasuredBioAssayTarget(undef)};
ok((!$@ and not defined $featureextraction->getMeasuredBioAssayTarget()),
   'setMeasuredBioAssayTarget accepts undef');

# test the meta-data for the assoication
$assn = $assns{measuredBioAssayTarget};
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
   'measuredBioAssayTarget->other() is a valid Bio::MAGE::Association::End'
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
   'measuredBioAssayTarget->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($featureextraction->getDescriptions,'ARRAY')
 and scalar @{$featureextraction->getDescriptions} == 1
 and UNIVERSAL::isa($featureextraction->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($featureextraction->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($featureextraction->getDescriptions,'ARRAY')
 and scalar @{$featureextraction->getDescriptions} == 1
 and $featureextraction->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($featureextraction->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($featureextraction->getDescriptions,'ARRAY')
 and scalar @{$featureextraction->getDescriptions} == 2
 and $featureextraction->getDescriptions->[0] == $descriptions_assn
 and $featureextraction->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$featureextraction->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$featureextraction->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$featureextraction->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$featureextraction->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$featureextraction->setDescriptions([])};
ok((!$@ and defined $featureextraction->getDescriptions()
    and UNIVERSAL::isa($featureextraction->getDescriptions, 'ARRAY')
    and scalar @{$featureextraction->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$featureextraction->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$featureextraction->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$featureextraction->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$featureextraction->setDescriptions(undef)};
ok((!$@ and not defined $featureextraction->getDescriptions()),
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


ok((UNIVERSAL::isa($featureextraction->getAuditTrail,'ARRAY')
 and scalar @{$featureextraction->getAuditTrail} == 1
 and UNIVERSAL::isa($featureextraction->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($featureextraction->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($featureextraction->getAuditTrail,'ARRAY')
 and scalar @{$featureextraction->getAuditTrail} == 1
 and $featureextraction->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($featureextraction->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($featureextraction->getAuditTrail,'ARRAY')
 and scalar @{$featureextraction->getAuditTrail} == 2
 and $featureextraction->getAuditTrail->[0] == $audittrail_assn
 and $featureextraction->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$featureextraction->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$featureextraction->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$featureextraction->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$featureextraction->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$featureextraction->setAuditTrail([])};
ok((!$@ and defined $featureextraction->getAuditTrail()
    and UNIVERSAL::isa($featureextraction->getAuditTrail, 'ARRAY')
    and scalar @{$featureextraction->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$featureextraction->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$featureextraction->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$featureextraction->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$featureextraction->setAuditTrail(undef)};
ok((!$@ and not defined $featureextraction->getAuditTrail()),
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


isa_ok($featureextraction->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($featureextraction->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($featureextraction->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$featureextraction->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$featureextraction->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$featureextraction->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$featureextraction->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$featureextraction->setSecurity(undef)};
ok((!$@ and not defined $featureextraction->getSecurity()),
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


ok((UNIVERSAL::isa($featureextraction->getPropertySets,'ARRAY')
 and scalar @{$featureextraction->getPropertySets} == 1
 and UNIVERSAL::isa($featureextraction->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featureextraction->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featureextraction->getPropertySets,'ARRAY')
 and scalar @{$featureextraction->getPropertySets} == 1
 and $featureextraction->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featureextraction->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featureextraction->getPropertySets,'ARRAY')
 and scalar @{$featureextraction->getPropertySets} == 2
 and $featureextraction->getPropertySets->[0] == $propertysets_assn
 and $featureextraction->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featureextraction->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featureextraction->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featureextraction->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featureextraction->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featureextraction->setPropertySets([])};
ok((!$@ and defined $featureextraction->getPropertySets()
    and UNIVERSAL::isa($featureextraction->getPropertySets, 'ARRAY')
    and scalar @{$featureextraction->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featureextraction->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featureextraction->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featureextraction->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featureextraction->setPropertySets(undef)};
ok((!$@ and not defined $featureextraction->getPropertySets()),
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





my $bioevent;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioevent = Bio::MAGE::BioEvent::BioEvent->new();
}

# testing superclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($featureextraction, q[Bio::MAGE::BioEvent::BioEvent]);

