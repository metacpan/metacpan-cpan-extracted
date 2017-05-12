##############################
#
# ArrayDesign.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayDesign.t`

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
use Test::More tests => 197;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::ArrayDesign') };

use Bio::MAGE::ArrayDesign::CompositeGroup;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::ArrayDesign::ReporterGroup;
use Bio::MAGE::ArrayDesign::FeatureGroup;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;

use Bio::MAGE::ArrayDesign::PhysicalArrayDesign;

# we test the new() method
my $arraydesign;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraydesign = Bio::MAGE::ArrayDesign::ArrayDesign->new();
}
isa_ok($arraydesign, 'Bio::MAGE::ArrayDesign::ArrayDesign');

# test the package_name class method
is($arraydesign->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($arraydesign->class_name(), q[Bio::MAGE::ArrayDesign::ArrayDesign],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraydesign = Bio::MAGE::ArrayDesign::ArrayDesign->new(identifier => '1',
numberOfFeatures => '2',
version => '3',
name => '4');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($arraydesign->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$arraydesign->setIdentifier('1');
is($arraydesign->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$arraydesign->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraydesign->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraydesign->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$arraydesign->setIdentifier(undef)};
ok((!$@ and not defined $arraydesign->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute numberOfFeatures
#

# test attribute values can be set in new()
is($arraydesign->getNumberOfFeatures(), '2',
  'numberOfFeatures new');

# test getter/setter
$arraydesign->setNumberOfFeatures('2');
is($arraydesign->getNumberOfFeatures(), '2',
  'numberOfFeatures getter/setter');

# test getter throws exception with argument
eval {$arraydesign->getNumberOfFeatures(1)};
ok($@, 'numberOfFeatures getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraydesign->setNumberOfFeatures()};
ok($@, 'numberOfFeatures setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraydesign->setNumberOfFeatures('2', '2')};
ok($@, 'numberOfFeatures setter throws exception with too many argument');

# test setter accepts undef
eval {$arraydesign->setNumberOfFeatures(undef)};
ok((!$@ and not defined $arraydesign->getNumberOfFeatures()),
   'numberOfFeatures setter accepts undef');



#
# testing attribute version
#

# test attribute values can be set in new()
is($arraydesign->getVersion(), '3',
  'version new');

# test getter/setter
$arraydesign->setVersion('3');
is($arraydesign->getVersion(), '3',
  'version getter/setter');

# test getter throws exception with argument
eval {$arraydesign->getVersion(1)};
ok($@, 'version getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraydesign->setVersion()};
ok($@, 'version setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraydesign->setVersion('3', '3')};
ok($@, 'version setter throws exception with too many argument');

# test setter accepts undef
eval {$arraydesign->setVersion(undef)};
ok((!$@ and not defined $arraydesign->getVersion()),
   'version setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($arraydesign->getName(), '4',
  'name new');

# test getter/setter
$arraydesign->setName('4');
is($arraydesign->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$arraydesign->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$arraydesign->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$arraydesign->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$arraydesign->setName(undef)};
ok((!$@ and not defined $arraydesign->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::ArrayDesign->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraydesign = Bio::MAGE::ArrayDesign::ArrayDesign->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
reporterGroups => [Bio::MAGE::ArrayDesign::ReporterGroup->new()],
featureGroups => [Bio::MAGE::ArrayDesign::FeatureGroup->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
compositeGroups => [Bio::MAGE::ArrayDesign::CompositeGroup->new()],
designProviders => [Bio::MAGE::AuditAndSecurity::Contact->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($arraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$arraydesign->getProtocolApplications} == 1
 and UNIVERSAL::isa($arraydesign->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($arraydesign->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($arraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$arraydesign->getProtocolApplications} == 1
 and $arraydesign->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($arraydesign->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getProtocolApplications,'ARRAY')
 and scalar @{$arraydesign->getProtocolApplications} == 2
 and $arraydesign->getProtocolApplications->[0] == $protocolapplications_assn
 and $arraydesign->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$arraydesign->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$arraydesign->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$arraydesign->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$arraydesign->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$arraydesign->setProtocolApplications([])};
ok((!$@ and defined $arraydesign->getProtocolApplications()
    and UNIVERSAL::isa($arraydesign->getProtocolApplications, 'ARRAY')
    and scalar @{$arraydesign->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$arraydesign->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$arraydesign->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$arraydesign->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$arraydesign->setProtocolApplications(undef)};
ok((!$@ and not defined $arraydesign->getProtocolApplications()),
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



# testing association reporterGroups
my $reportergroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportergroups_assn = Bio::MAGE::ArrayDesign::ReporterGroup->new();
}


ok((UNIVERSAL::isa($arraydesign->getReporterGroups,'ARRAY')
 and scalar @{$arraydesign->getReporterGroups} == 1
 and UNIVERSAL::isa($arraydesign->getReporterGroups->[0], q[Bio::MAGE::ArrayDesign::ReporterGroup])),
  'reporterGroups set in new()');

ok(eq_array($arraydesign->setReporterGroups([$reportergroups_assn]), [$reportergroups_assn]),
   'setReporterGroups returns correct value');

ok((UNIVERSAL::isa($arraydesign->getReporterGroups,'ARRAY')
 and scalar @{$arraydesign->getReporterGroups} == 1
 and $arraydesign->getReporterGroups->[0] == $reportergroups_assn),
   'getReporterGroups fetches correct value');

is($arraydesign->addReporterGroups($reportergroups_assn), 2,
  'addReporterGroups returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getReporterGroups,'ARRAY')
 and scalar @{$arraydesign->getReporterGroups} == 2
 and $arraydesign->getReporterGroups->[0] == $reportergroups_assn
 and $arraydesign->getReporterGroups->[1] == $reportergroups_assn),
  'addReporterGroups adds correct value');

# test setReporterGroups throws exception with non-array argument
eval {$arraydesign->setReporterGroups(1)};
ok($@, 'setReporterGroups throws exception with non-array argument');

# test setReporterGroups throws exception with bad argument array
eval {$arraydesign->setReporterGroups([1])};
ok($@, 'setReporterGroups throws exception with bad argument array');

# test addReporterGroups throws exception with no arguments
eval {$arraydesign->addReporterGroups()};
ok($@, 'addReporterGroups throws exception with no arguments');

# test addReporterGroups throws exception with bad argument
eval {$arraydesign->addReporterGroups(1)};
ok($@, 'addReporterGroups throws exception with bad array');

# test setReporterGroups accepts empty array ref
eval {$arraydesign->setReporterGroups([])};
ok((!$@ and defined $arraydesign->getReporterGroups()
    and UNIVERSAL::isa($arraydesign->getReporterGroups, 'ARRAY')
    and scalar @{$arraydesign->getReporterGroups} == 0),
   'setReporterGroups accepts empty array ref');


# test getReporterGroups throws exception with argument
eval {$arraydesign->getReporterGroups(1)};
ok($@, 'getReporterGroups throws exception with argument');

# test setReporterGroups throws exception with no argument
eval {$arraydesign->setReporterGroups()};
ok($@, 'setReporterGroups throws exception with no argument');

# test setReporterGroups throws exception with too many argument
eval {$arraydesign->setReporterGroups(1,2)};
ok($@, 'setReporterGroups throws exception with too many argument');

# test setReporterGroups accepts undef
eval {$arraydesign->setReporterGroups(undef)};
ok((!$@ and not defined $arraydesign->getReporterGroups()),
   'setReporterGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporterGroups};
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
   'reporterGroups->other() is a valid Bio::MAGE::Association::End'
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
   'reporterGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureGroups
my $featuregroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroups_assn = Bio::MAGE::ArrayDesign::FeatureGroup->new();
}


ok((UNIVERSAL::isa($arraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$arraydesign->getFeatureGroups} == 1
 and UNIVERSAL::isa($arraydesign->getFeatureGroups->[0], q[Bio::MAGE::ArrayDesign::FeatureGroup])),
  'featureGroups set in new()');

ok(eq_array($arraydesign->setFeatureGroups([$featuregroups_assn]), [$featuregroups_assn]),
   'setFeatureGroups returns correct value');

ok((UNIVERSAL::isa($arraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$arraydesign->getFeatureGroups} == 1
 and $arraydesign->getFeatureGroups->[0] == $featuregroups_assn),
   'getFeatureGroups fetches correct value');

is($arraydesign->addFeatureGroups($featuregroups_assn), 2,
  'addFeatureGroups returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getFeatureGroups,'ARRAY')
 and scalar @{$arraydesign->getFeatureGroups} == 2
 and $arraydesign->getFeatureGroups->[0] == $featuregroups_assn
 and $arraydesign->getFeatureGroups->[1] == $featuregroups_assn),
  'addFeatureGroups adds correct value');

# test setFeatureGroups throws exception with non-array argument
eval {$arraydesign->setFeatureGroups(1)};
ok($@, 'setFeatureGroups throws exception with non-array argument');

# test setFeatureGroups throws exception with bad argument array
eval {$arraydesign->setFeatureGroups([1])};
ok($@, 'setFeatureGroups throws exception with bad argument array');

# test addFeatureGroups throws exception with no arguments
eval {$arraydesign->addFeatureGroups()};
ok($@, 'addFeatureGroups throws exception with no arguments');

# test addFeatureGroups throws exception with bad argument
eval {$arraydesign->addFeatureGroups(1)};
ok($@, 'addFeatureGroups throws exception with bad array');

# test setFeatureGroups accepts empty array ref
eval {$arraydesign->setFeatureGroups([])};
ok((!$@ and defined $arraydesign->getFeatureGroups()
    and UNIVERSAL::isa($arraydesign->getFeatureGroups, 'ARRAY')
    and scalar @{$arraydesign->getFeatureGroups} == 0),
   'setFeatureGroups accepts empty array ref');


# test getFeatureGroups throws exception with argument
eval {$arraydesign->getFeatureGroups(1)};
ok($@, 'getFeatureGroups throws exception with argument');

# test setFeatureGroups throws exception with no argument
eval {$arraydesign->setFeatureGroups()};
ok($@, 'setFeatureGroups throws exception with no argument');

# test setFeatureGroups throws exception with too many argument
eval {$arraydesign->setFeatureGroups(1,2)};
ok($@, 'setFeatureGroups throws exception with too many argument');

# test setFeatureGroups accepts undef
eval {$arraydesign->setFeatureGroups(undef)};
ok((!$@ and not defined $arraydesign->getFeatureGroups()),
   'setFeatureGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureGroups};
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
   'featureGroups->other() is a valid Bio::MAGE::Association::End'
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
   'featureGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($arraydesign->getDescriptions,'ARRAY')
 and scalar @{$arraydesign->getDescriptions} == 1
 and UNIVERSAL::isa($arraydesign->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($arraydesign->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($arraydesign->getDescriptions,'ARRAY')
 and scalar @{$arraydesign->getDescriptions} == 1
 and $arraydesign->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($arraydesign->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getDescriptions,'ARRAY')
 and scalar @{$arraydesign->getDescriptions} == 2
 and $arraydesign->getDescriptions->[0] == $descriptions_assn
 and $arraydesign->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$arraydesign->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$arraydesign->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$arraydesign->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$arraydesign->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$arraydesign->setDescriptions([])};
ok((!$@ and defined $arraydesign->getDescriptions()
    and UNIVERSAL::isa($arraydesign->getDescriptions, 'ARRAY')
    and scalar @{$arraydesign->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$arraydesign->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$arraydesign->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$arraydesign->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$arraydesign->setDescriptions(undef)};
ok((!$@ and not defined $arraydesign->getDescriptions()),
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


isa_ok($arraydesign->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($arraydesign->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($arraydesign->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$arraydesign->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$arraydesign->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$arraydesign->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$arraydesign->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$arraydesign->setSecurity(undef)};
ok((!$@ and not defined $arraydesign->getSecurity()),
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


ok((UNIVERSAL::isa($arraydesign->getAuditTrail,'ARRAY')
 and scalar @{$arraydesign->getAuditTrail} == 1
 and UNIVERSAL::isa($arraydesign->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($arraydesign->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($arraydesign->getAuditTrail,'ARRAY')
 and scalar @{$arraydesign->getAuditTrail} == 1
 and $arraydesign->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($arraydesign->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getAuditTrail,'ARRAY')
 and scalar @{$arraydesign->getAuditTrail} == 2
 and $arraydesign->getAuditTrail->[0] == $audittrail_assn
 and $arraydesign->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$arraydesign->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$arraydesign->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$arraydesign->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$arraydesign->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$arraydesign->setAuditTrail([])};
ok((!$@ and defined $arraydesign->getAuditTrail()
    and UNIVERSAL::isa($arraydesign->getAuditTrail, 'ARRAY')
    and scalar @{$arraydesign->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$arraydesign->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$arraydesign->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$arraydesign->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$arraydesign->setAuditTrail(undef)};
ok((!$@ and not defined $arraydesign->getAuditTrail()),
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


ok((UNIVERSAL::isa($arraydesign->getPropertySets,'ARRAY')
 and scalar @{$arraydesign->getPropertySets} == 1
 and UNIVERSAL::isa($arraydesign->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($arraydesign->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($arraydesign->getPropertySets,'ARRAY')
 and scalar @{$arraydesign->getPropertySets} == 1
 and $arraydesign->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($arraydesign->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getPropertySets,'ARRAY')
 and scalar @{$arraydesign->getPropertySets} == 2
 and $arraydesign->getPropertySets->[0] == $propertysets_assn
 and $arraydesign->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$arraydesign->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$arraydesign->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$arraydesign->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$arraydesign->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$arraydesign->setPropertySets([])};
ok((!$@ and defined $arraydesign->getPropertySets()
    and UNIVERSAL::isa($arraydesign->getPropertySets, 'ARRAY')
    and scalar @{$arraydesign->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$arraydesign->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$arraydesign->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$arraydesign->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$arraydesign->setPropertySets(undef)};
ok((!$@ and not defined $arraydesign->getPropertySets()),
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



# testing association compositeGroups
my $compositegroups_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositegroups_assn = Bio::MAGE::ArrayDesign::CompositeGroup->new();
}


ok((UNIVERSAL::isa($arraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$arraydesign->getCompositeGroups} == 1
 and UNIVERSAL::isa($arraydesign->getCompositeGroups->[0], q[Bio::MAGE::ArrayDesign::CompositeGroup])),
  'compositeGroups set in new()');

ok(eq_array($arraydesign->setCompositeGroups([$compositegroups_assn]), [$compositegroups_assn]),
   'setCompositeGroups returns correct value');

ok((UNIVERSAL::isa($arraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$arraydesign->getCompositeGroups} == 1
 and $arraydesign->getCompositeGroups->[0] == $compositegroups_assn),
   'getCompositeGroups fetches correct value');

is($arraydesign->addCompositeGroups($compositegroups_assn), 2,
  'addCompositeGroups returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getCompositeGroups,'ARRAY')
 and scalar @{$arraydesign->getCompositeGroups} == 2
 and $arraydesign->getCompositeGroups->[0] == $compositegroups_assn
 and $arraydesign->getCompositeGroups->[1] == $compositegroups_assn),
  'addCompositeGroups adds correct value');

# test setCompositeGroups throws exception with non-array argument
eval {$arraydesign->setCompositeGroups(1)};
ok($@, 'setCompositeGroups throws exception with non-array argument');

# test setCompositeGroups throws exception with bad argument array
eval {$arraydesign->setCompositeGroups([1])};
ok($@, 'setCompositeGroups throws exception with bad argument array');

# test addCompositeGroups throws exception with no arguments
eval {$arraydesign->addCompositeGroups()};
ok($@, 'addCompositeGroups throws exception with no arguments');

# test addCompositeGroups throws exception with bad argument
eval {$arraydesign->addCompositeGroups(1)};
ok($@, 'addCompositeGroups throws exception with bad array');

# test setCompositeGroups accepts empty array ref
eval {$arraydesign->setCompositeGroups([])};
ok((!$@ and defined $arraydesign->getCompositeGroups()
    and UNIVERSAL::isa($arraydesign->getCompositeGroups, 'ARRAY')
    and scalar @{$arraydesign->getCompositeGroups} == 0),
   'setCompositeGroups accepts empty array ref');


# test getCompositeGroups throws exception with argument
eval {$arraydesign->getCompositeGroups(1)};
ok($@, 'getCompositeGroups throws exception with argument');

# test setCompositeGroups throws exception with no argument
eval {$arraydesign->setCompositeGroups()};
ok($@, 'setCompositeGroups throws exception with no argument');

# test setCompositeGroups throws exception with too many argument
eval {$arraydesign->setCompositeGroups(1,2)};
ok($@, 'setCompositeGroups throws exception with too many argument');

# test setCompositeGroups accepts undef
eval {$arraydesign->setCompositeGroups(undef)};
ok((!$@ and not defined $arraydesign->getCompositeGroups()),
   'setCompositeGroups accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeGroups};
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
   'compositeGroups->other() is a valid Bio::MAGE::Association::End'
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
   'compositeGroups->self() is a valid Bio::MAGE::Association::End'
  );



# testing association designProviders
my $designproviders_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designproviders_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($arraydesign->getDesignProviders,'ARRAY')
 and scalar @{$arraydesign->getDesignProviders} == 1
 and UNIVERSAL::isa($arraydesign->getDesignProviders->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'designProviders set in new()');

ok(eq_array($arraydesign->setDesignProviders([$designproviders_assn]), [$designproviders_assn]),
   'setDesignProviders returns correct value');

ok((UNIVERSAL::isa($arraydesign->getDesignProviders,'ARRAY')
 and scalar @{$arraydesign->getDesignProviders} == 1
 and $arraydesign->getDesignProviders->[0] == $designproviders_assn),
   'getDesignProviders fetches correct value');

is($arraydesign->addDesignProviders($designproviders_assn), 2,
  'addDesignProviders returns number of items in list');

ok((UNIVERSAL::isa($arraydesign->getDesignProviders,'ARRAY')
 and scalar @{$arraydesign->getDesignProviders} == 2
 and $arraydesign->getDesignProviders->[0] == $designproviders_assn
 and $arraydesign->getDesignProviders->[1] == $designproviders_assn),
  'addDesignProviders adds correct value');

# test setDesignProviders throws exception with non-array argument
eval {$arraydesign->setDesignProviders(1)};
ok($@, 'setDesignProviders throws exception with non-array argument');

# test setDesignProviders throws exception with bad argument array
eval {$arraydesign->setDesignProviders([1])};
ok($@, 'setDesignProviders throws exception with bad argument array');

# test addDesignProviders throws exception with no arguments
eval {$arraydesign->addDesignProviders()};
ok($@, 'addDesignProviders throws exception with no arguments');

# test addDesignProviders throws exception with bad argument
eval {$arraydesign->addDesignProviders(1)};
ok($@, 'addDesignProviders throws exception with bad array');

# test setDesignProviders accepts empty array ref
eval {$arraydesign->setDesignProviders([])};
ok((!$@ and defined $arraydesign->getDesignProviders()
    and UNIVERSAL::isa($arraydesign->getDesignProviders, 'ARRAY')
    and scalar @{$arraydesign->getDesignProviders} == 0),
   'setDesignProviders accepts empty array ref');


# test getDesignProviders throws exception with argument
eval {$arraydesign->getDesignProviders(1)};
ok($@, 'getDesignProviders throws exception with argument');

# test setDesignProviders throws exception with no argument
eval {$arraydesign->setDesignProviders()};
ok($@, 'setDesignProviders throws exception with no argument');

# test setDesignProviders throws exception with too many argument
eval {$arraydesign->setDesignProviders(1,2)};
ok($@, 'setDesignProviders throws exception with too many argument');

# test setDesignProviders accepts undef
eval {$arraydesign->setDesignProviders(undef)};
ok((!$@ and not defined $arraydesign->getDesignProviders()),
   'setDesignProviders accepts undef');

# test the meta-data for the assoication
$assn = $assns{designProviders};
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
   'designProviders->other() is a valid Bio::MAGE::Association::End'
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
   'designProviders->self() is a valid Bio::MAGE::Association::End'
  );




# create a subclass
my $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new();

# testing subclass PhysicalArrayDesign
isa_ok($physicalarraydesign, q[Bio::MAGE::ArrayDesign::PhysicalArrayDesign]);
isa_ok($physicalarraydesign, q[Bio::MAGE::ArrayDesign::ArrayDesign]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($arraydesign, q[Bio::MAGE::Identifiable]);

