##############################
#
# ExperimentDesign.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ExperimentDesign.t`

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
use Test::More tests => 172;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Experiment::ExperimentDesign') };

use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Experiment::ExperimentalFactor;
use Bio::MAGE::Description::Description;


# we test the new() method
my $experimentdesign;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentdesign = Bio::MAGE::Experiment::ExperimentDesign->new();
}
isa_ok($experimentdesign, 'Bio::MAGE::Experiment::ExperimentDesign');

# test the package_name class method
is($experimentdesign->package_name(), q[Experiment],
  'package');

# test the class_name class method
is($experimentdesign->class_name(), q[Bio::MAGE::Experiment::ExperimentDesign],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentdesign = Bio::MAGE::Experiment::ExperimentDesign->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Experiment::ExperimentDesign->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentdesign = Bio::MAGE::Experiment::ExperimentDesign->new(replicateDescription => Bio::MAGE::Description::Description->new(),
experimentalFactors => [Bio::MAGE::Experiment::ExperimentalFactor->new()],
types => [Bio::MAGE::Description::OntologyEntry->new()],
qualityControlDescription => Bio::MAGE::Description::Description->new(),
normalizationDescription => Bio::MAGE::Description::Description->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
topLevelBioAssays => [Bio::MAGE::BioAssay::BioAssay->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new());
}

my ($end, $assn);


# testing association replicateDescription
my $replicatedescription_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $replicatedescription_assn = Bio::MAGE::Description::Description->new();
}


isa_ok($experimentdesign->getReplicateDescription, q[Bio::MAGE::Description::Description]);

is($experimentdesign->setReplicateDescription($replicatedescription_assn), $replicatedescription_assn,
  'setReplicateDescription returns value');

ok($experimentdesign->getReplicateDescription() == $replicatedescription_assn,
   'getReplicateDescription fetches correct value');

# test setReplicateDescription throws exception with bad argument
eval {$experimentdesign->setReplicateDescription(1)};
ok($@, 'setReplicateDescription throws exception with bad argument');


# test getReplicateDescription throws exception with argument
eval {$experimentdesign->getReplicateDescription(1)};
ok($@, 'getReplicateDescription throws exception with argument');

# test setReplicateDescription throws exception with no argument
eval {$experimentdesign->setReplicateDescription()};
ok($@, 'setReplicateDescription throws exception with no argument');

# test setReplicateDescription throws exception with too many argument
eval {$experimentdesign->setReplicateDescription(1,2)};
ok($@, 'setReplicateDescription throws exception with too many argument');

# test setReplicateDescription accepts undef
eval {$experimentdesign->setReplicateDescription(undef)};
ok((!$@ and not defined $experimentdesign->getReplicateDescription()),
   'setReplicateDescription accepts undef');

# test the meta-data for the assoication
$assn = $assns{replicateDescription};
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
   'replicateDescription->other() is a valid Bio::MAGE::Association::End'
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
   'replicateDescription->self() is a valid Bio::MAGE::Association::End'
  );



# testing association experimentalFactors
my $experimentalfactors_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentalfactors_assn = Bio::MAGE::Experiment::ExperimentalFactor->new();
}


ok((UNIVERSAL::isa($experimentdesign->getExperimentalFactors,'ARRAY')
 and scalar @{$experimentdesign->getExperimentalFactors} == 1
 and UNIVERSAL::isa($experimentdesign->getExperimentalFactors->[0], q[Bio::MAGE::Experiment::ExperimentalFactor])),
  'experimentalFactors set in new()');

ok(eq_array($experimentdesign->setExperimentalFactors([$experimentalfactors_assn]), [$experimentalfactors_assn]),
   'setExperimentalFactors returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getExperimentalFactors,'ARRAY')
 and scalar @{$experimentdesign->getExperimentalFactors} == 1
 and $experimentdesign->getExperimentalFactors->[0] == $experimentalfactors_assn),
   'getExperimentalFactors fetches correct value');

