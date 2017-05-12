##############################
#
# ReporterCompositeMap.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ReporterCompositeMap.t`

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

BEGIN { use_ok('Bio::MAGE::DesignElement::ReporterCompositeMap') };

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::DesignElement::ReporterPosition;
use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $reportercompositemap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportercompositemap = Bio::MAGE::DesignElement::ReporterCompositeMap->new();
}
isa_ok($reportercompositemap, 'Bio::MAGE::DesignElement::ReporterCompositeMap');

# test the package_name class method
is($reportercompositemap->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($reportercompositemap->class_name(), q[Bio::MAGE::DesignElement::ReporterCompositeMap],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportercompositemap = Bio::MAGE::DesignElement::ReporterCompositeMap->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($reportercompositemap->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$reportercompositemap->setIdentifier('1');
is($reportercompositemap->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$reportercompositemap->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$reportercompositemap->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reportercompositemap->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$reportercompositemap->setIdentifier(undef)};
ok((!$@ and not defined $reportercompositemap->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($reportercompositemap->getName(), '2',
  'name new');

# test getter/setter
$reportercompositemap->setName('2');
is($reportercompositemap->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$reportercompositemap->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$reportercompositemap->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reportercompositemap->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$reportercompositemap->setName(undef)};
ok((!$@ and not defined $reportercompositemap->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::ReporterCompositeMap->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportercompositemap = Bio::MAGE::DesignElement::ReporterCompositeMap->new(reporterPositionSources => [Bio::MAGE::DesignElement::ReporterPosition->new()],
protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
compositeSequence => Bio::MAGE::DesignElement::CompositeSequence->new());
}

my ($end, $assn);


# testing association reporterPositionSources
my $reporterpositionsources_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterpositionsources_assn = Bio::MAGE::DesignElement::ReporterPosition->new();
}


ok((UNIVERSAL::isa($reportercompositemap->getReporterPositionSources,'ARRAY')
 and scalar @{$reportercompositemap->getReporterPositionSources} == 1
 and UNIVERSAL::isa($reportercompositemap->getReporterPositionSources->[0], q[Bio::MAGE::DesignElement::ReporterPosition])),
  'reporterPositionSources set in new()');

ok(eq_array($reportercompositemap->setReporterPositionSources([$reporterpositionsources_assn]), [$reporterpositionsources_assn]),
   'setReporterPositionSources returns correct value');

ok((UNIVERSAL::isa($reportercompositemap->getReporterPositionSources,'ARRAY')
 and scalar @{$reportercompositemap->getReporterPositionSources} == 1
 and $reportercompositemap->getReporterPositionSources->[0] == $reporterpositionsources_assn),
   'getReporterPositionSources fetches correct value');

is($reportercompositemap->addReporterPositionSources($reporterpositionsources_assn), 2,
  'addReporterPositionSources returns number of items in list');

ok((UNIVERSAL::isa($reportercompositemap->getReporterPositionSources,'ARRAY')
 and scalar @{$reportercompositemap->getReporterPositionSources} == 2
 and $reportercompositemap->getReporterPositionSources->[0] == $reporterpositionsources_assn
 and $reportercompositemap->getReporterPositionSources->[1] == $reporterpositionsources_assn),
  'addReporterPositionSources adds correct value');

# test setReporterPositionSources throws exception with non-array argument
eval {$reportercompositemap->setReporterPositionSources(1)};
ok($@, 'setReporterPositionSources throws exception with non-array argument');

# test setReporterPositionSources throws exception with bad argument array
eval {$reportercompositemap->setReporterPositionSources([1])};
ok($@, 'setReporterPositionSources throws exception with bad argument array');

# test addReporterPositionSources throws exception with no arguments
eval {$reportercompositemap->addReporterPositionSources()};
ok($@, 'addReporterPositionSources throws exception with no arguments');

# test addReporterPositionSources throws exception with bad argument
eval {$reportercompositemap->addReporterPositionSources(1)};
ok($@, 'addReporterPositionSources throws exception with bad array');

# test setReporterPositionSources accepts empty array ref
eval {$reportercompositemap->setReporterPositionSources([])};
ok((!$@ and defined $reportercompositemap->getReporterPositionSources()
    and UNIVERSAL::isa($reportercompositemap->getReporterPositionSources, 'ARRAY')
    and scalar @{$reportercompositemap->getReporterPositionSources} == 0),
   'setReporterPositionSources accepts empty array ref');


# test getReporterPositionSources throws exception with argument
eval {$reportercompositemap->getReporterPositionSources(1)};
ok($@, 'getReporterPositionSources throws exception with argument');

# test setReporterPositionSources throws exception with no argument
eval {$reportercompositemap->setReporterPositionSources()};
ok($@, 'setReporterPositionSources throws exception with no argument');

# test setReporterPositionSources throws exception with too many argument
eval {$reportercompositemap->setReporterPositionSources(1,2)};
ok($@, 'setReporterPositionSources throws exception with too many argument');

# test setReporterPositionSources accepts undef
eval {$reportercompositemap->setReporterPositionSources(undef)};
ok((!$@ and not defined $reportercompositemap->getReporterPositionSources()),
   'setReporterPositionSources accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporterPositionSources};
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
   'reporterPositionSources->other() is a valid Bio::MAGE::Association::End'
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
   'reporterPositionSources->self() is a valid Bio::MAGE::Association::End'
  );



# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($reportercompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$reportercompositemap->getProtocolApplications} == 1
 and UNIVERSAL::isa($reportercompositemap->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($reportercompositemap->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($reportercompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$reportercompositemap->getProtocolApplications} == 1
 and $reportercompositemap->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($reportercompositemap->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($reportercompositemap->getProtocolApplications,'ARRAY')
 and scalar @{$reportercompositemap->getProtocolApplications} == 2
 and $reportercompositemap->getProtocolApplications->[0] == $protocolapplications_assn
 and $reportercompositemap->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$reportercompositemap->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$reportercompositemap->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$reportercompositemap->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$reportercompositemap->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$reportercompositemap->setProtocolApplications([])};
ok((!$@ and defined $reportercompositemap->getProtocolApplications()
    and UNIVERSAL::isa($reportercompositemap->getProtocolApplications, 'ARRAY')
    and scalar @{$reportercompositemap->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$reportercompositemap->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$reportercompositemap->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$reportercompositemap->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$reportercompositemap->setProtocolApplications(undef)};
ok((!$@ and not defined $reportercompositemap->getProtocolApplications()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($reportercompositemap->getDescriptions,'ARRAY')
 and scalar @{$reportercompositemap->getDescriptions} == 1
 and UNIVERSAL::isa($reportercompositemap->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($reportercompositemap->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($reportercompositemap->getDescriptions,'ARRAY')
 and scalar @{$reportercompositemap->getDescriptions} == 1
 and $reportercompositemap->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($reportercompositemap->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($reportercompositemap->getDescriptions,'ARRAY')
 and scalar @{$reportercompositemap->getDescriptions} == 2
 and $reportercompositemap->getDescriptions->[0] == $descriptions_assn
 and $reportercompositemap->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$reportercompositemap->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$reportercompositemap->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$reportercompositemap->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$reportercompositemap->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$reportercompositemap->setDescriptions([])};
ok((!$@ and defined $reportercompositemap->getDescriptions()
    and UNIVERSAL::isa($reportercompositemap->getDescriptions, 'ARRAY')
    and scalar @{$reportercompositemap->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$reportercompositemap->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$reportercompositemap->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$reportercompositemap->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$reportercompositemap->setDescriptions(undef)};
ok((!$@ and not defined $reportercompositemap->getDescriptions()),
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


ok((UNIVERSAL::isa($reportercompositemap->getAuditTrail,'ARRAY')
 and scalar @{$reportercompositemap->getAuditTrail} == 1
 and UNIVERSAL::isa($reportercompositemap->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($reportercompositemap->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($reportercompositemap->getAuditTrail,'ARRAY')
 and scalar @{$reportercompositemap->getAuditTrail} == 1
 and $reportercompositemap->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($reportercompositemap->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($reportercompositemap->getAuditTrail,'ARRAY')
 and scalar @{$reportercompositemap->getAuditTrail} == 2
 and $reportercompositemap->getAuditTrail->[0] == $audittrail_assn
 and $reportercompositemap->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$reportercompositemap->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$reportercompositemap->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$reportercompositemap->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$reportercompositemap->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$reportercompositemap->setAuditTrail([])};
ok((!$@ and defined $reportercompositemap->getAuditTrail()
    and UNIVERSAL::isa($reportercompositemap->getAuditTrail, 'ARRAY')
    and scalar @{$reportercompositemap->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$reportercompositemap->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$reportercompositemap->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$reportercompositemap->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$reportercompositemap->setAuditTrail(undef)};
ok((!$@ and not defined $reportercompositemap->getAuditTrail()),
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


isa_ok($reportercompositemap->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($reportercompositemap->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($reportercompositemap->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$reportercompositemap->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$reportercompositemap->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$reportercompositemap->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$reportercompositemap->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$reportercompositemap->setSecurity(undef)};
ok((!$@ and not defined $reportercompositemap->getSecurity()),
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


ok((UNIVERSAL::isa($reportercompositemap->getPropertySets,'ARRAY')
 and scalar @{$reportercompositemap->getPropertySets} == 1
 and UNIVERSAL::isa($reportercompositemap->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($reportercompositemap->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($reportercompositemap->getPropertySets,'ARRAY')
 and scalar @{$reportercompositemap->getPropertySets} == 1
 and $reportercompositemap->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($reportercompositemap->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($reportercompositemap->getPropertySets,'ARRAY')
 and scalar @{$reportercompositemap->getPropertySets} == 2
 and $reportercompositemap->getPropertySets->[0] == $propertysets_assn
 and $reportercompositemap->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$reportercompositemap->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$reportercompositemap->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$reportercompositemap->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$reportercompositemap->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$reportercompositemap->setPropertySets([])};
ok((!$@ and defined $reportercompositemap->getPropertySets()
    and UNIVERSAL::isa($reportercompositemap->getPropertySets, 'ARRAY')
    and scalar @{$reportercompositemap->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$reportercompositemap->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$reportercompositemap->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$reportercompositemap->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$reportercompositemap->setPropertySets(undef)};
ok((!$@ and not defined $reportercompositemap->getPropertySets()),
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



# testing association compositeSequence
my $compositesequence_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequence_assn = Bio::MAGE::DesignElement::CompositeSequence->new();
}


isa_ok($reportercompositemap->getCompositeSequence, q[Bio::MAGE::DesignElement::CompositeSequence]);

is($reportercompositemap->setCompositeSequence($compositesequence_assn), $compositesequence_assn,
  'setCompositeSequence returns value');

ok($reportercompositemap->getCompositeSequence() == $compositesequence_assn,
   'getCompositeSequence fetches correct value');

# test setCompositeSequence throws exception with bad argument
eval {$reportercompositemap->setCompositeSequence(1)};
ok($@, 'setCompositeSequence throws exception with bad argument');


# test getCompositeSequence throws exception with argument
eval {$reportercompositemap->getCompositeSequence(1)};
ok($@, 'getCompositeSequence throws exception with argument');

# test setCompositeSequence throws exception with no argument
eval {$reportercompositemap->setCompositeSequence()};
ok($@, 'setCompositeSequence throws exception with no argument');

# test setCompositeSequence throws exception with too many argument
eval {$reportercompositemap->setCompositeSequence(1,2)};
ok($@, 'setCompositeSequence throws exception with too many argument');

# test setCompositeSequence accepts undef
eval {$reportercompositemap->setCompositeSequence(undef)};
ok((!$@ and not defined $reportercompositemap->getCompositeSequence()),
   'setCompositeSequence accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeSequence};
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
   'compositeSequence->other() is a valid Bio::MAGE::Association::End'
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
   'compositeSequence->self() is a valid Bio::MAGE::Association::End'
  );





my $designelementmap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementmap = Bio::MAGE::BioAssayData::DesignElementMap->new();
}

# testing superclass DesignElementMap
isa_ok($designelementmap, q[Bio::MAGE::BioAssayData::DesignElementMap]);
isa_ok($reportercompositemap, q[Bio::MAGE::BioAssayData::DesignElementMap]);

