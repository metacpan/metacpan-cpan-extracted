##############################
#
# FeatureGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureGroup.t`

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
use Test::More tests => 196;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::FeatureGroup') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $featuregroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new();
}
isa_ok($featuregroup, 'Bio::MAGE::ArrayDesign::FeatureGroup');

# test the package_name class method
is($featuregroup->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($featuregroup->class_name(), q[Bio::MAGE::ArrayDesign::FeatureGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new(featureLength => '1',
featureWidth => '2',
identifier => '3',
featureHeight => '4',
name => '5');
}


#
# testing attribute featureLength
#

# test attribute values can be set in new()
is($featuregroup->getFeatureLength(), '1',
  'featureLength new');

# test getter/setter
$featuregroup->setFeatureLength('1');
is($featuregroup->getFeatureLength(), '1',
  'featureLength getter/setter');

# test getter throws exception with argument
eval {$featuregroup->getFeatureLength(1)};
ok($@, 'featureLength getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuregroup->setFeatureLength()};
ok($@, 'featureLength setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuregroup->setFeatureLength('1', '1')};
ok($@, 'featureLength setter throws exception with too many argument');

# test setter accepts undef
eval {$featuregroup->setFeatureLength(undef)};
ok((!$@ and not defined $featuregroup->getFeatureLength()),
   'featureLength setter accepts undef');



#
# testing attribute featureWidth
#

# test attribute values can be set in new()
is($featuregroup->getFeatureWidth(), '2',
  'featureWidth new');

# test getter/setter
$featuregroup->setFeatureWidth('2');
is($featuregroup->getFeatureWidth(), '2',
  'featureWidth getter/setter');

# test getter throws exception with argument
eval {$featuregroup->getFeatureWidth(1)};
ok($@, 'featureWidth getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuregroup->setFeatureWidth()};
ok($@, 'featureWidth setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuregroup->setFeatureWidth('2', '2')};
ok($@, 'featureWidth setter throws exception with too many argument');

# test setter accepts undef
eval {$featuregroup->setFeatureWidth(undef)};
ok((!$@ and not defined $featuregroup->getFeatureWidth()),
   'featureWidth setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($featuregroup->getIdentifier(), '3',
  'identifier new');

# test getter/setter
$featuregroup->setIdentifier('3');
is($featuregroup->getIdentifier(), '3',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$featuregroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuregroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuregroup->setIdentifier('3', '3')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$featuregroup->setIdentifier(undef)};
ok((!$@ and not defined $featuregroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute featureHeight
#

# test attribute values can be set in new()
is($featuregroup->getFeatureHeight(), '4',
  'featureHeight new');

# test getter/setter
$featuregroup->setFeatureHeight('4');
is($featuregroup->getFeatureHeight(), '4',
  'featureHeight getter/setter');

# test getter throws exception with argument
eval {$featuregroup->getFeatureHeight(1)};
ok($@, 'featureHeight getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuregroup->setFeatureHeight()};
ok($@, 'featureHeight setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuregroup->setFeatureHeight('4', '4')};
ok($@, 'featureHeight setter throws exception with too many argument');

# test setter accepts undef
eval {$featuregroup->setFeatureHeight(undef)};
ok((!$@ and not defined $featuregroup->getFeatureHeight()),
   'featureHeight setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($featuregroup->getName(), '5',
  'name new');

# test getter/setter
$featuregroup->setName('5');
is($featuregroup->getName(), '5',
  'name getter/setter');

# test getter throws exception with argument
eval {$featuregroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuregroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuregroup->setName('5', '5')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$featuregroup->setName(undef)};
ok((!$@ and not defined $featuregroup->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::FeatureGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new(types => [Bio::MAGE::Description::OntologyEntry->new()],
features => [Bio::MAGE::DesignElement::Feature->new()],
featureShape => Bio::MAGE::Description::OntologyEntry->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
technologyType => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
species => Bio::MAGE::Description::OntologyEntry->new(),
distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new());
}

my ($end, $assn);


# testing association types
my $types_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $types_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($featuregroup->getTypes,'ARRAY')
 and scalar @{$featuregroup->getTypes} == 1
 and UNIVERSAL::isa($featuregroup->getTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'types set in new()');

ok(eq_array($featuregroup->setTypes([$types_assn]), [$types_assn]),
   'setTypes returns correct value');

ok((UNIVERSAL::isa($featuregroup->getTypes,'ARRAY')
 and scalar @{$featuregroup->getTypes} == 1
 and $featuregroup->getTypes->[0] == $types_assn),
   'getTypes fetches correct value');

is($featuregroup->addTypes($types_assn), 2,
  'addTypes returns number of items in list');

ok((UNIVERSAL::isa($featuregroup->getTypes,'ARRAY')
 and scalar @{$featuregroup->getTypes} == 2
 and $featuregroup->getTypes->[0] == $types_assn
 and $featuregroup->getTypes->[1] == $types_assn),
  'addTypes adds correct value');

# test setTypes throws exception with non-array argument
eval {$featuregroup->setTypes(1)};
ok($@, 'setTypes throws exception with non-array argument');

# test setTypes throws exception with bad argument array
eval {$featuregroup->setTypes([1])};
ok($@, 'setTypes throws exception with bad argument array');

# test addTypes throws exception with no arguments
eval {$featuregroup->addTypes()};
ok($@, 'addTypes throws exception with no arguments');

# test addTypes throws exception with bad argument
eval {$featuregroup->addTypes(1)};
ok($@, 'addTypes throws exception with bad array');

# test setTypes accepts empty array ref
eval {$featuregroup->setTypes([])};
ok((!$@ and defined $featuregroup->getTypes()
    and UNIVERSAL::isa($featuregroup->getTypes, 'ARRAY')
    and scalar @{$featuregroup->getTypes} == 0),
   'setTypes accepts empty array ref');


# test getTypes throws exception with argument
eval {$featuregroup->getTypes(1)};
ok($@, 'getTypes throws exception with argument');

# test setTypes throws exception with no argument
eval {$featuregroup->setTypes()};
ok($@, 'setTypes throws exception with no argument');

# test setTypes throws exception with too many argument
eval {$featuregroup->setTypes(1,2)};
ok($@, 'setTypes throws exception with too many argument');

# test setTypes accepts undef
eval {$featuregroup->setTypes(undef)};
ok((!$@ and not defined $featuregroup->getTypes()),
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



# testing association features
my $features_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $features_assn = Bio::MAGE::DesignElement::Feature->new();
}


ok((UNIVERSAL::isa($featuregroup->getFeatures,'ARRAY')
 and scalar @{$featuregroup->getFeatures} == 1
 and UNIVERSAL::isa($featuregroup->getFeatures->[0], q[Bio::MAGE::DesignElement::Feature])),
  'features set in new()');

ok(eq_array($featuregroup->setFeatures([$features_assn]), [$features_assn]),
   'setFeatures returns correct value');

ok((UNIVERSAL::isa($featuregroup->getFeatures,'ARRAY')
 and scalar @{$featuregroup->getFeatures} == 1
 and $featuregroup->getFeatures->[0] == $features_assn),
   'getFeatures fetches correct value');

is($featuregroup->addFeatures($features_assn), 2,
  'addFeatures returns number of items in list');

ok((UNIVERSAL::isa($featuregroup->getFeatures,'ARRAY')
 and scalar @{$featuregroup->getFeatures} == 2
 and $featuregroup->getFeatures->[0] == $features_assn
 and $featuregroup->getFeatures->[1] == $features_assn),
  'addFeatures adds correct value');

# test setFeatures throws exception with non-array argument
eval {$featuregroup->setFeatures(1)};
ok($@, 'setFeatures throws exception with non-array argument');

# test setFeatures throws exception with bad argument array
eval {$featuregroup->setFeatures([1])};
ok($@, 'setFeatures throws exception with bad argument array');

# test addFeatures throws exception with no arguments
eval {$featuregroup->addFeatures()};
ok($@, 'addFeatures throws exception with no arguments');

# test addFeatures throws exception with bad argument
eval {$featuregroup->addFeatures(1)};
ok($@, 'addFeatures throws exception with bad array');

# test setFeatures accepts empty array ref
eval {$featuregroup->setFeatures([])};
ok((!$@ and defined $featuregroup->getFeatures()
    and UNIVERSAL::isa($featuregroup->getFeatures, 'ARRAY')
    and scalar @{$featuregroup->getFeatures} == 0),
   'setFeatures accepts empty array ref');


# test getFeatures throws exception with argument
eval {$featuregroup->getFeatures(1)};
ok($@, 'getFeatures throws exception with argument');

# test setFeatures throws exception with no argument
eval {$featuregroup->setFeatures()};
ok($@, 'setFeatures throws exception with no argument');

# test setFeatures throws exception with too many argument
eval {$featuregroup->setFeatures(1,2)};
ok($@, 'setFeatures throws exception with too many argument');

# test setFeatures accepts undef
eval {$featuregroup->setFeatures(undef)};
ok((!$@ and not defined $featuregroup->getFeatures()),
   'setFeatures accepts undef');

# test the meta-data for the assoication
$assn = $assns{features};
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
   'features->other() is a valid Bio::MAGE::Association::End'
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
   'features->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureShape
my $featureshape_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureshape_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($featuregroup->getFeatureShape, q[Bio::MAGE::Description::OntologyEntry]);

is($featuregroup->setFeatureShape($featureshape_assn), $featureshape_assn,
  'setFeatureShape returns value');

ok($featuregroup->getFeatureShape() == $featureshape_assn,
   'getFeatureShape fetches correct value');

# test setFeatureShape throws exception with bad argument
eval {$featuregroup->setFeatureShape(1)};
ok($@, 'setFeatureShape throws exception with bad argument');


# test getFeatureShape throws exception with argument
eval {$featuregroup->getFeatureShape(1)};
ok($@, 'getFeatureShape throws exception with argument');

# test setFeatureShape throws exception with no argument
eval {$featuregroup->setFeatureShape()};
ok($@, 'setFeatureShape throws exception with no argument');

# test setFeatureShape throws exception with too many argument
eval {$featuregroup->setFeatureShape(1,2)};
ok($@, 'setFeatureShape throws exception with too many argument');

# test setFeatureShape accepts undef
eval {$featuregroup->setFeatureShape(undef)};
ok((!$@ and not defined $featuregroup->getFeatureShape()),
   'setFeatureShape accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureShape};
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
   'featureShape->other() is a valid Bio::MAGE::Association::End'
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
   'featureShape->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($featuregroup->getAuditTrail,'ARRAY')
 and scalar @{$featuregroup->getAuditTrail} == 1
 and UNIVERSAL::isa($featuregroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($featuregroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($featuregroup->getAuditTrail,'ARRAY')
 and scalar @{$featuregroup->getAuditTrail} == 1
 and $featuregroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($featuregroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($featuregroup->getAuditTrail,'ARRAY')
 and scalar @{$featuregroup->getAuditTrail} == 2
 and $featuregroup->getAuditTrail->[0] == $audittrail_assn
 and $featuregroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$featuregroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$featuregroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$featuregroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$featuregroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$featuregroup->setAuditTrail([])};
ok((!$@ and defined $featuregroup->getAuditTrail()
    and UNIVERSAL::isa($featuregroup->getAuditTrail, 'ARRAY')
    and scalar @{$featuregroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$featuregroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$featuregroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$featuregroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$featuregroup->setAuditTrail(undef)};
ok((!$@ and not defined $featuregroup->getAuditTrail()),
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



# testing association technologyType
my $technologytype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $technologytype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($featuregroup->getTechnologyType, q[Bio::MAGE::Description::OntologyEntry]);

is($featuregroup->setTechnologyType($technologytype_assn), $technologytype_assn,
  'setTechnologyType returns value');

ok($featuregroup->getTechnologyType() == $technologytype_assn,
   'getTechnologyType fetches correct value');

# test setTechnologyType throws exception with bad argument
eval {$featuregroup->setTechnologyType(1)};
ok($@, 'setTechnologyType throws exception with bad argument');


# test getTechnologyType throws exception with argument
eval {$featuregroup->getTechnologyType(1)};
ok($@, 'getTechnologyType throws exception with argument');

# test setTechnologyType throws exception with no argument
eval {$featuregroup->setTechnologyType()};
ok($@, 'setTechnologyType throws exception with no argument');

# test setTechnologyType throws exception with too many argument
eval {$featuregroup->setTechnologyType(1,2)};
ok($@, 'setTechnologyType throws exception with too many argument');

# test setTechnologyType accepts undef
eval {$featuregroup->setTechnologyType(undef)};
ok((!$@ and not defined $featuregroup->getTechnologyType()),
   'setTechnologyType accepts undef');

# test the meta-data for the assoication
$assn = $assns{technologyType};
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
   'technologyType->other() is a valid Bio::MAGE::Association::End'
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
   'technologyType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($featuregroup->getPropertySets,'ARRAY')
 and scalar @{$featuregroup->getPropertySets} == 1
 and UNIVERSAL::isa($featuregroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featuregroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featuregroup->getPropertySets,'ARRAY')
 and scalar @{$featuregroup->getPropertySets} == 1
 and $featuregroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featuregroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featuregroup->getPropertySets,'ARRAY')
 and scalar @{$featuregroup->getPropertySets} == 2
 and $featuregroup->getPropertySets->[0] == $propertysets_assn
 and $featuregroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featuregroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featuregroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featuregroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featuregroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featuregroup->setPropertySets([])};
ok((!$@ and defined $featuregroup->getPropertySets()
    and UNIVERSAL::isa($featuregroup->getPropertySets, 'ARRAY')
    and scalar @{$featuregroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featuregroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featuregroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featuregroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featuregroup->setPropertySets(undef)};
ok((!$@ and not defined $featuregroup->getPropertySets()),
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


isa_ok($featuregroup->getSpecies, q[Bio::MAGE::Description::OntologyEntry]);

is($featuregroup->setSpecies($species_assn), $species_assn,
  'setSpecies returns value');

ok($featuregroup->getSpecies() == $species_assn,
   'getSpecies fetches correct value');

# test setSpecies throws exception with bad argument
eval {$featuregroup->setSpecies(1)};
ok($@, 'setSpecies throws exception with bad argument');


# test getSpecies throws exception with argument
eval {$featuregroup->getSpecies(1)};
ok($@, 'getSpecies throws exception with argument');

# test setSpecies throws exception with no argument
eval {$featuregroup->setSpecies()};
ok($@, 'setSpecies throws exception with no argument');

# test setSpecies throws exception with too many argument
eval {$featuregroup->setSpecies(1,2)};
ok($@, 'setSpecies throws exception with too many argument');

# test setSpecies accepts undef
eval {$featuregroup->setSpecies(undef)};
ok((!$@ and not defined $featuregroup->getSpecies()),
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



# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($featuregroup->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($featuregroup->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($featuregroup->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$featuregroup->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$featuregroup->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$featuregroup->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$featuregroup->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$featuregroup->setDistanceUnit(undef)};
ok((!$@ and not defined $featuregroup->getDistanceUnit()),
   'setDistanceUnit accepts undef');

# test the meta-data for the assoication
$assn = $assns{distanceUnit};
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
   'distanceUnit->other() is a valid Bio::MAGE::Association::End'
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
   'distanceUnit->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($featuregroup->getDescriptions,'ARRAY')
 and scalar @{$featuregroup->getDescriptions} == 1
 and UNIVERSAL::isa($featuregroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($featuregroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($featuregroup->getDescriptions,'ARRAY')
 and scalar @{$featuregroup->getDescriptions} == 1
 and $featuregroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($featuregroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($featuregroup->getDescriptions,'ARRAY')
 and scalar @{$featuregroup->getDescriptions} == 2
 and $featuregroup->getDescriptions->[0] == $descriptions_assn
 and $featuregroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$featuregroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$featuregroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$featuregroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$featuregroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$featuregroup->setDescriptions([])};
ok((!$@ and defined $featuregroup->getDescriptions()
    and UNIVERSAL::isa($featuregroup->getDescriptions, 'ARRAY')
    and scalar @{$featuregroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$featuregroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$featuregroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$featuregroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$featuregroup->setDescriptions(undef)};
ok((!$@ and not defined $featuregroup->getDescriptions()),
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


isa_ok($featuregroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($featuregroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($featuregroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$featuregroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$featuregroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$featuregroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$featuregroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$featuregroup->setSecurity(undef)};
ok((!$@ and not defined $featuregroup->getSecurity()),
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





my $designelementgroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new();
}

# testing superclass DesignElementGroup
isa_ok($designelementgroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);
isa_ok($featuregroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);

