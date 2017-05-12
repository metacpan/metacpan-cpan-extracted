##############################
#
# CompositePosition.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompositePosition.t`

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
use Test::More tests => 69;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::CompositePosition') };

use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::DesignElement::MismatchInformation;
use Bio::MAGE::NameValueType;


# we test the new() method
my $compositeposition;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositeposition = Bio::MAGE::DesignElement::CompositePosition->new();
}
isa_ok($compositeposition, 'Bio::MAGE::DesignElement::CompositePosition');

# test the package_name class method
is($compositeposition->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($compositeposition->class_name(), q[Bio::MAGE::DesignElement::CompositePosition],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositeposition = Bio::MAGE::DesignElement::CompositePosition->new(end => '1',
start => '2');
}


#
# testing attribute end
#

# test attribute values can be set in new()
is($compositeposition->getEnd(), '1',
  'end new');

# test getter/setter
$compositeposition->setEnd('1');
is($compositeposition->getEnd(), '1',
  'end getter/setter');

# test getter throws exception with argument
eval {$compositeposition->getEnd(1)};
ok($@, 'end getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositeposition->setEnd()};
ok($@, 'end setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositeposition->setEnd('1', '1')};
ok($@, 'end setter throws exception with too many argument');

# test setter accepts undef
eval {$compositeposition->setEnd(undef)};
ok((!$@ and not defined $compositeposition->getEnd()),
   'end setter accepts undef');



#
# testing attribute start
#

# test attribute values can be set in new()
is($compositeposition->getStart(), '2',
  'start new');

# test getter/setter
$compositeposition->setStart('2');
is($compositeposition->getStart(), '2',
  'start getter/setter');

# test getter throws exception with argument
eval {$compositeposition->getStart(1)};
ok($@, 'start getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositeposition->setStart()};
ok($@, 'start setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositeposition->setStart('2', '2')};
ok($@, 'start setter throws exception with too many argument');

# test setter accepts undef
eval {$compositeposition->setStart(undef)};
ok((!$@ and not defined $compositeposition->getStart()),
   'start setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::CompositePosition->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositeposition = Bio::MAGE::DesignElement::CompositePosition->new(composite => Bio::MAGE::DesignElement::CompositeSequence->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
mismatchInformation => [Bio::MAGE::DesignElement::MismatchInformation->new()]);
}

my ($end, $assn);


# testing association composite
my $composite_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $composite_assn = Bio::MAGE::DesignElement::CompositeSequence->new();
}


isa_ok($compositeposition->getComposite, q[Bio::MAGE::DesignElement::CompositeSequence]);

is($compositeposition->setComposite($composite_assn), $composite_assn,
  'setComposite returns value');

ok($compositeposition->getComposite() == $composite_assn,
   'getComposite fetches correct value');

# test setComposite throws exception with bad argument
eval {$compositeposition->setComposite(1)};
ok($@, 'setComposite throws exception with bad argument');


# test getComposite throws exception with argument
eval {$compositeposition->getComposite(1)};
ok($@, 'getComposite throws exception with argument');

# test setComposite throws exception with no argument
eval {$compositeposition->setComposite()};
ok($@, 'setComposite throws exception with no argument');

# test setComposite throws exception with too many argument
eval {$compositeposition->setComposite(1,2)};
ok($@, 'setComposite throws exception with too many argument');

# test setComposite accepts undef
eval {$compositeposition->setComposite(undef)};
ok((!$@ and not defined $compositeposition->getComposite()),
   'setComposite accepts undef');

# test the meta-data for the assoication
$assn = $assns{composite};
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
   'composite->other() is a valid Bio::MAGE::Association::End'
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
   'composite->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($compositeposition->getPropertySets,'ARRAY')
 and scalar @{$compositeposition->getPropertySets} == 1
 and UNIVERSAL::isa($compositeposition->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compositeposition->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compositeposition->getPropertySets,'ARRAY')
 and scalar @{$compositeposition->getPropertySets} == 1
 and $compositeposition->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compositeposition->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compositeposition->getPropertySets,'ARRAY')
 and scalar @{$compositeposition->getPropertySets} == 2
 and $compositeposition->getPropertySets->[0] == $propertysets_assn
 and $compositeposition->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compositeposition->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compositeposition->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compositeposition->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compositeposition->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compositeposition->setPropertySets([])};
ok((!$@ and defined $compositeposition->getPropertySets()
    and UNIVERSAL::isa($compositeposition->getPropertySets, 'ARRAY')
    and scalar @{$compositeposition->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compositeposition->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compositeposition->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compositeposition->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compositeposition->setPropertySets(undef)};
ok((!$@ and not defined $compositeposition->getPropertySets()),
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



# testing association mismatchInformation
my $mismatchinformation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation_assn = Bio::MAGE::DesignElement::MismatchInformation->new();
}


ok((UNIVERSAL::isa($compositeposition->getMismatchInformation,'ARRAY')
 and scalar @{$compositeposition->getMismatchInformation} == 1
 and UNIVERSAL::isa($compositeposition->getMismatchInformation->[0], q[Bio::MAGE::DesignElement::MismatchInformation])),
  'mismatchInformation set in new()');

ok(eq_array($compositeposition->setMismatchInformation([$mismatchinformation_assn]), [$mismatchinformation_assn]),
   'setMismatchInformation returns correct value');

ok((UNIVERSAL::isa($compositeposition->getMismatchInformation,'ARRAY')
 and scalar @{$compositeposition->getMismatchInformation} == 1
 and $compositeposition->getMismatchInformation->[0] == $mismatchinformation_assn),
   'getMismatchInformation fetches correct value');

is($compositeposition->addMismatchInformation($mismatchinformation_assn), 2,
  'addMismatchInformation returns number of items in list');

ok((UNIVERSAL::isa($compositeposition->getMismatchInformation,'ARRAY')
 and scalar @{$compositeposition->getMismatchInformation} == 2
 and $compositeposition->getMismatchInformation->[0] == $mismatchinformation_assn
 and $compositeposition->getMismatchInformation->[1] == $mismatchinformation_assn),
  'addMismatchInformation adds correct value');

# test setMismatchInformation throws exception with non-array argument
eval {$compositeposition->setMismatchInformation(1)};
ok($@, 'setMismatchInformation throws exception with non-array argument');

# test setMismatchInformation throws exception with bad argument array
eval {$compositeposition->setMismatchInformation([1])};
ok($@, 'setMismatchInformation throws exception with bad argument array');

# test addMismatchInformation throws exception with no arguments
eval {$compositeposition->addMismatchInformation()};
ok($@, 'addMismatchInformation throws exception with no arguments');

# test addMismatchInformation throws exception with bad argument
eval {$compositeposition->addMismatchInformation(1)};
ok($@, 'addMismatchInformation throws exception with bad array');

# test setMismatchInformation accepts empty array ref
eval {$compositeposition->setMismatchInformation([])};
ok((!$@ and defined $compositeposition->getMismatchInformation()
    and UNIVERSAL::isa($compositeposition->getMismatchInformation, 'ARRAY')
    and scalar @{$compositeposition->getMismatchInformation} == 0),
   'setMismatchInformation accepts empty array ref');


# test getMismatchInformation throws exception with argument
eval {$compositeposition->getMismatchInformation(1)};
ok($@, 'getMismatchInformation throws exception with argument');

# test setMismatchInformation throws exception with no argument
eval {$compositeposition->setMismatchInformation()};
ok($@, 'setMismatchInformation throws exception with no argument');

# test setMismatchInformation throws exception with too many argument
eval {$compositeposition->setMismatchInformation(1,2)};
ok($@, 'setMismatchInformation throws exception with too many argument');

# test setMismatchInformation accepts undef
eval {$compositeposition->setMismatchInformation(undef)};
ok((!$@ and not defined $compositeposition->getMismatchInformation()),
   'setMismatchInformation accepts undef');

# test the meta-data for the assoication
$assn = $assns{mismatchInformation};
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
   'mismatchInformation->other() is a valid Bio::MAGE::Association::End'
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
   'mismatchInformation->self() is a valid Bio::MAGE::Association::End'
  );





my $sequenceposition;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $sequenceposition = Bio::MAGE::BioSequence::SequencePosition->new();
}

# testing superclass SequencePosition
isa_ok($sequenceposition, q[Bio::MAGE::BioSequence::SequencePosition]);
isa_ok($compositeposition, q[Bio::MAGE::BioSequence::SequencePosition]);

