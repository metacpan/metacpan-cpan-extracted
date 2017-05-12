##############################
#
# FeatureDefect.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureDefect.t`

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
use Test::More tests => 64;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::FeatureDefect') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Array::PositionDelta;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;


# we test the new() method
my $featuredefect;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredefect = Bio::MAGE::Array::FeatureDefect->new();
}
isa_ok($featuredefect, 'Bio::MAGE::Array::FeatureDefect');

# test the package_name class method
is($featuredefect->package_name(), q[Array],
  'package');

# test the class_name class method
is($featuredefect->class_name(), q[Bio::MAGE::Array::FeatureDefect],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredefect = Bio::MAGE::Array::FeatureDefect->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::FeatureDefect->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredefect = Bio::MAGE::Array::FeatureDefect->new(positionDelta => Bio::MAGE::Array::PositionDelta->new(),
feature => Bio::MAGE::DesignElement::Feature->new(),
defectType => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association positionDelta
my $positiondelta_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $positiondelta_assn = Bio::MAGE::Array::PositionDelta->new();
}


isa_ok($featuredefect->getPositionDelta, q[Bio::MAGE::Array::PositionDelta]);

is($featuredefect->setPositionDelta($positiondelta_assn), $positiondelta_assn,
  'setPositionDelta returns value');

ok($featuredefect->getPositionDelta() == $positiondelta_assn,
   'getPositionDelta fetches correct value');

# test setPositionDelta throws exception with bad argument
eval {$featuredefect->setPositionDelta(1)};
ok($@, 'setPositionDelta throws exception with bad argument');


# test getPositionDelta throws exception with argument
eval {$featuredefect->getPositionDelta(1)};
ok($@, 'getPositionDelta throws exception with argument');

# test setPositionDelta throws exception with no argument
eval {$featuredefect->setPositionDelta()};
ok($@, 'setPositionDelta throws exception with no argument');

# test setPositionDelta throws exception with too many argument
eval {$featuredefect->setPositionDelta(1,2)};
ok($@, 'setPositionDelta throws exception with too many argument');

# test setPositionDelta accepts undef
eval {$featuredefect->setPositionDelta(undef)};
ok((!$@ and not defined $featuredefect->getPositionDelta()),
   'setPositionDelta accepts undef');

# test the meta-data for the assoication
$assn = $assns{positionDelta};
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
   'positionDelta->other() is a valid Bio::MAGE::Association::End'
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
   'positionDelta->self() is a valid Bio::MAGE::Association::End'
  );



# testing association feature
my $feature_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature_assn = Bio::MAGE::DesignElement::Feature->new();
}


isa_ok($featuredefect->getFeature, q[Bio::MAGE::DesignElement::Feature]);

is($featuredefect->setFeature($feature_assn), $feature_assn,
  'setFeature returns value');

ok($featuredefect->getFeature() == $feature_assn,
   'getFeature fetches correct value');

# test setFeature throws exception with bad argument
eval {$featuredefect->setFeature(1)};
ok($@, 'setFeature throws exception with bad argument');


# test getFeature throws exception with argument
eval {$featuredefect->getFeature(1)};
ok($@, 'getFeature throws exception with argument');

# test setFeature throws exception with no argument
eval {$featuredefect->setFeature()};
ok($@, 'setFeature throws exception with no argument');

# test setFeature throws exception with too many argument
eval {$featuredefect->setFeature(1,2)};
ok($@, 'setFeature throws exception with too many argument');

# test setFeature accepts undef
eval {$featuredefect->setFeature(undef)};
ok((!$@ and not defined $featuredefect->getFeature()),
   'setFeature accepts undef');

# test the meta-data for the assoication
$assn = $assns{feature};
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
   'feature->other() is a valid Bio::MAGE::Association::End'
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
   'feature->self() is a valid Bio::MAGE::Association::End'
  );



# testing association defectType
my $defecttype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $defecttype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($featuredefect->getDefectType, q[Bio::MAGE::Description::OntologyEntry]);

is($featuredefect->setDefectType($defecttype_assn), $defecttype_assn,
  'setDefectType returns value');

ok($featuredefect->getDefectType() == $defecttype_assn,
   'getDefectType fetches correct value');

# test setDefectType throws exception with bad argument
eval {$featuredefect->setDefectType(1)};
ok($@, 'setDefectType throws exception with bad argument');


# test getDefectType throws exception with argument
eval {$featuredefect->getDefectType(1)};
ok($@, 'getDefectType throws exception with argument');

# test setDefectType throws exception with no argument
eval {$featuredefect->setDefectType()};
ok($@, 'setDefectType throws exception with no argument');

# test setDefectType throws exception with too many argument
eval {$featuredefect->setDefectType(1,2)};
ok($@, 'setDefectType throws exception with too many argument');

# test setDefectType accepts undef
eval {$featuredefect->setDefectType(undef)};
ok((!$@ and not defined $featuredefect->getDefectType()),
   'setDefectType accepts undef');

# test the meta-data for the assoication
$assn = $assns{defectType};
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
   'defectType->other() is a valid Bio::MAGE::Association::End'
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
   'defectType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($featuredefect->getPropertySets,'ARRAY')
 and scalar @{$featuredefect->getPropertySets} == 1
 and UNIVERSAL::isa($featuredefect->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featuredefect->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featuredefect->getPropertySets,'ARRAY')
 and scalar @{$featuredefect->getPropertySets} == 1
 and $featuredefect->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featuredefect->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featuredefect->getPropertySets,'ARRAY')
 and scalar @{$featuredefect->getPropertySets} == 2
 and $featuredefect->getPropertySets->[0] == $propertysets_assn
 and $featuredefect->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featuredefect->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featuredefect->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featuredefect->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featuredefect->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featuredefect->setPropertySets([])};
ok((!$@ and defined $featuredefect->getPropertySets()
    and UNIVERSAL::isa($featuredefect->getPropertySets, 'ARRAY')
    and scalar @{$featuredefect->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featuredefect->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featuredefect->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featuredefect->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featuredefect->setPropertySets(undef)};
ok((!$@ and not defined $featuredefect->getPropertySets()),
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
isa_ok($featuredefect, q[Bio::MAGE::Extendable]);