is($experimentdesign->addExperimentalFactors($experimentalfactors_assn), 2,
  'addExperimentalFactors returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getExperimentalFactors,'ARRAY')
 and scalar @{$experimentdesign->getExperimentalFactors} == 2
 and $experimentdesign->getExperimentalFactors->[0] == $experimentalfactors_assn
 and $experimentdesign->getExperimentalFactors->[1] == $experimentalfactors_assn),
  'addExperimentalFactors adds correct value');

# test setExperimentalFactors throws exception with non-array argument
eval {$experimentdesign->setExperimentalFactors(1)};
ok($@, 'setExperimentalFactors throws exception with non-array argument');

# test setExperimentalFactors throws exception with bad argument array
eval {$experimentdesign->setExperimentalFactors([1])};
ok($@, 'setExperimentalFactors throws exception with bad argument array');

# test addExperimentalFactors throws exception with no arguments
eval {$experimentdesign->addExperimentalFactors()};
ok($@, 'addExperimentalFactors throws exception with no arguments');

# test addExperimentalFactors throws exception with bad argument
eval {$experimentdesign->addExperimentalFactors(1)};
ok($@, 'addExperimentalFactors throws exception with bad array');

# test setExperimentalFactors accepts empty array ref
eval {$experimentdesign->setExperimentalFactors([])};
ok((!$@ and defined $experimentdesign->getExperimentalFactors()
    and UNIVERSAL::isa($experimentdesign->getExperimentalFactors, 'ARRAY')
    and scalar @{$experimentdesign->getExperimentalFactors} == 0),
   'setExperimentalFactors accepts empty array ref');


# test getExperimentalFactors throws exception with argument
eval {$experimentdesign->getExperimentalFactors(1)};
ok($@, 'getExperimentalFactors throws exception with argument');

# test setExperimentalFactors throws exception with no argument
eval {$experimentdesign->setExperimentalFactors()};
ok($@, 'setExperimentalFactors throws exception with no argument');

# test setExperimentalFactors throws exception with too many argument
eval {$experimentdesign->setExperimentalFactors(1,2)};
ok($@, 'setExperimentalFactors throws exception with too many argument');

# test setExperimentalFactors accepts undef
eval {$experimentdesign->setExperimentalFactors(undef)};
ok((!$@ and not defined $experimentdesign->getExperimentalFactors()),
   'setExperimentalFactors accepts undef');

# test the meta-data for the assoication
$assn = $assns{experimentalFactors};
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
   'experimentalFactors->other() is a valid Bio::MAGE::Association::End'
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
   'experimentalFactors->self() is a valid Bio::MAGE::Association::End'
  );



# testing association types
my $types_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $types_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($experimentdesign->getTypes,'ARRAY')
 and scalar @{$experimentdesign->getTypes} == 1
 and UNIVERSAL::isa($experimentdesign->getTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'types set in new()');

ok(eq_array($experimentdesign->setTypes([$types_assn]), [$types_assn]),
   'setTypes returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getTypes,'ARRAY')
 and scalar @{$experimentdesign->getTypes} == 1
 and $experimentdesign->getTypes->[0] == $types_assn),
   'getTypes fetches correct value');

is($experimentdesign->addTypes($types_assn), 2,
  'addTypes returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getTypes,'ARRAY')
 and scalar @{$experimentdesign->getTypes} == 2
 and $experimentdesign->getTypes->[0] == $types_assn
 and $experimentdesign->getTypes->[1] == $types_assn),
  'addTypes adds correct value');

# test setTypes throws exception with non-array argument
eval {$experimentdesign->setTypes(1)};
ok($@, 'setTypes throws exception with non-array argument');

# test setTypes throws exception with bad argument array
eval {$experimentdesign->setTypes([1])};
ok($@, 'setTypes throws exception with bad argument array');

# test addTypes throws exception with no arguments
eval {$experimentdesign->addTypes()};
ok($@, 'addTypes throws exception with no arguments');

