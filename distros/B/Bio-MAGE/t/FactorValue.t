##############################
#
# FactorValue.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FactorValue.t`

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
use Test::More tests => 127;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Experiment::FactorValue') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Measurement::Measurement;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Experiment::ExperimentalFactor;


# we test the new() method
my $factorvalue;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $factorvalue = Bio::MAGE::Experiment::FactorValue->new();
}
isa_ok($factorvalue, 'Bio::MAGE::Experiment::FactorValue');

# test the package_name class method
is($factorvalue->package_name(), q[Experiment],
  'package');

# test the class_name class method
is($factorvalue->class_name(), q[Bio::MAGE::Experiment::FactorValue],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $factorvalue = Bio::MAGE::Experiment::FactorValue->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($factorvalue->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$factorvalue->setIdentifier('1');
is($factorvalue->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$factorvalue->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$factorvalue->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$factorvalue->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$factorvalue->setIdentifier(undef)};
ok((!$@ and not defined $factorvalue->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($factorvalue->getName(), '2',
  'name new');

# test getter/setter
$factorvalue->setName('2');
is($factorvalue->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$factorvalue->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$factorvalue->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$factorvalue->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$factorvalue->setName(undef)};
ok((!$@ and not defined $factorvalue->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Experiment::FactorValue->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $factorvalue = Bio::MAGE::Experiment::FactorValue->new(experimentalFactor => Bio::MAGE::Experiment::ExperimentalFactor->new(),
measurement => Bio::MAGE::Measurement::Measurement->new(),
value => Bio::MAGE::Description::OntologyEntry->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association experimentalFactor
my $experimentalfactor_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentalfactor_assn = Bio::MAGE::Experiment::ExperimentalFactor->new();
}


isa_ok($factorvalue->getExperimentalFactor, q[Bio::MAGE::Experiment::ExperimentalFactor]);

is($factorvalue->setExperimentalFactor($experimentalfactor_assn), $experimentalfactor_assn,
  'setExperimentalFactor returns value');

ok($factorvalue->getExperimentalFactor() == $experimentalfactor_assn,
   'getExperimentalFactor fetches correct value');

# test setExperimentalFactor throws exception with bad argument
eval {$factorvalue->setExperimentalFactor(1)};
ok($@, 'setExperimentalFactor throws exception with bad argument');


# test getExperimentalFactor throws exception with argument
eval {$factorvalue->getExperimentalFactor(1)};
ok($@, 'getExperimentalFactor throws exception with argument');

# test setExperimentalFactor throws exception with no argument
eval {$factorvalue->setExperimentalFactor()};
ok($@, 'setExperimentalFactor throws exception with no argument');

# test setExperimentalFactor throws exception with too many argument
eval {$factorvalue->setExperimentalFactor(1,2)};
ok($@, 'setExperimentalFactor throws exception with too many argument');

# test setExperimentalFactor accepts undef
eval {$factorvalue->setExperimentalFactor(undef)};
ok((!$@ and not defined $factorvalue->getExperimentalFactor()),
   'setExperimentalFactor accepts undef');

# test the meta-data for the assoication
$assn = $assns{experimentalFactor};
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
   'experimentalFactor->other() is a valid Bio::MAGE::Association::End'
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
   'experimentalFactor->self() is a valid Bio::MAGE::Association::End'
  );



# testing association measurement
my $measurement_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement_assn = Bio::MAGE::Measurement::Measurement->new();
}


isa_ok($factorvalue->getMeasurement, q[Bio::MAGE::Measurement::Measurement]);

is($factorvalue->setMeasurement($measurement_assn), $measurement_assn,
  'setMeasurement returns value');

ok($factorvalue->getMeasurement() == $measurement_assn,
   'getMeasurement fetches correct value');

# test setMeasurement throws exception with bad argument
eval {$factorvalue->setMeasurement(1)};
ok($@, 'setMeasurement throws exception with bad argument');


# test getMeasurement throws exception with argument
eval {$factorvalue->getMeasurement(1)};
ok($@, 'getMeasurement throws exception with argument');

# test setMeasurement throws exception with no argument
eval {$factorvalue->setMeasurement()};
ok($@, 'setMeasurement throws exception with no argument');

# test setMeasurement throws exception with too many argument
eval {$factorvalue->setMeasurement(1,2)};
ok($@, 'setMeasurement throws exception with too many argument');

# test setMeasurement accepts undef
eval {$factorvalue->setMeasurement(undef)};
ok((!$@ and not defined $factorvalue->getMeasurement()),
   'setMeasurement accepts undef');

# test the meta-data for the assoication
$assn = $assns{measurement};
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
   'measurement->other() is a valid Bio::MAGE::Association::End'
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
   'measurement->self() is a valid Bio::MAGE::Association::End'
  );



# testing association value
my $value_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $value_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($factorvalue->getValue, q[Bio::MAGE::Description::OntologyEntry]);

is($factorvalue->setValue($value_assn), $value_assn,
  'setValue returns value');

ok($factorvalue->getValue() == $value_assn,
   'getValue fetches correct value');

# test setValue throws exception with bad argument
eval {$factorvalue->setValue(1)};
ok($@, 'setValue throws exception with bad argument');


# test getValue throws exception with argument
eval {$factorvalue->getValue(1)};
ok($@, 'getValue throws exception with argument');

# test setValue throws exception with no argument
eval {$factorvalue->setValue()};
ok($@, 'setValue throws exception with no argument');

# test setValue throws exception with too many argument
eval {$factorvalue->setValue(1,2)};
ok($@, 'setValue throws exception with too many argument');

# test setValue accepts undef
eval {$factorvalue->setValue(undef)};
ok((!$@ and not defined $factorvalue->getValue()),
   'setValue accepts undef');

# test the meta-data for the assoication
$assn = $assns{value};
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
   'value->other() is a valid Bio::MAGE::Association::End'
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
   'value->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($factorvalue->getDescriptions,'ARRAY')
 and scalar @{$factorvalue->getDescriptions} == 1
 and UNIVERSAL::isa($factorvalue->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($factorvalue->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($factorvalue->getDescriptions,'ARRAY')
 and scalar @{$factorvalue->getDescriptions} == 1
 and $factorvalue->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($factorvalue->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($factorvalue->getDescriptions,'ARRAY')
 and scalar @{$factorvalue->getDescriptions} == 2
 and $factorvalue->getDescriptions->[0] == $descriptions_assn
 and $factorvalue->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$factorvalue->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$factorvalue->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$factorvalue->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$factorvalue->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$factorvalue->setDescriptions([])};
ok((!$@ and defined $factorvalue->getDescriptions()
    and UNIVERSAL::isa($factorvalue->getDescriptions, 'ARRAY')
    and scalar @{$factorvalue->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$factorvalue->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$factorvalue->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$factorvalue->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$factorvalue->setDescriptions(undef)};
ok((!$@ and not defined $factorvalue->getDescriptions()),
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


isa_ok($factorvalue->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($factorvalue->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($factorvalue->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$factorvalue->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$factorvalue->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$factorvalue->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$factorvalue->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$factorvalue->setSecurity(undef)};
ok((!$@ and not defined $factorvalue->getSecurity()),
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


ok((UNIVERSAL::isa($factorvalue->getAuditTrail,'ARRAY')
 and scalar @{$factorvalue->getAuditTrail} == 1
 and UNIVERSAL::isa($factorvalue->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($factorvalue->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($factorvalue->getAuditTrail,'ARRAY')
 and scalar @{$factorvalue->getAuditTrail} == 1
 and $factorvalue->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($factorvalue->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($factorvalue->getAuditTrail,'ARRAY')
 and scalar @{$factorvalue->getAuditTrail} == 2
 and $factorvalue->getAuditTrail->[0] == $audittrail_assn
 and $factorvalue->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$factorvalue->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$factorvalue->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$factorvalue->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$factorvalue->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$factorvalue->setAuditTrail([])};
ok((!$@ and defined $factorvalue->getAuditTrail()
    and UNIVERSAL::isa($factorvalue->getAuditTrail, 'ARRAY')
    and scalar @{$factorvalue->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$factorvalue->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$factorvalue->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$factorvalue->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$factorvalue->setAuditTrail(undef)};
ok((!$@ and not defined $factorvalue->getAuditTrail()),
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


ok((UNIVERSAL::isa($factorvalue->getPropertySets,'ARRAY')
 and scalar @{$factorvalue->getPropertySets} == 1
 and UNIVERSAL::isa($factorvalue->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($factorvalue->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($factorvalue->getPropertySets,'ARRAY')
 and scalar @{$factorvalue->getPropertySets} == 1
 and $factorvalue->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($factorvalue->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($factorvalue->getPropertySets,'ARRAY')
 and scalar @{$factorvalue->getPropertySets} == 2
 and $factorvalue->getPropertySets->[0] == $propertysets_assn
 and $factorvalue->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$factorvalue->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$factorvalue->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$factorvalue->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$factorvalue->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$factorvalue->setPropertySets([])};
ok((!$@ and defined $factorvalue->getPropertySets()
    and UNIVERSAL::isa($factorvalue->getPropertySets, 'ARRAY')
    and scalar @{$factorvalue->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$factorvalue->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$factorvalue->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$factorvalue->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$factorvalue->setPropertySets(undef)};
ok((!$@ and not defined $factorvalue->getPropertySets()),
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





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($factorvalue, q[Bio::MAGE::Identifiable]);

