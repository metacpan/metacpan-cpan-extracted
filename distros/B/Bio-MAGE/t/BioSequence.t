##############################
#
# BioSequence.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioSequence.t`

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
use Test::More tests => 208;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioSequence::BioSequence') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::DatabaseEntry;
use Bio::MAGE::BioSequence::SeqFeature;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $biosequence;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosequence = Bio::MAGE::BioSequence::BioSequence->new();
}
isa_ok($biosequence, 'Bio::MAGE::BioSequence::BioSequence');

# test the package_name class method
is($biosequence->package_name(), q[BioSequence],
  'package');

# test the class_name class method
is($biosequence->class_name(), q[Bio::MAGE::BioSequence::BioSequence],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosequence = Bio::MAGE::BioSequence::BioSequence->new(length => '1',
isApproximateLength => '2',
identifier => '3',
sequence => '4',
name => '5',
isCircular => '6');
}


#
# testing attribute length
#

# test attribute values can be set in new()
is($biosequence->getLength(), '1',
  'length new');

# test getter/setter
$biosequence->setLength('1');
is($biosequence->getLength(), '1',
  'length getter/setter');

# test getter throws exception with argument
eval {$biosequence->getLength(1)};
ok($@, 'length getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setLength()};
ok($@, 'length setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setLength('1', '1')};
ok($@, 'length setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setLength(undef)};
ok((!$@ and not defined $biosequence->getLength()),
   'length setter accepts undef');



#
# testing attribute isApproximateLength
#

# test attribute values can be set in new()
is($biosequence->getIsApproximateLength(), '2',
  'isApproximateLength new');

# test getter/setter
$biosequence->setIsApproximateLength('2');
is($biosequence->getIsApproximateLength(), '2',
  'isApproximateLength getter/setter');

# test getter throws exception with argument
eval {$biosequence->getIsApproximateLength(1)};
ok($@, 'isApproximateLength getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setIsApproximateLength()};
ok($@, 'isApproximateLength setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setIsApproximateLength('2', '2')};
ok($@, 'isApproximateLength setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setIsApproximateLength(undef)};
ok((!$@ and not defined $biosequence->getIsApproximateLength()),
   'isApproximateLength setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($biosequence->getIdentifier(), '3',
  'identifier new');

# test getter/setter
$biosequence->setIdentifier('3');
is($biosequence->getIdentifier(), '3',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$biosequence->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setIdentifier('3', '3')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setIdentifier(undef)};
ok((!$@ and not defined $biosequence->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute sequence
#

# test attribute values can be set in new()
is($biosequence->getSequence(), '4',
  'sequence new');

# test getter/setter
$biosequence->setSequence('4');
is($biosequence->getSequence(), '4',
  'sequence getter/setter');

# test getter throws exception with argument
eval {$biosequence->getSequence(1)};
ok($@, 'sequence getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setSequence()};
ok($@, 'sequence setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setSequence('4', '4')};
ok($@, 'sequence setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setSequence(undef)};
ok((!$@ and not defined $biosequence->getSequence()),
   'sequence setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($biosequence->getName(), '5',
  'name new');

# test getter/setter
$biosequence->setName('5');
is($biosequence->getName(), '5',
  'name getter/setter');

# test getter throws exception with argument
eval {$biosequence->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setName('5', '5')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setName(undef)};
ok((!$@ and not defined $biosequence->getName()),
   'name setter accepts undef');



#
# testing attribute isCircular
#

# test attribute values can be set in new()
is($biosequence->getIsCircular(), '6',
  'isCircular new');

# test getter/setter
$biosequence->setIsCircular('6');
is($biosequence->getIsCircular(), '6',
  'isCircular getter/setter');

# test getter throws exception with argument
eval {$biosequence->getIsCircular(1)};
ok($@, 'isCircular getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosequence->setIsCircular()};
ok($@, 'isCircular setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosequence->setIsCircular('6', '6')};
ok($@, 'isCircular setter throws exception with too many argument');

# test setter accepts undef
eval {$biosequence->setIsCircular(undef)};
ok((!$@ and not defined $biosequence->getIsCircular()),
   'isCircular setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioSequence::BioSequence->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosequence = Bio::MAGE::BioSequence::BioSequence->new(sequenceDatabases => [Bio::MAGE::Description::DatabaseEntry->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
polymerType => Bio::MAGE::Description::OntologyEntry->new(),
species => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
ontologyEntries => [Bio::MAGE::Description::OntologyEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
seqFeatures => [Bio::MAGE::BioSequence::SeqFeature->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
type => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association sequenceDatabases
my $sequencedatabases_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sequencedatabases_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


ok((UNIVERSAL::isa($biosequence->getSequenceDatabases,'ARRAY')
 and scalar @{$biosequence->getSequenceDatabases} == 1
 and UNIVERSAL::isa($biosequence->getSequenceDatabases->[0], q[Bio::MAGE::Description::DatabaseEntry])),
  'sequenceDatabases set in new()');

ok(eq_array($biosequence->setSequenceDatabases([$sequencedatabases_assn]), [$sequencedatabases_assn]),
   'setSequenceDatabases returns correct value');

ok((UNIVERSAL::isa($biosequence->getSequenceDatabases,'ARRAY')
 and scalar @{$biosequence->getSequenceDatabases} == 1
 and $biosequence->getSequenceDatabases->[0] == $sequencedatabases_assn),
   'getSequenceDatabases fetches correct value');

is($biosequence->addSequenceDatabases($sequencedatabases_assn), 2,
  'addSequenceDatabases returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getSequenceDatabases,'ARRAY')
 and scalar @{$biosequence->getSequenceDatabases} == 2
 and $biosequence->getSequenceDatabases->[0] == $sequencedatabases_assn
 and $biosequence->getSequenceDatabases->[1] == $sequencedatabases_assn),
  'addSequenceDatabases adds correct value');

# test setSequenceDatabases throws exception with non-array argument
eval {$biosequence->setSequenceDatabases(1)};
ok($@, 'setSequenceDatabases throws exception with non-array argument');

# test setSequenceDatabases throws exception with bad argument array
eval {$biosequence->setSequenceDatabases([1])};
ok($@, 'setSequenceDatabases throws exception with bad argument array');

# test addSequenceDatabases throws exception with no arguments
eval {$biosequence->addSequenceDatabases()};
ok($@, 'addSequenceDatabases throws exception with no arguments');

# test addSequenceDatabases throws exception with bad argument
eval {$biosequence->addSequenceDatabases(1)};
ok($@, 'addSequenceDatabases throws exception with bad array');

# test setSequenceDatabases accepts empty array ref
eval {$biosequence->setSequenceDatabases([])};
ok((!$@ and defined $biosequence->getSequenceDatabases()
    and UNIVERSAL::isa($biosequence->getSequenceDatabases, 'ARRAY')
    and scalar @{$biosequence->getSequenceDatabases} == 0),
   'setSequenceDatabases accepts empty array ref');


# test getSequenceDatabases throws exception with argument
eval {$biosequence->getSequenceDatabases(1)};
ok($@, 'getSequenceDatabases throws exception with argument');

# test setSequenceDatabases throws exception with no argument
eval {$biosequence->setSequenceDatabases()};
ok($@, 'setSequenceDatabases throws exception with no argument');

# test setSequenceDatabases throws exception with too many argument
eval {$biosequence->setSequenceDatabases(1,2)};
ok($@, 'setSequenceDatabases throws exception with too many argument');

# test setSequenceDatabases accepts undef
eval {$biosequence->setSequenceDatabases(undef)};
ok((!$@ and not defined $biosequence->getSequenceDatabases()),
   'setSequenceDatabases accepts undef');

# test the meta-data for the assoication
$assn = $assns{sequenceDatabases};
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
   'sequenceDatabases->other() is a valid Bio::MAGE::Association::End'
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
   'sequenceDatabases->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($biosequence->getAuditTrail,'ARRAY')
 and scalar @{$biosequence->getAuditTrail} == 1
 and UNIVERSAL::isa($biosequence->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($biosequence->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($biosequence->getAuditTrail,'ARRAY')
 and scalar @{$biosequence->getAuditTrail} == 1
 and $biosequence->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($biosequence->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getAuditTrail,'ARRAY')
 and scalar @{$biosequence->getAuditTrail} == 2
 and $biosequence->getAuditTrail->[0] == $audittrail_assn
 and $biosequence->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$biosequence->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$biosequence->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$biosequence->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$biosequence->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$biosequence->setAuditTrail([])};
ok((!$@ and defined $biosequence->getAuditTrail()
    and UNIVERSAL::isa($biosequence->getAuditTrail, 'ARRAY')
    and scalar @{$biosequence->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$biosequence->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$biosequence->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$biosequence->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$biosequence->setAuditTrail(undef)};
ok((!$@ and not defined $biosequence->getAuditTrail()),
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



# testing association polymerType
my $polymertype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $polymertype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosequence->getPolymerType, q[Bio::MAGE::Description::OntologyEntry]);

is($biosequence->setPolymerType($polymertype_assn), $polymertype_assn,
  'setPolymerType returns value');

ok($biosequence->getPolymerType() == $polymertype_assn,
   'getPolymerType fetches correct value');

# test setPolymerType throws exception with bad argument
eval {$biosequence->setPolymerType(1)};
ok($@, 'setPolymerType throws exception with bad argument');


# test getPolymerType throws exception with argument
eval {$biosequence->getPolymerType(1)};
ok($@, 'getPolymerType throws exception with argument');

# test setPolymerType throws exception with no argument
eval {$biosequence->setPolymerType()};
ok($@, 'setPolymerType throws exception with no argument');

# test setPolymerType throws exception with too many argument
eval {$biosequence->setPolymerType(1,2)};
ok($@, 'setPolymerType throws exception with too many argument');

# test setPolymerType accepts undef
eval {$biosequence->setPolymerType(undef)};
ok((!$@ and not defined $biosequence->getPolymerType()),
   'setPolymerType accepts undef');

# test the meta-data for the assoication
$assn = $assns{polymerType};
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
   'polymerType->other() is a valid Bio::MAGE::Association::End'
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
   'polymerType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association species
my $species_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $species_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosequence->getSpecies, q[Bio::MAGE::Description::OntologyEntry]);

is($biosequence->setSpecies($species_assn), $species_assn,
  'setSpecies returns value');

ok($biosequence->getSpecies() == $species_assn,
   'getSpecies fetches correct value');

# test setSpecies throws exception with bad argument
eval {$biosequence->setSpecies(1)};
ok($@, 'setSpecies throws exception with bad argument');


# test getSpecies throws exception with argument
eval {$biosequence->getSpecies(1)};
ok($@, 'getSpecies throws exception with argument');

# test setSpecies throws exception with no argument
eval {$biosequence->setSpecies()};
ok($@, 'setSpecies throws exception with no argument');

# test setSpecies throws exception with too many argument
eval {$biosequence->setSpecies(1,2)};
ok($@, 'setSpecies throws exception with too many argument');

# test setSpecies accepts undef
eval {$biosequence->setSpecies(undef)};
ok((!$@ and not defined $biosequence->getSpecies()),
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


ok((UNIVERSAL::isa($biosequence->getPropertySets,'ARRAY')
 and scalar @{$biosequence->getPropertySets} == 1
 and UNIVERSAL::isa($biosequence->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biosequence->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biosequence->getPropertySets,'ARRAY')
 and scalar @{$biosequence->getPropertySets} == 1
 and $biosequence->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biosequence->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getPropertySets,'ARRAY')
 and scalar @{$biosequence->getPropertySets} == 2
 and $biosequence->getPropertySets->[0] == $propertysets_assn
 and $biosequence->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biosequence->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biosequence->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biosequence->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biosequence->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biosequence->setPropertySets([])};
ok((!$@ and defined $biosequence->getPropertySets()
    and UNIVERSAL::isa($biosequence->getPropertySets, 'ARRAY')
    and scalar @{$biosequence->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biosequence->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biosequence->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biosequence->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biosequence->setPropertySets(undef)};
ok((!$@ and not defined $biosequence->getPropertySets()),
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



# testing association ontologyEntries
my $ontologyentries_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ontologyentries_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($biosequence->getOntologyEntries,'ARRAY')
 and scalar @{$biosequence->getOntologyEntries} == 1
 and UNIVERSAL::isa($biosequence->getOntologyEntries->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'ontologyEntries set in new()');

ok(eq_array($biosequence->setOntologyEntries([$ontologyentries_assn]), [$ontologyentries_assn]),
   'setOntologyEntries returns correct value');

ok((UNIVERSAL::isa($biosequence->getOntologyEntries,'ARRAY')
 and scalar @{$biosequence->getOntologyEntries} == 1
 and $biosequence->getOntologyEntries->[0] == $ontologyentries_assn),
   'getOntologyEntries fetches correct value');

is($biosequence->addOntologyEntries($ontologyentries_assn), 2,
  'addOntologyEntries returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getOntologyEntries,'ARRAY')
 and scalar @{$biosequence->getOntologyEntries} == 2
 and $biosequence->getOntologyEntries->[0] == $ontologyentries_assn
 and $biosequence->getOntologyEntries->[1] == $ontologyentries_assn),
  'addOntologyEntries adds correct value');

# test setOntologyEntries throws exception with non-array argument
eval {$biosequence->setOntologyEntries(1)};
ok($@, 'setOntologyEntries throws exception with non-array argument');

# test setOntologyEntries throws exception with bad argument array
eval {$biosequence->setOntologyEntries([1])};
ok($@, 'setOntologyEntries throws exception with bad argument array');

# test addOntologyEntries throws exception with no arguments
eval {$biosequence->addOntologyEntries()};
ok($@, 'addOntologyEntries throws exception with no arguments');

# test addOntologyEntries throws exception with bad argument
eval {$biosequence->addOntologyEntries(1)};
ok($@, 'addOntologyEntries throws exception with bad array');

# test setOntologyEntries accepts empty array ref
eval {$biosequence->setOntologyEntries([])};
ok((!$@ and defined $biosequence->getOntologyEntries()
    and UNIVERSAL::isa($biosequence->getOntologyEntries, 'ARRAY')
    and scalar @{$biosequence->getOntologyEntries} == 0),
   'setOntologyEntries accepts empty array ref');


# test getOntologyEntries throws exception with argument
eval {$biosequence->getOntologyEntries(1)};
ok($@, 'getOntologyEntries throws exception with argument');

# test setOntologyEntries throws exception with no argument
eval {$biosequence->setOntologyEntries()};
ok($@, 'setOntologyEntries throws exception with no argument');

# test setOntologyEntries throws exception with too many argument
eval {$biosequence->setOntologyEntries(1,2)};
ok($@, 'setOntologyEntries throws exception with too many argument');

# test setOntologyEntries accepts undef
eval {$biosequence->setOntologyEntries(undef)};
ok((!$@ and not defined $biosequence->getOntologyEntries()),
   'setOntologyEntries accepts undef');

# test the meta-data for the assoication
$assn = $assns{ontologyEntries};
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
   'ontologyEntries->other() is a valid Bio::MAGE::Association::End'
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
   'ontologyEntries->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($biosequence->getDescriptions,'ARRAY')
 and scalar @{$biosequence->getDescriptions} == 1
 and UNIVERSAL::isa($biosequence->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($biosequence->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($biosequence->getDescriptions,'ARRAY')
 and scalar @{$biosequence->getDescriptions} == 1
 and $biosequence->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($biosequence->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getDescriptions,'ARRAY')
 and scalar @{$biosequence->getDescriptions} == 2
 and $biosequence->getDescriptions->[0] == $descriptions_assn
 and $biosequence->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$biosequence->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$biosequence->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$biosequence->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$biosequence->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$biosequence->setDescriptions([])};
ok((!$@ and defined $biosequence->getDescriptions()
    and UNIVERSAL::isa($biosequence->getDescriptions, 'ARRAY')
    and scalar @{$biosequence->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$biosequence->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$biosequence->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$biosequence->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$biosequence->setDescriptions(undef)};
ok((!$@ and not defined $biosequence->getDescriptions()),
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



# testing association seqFeatures
my $seqfeatures_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeatures_assn = Bio::MAGE::BioSequence::SeqFeature->new();
}


ok((UNIVERSAL::isa($biosequence->getSeqFeatures,'ARRAY')
 and scalar @{$biosequence->getSeqFeatures} == 1
 and UNIVERSAL::isa($biosequence->getSeqFeatures->[0], q[Bio::MAGE::BioSequence::SeqFeature])),
  'seqFeatures set in new()');

ok(eq_array($biosequence->setSeqFeatures([$seqfeatures_assn]), [$seqfeatures_assn]),
   'setSeqFeatures returns correct value');

ok((UNIVERSAL::isa($biosequence->getSeqFeatures,'ARRAY')
 and scalar @{$biosequence->getSeqFeatures} == 1
 and $biosequence->getSeqFeatures->[0] == $seqfeatures_assn),
   'getSeqFeatures fetches correct value');

is($biosequence->addSeqFeatures($seqfeatures_assn), 2,
  'addSeqFeatures returns number of items in list');

ok((UNIVERSAL::isa($biosequence->getSeqFeatures,'ARRAY')
 and scalar @{$biosequence->getSeqFeatures} == 2
 and $biosequence->getSeqFeatures->[0] == $seqfeatures_assn
 and $biosequence->getSeqFeatures->[1] == $seqfeatures_assn),
  'addSeqFeatures adds correct value');

# test setSeqFeatures throws exception with non-array argument
eval {$biosequence->setSeqFeatures(1)};
ok($@, 'setSeqFeatures throws exception with non-array argument');

# test setSeqFeatures throws exception with bad argument array
eval {$biosequence->setSeqFeatures([1])};
ok($@, 'setSeqFeatures throws exception with bad argument array');

# test addSeqFeatures throws exception with no arguments
eval {$biosequence->addSeqFeatures()};
ok($@, 'addSeqFeatures throws exception with no arguments');

# test addSeqFeatures throws exception with bad argument
eval {$biosequence->addSeqFeatures(1)};
ok($@, 'addSeqFeatures throws exception with bad array');

# test setSeqFeatures accepts empty array ref
eval {$biosequence->setSeqFeatures([])};
ok((!$@ and defined $biosequence->getSeqFeatures()
    and UNIVERSAL::isa($biosequence->getSeqFeatures, 'ARRAY')
    and scalar @{$biosequence->getSeqFeatures} == 0),
   'setSeqFeatures accepts empty array ref');


# test getSeqFeatures throws exception with argument
eval {$biosequence->getSeqFeatures(1)};
ok($@, 'getSeqFeatures throws exception with argument');

# test setSeqFeatures throws exception with no argument
eval {$biosequence->setSeqFeatures()};
ok($@, 'setSeqFeatures throws exception with no argument');

# test setSeqFeatures throws exception with too many argument
eval {$biosequence->setSeqFeatures(1,2)};
ok($@, 'setSeqFeatures throws exception with too many argument');

# test setSeqFeatures accepts undef
eval {$biosequence->setSeqFeatures(undef)};
ok((!$@ and not defined $biosequence->getSeqFeatures()),
   'setSeqFeatures accepts undef');

# test the meta-data for the assoication
$assn = $assns{seqFeatures};
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
   'seqFeatures->other() is a valid Bio::MAGE::Association::End'
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
   'seqFeatures->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($biosequence->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($biosequence->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($biosequence->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$biosequence->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$biosequence->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$biosequence->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$biosequence->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$biosequence->setSecurity(undef)};
ok((!$@ and not defined $biosequence->getSecurity()),
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



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosequence->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($biosequence->setType($type_assn), $type_assn,
  'setType returns value');

ok($biosequence->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$biosequence->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$biosequence->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$biosequence->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$biosequence->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$biosequence->setType(undef)};
ok((!$@ and not defined $biosequence->getType()),
   'setType accepts undef');

# test the meta-data for the assoication
$assn = $assns{type};
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
   'type->other() is a valid Bio::MAGE::Association::End'
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
   'type->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($biosequence, q[Bio::MAGE::Identifiable]);

