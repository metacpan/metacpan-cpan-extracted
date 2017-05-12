##############################
#
# VolumeUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VolumeUnit.t`

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

BEGIN { use_ok('Bio::MAGE::Measurement::VolumeUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $volumeunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $volumeunit = Bio::MAGE::Measurement::VolumeUnit->new();
}
isa_ok($volumeunit, 'Bio::MAGE::Measurement::VolumeUnit');

# test the package_name class method
is($volumeunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($volumeunit->class_name(), q[Bio::MAGE::Measurement::VolumeUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $volumeunit = Bio::MAGE::Measurement::VolumeUnit->new(unitName => '1',
unitNameCV => 'mL');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($volumeunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$volumeunit->setUnitName('1');
is($volumeunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$volumeunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$volumeunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$volumeunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$volumeunit->setUnitName(undef)};
ok((!$@ and not defined $volumeunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($volumeunit->getUnitNameCV(), 'mL',
  'unitNameCV new');

# test getter/setter
$volumeunit->setUnitNameCV('mL');
is($volumeunit->getUnitNameCV(), 'mL',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$volumeunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$volumeunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$volumeunit->setUnitNameCV('mL', 'mL')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$volumeunit->setUnitNameCV(undef)};
ok((!$@ and not defined $volumeunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$volumeunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: mL

eval {$volumeunit->setUnitNameCV('mL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'mL'),
   'unitNameCV accepts mL');


# test setter accepts enumerated value: cc

eval {$volumeunit->setUnitNameCV('cc')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'cc'),
   'unitNameCV accepts cc');


# test setter accepts enumerated value: dL

eval {$volumeunit->setUnitNameCV('dL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'dL'),
   'unitNameCV accepts dL');


# test setter accepts enumerated value: L

eval {$volumeunit->setUnitNameCV('L')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'L'),
   'unitNameCV accepts L');


# test setter accepts enumerated value: uL

eval {$volumeunit->setUnitNameCV('uL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'uL'),
   'unitNameCV accepts uL');


# test setter accepts enumerated value: nL

eval {$volumeunit->setUnitNameCV('nL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'nL'),
   'unitNameCV accepts nL');


# test setter accepts enumerated value: pL

eval {$volumeunit->setUnitNameCV('pL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'pL'),
   'unitNameCV accepts pL');


# test setter accepts enumerated value: fL

eval {$volumeunit->setUnitNameCV('fL')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'fL'),
   'unitNameCV accepts fL');


# test setter accepts enumerated value: other

eval {$volumeunit->setUnitNameCV('other')};
ok((not $@ and $volumeunit->getUnitNameCV() eq 'other'),
   'unitNameCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::VolumeUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $volumeunit = Bio::MAGE::Measurement::VolumeUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($volumeunit->getPropertySets,'ARRAY')
 and scalar @{$volumeunit->getPropertySets} == 1
 and UNIVERSAL::isa($volumeunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($volumeunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($volumeunit->getPropertySets,'ARRAY')
 and scalar @{$volumeunit->getPropertySets} == 1
 and $volumeunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($volumeunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($volumeunit->getPropertySets,'ARRAY')
 and scalar @{$volumeunit->getPropertySets} == 2
 and $volumeunit->getPropertySets->[0] == $propertysets_assn
 and $volumeunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$volumeunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$volumeunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$volumeunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$volumeunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$volumeunit->setPropertySets([])};
ok((!$@ and defined $volumeunit->getPropertySets()
    and UNIVERSAL::isa($volumeunit->getPropertySets, 'ARRAY')
    and scalar @{$volumeunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$volumeunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$volumeunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$volumeunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$volumeunit->setPropertySets(undef)};
ok((!$@ and not defined $volumeunit->getPropertySets()),
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
isa_ok($volumeunit, q[Bio::MAGE::Measurement::Unit]);

