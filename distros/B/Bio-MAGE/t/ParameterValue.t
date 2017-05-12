##############################
#
# ParameterValue.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ParameterValue.t`

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

BEGIN { use_ok('Bio::MAGE::Protocol::ParameterValue') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::Protocol::Parameter;


# we test the new() method
my $parametervalue;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalue = Bio::MAGE::Protocol::ParameterValue->new();
}
isa_ok($parametervalue, 'Bio::MAGE::Protocol::ParameterValue');

# test the package_name class method
is($parametervalue->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($parametervalue->class_name(), q[Bio::MAGE::Protocol::ParameterValue],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalue = Bio::MAGE::Protocol::ParameterValue->new(value => '1');
}


#
# testing attribute value
#

# test attribute values can be set in new()
is($parametervalue->getValue(), '1',
  'value new');

# test getter/setter
$parametervalue->setValue('1');
is($parametervalue->getValue(), '1',
  'value getter/setter');

# test getter throws exception with argument
eval {$parametervalue->getValue(1)};
ok($@, 'value getter throws exception with argument');

# test setter throws exception with no argument
eval {$parametervalue->setValue()};
ok($@, 'value setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$parametervalue->setValue('1', '1')};
ok($@, 'value setter throws exception with too many argument');

# test setter accepts undef
eval {$parametervalue->setValue(undef)};
ok((!$@ and not defined $parametervalue->getValue()),
   'value setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::ParameterValue->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalue = Bio::MAGE::Protocol::ParameterValue->new(parameterType => Bio::MAGE::Protocol::Parameter->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association parameterType
my $parametertype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametertype_assn = Bio::MAGE::Protocol::Parameter->new();
}


isa_ok($parametervalue->getParameterType, q[Bio::MAGE::Protocol::Parameter]);

is($parametervalue->setParameterType($parametertype_assn), $parametertype_assn,
  'setParameterType returns value');

ok($parametervalue->getParameterType() == $parametertype_assn,
   'getParameterType fetches correct value');

# test setParameterType throws exception with bad argument
eval {$parametervalue->setParameterType(1)};
ok($@, 'setParameterType throws exception with bad argument');


# test getParameterType throws exception with argument
eval {$parametervalue->getParameterType(1)};
ok($@, 'getParameterType throws exception with argument');

# test setParameterType throws exception with no argument
eval {$parametervalue->setParameterType()};
ok($@, 'setParameterType throws exception with no argument');

# test setParameterType throws exception with too many argument
eval {$parametervalue->setParameterType(1,2)};
ok($@, 'setParameterType throws exception with too many argument');

# test setParameterType accepts undef
eval {$parametervalue->setParameterType(undef)};
ok((!$@ and not defined $parametervalue->getParameterType()),
   'setParameterType accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameterType};
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
   'parameterType->other() is a valid Bio::MAGE::Association::End'
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
   'parameterType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($parametervalue->getPropertySets,'ARRAY')
 and scalar @{$parametervalue->getPropertySets} == 1
 and UNIVERSAL::isa($parametervalue->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($parametervalue->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($parametervalue->getPropertySets,'ARRAY')
 and scalar @{$parametervalue->getPropertySets} == 1
 and $parametervalue->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($parametervalue->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($parametervalue->getPropertySets,'ARRAY')
 and scalar @{$parametervalue->getPropertySets} == 2
 and $parametervalue->getPropertySets->[0] == $propertysets_assn
 and $parametervalue->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$parametervalue->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$parametervalue->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$parametervalue->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$parametervalue->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$parametervalue->setPropertySets([])};
ok((!$@ and defined $parametervalue->getPropertySets()
    and UNIVERSAL::isa($parametervalue->getPropertySets, 'ARRAY')
    and scalar @{$parametervalue->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$parametervalue->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$parametervalue->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$parametervalue->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$parametervalue->setPropertySets(undef)};
ok((!$@ and not defined $parametervalue->getPropertySets()),
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
isa_ok($parametervalue, q[Bio::MAGE::Extendable]);

