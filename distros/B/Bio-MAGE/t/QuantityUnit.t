##############################
#
# QuantityUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl QuantityUnit.t`

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
use Test::More tests => 47;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::QuantityUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $quantityunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new();
}
isa_ok($quantityunit, 'Bio::MAGE::Measurement::QuantityUnit');

# test the package_name class method
is($quantityunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($quantityunit->class_name(), q[Bio::MAGE::Measurement::QuantityUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new(unitName => '1',
unitNameCV => 'mol');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($quantityunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$quantityunit->setUnitName('1');
is($quantityunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$quantityunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantityunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantityunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$quantityunit->setUnitName(undef)};
ok((!$@ and not defined $quantityunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($quantityunit->getUnitNameCV(), 'mol',
  'unitNameCV new');

# test getter/setter
$quantityunit->setUnitNameCV('mol');
is($quantityunit->getUnitNameCV(), 'mol',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$quantityunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantityunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantityunit->setUnitNameCV('mol', 'mol')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$quantityunit->setUnitNameCV(undef)};
ok((!$@ and not defined $quantityunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$quantityunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: mol

eval {$quantityunit->setUnitNameCV('mol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'mol'),
   'unitNameCV accepts mol');


# test setter accepts enumerated value: amol

eval {$quantityunit->setUnitNameCV('amol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'amol'),
   'unitNameCV accepts amol');


# test setter accepts enumerated value: fmol

eval {$quantityunit->setUnitNameCV('fmol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'fmol'),
   'unitNameCV accepts fmol');


# test setter accepts enumerated value: pmol

eval {$quantityunit->setUnitNameCV('pmol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'pmol'),
   'unitNameCV accepts pmol');


# test setter accepts enumerated value: nmol

eval {$quantityunit->setUnitNameCV('nmol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'nmol'),
   'unitNameCV accepts nmol');


# test setter accepts enumerated value: umol

eval {$quantityunit->setUnitNameCV('umol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'umol'),
   'unitNameCV accepts umol');


# test setter accepts enumerated value: mmol

eval {$quantityunit->setUnitNameCV('mmol')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'mmol'),
   'unitNameCV accepts mmol');


# test setter accepts enumerated value: molecules

eval {$quantityunit->setUnitNameCV('molecules')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'molecules'),
   'unitNameCV accepts molecules');


# test setter accepts enumerated value: other

eval {$quantityunit->setUnitNameCV('other')};
ok((not $@ and $quantityunit->getUnitNameCV() eq 'other'),
   'unitNameCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::QuantityUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($quantityunit->getPropertySets,'ARRAY')
 and scalar @{$quantityunit->getPropertySets} == 1
 and UNIVERSAL::isa($quantityunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($quantityunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($quantityunit->getPropertySets,'ARRAY')
 and scalar @{$quantityunit->getPropertySets} == 1
 and $quantityunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($quantityunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($quantityunit->getPropertySets,'ARRAY')
 and scalar @{$quantityunit->getPropertySets} == 2
 and $quantityunit->getPropertySets->[0] == $propertysets_assn
 and $quantityunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$quantityunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$quantityunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$quantityunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$quantityunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$quantityunit->setPropertySets([])};
ok((!$@ and defined $quantityunit->getPropertySets()
    and UNIVERSAL::isa($quantityunit->getPropertySets, 'ARRAY')
    and scalar @{$quantityunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$quantityunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$quantityunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$quantityunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$quantityunit->setPropertySets(undef)};
ok((!$@ and not defined $quantityunit->getPropertySets()),
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





my $unit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $unit = Bio::MAGE::Measurement::Unit->new();
}

# testing superclass Unit
isa_ok($unit, q[Bio::MAGE::Measurement::Unit]);
isa_ok($quantityunit, q[Bio::MAGE::Measurement::Unit]);