# test addTypes throws exception with bad argument
eval {$experimentdesign->addTypes(1)};
ok($@, 'addTypes throws exception with bad array');

# test setTypes accepts empty array ref
eval {$experimentdesign->setTypes([])};
ok((!$@ and defined $experimentdesign->getTypes()
    and UNIVERSAL::isa($experimentdesign->getTypes, 'ARRAY')
    and scalar @{$experimentdesign->getTypes} == 0),
   'setTypes accepts empty array ref');


# test getTypes throws exception with argument
eval {$experimentdesign->getTypes(1)};
ok($@, 'getTypes throws exception with argument');

# test setTypes throws exception with no argument
eval {$experimentdesign->setTypes()};
ok($@, 'setTypes throws exception with no argument');

# test setTypes throws exception with too many argument
eval {$experimentdesign->setTypes(1,2)};
ok($@, 'setTypes throws exception with too many argument');

# test setTypes accepts undef
eval {$experimentdesign->setTypes(undef)};
ok((!$@ and not defined $experimentdesign->getTypes()),
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



# testing association qualityControlDescription
my $qualitycontroldescription_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $qualitycontroldescription_assn = Bio::MAGE::Description::Description->new();
}


isa_ok($experimentdesign->getQualityControlDescription, q[Bio::MAGE::Description::Description]);

is($experimentdesign->setQualityControlDescription($qualitycontroldescription_assn), $qualitycontroldescription_assn,
  'setQualityControlDescription returns value');

ok($experimentdesign->getQualityControlDescription() == $qualitycontroldescription_assn,
   'getQualityControlDescription fetches correct value');

# test setQualityControlDescription throws exception with bad argument
eval {$experimentdesign->setQualityControlDescription(1)};
ok($@, 'setQualityControlDescription throws exception with bad argument');


# test getQualityControlDescription throws exception with argument
eval {$experimentdesign->getQualityControlDescription(1)};
ok($@, 'getQualityControlDescription throws exception with argument');

# test setQualityControlDescription throws exception with no argument
eval {$experimentdesign->setQualityControlDescription()};
ok($@, 'setQualityControlDescription throws exception with no argument');

# test setQualityControlDescription throws exception with too many argument
eval {$experimentdesign->setQualityControlDescription(1,2)};
ok($@, 'setQualityControlDescription throws exception with too many argument');

# test setQualityControlDescription accepts undef
eval {$experimentdesign->setQualityControlDescription(undef)};
ok((!$@ and not defined $experimentdesign->getQualityControlDescription()),
   'setQualityControlDescription accepts undef');

# test the meta-data for the assoication
$assn = $assns{qualityControlDescription};
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
   'qualityControlDescription->other() is a valid Bio::MAGE::Association::End'
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
   'qualityControlDescription->self() is a valid Bio::MAGE::Association::End'
  );



# testing association normalizationDescription
my $normalizationdescription_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $normalizationdescription_assn = Bio::MAGE::Description::Description->new();
}


isa_ok($experimentdesign->getNormalizationDescription, q[Bio::MAGE::Description::Description]);

is($experimentdesign->setNormalizationDescription($normalizationdescription_assn), $normalizationdescription_assn,
  'setNormalizationDescription returns value');

ok($experimentdesign->getNormalizationDescription() == $normalizationdescription_assn,
   'getNormalizationDescription fetches correct value');

# test setNormalizationDescription throws exception with bad argument
eval {$experimentdesign->setNormalizationDescription(1)};
ok($@, 'setNormalizationDescription throws exception with bad argument');


# test getNormalizationDescription throws exception with argument
eval {$experimentdesign->getNormalizationDescription(1)};
ok($@, 'getNormalizationDescription throws exception with argument');

# test setNormalizationDescription throws exception with no argument
eval {$experimentdesign->setNormalizationDescription()};
ok($@, 'setNormalizationDescription throws exception with no argument');

# test setNormalizationDescription throws exception with too many argument
eval {$experimentdesign->setNormalizationDescription(1,2)};
ok($@, 'setNormalizationDescription throws exception with too many argument');

