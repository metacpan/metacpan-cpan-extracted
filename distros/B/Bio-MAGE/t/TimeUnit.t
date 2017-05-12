##############################
#
# TimeUnit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TimeUnit.t`

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
use Test::More tests => 47;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Measurement::TimeUnit') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $timeunit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $timeunit = Bio::MAGE::Measurement::TimeUnit->new();
}
isa_ok($timeunit, 'Bio::MAGE::Measurement::TimeUnit');

# test the package_name class method
is($timeunit->package_name(), q[Measurement],
  'package');

# test the class_name class method
is($timeunit->class_name(), q[Bio::MAGE::Measurement::TimeUnit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $timeunit = Bio::MAGE::Measurement::TimeUnit->new(unitName => '1',
unitNameCV => 'years');
}


#
# testing attribute unitName
#

# test attribute values can be set in new()
is($timeunit->getUnitName(), '1',
  'unitName new');

# test getter/setter
$timeunit->setUnitName('1');
is($timeunit->getUnitName(), '1',
  'unitName getter/setter');

# test getter throws exception with argument
eval {$timeunit->getUnitName(1)};
ok($@, 'unitName getter throws exception with argument');

# test setter throws exception with no argument
eval {$timeunit->setUnitName()};
ok($@, 'unitName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$timeunit->setUnitName('1', '1')};
ok($@, 'unitName setter throws exception with too many argument');

# test setter accepts undef
eval {$timeunit->setUnitName(undef)};
ok((!$@ and not defined $timeunit->getUnitName()),
   'unitName setter accepts undef');



#
# testing attribute unitNameCV
#

# test attribute values can be set in new()
is($timeunit->getUnitNameCV(), 'years',
  'unitNameCV new');

# test getter/setter
$timeunit->setUnitNameCV('years');
is($timeunit->getUnitNameCV(), 'years',
  'unitNameCV getter/setter');

# test getter throws exception with argument
eval {$timeunit->getUnitNameCV(1)};
ok($@, 'unitNameCV getter throws exception with argument');

# test setter throws exception with no argument
eval {$timeunit->setUnitNameCV()};
ok($@, 'unitNameCV setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$timeunit->setUnitNameCV('years', 'years')};
ok($@, 'unitNameCV setter throws exception with too many argument');

# test setter accepts undef
eval {$timeunit->setUnitNameCV(undef)};
ok((!$@ and not defined $timeunit->getUnitNameCV()),
   'unitNameCV setter accepts undef');


# test setter throws exception with bad argument
eval {$timeunit->setUnitNameCV(1)};
ok($@, 'unitNameCV setter throws exception with bad argument');


# test setter accepts enumerated value: years

eval {$timeunit->setUnitNameCV('years')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'years'),
   'unitNameCV accepts years');


# test setter accepts enumerated value: months

eval {$timeunit->setUnitNameCV('months')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'months'),
   'unitNameCV accepts months');


# test setter accepts enumerated value: weeks

eval {$timeunit->setUnitNameCV('weeks')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'weeks'),
   'unitNameCV accepts weeks');


# test setter accepts enumerated value: d

eval {$timeunit->setUnitNameCV('d')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'd'),
   'unitNameCV accepts d');


# test setter accepts enumerated value: h

eval {$timeunit->setUnitNameCV('h')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'h'),
   'unitNameCV accepts h');


# test setter accepts enumerated value: m

eval {$timeunit->setUnitNameCV('m')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'm'),
   'unitNameCV accepts m');


# test setter accepts enumerated value: s

eval {$timeunit->setUnitNameCV('s')};
ok((not $@ and $timeunit->getUnitNameCV() eq 's'),
   'unitNameCV accepts s');


# test setter accepts enumerated value: us

eval {$timeunit->setUnitNameCV('us')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'us'),
   'unitNameCV accepts us');


# test setter accepts enumerated value: other

eval {$timeunit->setUnitNameCV('other')};
ok((not $@ and $timeunit->getUnitNameCV() eq 'other'),
   'unitNameCV accepts other');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Measurement::TimeUnit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $timeunit = Bio::MAGE::Measurement::TimeUnit->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($timeunit->getPropertySets,'ARRAY')
 and scalar @{$timeunit->getPropertySets} == 1
 and UNIVERSAL::isa($timeunit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($timeunit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($timeunit->getPropertySets,'ARRAY')
 and scalar @{$timeunit->getPropertySets} == 1
 and $timeunit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($timeunit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($timeunit->getPropertySets,'ARRAY')
 and scalar @{$timeunit->getPropertySets} == 2
 and $timeunit->getPropertySets->[0] == $propertysets_assn
 and $timeunit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$timeunit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$timeunit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$timeunit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$timeunit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$timeunit->setPropertySets([])};
ok((!$@ and defined $timeunit->getPropertySets()
    and UNIVERSAL::isa($timeunit->getPropertySets, 'ARRAY')
    and scalar @{$timeunit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$timeunit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$timeunit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$timeunit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$timeunit->setPropertySets(undef)};
ok((!$@ and not defined $timeunit->getPropertySets()),
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





my $unit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $unit = Bio::MAGE::Measurement::Unit->new();
}

# testing superclass Unit
isa_ok($unit, q[Bio::MAGE::Measurement::Unit]);
isa_ok($timeunit, q[Bio::MAGE::Measurement::Unit]);

