##############################
#
# TemperatureUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TemperatureUnit.t`

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
use Test::More tests => 41;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::TemperatureUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $temperatureunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $temperatureunit = Bio::MAGE::Measurement::TemperatureUnit->new();
}
isa_ok($temperatureunit, 'Bio::MAGE::Measurement::TemperatureUnit');

# test the package_name class method
is($temperatureunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($temperatureunit->class_name(), q[Bio::MAGE::Measurement::TemperatureUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $temperatureunit = Bio::MAGE::Measurement::TemperatureUnit->new(unitName => '1',
unitNameCV => 'degree_C');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($temperatureunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$temperatureunit->setUnitName('1');
is($temperatureunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$temperatureunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$temperatureunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$temperatureunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$temperatureunit->setUnitName(undef)};
ok((!$@ and not defined $temperatureunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($temperatureunit->getUnitNameCV(), 'degree_C',
  'unitNameCV new');

# test getter/setter
$temperatureunit->setUnitNameCV('degree_C');
is($temperatureunit->getUnitNameCV(), 'degree_C',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$temperatureunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$temperatureunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$temperatureunit->setUnitNameCV('degree_C', 'degree_C')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$temperatureunit->setUnitNameCV(undef)};
ok((!$@ and not defined $temperatureunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$temperatureunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: degree_C

eval {$temperatureunit->setUnitNameCV('degree_C')};
ok((not $@ and $temperatureunit->getUnitNameCV() eq 'degree_C'),
   'unitNameCV accepts degree_C');


# test setter accepts enumerated value: degree_F

eval {$temperatureunit->setUnitNameCV('degree_F')};
ok((not $@ and $temperatureunit->getUnitNameCV() eq 'degree_F'),
   'unitNameCV accepts degree_F');


# test setter accepts enumerated value: K

eval {$temperatureunit->setUnitNameCV('K')};
ok((not $@ and $temperatureunit->getUnitNameCV() eq 'K'),
   'unitNameCV accepts K');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::TemperatureUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $temperatureunit = Bio::MAGE::Measurement::TemperatureUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($temperatureunit->getPropertySets,'ARRAY')
 and scalar @{$temperatureunit->getPropertySets} == 1
 and UNIVERSAL::isa($temperatureunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($temperatureunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($temperatureunit->getPropertySets,'ARRAY')
 and scalar @{$temperatureunit->getPropertySets} == 1
 and $temperatureunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($temperatureunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($temperatureunit->getPropertySets,'ARRAY')
 and scalar @{$temperatureunit->getPropertySets} == 2
 and $temperatureunit->getPropertySets->[0] == $propertysets_assn
 and $temperatureunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$temperatureunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$temperatureunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$temperatureunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$temperatureunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$temperatureunit->setPropertySets([])};
ok((!$@ and defined $temperatureunit->getPropertySets()
    and UNIVERSAL::isa($temperatureunit->getPropertySets, 'ARRAY')
    and scalar @{$temperatureunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$temperatureunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$temperatureunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$temperatureunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$temperatureunit->setPropertySets(undef)};
ok((!$@ and not defined $temperatureunit->getPropertySets()),
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
isa_ok($temperatureunit, q[Bio::MAGE::Measurement::Unit]);

