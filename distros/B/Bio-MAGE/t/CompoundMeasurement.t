##############################
#
# CompoundMeasurement.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompoundMeasurement.t`

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
use Test::More tests => 51;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::CompoundMeasurement') };

use Bio::MAGE::Measurement::Measurement;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioMaterial::Compound;


# we test the new() method
my $compoundmeasurement;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compoundmeasurement = Bio::MAGE::BioMaterial::CompoundMeasurement->new();
}
isa_ok($compoundmeasurement, 'Bio::MAGE::BioMaterial::CompoundMeasurement');

# test the package_name class method
is($compoundmeasurement->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($compoundmeasurement->class_name(), q[Bio::MAGE::BioMaterial::CompoundMeasurement],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compoundmeasurement = Bio::MAGE::BioMaterial::CompoundMeasurement->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::CompoundMeasurement->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compoundmeasurement = Bio::MAGE::BioMaterial::CompoundMeasurement->new(measurement => Bio::MAGE::Measurement::Measurement->new(),
compound => Bio::MAGE::BioMaterial::Compound->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association measurement
my $measurement_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement_assn = Bio::MAGE::Measurement::Measurement->new();
}


isa_ok($compoundmeasurement->getMeasurement, q[Bio::MAGE::Measurement::Measurement]);

is($compoundmeasurement->setMeasurement($measurement_assn), $measurement_assn,
  'setMeasurement returns value');

ok($compoundmeasurement->getMeasurement() == $measurement_assn,
   'getMeasurement fetches correct value');

# test setMeasurement throws exception with bad argument
eval {$compoundmeasurement->setMeasurement(1)};
ok($@, 'setMeasurement throws exception with bad argument');


# test getMeasurement throws exception with argument
eval {$compoundmeasurement->getMeasurement(1)};
ok($@, 'getMeasurement throws exception with argument');

# test setMeasurement throws exception with no argument
eval {$compoundmeasurement->setMeasurement()};
ok($@, 'setMeasurement throws exception with no argument');

# test setMeasurement throws exception with too many argument
eval {$compoundmeasurement->setMeasurement(1,2)};
ok($@, 'setMeasurement throws exception with too many argument');

# test setMeasurement accepts undef
eval {$compoundmeasurement->setMeasurement(undef)};
ok((!$@ and not defined $compoundmeasurement->getMeasurement()),
   'setMeasurement accepts undef');

# test the meta-data for the assoication
$assn = $assns{measurement};
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
   'measurement->other() is a valid Bio::MAGE::Association::End'
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
   'measurement->self() is a valid Bio::MAGE::Association::End'
  );



# testing association compound
my $compound_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compound_assn = Bio::MAGE::BioMaterial::Compound->new();
}


isa_ok($compoundmeasurement->getCompound, q[Bio::MAGE::BioMaterial::Compound]);

is($compoundmeasurement->setCompound($compound_assn), $compound_assn,
  'setCompound returns value');

ok($compoundmeasurement->getCompound() == $compound_assn,
   'getCompound fetches correct value');

# test setCompound throws exception with bad argument
eval {$compoundmeasurement->setCompound(1)};
ok($@, 'setCompound throws exception with bad argument');


# test getCompound throws exception with argument
eval {$compoundmeasurement->getCompound(1)};
ok($@, 'getCompound throws exception with argument');

# test setCompound throws exception with no argument
eval {$compoundmeasurement->setCompound()};
ok($@, 'setCompound throws exception with no argument');

# test setCompound throws exception with too many argument
eval {$compoundmeasurement->setCompound(1,2)};
ok($@, 'setCompound throws exception with too many argument');

# test setCompound accepts undef
eval {$compoundmeasurement->setCompound(undef)};
ok((!$@ and not defined $compoundmeasurement->getCompound()),
   'setCompound accepts undef');

# test the meta-data for the assoication
$assn = $assns{compound};
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
   'compound->other() is a valid Bio::MAGE::Association::End'
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
   'compound->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($compoundmeasurement->getPropertySets,'ARRAY')
 and scalar @{$compoundmeasurement->getPropertySets} == 1
 and UNIVERSAL::isa($compoundmeasurement->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compoundmeasurement->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compoundmeasurement->getPropertySets,'ARRAY')
 and scalar @{$compoundmeasurement->getPropertySets} == 1
 and $compoundmeasurement->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compoundmeasurement->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compoundmeasurement->getPropertySets,'ARRAY')
 and scalar @{$compoundmeasurement->getPropertySets} == 2
 and $compoundmeasurement->getPropertySets->[0] == $propertysets_assn
 and $compoundmeasurement->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compoundmeasurement->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compoundmeasurement->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compoundmeasurement->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compoundmeasurement->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compoundmeasurement->setPropertySets([])};
ok((!$@ and defined $compoundmeasurement->getPropertySets()
    and UNIVERSAL::isa($compoundmeasurement->getPropertySets, 'ARRAY')
    and scalar @{$compoundmeasurement->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compoundmeasurement->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compoundmeasurement->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compoundmeasurement->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compoundmeasurement->setPropertySets(undef)};
ok((!$@ and not defined $compoundmeasurement->getPropertySets()),
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
isa_ok($compoundmeasurement, q[Bio::MAGE::Extendable]);

