##############################
#
# Feature.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Feature.t`

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
use Test::More tests => 191;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::Feature') };

use Bio::MAGE::DesignElement::FeatureLocation;
use Bio::MAGE::DesignElement::Position;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::ArrayDesign::FeatureGroup;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::ArrayDesign::Zone;


# we test the new() method
my $feature;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature = Bio::MAGE::DesignElement::Feature->new();
}
isa_ok($feature, 'Bio::MAGE::DesignElement::Feature');

# test the package_name class method
is($feature->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($feature->class_name(), q[Bio::MAGE::DesignElement::Feature],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature = Bio::MAGE::DesignElement::Feature->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($feature->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$feature->setIdentifier('1');
is($feature->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$feature->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$feature->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$feature->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$feature->setIdentifier(undef)};
ok((!$@ and not defined $feature->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($feature->getName(), '2',
  'name new');

# test getter/setter
$feature->setName('2');
is($feature->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$feature->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$feature->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$feature->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$feature->setName(undef)};
ok((!$@ and not defined $feature->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::Feature->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature = Bio::MAGE::DesignElement::Feature->new(controlType => Bio::MAGE::Description::OntologyEntry->new(),
zone => Bio::MAGE::ArrayDesign::Zone->new(),
controlledFeatures => [Bio::MAGE::DesignElement::Feature->new()],
position => Bio::MAGE::DesignElement::Position->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
featureGroup => Bio::MAGE::ArrayDesign::FeatureGroup->new(),
featureLocation => Bio::MAGE::DesignElement::FeatureLocation->new(),
controlFeatures => [Bio::MAGE::DesignElement::Feature->new()]);
}

my ($end, $assn);


# testing association controlType
my $controltype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $controltype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($feature->getControlType, q[Bio::MAGE::Description::OntologyEntry]);

is($feature->setControlType($controltype_assn), $controltype_assn,
  'setControlType returns value');

ok($feature->getControlType() == $controltype_assn,
   'getControlType fetches correct value');

# test setControlType throws exception with bad argument
eval {$feature->setControlType(1)};
ok($@, 'setControlType throws exception with bad argument');


# test getControlType throws exception with argument
eval {$feature->getControlType(1)};
ok($@, 'getControlType throws exception with argument');

# test setControlType throws exception with no argument
eval {$feature->setControlType()};
ok($@, 'setControlType throws exception with no argument');

# test setControlType throws exception with too many argument
eval {$feature->setControlType(1,2)};
ok($@, 'setControlType throws exception with too many argument');

# test setControlType accepts undef
eval {$feature->setControlType(undef)};
ok((!$@ and not defined $feature->getControlType()),
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



# testing association zone
my $zone_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zone_assn = Bio::MAGE::ArrayDesign::Zone->new();
}


isa_ok($feature->getZone, q[Bio::MAGE::ArrayDesign::Zone]);

is($feature->setZone($zone_assn), $zone_assn,
  'setZone returns value');

ok($feature->getZone() == $zone_assn,
   'getZone fetches correct value');

# test setZone throws exception with bad argument
eval {$feature->setZone(1)};
ok($@, 'setZone throws exception with bad argument');


# test getZone throws exception with argument
eval {$feature->getZone(1)};
ok($@, 'getZone throws exception with argument');

# test setZone throws exception with no argument
eval {$feature->setZone()};
ok($@, 'setZone throws exception with no argument');

# test setZone throws exception with too many argument
eval {$feature->setZone(1,2)};
ok($@, 'setZone throws exception with too many argument');

# test setZone accepts undef
eval {$feature->setZone(undef)};
ok((!$@ and not defined $feature->getZone()),
   'setZone accepts undef');

# test the meta-data for the assoication
$assn = $assns{zone};
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
   'zone->other() is a valid Bio::MAGE::Association::End'
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
   'zone->self() is a valid Bio::MAGE::Association::End'
  );



# testing association controlledFeatures
my $controlledfeatures_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $controlledfeatures_assn = Bio::MAGE::DesignElement::Feature->new();
}


ok((UNIVERSAL::isa($feature->getControlledFeatures,'ARRAY')
 and scalar @{$feature->getControlledFeatures} == 1
 and UNIVERSAL::isa($feature->getControlledFeatures->[0], q[Bio::MAGE::DesignElement::Feature])),
  'controlledFeatures set in new()');

ok(eq_array($feature->setControlledFeatures([$controlledfeatures_assn]), [$controlledfeatures_assn]),
   'setControlledFeatures returns correct value');

ok((UNIVERSAL::isa($feature->getControlledFeatures,'ARRAY')
 and scalar @{$feature->getControlledFeatures} == 1
 and $feature->getControlledFeatures->[0] == $controlledfeatures_assn),
   'getControlledFeatures fetches correct value');

is($feature->addControlledFeatures($controlledfeatures_assn), 2,
  'addControlledFeatures returns number of items in list');

ok((UNIVERSAL::isa($feature->getControlledFeatures,'ARRAY')
 and scalar @{$feature->getControlledFeatures} == 2
 and $feature->getControlledFeatures->[0] == $controlledfeatures_assn
 and $feature->getControlledFeatures->[1] == $controlledfeatures_assn),
  'addControlledFeatures adds correct value');

# test setControlledFeatures throws exception with non-array argument
eval {$feature->setControlledFeatures(1)};
ok($@, 'setControlledFeatures throws exception with non-array argument');

# test setControlledFeatures throws exception with bad argument array
eval {$feature->setControlledFeatures([1])};
ok($@, 'setControlledFeatures throws exception with bad argument array');

# test addControlledFeatures throws exception with no arguments
eval {$feature->addControlledFeatures()};
ok($@, 'addControlledFeatures throws exception with no arguments');

# test addControlledFeatures throws exception with bad argument
eval {$feature->addControlledFeatures(1)};
ok($@, 'addControlledFeatures throws exception with bad array');

# test setControlledFeatures accepts empty array ref
eval {$feature->setControlledFeatures([])};
ok((!$@ and defined $feature->getControlledFeatures()
    and UNIVERSAL::isa($feature->getControlledFeatures, 'ARRAY')
    and scalar @{$feature->getControlledFeatures} == 0),
   'setControlledFeatures accepts empty array ref');


# test getControlledFeatures throws exception with argument
eval {$feature->getControlledFeatures(1)};
ok($@, 'getControlledFeatures throws exception with argument');

# test setControlledFeatures throws exception with no argument
eval {$feature->setControlledFeatures()};
ok($@, 'setControlledFeatures throws exception with no argument');

# test setControlledFeatures throws exception with too many argument
eval {$feature->setControlledFeatures(1,2)};
ok($@, 'setControlledFeatures throws exception with too many argument');

# test setControlledFeatures accepts undef
eval {$feature->setControlledFeatures(undef)};
ok((!$@ and not defined $feature->getControlledFeatures()),
   'setControlledFeatures accepts undef');

# test the meta-data for the assoication
$assn = $assns{controlledFeatures};
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
   'controlledFeatures->other() is a valid Bio::MAGE::Association::End'
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
   'controlledFeatures->self() is a valid Bio::MAGE::Association::End'
  );



# testing association position
my $position_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $position_assn = Bio::MAGE::DesignElement::Position->new();
}


isa_ok($feature->getPosition, q[Bio::MAGE::DesignElement::Position]);

is($feature->setPosition($position_assn), $position_assn,
  'setPosition returns value');

ok($feature->getPosition() == $position_assn,
   'getPosition fetches correct value');

# test setPosition throws exception with bad argument
eval {$feature->setPosition(1)};
ok($@, 'setPosition throws exception with bad argument');


# test getPosition throws exception with argument
eval {$feature->getPosition(1)};
ok($@, 'getPosition throws exception with argument');

# test setPosition throws exception with no argument
eval {$feature->setPosition()};
ok($@, 'setPosition throws exception with no argument');

# test setPosition throws exception with too many argument
eval {$feature->setPosition(1,2)};
ok($@, 'setPosition throws exception with too many argument');

# test setPosition accepts undef
eval {$feature->setPosition(undef)};
ok((!$@ and not defined $feature->getPosition()),
   'setPosition accepts undef');

# test the meta-data for the assoication
$assn = $assns{position};
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
   'position->other() is a valid Bio::MAGE::Association::End'
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
   'position->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($feature->getAuditTrail,'ARRAY')
 and scalar @{$feature->getAuditTrail} == 1
 and UNIVERSAL::isa($feature->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($feature->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($feature->getAuditTrail,'ARRAY')
 and scalar @{$feature->getAuditTrail} == 1
 and $feature->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($feature->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($feature->getAuditTrail,'ARRAY')
 and scalar @{$feature->getAuditTrail} == 2
 and $feature->getAuditTrail->[0] == $audittrail_assn
 and $feature->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$feature->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$feature->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$feature->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$feature->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$feature->setAuditTrail([])};
ok((!$@ and defined $feature->getAuditTrail()
    and UNIVERSAL::isa($feature->getAuditTrail, 'ARRAY')
    and scalar @{$feature->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$feature->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$feature->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$feature->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$feature->setAuditTrail(undef)};
ok((!$@ and not defined $feature->getAuditTrail()),
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


ok((UNIVERSAL::isa($feature->getPropertySets,'ARRAY')
 and scalar @{$feature->getPropertySets} == 1
 and UNIVERSAL::isa($feature->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($feature->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($feature->getPropertySets,'ARRAY')
 and scalar @{$feature->getPropertySets} == 1
 and $feature->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($feature->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($feature->getPropertySets,'ARRAY')
 and scalar @{$feature->getPropertySets} == 2
 and $feature->getPropertySets->[0] == $propertysets_assn
 and $feature->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$feature->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$feature->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$feature->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$feature->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$feature->setPropertySets([])};
ok((!$@ and defined $feature->getPropertySets()
    and UNIVERSAL::isa($feature->getPropertySets, 'ARRAY')
    and scalar @{$feature->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$feature->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$feature->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$feature->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$feature->setPropertySets(undef)};
ok((!$@ and not defined $feature->getPropertySets()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($feature->getDescriptions,'ARRAY')
 and scalar @{$feature->getDescriptions} == 1
 and UNIVERSAL::isa($feature->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($feature->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($feature->getDescriptions,'ARRAY')
 and scalar @{$feature->getDescriptions} == 1
 and $feature->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($feature->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($feature->getDescriptions,'ARRAY')
 and scalar @{$feature->getDescriptions} == 2
 and $feature->getDescriptions->[0] == $descriptions_assn
 and $feature->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$feature->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$feature->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$feature->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$feature->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$feature->setDescriptions([])};
ok((!$@ and defined $feature->getDescriptions()
    and UNIVERSAL::isa($feature->getDescriptions, 'ARRAY')
    and scalar @{$feature->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$feature->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$feature->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$feature->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$feature->setDescriptions(undef)};
ok((!$@ and not defined $feature->getDescriptions()),
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


isa_ok($feature->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($feature->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($feature->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$feature->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$feature->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$feature->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$feature->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$feature->setSecurity(undef)};
ok((!$@ and not defined $feature->getSecurity()),
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



# testing association featureGroup
my $featuregroup_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuregroup_assn = Bio::MAGE::ArrayDesign::FeatureGroup->new();
}


isa_ok($feature->getFeatureGroup, q[Bio::MAGE::ArrayDesign::FeatureGroup]);

is($feature->setFeatureGroup($featuregroup_assn), $featuregroup_assn,
  'setFeatureGroup returns value');

ok($feature->getFeatureGroup() == $featuregroup_assn,
   'getFeatureGroup fetches correct value');

# test setFeatureGroup throws exception with bad argument
eval {$feature->setFeatureGroup(1)};
ok($@, 'setFeatureGroup throws exception with bad argument');


# test getFeatureGroup throws exception with argument
eval {$feature->getFeatureGroup(1)};
ok($@, 'getFeatureGroup throws exception with argument');

# test setFeatureGroup throws exception with no argument
eval {$feature->setFeatureGroup()};
ok($@, 'setFeatureGroup throws exception with no argument');

# test setFeatureGroup throws exception with too many argument
eval {$feature->setFeatureGroup(1,2)};
ok($@, 'setFeatureGroup throws exception with too many argument');

# test setFeatureGroup accepts undef
eval {$feature->setFeatureGroup(undef)};
ok((!$@ and not defined $feature->getFeatureGroup()),
   'setFeatureGroup accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureGroup};
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
   'featureGroup->other() is a valid Bio::MAGE::Association::End'
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
   'featureGroup->self() is a valid Bio::MAGE::Association::End'
  );



# testing association featureLocation
my $featurelocation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurelocation_assn = Bio::MAGE::DesignElement::FeatureLocation->new();
}


isa_ok($feature->getFeatureLocation, q[Bio::MAGE::DesignElement::FeatureLocation]);

is($feature->setFeatureLocation($featurelocation_assn), $featurelocation_assn,
  'setFeatureLocation returns value');

ok($feature->getFeatureLocation() == $featurelocation_assn,
   'getFeatureLocation fetches correct value');

# test setFeatureLocation throws exception with bad argument
eval {$feature->setFeatureLocation(1)};
ok($@, 'setFeatureLocation throws exception with bad argument');


# test getFeatureLocation throws exception with argument
eval {$feature->getFeatureLocation(1)};
ok($@, 'getFeatureLocation throws exception with argument');

# test setFeatureLocation throws exception with no argument
eval {$feature->setFeatureLocation()};
ok($@, 'setFeatureLocation throws exception with no argument');

# test setFeatureLocation throws exception with too many argument
eval {$feature->setFeatureLocation(1,2)};
ok($@, 'setFeatureLocation throws exception with too many argument');

# test setFeatureLocation accepts undef
eval {$feature->setFeatureLocation(undef)};
ok((!$@ and not defined $feature->getFeatureLocation()),
   'setFeatureLocation accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureLocation};
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
   'featureLocation->other() is a valid Bio::MAGE::Association::End'
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
   'featureLocation->self() is a valid Bio::MAGE::Association::End'
  );



# testing association controlFeatures
my $controlfeatures_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $controlfeatures_assn = Bio::MAGE::DesignElement::Feature->new();
}


ok((UNIVERSAL::isa($feature->getControlFeatures,'ARRAY')
 and scalar @{$feature->getControlFeatures} == 1
 and UNIVERSAL::isa($feature->getControlFeatures->[0], q[Bio::MAGE::DesignElement::Feature])),
  'controlFeatures set in new()');

ok(eq_array($feature->setControlFeatures([$controlfeatures_assn]), [$controlfeatures_assn]),
   'setControlFeatures returns correct value');

ok((UNIVERSAL::isa($feature->getControlFeatures,'ARRAY')
 and scalar @{$feature->getControlFeatures} == 1
 and $feature->getControlFeatures->[0] == $controlfeatures_assn),
   'getControlFeatures fetches correct value');

is($feature->addControlFeatures($controlfeatures_assn), 2,
  'addControlFeatures returns number of items in list');

ok((UNIVERSAL::isa($feature->getControlFeatures,'ARRAY')
 and scalar @{$feature->getControlFeatures} == 2
 and $feature->getControlFeatures->[0] == $controlfeatures_assn
 and $feature->getControlFeatures->[1] == $controlfeatures_assn),
  'addControlFeatures adds correct value');

# test setControlFeatures throws exception with non-array argument
eval {$feature->setControlFeatures(1)};
ok($@, 'setControlFeatures throws exception with non-array argument');

# test setControlFeatures throws exception with bad argument array
eval {$feature->setControlFeatures([1])};
ok($@, 'setControlFeatures throws exception with bad argument array');

# test addControlFeatures throws exception with no arguments
eval {$feature->addControlFeatures()};
ok($@, 'addControlFeatures throws exception with no arguments');

# test addControlFeatures throws exception with bad argument
eval {$feature->addControlFeatures(1)};
ok($@, 'addControlFeatures throws exception with bad array');

# test setControlFeatures accepts empty array ref
eval {$feature->setControlFeatures([])};
ok((!$@ and defined $feature->getControlFeatures()
    and UNIVERSAL::isa($feature->getControlFeatures, 'ARRAY')
    and scalar @{$feature->getControlFeatures} == 0),
   'setControlFeatures accepts empty array ref');


# test getControlFeatures throws exception with argument
eval {$feature->getControlFeatures(1)};
ok($@, 'getControlFeatures throws exception with argument');

# test setControlFeatures throws exception with no argument
eval {$feature->setControlFeatures()};
ok($@, 'setControlFeatures throws exception with no argument');

# test setControlFeatures throws exception with too many argument
eval {$feature->setControlFeatures(1,2)};
ok($@, 'setControlFeatures throws exception with too many argument');

# test setControlFeatures accepts undef
eval {$feature->setControlFeatures(undef)};
ok((!$@ and not defined $feature->getControlFeatures()),
   'setControlFeatures accepts undef');

# test the meta-data for the assoication
$assn = $assns{controlFeatures};
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
   'controlFeatures->other() is a valid Bio::MAGE::Association::End'
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
   'controlFeatures->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($feature, q[Bio::MAGE::DesignElement::DesignElement]);

