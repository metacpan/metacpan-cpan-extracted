##############################
#
# BioAssayTreatment.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayTreatment.t`

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
use Test::More tests => 135;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::BioAssayTreatment') };

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::BioAssay::PhysicalBioAssay;

use Bio::MAGE::BioAssay::ImageAcquisition;

# we test the new() method
my $bioassaytreatment;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaytreatment = Bio::MAGE::BioAssay::BioAssayTreatment->new();
}
isa_ok($bioassaytreatment, 'Bio::MAGE::BioAssay::BioAssayTreatment');

# test the package_name class method
is($bioassaytreatment->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($bioassaytreatment->class_name(), q[Bio::MAGE::BioAssay::BioAssayTreatment],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaytreatment = Bio::MAGE::BioAssay::BioAssayTreatment->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaytreatment->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaytreatment->setIdentifier('1');
is($bioassaytreatment->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaytreatment->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaytreatment->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaytreatment->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaytreatment->setIdentifier(undef)};
ok((!$@ and not defined $bioassaytreatment->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaytreatment->getName(), '2',
  'name new');

# test getter/setter
$bioassaytreatment->setName('2');
is($bioassaytreatment->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaytreatment->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaytreatment->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaytreatment->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaytreatment->setName(undef)};
ok((!$@ and not defined $bioassaytreatment->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::BioAssayTreatment->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaytreatment = Bio::MAGE::BioAssay::BioAssayTreatment->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
target => Bio::MAGE::BioAssay::PhysicalBioAssay->new(),
physicalBioAssay => Bio::MAGE::BioAssay::PhysicalBioAssay->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($bioassaytreatment->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaytreatment->getProtocolApplications} == 1
 and UNIVERSAL::isa($bioassaytreatment->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($bioassaytreatment->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($bioassaytreatment->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaytreatment->getProtocolApplications} == 1
 and $bioassaytreatment->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($bioassaytreatment->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($bioassaytreatment->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaytreatment->getProtocolApplications} == 2
 and $bioassaytreatment->getProtocolApplications->[0] == $protocolapplications_assn
 and $bioassaytreatment->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$bioassaytreatment->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$bioassaytreatment->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$bioassaytreatment->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$bioassaytreatment->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$bioassaytreatment->setProtocolApplications([])};
ok((!$@ and defined $bioassaytreatment->getProtocolApplications()
    and UNIVERSAL::isa($bioassaytreatment->getProtocolApplications, 'ARRAY')
    and scalar @{$bioassaytreatment->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$bioassaytreatment->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$bioassaytreatment->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$bioassaytreatment->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$bioassaytreatment->setProtocolApplications(undef)};
ok((!$@ and not defined $bioassaytreatment->getProtocolApplications()),
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



# testing association target
my $target_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $target_assn = Bio::MAGE::BioAssay::PhysicalBioAssay->new();
}


isa_ok($bioassaytreatment->getTarget, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);

is($bioassaytreatment->setTarget($target_assn), $target_assn,
  'setTarget returns value');

ok($bioassaytreatment->getTarget() == $target_assn,
   'getTarget fetches correct value');

# test setTarget throws exception with bad argument
eval {$bioassaytreatment->setTarget(1)};
ok($@, 'setTarget throws exception with bad argument');


# test getTarget throws exception with argument
eval {$bioassaytreatment->getTarget(1)};
ok($@, 'getTarget throws exception with argument');

# test setTarget throws exception with no argument
eval {$bioassaytreatment->setTarget()};
ok($@, 'setTarget throws exception with no argument');

# test setTarget throws exception with too many argument
eval {$bioassaytreatment->setTarget(1,2)};
ok($@, 'setTarget throws exception with too many argument');

# test setTarget accepts undef
eval {$bioassaytreatment->setTarget(undef)};
ok((!$@ and not defined $bioassaytreatment->getTarget()),
   'setTarget accepts undef');

# test the meta-data for the assoication
$assn = $assns{target};
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
   'target->other() is a valid Bio::MAGE::Association::End'
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
   'target->self() is a valid Bio::MAGE::Association::End'
  );



# testing association physicalBioAssay
my $physicalbioassay_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $physicalbioassay_assn = Bio::MAGE::BioAssay::PhysicalBioAssay->new();
}


isa_ok($bioassaytreatment->getPhysicalBioAssay, q[Bio::MAGE::BioAssay::PhysicalBioAssay]);

is($bioassaytreatment->setPhysicalBioAssay($physicalbioassay_assn), $physicalbioassay_assn,
  'setPhysicalBioAssay returns value');

ok($bioassaytreatment->getPhysicalBioAssay() == $physicalbioassay_assn,
   'getPhysicalBioAssay fetches correct value');

# test setPhysicalBioAssay throws exception with bad argument
eval {$bioassaytreatment->setPhysicalBioAssay(1)};
ok($@, 'setPhysicalBioAssay throws exception with bad argument');


# test getPhysicalBioAssay throws exception with argument
eval {$bioassaytreatment->getPhysicalBioAssay(1)};
ok($@, 'getPhysicalBioAssay throws exception with argument');

# test setPhysicalBioAssay throws exception with no argument
eval {$bioassaytreatment->setPhysicalBioAssay()};
ok($@, 'setPhysicalBioAssay throws exception with no argument');

# test setPhysicalBioAssay throws exception with too many argument
eval {$bioassaytreatment->setPhysicalBioAssay(1,2)};
ok($@, 'setPhysicalBioAssay throws exception with too many argument');

# test setPhysicalBioAssay accepts undef
eval {$bioassaytreatment->setPhysicalBioAssay(undef)};
ok((!$@ and not defined $bioassaytreatment->getPhysicalBioAssay()),
   'setPhysicalBioAssay accepts undef');

# test the meta-data for the assoication
$assn = $assns{physicalBioAssay};
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
   'physicalBioAssay->other() is a valid Bio::MAGE::Association::End'
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
   'physicalBioAssay->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bioassaytreatment->getDescriptions,'ARRAY')
 and scalar @{$bioassaytreatment->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaytreatment->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaytreatment->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaytreatment->getDescriptions,'ARRAY')
 and scalar @{$bioassaytreatment->getDescriptions} == 1
 and $bioassaytreatment->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaytreatment->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaytreatment->getDescriptions,'ARRAY')
 and scalar @{$bioassaytreatment->getDescriptions} == 2
 and $bioassaytreatment->getDescriptions->[0] == $descriptions_assn
 and $bioassaytreatment->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaytreatment->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaytreatment->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaytreatment->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaytreatment->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaytreatment->setDescriptions([])};
ok((!$@ and defined $bioassaytreatment->getDescriptions()
    and UNIVERSAL::isa($bioassaytreatment->getDescriptions, 'ARRAY')
    and scalar @{$bioassaytreatment->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaytreatment->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaytreatment->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaytreatment->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaytreatment->setDescriptions(undef)};
ok((!$@ and not defined $bioassaytreatment->getDescriptions()),
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


ok((UNIVERSAL::isa($bioassaytreatment->getAuditTrail,'ARRAY')
 and scalar @{$bioassaytreatment->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaytreatment->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaytreatment->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaytreatment->getAuditTrail,'ARRAY')
 and scalar @{$bioassaytreatment->getAuditTrail} == 1
 and $bioassaytreatment->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaytreatment->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaytreatment->getAuditTrail,'ARRAY')
 and scalar @{$bioassaytreatment->getAuditTrail} == 2
 and $bioassaytreatment->getAuditTrail->[0] == $audittrail_assn
 and $bioassaytreatment->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaytreatment->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaytreatment->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaytreatment->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaytreatment->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaytreatment->setAuditTrail([])};
ok((!$@ and defined $bioassaytreatment->getAuditTrail()
    and UNIVERSAL::isa($bioassaytreatment->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaytreatment->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaytreatment->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaytreatment->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaytreatment->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaytreatment->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaytreatment->getAuditTrail()),
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


isa_ok($bioassaytreatment->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaytreatment->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaytreatment->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaytreatment->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaytreatment->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaytreatment->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaytreatment->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaytreatment->setSecurity(undef)};
ok((!$@ and not defined $bioassaytreatment->getSecurity()),
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


ok((UNIVERSAL::isa($bioassaytreatment->getPropertySets,'ARRAY')
 and scalar @{$bioassaytreatment->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaytreatment->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaytreatment->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaytreatment->getPropertySets,'ARRAY')
 and scalar @{$bioassaytreatment->getPropertySets} == 1
 and $bioassaytreatment->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaytreatment->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaytreatment->getPropertySets,'ARRAY')
 and scalar @{$bioassaytreatment->getPropertySets} == 2
 and $bioassaytreatment->getPropertySets->[0] == $propertysets_assn
 and $bioassaytreatment->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaytreatment->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaytreatment->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaytreatment->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaytreatment->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaytreatment->setPropertySets([])};
ok((!$@ and defined $bioassaytreatment->getPropertySets()
    and UNIVERSAL::isa($bioassaytreatment->getPropertySets, 'ARRAY')
    and scalar @{$bioassaytreatment->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaytreatment->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaytreatment->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaytreatment->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaytreatment->setPropertySets(undef)};
ok((!$@ and not defined $bioassaytreatment->getPropertySets()),
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
my $imageacquisition = Bio::MAGE::BioAssay::ImageAcquisition->new();

# testing subclass ImageAcquisition
isa_ok($imageacquisition, q[Bio::MAGE::BioAssay::ImageAcquisition]);
isa_ok($imageacquisition, q[Bio::MAGE::BioAssay::BioAssayTreatment]);



my $bioevent;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioevent = Bio::MAGE::BioEvent::BioEvent->new();
}

# testing superclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($bioassaytreatment, q[Bio::MAGE::BioEvent::BioEvent]);

