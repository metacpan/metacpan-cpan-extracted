##############################
#
# SequencePosition.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SequencePosition.t`

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

BEGIN { use_ok('Bio::MAGE::BioSequence::SequencePosition') };

use Bio::MAGE::NameValueType;

use Bio::MAGE::DesignElement::ReporterPosition;
use Bio::MAGE::DesignElement::CompositePosition;

# we test the new() method
my $sequenceposition;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sequenceposition = Bio::MAGE::BioSequence::SequencePosition->new();
}
isa_ok($sequenceposition, 'Bio::MAGE::BioSequence::SequencePosition');

# test the package_name class method
is($sequenceposition->package_name(), q[BioSequence],
  'package');

# test the class_name class method
is($sequenceposition->class_name(), q[Bio::MAGE::BioSequence::SequencePosition],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sequenceposition = Bio::MAGE::BioSequence::SequencePosition->new(start => '1',
end => '2');
}


#
# testing attribute start
#

# test attribute values can be set in new()
is($sequenceposition->getStart(), '1',
  'start new');

# test getter/setter
$sequenceposition->setStart('1');
is($sequenceposition->getStart(), '1',
  'start getter/setter');

# test getter throws exception with argument
eval {$sequenceposition->getStart(1)};
ok($@, 'start getter throws exception with argument');

# test setter throws exception with no argument
eval {$sequenceposition->setStart()};
ok($@, 'start setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$sequenceposition->setStart('1', '1')};
ok($@, 'start setter throws exception with too many argument');

# test setter accepts undef
eval {$sequenceposition->setStart(undef)};
ok((!$@ and not defined $sequenceposition->getStart()),
   'start setter accepts undef');



#
# testing attribute end
#

# test attribute values can be set in new()
is($sequenceposition->getEnd(), '2',
  'end new');

# test getter/setter
$sequenceposition->setEnd('2');
is($sequenceposition->getEnd(), '2',
  'end getter/setter');

# test getter throws exception with argument
eval {$sequenceposition->getEnd(1)};
ok($@, 'end getter throws exception with argument');

# test setter throws exception with no argument
eval {$sequenceposition->setEnd()};
ok($@, 'end setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$sequenceposition->setEnd('2', '2')};
ok($@, 'end setter throws exception with too many argument');

# test setter accepts undef
eval {$sequenceposition->setEnd(undef)};
ok((!$@ and not defined $sequenceposition->getEnd()),
   'end setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioSequence::SequencePosition->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sequenceposition = Bio::MAGE::BioSequence::SequencePosition->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($sequenceposition->getPropertySets,'ARRAY')
 and scalar @{$sequenceposition->getPropertySets} == 1
 and UNIVERSAL::isa($sequenceposition->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($sequenceposition->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($sequenceposition->getPropertySets,'ARRAY')
 and scalar @{$sequenceposition->getPropertySets} == 1
 and $sequenceposition->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($sequenceposition->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($sequenceposition->getPropertySets,'ARRAY')
 and scalar @{$sequenceposition->getPropertySets} == 2
 and $sequenceposition->getPropertySets->[0] == $propertysets_assn
 and $sequenceposition->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$sequenceposition->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$sequenceposition->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$sequenceposition->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$sequenceposition->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$sequenceposition->setPropertySets([])};
ok((!$@ and defined $sequenceposition->getPropertySets()
    and UNIVERSAL::isa($sequenceposition->getPropertySets, 'ARRAY')
    and scalar @{$sequenceposition->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$sequenceposition->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$sequenceposition->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$sequenceposition->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$sequenceposition->setPropertySets(undef)};
ok((!$@ and not defined $sequenceposition->getPropertySets()),
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
my $reporterposition = Bio::MAGE::DesignElement::ReporterPosition->new();

# testing subclass ReporterPosition
isa_ok($reporterposition, q[Bio::MAGE::DesignElement::ReporterPosition]);
isa_ok($reporterposition, q[Bio::MAGE::BioSequence::SequencePosition]);


# create a subclass
my $compositeposition = Bio::MAGE::DesignElement::CompositePosition->new();

# testing subclass CompositePosition
isa_ok($compositeposition, q[Bio::MAGE::DesignElement::CompositePosition]);
isa_ok($compositeposition, q[Bio::MAGE::BioSequence::SequencePosition]);



my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($sequenceposition, q[Bio::MAGE::Extendable]);

