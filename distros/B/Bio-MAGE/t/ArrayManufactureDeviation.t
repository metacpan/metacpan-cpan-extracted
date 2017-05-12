##############################
#
# ArrayManufactureDeviation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ArrayManufactureDeviation.t`

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
use Test::More tests => 63;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::ArrayManufactureDeviation') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::Array::FeatureDefect;
use Bio::MAGE::Array::ZoneDefect;


# we test the new() method
my $arraymanufacturedeviation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacturedeviation = Bio::MAGE::Array::ArrayManufactureDeviation->new();
}
isa_ok($arraymanufacturedeviation, 'Bio::MAGE::Array::ArrayManufactureDeviation');

# test the package_name class method
is($arraymanufacturedeviation->package_name(), q[Array],
  'package');

# test the class_name class method
is($arraymanufacturedeviation->class_name(), q[Bio::MAGE::Array::ArrayManufactureDeviation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacturedeviation = Bio::MAGE::Array::ArrayManufactureDeviation->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ArrayManufactureDeviation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $arraymanufacturedeviation = Bio::MAGE::Array::ArrayManufactureDeviation->new(adjustments => [Bio::MAGE::Array::ZoneDefect->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
featureDefects => [Bio::MAGE::Array::FeatureDefect->new()]);
}

my ($end, $assn);


# testing association adjustments
my $adjustments_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $adjustments_assn = Bio::MAGE::Array::ZoneDefect->new();
}


ok((UNIVERSAL::isa($arraymanufacturedeviation->getAdjustments,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getAdjustments} == 1
 and UNIVERSAL::isa($arraymanufacturedeviation->getAdjustments->[0], q[Bio::MAGE::Array::ZoneDefect])),
  'adjustments set in new()');

ok(eq_array($arraymanufacturedeviation->setAdjustments([$adjustments_assn]), [$adjustments_assn]),
   'setAdjustments returns correct value');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getAdjustments,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getAdjustments} == 1
 and $arraymanufacturedeviation->getAdjustments->[0] == $adjustments_assn),
   'getAdjustments fetches correct value');

is($arraymanufacturedeviation->addAdjustments($adjustments_assn), 2,
  'addAdjustments returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getAdjustments,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getAdjustments} == 2
 and $arraymanufacturedeviation->getAdjustments->[0] == $adjustments_assn
 and $arraymanufacturedeviation->getAdjustments->[1] == $adjustments_assn),
  'addAdjustments adds correct value');

# test setAdjustments throws exception with non-array argument
eval {$arraymanufacturedeviation->setAdjustments(1)};
ok($@, 'setAdjustments throws exception with non-array argument');

# test setAdjustments throws exception with bad argument array
eval {$arraymanufacturedeviation->setAdjustments([1])};
ok($@, 'setAdjustments throws exception with bad argument array');

# test addAdjustments throws exception with no arguments
eval {$arraymanufacturedeviation->addAdjustments()};
ok($@, 'addAdjustments throws exception with no arguments');

# test addAdjustments throws exception with bad argument
eval {$arraymanufacturedeviation->addAdjustments(1)};
ok($@, 'addAdjustments throws exception with bad array');

# test setAdjustments accepts empty array ref
eval {$arraymanufacturedeviation->setAdjustments([])};
ok((!$@ and defined $arraymanufacturedeviation->getAdjustments()
    and UNIVERSAL::isa($arraymanufacturedeviation->getAdjustments, 'ARRAY')
    and scalar @{$arraymanufacturedeviation->getAdjustments} == 0),
   'setAdjustments accepts empty array ref');


# test getAdjustments throws exception with argument
eval {$arraymanufacturedeviation->getAdjustments(1)};
ok($@, 'getAdjustments throws exception with argument');

# test setAdjustments throws exception with no argument
eval {$arraymanufacturedeviation->setAdjustments()};
ok($@, 'setAdjustments throws exception with no argument');

# test setAdjustments throws exception with too many argument
eval {$arraymanufacturedeviation->setAdjustments(1,2)};
ok($@, 'setAdjustments throws exception with too many argument');

# test setAdjustments accepts undef
eval {$arraymanufacturedeviation->setAdjustments(undef)};
ok((!$@ and not defined $arraymanufacturedeviation->getAdjustments()),
   'setAdjustments accepts undef');

