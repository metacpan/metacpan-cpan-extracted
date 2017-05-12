##############################
#
# Reporter.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Reporter.t`

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

BEGIN { use_ok('Bio::MAGE::DesignElement::Reporter') };

use Bio::MAGE::DesignElement::FeatureReporterMap;
use Bio::MAGE::BioSequence::BioSequence;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $reporter;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporter = Bio::MAGE::DesignElement::Reporter->new();
}
isa_ok($reporter, 'Bio::MAGE::DesignElement::Reporter');

# test the package_name class method
is($reporter->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($reporter->class_name(), q[Bio::MAGE::DesignElement::Reporter],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporter = Bio::MAGE::DesignElement::Reporter->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($reporter->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$reporter->setIdentifier('1');
is($reporter->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$reporter->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporter->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporter->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$reporter->setIdentifier(undef)};
ok((!$@ and not defined $reporter->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($reporter->getName(), '2',
  'name new');

# test getter/setter
$reporter->setName('2');
is($reporter->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$reporter->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporter->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporter->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$reporter->setName(undef)};
ok((!$@ and not defined $reporter->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::Reporter->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporter = Bio::MAGE::DesignElement::Reporter->new(warningType => Bio::MAGE::Description::OntologyEntry->new(),
controlType => Bio::MAGE::Description::OntologyEntry->new(),
failTypes => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
immobilizedCharacteristics => [Bio::MAGE::BioSequence::BioSequence->new()],
featureReporterMaps => [Bio::MAGE::DesignElement::FeatureReporterMap->new()]);
}

my ($end, $assn);


# testing association warningType
my $warningtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $warningtype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($reporter->getWarningType, q[Bio::MAGE::Description::OntologyEntry]);

is($reporter->setWarningType($warningtype_assn), $warningtype_assn,
  'setWarningType returns value');

ok($reporter->getWarningType() == $warningtype_assn,
   'getWarningType fetches correct value');

# test setWarningType throws exception with bad argument
eval {$reporter->setWarningType(1)};
ok($@, 'setWarningType throws exception with bad argument');


# test getWarningType throws exception with argument
eval {$reporter->getWarningType(1)};
ok($@, 'getWarningType throws exception with argument');

# test setWarningType throws exception with no argument
eval {$reporter->setWarningType()};
ok($@, 'setWarningType throws exception with no argument');

# test setWarningType throws exception with too many argument
eval {$reporter->setWarningType(1,2)};
ok($@, 'setWarningType throws exception with too many argument');

# test setWarningType accepts undef
eval {$reporter->setWarningType(undef)};
ok((!$@ and not defined $reporter->getWarningType()),
   'setWarningType accepts undef');

# test the meta-data for the assoication
$assn = $assns{warningType};
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
   'warningType->other() is a valid Bio::MAGE::Association::End'
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
   'warningType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association controlType
my $controltype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $controltype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($reporter->getControlType, q[Bio::MAGE::Description::OntologyEntry]);

is($reporter->setControlType($controltype_assn), $controltype_assn,
  'setControlType returns value');

ok($reporter->getControlType() == $controltype_assn,
   'getControlType fetches correct value');

# test setControlType throws exception with bad argument
eval {$reporter->setControlType(1)};
ok($@, 'setControlType throws exception with bad argument');


# test getControlType throws exception with argument
eval {$reporter->getControlType(1)};
ok($@, 'getControlType throws exception with argument');

# test setControlType throws exception with no argument
eval {$reporter->setControlType()};
ok($@, 'setControlType throws exception with no argument');

# test setControlType throws exception with too many argument
eval {$reporter->setControlType(1,2)};
ok($@, 'setControlType throws exception with too many argument');

# test setControlType accepts undef
eval {$reporter->setControlType(undef)};
ok((!$@ and not defined $reporter->getControlType()),
   'setControlType accepts undef');

# test the meta-data for the assoication
$assn = $assns{controlType};
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
   'controlType->other() is a valid Bio::MAGE::Association::End'
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
   'controlType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association failTypes
my $failtypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $failtypes_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($reporter->getFailTypes,'ARRAY')
 and scalar @{$reporter->getFailTypes} == 1
 and UNIVERSAL::isa($reporter->getFailTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'failTypes set in new()');

ok(eq_array($reporter->setFailTypes([$failtypes_assn]), [$failtypes_assn]),
   'setFailTypes returns correct value');

ok((UNIVERSAL::isa($reporter->getFailTypes,'ARRAY')
 and scalar @{$reporter->getFailTypes} == 1
 and $reporter->getFailTypes->[0] == $failtypes_assn),
   'getFailTypes fetches correct value');

is($reporter->addFailTypes($failtypes_assn), 2,
  'addFailTypes returns number of items in list');

ok((UNIVERSAL::isa($reporter->getFailTypes,'ARRAY')
 and scalar @{$reporter->getFailTypes} == 2
 and $reporter->getFailTypes->[0] == $failtypes_assn
 and $reporter->getFailTypes->[1] == $failtypes_assn),
  'addFailTypes adds correct value');

# test setFailTypes throws exception with non-array argument
eval {$reporter->setFailTypes(1)};
ok($@, 'setFailTypes throws exception with non-array argument');

# test setFailTypes throws exception with bad argument array
eval {$reporter->setFailTypes([1])};
ok($@, 'setFailTypes throws exception with bad argument array');

# test addFailTypes throws exception with no arguments
eval {$reporter->addFailTypes()};
ok($@, 'addFailTypes throws exception with no arguments');

# test addFailTypes throws exception with bad argument
eval {$reporter->addFailTypes(1)};
ok($@, 'addFailTypes throws exception with bad array');

# test setFailTypes accepts empty array ref
eval {$reporter->setFailTypes([])};
ok((!$@ and defined $reporter->getFailTypes()
    and UNIVERSAL::isa($reporter->getFailTypes, 'ARRAY')
    and scalar @{$reporter->getFailTypes} == 0),
   'setFailTypes accepts empty array ref');


# test getFailTypes throws exception with argument
eval {$reporter->getFailTypes(1)};
ok($@, 'getFailTypes throws exception with argument');

# test setFailTypes throws exception with no argument
eval {$reporter->setFailTypes()};
ok($@, 'setFailTypes throws exception with no argument');

# test setFailTypes throws exception with too many argument
eval {$reporter->setFailTypes(1,2)};
ok($@, 'setFailTypes throws exception with too many argument');

# test setFailTypes accepts undef
eval {$reporter->setFailTypes(undef)};
ok((!$@ and not defined $reporter->getFailTypes()),
   'setFailTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{failTypes};
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
   'failTypes->other() is a valid Bio::MAGE::Association::End'
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
   'failTypes->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($reporter->getDescriptions,'ARRAY')
 and scalar @{$reporter->getDescriptions} == 1
 and UNIVERSAL::isa($reporter->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($reporter->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($reporter->getDescriptions,'ARRAY')
 and scalar @{$reporter->getDescriptions} == 1
 and $reporter->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($reporter->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($reporter->getDescriptions,'ARRAY')
 and scalar @{$reporter->getDescriptions} == 2
 and $reporter->getDescriptions->[0] == $descriptions_assn
 and $reporter->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$reporter->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$reporter->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$reporter->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$reporter->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$reporter->setDescriptions([])};
ok((!$@ and defined $reporter->getDescriptions()
    and UNIVERSAL::isa($reporter->getDescriptions, 'ARRAY')
    and scalar @{$reporter->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$reporter->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$reporter->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$reporter->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$reporter->setDescriptions(undef)};
ok((!$@ and not defined $reporter->getDescriptions()),
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


ok((UNIVERSAL::isa($reporter->getAuditTrail,'ARRAY')
 and scalar @{$reporter->getAuditTrail} == 1
 and UNIVERSAL::isa($reporter->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($reporter->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($reporter->getAuditTrail,'ARRAY')
 and scalar @{$reporter->getAuditTrail} == 1
 and $reporter->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($reporter->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($reporter->getAuditTrail,'ARRAY')
 and scalar @{$reporter->getAuditTrail} == 2
 and $reporter->getAuditTrail->[0] == $audittrail_assn
 and $reporter->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$reporter->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$reporter->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$reporter->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$reporter->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$reporter->setAuditTrail([])};
ok((!$@ and defined $reporter->getAuditTrail()
    and UNIVERSAL::isa($reporter->getAuditTrail, 'ARRAY')
    and scalar @{$reporter->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$reporter->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$reporter->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$reporter->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$reporter->setAuditTrail(undef)};
ok((!$@ and not defined $reporter->getAuditTrail()),
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


isa_ok($reporter->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($reporter->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($reporter->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$reporter->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$reporter->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$reporter->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$reporter->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$reporter->setSecurity(undef)};
ok((!$@ and not defined $reporter->getSecurity()),
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


ok((UNIVERSAL::isa($reporter->getPropertySets,'ARRAY')
 and scalar @{$reporter->getPropertySets} == 1
 and UNIVERSAL::isa($reporter->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($reporter->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($reporter->getPropertySets,'ARRAY')
 and scalar @{$reporter->getPropertySets} == 1
 and $reporter->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($reporter->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($reporter->getPropertySets,'ARRAY')
 and scalar @{$reporter->getPropertySets} == 2
 and $reporter->getPropertySets->[0] == $propertysets_assn
 and $reporter->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$reporter->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$reporter->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$reporter->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$reporter->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$reporter->setPropertySets([])};
ok((!$@ and defined $reporter->getPropertySets()
    and UNIVERSAL::isa($reporter->getPropertySets, 'ARRAY')
    and scalar @{$reporter->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$reporter->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$reporter->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$reporter->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$reporter->setPropertySets(undef)};
ok((!$@ and not defined $reporter->getPropertySets()),
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



# testing association immobilizedCharacteristics
my $immobilizedcharacteristics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $immobilizedcharacteristics_assn = Bio::MAGE::BioSequence::BioSequence->new();
}


ok((UNIVERSAL::isa($reporter->getImmobilizedCharacteristics,'ARRAY')
 and scalar @{$reporter->getImmobilizedCharacteristics} == 1
 and UNIVERSAL::isa($reporter->getImmobilizedCharacteristics->[0], q[Bio::MAGE::BioSequence::BioSequence])),
  'immobilizedCharacteristics set in new()');

ok(eq_array($reporter->setImmobilizedCharacteristics([$immobilizedcharacteristics_assn]), [$immobilizedcharacteristics_assn]),
   'setImmobilizedCharacteristics returns correct value');

ok((UNIVERSAL::isa($reporter->getImmobilizedCharacteristics,'ARRAY')
 and scalar @{$reporter->getImmobilizedCharacteristics} == 1
 and $reporter->getImmobilizedCharacteristics->[0] == $immobilizedcharacteristics_assn),
   'getImmobilizedCharacteristics fetches correct value');

is($reporter->addImmobilizedCharacteristics($immobilizedcharacteristics_assn), 2,
  'addImmobilizedCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($reporter->getImmobilizedCharacteristics,'ARRAY')
 and scalar @{$reporter->getImmobilizedCharacteristics} == 2
 and $reporter->getImmobilizedCharacteristics->[0] == $immobilizedcharacteristics_assn
 and $reporter->getImmobilizedCharacteristics->[1] == $immobilizedcharacteristics_assn),
  'addImmobilizedCharacteristics adds correct value');

# test setImmobilizedCharacteristics throws exception with non-array argument
eval {$reporter->setImmobilizedCharacteristics(1)};
ok($@, 'setImmobilizedCharacteristics throws exception with non-array argument');

# test setImmobilizedCharacteristics throws exception with bad argument array
eval {$reporter->setImmobilizedCharacteristics([1])};
ok($@, 'setImmobilizedCharacteristics throws exception with bad argument array');

# test addImmobilizedCharacteristics throws exception with no arguments
eval {$reporter->addImmobilizedCharacteristics()};
ok($@, 'addImmobilizedCharacteristics throws exception with no arguments');

# test addImmobilizedCharacteristics throws exception with bad argument
eval {$reporter->addImmobilizedCharacteristics(1)};
ok($@, 'addImmobilizedCharacteristics throws exception with bad array');

# test setImmobilizedCharacteristics accepts empty array ref
eval {$reporter->setImmobilizedCharacteristics([])};
ok((!$@ and defined $reporter->getImmobilizedCharacteristics()
    and UNIVERSAL::isa($reporter->getImmobilizedCharacteristics, 'ARRAY')
    and scalar @{$reporter->getImmobilizedCharacteristics} == 0),
   'setImmobilizedCharacteristics accepts empty array ref');


# test getImmobilizedCharacteristics throws exception with argument
eval {$reporter->getImmobilizedCharacteristics(1)};
ok($@, 'getImmobilizedCharacteristics throws exception with argument');

# test setImmobilizedCharacteristics throws exception with no argument
eval {$reporter->setImmobilizedCharacteristics()};
ok($@, 'setImmobilizedCharacteristics throws exception with no argument');

# test setImmobilizedCharacteristics throws exception with too many argument
eval {$reporter->setImmobilizedCharacteristics(1,2)};
ok($@, 'setImmobilizedCharacteristics throws exception with too many argument');

# test setImmobilizedCharacteristics accepts undef
eval {$reporter->setImmobilizedCharacteristics(undef)};
ok((!$@ and not defined $reporter->getImmobilizedCharacteristics()),
   'setImmobilizedCharacteristics accepts undef');

# test the meta-data for the assoication
$assn = $assns{immobilizedCharacteristics};
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
   'immobilizedCharacteristics->other() is a valid Bio::MAGE::Association::End'
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
   'immobilizedCharacteristics->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureReporterMaps
my $featurereportermaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurereportermaps_assn = Bio::MAGE::DesignElement::FeatureReporterMap->new();
}


ok((UNIVERSAL::isa($reporter->getFeatureReporterMaps,'ARRAY')
 and scalar @{$reporter->getFeatureReporterMaps} == 1
 and UNIVERSAL::isa($reporter->getFeatureReporterMaps->[0], q[Bio::MAGE::DesignElement::FeatureReporterMap])),
  'featureReporterMaps set in new()');

ok(eq_array($reporter->setFeatureReporterMaps([$featurereportermaps_assn]), [$featurereportermaps_assn]),
   'setFeatureReporterMaps returns correct value');

ok((UNIVERSAL::isa($reporter->getFeatureReporterMaps,'ARRAY')
 and scalar @{$reporter->getFeatureReporterMaps} == 1
 and $reporter->getFeatureReporterMaps->[0] == $featurereportermaps_assn),
   'getFeatureReporterMaps fetches correct value');

is($reporter->addFeatureReporterMaps($featurereportermaps_assn), 2,
  'addFeatureReporterMaps returns number of items in list');

ok((UNIVERSAL::isa($reporter->getFeatureReporterMaps,'ARRAY')
 and scalar @{$reporter->getFeatureReporterMaps} == 2
 and $reporter->getFeatureReporterMaps->[0] == $featurereportermaps_assn
 and $reporter->getFeatureReporterMaps->[1] == $featurereportermaps_assn),
  'addFeatureReporterMaps adds correct value');

# test setFeatureReporterMaps throws exception with non-array argument
eval {$reporter->setFeatureReporterMaps(1)};
ok($@, 'setFeatureReporterMaps throws exception with non-array argument');

# test setFeatureReporterMaps throws exception with bad argument array
eval {$reporter->setFeatureReporterMaps([1])};
ok($@, 'setFeatureReporterMaps throws exception with bad argument array');

# test addFeatureReporterMaps throws exception with no arguments
eval {$reporter->addFeatureReporterMaps()};
ok($@, 'addFeatureReporterMaps throws exception with no arguments');

# test addFeatureReporterMaps throws exception with bad argument
eval {$reporter->addFeatureReporterMaps(1)};
ok($@, 'addFeatureReporterMaps throws exception with bad array');

# test setFeatureReporterMaps accepts empty array ref
eval {$reporter->setFeatureReporterMaps([])};
ok((!$@ and defined $reporter->getFeatureReporterMaps()
    and UNIVERSAL::isa($reporter->getFeatureReporterMaps, 'ARRAY')
    and scalar @{$reporter->getFeatureReporterMaps} == 0),
   'setFeatureReporterMaps accepts empty array ref');


# test getFeatureReporterMaps throws exception with argument
eval {$reporter->getFeatureReporterMaps(1)};
ok($@, 'getFeatureReporterMaps throws exception with argument');

# test setFeatureReporterMaps throws exception with no argument
eval {$reporter->setFeatureReporterMaps()};
ok($@, 'setFeatureReporterMaps throws exception with no argument');

# test setFeatureReporterMaps throws exception with too many argument
eval {$reporter->setFeatureReporterMaps(1,2)};
ok($@, 'setFeatureReporterMaps throws exception with too many argument');

# test setFeatureReporterMaps accepts undef
eval {$reporter->setFeatureReporterMaps(undef)};
ok((!$@ and not defined $reporter->getFeatureReporterMaps()),
   'setFeatureReporterMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureReporterMaps};
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
   'featureReporterMaps->other() is a valid Bio::MAGE::Association::End'
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
   'featureReporterMaps->self() is a valid Bio::MAGE::Association::End'
  );





my $designelement;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelement = Bio::MAGE::DesignElement::DesignElement->new();
}

# testing superclass DesignElement
isa_ok($designelement, q[Bio::MAGE::DesignElement::DesignElement]);
isa_ok($reporter, q[Bio::MAGE::DesignElement::DesignElement]);

