##############################
#
# ArrayManufacture.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayManufacture.t`

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
use Test::More tests => 195;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::ArrayManufacture') };

use Bio::MAGE::Array::Array;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Array::ManufactureLIMS;


# we test the new() method
my $arraymanufacture;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacture = Bio::MAGE::Array::ArrayManufacture->new();
}
isa_ok($arraymanufacture, 'Bio::MAGE::Array::ArrayManufacture');

# test the package_name class method
is($arraymanufacture->package_name(), q[Array],
  'package');

# test the class_name class method
is($arraymanufacture->class_name(), q[Bio::MAGE::Array::ArrayManufacture],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacture = Bio::MAGE::Array::ArrayManufacture->new(identifier => '1',
tolerance => '2',
name => '3',
manufacturingDate => '4');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($arraymanufacture->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$arraymanufacture->setIdentifier('1');
is($arraymanufacture->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$arraymanufacture->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraymanufacture->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraymanufacture->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$arraymanufacture->setIdentifier(undef)};
ok((!$@ and not defined $arraymanufacture->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute tolerance
#

# test attribute values can be set in new()
is($arraymanufacture->getTolerance(), '2',
  'tolerance new');

# test getter/setter
$arraymanufacture->setTolerance('2');
is($arraymanufacture->getTolerance(), '2',
  'tolerance getter/setter');

# test getter throws exception with argument
eval {$arraymanufacture->getTolerance(1)};
ok($@, 'tolerance getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraymanufacture->setTolerance()};
ok($@, 'tolerance setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraymanufacture->setTolerance('2', '2')};
ok($@, 'tolerance setter throws exception with too many argument');

# test setter accepts undef
eval {$arraymanufacture->setTolerance(undef)};
ok((!$@ and not defined $arraymanufacture->getTolerance()),
   'tolerance setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($arraymanufacture->getName(), '3',
  'name new');

# test getter/setter
$arraymanufacture->setName('3');
is($arraymanufacture->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$arraymanufacture->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraymanufacture->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraymanufacture->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$arraymanufacture->setName(undef)};
ok((!$@ and not defined $arraymanufacture->getName()),
   'name setter accepts undef');



#
# testing attribute manufacturingDate
#

# test attribute values can be set in new()
is($arraymanufacture->getManufacturingDate(), '4',
  'manufacturingDate new');

# test getter/setter
$arraymanufacture->setManufacturingDate('4');
is($arraymanufacture->getManufacturingDate(), '4',
  'manufacturingDate getter/setter');

# test getter throws exception with argument
eval {$arraymanufacture->getManufacturingDate(1)};
ok($@, 'manufacturingDate getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraymanufacture->setManufacturingDate()};
ok($@, 'manufacturingDate setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraymanufacture->setManufacturingDate('4', '4')};
ok($@, 'manufacturingDate setter throws exception with too many argument');

# test setter accepts undef
eval {$arraymanufacture->setManufacturingDate(undef)};
ok((!$@ and not defined $arraymanufacture->getManufacturingDate()),
   'manufacturingDate setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ArrayManufacture->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacture = Bio::MAGE::Array::ArrayManufacture->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
arrayManufacturers => [Bio::MAGE::AuditAndSecurity::Contact->new()],
featureLIMSs => [Bio::MAGE::Array::ManufactureLIMS->new()],
arrays => [Bio::MAGE::Array::Array->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
qualityControlStatistics => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getProtocolApplications,'ARRAY')
 and scalar @{$arraymanufacture->getProtocolApplications} == 1
 and UNIVERSAL::isa($arraymanufacture->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($arraymanufacture->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getProtocolApplications,'ARRAY')
 and scalar @{$arraymanufacture->getProtocolApplications} == 1
 and $arraymanufacture->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($arraymanufacture->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getProtocolApplications,'ARRAY')
 and scalar @{$arraymanufacture->getProtocolApplications} == 2
 and $arraymanufacture->getProtocolApplications->[0] == $protocolapplications_assn
 and $arraymanufacture->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$arraymanufacture->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$arraymanufacture->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$arraymanufacture->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$arraymanufacture->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$arraymanufacture->setProtocolApplications([])};
ok((!$@ and defined $arraymanufacture->getProtocolApplications()
    and UNIVERSAL::isa($arraymanufacture->getProtocolApplications, 'ARRAY')
    and scalar @{$arraymanufacture->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$arraymanufacture->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$arraymanufacture->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$arraymanufacture->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$arraymanufacture->setProtocolApplications(undef)};
ok((!$@ and not defined $arraymanufacture->getProtocolApplications()),
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



# testing association arrayManufacturers
my $arraymanufacturers_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacturers_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getArrayManufacturers,'ARRAY')
 and scalar @{$arraymanufacture->getArrayManufacturers} == 1
 and UNIVERSAL::isa($arraymanufacture->getArrayManufacturers->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'arrayManufacturers set in new()');

ok(eq_array($arraymanufacture->setArrayManufacturers([$arraymanufacturers_assn]), [$arraymanufacturers_assn]),
   'setArrayManufacturers returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getArrayManufacturers,'ARRAY')
 and scalar @{$arraymanufacture->getArrayManufacturers} == 1
 and $arraymanufacture->getArrayManufacturers->[0] == $arraymanufacturers_assn),
   'getArrayManufacturers fetches correct value');

is($arraymanufacture->addArrayManufacturers($arraymanufacturers_assn), 2,
  'addArrayManufacturers returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getArrayManufacturers,'ARRAY')
 and scalar @{$arraymanufacture->getArrayManufacturers} == 2
 and $arraymanufacture->getArrayManufacturers->[0] == $arraymanufacturers_assn
 and $arraymanufacture->getArrayManufacturers->[1] == $arraymanufacturers_assn),
  'addArrayManufacturers adds correct value');

# test setArrayManufacturers throws exception with non-array argument
eval {$arraymanufacture->setArrayManufacturers(1)};
ok($@, 'setArrayManufacturers throws exception with non-array argument');

# test setArrayManufacturers throws exception with bad argument array
eval {$arraymanufacture->setArrayManufacturers([1])};
ok($@, 'setArrayManufacturers throws exception with bad argument array');

# test addArrayManufacturers throws exception with no arguments
eval {$arraymanufacture->addArrayManufacturers()};
ok($@, 'addArrayManufacturers throws exception with no arguments');

# test addArrayManufacturers throws exception with bad argument
eval {$arraymanufacture->addArrayManufacturers(1)};
ok($@, 'addArrayManufacturers throws exception with bad array');

# test setArrayManufacturers accepts empty array ref
eval {$arraymanufacture->setArrayManufacturers([])};
ok((!$@ and defined $arraymanufacture->getArrayManufacturers()
    and UNIVERSAL::isa($arraymanufacture->getArrayManufacturers, 'ARRAY')
    and scalar @{$arraymanufacture->getArrayManufacturers} == 0),
   'setArrayManufacturers accepts empty array ref');


# test getArrayManufacturers throws exception with argument
eval {$arraymanufacture->getArrayManufacturers(1)};
ok($@, 'getArrayManufacturers throws exception with argument');

# test setArrayManufacturers throws exception with no argument
eval {$arraymanufacture->setArrayManufacturers()};
ok($@, 'setArrayManufacturers throws exception with no argument');

# test setArrayManufacturers throws exception with too many argument
eval {$arraymanufacture->setArrayManufacturers(1,2)};
ok($@, 'setArrayManufacturers throws exception with too many argument');

# test setArrayManufacturers accepts undef
eval {$arraymanufacture->setArrayManufacturers(undef)};
ok((!$@ and not defined $arraymanufacture->getArrayManufacturers()),
   'setArrayManufacturers accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrayManufacturers};
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
   'arrayManufacturers->other() is a valid Bio::MAGE::Association::End'
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
   'arrayManufacturers->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureLIMSs
my $featurelimss_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurelimss_assn = Bio::MAGE::Array::ManufactureLIMS->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getFeatureLIMSs,'ARRAY')
 and scalar @{$arraymanufacture->getFeatureLIMSs} == 1
 and UNIVERSAL::isa($arraymanufacture->getFeatureLIMSs->[0], q[Bio::MAGE::Array::ManufactureLIMS])),
  'featureLIMSs set in new()');

ok(eq_array($arraymanufacture->setFeatureLIMSs([$featurelimss_assn]), [$featurelimss_assn]),
   'setFeatureLIMSs returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getFeatureLIMSs,'ARRAY')
 and scalar @{$arraymanufacture->getFeatureLIMSs} == 1
 and $arraymanufacture->getFeatureLIMSs->[0] == $featurelimss_assn),
   'getFeatureLIMSs fetches correct value');

is($arraymanufacture->addFeatureLIMSs($featurelimss_assn), 2,
  'addFeatureLIMSs returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getFeatureLIMSs,'ARRAY')
 and scalar @{$arraymanufacture->getFeatureLIMSs} == 2
 and $arraymanufacture->getFeatureLIMSs->[0] == $featurelimss_assn
 and $arraymanufacture->getFeatureLIMSs->[1] == $featurelimss_assn),
  'addFeatureLIMSs adds correct value');

# test setFeatureLIMSs throws exception with non-array argument
eval {$arraymanufacture->setFeatureLIMSs(1)};
ok($@, 'setFeatureLIMSs throws exception with non-array argument');

# test setFeatureLIMSs throws exception with bad argument array
eval {$arraymanufacture->setFeatureLIMSs([1])};
ok($@, 'setFeatureLIMSs throws exception with bad argument array');

# test addFeatureLIMSs throws exception with no arguments
eval {$arraymanufacture->addFeatureLIMSs()};
ok($@, 'addFeatureLIMSs throws exception with no arguments');

# test addFeatureLIMSs throws exception with bad argument
eval {$arraymanufacture->addFeatureLIMSs(1)};
ok($@, 'addFeatureLIMSs throws exception with bad array');

# test setFeatureLIMSs accepts empty array ref
eval {$arraymanufacture->setFeatureLIMSs([])};
ok((!$@ and defined $arraymanufacture->getFeatureLIMSs()
    and UNIVERSAL::isa($arraymanufacture->getFeatureLIMSs, 'ARRAY')
    and scalar @{$arraymanufacture->getFeatureLIMSs} == 0),
   'setFeatureLIMSs accepts empty array ref');


# test getFeatureLIMSs throws exception with argument
eval {$arraymanufacture->getFeatureLIMSs(1)};
ok($@, 'getFeatureLIMSs throws exception with argument');

# test setFeatureLIMSs throws exception with no argument
eval {$arraymanufacture->setFeatureLIMSs()};
ok($@, 'setFeatureLIMSs throws exception with no argument');

# test setFeatureLIMSs throws exception with too many argument
eval {$arraymanufacture->setFeatureLIMSs(1,2)};
ok($@, 'setFeatureLIMSs throws exception with too many argument');

# test setFeatureLIMSs accepts undef
eval {$arraymanufacture->setFeatureLIMSs(undef)};
ok((!$@ and not defined $arraymanufacture->getFeatureLIMSs()),
   'setFeatureLIMSs accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureLIMSs};
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
   'featureLIMSs->other() is a valid Bio::MAGE::Association::End'
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
   'featureLIMSs->self() is a valid Bio::MAGE::Association::End'
  );



# testing association arrays
my $arrays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arrays_assn = Bio::MAGE::Array::Array->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getArrays,'ARRAY')
 and scalar @{$arraymanufacture->getArrays} == 1
 and UNIVERSAL::isa($arraymanufacture->getArrays->[0], q[Bio::MAGE::Array::Array])),
  'arrays set in new()');

ok(eq_array($arraymanufacture->setArrays([$arrays_assn]), [$arrays_assn]),
   'setArrays returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getArrays,'ARRAY')
 and scalar @{$arraymanufacture->getArrays} == 1
 and $arraymanufacture->getArrays->[0] == $arrays_assn),
   'getArrays fetches correct value');

is($arraymanufacture->addArrays($arrays_assn), 2,
  'addArrays returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getArrays,'ARRAY')
 and scalar @{$arraymanufacture->getArrays} == 2
 and $arraymanufacture->getArrays->[0] == $arrays_assn
 and $arraymanufacture->getArrays->[1] == $arrays_assn),
  'addArrays adds correct value');

