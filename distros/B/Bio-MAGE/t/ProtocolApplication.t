##############################
#
# ProtocolApplication.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ProtocolApplication.t`

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

BEGIN { use_ok('Bio::MAGE::Protocol::ProtocolApplication') };

use Bio::MAGE::Protocol::HardwareApplication;
use Bio::MAGE::Protocol::SoftwareApplication;
use Bio::MAGE::Protocol::ParameterValue;
use Bio::MAGE::Protocol::Protocol;
use Bio::MAGE::AuditAndSecurity::Person;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $protocolapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplication = Bio::MAGE::Protocol::ProtocolApplication->new();
}
isa_ok($protocolapplication, 'Bio::MAGE::Protocol::ProtocolApplication');

# test the package_name class method
is($protocolapplication->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($protocolapplication->class_name(), q[Bio::MAGE::Protocol::ProtocolApplication],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplication = Bio::MAGE::Protocol::ProtocolApplication->new(activityDate => '1');
}


#
# testing attribute activityDate
#

# test attribute values can be set in new()
is($protocolapplication->getActivityDate(), '1',
  'activityDate new');

# test getter/setter
$protocolapplication->setActivityDate('1');
is($protocolapplication->getActivityDate(), '1',
  'activityDate getter/setter');

# test getter throws exception with argument
eval {$protocolapplication->getActivityDate(1)};
ok($@, 'activityDate getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocolapplication->setActivityDate()};
ok($@, 'activityDate setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocolapplication->setActivityDate('1', '1')};
ok($@, 'activityDate setter throws exception with too many argument');

# test setter accepts undef
eval {$protocolapplication->setActivityDate(undef)};
ok((!$@ and not defined $protocolapplication->getActivityDate()),
   'activityDate setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::ProtocolApplication->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplication = Bio::MAGE::Protocol::ProtocolApplication->new(protocol => Bio::MAGE::Protocol::Protocol->new(),
hardwareApplications => [Bio::MAGE::Protocol::HardwareApplication->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
softwareApplications => [Bio::MAGE::Protocol::SoftwareApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
performers => [Bio::MAGE::AuditAndSecurity::Person->new()],
parameterValues => [Bio::MAGE::Protocol::ParameterValue->new()]);
}

my ($end, $assn);


# testing association protocol
my $protocol_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocol_assn = Bio::MAGE::Protocol::Protocol->new();
}


isa_ok($protocolapplication->getProtocol, q[Bio::MAGE::Protocol::Protocol]);

is($protocolapplication->setProtocol($protocol_assn), $protocol_assn,
  'setProtocol returns value');

ok($protocolapplication->getProtocol() == $protocol_assn,
   'getProtocol fetches correct value');

# test setProtocol throws exception with bad argument
eval {$protocolapplication->setProtocol(1)};
ok($@, 'setProtocol throws exception with bad argument');


# test getProtocol throws exception with argument
eval {$protocolapplication->getProtocol(1)};
ok($@, 'getProtocol throws exception with argument');

# test setProtocol throws exception with no argument
eval {$protocolapplication->setProtocol()};
ok($@, 'setProtocol throws exception with no argument');

# test setProtocol throws exception with too many argument
eval {$protocolapplication->setProtocol(1,2)};
ok($@, 'setProtocol throws exception with too many argument');

# test setProtocol accepts undef
eval {$protocolapplication->setProtocol(undef)};
ok((!$@ and not defined $protocolapplication->getProtocol()),
   'setProtocol accepts undef');

# test the meta-data for the assoication
$assn = $assns{protocol};
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
   'protocol->other() is a valid Bio::MAGE::Association::End'
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
   'protocol->self() is a valid Bio::MAGE::Association::End'
  );



# testing association hardwareApplications
my $hardwareapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwareapplications_assn = Bio::MAGE::Protocol::HardwareApplication->new();
}


ok((UNIVERSAL::isa($protocolapplication->getHardwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getHardwareApplications} == 1
 and UNIVERSAL::isa($protocolapplication->getHardwareApplications->[0], q[Bio::MAGE::Protocol::HardwareApplication])),
  'hardwareApplications set in new()');

ok(eq_array($protocolapplication->setHardwareApplications([$hardwareapplications_assn]), [$hardwareapplications_assn]),
   'setHardwareApplications returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getHardwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getHardwareApplications} == 1
 and $protocolapplication->getHardwareApplications->[0] == $hardwareapplications_assn),
   'getHardwareApplications fetches correct value');

