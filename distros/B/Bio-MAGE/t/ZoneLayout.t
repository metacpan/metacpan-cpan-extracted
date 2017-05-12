##############################
#
# ZoneLayout.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ZoneLayout.t`

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
use Test::More tests => 62;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::ArrayDesign::ZoneLayout') };

use Bio::MAGE::Measurement::DistanceUnit;
use Bio::MAGE::NameValueType;


# we test the new() method
my $zonelayout;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonelayout = Bio::MAGE::ArrayDesign::ZoneLayout->new();
}
isa_ok($zonelayout, 'Bio::MAGE::ArrayDesign::ZoneLayout');

# test the package_name class method
is($zonelayout->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($zonelayout->class_name(), q[Bio::MAGE::ArrayDesign::ZoneLayout],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonelayout = Bio::MAGE::ArrayDesign::ZoneLayout->new(spacingBetweenRows => '1',
numFeaturesPerCol => '2',
numFeaturesPerRow => '3',
spacingBetweenCols => '4');
}


#
# testing attribute spacingBetweenRows
#

# test attribute values can be set in new()
is($zonelayout->getSpacingBetweenRows(), '1',
  'spacingBetweenRows new');

# test getter/setter
$zonelayout->setSpacingBetweenRows('1');
is($zonelayout->getSpacingBetweenRows(), '1',
  'spacingBetweenRows getter/setter');

# test getter throws exception with argument
eval {$zonelayout->getSpacingBetweenRows(1)};
ok($@, 'spacingBetweenRows getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonelayout->setSpacingBetweenRows()};
ok($@, 'spacingBetweenRows setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonelayout->setSpacingBetweenRows('1', '1')};
ok($@, 'spacingBetweenRows setter throws exception with too many argument');

# test setter accepts undef
eval {$zonelayout->setSpacingBetweenRows(undef)};
ok((!$@ and not defined $zonelayout->getSpacingBetweenRows()),
   'spacingBetweenRows setter accepts undef');



#
# testing attribute numFeaturesPerCol
#

# test attribute values can be set in new()
is($zonelayout->getNumFeaturesPerCol(), '2',
  'numFeaturesPerCol new');

# test getter/setter
$zonelayout->setNumFeaturesPerCol('2');
is($zonelayout->getNumFeaturesPerCol(), '2',
  'numFeaturesPerCol getter/setter');

# test getter throws exception with argument
eval {$zonelayout->getNumFeaturesPerCol(1)};
ok($@, 'numFeaturesPerCol getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonelayout->setNumFeaturesPerCol()};
ok($@, 'numFeaturesPerCol setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonelayout->setNumFeaturesPerCol('2', '2')};
ok($@, 'numFeaturesPerCol setter throws exception with too many argument');

# test setter accepts undef
eval {$zonelayout->setNumFeaturesPerCol(undef)};
ok((!$@ and not defined $zonelayout->getNumFeaturesPerCol()),
   'numFeaturesPerCol setter accepts undef');



#
# testing attribute numFeaturesPerRow
#

# test attribute values can be set in new()
is($zonelayout->getNumFeaturesPerRow(), '3',
  'numFeaturesPerRow new');

# test getter/setter
$zonelayout->setNumFeaturesPerRow('3');
is($zonelayout->getNumFeaturesPerRow(), '3',
  'numFeaturesPerRow getter/setter');

# test getter throws exception with argument
eval {$zonelayout->getNumFeaturesPerRow(1)};
ok($@, 'numFeaturesPerRow getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonelayout->setNumFeaturesPerRow()};
ok($@, 'numFeaturesPerRow setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonelayout->setNumFeaturesPerRow('3', '3')};
ok($@, 'numFeaturesPerRow setter throws exception with too many argument');

# test setter accepts undef
eval {$zonelayout->setNumFeaturesPerRow(undef)};
ok((!$@ and not defined $zonelayout->getNumFeaturesPerRow()),
   'numFeaturesPerRow setter accepts undef');



#
# testing attribute spacingBetweenCols
#

# test attribute values can be set in new()
is($zonelayout->getSpacingBetweenCols(), '4',
  'spacingBetweenCols new');

# test getter/setter
$zonelayout->setSpacingBetweenCols('4');
is($zonelayout->getSpacingBetweenCols(), '4',
  'spacingBetweenCols getter/setter');

# test getter throws exception with argument
eval {$zonelayout->getSpacingBetweenCols(1)};
ok($@, 'spacingBetweenCols getter throws exception with argument');

# test setter throws exception with no argument
eval {$zonelayout->setSpacingBetweenCols()};
ok($@, 'spacingBetweenCols setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$zonelayout->setSpacingBetweenCols('4', '4')};
ok($@, 'spacingBetweenCols setter throws exception with too many argument');

# test setter accepts undef
eval {$zonelayout->setSpacingBetweenCols(undef)};
ok((!$@ and not defined $zonelayout->getSpacingBetweenCols()),
   'spacingBetweenCols setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::ZoneLayout->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $zonelayout = Bio::MAGE::ArrayDesign::ZoneLayout->new(distanceUnit => Bio::MAGE::Measurement::DistanceUnit->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association distanceUnit
my $distanceunit_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $distanceunit_assn = Bio::MAGE::Measurement::DistanceUnit->new();
}


isa_ok($zonelayout->getDistanceUnit, q[Bio::MAGE::Measurement::DistanceUnit]);

is($zonelayout->setDistanceUnit($distanceunit_assn), $distanceunit_assn,
  'setDistanceUnit returns value');

ok($zonelayout->getDistanceUnit() == $distanceunit_assn,
   'getDistanceUnit fetches correct value');

# test setDistanceUnit throws exception with bad argument
eval {$zonelayout->setDistanceUnit(1)};
ok($@, 'setDistanceUnit throws exception with bad argument');


# test getDistanceUnit throws exception with argument
eval {$zonelayout->getDistanceUnit(1)};
ok($@, 'getDistanceUnit throws exception with argument');

# test setDistanceUnit throws exception with no argument
eval {$zonelayout->setDistanceUnit()};
ok($@, 'setDistanceUnit throws exception with no argument');

# test setDistanceUnit throws exception with too many argument
eval {$zonelayout->setDistanceUnit(1,2)};
ok($@, 'setDistanceUnit throws exception with too many argument');

# test setDistanceUnit accepts undef
eval {$zonelayout->setDistanceUnit(undef)};
ok((!$@ and not defined $zonelayout->getDistanceUnit()),
   'setDistanceUnit accepts undef');

# test the meta-data for the assoication
$assn = $assns{distanceUnit};
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
   'distanceUnit->other() is a valid Bio::MAGE::Association::End'
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
   'distanceUnit->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($zonelayout->getPropertySets,'ARRAY')
 and scalar @{$zonelayout->getPropertySets} == 1
 and UNIVERSAL::isa($zonelayout->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($zonelayout->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($zonelayout->getPropertySets,'ARRAY')
 and scalar @{$zonelayout->getPropertySets} == 1
 and $zonelayout->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($zonelayout->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($zonelayout->getPropertySets,'ARRAY')
 and scalar @{$zonelayout->getPropertySets} == 2
 and $zonelayout->getPropertySets->[0] == $propertysets_assn
 and $zonelayout->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$zonelayout->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$zonelayout->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$zonelayout->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$zonelayout->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$zonelayout->setPropertySets([])};
ok((!$@ and defined $zonelayout->getPropertySets()
    and UNIVERSAL::isa($zonelayout->getPropertySets, 'ARRAY')
    and scalar @{$zonelayout->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$zonelayout->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$zonelayout->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$zonelayout->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$zonelayout->setPropertySets(undef)};
ok((!$@ and not defined $zonelayout->getPropertySets()),
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
isa_ok($zonelayout, q[Bio::MAGE::Extendable]);