# test setArrays throws exception with non-array argument
eval {$arraymanufacture->setArrays(1)};
ok($@, 'setArrays throws exception with non-array argument');

# test setArrays throws exception with bad argument array
eval {$arraymanufacture->setArrays([1])};
ok($@, 'setArrays throws exception with bad argument array');

# test addArrays throws exception with no arguments
eval {$arraymanufacture->addArrays()};
ok($@, 'addArrays throws exception with no arguments');

# test addArrays throws exception with bad argument
eval {$arraymanufacture->addArrays(1)};
ok($@, 'addArrays throws exception with bad array');

# test setArrays accepts empty array ref
eval {$arraymanufacture->setArrays([])};
ok((!$@ and defined $arraymanufacture->getArrays()
    and UNIVERSAL::isa($arraymanufacture->getArrays, 'ARRAY')
    and scalar @{$arraymanufacture->getArrays} == 0),
   'setArrays accepts empty array ref');


# test getArrays throws exception with argument
eval {$arraymanufacture->getArrays(1)};
ok($@, 'getArrays throws exception with argument');

# test setArrays throws exception with no argument
eval {$arraymanufacture->setArrays()};
ok($@, 'setArrays throws exception with no argument');

# test setArrays throws exception with too many argument
eval {$arraymanufacture->setArrays(1,2)};
ok($@, 'setArrays throws exception with too many argument');

