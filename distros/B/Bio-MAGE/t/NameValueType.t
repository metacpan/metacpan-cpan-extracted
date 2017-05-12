##############################
#
# NameValueType.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NameValueType.t`

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

BEGIN { use_ok('Bio::MAGE::NameValueType') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $namevaluetype;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $namevaluetype = Bio::MAGE::NameValueType->new();
}
isa_ok($namevaluetype, 'Bio::MAGE::NameValueType');

# test the package_name class method
is($namevaluetype->package_name(), q[MAGE],
  'package');

# test the class_name class method
is($namevaluetype->class_name(), q[Bio::MAGE::NameValueType],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $namevaluetype = Bio::MAGE::NameValueType->new(value => '1',
name => '2',
type => '3');
}


#
# testing attribute value
#

# test attribute values can be set in new()
is($namevaluetype->getValue(), '1',
  'value new');

# test getter/setter
$namevaluetype->setValue('1');
is($namevaluetype->getValue(), '1',
  'value getter/setter');

# test getter throws exception with argument
eval {$namevaluetype->getValue(1)};
ok($@, 'value getter throws exception with argument');

# test setter throws exception with no argument
eval {$namevaluetype->setValue()};
ok($@, 'value setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$namevaluetype->setValue('1', '1')};
ok($@, 'value setter throws exception with too many argument');

# test setter accepts undef
eval {$namevaluetype->setValue(undef)};
ok((!$@ and not defined $namevaluetype->getValue()),
   'value setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($namevaluetype->getName(), '2',
  'name new');

# test getter/setter
$namevaluetype->setName('2');
is($namevaluetype->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$namevaluetype->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$namevaluetype->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$namevaluetype->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$namevaluetype->setName(undef)};
ok((!$@ and not defined $namevaluetype->getName()),
   'name setter accepts undef');



#
# testing attribute type
#

# test attribute values can be set in new()
is($namevaluetype->getType(), '3',
  'type new');

# test getter/setter
$namevaluetype->setType('3');
is($namevaluetype->getType(), '3',
  'type getter/setter');

# test getter throws exception with argument
eval {$namevaluetype->getType(1)};
ok($@, 'type getter throws exception with argument');

# test setter throws exception with no argument
eval {$namevaluetype->setType()};
ok($@, 'type setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$namevaluetype->setType('3', '3')};
ok($@, 'type setter throws exception with too many argument');

# test setter accepts undef
eval {$namevaluetype->setType(undef)};
ok((!$@ and not defined $namevaluetype->getType()),
   'type setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::NameValueType->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $namevaluetype = Bio::MAGE::NameValueType->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($namevaluetype->getPropertySets,'ARRAY')
 and scalar @{$namevaluetype->getPropertySets} == 1
 and UNIVERSAL::isa($namevaluetype->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($namevaluetype->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($namevaluetype->getPropertySets,'ARRAY')
 and scalar @{$namevaluetype->getPropertySets} == 1
 and $namevaluetype->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($namevaluetype->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($namevaluetype->getPropertySets,'ARRAY')
 and scalar @{$namevaluetype->getPropertySets} == 2
 and $namevaluetype->getPropertySets->[0] == $propertysets_assn
 and $namevaluetype->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$namevaluetype->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$namevaluetype->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$namevaluetype->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$namevaluetype->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$namevaluetype->setPropertySets([])};
ok((!$@ and defined $namevaluetype->getPropertySets()
    and UNIVERSAL::isa($namevaluetype->getPropertySets, 'ARRAY')
    and scalar @{$namevaluetype->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$namevaluetype->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$namevaluetype->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$namevaluetype->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$namevaluetype->setPropertySets(undef)};
ok((!$@ and not defined $namevaluetype->getPropertySets()),
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




