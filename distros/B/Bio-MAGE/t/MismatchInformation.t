##############################
#
# MismatchInformation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MismatchInformation.t`

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
use Test::More tests => 43;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::MismatchInformation') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $mismatchinformation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation = Bio::MAGE::DesignElement::MismatchInformation->new();
}
isa_ok($mismatchinformation, 'Bio::MAGE::DesignElement::MismatchInformation');

# test the package_name class method
is($mismatchinformation->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($mismatchinformation->class_name(), q[Bio::MAGE::DesignElement::MismatchInformation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation = Bio::MAGE::DesignElement::MismatchInformation->new(replacedLength => '1',
startCoord => '2',
newSequence => '3');
}


#
# testing attribute replacedLength
#

# test attribute values can be set in new()
is($mismatchinformation->getReplacedLength(), '1',
  'replacedLength new');

# test getter/setter
$mismatchinformation->setReplacedLength('1');
is($mismatchinformation->getReplacedLength(), '1',
  'replacedLength getter/setter');

# test getter throws exception with argument
eval {$mismatchinformation->getReplacedLength(1)};
ok($@, 'replacedLength getter throws exception with argument');

# test setter throws exception with no argument
eval {$mismatchinformation->setReplacedLength()};
ok($@, 'replacedLength setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$mismatchinformation->setReplacedLength('1', '1')};
ok($@, 'replacedLength setter throws exception with too many argument');

# test setter accepts undef
eval {$mismatchinformation->setReplacedLength(undef)};
ok((!$@ and not defined $mismatchinformation->getReplacedLength()),
   'replacedLength setter accepts undef');



#
# testing attribute startCoord
#

# test attribute values can be set in new()
is($mismatchinformation->getStartCoord(), '2',
  'startCoord new');

# test getter/setter
$mismatchinformation->setStartCoord('2');
is($mismatchinformation->getStartCoord(), '2',
  'startCoord getter/setter');

# test getter throws exception with argument
eval {$mismatchinformation->getStartCoord(1)};
ok($@, 'startCoord getter throws exception with argument');

# test setter throws exception with no argument
eval {$mismatchinformation->setStartCoord()};
ok($@, 'startCoord setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$mismatchinformation->setStartCoord('2', '2')};
ok($@, 'startCoord setter throws exception with too many argument');

# test setter accepts undef
eval {$mismatchinformation->setStartCoord(undef)};
ok((!$@ and not defined $mismatchinformation->getStartCoord()),
   'startCoord setter accepts undef');



#
# testing attribute newSequence
#

# test attribute values can be set in new()
is($mismatchinformation->getNewSequence(), '3',
  'newSequence new');

# test getter/setter
$mismatchinformation->setNewSequence('3');
is($mismatchinformation->getNewSequence(), '3',
  'newSequence getter/setter');

# test getter throws exception with argument
eval {$mismatchinformation->getNewSequence(1)};
ok($@, 'newSequence getter throws exception with argument');

# test setter throws exception with no argument
eval {$mismatchinformation->setNewSequence()};
ok($@, 'newSequence setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$mismatchinformation->setNewSequence('3', '3')};
ok($@, 'newSequence setter throws exception with too many argument');

# test setter accepts undef
eval {$mismatchinformation->setNewSequence(undef)};
ok((!$@ and not defined $mismatchinformation->getNewSequence()),
   'newSequence setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::MismatchInformation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation = Bio::MAGE::DesignElement::MismatchInformation->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($mismatchinformation->getPropertySets,'ARRAY')
 and scalar @{$mismatchinformation->getPropertySets} == 1
 and UNIVERSAL::isa($mismatchinformation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($mismatchinformation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($mismatchinformation->getPropertySets,'ARRAY')
 and scalar @{$mismatchinformation->getPropertySets} == 1
 and $mismatchinformation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($mismatchinformation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($mismatchinformation->getPropertySets,'ARRAY')
 and scalar @{$mismatchinformation->getPropertySets} == 2
 and $mismatchinformation->getPropertySets->[0] == $propertysets_assn
 and $mismatchinformation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$mismatchinformation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$mismatchinformation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$mismatchinformation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$mismatchinformation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$mismatchinformation->setPropertySets([])};
ok((!$@ and defined $mismatchinformation->getPropertySets()
    and UNIVERSAL::isa($mismatchinformation->getPropertySets, 'ARRAY')
    and scalar @{$mismatchinformation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$mismatchinformation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$mismatchinformation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$mismatchinformation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$mismatchinformation->setPropertySets(undef)};
ok((!$@ and not defined $mismatchinformation->getPropertySets()),
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
isa_ok($mismatchinformation, q[Bio::MAGE::Extendable]);

