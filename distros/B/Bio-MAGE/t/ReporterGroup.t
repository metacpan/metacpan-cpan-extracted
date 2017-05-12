##############################
#
# ReporterGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ReporterGroup.t`

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
use Test::More tests => 139;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::ReporterGroup') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::DesignElement::Reporter;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $reportergroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportergroup = Bio::MAGE::ArrayDesign::ReporterGroup->new();
}
isa_ok($reportergroup, 'Bio::MAGE::ArrayDesign::ReporterGroup');

# test the package_name class method
is($reportergroup->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($reportergroup->class_name(), q[Bio::MAGE::ArrayDesign::ReporterGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportergroup = Bio::MAGE::ArrayDesign::ReporterGroup->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($reportergroup->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$reportergroup->setIdentifier('1');
is($reportergroup->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$reportergroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$reportergroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reportergroup->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$reportergroup->setIdentifier(undef)};
ok((!$@ and not defined $reportergroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($reportergroup->getName(), '2',
  'name new');

# test getter/setter
$reportergroup->setName('2');
is($reportergroup->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$reportergroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$reportergroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reportergroup->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$reportergroup->setName(undef)};
ok((!$@ and not defined $reportergroup->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::ReporterGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportergroup = Bio::MAGE::ArrayDesign::ReporterGroup->new(reporters => [Bio::MAGE::DesignElement::Reporter->new()],
types => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
species => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association reporters
my $reporters_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporters_assn = Bio::MAGE::DesignElement::Reporter->new();
}


ok((UNIVERSAL::isa($reportergroup->getReporters,'ARRAY')
 and scalar @{$reportergroup->getReporters} == 1
 and UNIVERSAL::isa($reportergroup->getReporters->[0], q[Bio::MAGE::DesignElement::Reporter])),
  'reporters set in new()');

ok(eq_array($reportergroup->setReporters([$reporters_assn]), [$reporters_assn]),
   'setReporters returns correct value');

ok((UNIVERSAL::isa($reportergroup->getReporters,'ARRAY')
 and scalar @{$reportergroup->getReporters} == 1
 and $reportergroup->getReporters->[0] == $reporters_assn),
   'getReporters fetches correct value');

is($reportergroup->addReporters($reporters_assn), 2,
  'addReporters returns number of items in list');

ok((UNIVERSAL::isa($reportergroup->getReporters,'ARRAY')
 and scalar @{$reportergroup->getReporters} == 2
 and $reportergroup->getReporters->[0] == $reporters_assn
 and $reportergroup->getReporters->[1] == $reporters_assn),
  'addReporters adds correct value');

# test setReporters throws exception with non-array argument
eval {$reportergroup->setReporters(1)};
ok($@, 'setReporters throws exception with non-array argument');

# test setReporters throws exception with bad argument array
eval {$reportergroup->setReporters([1])};
ok($@, 'setReporters throws exception with bad argument array');

# test addReporters throws exception with no arguments
eval {$reportergroup->addReporters()};
ok($@, 'addReporters throws exception with no arguments');

# test addReporters throws exception with bad argument
eval {$reportergroup->addReporters(1)};
ok($@, 'addReporters throws exception with bad array');

# test setReporters accepts empty array ref
eval {$reportergroup->setReporters([])};
ok((!$@ and defined $reportergroup->getReporters()
    and UNIVERSAL::isa($reportergroup->getReporters, 'ARRAY')
    and scalar @{$reportergroup->getReporters} == 0),
   'setReporters accepts empty array ref');


# test getReporters throws exception with argument
eval {$reportergroup->getReporters(1)};
ok($@, 'getReporters throws exception with argument');

# test setReporters throws exception with no argument
eval {$reportergroup->setReporters()};
ok($@, 'setReporters throws exception with no argument');

# test setReporters throws exception with too many argument
eval {$reportergroup->setReporters(1,2)};
ok($@, 'setReporters throws exception with too many argument');

# test setReporters accepts undef
eval {$reportergroup->setReporters(undef)};
ok((!$@ and not defined $reportergroup->getReporters()),
   'setReporters accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporters};
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
   'reporters->other() is a valid Bio::MAGE::Association::End'
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
   'reporters->self() is a valid Bio::MAGE::Association::End'
  );



# testing association types
my $types_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $types_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($reportergroup->getTypes,'ARRAY')
 and scalar @{$reportergroup->getTypes} == 1
 and UNIVERSAL::isa($reportergroup->getTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'types set in new()');

ok(eq_array($reportergroup->setTypes([$types_assn]), [$types_assn]),
   'setTypes returns correct value');

ok((UNIVERSAL::isa($reportergroup->getTypes,'ARRAY')
 and scalar @{$reportergroup->getTypes} == 1
 and $reportergroup->getTypes->[0] == $types_assn),
   'getTypes fetches correct value');

is($reportergroup->addTypes($types_assn), 2,
  'addTypes returns number of items in list');

ok((UNIVERSAL::isa($reportergroup->getTypes,'ARRAY')
 and scalar @{$reportergroup->getTypes} == 2
 and $reportergroup->getTypes->[0] == $types_assn
 and $reportergroup->getTypes->[1] == $types_assn),
  'addTypes adds correct value');

# test setTypes throws exception with non-array argument
eval {$reportergroup->setTypes(1)};
ok($@, 'setTypes throws exception with non-array argument');

# test setTypes throws exception with bad argument array
eval {$reportergroup->setTypes([1])};
ok($@, 'setTypes throws exception with bad argument array');

# test addTypes throws exception with no arguments
eval {$reportergroup->addTypes()};
ok($@, 'addTypes throws exception with no arguments');

# test addTypes throws exception with bad argument
eval {$reportergroup->addTypes(1)};
ok($@, 'addTypes throws exception with bad array');

# test setTypes accepts empty array ref
eval {$reportergroup->setTypes([])};
ok((!$@ and defined $reportergroup->getTypes()
    and UNIVERSAL::isa($reportergroup->getTypes, 'ARRAY')
    and scalar @{$reportergroup->getTypes} == 0),
   'setTypes accepts empty array ref');


# test getTypes throws exception with argument
eval {$reportergroup->getTypes(1)};
ok($@, 'getTypes throws exception with argument');

# test setTypes throws exception with no argument
eval {$reportergroup->setTypes()};
ok($@, 'setTypes throws exception with no argument');

# test setTypes throws exception with too many argument
eval {$reportergroup->setTypes(1,2)};
ok($@, 'setTypes throws exception with too many argument');

# test setTypes accepts undef
eval {$reportergroup->setTypes(undef)};
ok((!$@ and not defined $reportergroup->getTypes()),
   'setTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{types};
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
   'types->other() is a valid Bio::MAGE::Association::End'
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
   'types->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($reportergroup->getDescriptions,'ARRAY')
 and scalar @{$reportergroup->getDescriptions} == 1
 and UNIVERSAL::isa($reportergroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($reportergroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($reportergroup->getDescriptions,'ARRAY')
 and scalar @{$reportergroup->getDescriptions} == 1
 and $reportergroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($reportergroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($reportergroup->getDescriptions,'ARRAY')
 and scalar @{$reportergroup->getDescriptions} == 2
 and $reportergroup->getDescriptions->[0] == $descriptions_assn
 and $reportergroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$reportergroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$reportergroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$reportergroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$reportergroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$reportergroup->setDescriptions([])};
ok((!$@ and defined $reportergroup->getDescriptions()
    and UNIVERSAL::isa($reportergroup->getDescriptions, 'ARRAY')
    and scalar @{$reportergroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$reportergroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$reportergroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$reportergroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$reportergroup->setDescriptions(undef)};
ok((!$@ and not defined $reportergroup->getDescriptions()),
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


ok((UNIVERSAL::isa($reportergroup->getAuditTrail,'ARRAY')
 and scalar @{$reportergroup->getAuditTrail} == 1
 and UNIVERSAL::isa($reportergroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($reportergroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($reportergroup->getAuditTrail,'ARRAY')
 and scalar @{$reportergroup->getAuditTrail} == 1
 and $reportergroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($reportergroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($reportergroup->getAuditTrail,'ARRAY')
 and scalar @{$reportergroup->getAuditTrail} == 2
 and $reportergroup->getAuditTrail->[0] == $audittrail_assn
 and $reportergroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$reportergroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$reportergroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$reportergroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$reportergroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$reportergroup->setAuditTrail([])};
ok((!$@ and defined $reportergroup->getAuditTrail()
    and UNIVERSAL::isa($reportergroup->getAuditTrail, 'ARRAY')
    and scalar @{$reportergroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$reportergroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$reportergroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$reportergroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$reportergroup->setAuditTrail(undef)};
ok((!$@ and not defined $reportergroup->getAuditTrail()),
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


isa_ok($reportergroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($reportergroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($reportergroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$reportergroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$reportergroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$reportergroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$reportergroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$reportergroup->setSecurity(undef)};
ok((!$@ and not defined $reportergroup->getSecurity()),
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


ok((UNIVERSAL::isa($reportergroup->getPropertySets,'ARRAY')
 and scalar @{$reportergroup->getPropertySets} == 1
 and UNIVERSAL::isa($reportergroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($reportergroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($reportergroup->getPropertySets,'ARRAY')
 and scalar @{$reportergroup->getPropertySets} == 1
 and $reportergroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($reportergroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($reportergroup->getPropertySets,'ARRAY')
 and scalar @{$reportergroup->getPropertySets} == 2
 and $reportergroup->getPropertySets->[0] == $propertysets_assn
 and $reportergroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$reportergroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$reportergroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$reportergroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$reportergroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$reportergroup->setPropertySets([])};
ok((!$@ and defined $reportergroup->getPropertySets()
    and UNIVERSAL::isa($reportergroup->getPropertySets, 'ARRAY')
    and scalar @{$reportergroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$reportergroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$reportergroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$reportergroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$reportergroup->setPropertySets(undef)};
ok((!$@ and not defined $reportergroup->getPropertySets()),
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



# testing association species
my $species_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $species_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($reportergroup->getSpecies, q[Bio::MAGE::Description::OntologyEntry]);

is($reportergroup->setSpecies($species_assn), $species_assn,
  'setSpecies returns value');

ok($reportergroup->getSpecies() == $species_assn,
   'getSpecies fetches correct value');

# test setSpecies throws exception with bad argument
eval {$reportergroup->setSpecies(1)};
ok($@, 'setSpecies throws exception with bad argument');


# test getSpecies throws exception with argument
eval {$reportergroup->getSpecies(1)};
ok($@, 'getSpecies throws exception with argument');

# test setSpecies throws exception with no argument
eval {$reportergroup->setSpecies()};
ok($@, 'setSpecies throws exception with no argument');

# test setSpecies throws exception with too many argument
eval {$reportergroup->setSpecies(1,2)};
ok($@, 'setSpecies throws exception with too many argument');

# test setSpecies accepts undef
eval {$reportergroup->setSpecies(undef)};
ok((!$@ and not defined $reportergroup->getSpecies()),
   'setSpecies accepts undef');

# test the meta-data for the assoication
$assn = $assns{species};
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
   'species->other() is a valid Bio::MAGE::Association::End'
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
   'species->self() is a valid Bio::MAGE::Association::End'
  );





my $designelementgroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new();
}

# testing superclass DesignElementGroup
isa_ok($designelementgroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);
isa_ok($reportergroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);