# test setNormalizationDescription accepts undef
eval {$experimentdesign->setNormalizationDescription(undef)};
ok((!$@ and not defined $experimentdesign->getNormalizationDescription()),
   'setNormalizationDescription accepts undef');

# test the meta-data for the assoication
$assn = $assns{normalizationDescription};
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
   'normalizationDescription->other() is a valid Bio::MAGE::Association::End'
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
   'normalizationDescription->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($experimentdesign->getAuditTrail,'ARRAY')
 and scalar @{$experimentdesign->getAuditTrail} == 1
 and UNIVERSAL::isa($experimentdesign->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($experimentdesign->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getAuditTrail,'ARRAY')
 and scalar @{$experimentdesign->getAuditTrail} == 1
 and $experimentdesign->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($experimentdesign->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getAuditTrail,'ARRAY')
 and scalar @{$experimentdesign->getAuditTrail} == 2
 and $experimentdesign->getAuditTrail->[0] == $audittrail_assn
 and $experimentdesign->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$experimentdesign->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$experimentdesign->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$experimentdesign->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$experimentdesign->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$experimentdesign->setAuditTrail([])};
ok((!$@ and defined $experimentdesign->getAuditTrail()
    and UNIVERSAL::isa($experimentdesign->getAuditTrail, 'ARRAY')
    and scalar @{$experimentdesign->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$experimentdesign->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$experimentdesign->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$experimentdesign->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$experimentdesign->setAuditTrail(undef)};
ok((!$@ and not defined $experimentdesign->getAuditTrail()),
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


ok((UNIVERSAL::isa($experimentdesign->getPropertySets,'ARRAY')
 and scalar @{$experimentdesign->getPropertySets} == 1
 and UNIVERSAL::isa($experimentdesign->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($experimentdesign->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getPropertySets,'ARRAY')
 and scalar @{$experimentdesign->getPropertySets} == 1
 and $experimentdesign->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($experimentdesign->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getPropertySets,'ARRAY')
 and scalar @{$experimentdesign->getPropertySets} == 2
 and $experimentdesign->getPropertySets->[0] == $propertysets_assn
 and $experimentdesign->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$experimentdesign->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$experimentdesign->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$experimentdesign->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$experimentdesign->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$experimentdesign->setPropertySets([])};
ok((!$@ and defined $experimentdesign->getPropertySets()
    and UNIVERSAL::isa($experimentdesign->getPropertySets, 'ARRAY')
    and scalar @{$experimentdesign->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$experimentdesign->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$experimentdesign->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$experimentdesign->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$experimentdesign->setPropertySets(undef)};
ok((!$@ and not defined $experimentdesign->getPropertySets()),
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



# testing association topLevelBioAssays
my $toplevelbioassays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $toplevelbioassays_assn = Bio::MAGE::BioAssay::BioAssay->new();
}


ok((UNIVERSAL::isa($experimentdesign->getTopLevelBioAssays,'ARRAY')
 and scalar @{$experimentdesign->getTopLevelBioAssays} == 1
 and UNIVERSAL::isa($experimentdesign->getTopLevelBioAssays->[0], q[Bio::MAGE::BioAssay::BioAssay])),
  'topLevelBioAssays set in new()');

ok(eq_array($experimentdesign->setTopLevelBioAssays([$toplevelbioassays_assn]), [$toplevelbioassays_assn]),
   'setTopLevelBioAssays returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getTopLevelBioAssays,'ARRAY')
 and scalar @{$experimentdesign->getTopLevelBioAssays} == 1
 and $experimentdesign->getTopLevelBioAssays->[0] == $toplevelbioassays_assn),
   'getTopLevelBioAssays fetches correct value');

is($experimentdesign->addTopLevelBioAssays($toplevelbioassays_assn), 2,
  'addTopLevelBioAssays returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getTopLevelBioAssays,'ARRAY')
 and scalar @{$experimentdesign->getTopLevelBioAssays} == 2
 and $experimentdesign->getTopLevelBioAssays->[0] == $toplevelbioassays_assn
 and $experimentdesign->getTopLevelBioAssays->[1] == $toplevelbioassays_assn),
  'addTopLevelBioAssays adds correct value');

# test setTopLevelBioAssays throws exception with non-array argument
eval {$experimentdesign->setTopLevelBioAssays(1)};
ok($@, 'setTopLevelBioAssays throws exception with non-array argument');

# test setTopLevelBioAssays throws exception with bad argument array
eval {$experimentdesign->setTopLevelBioAssays([1])};
ok($@, 'setTopLevelBioAssays throws exception with bad argument array');

# test addTopLevelBioAssays throws exception with no arguments
eval {$experimentdesign->addTopLevelBioAssays()};
ok($@, 'addTopLevelBioAssays throws exception with no arguments');

# test addTopLevelBioAssays throws exception with bad argument
eval {$experimentdesign->addTopLevelBioAssays(1)};
ok($@, 'addTopLevelBioAssays throws exception with bad array');

# test setTopLevelBioAssays accepts empty array ref
eval {$experimentdesign->setTopLevelBioAssays([])};
ok((!$@ and defined $experimentdesign->getTopLevelBioAssays()
    and UNIVERSAL::isa($experimentdesign->getTopLevelBioAssays, 'ARRAY')
    and scalar @{$experimentdesign->getTopLevelBioAssays} == 0),
   'setTopLevelBioAssays accepts empty array ref');


# test getTopLevelBioAssays throws exception with argument
eval {$experimentdesign->getTopLevelBioAssays(1)};
ok($@, 'getTopLevelBioAssays throws exception with argument');

# test setTopLevelBioAssays throws exception with no argument
eval {$experimentdesign->setTopLevelBioAssays()};
ok($@, 'setTopLevelBioAssays throws exception with no argument');

# test setTopLevelBioAssays throws exception with too many argument
eval {$experimentdesign->setTopLevelBioAssays(1,2)};
ok($@, 'setTopLevelBioAssays throws exception with too many argument');

# test setTopLevelBioAssays accepts undef
eval {$experimentdesign->setTopLevelBioAssays(undef)};
ok((!$@ and not defined $experimentdesign->getTopLevelBioAssays()),
   'setTopLevelBioAssays accepts undef');

# test the meta-data for the assoication
$assn = $assns{topLevelBioAssays};
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
   'topLevelBioAssays->other() is a valid Bio::MAGE::Association::End'
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
   'topLevelBioAssays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($experimentdesign->getDescriptions,'ARRAY')
 and scalar @{$experimentdesign->getDescriptions} == 1
 and UNIVERSAL::isa($experimentdesign->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($experimentdesign->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($experimentdesign->getDescriptions,'ARRAY')
 and scalar @{$experimentdesign->getDescriptions} == 1
 and $experimentdesign->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($experimentdesign->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($experimentdesign->getDescriptions,'ARRAY')
 and scalar @{$experimentdesign->getDescriptions} == 2
 and $experimentdesign->getDescriptions->[0] == $descriptions_assn
 and $experimentdesign->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$experimentdesign->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$experimentdesign->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$experimentdesign->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$experimentdesign->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$experimentdesign->setDescriptions([])};
ok((!$@ and defined $experimentdesign->getDescriptions()
    and UNIVERSAL::isa($experimentdesign->getDescriptions, 'ARRAY')
    and scalar @{$experimentdesign->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$experimentdesign->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$experimentdesign->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$experimentdesign->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$experimentdesign->setDescriptions(undef)};
ok((!$@ and not defined $experimentdesign->getDescriptions()),
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


isa_ok($experimentdesign->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($experimentdesign->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($experimentdesign->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$experimentdesign->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$experimentdesign->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$experimentdesign->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$experimentdesign->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$experimentdesign->setSecurity(undef)};
ok((!$@ and not defined $experimentdesign->getSecurity()),
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





my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($experimentdesign, q[Bio::MAGE::Describable]);

