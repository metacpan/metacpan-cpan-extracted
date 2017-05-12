##############################
#
# DesignElementGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DesignElementGroup.t`

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
use Test::More tests => 126;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::DesignElementGroup') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;

use Bio::MAGE::ArrayDesign::ReporterGroup;
use Bio::MAGE::ArrayDesign::FeatureGroup;
use Bio::MAGE::ArrayDesign::CompositeGroup;

# we test the new() method
my $designelementgroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new();
}
isa_ok($designelementgroup, 'Bio::MAGE::ArrayDesign::DesignElementGroup');

# test the package_name class method
is($designelementgroup->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($designelementgroup->class_name(), q[Bio::MAGE::ArrayDesign::DesignElementGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($designelementgroup->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$designelementgroup->setIdentifier('1');
is($designelementgroup->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$designelementgroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$designelementgroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$designelementgroup->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$designelementgroup->setIdentifier(undef)};
ok((!$@ and not defined $designelementgroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($designelementgroup->getName(), '2',
  'name new');

# test getter/setter
$designelementgroup->setName('2');
is($designelementgroup->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$designelementgroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$designelementgroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$designelementgroup->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$designelementgroup->setName(undef)};
ok((!$@ and not defined $designelementgroup->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::DesignElementGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new(types => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
species => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association types
my $types_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $types_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($designelementgroup->getTypes,'ARRAY')
 and scalar @{$designelementgroup->getTypes} == 1
 and UNIVERSAL::isa($designelementgroup->getTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'types set in new()');

ok(eq_array($designelementgroup->setTypes([$types_assn]), [$types_assn]),
   'setTypes returns correct value');

ok((UNIVERSAL::isa($designelementgroup->getTypes,'ARRAY')
 and scalar @{$designelementgroup->getTypes} == 1
 and $designelementgroup->getTypes->[0] == $types_assn),
   'getTypes fetches correct value');

is($designelementgroup->addTypes($types_assn), 2,
  'addTypes returns number of items in list');

ok((UNIVERSAL::isa($designelementgroup->getTypes,'ARRAY')
 and scalar @{$designelementgroup->getTypes} == 2
 and $designelementgroup->getTypes->[0] == $types_assn
 and $designelementgroup->getTypes->[1] == $types_assn),
  'addTypes adds correct value');

# test setTypes throws exception with non-array argument
eval {$designelementgroup->setTypes(1)};
ok($@, 'setTypes throws exception with non-array argument');

# test setTypes throws exception with bad argument array
eval {$designelementgroup->setTypes([1])};
ok($@, 'setTypes throws exception with bad argument array');

# test addTypes throws exception with no arguments
eval {$designelementgroup->addTypes()};
ok($@, 'addTypes throws exception with no arguments');

# test addTypes throws exception with bad argument
eval {$designelementgroup->addTypes(1)};
ok($@, 'addTypes throws exception with bad array');

# test setTypes accepts empty array ref
eval {$designelementgroup->setTypes([])};
ok((!$@ and defined $designelementgroup->getTypes()
    and UNIVERSAL::isa($designelementgroup->getTypes, 'ARRAY')
    and scalar @{$designelementgroup->getTypes} == 0),
   'setTypes accepts empty array ref');


# test getTypes throws exception with argument
eval {$designelementgroup->getTypes(1)};
ok($@, 'getTypes throws exception with argument');

# test setTypes throws exception with no argument
eval {$designelementgroup->setTypes()};
ok($@, 'setTypes throws exception with no argument');

# test setTypes throws exception with too many argument
eval {$designelementgroup->setTypes(1,2)};
ok($@, 'setTypes throws exception with too many argument');

# test setTypes accepts undef
eval {$designelementgroup->setTypes(undef)};
ok((!$@ and not defined $designelementgroup->getTypes()),
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


ok((UNIVERSAL::isa($designelementgroup->getDescriptions,'ARRAY')
 and scalar @{$designelementgroup->getDescriptions} == 1
 and UNIVERSAL::isa($designelementgroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($designelementgroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($designelementgroup->getDescriptions,'ARRAY')
 and scalar @{$designelementgroup->getDescriptions} == 1
 and $designelementgroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($designelementgroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($designelementgroup->getDescriptions,'ARRAY')
 and scalar @{$designelementgroup->getDescriptions} == 2
 and $designelementgroup->getDescriptions->[0] == $descriptions_assn
 and $designelementgroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$designelementgroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$designelementgroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$designelementgroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$designelementgroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$designelementgroup->setDescriptions([])};
ok((!$@ and defined $designelementgroup->getDescriptions()
    and UNIVERSAL::isa($designelementgroup->getDescriptions, 'ARRAY')
    and scalar @{$designelementgroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$designelementgroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$designelementgroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$designelementgroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$designelementgroup->setDescriptions(undef)};
ok((!$@ and not defined $designelementgroup->getDescriptions()),
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


isa_ok($designelementgroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($designelementgroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($designelementgroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$designelementgroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$designelementgroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$designelementgroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$designelementgroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$designelementgroup->setSecurity(undef)};
ok((!$@ and not defined $designelementgroup->getSecurity()),
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


ok((UNIVERSAL::isa($designelementgroup->getAuditTrail,'ARRAY')
 and scalar @{$designelementgroup->getAuditTrail} == 1
 and UNIVERSAL::isa($designelementgroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($designelementgroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($designelementgroup->getAuditTrail,'ARRAY')
 and scalar @{$designelementgroup->getAuditTrail} == 1
 and $designelementgroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($designelementgroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($designelementgroup->getAuditTrail,'ARRAY')
 and scalar @{$designelementgroup->getAuditTrail} == 2
 and $designelementgroup->getAuditTrail->[0] == $audittrail_assn
 and $designelementgroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$designelementgroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$designelementgroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$designelementgroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$designelementgroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$designelementgroup->setAuditTrail([])};
ok((!$@ and defined $designelementgroup->getAuditTrail()
    and UNIVERSAL::isa($designelementgroup->getAuditTrail, 'ARRAY')
    and scalar @{$designelementgroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$designelementgroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$designelementgroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$designelementgroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$designelementgroup->setAuditTrail(undef)};
ok((!$@ and not defined $designelementgroup->getAuditTrail()),
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



# testing association species
my $species_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $species_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($designelementgroup->getSpecies, q[Bio::MAGE::Description::OntologyEntry]);

is($designelementgroup->setSpecies($species_assn), $species_assn,
  'setSpecies returns value');

ok($designelementgroup->getSpecies() == $species_assn,
   'getSpecies fetches correct value');

# test setSpecies throws exception with bad argument
eval {$designelementgroup->setSpecies(1)};
ok($@, 'setSpecies throws exception with bad argument');


# test getSpecies throws exception with argument
eval {$designelementgroup->getSpecies(1)};
ok($@, 'getSpecies throws exception with argument');

# test setSpecies throws exception with no argument
eval {$designelementgroup->setSpecies()};
ok($@, 'setSpecies throws exception with no argument');

# test setSpecies throws exception with too many argument
eval {$designelementgroup->setSpecies(1,2)};
ok($@, 'setSpecies throws exception with too many argument');

# test setSpecies accepts undef
eval {$designelementgroup->setSpecies(undef)};
ok((!$@ and not defined $designelementgroup->getSpecies()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($designelementgroup->getPropertySets,'ARRAY')
 and scalar @{$designelementgroup->getPropertySets} == 1
 and UNIVERSAL::isa($designelementgroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($designelementgroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($designelementgroup->getPropertySets,'ARRAY')
 and scalar @{$designelementgroup->getPropertySets} == 1
 and $designelementgroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($designelementgroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($designelementgroup->getPropertySets,'ARRAY')
 and scalar @{$designelementgroup->getPropertySets} == 2
 and $designelementgroup->getPropertySets->[0] == $propertysets_assn
 and $designelementgroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$designelementgroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$designelementgroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$designelementgroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$designelementgroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$designelementgroup->setPropertySets([])};
ok((!$@ and defined $designelementgroup->getPropertySets()
    and UNIVERSAL::isa($designelementgroup->getPropertySets, 'ARRAY')
    and scalar @{$designelementgroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$designelementgroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$designelementgroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$designelementgroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$designelementgroup->setPropertySets(undef)};
ok((!$@ and not defined $designelementgroup->getPropertySets()),
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




# create a subclass
my $reportergroup = Bio::MAGE::ArrayDesign::ReporterGroup->new();

# testing subclass ReporterGroup
isa_ok($reportergroup, q[Bio::MAGE::ArrayDesign::ReporterGroup]);
isa_ok($reportergroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);


# create a subclass
my $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new();

# testing subclass FeatureGroup
isa_ok($featuregroup, q[Bio::MAGE::ArrayDesign::FeatureGroup]);
isa_ok($featuregroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);


# create a subclass
my $compositegroup = Bio::MAGE::ArrayDesign::CompositeGroup->new();

# testing subclass CompositeGroup
isa_ok($compositegroup, q[Bio::MAGE::ArrayDesign::CompositeGroup]);
isa_ok($compositegroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($designelementgroup, q[Bio::MAGE::Identifiable]);

