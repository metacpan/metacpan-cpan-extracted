##############################
#
# Experiment.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Experiment.t`

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
use Test::More tests => 183;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Experiment::Experiment') };

use Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster;
use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::BioAssayData::BioAssayData;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Experiment::ExperimentDesign;


# we test the new() method
my $experiment;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experiment = Bio::MAGE::Experiment::Experiment->new();
}
isa_ok($experiment, 'Bio::MAGE::Experiment::Experiment');

# test the package_name class method
is($experiment->package_name(), q[Experiment],
  'package');

# test the class_name class method
is($experiment->class_name(), q[Bio::MAGE::Experiment::Experiment],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experiment = Bio::MAGE::Experiment::Experiment->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($experiment->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$experiment->setIdentifier('1');
is($experiment->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$experiment->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$experiment->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$experiment->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$experiment->setIdentifier(undef)};
ok((!$@ and not defined $experiment->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($experiment->getName(), '2',
  'name new');

# test getter/setter
$experiment->setName('2');
is($experiment->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$experiment->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$experiment->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$experiment->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$experiment->setName(undef)};
ok((!$@ and not defined $experiment->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Experiment::Experiment->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experiment = Bio::MAGE::Experiment::Experiment->new(experimentDesigns => [Bio::MAGE::Experiment::ExperimentDesign->new()],
providers => [Bio::MAGE::AuditAndSecurity::Contact->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
analysisResults => [Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new()],
bioAssays => [Bio::MAGE::BioAssay::BioAssay->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
bioAssayData => [Bio::MAGE::BioAssayData::BioAssayData->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new());
}

my ($end, $assn);


# testing association experimentDesigns
my $experimentdesigns_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentdesigns_assn = Bio::MAGE::Experiment::ExperimentDesign->new();
}


ok((UNIVERSAL::isa($experiment->getExperimentDesigns,'ARRAY')
 and scalar @{$experiment->getExperimentDesigns} == 1
 and UNIVERSAL::isa($experiment->getExperimentDesigns->[0], q[Bio::MAGE::Experiment::ExperimentDesign])),
  'experimentDesigns set in new()');

ok(eq_array($experiment->setExperimentDesigns([$experimentdesigns_assn]), [$experimentdesigns_assn]),
   'setExperimentDesigns returns correct value');

ok((UNIVERSAL::isa($experiment->getExperimentDesigns,'ARRAY')
 and scalar @{$experiment->getExperimentDesigns} == 1
 and $experiment->getExperimentDesigns->[0] == $experimentdesigns_assn),
   'getExperimentDesigns fetches correct value');

is($experiment->addExperimentDesigns($experimentdesigns_assn), 2,
  'addExperimentDesigns returns number of items in list');

ok((UNIVERSAL::isa($experiment->getExperimentDesigns,'ARRAY')
 and scalar @{$experiment->getExperimentDesigns} == 2
 and $experiment->getExperimentDesigns->[0] == $experimentdesigns_assn
 and $experiment->getExperimentDesigns->[1] == $experimentdesigns_assn),
  'addExperimentDesigns adds correct value');

# test setExperimentDesigns throws exception with non-array argument
eval {$experiment->setExperimentDesigns(1)};
ok($@, 'setExperimentDesigns throws exception with non-array argument');

# test setExperimentDesigns throws exception with bad argument array
eval {$experiment->setExperimentDesigns([1])};
ok($@, 'setExperimentDesigns throws exception with bad argument array');

# test addExperimentDesigns throws exception with no arguments
eval {$experiment->addExperimentDesigns()};
ok($@, 'addExperimentDesigns throws exception with no arguments');

# test addExperimentDesigns throws exception with bad argument
eval {$experiment->addExperimentDesigns(1)};
ok($@, 'addExperimentDesigns throws exception with bad array');

# test setExperimentDesigns accepts empty array ref
eval {$experiment->setExperimentDesigns([])};
ok((!$@ and defined $experiment->getExperimentDesigns()
    and UNIVERSAL::isa($experiment->getExperimentDesigns, 'ARRAY')
    and scalar @{$experiment->getExperimentDesigns} == 0),
   'setExperimentDesigns accepts empty array ref');


# test getExperimentDesigns throws exception with argument
eval {$experiment->getExperimentDesigns(1)};
ok($@, 'getExperimentDesigns throws exception with argument');

# test setExperimentDesigns throws exception with no argument
eval {$experiment->setExperimentDesigns()};
ok($@, 'setExperimentDesigns throws exception with no argument');

# test setExperimentDesigns throws exception with too many argument
eval {$experiment->setExperimentDesigns(1,2)};
ok($@, 'setExperimentDesigns throws exception with too many argument');

# test setExperimentDesigns accepts undef
eval {$experiment->setExperimentDesigns(undef)};
ok((!$@ and not defined $experiment->getExperimentDesigns()),
   'setExperimentDesigns accepts undef');

# test the meta-data for the assoication
$assn = $assns{experimentDesigns};
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
   'experimentDesigns->other() is a valid Bio::MAGE::Association::End'
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
   'experimentDesigns->self() is a valid Bio::MAGE::Association::End'
  );



# testing association providers
my $providers_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $providers_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($experiment->getProviders,'ARRAY')
 and scalar @{$experiment->getProviders} == 1
 and UNIVERSAL::isa($experiment->getProviders->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'providers set in new()');

ok(eq_array($experiment->setProviders([$providers_assn]), [$providers_assn]),
   'setProviders returns correct value');

ok((UNIVERSAL::isa($experiment->getProviders,'ARRAY')
 and scalar @{$experiment->getProviders} == 1
 and $experiment->getProviders->[0] == $providers_assn),
   'getProviders fetches correct value');

is($experiment->addProviders($providers_assn), 2,
  'addProviders returns number of items in list');

ok((UNIVERSAL::isa($experiment->getProviders,'ARRAY')
 and scalar @{$experiment->getProviders} == 2
 and $experiment->getProviders->[0] == $providers_assn
 and $experiment->getProviders->[1] == $providers_assn),
  'addProviders adds correct value');

# test setProviders throws exception with non-array argument
eval {$experiment->setProviders(1)};
ok($@, 'setProviders throws exception with non-array argument');

# test setProviders throws exception with bad argument array
eval {$experiment->setProviders([1])};
ok($@, 'setProviders throws exception with bad argument array');

# test addProviders throws exception with no arguments
eval {$experiment->addProviders()};
ok($@, 'addProviders throws exception with no arguments');

# test addProviders throws exception with bad argument
eval {$experiment->addProviders(1)};
ok($@, 'addProviders throws exception with bad array');

# test setProviders accepts empty array ref
eval {$experiment->setProviders([])};
ok((!$@ and defined $experiment->getProviders()
    and UNIVERSAL::isa($experiment->getProviders, 'ARRAY')
    and scalar @{$experiment->getProviders} == 0),
   'setProviders accepts empty array ref');


# test getProviders throws exception with argument
eval {$experiment->getProviders(1)};
ok($@, 'getProviders throws exception with argument');

# test setProviders throws exception with no argument
eval {$experiment->setProviders()};
ok($@, 'setProviders throws exception with no argument');

# test setProviders throws exception with too many argument
eval {$experiment->setProviders(1,2)};
ok($@, 'setProviders throws exception with too many argument');

# test setProviders accepts undef
eval {$experiment->setProviders(undef)};
ok((!$@ and not defined $experiment->getProviders()),
   'setProviders accepts undef');

# test the meta-data for the assoication
$assn = $assns{providers};
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
   'providers->other() is a valid Bio::MAGE::Association::End'
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
   'providers->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($experiment->getAuditTrail,'ARRAY')
 and scalar @{$experiment->getAuditTrail} == 1
 and UNIVERSAL::isa($experiment->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($experiment->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($experiment->getAuditTrail,'ARRAY')
 and scalar @{$experiment->getAuditTrail} == 1
 and $experiment->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($experiment->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($experiment->getAuditTrail,'ARRAY')
 and scalar @{$experiment->getAuditTrail} == 2
 and $experiment->getAuditTrail->[0] == $audittrail_assn
 and $experiment->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$experiment->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$experiment->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$experiment->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$experiment->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$experiment->setAuditTrail([])};
ok((!$@ and defined $experiment->getAuditTrail()
    and UNIVERSAL::isa($experiment->getAuditTrail, 'ARRAY')
    and scalar @{$experiment->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$experiment->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$experiment->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$experiment->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$experiment->setAuditTrail(undef)};
ok((!$@ and not defined $experiment->getAuditTrail()),
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


ok((UNIVERSAL::isa($experiment->getPropertySets,'ARRAY')
 and scalar @{$experiment->getPropertySets} == 1
 and UNIVERSAL::isa($experiment->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($experiment->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($experiment->getPropertySets,'ARRAY')
 and scalar @{$experiment->getPropertySets} == 1
 and $experiment->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($experiment->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($experiment->getPropertySets,'ARRAY')
 and scalar @{$experiment->getPropertySets} == 2
 and $experiment->getPropertySets->[0] == $propertysets_assn
 and $experiment->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$experiment->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$experiment->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$experiment->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$experiment->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$experiment->setPropertySets([])};
ok((!$@ and defined $experiment->getPropertySets()
    and UNIVERSAL::isa($experiment->getPropertySets, 'ARRAY')
    and scalar @{$experiment->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$experiment->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$experiment->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$experiment->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$experiment->setPropertySets(undef)};
ok((!$@ and not defined $experiment->getPropertySets()),
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



# testing association analysisResults
my $analysisresults_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $analysisresults_assn = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new();
}


ok((UNIVERSAL::isa($experiment->getAnalysisResults,'ARRAY')
 and scalar @{$experiment->getAnalysisResults} == 1
 and UNIVERSAL::isa($experiment->getAnalysisResults->[0], q[Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster])),
  'analysisResults set in new()');

ok(eq_array($experiment->setAnalysisResults([$analysisresults_assn]), [$analysisresults_assn]),
   'setAnalysisResults returns correct value');

ok((UNIVERSAL::isa($experiment->getAnalysisResults,'ARRAY')
 and scalar @{$experiment->getAnalysisResults} == 1
 and $experiment->getAnalysisResults->[0] == $analysisresults_assn),
   'getAnalysisResults fetches correct value');

is($experiment->addAnalysisResults($analysisresults_assn), 2,
  'addAnalysisResults returns number of items in list');

ok((UNIVERSAL::isa($experiment->getAnalysisResults,'ARRAY')
 and scalar @{$experiment->getAnalysisResults} == 2
 and $experiment->getAnalysisResults->[0] == $analysisresults_assn
 and $experiment->getAnalysisResults->[1] == $analysisresults_assn),
  'addAnalysisResults adds correct value');

# test setAnalysisResults throws exception with non-array argument
eval {$experiment->setAnalysisResults(1)};
ok($@, 'setAnalysisResults throws exception with non-array argument');

# test setAnalysisResults throws exception with bad argument array
eval {$experiment->setAnalysisResults([1])};
ok($@, 'setAnalysisResults throws exception with bad argument array');

# test addAnalysisResults throws exception with no arguments
eval {$experiment->addAnalysisResults()};
ok($@, 'addAnalysisResults throws exception with no arguments');

# test addAnalysisResults throws exception with bad argument
eval {$experiment->addAnalysisResults(1)};
ok($@, 'addAnalysisResults throws exception with bad array');

# test setAnalysisResults accepts empty array ref
eval {$experiment->setAnalysisResults([])};
ok((!$@ and defined $experiment->getAnalysisResults()
    and UNIVERSAL::isa($experiment->getAnalysisResults, 'ARRAY')
    and scalar @{$experiment->getAnalysisResults} == 0),
   'setAnalysisResults accepts empty array ref');


# test getAnalysisResults throws exception with argument
eval {$experiment->getAnalysisResults(1)};
ok($@, 'getAnalysisResults throws exception with argument');

# test setAnalysisResults throws exception with no argument
eval {$experiment->setAnalysisResults()};
ok($@, 'setAnalysisResults throws exception with no argument');

# test setAnalysisResults throws exception with too many argument
eval {$experiment->setAnalysisResults(1,2)};
ok($@, 'setAnalysisResults throws exception with too many argument');

# test setAnalysisResults accepts undef
eval {$experiment->setAnalysisResults(undef)};
ok((!$@ and not defined $experiment->getAnalysisResults()),
   'setAnalysisResults accepts undef');

# test the meta-data for the assoication
$assn = $assns{analysisResults};
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
   'analysisResults->other() is a valid Bio::MAGE::Association::End'
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
   'analysisResults->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssays
my $bioassays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassays_assn = Bio::MAGE::BioAssay::BioAssay->new();
}


ok((UNIVERSAL::isa($experiment->getBioAssays,'ARRAY')
 and scalar @{$experiment->getBioAssays} == 1
 and UNIVERSAL::isa($experiment->getBioAssays->[0], q[Bio::MAGE::BioAssay::BioAssay])),
  'bioAssays set in new()');

ok(eq_array($experiment->setBioAssays([$bioassays_assn]), [$bioassays_assn]),
   'setBioAssays returns correct value');

ok((UNIVERSAL::isa($experiment->getBioAssays,'ARRAY')
 and scalar @{$experiment->getBioAssays} == 1
 and $experiment->getBioAssays->[0] == $bioassays_assn),
   'getBioAssays fetches correct value');

is($experiment->addBioAssays($bioassays_assn), 2,
  'addBioAssays returns number of items in list');

ok((UNIVERSAL::isa($experiment->getBioAssays,'ARRAY')
 and scalar @{$experiment->getBioAssays} == 2
 and $experiment->getBioAssays->[0] == $bioassays_assn
 and $experiment->getBioAssays->[1] == $bioassays_assn),
  'addBioAssays adds correct value');

# test setBioAssays throws exception with non-array argument
eval {$experiment->setBioAssays(1)};
ok($@, 'setBioAssays throws exception with non-array argument');

# test setBioAssays throws exception with bad argument array
eval {$experiment->setBioAssays([1])};
ok($@, 'setBioAssays throws exception with bad argument array');

# test addBioAssays throws exception with no arguments
eval {$experiment->addBioAssays()};
ok($@, 'addBioAssays throws exception with no arguments');

# test addBioAssays throws exception with bad argument
eval {$experiment->addBioAssays(1)};
ok($@, 'addBioAssays throws exception with bad array');

# test setBioAssays accepts empty array ref
eval {$experiment->setBioAssays([])};
ok((!$@ and defined $experiment->getBioAssays()
    and UNIVERSAL::isa($experiment->getBioAssays, 'ARRAY')
    and scalar @{$experiment->getBioAssays} == 0),
   'setBioAssays accepts empty array ref');


# test getBioAssays throws exception with argument
eval {$experiment->getBioAssays(1)};
ok($@, 'getBioAssays throws exception with argument');

# test setBioAssays throws exception with no argument
eval {$experiment->setBioAssays()};
ok($@, 'setBioAssays throws exception with no argument');

# test setBioAssays throws exception with too many argument
eval {$experiment->setBioAssays(1,2)};
ok($@, 'setBioAssays throws exception with too many argument');

# test setBioAssays accepts undef
eval {$experiment->setBioAssays(undef)};
ok((!$@ and not defined $experiment->getBioAssays()),
   'setBioAssays accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssays};
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
   'bioAssays->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($experiment->getDescriptions,'ARRAY')
 and scalar @{$experiment->getDescriptions} == 1
 and UNIVERSAL::isa($experiment->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($experiment->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($experiment->getDescriptions,'ARRAY')
 and scalar @{$experiment->getDescriptions} == 1
 and $experiment->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($experiment->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($experiment->getDescriptions,'ARRAY')
 and scalar @{$experiment->getDescriptions} == 2
 and $experiment->getDescriptions->[0] == $descriptions_assn
 and $experiment->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$experiment->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$experiment->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$experiment->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$experiment->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$experiment->setDescriptions([])};
ok((!$@ and defined $experiment->getDescriptions()
    and UNIVERSAL::isa($experiment->getDescriptions, 'ARRAY')
    and scalar @{$experiment->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$experiment->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$experiment->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$experiment->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$experiment->setDescriptions(undef)};
ok((!$@ and not defined $experiment->getDescriptions()),
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



# testing association bioAssayData
my $bioassaydata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydata_assn = Bio::MAGE::BioAssayData::BioAssayData->new();
}


ok((UNIVERSAL::isa($experiment->getBioAssayData,'ARRAY')
 and scalar @{$experiment->getBioAssayData} == 1
 and UNIVERSAL::isa($experiment->getBioAssayData->[0], q[Bio::MAGE::BioAssayData::BioAssayData])),
  'bioAssayData set in new()');

ok(eq_array($experiment->setBioAssayData([$bioassaydata_assn]), [$bioassaydata_assn]),
   'setBioAssayData returns correct value');

ok((UNIVERSAL::isa($experiment->getBioAssayData,'ARRAY')
 and scalar @{$experiment->getBioAssayData} == 1
 and $experiment->getBioAssayData->[0] == $bioassaydata_assn),
   'getBioAssayData fetches correct value');

is($experiment->addBioAssayData($bioassaydata_assn), 2,
  'addBioAssayData returns number of items in list');

ok((UNIVERSAL::isa($experiment->getBioAssayData,'ARRAY')
 and scalar @{$experiment->getBioAssayData} == 2
 and $experiment->getBioAssayData->[0] == $bioassaydata_assn
 and $experiment->getBioAssayData->[1] == $bioassaydata_assn),
  'addBioAssayData adds correct value');

# test setBioAssayData throws exception with non-array argument
eval {$experiment->setBioAssayData(1)};
ok($@, 'setBioAssayData throws exception with non-array argument');

# test setBioAssayData throws exception with bad argument array
eval {$experiment->setBioAssayData([1])};
ok($@, 'setBioAssayData throws exception with bad argument array');

# test addBioAssayData throws exception with no arguments
eval {$experiment->addBioAssayData()};
ok($@, 'addBioAssayData throws exception with no arguments');

# test addBioAssayData throws exception with bad argument
eval {$experiment->addBioAssayData(1)};
ok($@, 'addBioAssayData throws exception with bad array');

# test setBioAssayData accepts empty array ref
eval {$experiment->setBioAssayData([])};
ok((!$@ and defined $experiment->getBioAssayData()
    and UNIVERSAL::isa($experiment->getBioAssayData, 'ARRAY')
    and scalar @{$experiment->getBioAssayData} == 0),
   'setBioAssayData accepts empty array ref');


# test getBioAssayData throws exception with argument
eval {$experiment->getBioAssayData(1)};
ok($@, 'getBioAssayData throws exception with argument');

# test setBioAssayData throws exception with no argument
eval {$experiment->setBioAssayData()};
ok($@, 'setBioAssayData throws exception with no argument');

# test setBioAssayData throws exception with too many argument
eval {$experiment->setBioAssayData(1,2)};
ok($@, 'setBioAssayData throws exception with too many argument');

# test setBioAssayData accepts undef
eval {$experiment->setBioAssayData(undef)};
ok((!$@ and not defined $experiment->getBioAssayData()),
   'setBioAssayData accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayData};
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
   'bioAssayData->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayData->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($experiment->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($experiment->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($experiment->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$experiment->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$experiment->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$experiment->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$experiment->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$experiment->setSecurity(undef)};
ok((!$@ and not defined $experiment->getSecurity()),
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





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($experiment, q[Bio::MAGE::Identifiable]);

