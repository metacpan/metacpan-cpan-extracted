##############################
#
# Measurement.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Measurement.t`

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
use Test::More tests => 74;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::Measurement') };

use Bio::MAGE::Measurement::Unit;
use Bio::MAGE::NameValueType;


# we test the new() method
my $measurement;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement = Bio::MAGE::Measurement::Measurement->new();
}
isa_ok($measurement, 'Bio::MAGE::Measurement::Measurement');

# test the package_name class method
is($measurement->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($measurement->class_name(), q[Bio::MAGE::Measurement::Measurement],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement = Bio::MAGE::Measurement::Measurement->new(value => '1',
otherKind => '2',
type => 'absolute',
kindCV => 'time');
}


#
# testing attribute value
#

# test attribute values can be set in new()
is($measurement->getValue(), '1',
  'value new');

# test getter/setter
$measurement->setValue('1');
is($measurement->getValue(), '1',
  'value getter/setter');

# test getter throws exception with argument
eval {$measurement->getValue(1)};
ok($@, 'value getter throws exception with argument');

# test setter throws exception with no argument
eval {$measurement->setValue()};
ok($@, 'value setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measurement->setValue('1', '1')};
ok($@, 'value setter throws exception with too many argument');

# test setter accepts undef
eval {$measurement->setValue(undef)};
ok((!$@ and not defined $measurement->getValue()),
   'value setter accepts undef');



#
# testing attribute otherKind
#

# test attribute values can be set in new()
is($measurement->getOtherKind(), '2',
  'otherKind new');

# test getter/setter
$measurement->setOtherKind('2');
is($measurement->getOtherKind(), '2',
  'otherKind getter/setter');

# test getter throws exception with argument
eval {$measurement->getOtherKind(1)};
ok($@, 'otherKind getter throws exception with argument');

# test setter throws exception with no argument
eval {$measurement->setOtherKind()};
ok($@, 'otherKind setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measurement->setOtherKind('2', '2')};
ok($@, 'otherKind setter throws exception with too many argument');

# test setter accepts undef
eval {$measurement->setOtherKind(undef)};
ok((!$@ and not defined $measurement->getOtherKind()),
   'otherKind setter accepts undef');



#
# testing attribute type
#

# test attribute values can be set in new()
is($measurement->getType(), 'absolute',
  'type new');

# test getter/setter
$measurement->setType('absolute');
is($measurement->getType(), 'absolute',
  'type getter/setter');

# test getter throws exception with argument
eval {$measurement->getType(1)};
ok($@, 'type getter throws exception with argument');

# test setter throws exception with no argument
eval {$measurement->setType()};
ok($@, 'type setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measurement->setType('absolute', 'absolute')};
ok($@, 'type setter throws exception with too many argument');

# test setter accepts undef
eval {$measurement->setType(undef)};
ok((!$@ and not defined $measurement->getType()),
   'type setter accepts undef');


# test setter throws exception with bad argument
eval {$measurement->setType(1)};
ok($@, 'type setter throws exception with bad argument');


# test setter accepts enumerated value: absolute

eval {$measurement->setType('absolute')};
ok((not $@ and $measurement->getType() eq 'absolute'),
   'type accepts absolute');


# test setter accepts enumerated value: change

eval {$measurement->setType('change')};
ok((not $@ and $measurement->getType() eq 'change'),
   'type accepts change');



#
# testing attribute kindCV
#

# test attribute values can be set in new()
is($measurement->getKindCV(), 'time',
  'kindCV new');

# test getter/setter
$measurement->setKindCV('time');
is($measurement->getKindCV(), 'time',
  'kindCV getter/setter');

# test getter throws exception with argument
eval {$measurement->getKindCV(1)};
ok($@, 'kindCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$measurement->setKindCV()};
ok($@, 'kindCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$measurement->setKindCV('time', 'time')};
ok($@, 'kindCV setter throws exception with too many argument');

# test setter accepts undef
eval {$measurement->setKindCV(undef)};
ok((!$@ and not defined $measurement->getKindCV()),
   'kindCV setter accepts undef');


# test setter throws exception with bad argument
eval {$measurement->setKindCV(1)};
ok($@, 'kindCV setter throws exception with bad argument');


# test setter accepts enumerated value: time

eval {$measurement->setKindCV('time')};
ok((not $@ and $measurement->getKindCV() eq 'time'),
   'kindCV accepts time');


# test setter accepts enumerated value: distance

eval {$measurement->setKindCV('distance')};
ok((not $@ and $measurement->getKindCV() eq 'distance'),
   'kindCV accepts distance');


# test setter accepts enumerated value: temperature

eval {$measurement->setKindCV('temperature')};
ok((not $@ and $measurement->getKindCV() eq 'temperature'),
   'kindCV accepts temperature');


# test setter accepts enumerated value: quantity

eval {$measurement->setKindCV('quantity')};
ok((not $@ and $measurement->getKindCV() eq 'quantity'),
   'kindCV accepts quantity');


# test setter accepts enumerated value: mass

eval {$measurement->setKindCV('mass')};
ok((not $@ and $measurement->getKindCV() eq 'mass'),
   'kindCV accepts mass');


# test setter accepts enumerated value: volume

eval {$measurement->setKindCV('volume')};
ok((not $@ and $measurement->getKindCV() eq 'volume'),
   'kindCV accepts volume');


# test setter accepts enumerated value: concentration

eval {$measurement->setKindCV('concentration')};
ok((not $@ and $measurement->getKindCV() eq 'concentration'),
   'kindCV accepts concentration');


# test setter accepts enumerated value: other

eval {$measurement->setKindCV('other')};
ok((not $@ and $measurement->getKindCV() eq 'other'),
   'kindCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::Measurement->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $measurement = Bio::MAGE::Measurement::Measurement->new(unit => Bio::MAGE::Measurement::Unit->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association unit
my $unit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $unit_assn = Bio::MAGE::Measurement::Unit->new();
}


isa_ok($measurement->getUnit, q[Bio::MAGE::Measurement::Unit]);

is($measurement->setUnit($unit_assn), $unit_assn,
  'setUnit returns value');

ok($measurement->getUnit() == $unit_assn,
   'getUnit fetches correct value');

# test setUnit throws exception with bad argument
eval {$measurement->setUnit(1)};
ok($@, 'setUnit throws exception with bad argument');


# test getUnit throws exception with argument
eval {$measurement->getUnit(1)};
ok($@, 'getUnit throws exception with argument');

# test setUnit throws exception with no argument
eval {$measurement->setUnit()};
ok($@, 'setUnit throws exception with no argument');

# test setUnit throws exception with too many argument
eval {$measurement->setUnit(1,2)};
ok($@, 'setUnit throws exception with too many argument');

# test setUnit accepts undef
eval {$measurement->setUnit(undef)};
ok((!$@ and not defined $measurement->getUnit()),
   'setUnit accepts undef');

# test the meta-data for the assoication
$assn = $assns{unit};
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
   'unit->other() is a valid Bio::MAGE::Association::End'
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
   'unit->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($measurement->getPropertySets,'ARRAY')
 and scalar @{$measurement->getPropertySets} == 1
 and UNIVERSAL::isa($measurement->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($measurement->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($measurement->getPropertySets,'ARRAY')
 and scalar @{$measurement->getPropertySets} == 1
 and $measurement->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($measurement->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($measurement->getPropertySets,'ARRAY')
 and scalar @{$measurement->getPropertySets} == 2
 and $measurement->getPropertySets->[0] == $propertysets_assn
 and $measurement->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$measurement->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$measurement->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$measurement->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$measurement->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$measurement->setPropertySets([])};
ok((!$@ and defined $measurement->getPropertySets()
    and UNIVERSAL::isa($measurement->getPropertySets, 'ARRAY')
    and scalar @{$measurement->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$measurement->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$measurement->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$measurement->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$measurement->setPropertySets(undef)};
ok((!$@ and not defined $measurement->getPropertySets()),
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
isa_ok($measurement, q[Bio::MAGE::Extendable]);

