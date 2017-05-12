##############################
#
# Fiducial.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Fiducial.t`

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
use Test::More tests => 115;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::Fiducial') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::DesignElement::Position;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $fiducial;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $fiducial = Bio::MAGE::Array::Fiducial->new();
}
isa_ok($fiducial, 'Bio::MAGE::Array::Fiducial');

# test the package_name class method
is($fiducial->package_name(), q[Array],
  'package');

# test the class_name class method
is($fiducial->class_name(), q[Bio::MAGE::Array::Fiducial],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $fiducial = Bio::MAGE::Array::Fiducial->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::Fiducial->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $fiducial = Bio::MAGE::Array::Fiducial->new(distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
position => Bio::MAGE::DesignElement::Position->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
fiducialType => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($fiducial->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($fiducial->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($fiducial->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$fiducial->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$fiducial->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$fiducial->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$fiducial->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$fiducial->setDistanceUnit(undef)};
ok((!$@ and not defined $fiducial->getDistanceUnit()),
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


ok((UNIVERSAL::isa($fiducial->getDescriptions,'ARRAY')
 and scalar @{$fiducial->getDescriptions} == 1
 and UNIVERSAL::isa($fiducial->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($fiducial->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($fiducial->getDescriptions,'ARRAY')
 and scalar @{$fiducial->getDescriptions} == 1
 and $fiducial->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($fiducial->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($fiducial->getDescriptions,'ARRAY')
 and scalar @{$fiducial->getDescriptions} == 2
 and $fiducial->getDescriptions->[0] == $descriptions_assn
 and $fiducial->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$fiducial->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$fiducial->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$fiducial->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$fiducial->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$fiducial->setDescriptions([])};
ok((!$@ and defined $fiducial->getDescriptions()
    and UNIVERSAL::isa($fiducial->getDescriptions, 'ARRAY')
    and scalar @{$fiducial->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$fiducial->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$fiducial->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$fiducial->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$fiducial->setDescriptions(undef)};
ok((!$@ and not defined $fiducial->getDescriptions()),
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



# testing association position
my $position_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $position_assn = Bio::MAGE::DesignElement::Position->new();
}


isa_ok($fiducial->getPosition, q[Bio::MAGE::DesignElement::Position]);

is($fiducial->setPosition($position_assn), $position_assn,
  'setPosition returns value');

ok($fiducial->getPosition() == $position_assn,
   'getPosition fetches correct value');

# test setPosition throws exception with bad argument
eval {$fiducial->setPosition(1)};
ok($@, 'setPosition throws exception with bad argument');


# test getPosition throws exception with argument
eval {$fiducial->getPosition(1)};
ok($@, 'getPosition throws exception with argument');

# test setPosition throws exception with no argument
eval {$fiducial->setPosition()};
ok($@, 'setPosition throws exception with no argument');

# test setPosition throws exception with too many argument
eval {$fiducial->setPosition(1,2)};
ok($@, 'setPosition throws exception with too many argument');

# test setPosition accepts undef
eval {$fiducial->setPosition(undef)};
ok((!$@ and not defined $fiducial->getPosition()),
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


ok((UNIVERSAL::isa($fiducial->getAuditTrail,'ARRAY')
 and scalar @{$fiducial->getAuditTrail} == 1
 and UNIVERSAL::isa($fiducial->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($fiducial->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($fiducial->getAuditTrail,'ARRAY')
 and scalar @{$fiducial->getAuditTrail} == 1
 and $fiducial->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($fiducial->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($fiducial->getAuditTrail,'ARRAY')
 and scalar @{$fiducial->getAuditTrail} == 2
 and $fiducial->getAuditTrail->[0] == $audittrail_assn
 and $fiducial->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$fiducial->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$fiducial->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$fiducial->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$fiducial->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$fiducial->setAuditTrail([])};
ok((!$@ and defined $fiducial->getAuditTrail()
    and UNIVERSAL::isa($fiducial->getAuditTrail, 'ARRAY')
    and scalar @{$fiducial->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$fiducial->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$fiducial->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$fiducial->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$fiducial->setAuditTrail(undef)};
ok((!$@ and not defined $fiducial->getAuditTrail()),
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


isa_ok($fiducial->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($fiducial->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($fiducial->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$fiducial->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$fiducial->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$fiducial->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$fiducial->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$fiducial->setSecurity(undef)};
ok((!$@ and not defined $fiducial->getSecurity()),
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


ok((UNIVERSAL::isa($fiducial->getPropertySets,'ARRAY')
 and scalar @{$fiducial->getPropertySets} == 1
 and UNIVERSAL::isa($fiducial->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($fiducial->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($fiducial->getPropertySets,'ARRAY')
 and scalar @{$fiducial->getPropertySets} == 1
 and $fiducial->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($fiducial->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($fiducial->getPropertySets,'ARRAY')
 and scalar @{$fiducial->getPropertySets} == 2
 and $fiducial->getPropertySets->[0] == $propertysets_assn
 and $fiducial->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$fiducial->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$fiducial->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$fiducial->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$fiducial->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$fiducial->setPropertySets([])};
ok((!$@ and defined $fiducial->getPropertySets()
    and UNIVERSAL::isa($fiducial->getPropertySets, 'ARRAY')
    and scalar @{$fiducial->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$fiducial->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$fiducial->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$fiducial->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$fiducial->setPropertySets(undef)};
ok((!$@ and not defined $fiducial->getPropertySets()),
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



# testing association fiducialType
my $fiducialtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $fiducialtype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($fiducial->getFiducialType, q[Bio::MAGE::Description::OntologyEntry]);

is($fiducial->setFiducialType($fiducialtype_assn), $fiducialtype_assn,
  'setFiducialType returns value');

ok($fiducial->getFiducialType() == $fiducialtype_assn,
   'getFiducialType fetches correct value');

# test setFiducialType throws exception with bad argument
eval {$fiducial->setFiducialType(1)};
ok($@, 'setFiducialType throws exception with bad argument');


# test getFiducialType throws exception with argument
eval {$fiducial->getFiducialType(1)};
ok($@, 'getFiducialType throws exception with argument');

# test setFiducialType throws exception with no argument
eval {$fiducial->setFiducialType()};
ok($@, 'setFiducialType throws exception with no argument');

# test setFiducialType throws exception with too many argument
eval {$fiducial->setFiducialType(1,2)};
ok($@, 'setFiducialType throws exception with too many argument');

# test setFiducialType accepts undef
eval {$fiducial->setFiducialType(undef)};
ok((!$@ and not defined $fiducial->getFiducialType()),
   'setFiducialType accepts undef');

# test the meta-data for the assoication
$assn = $assns{fiducialType};
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
   'fiducialType->other() is a valid Bio::MAGE::Association::End'
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
   'fiducialType->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($fiducial, q[Bio::MAGE::Describable]);

