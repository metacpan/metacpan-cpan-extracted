##############################
#
# HardwareApplication.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HardwareApplication.t`

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
use Test::More tests => 114;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::HardwareApplication') };

use Bio::MAGE::Protocol::ParameterValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Protocol::Hardware;
use Bio::MAGE::Description::Description;


# we test the new() method
my $hardwareapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwareapplication = Bio::MAGE::Protocol::HardwareApplication->new();
}
isa_ok($hardwareapplication, 'Bio::MAGE::Protocol::HardwareApplication');

# test the package_name class method
is($hardwareapplication->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($hardwareapplication->class_name(), q[Bio::MAGE::Protocol::HardwareApplication],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwareapplication = Bio::MAGE::Protocol::HardwareApplication->new(serialNumber => '1');
}


#
# testing attribute serialNumber
#

# test attribute values can be set in new()
is($hardwareapplication->getSerialNumber(), '1',
  'serialNumber new');

# test getter/setter
$hardwareapplication->setSerialNumber('1');
is($hardwareapplication->getSerialNumber(), '1',
  'serialNumber getter/setter');

# test getter throws exception with argument
eval {$hardwareapplication->getSerialNumber(1)};
ok($@, 'serialNumber getter throws exception with argument');

# test setter throws exception with no argument
eval {$hardwareapplication->setSerialNumber()};
ok($@, 'serialNumber setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$hardwareapplication->setSerialNumber('1', '1')};
ok($@, 'serialNumber setter throws exception with too many argument');

# test setter accepts undef
eval {$hardwareapplication->setSerialNumber(undef)};
ok((!$@ and not defined $hardwareapplication->getSerialNumber()),
   'serialNumber setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::HardwareApplication->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwareapplication = Bio::MAGE::Protocol::HardwareApplication->new(hardware => Bio::MAGE::Protocol::Hardware->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
parameterValues => [Bio::MAGE::Protocol::ParameterValue->new()]);
}

my ($end, $assn);


# testing association hardware
my $hardware_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardware_assn = Bio::MAGE::Protocol::Hardware->new();
}


isa_ok($hardwareapplication->getHardware, q[Bio::MAGE::Protocol::Hardware]);

is($hardwareapplication->setHardware($hardware_assn), $hardware_assn,
  'setHardware returns value');

ok($hardwareapplication->getHardware() == $hardware_assn,
   'getHardware fetches correct value');

# test setHardware throws exception with bad argument
eval {$hardwareapplication->setHardware(1)};
ok($@, 'setHardware throws exception with bad argument');


# test getHardware throws exception with argument
eval {$hardwareapplication->getHardware(1)};
ok($@, 'getHardware throws exception with argument');

# test setHardware throws exception with no argument
eval {$hardwareapplication->setHardware()};
ok($@, 'setHardware throws exception with no argument');

# test setHardware throws exception with too many argument
eval {$hardwareapplication->setHardware(1,2)};
ok($@, 'setHardware throws exception with too many argument');

# test setHardware accepts undef
eval {$hardwareapplication->setHardware(undef)};
ok((!$@ and not defined $hardwareapplication->getHardware()),
   'setHardware accepts undef');

