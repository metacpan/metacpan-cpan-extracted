##############################
#
# BioDataValues.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioDataValues.t`

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
use Test::More tests => 29;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioDataValues') };

use Bio::MAGE::NameValueType;

use Bio::MAGE::BioAssayData::BioDataCube;
use Bio::MAGE::BioAssayData::BioDataTuples;

# we test the new() method
my $biodatavalues;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatavalues = Bio::MAGE::BioAssayData::BioDataValues->new();
}
isa_ok($biodatavalues, 'Bio::MAGE::BioAssayData::BioDataValues');

# test the package_name class method
is($biodatavalues->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($biodatavalues->class_name(), q[Bio::MAGE::BioAssayData::BioDataValues],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatavalues = Bio::MAGE::BioAssayData::BioDataValues->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioDataValues->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatavalues = Bio::MAGE::BioAssayData::BioDataValues->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($biodatavalues->getPropertySets,'ARRAY')
 and scalar @{$biodatavalues->getPropertySets} == 1
 and UNIVERSAL::isa($biodatavalues->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biodatavalues->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biodatavalues->getPropertySets,'ARRAY')
 and scalar @{$biodatavalues->getPropertySets} == 1
 and $biodatavalues->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biodatavalues->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biodatavalues->getPropertySets,'ARRAY')
 and scalar @{$biodatavalues->getPropertySets} == 2
 and $biodatavalues->getPropertySets->[0] == $propertysets_assn
 and $biodatavalues->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biodatavalues->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biodatavalues->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biodatavalues->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biodatavalues->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biodatavalues->setPropertySets([])};
ok((!$@ and defined $biodatavalues->getPropertySets()
    and UNIVERSAL::isa($biodatavalues->getPropertySets, 'ARRAY')
    and scalar @{$biodatavalues->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biodatavalues->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biodatavalues->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biodatavalues->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biodatavalues->setPropertySets(undef)};
ok((!$@ and not defined $biodatavalues->getPropertySets()),
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
my $biodatacube = Bio::MAGE::BioAssayData::BioDataCube->new();

# testing subclass BioDataCube
isa_ok($biodatacube, q[Bio::MAGE::BioAssayData::BioDataCube]);
isa_ok($biodatacube, q[Bio::MAGE::BioAssayData::BioDataValues]);


# create a subclass
my $biodatatuples = Bio::MAGE::BioAssayData::BioDataTuples->new();

# testing subclass BioDataTuples
isa_ok($biodatatuples, q[Bio::MAGE::BioAssayData::BioDataTuples]);
isa_ok($biodatatuples, q[Bio::MAGE::BioAssayData::BioDataValues]);



my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($biodatavalues, q[Bio::MAGE::Extendable]);

