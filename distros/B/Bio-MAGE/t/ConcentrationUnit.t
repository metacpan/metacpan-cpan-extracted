##############################
#
# ConcentrationUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ConcentrationUnit.t`

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

BEGIN { use_ok('Bio::MAGE::Measurement::ConcentrationUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $concentrationunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $concentrationunit = Bio::MAGE::Measurement::ConcentrationUnit->new();
}
isa_ok($concentrationunit, 'Bio::MAGE::Measurement::ConcentrationUnit');

# test the package_name class method
is($concentrationunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($concentrationunit->class_name(), q[Bio::MAGE::Measurement::ConcentrationUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $concentrationunit = Bio::MAGE::Measurement::ConcentrationUnit->new(unitName => '1',
unitNameCV => 'M');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($concentrationunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$concentrationunit->setUnitName('1');
is($concentrationunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$concentrationunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$concentrationunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$concentrationunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$concentrationunit->setUnitName(undef)};
ok((!$@ and not defined $concentrationunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($concentrationunit->getUnitNameCV(), 'M',
  'unitNameCV new');

# test getter/setter
$concentrationunit->setUnitNameCV('M');
is($concentrationunit->getUnitNameCV(), 'M',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$concentrationunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$concentrationunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$concentrationunit->setUnitNameCV('M', 'M')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$concentrationunit->setUnitNameCV(undef)};
ok((!$@ and not defined $concentrationunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$concentrationunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: M

eval {$concentrationunit->setUnitNameCV('M')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'M'),
   'unitNameCV accepts M');


# test setter accepts enumerated value: mM

eval {$concentrationunit->setUnitNameCV('mM')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'mM'),
   'unitNameCV accepts mM');


# test setter accepts enumerated value: uM

eval {$concentrationunit->setUnitNameCV('uM')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'uM'),
   'unitNameCV accepts uM');


# test setter accepts enumerated value: nM

eval {$concentrationunit->setUnitNameCV('nM')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'nM'),
   'unitNameCV accepts nM');


# test setter accepts enumerated value: pM

eval {$concentrationunit->setUnitNameCV('pM')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'pM'),
   'unitNameCV accepts pM');


# test setter accepts enumerated value: fM

eval {$concentrationunit->setUnitNameCV('fM')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'fM'),
   'unitNameCV accepts fM');


# test setter accepts enumerated value: mg_per_mL

eval {$concentrationunit->setUnitNameCV('mg_per_mL')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'mg_per_mL'),
   'unitNameCV accepts mg_per_mL');


# test setter accepts enumerated value: mL_per_L

eval {$concentrationunit->setUnitNameCV('mL_per_L')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'mL_per_L'),
   'unitNameCV accepts mL_per_L');


# test setter accepts enumerated value: g_per_L

eval {$concentrationunit->setUnitNameCV('g_per_L')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'g_per_L'),
   'unitNameCV accepts g_per_L');


# test setter accepts enumerated value: gram_percent

eval {$concentrationunit->setUnitNameCV('gram_percent')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'gram_percent'),
   'unitNameCV accepts gram_percent');


# test setter accepts enumerated value: mass_per_volume_percent

eval {$concentrationunit->setUnitNameCV('mass_per_volume_percent')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'mass_per_volume_percent'),
   'unitNameCV accepts mass_per_volume_percent');


# test setter accepts enumerated value: mass_per_mass_percent

eval {$concentrationunit->setUnitNameCV('mass_per_mass_percent')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'mass_per_mass_percent'),
   'unitNameCV accepts mass_per_mass_percent');


# test setter accepts enumerated value: other

eval {$concentrationunit->setUnitNameCV('other')};
ok((not $@ and $concentrationunit->getUnitNameCV() eq 'other'),
   'unitNameCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::ConcentrationUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $concentrationunit = Bio::MAGE::Measurement::ConcentrationUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($concentrationunit->getPropertySets,'ARRAY')
 and scalar @{$concentrationunit->getPropertySets} == 1
 and UNIVERSAL::isa($concentrationunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($concentrationunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($concentrationunit->getPropertySets,'ARRAY')
 and scalar @{$concentrationunit->getPropertySets} == 1
 and $concentrationunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($concentrationunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($concentrationunit->getPropertySets,'ARRAY')
 and scalar @{$concentrationunit->getPropertySets} == 2
 and $concentrationunit->getPropertySets->[0] == $propertysets_assn
 and $concentrationunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$concentrationunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$concentrationunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$concentrationunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$concentrationunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$concentrationunit->setPropertySets([])};
ok((!$@ and defined $concentrationunit->getPropertySets()
    and UNIVERSAL::isa($concentrationunit->getPropertySets, 'ARRAY')
    and scalar @{$concentrationunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$concentrationunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$concentrationunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$concentrationunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$concentrationunit->setPropertySets(undef)};
ok((!$@ and not defined $concentrationunit->getPropertySets()),
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
isa_ok($concentrationunit, q[Bio::MAGE::Measurement::Unit]);