# test the meta-data for the assoication
$assn = $assns{hardware};
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
   'hardware->other() is a valid Bio::MAGE::Association::End'
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
   'hardware->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($hardwareapplication->getDescriptions,'ARRAY')
 and scalar @{$hardwareapplication->getDescriptions} == 1
 and UNIVERSAL::isa($hardwareapplication->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($hardwareapplication->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($hardwareapplication->getDescriptions,'ARRAY')
 and scalar @{$hardwareapplication->getDescriptions} == 1
 and $hardwareapplication->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($hardwareapplication->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($hardwareapplication->getDescriptions,'ARRAY')
 and scalar @{$hardwareapplication->getDescriptions} == 2
 and $hardwareapplication->getDescriptions->[0] == $descriptions_assn
 and $hardwareapplication->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$hardwareapplication->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$hardwareapplication->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$hardwareapplication->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$hardwareapplication->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$hardwareapplication->setDescriptions([])};
ok((!$@ and defined $hardwareapplication->getDescriptions()
    and UNIVERSAL::isa($hardwareapplication->getDescriptions, 'ARRAY')
    and scalar @{$hardwareapplication->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$hardwareapplication->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$hardwareapplication->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$hardwareapplication->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$hardwareapplication->setDescriptions(undef)};
ok((!$@ and not defined $hardwareapplication->getDescriptions()),
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


isa_ok($hardwareapplication->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($hardwareapplication->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($hardwareapplication->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$hardwareapplication->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$hardwareapplication->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$hardwareapplication->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$hardwareapplication->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$hardwareapplication->setSecurity(undef)};
ok((!$@ and not defined $hardwareapplication->getSecurity()),
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


ok((UNIVERSAL::isa($hardwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$hardwareapplication->getAuditTrail} == 1
 and UNIVERSAL::isa($hardwareapplication->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($hardwareapplication->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($hardwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$hardwareapplication->getAuditTrail} == 1
 and $hardwareapplication->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($hardwareapplication->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($hardwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$hardwareapplication->getAuditTrail} == 2
 and $hardwareapplication->getAuditTrail->[0] == $audittrail_assn
 and $hardwareapplication->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$hardwareapplication->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$hardwareapplication->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$hardwareapplication->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$hardwareapplication->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$hardwareapplication->setAuditTrail([])};
ok((!$@ and defined $hardwareapplication->getAuditTrail()
    and UNIVERSAL::isa($hardwareapplication->getAuditTrail, 'ARRAY')
    and scalar @{$hardwareapplication->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$hardwareapplication->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$hardwareapplication->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$hardwareapplication->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$hardwareapplication->setAuditTrail(undef)};
ok((!$@ and not defined $hardwareapplication->getAuditTrail()),
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


ok((UNIVERSAL::isa($hardwareapplication->getPropertySets,'ARRAY')
 and scalar @{$hardwareapplication->getPropertySets} == 1
 and UNIVERSAL::isa($hardwareapplication->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($hardwareapplication->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($hardwareapplication->getPropertySets,'ARRAY')
 and scalar @{$hardwareapplication->getPropertySets} == 1
 and $hardwareapplication->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($hardwareapplication->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($hardwareapplication->getPropertySets,'ARRAY')
 and scalar @{$hardwareapplication->getPropertySets} == 2
 and $hardwareapplication->getPropertySets->[0] == $propertysets_assn
 and $hardwareapplication->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$hardwareapplication->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$hardwareapplication->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$hardwareapplication->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$hardwareapplication->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$hardwareapplication->setPropertySets([])};
ok((!$@ and defined $hardwareapplication->getPropertySets()
    and UNIVERSAL::isa($hardwareapplication->getPropertySets, 'ARRAY')
    and scalar @{$hardwareapplication->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$hardwareapplication->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$hardwareapplication->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$hardwareapplication->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$hardwareapplication->setPropertySets(undef)};
ok((!$@ and not defined $hardwareapplication->getPropertySets()),
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



# testing association parameterValues
my $parametervalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalues_assn = Bio::MAGE::Protocol::ParameterValue->new();
}


ok((UNIVERSAL::isa($hardwareapplication->getParameterValues,'ARRAY')
 and scalar @{$hardwareapplication->getParameterValues} == 1
 and UNIVERSAL::isa($hardwareapplication->getParameterValues->[0], q[Bio::MAGE::Protocol::ParameterValue])),
  'parameterValues set in new()');

ok(eq_array($hardwareapplication->setParameterValues([$parametervalues_assn]), [$parametervalues_assn]),
   'setParameterValues returns correct value');

ok((UNIVERSAL::isa($hardwareapplication->getParameterValues,'ARRAY')
 and scalar @{$hardwareapplication->getParameterValues} == 1
 and $hardwareapplication->getParameterValues->[0] == $parametervalues_assn),
   'getParameterValues fetches correct value');

is($hardwareapplication->addParameterValues($parametervalues_assn), 2,
  'addParameterValues returns number of items in list');

ok((UNIVERSAL::isa($hardwareapplication->getParameterValues,'ARRAY')
 and scalar @{$hardwareapplication->getParameterValues} == 2
 and $hardwareapplication->getParameterValues->[0] == $parametervalues_assn
 and $hardwareapplication->getParameterValues->[1] == $parametervalues_assn),
  'addParameterValues adds correct value');

# test setParameterValues throws exception with non-array argument
eval {$hardwareapplication->setParameterValues(1)};
ok($@, 'setParameterValues throws exception with non-array argument');

# test setParameterValues throws exception with bad argument array
eval {$hardwareapplication->setParameterValues([1])};
ok($@, 'setParameterValues throws exception with bad argument array');

# test addParameterValues throws exception with no arguments
eval {$hardwareapplication->addParameterValues()};
ok($@, 'addParameterValues throws exception with no arguments');

# test addParameterValues throws exception with bad argument
eval {$hardwareapplication->addParameterValues(1)};
ok($@, 'addParameterValues throws exception with bad array');

# test setParameterValues accepts empty array ref
eval {$hardwareapplication->setParameterValues([])};
ok((!$@ and defined $hardwareapplication->getParameterValues()
    and UNIVERSAL::isa($hardwareapplication->getParameterValues, 'ARRAY')
    and scalar @{$hardwareapplication->getParameterValues} == 0),
   'setParameterValues accepts empty array ref');


# test getParameterValues throws exception with argument
eval {$hardwareapplication->getParameterValues(1)};
ok($@, 'getParameterValues throws exception with argument');

# test setParameterValues throws exception with no argument
eval {$hardwareapplication->setParameterValues()};
ok($@, 'setParameterValues throws exception with no argument');

# test setParameterValues throws exception with too many argument
eval {$hardwareapplication->setParameterValues(1,2)};
ok($@, 'setParameterValues throws exception with too many argument');

# test setParameterValues accepts undef
eval {$hardwareapplication->setParameterValues(undef)};
ok((!$@ and not defined $hardwareapplication->getParameterValues()),
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
isa_ok($hardwareapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);