# test the meta-data for the assoication
$assn = $assns{adjustments};
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
   'adjustments->other() is a valid Bio::MAGE::Association::End'
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
   'adjustments->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($arraymanufacturedeviation->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getPropertySets} == 1
 and UNIVERSAL::isa($arraymanufacturedeviation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($arraymanufacturedeviation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getPropertySets} == 1
 and $arraymanufacturedeviation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($arraymanufacturedeviation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getPropertySets,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getPropertySets} == 2
 and $arraymanufacturedeviation->getPropertySets->[0] == $propertysets_assn
 and $arraymanufacturedeviation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$arraymanufacturedeviation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$arraymanufacturedeviation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$arraymanufacturedeviation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$arraymanufacturedeviation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$arraymanufacturedeviation->setPropertySets([])};
ok((!$@ and defined $arraymanufacturedeviation->getPropertySets()
    and UNIVERSAL::isa($arraymanufacturedeviation->getPropertySets, 'ARRAY')
    and scalar @{$arraymanufacturedeviation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$arraymanufacturedeviation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$arraymanufacturedeviation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$arraymanufacturedeviation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$arraymanufacturedeviation->setPropertySets(undef)};
ok((!$@ and not defined $arraymanufacturedeviation->getPropertySets()),
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



# testing association featureDefects
my $featuredefects_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredefects_assn = Bio::MAGE::Array::FeatureDefect->new();
}


ok((UNIVERSAL::isa($arraymanufacturedeviation->getFeatureDefects,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getFeatureDefects} == 1
 and UNIVERSAL::isa($arraymanufacturedeviation->getFeatureDefects->[0], q[Bio::MAGE::Array::FeatureDefect])),
  'featureDefects set in new()');

ok(eq_array($arraymanufacturedeviation->setFeatureDefects([$featuredefects_assn]), [$featuredefects_assn]),
   'setFeatureDefects returns correct value');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getFeatureDefects,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getFeatureDefects} == 1
 and $arraymanufacturedeviation->getFeatureDefects->[0] == $featuredefects_assn),
   'getFeatureDefects fetches correct value');

is($arraymanufacturedeviation->addFeatureDefects($featuredefects_assn), 2,
  'addFeatureDefects returns number of items in list');

ok((UNIVERSAL::isa($arraymanufacturedeviation->getFeatureDefects,'ARRAY')
 and scalar @{$arraymanufacturedeviation->getFeatureDefects} == 2
 and $arraymanufacturedeviation->getFeatureDefects->[0] == $featuredefects_assn
 and $arraymanufacturedeviation->getFeatureDefects->[1] == $featuredefects_assn),
  'addFeatureDefects adds correct value');

# test setFeatureDefects throws exception with non-array argument
eval {$arraymanufacturedeviation->setFeatureDefects(1)};
ok($@, 'setFeatureDefects throws exception with non-array argument');

# test setFeatureDefects throws exception with bad argument array
eval {$arraymanufacturedeviation->setFeatureDefects([1])};
ok($@, 'setFeatureDefects throws exception with bad argument array');

# test addFeatureDefects throws exception with no arguments
eval {$arraymanufacturedeviation->addFeatureDefects()};
ok($@, 'addFeatureDefects throws exception with no arguments');

# test addFeatureDefects throws exception with bad argument
eval {$arraymanufacturedeviation->addFeatureDefects(1)};
ok($@, 'addFeatureDefects throws exception with bad array');

# test setFeatureDefects accepts empty array ref
eval {$arraymanufacturedeviation->setFeatureDefects([])};
ok((!$@ and defined $arraymanufacturedeviation->getFeatureDefects()
    and UNIVERSAL::isa($arraymanufacturedeviation->getFeatureDefects, 'ARRAY')
    and scalar @{$arraymanufacturedeviation->getFeatureDefects} == 0),
   'setFeatureDefects accepts empty array ref');


# test getFeatureDefects throws exception with argument
eval {$arraymanufacturedeviation->getFeatureDefects(1)};
ok($@, 'getFeatureDefects throws exception with argument');

# test setFeatureDefects throws exception with no argument
eval {$arraymanufacturedeviation->setFeatureDefects()};
ok($@, 'setFeatureDefects throws exception with no argument');

# test setFeatureDefects throws exception with too many argument
eval {$arraymanufacturedeviation->setFeatureDefects(1,2)};
ok($@, 'setFeatureDefects throws exception with too many argument');

# test setFeatureDefects accepts undef
eval {$arraymanufacturedeviation->setFeatureDefects(undef)};
ok((!$@ and not defined $arraymanufacturedeviation->getFeatureDefects()),
   'setFeatureDefects accepts undef');

# test the meta-data for the assoication
$assn = $assns{featureDefects};
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
   'featureDefects->other() is a valid Bio::MAGE::Association::End'
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
   'featureDefects->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($arraymanufacturedeviation, q[Bio::MAGE::Extendable]);

