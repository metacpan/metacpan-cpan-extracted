##############################
#
# MassUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MassUnit.t`

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
use Test::More tests => 46;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::MassUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $massunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $massunit = Bio::MAGE::Measurement::MassUnit->new();
}
isa_ok($massunit, 'Bio::MAGE::Measurement::MassUnit');

# test the package_name class method
is($massunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($massunit->class_name(), q[Bio::MAGE::Measurement::MassUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $massunit = Bio::MAGE::Measurement::MassUnit->new(unitName => '1',
unitNameCV => 'kg');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($massunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$massunit->setUnitName('1');
is($massunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$massunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$massunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$massunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$massunit->setUnitName(undef)};
ok((!$@ and not defined $massunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($massunit->getUnitNameCV(), 'kg',
  'unitNameCV new');

# test getter/setter
$massunit->setUnitNameCV('kg');
is($massunit->getUnitNameCV(), 'kg',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$massunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$massunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$massunit->setUnitNameCV('kg', 'kg')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$massunit->setUnitNameCV(undef)};
ok((!$@ and not defined $massunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$massunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: kg

eval {$massunit->setUnitNameCV('kg')};
ok((not $@ and $massunit->getUnitNameCV() eq 'kg'),
   'unitNameCV accepts kg');


# test setter accepts enumerated value: g

eval {$massunit->setUnitNameCV('g')};
ok((not $@ and $massunit->getUnitNameCV() eq 'g'),
   'unitNameCV accepts g');


# test setter accepts enumerated value: mg

eval {$massunit->setUnitNameCV('mg')};
ok((not $@ and $massunit->getUnitNameCV() eq 'mg'),
   'unitNameCV accepts mg');


# test setter accepts enumerated value: ug

eval {$massunit->setUnitNameCV('ug')};
ok((not $@ and $massunit->getUnitNameCV() eq 'ug'),
   'unitNameCV accepts ug');


# test setter accepts enumerated value: ng

eval {$massunit->setUnitNameCV('ng')};
ok((not $@ and $massunit->getUnitNameCV() eq 'ng'),
   'unitNameCV accepts ng');


# test setter accepts enumerated value: pg

eval {$massunit->setUnitNameCV('pg')};
ok((not $@ and $massunit->getUnitNameCV() eq 'pg'),
   'unitNameCV accepts pg');


# test setter accepts enumerated value: fg

eval {$massunit->setUnitNameCV('fg')};
ok((not $@ and $massunit->getUnitNameCV() eq 'fg'),
   'unitNameCV accepts fg');


# test setter accepts enumerated value: other

eval {$massunit->setUnitNameCV('other')};
ok((not $@ and $massunit->getUnitNameCV() eq 'other'),
   'unitNameCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::MassUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $massunit = Bio::MAGE::Measurement::MassUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($massunit->getPropertySets,'ARRAY')
 and scalar @{$massunit->getPropertySets} == 1
 and UNIVERSAL::isa($massunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($massunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($massunit->getPropertySets,'ARRAY')
 and scalar @{$massunit->getPropertySets} == 1
 and $massunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($massunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($massunit->getPropertySets,'ARRAY')
 and scalar @{$massunit->getPropertySets} == 2
 and $massunit->getPropertySets->[0] == $propertysets_assn
 and $massunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$massunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$massunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$massunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$massunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$massunit->setPropertySets([])};
ok((!$@ and defined $massunit->getPropertySets()
    and UNIVERSAL::isa($massunit->getPropertySets, 'ARRAY')
    and scalar @{$massunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$massunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$massunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$massunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$massunit->setPropertySets(undef)};
ok((!$@ and not defined $massunit->getPropertySets()),
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
isa_ok($massunit, q[Bio::MAGE::Measurement::Unit]);

