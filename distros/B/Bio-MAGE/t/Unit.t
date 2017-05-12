##############################
#
# Unit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unit.t`

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
use Test::More tests => 45;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::Unit') };

use Bio::MAGE::NameValueType;

use Bio::MAGE::Measurement::TimeUnit;
use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::Measurement::TemperatureUnit;
use Bio::MAGE::Measurement::QuantityUnit;
use Bio::MAGE::Measurement::MassUnit;
use Bio::MAGE::Measurement::VolumeUnit;
use Bio::MAGE::Measurement::ConcentrationUnit;

# we test the new() method
my $unit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $unit = Bio::MAGE::Measurement::Unit->new();
}
isa_ok($unit, 'Bio::MAGE::Measurement::Unit');

# test the package_name class method
is($unit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($unit->class_name(), q[Bio::MAGE::Measurement::Unit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $unit = Bio::MAGE::Measurement::Unit->new(unitName => '1');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($unit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$unit->setUnitName('1');
is($unit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$unit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$unit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$unit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$unit->setUnitName(undef)};
ok((!$@ and not defined $unit->getUnitName()),
   'unitName setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::Unit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $unit = Bio::MAGE::Measurement::Unit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($unit->getPropertySets,'ARRAY')
 and scalar @{$unit->getPropertySets} == 1
 and UNIVERSAL::isa($unit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($unit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($unit->getPropertySets,'ARRAY')
 and scalar @{$unit->getPropertySets} == 1
 and $unit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($unit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($unit->getPropertySets,'ARRAY')
 and scalar @{$unit->getPropertySets} == 2
 and $unit->getPropertySets->[0] == $propertysets_assn
 and $unit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$unit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$unit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$unit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$unit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$unit->setPropertySets([])};
ok((!$@ and defined $unit->getPropertySets()
    and UNIVERSAL::isa($unit->getPropertySets, 'ARRAY')
    and scalar @{$unit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$unit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$unit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$unit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$unit->setPropertySets(undef)};
ok((!$@ and not defined $unit->getPropertySets()),
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




# create a subclass
my $timeunit = Bio::MAGE::Measurement::TimeUnit->new();

# testing subclass TimeUnit
isa_ok($timeunit, q[Bio::MAGE::Measurement::TimeUnit]);
isa_ok($timeunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $distanceunit = Bio::MAGE::Measurement::DistanceUnit->new();

# testing subclass DistanceUnit
isa_ok($distanceunit, q[Bio::MAGE::Measurement::DistanceUnit]);
isa_ok($distanceunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $temperatureunit = Bio::MAGE::Measurement::TemperatureUnit->new();

# testing subclass TemperatureUnit
isa_ok($temperatureunit, q[Bio::MAGE::Measurement::TemperatureUnit]);
isa_ok($temperatureunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new();

# testing subclass QuantityUnit
isa_ok($quantityunit, q[Bio::MAGE::Measurement::QuantityUnit]);
isa_ok($quantityunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $massunit = Bio::MAGE::Measurement::MassUnit->new();

# testing subclass MassUnit
isa_ok($massunit, q[Bio::MAGE::Measurement::MassUnit]);
isa_ok($massunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $volumeunit = Bio::MAGE::Measurement::VolumeUnit->new();

# testing subclass VolumeUnit
isa_ok($volumeunit, q[Bio::MAGE::Measurement::VolumeUnit]);
isa_ok($volumeunit, q[Bio::MAGE::Measurement::Unit]);


# create a subclass
my $concentrationunit = Bio::MAGE::Measurement::ConcentrationUnit->new();

# testing subclass ConcentrationUnit
isa_ok($concentrationunit, q[Bio::MAGE::Measurement::ConcentrationUnit]);
isa_ok($concentrationunit, q[Bio::MAGE::Measurement::Unit]);



my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($unit, q[Bio::MAGE::Extendable]);