is($protocolapplication->addHardwareApplications($hardwareapplications_assn), 2,
  'addHardwareApplications returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getHardwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getHardwareApplications} == 2
 and $protocolapplication->getHardwareApplications->[0] == $hardwareapplications_assn
 and $protocolapplication->getHardwareApplications->[1] == $hardwareapplications_assn),
  'addHardwareApplications adds correct value');

# test setHardwareApplications throws exception with non-array argument
eval {$protocolapplication->setHardwareApplications(1)};
ok($@, 'setHardwareApplications throws exception with non-array argument');

# test setHardwareApplications throws exception with bad argument array
eval {$protocolapplication->setHardwareApplications([1])};
ok($@, 'setHardwareApplications throws exception with bad argument array');

# test addHardwareApplications throws exception with no arguments
eval {$protocolapplication->addHardwareApplications()};
ok($@, 'addHardwareApplications throws exception with no arguments');

# test addHardwareApplications throws exception with bad argument
eval {$protocolapplication->addHardwareApplications(1)};
ok($@, 'addHardwareApplications throws exception with bad array');

# test setHardwareApplications accepts empty array ref
eval {$protocolapplication->setHardwareApplications([])};
ok((!$@ and defined $protocolapplication->getHardwareApplications()
    and UNIVERSAL::isa($protocolapplication->getHardwareApplications, 'ARRAY')
    and scalar @{$protocolapplication->getHardwareApplications} == 0),
   'setHardwareApplications accepts empty array ref');


# test getHardwareApplications throws exception with argument
eval {$protocolapplication->getHardwareApplications(1)};
ok($@, 'getHardwareApplications throws exception with argument');

# test setHardwareApplications throws exception with no argument
eval {$protocolapplication->setHardwareApplications()};
ok($@, 'setHardwareApplications throws exception with no argument');

# test setHardwareApplications throws exception with too many argument
eval {$protocolapplication->setHardwareApplications(1,2)};
ok($@, 'setHardwareApplications throws exception with too many argument');

# test setHardwareApplications accepts undef
eval {$protocolapplication->setHardwareApplications(undef)};
ok((!$@ and not defined $protocolapplication->getHardwareApplications()),
   'setHardwareApplications accepts undef');

# test the meta-data for the assoication
$assn = $assns{hardwareApplications};
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
   'hardwareApplications->other() is a valid Bio::MAGE::Association::End'
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
   'hardwareApplications->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($protocolapplication->getAuditTrail,'ARRAY')
 and scalar @{$protocolapplication->getAuditTrail} == 1
 and UNIVERSAL::isa($protocolapplication->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($protocolapplication->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getAuditTrail,'ARRAY')
 and scalar @{$protocolapplication->getAuditTrail} == 1
 and $protocolapplication->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($protocolapplication->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getAuditTrail,'ARRAY')
 and scalar @{$protocolapplication->getAuditTrail} == 2
 and $protocolapplication->getAuditTrail->[0] == $audittrail_assn
 and $protocolapplication->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$protocolapplication->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$protocolapplication->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$protocolapplication->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$protocolapplication->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$protocolapplication->setAuditTrail([])};
