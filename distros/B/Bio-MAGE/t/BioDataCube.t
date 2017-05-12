##############################
#
# BioDataCube.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioDataCube.t`

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
use Test::More tests => 44;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioDataCube') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $biodatacube;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatacube = Bio::MAGE::BioAssayData::BioDataCube->new();
}
isa_ok($biodatacube, 'Bio::MAGE::BioAssayData::BioDataCube');

# test the package_name class method
is($biodatacube->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($biodatacube->class_name(), q[Bio::MAGE::BioAssayData::BioDataCube],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatacube = Bio::MAGE::BioAssayData::BioDataCube->new(cube => '1',
order => 'BDQ');
}


#
# testing attribute cube
#

# test attribute values can be set in new()
is($biodatacube->getCube(), '1',
  'cube new');

# test getter/setter
$biodatacube->setCube('1');
is($biodatacube->getCube(), '1',
  'cube getter/setter');

# test getter throws exception with argument
eval {$biodatacube->getCube(1)};
ok($@, 'cube getter throws exception with argument');

# test setter throws exception with no argument
eval {$biodatacube->setCube()};
ok($@, 'cube setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biodatacube->setCube('1', '1')};
ok($@, 'cube setter throws exception with too many argument');

# test setter accepts undef
eval {$biodatacube->setCube(undef)};
ok((!$@ and not defined $biodatacube->getCube()),
   'cube setter accepts undef');



#
# testing attribute order
#

# test attribute values can be set in new()
is($biodatacube->getOrder(), 'BDQ',
  'order new');

# test getter/setter
$biodatacube->setOrder('BDQ');
is($biodatacube->getOrder(), 'BDQ',
  'order getter/setter');

# test getter throws exception with argument
eval {$biodatacube->getOrder(1)};
ok($@, 'order getter throws exception with argument');

# test setter throws exception with no argument
eval {$biodatacube->setOrder()};
ok($@, 'order setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biodatacube->setOrder('BDQ', 'BDQ')};
ok($@, 'order setter throws exception with too many argument');

# test setter accepts undef
eval {$biodatacube->setOrder(undef)};
ok((!$@ and not defined $biodatacube->getOrder()),
   'order setter accepts undef');


# test setter throws exception with bad argument
eval {$biodatacube->setOrder(1)};
ok($@, 'order setter throws exception with bad argument');


# test setter accepts enumerated value: BDQ

eval {$biodatacube->setOrder('BDQ')};
ok((not $@ and $biodatacube->getOrder() eq 'BDQ'),
   'order accepts BDQ');


# test setter accepts enumerated value: BQD

eval {$biodatacube->setOrder('BQD')};
ok((not $@ and $biodatacube->getOrder() eq 'BQD'),
   'order accepts BQD');


# test setter accepts enumerated value: DBQ

eval {$biodatacube->setOrder('DBQ')};
ok((not $@ and $biodatacube->getOrder() eq 'DBQ'),
   'order accepts DBQ');


# test setter accepts enumerated value: DQB

eval {$biodatacube->setOrder('DQB')};
ok((not $@ and $biodatacube->getOrder() eq 'DQB'),
   'order accepts DQB');


# test setter accepts enumerated value: QBD

eval {$biodatacube->setOrder('QBD')};
ok((not $@ and $biodatacube->getOrder() eq 'QBD'),
   'order accepts QBD');


# test setter accepts enumerated value: QDB

eval {$biodatacube->setOrder('QDB')};
ok((not $@ and $biodatacube->getOrder() eq 'QDB'),
   'order accepts QDB');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioDataCube->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatacube = Bio::MAGE::BioAssayData::BioDataCube->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($biodatacube->getPropertySets,'ARRAY')
 and scalar @{$biodatacube->getPropertySets} == 1
 and UNIVERSAL::isa($biodatacube->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biodatacube->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biodatacube->getPropertySets,'ARRAY')
 and scalar @{$biodatacube->getPropertySets} == 1
 and $biodatacube->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biodatacube->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biodatacube->getPropertySets,'ARRAY')
 and scalar @{$biodatacube->getPropertySets} == 2
 and $biodatacube->getPropertySets->[0] == $propertysets_assn
 and $biodatacube->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biodatacube->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biodatacube->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biodatacube->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biodatacube->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biodatacube->setPropertySets([])};
ok((!$@ and defined $biodatacube->getPropertySets()
    and UNIVERSAL::isa($biodatacube->getPropertySets, 'ARRAY')
    and scalar @{$biodatacube->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biodatacube->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biodatacube->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biodatacube->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biodatacube->setPropertySets(undef)};
ok((!$@ and not defined $biodatacube->getPropertySets()),
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





my $biodatavalues;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $biodatavalues = Bio::MAGE::BioAssayData::BioDataValues->new();
}

# testing superclass BioDataValues
isa_ok($biodatavalues, q[Bio::MAGE::BioAssayData::BioDataValues]);
isa_ok($biodatacube, q[Bio::MAGE::BioAssayData::BioDataValues]);

