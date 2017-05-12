##############################
#
# FeatureLocation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureLocation.t`

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
use Test::More tests => 37;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::FeatureLocation') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $featurelocation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurelocation = Bio::MAGE::DesignElement::FeatureLocation->new();
}
isa_ok($featurelocation, 'Bio::MAGE::DesignElement::FeatureLocation');

# test the package_name class method
is($featurelocation->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($featurelocation->class_name(), q[Bio::MAGE::DesignElement::FeatureLocation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurelocation = Bio::MAGE::DesignElement::FeatureLocation->new(row => '1',
column => '2');
}


#
# testing attribute row
#

# test attribute values can be set in new()
is($featurelocation->getRow(), '1',
  'row new');

# test getter/setter
$featurelocation->setRow('1');
is($featurelocation->getRow(), '1',
  'row getter/setter');

# test getter throws exception with argument
eval {$featurelocation->getRow(1)};
ok($@, 'row getter throws exception with argument');

# test setter throws exception with no argument
eval {$featurelocation->setRow()};
ok($@, 'row setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featurelocation->setRow('1', '1')};
ok($@, 'row setter throws exception with too many argument');

# test setter accepts undef
eval {$featurelocation->setRow(undef)};
ok((!$@ and not defined $featurelocation->getRow()),
   'row setter accepts undef');



#
# testing attribute column
#

# test attribute values can be set in new()
is($featurelocation->getColumn(), '2',
  'column new');

# test getter/setter
$featurelocation->setColumn('2');
is($featurelocation->getColumn(), '2',
  'column getter/setter');

# test getter throws exception with argument
eval {$featurelocation->getColumn(1)};
ok($@, 'column getter throws exception with argument');

# test setter throws exception with no argument
eval {$featurelocation->setColumn()};
ok($@, 'column setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featurelocation->setColumn('2', '2')};
ok($@, 'column setter throws exception with too many argument');

# test setter accepts undef
eval {$featurelocation->setColumn(undef)};
ok((!$@ and not defined $featurelocation->getColumn()),
   'column setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::FeatureLocation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featurelocation = Bio::MAGE::DesignElement::FeatureLocation->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($featurelocation->getPropertySets,'ARRAY')
 and scalar @{$featurelocation->getPropertySets} == 1
 and UNIVERSAL::isa($featurelocation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featurelocation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featurelocation->getPropertySets,'ARRAY')
 and scalar @{$featurelocation->getPropertySets} == 1
 and $featurelocation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featurelocation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featurelocation->getPropertySets,'ARRAY')
 and scalar @{$featurelocation->getPropertySets} == 2
 and $featurelocation->getPropertySets->[0] == $propertysets_assn
 and $featurelocation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featurelocation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featurelocation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featurelocation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featurelocation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featurelocation->setPropertySets([])};
ok((!$@ and defined $featurelocation->getPropertySets()
    and UNIVERSAL::isa($featurelocation->getPropertySets, 'ARRAY')
    and scalar @{$featurelocation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featurelocation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featurelocation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featurelocation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featurelocation->setPropertySets(undef)};
ok((!$@ and not defined $featurelocation->getPropertySets()),
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
isa_ok($featurelocation, q[Bio::MAGE::Extendable]);

