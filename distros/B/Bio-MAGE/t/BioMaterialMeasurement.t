##############################
#
# BioMaterialMeasurement.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioMaterialMeasurement.t`

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

BEGIN { use_ok('Bio::MAGE::BioMaterial::BioMaterialMeasurement') };

use Bio::MAGE::BioMaterial::BioMaterial;
use Bio::MAGE::Measurement::Measurement;
use Bio::MAGE::NameValueType;


# we test the new() method
my $biomaterialmeasurement;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterialmeasurement = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new();
}
isa_ok($biomaterialmeasurement, 'Bio::MAGE::BioMaterial::BioMaterialMeasurement');

# test the package_name class method
is($biomaterialmeasurement->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($biomaterialmeasurement->class_name(), q[Bio::MAGE::BioMaterial::BioMaterialMeasurement],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterialmeasurement = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::BioMaterialMeasurement->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterialmeasurement = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new(bioMaterial => Bio::MAGE::BioMaterial::BioMaterial->new(),
measurement => Bio::MAGE::Measurement::Measurement->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association bioMaterial
my $biomaterial_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial_assn = Bio::MAGE::BioMaterial::BioMaterial->new();
}


isa_ok($biomaterialmeasurement->getBioMaterial, q[Bio::MAGE::BioMaterial::BioMaterial]);

is($biomaterialmeasurement->setBioMaterial($biomaterial_assn), $biomaterial_assn,
  'setBioMaterial returns value');

ok($biomaterialmeasurement->getBioMaterial() == $biomaterial_assn,
   'getBioMaterial fetches correct value');

# test setBioMaterial throws exception with bad argument
eval {$biomaterialmeasurement->setBioMaterial(1)};
ok($@, 'setBioMaterial throws exception with bad argument');


# test getBioMaterial throws exception with argument
eval {$biomaterialmeasurement->getBioMaterial(1)};
ok($@, 'getBioMaterial throws exception with argument');

# test setBioMaterial throws exception with no argument
eval {$biomaterialmeasurement->setBioMaterial()};
ok($@, 'setBioMaterial throws exception with no argument');

# test setBioMaterial throws exception with too many argument
eval {$biomaterialmeasurement->setBioMaterial(1,2)};
ok($@, 'setBioMaterial throws exception with too many argument');

# test setBioMaterial accepts undef
eval {$biomaterialmeasurement->setBioMaterial(undef)};
ok((!$@ and not defined $biomaterialmeasurement->getBioMaterial()),
   'setBioMaterial accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioMaterial};
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
   'bioMaterial->other() is a valid Bio::MAGE::Association::End'
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
   'bioMaterial->self() is a valid Bio::MAGE::Association::End'
  );



# testing association measurement
my $measurement_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement_assn = Bio::MAGE::Measurement::Measurement->new();
}


isa_ok($biomaterialmeasurement->getMeasurement, q[Bio::MAGE::Measurement::Measurement]);

is($biomaterialmeasurement->setMeasurement($measurement_assn), $measurement_assn,
  'setMeasurement returns value');

ok($biomaterialmeasurement->getMeasurement() == $measurement_assn,
   'getMeasurement fetches correct value');

# test setMeasurement throws exception with bad argument
eval {$biomaterialmeasurement->setMeasurement(1)};
ok($@, 'setMeasurement throws exception with bad argument');


# test getMeasurement throws exception with argument
eval {$biomaterialmeasurement->getMeasurement(1)};
ok($@, 'getMeasurement throws exception with argument');

# test setMeasurement throws exception with no argument
eval {$biomaterialmeasurement->setMeasurement()};
ok($@, 'setMeasurement throws exception with no argument');

# test setMeasurement throws exception with too many argument
eval {$biomaterialmeasurement->setMeasurement(1,2)};
ok($@, 'setMeasurement throws exception with too many argument');

# test setMeasurement accepts undef
eval {$biomaterialmeasurement->setMeasurement(undef)};
ok((!$@ and not defined $biomaterialmeasurement->getMeasurement()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($biomaterialmeasurement->getPropertySets,'ARRAY')
 and scalar @{$biomaterialmeasurement->getPropertySets} == 1
 and UNIVERSAL::isa($biomaterialmeasurement->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biomaterialmeasurement->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biomaterialmeasurement->getPropertySets,'ARRAY')
 and scalar @{$biomaterialmeasurement->getPropertySets} == 1
 and $biomaterialmeasurement->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biomaterialmeasurement->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biomaterialmeasurement->getPropertySets,'ARRAY')
 and scalar @{$biomaterialmeasurement->getPropertySets} == 2
 and $biomaterialmeasurement->getPropertySets->[0] == $propertysets_assn
 and $biomaterialmeasurement->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biomaterialmeasurement->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biomaterialmeasurement->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biomaterialmeasurement->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biomaterialmeasurement->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biomaterialmeasurement->setPropertySets([])};
ok((!$@ and defined $biomaterialmeasurement->getPropertySets()
    and UNIVERSAL::isa($biomaterialmeasurement->getPropertySets, 'ARRAY')
    and scalar @{$biomaterialmeasurement->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biomaterialmeasurement->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biomaterialmeasurement->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biomaterialmeasurement->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biomaterialmeasurement->setPropertySets(undef)};
ok((!$@ and not defined $biomaterialmeasurement->getPropertySets()),
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
isa_ok($biomaterialmeasurement, q[Bio::MAGE::Extendable]);

