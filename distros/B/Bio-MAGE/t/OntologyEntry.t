##############################
#
# OntologyEntry.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OntologyEntry.t`

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
use Test::More tests => 75;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Description::OntologyEntry') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::Description::DatabaseEntry;


# we test the new() method
my $ontologyentry;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ontologyentry = Bio::MAGE::Description::OntologyEntry->new();
}
isa_ok($ontologyentry, 'Bio::MAGE::Description::OntologyEntry');

# test the package_name class method
is($ontologyentry->package_name(), q[Description],
  'package');

# test the class_name class method
is($ontologyentry->class_name(), q[Bio::MAGE::Description::OntologyEntry],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ontologyentry = Bio::MAGE::Description::OntologyEntry->new(value => '1',
category => '2',
description => '3');
}


#
# testing attribute value
#

# test attribute values can be set in new()
is($ontologyentry->getValue(), '1',
  'value new');

# test getter/setter
$ontologyentry->setValue('1');
is($ontologyentry->getValue(), '1',
  'value getter/setter');

# test getter throws exception with argument
eval {$ontologyentry->getValue(1)};
ok($@, 'value getter throws exception with argument');

# test setter throws exception with no argument
eval {$ontologyentry->setValue()};
ok($@, 'value setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ontologyentry->setValue('1', '1')};
ok($@, 'value setter throws exception with too many argument');

# test setter accepts undef
eval {$ontologyentry->setValue(undef)};
ok((!$@ and not defined $ontologyentry->getValue()),
   'value setter accepts undef');



#
# testing attribute category
#

# test attribute values can be set in new()
is($ontologyentry->getCategory(), '2',
  'category new');

# test getter/setter
$ontologyentry->setCategory('2');
is($ontologyentry->getCategory(), '2',
  'category getter/setter');

# test getter throws exception with argument
eval {$ontologyentry->getCategory(1)};
ok($@, 'category getter throws exception with argument');

# test setter throws exception with no argument
eval {$ontologyentry->setCategory()};
ok($@, 'category setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ontologyentry->setCategory('2', '2')};
ok($@, 'category setter throws exception with too many argument');

# test setter accepts undef
eval {$ontologyentry->setCategory(undef)};
ok((!$@ and not defined $ontologyentry->getCategory()),
   'category setter accepts undef');



#
# testing attribute description
#

# test attribute values can be set in new()
is($ontologyentry->getDescription(), '3',
  'description new');

# test getter/setter
$ontologyentry->setDescription('3');
is($ontologyentry->getDescription(), '3',
  'description getter/setter');

# test getter throws exception with argument
eval {$ontologyentry->getDescription(1)};
ok($@, 'description getter throws exception with argument');

# test setter throws exception with no argument
eval {$ontologyentry->setDescription()};
ok($@, 'description setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$ontologyentry->setDescription('3', '3')};
ok($@, 'description setter throws exception with too many argument');

# test setter accepts undef
eval {$ontologyentry->setDescription(undef)};
ok((!$@ and not defined $ontologyentry->getDescription()),
   'description setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Description::OntologyEntry->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ontologyentry = Bio::MAGE::Description::OntologyEntry->new(associations => [Bio::MAGE::Description::OntologyEntry->new()],
ontologyReference => Bio::MAGE::Description::DatabaseEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association associations
my $associations_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $associations_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($ontologyentry->getAssociations,'ARRAY')
 and scalar @{$ontologyentry->getAssociations} == 1
 and UNIVERSAL::isa($ontologyentry->getAssociations->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'associations set in new()');

ok(eq_array($ontologyentry->setAssociations([$associations_assn]), [$associations_assn]),
   'setAssociations returns correct value');

ok((UNIVERSAL::isa($ontologyentry->getAssociations,'ARRAY')
 and scalar @{$ontologyentry->getAssociations} == 1
 and $ontologyentry->getAssociations->[0] == $associations_assn),
   'getAssociations fetches correct value');

is($ontologyentry->addAssociations($associations_assn), 2,
  'addAssociations returns number of items in list');

ok((UNIVERSAL::isa($ontologyentry->getAssociations,'ARRAY')
 and scalar @{$ontologyentry->getAssociations} == 2
 and $ontologyentry->getAssociations->[0] == $associations_assn
 and $ontologyentry->getAssociations->[1] == $associations_assn),
  'addAssociations adds correct value');

# test setAssociations throws exception with non-array argument
eval {$ontologyentry->setAssociations(1)};
ok($@, 'setAssociations throws exception with non-array argument');

# test setAssociations throws exception with bad argument array
eval {$ontologyentry->setAssociations([1])};
ok($@, 'setAssociations throws exception with bad argument array');

# test addAssociations throws exception with no arguments
eval {$ontologyentry->addAssociations()};
ok($@, 'addAssociations throws exception with no arguments');

# test addAssociations throws exception with bad argument
eval {$ontologyentry->addAssociations(1)};
ok($@, 'addAssociations throws exception with bad array');

# test setAssociations accepts empty array ref
eval {$ontologyentry->setAssociations([])};
ok((!$@ and defined $ontologyentry->getAssociations()
    and UNIVERSAL::isa($ontologyentry->getAssociations, 'ARRAY')
    and scalar @{$ontologyentry->getAssociations} == 0),
   'setAssociations accepts empty array ref');


# test getAssociations throws exception with argument
eval {$ontologyentry->getAssociations(1)};
ok($@, 'getAssociations throws exception with argument');

# test setAssociations throws exception with no argument
eval {$ontologyentry->setAssociations()};
ok($@, 'setAssociations throws exception with no argument');

# test setAssociations throws exception with too many argument
eval {$ontologyentry->setAssociations(1,2)};
ok($@, 'setAssociations throws exception with too many argument');

# test setAssociations accepts undef
eval {$ontologyentry->setAssociations(undef)};
ok((!$@ and not defined $ontologyentry->getAssociations()),
   'setAssociations accepts undef');

# test the meta-data for the assoication
$assn = $assns{associations};
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
   'associations->other() is a valid Bio::MAGE::Association::End'
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
   'associations->self() is a valid Bio::MAGE::Association::End'
  );



# testing association ontologyReference
my $ontologyreference_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $ontologyreference_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


isa_ok($ontologyentry->getOntologyReference, q[Bio::MAGE::Description::DatabaseEntry]);

is($ontologyentry->setOntologyReference($ontologyreference_assn), $ontologyreference_assn,
  'setOntologyReference returns value');

ok($ontologyentry->getOntologyReference() == $ontologyreference_assn,
   'getOntologyReference fetches correct value');

# test setOntologyReference throws exception with bad argument
eval {$ontologyentry->setOntologyReference(1)};
ok($@, 'setOntologyReference throws exception with bad argument');


# test getOntologyReference throws exception with argument
eval {$ontologyentry->getOntologyReference(1)};
ok($@, 'getOntologyReference throws exception with argument');

# test setOntologyReference throws exception with no argument
eval {$ontologyentry->setOntologyReference()};
ok($@, 'setOntologyReference throws exception with no argument');

# test setOntologyReference throws exception with too many argument
eval {$ontologyentry->setOntologyReference(1,2)};
ok($@, 'setOntologyReference throws exception with too many argument');

# test setOntologyReference accepts undef
eval {$ontologyentry->setOntologyReference(undef)};
ok((!$@ and not defined $ontologyentry->getOntologyReference()),
   'setOntologyReference accepts undef');

# test the meta-data for the assoication
$assn = $assns{ontologyReference};
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
   'ontologyReference->other() is a valid Bio::MAGE::Association::End'
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
   'ontologyReference->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($ontologyentry->getPropertySets,'ARRAY')
 and scalar @{$ontologyentry->getPropertySets} == 1
 and UNIVERSAL::isa($ontologyentry->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($ontologyentry->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($ontologyentry->getPropertySets,'ARRAY')
 and scalar @{$ontologyentry->getPropertySets} == 1
 and $ontologyentry->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($ontologyentry->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($ontologyentry->getPropertySets,'ARRAY')
 and scalar @{$ontologyentry->getPropertySets} == 2
 and $ontologyentry->getPropertySets->[0] == $propertysets_assn
 and $ontologyentry->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$ontologyentry->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$ontologyentry->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$ontologyentry->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$ontologyentry->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$ontologyentry->setPropertySets([])};
ok((!$@ and defined $ontologyentry->getPropertySets()
    and UNIVERSAL::isa($ontologyentry->getPropertySets, 'ARRAY')
    and scalar @{$ontologyentry->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$ontologyentry->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$ontologyentry->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$ontologyentry->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$ontologyentry->setPropertySets(undef)};
ok((!$@ and not defined $ontologyentry->getPropertySets()),
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





my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($ontologyentry, q[Bio::MAGE::Extendable]);