ok((!$@ and defined $protocolapplication->getAuditTrail()
    and UNIVERSAL::isa($protocolapplication->getAuditTrail, 'ARRAY')
    and scalar @{$protocolapplication->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$protocolapplication->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$protocolapplication->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$protocolapplication->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$protocolapplication->setAuditTrail(undef)};
ok((!$@ and not defined $protocolapplication->getAuditTrail()),
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


ok((UNIVERSAL::isa($protocolapplication->getPropertySets,'ARRAY')
 and scalar @{$protocolapplication->getPropertySets} == 1
 and UNIVERSAL::isa($protocolapplication->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($protocolapplication->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getPropertySets,'ARRAY')
 and scalar @{$protocolapplication->getPropertySets} == 1
 and $protocolapplication->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($protocolapplication->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getPropertySets,'ARRAY')
 and scalar @{$protocolapplication->getPropertySets} == 2
 and $protocolapplication->getPropertySets->[0] == $propertysets_assn
 and $protocolapplication->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$protocolapplication->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$protocolapplication->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$protocolapplication->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$protocolapplication->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$protocolapplication->setPropertySets([])};
ok((!$@ and defined $protocolapplication->getPropertySets()
    and UNIVERSAL::isa($protocolapplication->getPropertySets, 'ARRAY')
    and scalar @{$protocolapplication->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$protocolapplication->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$protocolapplication->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$protocolapplication->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$protocolapplication->setPropertySets(undef)};
ok((!$@ and not defined $protocolapplication->getPropertySets()),
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



# testing association softwareApplications
my $softwareapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwareapplications_assn = Bio::MAGE::Protocol::SoftwareApplication->new();
}


ok((UNIVERSAL::isa($protocolapplication->getSoftwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getSoftwareApplications} == 1
 and UNIVERSAL::isa($protocolapplication->getSoftwareApplications->[0], q[Bio::MAGE::Protocol::SoftwareApplication])),
  'softwareApplications set in new()');

ok(eq_array($protocolapplication->setSoftwareApplications([$softwareapplications_assn]), [$softwareapplications_assn]),
   'setSoftwareApplications returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getSoftwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getSoftwareApplications} == 1
 and $protocolapplication->getSoftwareApplications->[0] == $softwareapplications_assn),
   'getSoftwareApplications fetches correct value');

is($protocolapplication->addSoftwareApplications($softwareapplications_assn), 2,
  'addSoftwareApplications returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getSoftwareApplications,'ARRAY')
 and scalar @{$protocolapplication->getSoftwareApplications} == 2
 and $protocolapplication->getSoftwareApplications->[0] == $softwareapplications_assn
 and $protocolapplication->getSoftwareApplications->[1] == $softwareapplications_assn),
  'addSoftwareApplications adds correct value');

# test setSoftwareApplications throws exception with non-array argument
eval {$protocolapplication->setSoftwareApplications(1)};
ok($@, 'setSoftwareApplications throws exception with non-array argument');

# test setSoftwareApplications throws exception with bad argument array
eval {$protocolapplication->setSoftwareApplications([1])};
ok($@, 'setSoftwareApplications throws exception with bad argument array');

# test addSoftwareApplications throws exception with no arguments
eval {$protocolapplication->addSoftwareApplications()};
ok($@, 'addSoftwareApplications throws exception with no arguments');

# test addSoftwareApplications throws exception with bad argument
eval {$protocolapplication->addSoftwareApplications(1)};
ok($@, 'addSoftwareApplications throws exception with bad array');

# test setSoftwareApplications accepts empty array ref
eval {$protocolapplication->setSoftwareApplications([])};
ok((!$@ and defined $protocolapplication->getSoftwareApplications()
    and UNIVERSAL::isa($protocolapplication->getSoftwareApplications, 'ARRAY')
    and scalar @{$protocolapplication->getSoftwareApplications} == 0),
   'setSoftwareApplications accepts empty array ref');


# test getSoftwareApplications throws exception with argument
eval {$protocolapplication->getSoftwareApplications(1)};
ok($@, 'getSoftwareApplications throws exception with argument');

# test setSoftwareApplications throws exception with no argument
eval {$protocolapplication->setSoftwareApplications()};
ok($@, 'setSoftwareApplications throws exception with no argument');

# test setSoftwareApplications throws exception with too many argument
eval {$protocolapplication->setSoftwareApplications(1,2)};
ok($@, 'setSoftwareApplications throws exception with too many argument');

# test setSoftwareApplications accepts undef
eval {$protocolapplication->setSoftwareApplications(undef)};
ok((!$@ and not defined $protocolapplication->getSoftwareApplications()),
   'setSoftwareApplications accepts undef');

# test the meta-data for the assoication
$assn = $assns{softwareApplications};
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
   'softwareApplications->other() is a valid Bio::MAGE::Association::End'
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
   'softwareApplications->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($protocolapplication->getDescriptions,'ARRAY')
 and scalar @{$protocolapplication->getDescriptions} == 1
 and UNIVERSAL::isa($protocolapplication->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($protocolapplication->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getDescriptions,'ARRAY')
 and scalar @{$protocolapplication->getDescriptions} == 1
 and $protocolapplication->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($protocolapplication->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getDescriptions,'ARRAY')
 and scalar @{$protocolapplication->getDescriptions} == 2
 and $protocolapplication->getDescriptions->[0] == $descriptions_assn
 and $protocolapplication->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$protocolapplication->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$protocolapplication->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$protocolapplication->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$protocolapplication->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$protocolapplication->setDescriptions([])};
ok((!$@ and defined $protocolapplication->getDescriptions()
    and UNIVERSAL::isa($protocolapplication->getDescriptions, 'ARRAY')
    and scalar @{$protocolapplication->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$protocolapplication->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$protocolapplication->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$protocolapplication->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$protocolapplication->setDescriptions(undef)};
ok((!$@ and not defined $protocolapplication->getDescriptions()),
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


isa_ok($protocolapplication->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($protocolapplication->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($protocolapplication->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$protocolapplication->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$protocolapplication->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$protocolapplication->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$protocolapplication->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$protocolapplication->setSecurity(undef)};
ok((!$@ and not defined $protocolapplication->getSecurity()),
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



# testing association performers
my $performers_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $performers_assn = Bio::MAGE::AuditAndSecurity::Person->new();
}


ok((UNIVERSAL::isa($protocolapplication->getPerformers,'ARRAY')
 and scalar @{$protocolapplication->getPerformers} == 1
 and UNIVERSAL::isa($protocolapplication->getPerformers->[0], q[Bio::MAGE::AuditAndSecurity::Person])),
  'performers set in new()');

ok(eq_array($protocolapplication->setPerformers([$performers_assn]), [$performers_assn]),
   'setPerformers returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getPerformers,'ARRAY')
 and scalar @{$protocolapplication->getPerformers} == 1
 and $protocolapplication->getPerformers->[0] == $performers_assn),
   'getPerformers fetches correct value');

is($protocolapplication->addPerformers($performers_assn), 2,
  'addPerformers returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getPerformers,'ARRAY')
 and scalar @{$protocolapplication->getPerformers} == 2
 and $protocolapplication->getPerformers->[0] == $performers_assn
 and $protocolapplication->getPerformers->[1] == $performers_assn),
  'addPerformers adds correct value');

# test setPerformers throws exception with non-array argument
eval {$protocolapplication->setPerformers(1)};
ok($@, 'setPerformers throws exception with non-array argument');

# test setPerformers throws exception with bad argument array
eval {$protocolapplication->setPerformers([1])};
ok($@, 'setPerformers throws exception with bad argument array');

# test addPerformers throws exception with no arguments
eval {$protocolapplication->addPerformers()};
ok($@, 'addPerformers throws exception with no arguments');

# test addPerformers throws exception with bad argument
eval {$protocolapplication->addPerformers(1)};
ok($@, 'addPerformers throws exception with bad array');

# test setPerformers accepts empty array ref
eval {$protocolapplication->setPerformers([])};
ok((!$@ and defined $protocolapplication->getPerformers()
    and UNIVERSAL::isa($protocolapplication->getPerformers, 'ARRAY')
    and scalar @{$protocolapplication->getPerformers} == 0),
   'setPerformers accepts empty array ref');


# test getPerformers throws exception with argument
eval {$protocolapplication->getPerformers(1)};
ok($@, 'getPerformers throws exception with argument');

# test setPerformers throws exception with no argument
eval {$protocolapplication->setPerformers()};
ok($@, 'setPerformers throws exception with no argument');

# test setPerformers throws exception with too many argument
eval {$protocolapplication->setPerformers(1,2)};
ok($@, 'setPerformers throws exception with too many argument');

# test setPerformers accepts undef
eval {$protocolapplication->setPerformers(undef)};
ok((!$@ and not defined $protocolapplication->getPerformers()),
   'setPerformers accepts undef');

# test the meta-data for the assoication
$assn = $assns{performers};
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
   'performers->other() is a valid Bio::MAGE::Association::End'
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
   'performers->self() is a valid Bio::MAGE::Association::End'
  );



# testing association parameterValues
my $parametervalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalues_assn = Bio::MAGE::Protocol::ParameterValue->new();
}


ok((UNIVERSAL::isa($protocolapplication->getParameterValues,'ARRAY')
 and scalar @{$protocolapplication->getParameterValues} == 1
 and UNIVERSAL::isa($protocolapplication->getParameterValues->[0], q[Bio::MAGE::Protocol::ParameterValue])),
  'parameterValues set in new()');

ok(eq_array($protocolapplication->setParameterValues([$parametervalues_assn]), [$parametervalues_assn]),
   'setParameterValues returns correct value');

ok((UNIVERSAL::isa($protocolapplication->getParameterValues,'ARRAY')
 and scalar @{$protocolapplication->getParameterValues} == 1
 and $protocolapplication->getParameterValues->[0] == $parametervalues_assn),
   'getParameterValues fetches correct value');

is($protocolapplication->addParameterValues($parametervalues_assn), 2,
  'addParameterValues returns number of items in list');

ok((UNIVERSAL::isa($protocolapplication->getParameterValues,'ARRAY')
 and scalar @{$protocolapplication->getParameterValues} == 2
 and $protocolapplication->getParameterValues->[0] == $parametervalues_assn
 and $protocolapplication->getParameterValues->[1] == $parametervalues_assn),
  'addParameterValues adds correct value');

# test setParameterValues throws exception with non-array argument
eval {$protocolapplication->setParameterValues(1)};
ok($@, 'setParameterValues throws exception with non-array argument');

# test setParameterValues throws exception with bad argument array
eval {$protocolapplication->setParameterValues([1])};
ok($@, 'setParameterValues throws exception with bad argument array');

# test addParameterValues throws exception with no arguments
eval {$protocolapplication->addParameterValues()};
ok($@, 'addParameterValues throws exception with no arguments');

# test addParameterValues throws exception with bad argument
eval {$protocolapplication->addParameterValues(1)};
ok($@, 'addParameterValues throws exception with bad array');

# test setParameterValues accepts empty array ref
eval {$protocolapplication->setParameterValues([])};
ok((!$@ and defined $protocolapplication->getParameterValues()
    and UNIVERSAL::isa($protocolapplication->getParameterValues, 'ARRAY')
    and scalar @{$protocolapplication->getParameterValues} == 0),
   'setParameterValues accepts empty array ref');


# test getParameterValues throws exception with argument
eval {$protocolapplication->getParameterValues(1)};
ok($@, 'getParameterValues throws exception with argument');

# test setParameterValues throws exception with no argument
eval {$protocolapplication->setParameterValues()};
ok($@, 'setParameterValues throws exception with no argument');

# test setParameterValues throws exception with too many argument
eval {$protocolapplication->setParameterValues(1,2)};
ok($@, 'setParameterValues throws exception with too many argument');

# test setParameterValues accepts undef
eval {$protocolapplication->setParameterValues(undef)};
ok((!$@ and not defined $protocolapplication->getParameterValues()),
   'setParameterValues accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameterValues};
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
   'parameterValues->other() is a valid Bio::MAGE::Association::End'
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
   'parameterValues->self() is a valid Bio::MAGE::Association::End'
  );





my $parameterizableapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new();
}

# testing superclass ParameterizableApplication
isa_ok($parameterizableapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);
isa_ok($protocolapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);

