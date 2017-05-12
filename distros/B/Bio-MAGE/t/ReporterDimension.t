##############################
#
# ReporterDimension.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ReporterDimension.t`

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
use Test::More tests => 107;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::ReporterDimension') };

use Bio::MAGE::DesignElement::Reporter;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $reporterdimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterdimension = Bio::MAGE::BioAssayData::ReporterDimension->new();
}
isa_ok($reporterdimension, 'Bio::MAGE::BioAssayData::ReporterDimension');

# test the package_name class method
is($reporterdimension->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($reporterdimension->class_name(), q[Bio::MAGE::BioAssayData::ReporterDimension],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterdimension = Bio::MAGE::BioAssayData::ReporterDimension->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($reporterdimension->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$reporterdimension->setIdentifier('1');
is($reporterdimension->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$reporterdimension->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporterdimension->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporterdimension->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$reporterdimension->setIdentifier(undef)};
ok((!$@ and not defined $reporterdimension->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($reporterdimension->getName(), '2',
  'name new');

# test getter/setter
$reporterdimension->setName('2');
is($reporterdimension->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$reporterdimension->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporterdimension->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporterdimension->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$reporterdimension->setName(undef)};
ok((!$@ and not defined $reporterdimension->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::ReporterDimension->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterdimension = Bio::MAGE::BioAssayData::ReporterDimension->new(reporters => [Bio::MAGE::DesignElement::Reporter->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association reporters
my $reporters_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporters_assn = Bio::MAGE::DesignElement::Reporter->new();
}


ok((UNIVERSAL::isa($reporterdimension->getReporters,'ARRAY')
 and scalar @{$reporterdimension->getReporters} == 1
 and UNIVERSAL::isa($reporterdimension->getReporters->[0], q[Bio::MAGE::DesignElement::Reporter])),
  'reporters set in new()');

ok(eq_array($reporterdimension->setReporters([$reporters_assn]), [$reporters_assn]),
   'setReporters returns correct value');

ok((UNIVERSAL::isa($reporterdimension->getReporters,'ARRAY')
 and scalar @{$reporterdimension->getReporters} == 1
 and $reporterdimension->getReporters->[0] == $reporters_assn),
   'getReporters fetches correct value');

is($reporterdimension->addReporters($reporters_assn), 2,
  'addReporters returns number of items in list');

ok((UNIVERSAL::isa($reporterdimension->getReporters,'ARRAY')
 and scalar @{$reporterdimension->getReporters} == 2
 and $reporterdimension->getReporters->[0] == $reporters_assn
 and $reporterdimension->getReporters->[1] == $reporters_assn),
  'addReporters adds correct value');

# test setReporters throws exception with non-array argument
eval {$reporterdimension->setReporters(1)};
ok($@, 'setReporters throws exception with non-array argument');

# test setReporters throws exception with bad argument array
eval {$reporterdimension->setReporters([1])};
ok($@, 'setReporters throws exception with bad argument array');

# test addReporters throws exception with no arguments
eval {$reporterdimension->addReporters()};
ok($@, 'addReporters throws exception with no arguments');

# test addReporters throws exception with bad argument
eval {$reporterdimension->addReporters(1)};
ok($@, 'addReporters throws exception with bad array');

# test setReporters accepts empty array ref
eval {$reporterdimension->setReporters([])};
ok((!$@ and defined $reporterdimension->getReporters()
    and UNIVERSAL::isa($reporterdimension->getReporters, 'ARRAY')
    and scalar @{$reporterdimension->getReporters} == 0),
   'setReporters accepts empty array ref');


# test getReporters throws exception with argument
eval {$reporterdimension->getReporters(1)};
ok($@, 'getReporters throws exception with argument');

# test setReporters throws exception with no argument
eval {$reporterdimension->setReporters()};
ok($@, 'setReporters throws exception with no argument');

# test setReporters throws exception with too many argument
eval {$reporterdimension->setReporters(1,2)};
ok($@, 'setReporters throws exception with too many argument');

# test setReporters accepts undef
eval {$reporterdimension->setReporters(undef)};
ok((!$@ and not defined $reporterdimension->getReporters()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($reporterdimension->getDescriptions,'ARRAY')
 and scalar @{$reporterdimension->getDescriptions} == 1
 and UNIVERSAL::isa($reporterdimension->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($reporterdimension->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($reporterdimension->getDescriptions,'ARRAY')
 and scalar @{$reporterdimension->getDescriptions} == 1
 and $reporterdimension->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($reporterdimension->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($reporterdimension->getDescriptions,'ARRAY')
 and scalar @{$reporterdimension->getDescriptions} == 2
 and $reporterdimension->getDescriptions->[0] == $descriptions_assn
 and $reporterdimension->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$reporterdimension->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$reporterdimension->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$reporterdimension->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$reporterdimension->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$reporterdimension->setDescriptions([])};
ok((!$@ and defined $reporterdimension->getDescriptions()
    and UNIVERSAL::isa($reporterdimension->getDescriptions, 'ARRAY')
    and scalar @{$reporterdimension->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$reporterdimension->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$reporterdimension->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$reporterdimension->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$reporterdimension->setDescriptions(undef)};
ok((!$@ and not defined $reporterdimension->getDescriptions()),
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


ok((UNIVERSAL::isa($reporterdimension->getAuditTrail,'ARRAY')
 and scalar @{$reporterdimension->getAuditTrail} == 1
 and UNIVERSAL::isa($reporterdimension->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($reporterdimension->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($reporterdimension->getAuditTrail,'ARRAY')
 and scalar @{$reporterdimension->getAuditTrail} == 1
 and $reporterdimension->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($reporterdimension->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($reporterdimension->getAuditTrail,'ARRAY')
 and scalar @{$reporterdimension->getAuditTrail} == 2
 and $reporterdimension->getAuditTrail->[0] == $audittrail_assn
 and $reporterdimension->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$reporterdimension->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$reporterdimension->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$reporterdimension->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$reporterdimension->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$reporterdimension->setAuditTrail([])};
ok((!$@ and defined $reporterdimension->getAuditTrail()
    and UNIVERSAL::isa($reporterdimension->getAuditTrail, 'ARRAY')
    and scalar @{$reporterdimension->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$reporterdimension->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$reporterdimension->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$reporterdimension->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$reporterdimension->setAuditTrail(undef)};
ok((!$@ and not defined $reporterdimension->getAuditTrail()),
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


isa_ok($reporterdimension->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($reporterdimension->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($reporterdimension->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$reporterdimension->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$reporterdimension->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$reporterdimension->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$reporterdimension->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$reporterdimension->setSecurity(undef)};
ok((!$@ and not defined $reporterdimension->getSecurity()),
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


ok((UNIVERSAL::isa($reporterdimension->getPropertySets,'ARRAY')
 and scalar @{$reporterdimension->getPropertySets} == 1
 and UNIVERSAL::isa($reporterdimension->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($reporterdimension->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($reporterdimension->getPropertySets,'ARRAY')
 and scalar @{$reporterdimension->getPropertySets} == 1
 and $reporterdimension->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($reporterdimension->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($reporterdimension->getPropertySets,'ARRAY')
 and scalar @{$reporterdimension->getPropertySets} == 2
 and $reporterdimension->getPropertySets->[0] == $propertysets_assn
 and $reporterdimension->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$reporterdimension->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$reporterdimension->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$reporterdimension->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$reporterdimension->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$reporterdimension->setPropertySets([])};
ok((!$@ and defined $reporterdimension->getPropertySets()
    and UNIVERSAL::isa($reporterdimension->getPropertySets, 'ARRAY')
    and scalar @{$reporterdimension->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$reporterdimension->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$reporterdimension->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$reporterdimension->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$reporterdimension->setPropertySets(undef)};
ok((!$@ and not defined $reporterdimension->getPropertySets()),
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





my $designelementdimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementdimension = Bio::MAGE::BioAssayData::DesignElementDimension->new();
}

# testing superclass DesignElementDimension
isa_ok($designelementdimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);
isa_ok($reporterdimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