# test setArrays accepts undef
eval {$arraymanufacture->setArrays(undef)};
ok((!$@ and not defined $arraymanufacture->getArrays()),
   'setArrays accepts undef');

# test the meta-data for the assoication
$assn = $assns{arrays};
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
   'arrays->other() is a valid Bio::MAGE::Association::End'
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
   'arrays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getDescriptions,'ARRAY')
 and scalar @{$arraymanufacture->getDescriptions} == 1
 and UNIVERSAL::isa($arraymanufacture->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($arraymanufacture->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getDescriptions,'ARRAY')
 and scalar @{$arraymanufacture->getDescriptions} == 1
 and $arraymanufacture->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($arraymanufacture->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getDescriptions,'ARRAY')
 and scalar @{$arraymanufacture->getDescriptions} == 2
 and $arraymanufacture->getDescriptions->[0] == $descriptions_assn
 and $arraymanufacture->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$arraymanufacture->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$arraymanufacture->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$arraymanufacture->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$arraymanufacture->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$arraymanufacture->setDescriptions([])};
ok((!$@ and defined $arraymanufacture->getDescriptions()
    and UNIVERSAL::isa($arraymanufacture->getDescriptions, 'ARRAY')
    and scalar @{$arraymanufacture->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$arraymanufacture->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$arraymanufacture->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$arraymanufacture->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$arraymanufacture->setDescriptions(undef)};
ok((!$@ and not defined $arraymanufacture->getDescriptions()),
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


isa_ok($arraymanufacture->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($arraymanufacture->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($arraymanufacture->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$arraymanufacture->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$arraymanufacture->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$arraymanufacture->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$arraymanufacture->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$arraymanufacture->setSecurity(undef)};
ok((!$@ and not defined $arraymanufacture->getSecurity()),
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


ok((UNIVERSAL::isa($arraymanufacture->getAuditTrail,'ARRAY')
 and scalar @{$arraymanufacture->getAuditTrail} == 1
 and UNIVERSAL::isa($arraymanufacture->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($arraymanufacture->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getAuditTrail,'ARRAY')
 and scalar @{$arraymanufacture->getAuditTrail} == 1
 and $arraymanufacture->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($arraymanufacture->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getAuditTrail,'ARRAY')
 and scalar @{$arraymanufacture->getAuditTrail} == 2
 and $arraymanufacture->getAuditTrail->[0] == $audittrail_assn
 and $arraymanufacture->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$arraymanufacture->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$arraymanufacture->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$arraymanufacture->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$arraymanufacture->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$arraymanufacture->setAuditTrail([])};
ok((!$@ and defined $arraymanufacture->getAuditTrail()
    and UNIVERSAL::isa($arraymanufacture->getAuditTrail, 'ARRAY')
    and scalar @{$arraymanufacture->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$arraymanufacture->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$arraymanufacture->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$arraymanufacture->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$arraymanufacture->setAuditTrail(undef)};
ok((!$@ and not defined $arraymanufacture->getAuditTrail()),
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


ok((UNIVERSAL::isa($arraymanufacture->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacture->getPropertySets} == 1
 and UNIVERSAL::isa($arraymanufacture->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($arraymanufacture->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacture->getPropertySets} == 1
 and $arraymanufacture->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($arraymanufacture->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacture->getPropertySets} == 2
 and $arraymanufacture->getPropertySets->[0] == $propertysets_assn
 and $arraymanufacture->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$arraymanufacture->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$arraymanufacture->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$arraymanufacture->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$arraymanufacture->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$arraymanufacture->setPropertySets([])};
ok((!$@ and defined $arraymanufacture->getPropertySets()
    and UNIVERSAL::isa($arraymanufacture->getPropertySets, 'ARRAY')
    and scalar @{$arraymanufacture->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$arraymanufacture->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$arraymanufacture->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$arraymanufacture->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$arraymanufacture->setPropertySets(undef)};
ok((!$@ and not defined $arraymanufacture->getPropertySets()),
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



# testing association qualityControlStatistics
my $qualitycontrolstatistics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $qualitycontrolstatistics_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($arraymanufacture->getQualityControlStatistics,'ARRAY')
 and scalar @{$arraymanufacture->getQualityControlStatistics} == 1
 and UNIVERSAL::isa($arraymanufacture->getQualityControlStatistics->[0], q[Bio::MAGE::NameValueType])),
  'qualityControlStatistics set in new()');

ok(eq_array($arraymanufacture->setQualityControlStatistics([$qualitycontrolstatistics_assn]), [$qualitycontrolstatistics_assn]),
   'setQualityControlStatistics returns correct value');

ok((UNIVERSAL::isa($arraymanufacture->getQualityControlStatistics,'ARRAY')
 and scalar @{$arraymanufacture->getQualityControlStatistics} == 1
 and $arraymanufacture->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn),
   'getQualityControlStatistics fetches correct value');

is($arraymanufacture->addQualityControlStatistics($qualitycontrolstatistics_assn), 2,
  'addQualityControlStatistics returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacture->getQualityControlStatistics,'ARRAY')
 and scalar @{$arraymanufacture->getQualityControlStatistics} == 2
 and $arraymanufacture->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn
 and $arraymanufacture->getQualityControlStatistics->[1] == $qualitycontrolstatistics_assn),
  'addQualityControlStatistics adds correct value');

# test setQualityControlStatistics throws exception with non-array argument
eval {$arraymanufacture->setQualityControlStatistics(1)};
ok($@, 'setQualityControlStatistics throws exception with non-array argument');

# test setQualityControlStatistics throws exception with bad argument array
eval {$arraymanufacture->setQualityControlStatistics([1])};
ok($@, 'setQualityControlStatistics throws exception with bad argument array');

# test addQualityControlStatistics throws exception with no arguments
eval {$arraymanufacture->addQualityControlStatistics()};
ok($@, 'addQualityControlStatistics throws exception with no arguments');

# test addQualityControlStatistics throws exception with bad argument
eval {$arraymanufacture->addQualityControlStatistics(1)};
ok($@, 'addQualityControlStatistics throws exception with bad array');

# test setQualityControlStatistics accepts empty array ref
eval {$arraymanufacture->setQualityControlStatistics([])};
ok((!$@ and defined $arraymanufacture->getQualityControlStatistics()
    and UNIVERSAL::isa($arraymanufacture->getQualityControlStatistics, 'ARRAY')
    and scalar @{$arraymanufacture->getQualityControlStatistics} == 0),
   'setQualityControlStatistics accepts empty array ref');


# test getQualityControlStatistics throws exception with argument
eval {$arraymanufacture->getQualityControlStatistics(1)};
ok($@, 'getQualityControlStatistics throws exception with argument');

# test setQualityControlStatistics throws exception with no argument
eval {$arraymanufacture->setQualityControlStatistics()};
ok($@, 'setQualityControlStatistics throws exception with no argument');

# test setQualityControlStatistics throws exception with too many argument
eval {$arraymanufacture->setQualityControlStatistics(1,2)};
ok($@, 'setQualityControlStatistics throws exception with too many argument');

# test setQualityControlStatistics accepts undef
eval {$arraymanufacture->setQualityControlStatistics(undef)};
ok((!$@ and not defined $arraymanufacture->getQualityControlStatistics()),
   'setQualityControlStatistics accepts undef');

# test the meta-data for the assoication
$assn = $assns{qualityControlStatistics};
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
   'qualityControlStatistics->other() is a valid Bio::MAGE::Association::End'
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
   'qualityControlStatistics->self() is a valid Bio::MAGE::Association::End'
  );





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($arraymanufacture, q[Bio::MAGE::Identifiable]);

