##############################
#
# ReporterPosition.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ReporterPosition.t`

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

BEGIN { use_ok('Bio::MAGE::DesignElement::ReporterPosition') };

use Bio::MAGE::DesignElement::MismatchInformation;
use Bio::MAGE::DesignElement::Reporter;
use Bio::MAGE::NameValueType;


# we test the new() method
my $reporterposition;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterposition = Bio::MAGE::DesignElement::ReporterPosition->new();
}
isa_ok($reporterposition, 'Bio::MAGE::DesignElement::ReporterPosition');

# test the package_name class method
is($reporterposition->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($reporterposition->class_name(), q[Bio::MAGE::DesignElement::ReporterPosition],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterposition = Bio::MAGE::DesignElement::ReporterPosition->new(end => '1',
start => '2');
}


#
# testing attribute end
#

# test attribute values can be set in new()
is($reporterposition->getEnd(), '1',
  'end new');

# test getter/setter
$reporterposition->setEnd('1');
is($reporterposition->getEnd(), '1',
  'end getter/setter');

# test getter throws exception with argument
eval {$reporterposition->getEnd(1)};
ok($@, 'end getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporterposition->setEnd()};
ok($@, 'end setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporterposition->setEnd('1', '1')};
ok($@, 'end setter throws exception with too many argument');

# test setter accepts undef
eval {$reporterposition->setEnd(undef)};
ok((!$@ and not defined $reporterposition->getEnd()),
   'end setter accepts undef');



#
# testing attribute start
#

# test attribute values can be set in new()
is($reporterposition->getStart(), '2',
  'start new');

# test getter/setter
$reporterposition->setStart('2');
is($reporterposition->getStart(), '2',
  'start getter/setter');

# test getter throws exception with argument
eval {$reporterposition->getStart(1)};
ok($@, 'start getter throws exception with argument');

# test setter throws exception with no argument
eval {$reporterposition->setStart()};
ok($@, 'start setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$reporterposition->setStart('2', '2')};
ok($@, 'start setter throws exception with too many argument');

# test setter accepts undef
eval {$reporterposition->setStart(undef)};
ok((!$@ and not defined $reporterposition->getStart()),
   'start setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::ReporterPosition->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporterposition = Bio::MAGE::DesignElement::ReporterPosition->new(propertySets => [Bio::MAGE::NameValueType->new()],
reporter => Bio::MAGE::DesignElement::Reporter->new(),
mismatchInformation => [Bio::MAGE::DesignElement::MismatchInformation->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($reporterposition->getPropertySets,'ARRAY')
 and scalar @{$reporterposition->getPropertySets} == 1
 and UNIVERSAL::isa($reporterposition->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($reporterposition->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($reporterposition->getPropertySets,'ARRAY')
 and scalar @{$reporterposition->getPropertySets} == 1
 and $reporterposition->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($reporterposition->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($reporterposition->getPropertySets,'ARRAY')
 and scalar @{$reporterposition->getPropertySets} == 2
 and $reporterposition->getPropertySets->[0] == $propertysets_assn
 and $reporterposition->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$reporterposition->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$reporterposition->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$reporterposition->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$reporterposition->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$reporterposition->setPropertySets([])};
ok((!$@ and defined $reporterposition->getPropertySets()
    and UNIVERSAL::isa($reporterposition->getPropertySets, 'ARRAY')
    and scalar @{$reporterposition->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$reporterposition->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$reporterposition->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$reporterposition->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$reporterposition->setPropertySets(undef)};
ok((!$@ and not defined $reporterposition->getPropertySets()),
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



# testing association reporter
my $reporter_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reporter_assn = Bio::MAGE::DesignElement::Reporter->new();
}


isa_ok($reporterposition->getReporter, q[Bio::MAGE::DesignElement::Reporter]);

is($reporterposition->setReporter($reporter_assn), $reporter_assn,
  'setReporter returns value');

ok($reporterposition->getReporter() == $reporter_assn,
   'getReporter fetches correct value');

# test setReporter throws exception with bad argument
eval {$reporterposition->setReporter(1)};
ok($@, 'setReporter throws exception with bad argument');


# test getReporter throws exception with argument
eval {$reporterposition->getReporter(1)};
ok($@, 'getReporter throws exception with argument');

# test setReporter throws exception with no argument
eval {$reporterposition->setReporter()};
ok($@, 'setReporter throws exception with no argument');

# test setReporter throws exception with too many argument
eval {$reporterposition->setReporter(1,2)};
ok($@, 'setReporter throws exception with too many argument');

# test setReporter accepts undef
eval {$reporterposition->setReporter(undef)};
ok((!$@ and not defined $reporterposition->getReporter()),
   'setReporter accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporter};
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
   'reporter->other() is a valid Bio::MAGE::Association::End'
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
   'reporter->self() is a valid Bio::MAGE::Association::End'
  );



# testing association mismatchInformation
my $mismatchinformation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation_assn = Bio::MAGE::DesignElement::MismatchInformation->new();
}


ok((UNIVERSAL::isa($reporterposition->getMismatchInformation,'ARRAY')
 and scalar @{$reporterposition->getMismatchInformation} == 1
 and UNIVERSAL::isa($reporterposition->getMismatchInformation->[0], q[Bio::MAGE::DesignElement::MismatchInformation])),
  'mismatchInformation set in new()');

ok(eq_array($reporterposition->setMismatchInformation([$mismatchinformation_assn]), [$mismatchinformation_assn]),
   'setMismatchInformation returns correct value');

ok((UNIVERSAL::isa($reporterposition->getMismatchInformation,'ARRAY')
 and scalar @{$reporterposition->getMismatchInformation} == 1
 and $reporterposition->getMismatchInformation->[0] == $mismatchinformation_assn),
   'getMismatchInformation fetches correct value');

is($reporterposition->addMismatchInformation($mismatchinformation_assn), 2,
  'addMismatchInformation returns number of items in list');

ok((UNIVERSAL::isa($reporterposition->getMismatchInformation,'ARRAY')
 and scalar @{$reporterposition->getMismatchInformation} == 2
 and $reporterposition->getMismatchInformation->[0] == $mismatchinformation_assn
 and $reporterposition->getMismatchInformation->[1] == $mismatchinformation_assn),
  'addMismatchInformation adds correct value');

# test setMismatchInformation throws exception with non-array argument
eval {$reporterposition->setMismatchInformation(1)};
ok($@, 'setMismatchInformation throws exception with non-array argument');

# test setMismatchInformation throws exception with bad argument array
eval {$reporterposition->setMismatchInformation([1])};
ok($@, 'setMismatchInformation throws exception with bad argument array');

# test addMismatchInformation throws exception with no arguments
eval {$reporterposition->addMismatchInformation()};
ok($@, 'addMismatchInformation throws exception with no arguments');

# test addMismatchInformation throws exception with bad argument
eval {$reporterposition->addMismatchInformation(1)};
ok($@, 'addMismatchInformation throws exception with bad array');

# test setMismatchInformation accepts empty array ref
eval {$reporterposition->setMismatchInformation([])};
ok((!$@ and defined $reporterposition->getMismatchInformation()
    and UNIVERSAL::isa($reporterposition->getMismatchInformation, 'ARRAY')
    and scalar @{$reporterposition->getMismatchInformation} == 0),
   'setMismatchInformation accepts empty array ref');


# test getMismatchInformation throws exception with argument
eval {$reporterposition->getMismatchInformation(1)};
ok($@, 'getMismatchInformation throws exception with argument');

# test setMismatchInformation throws exception with no argument
eval {$reporterposition->setMismatchInformation()};
ok($@, 'setMismatchInformation throws exception with no argument');

# test setMismatchInformation throws exception with too many argument
eval {$reporterposition->setMismatchInformation(1,2)};
ok($@, 'setMismatchInformation throws exception with too many argument');

# test setMismatchInformation accepts undef
eval {$reporterposition->setMismatchInformation(undef)};
ok((!$@ and not defined $reporterposition->getMismatchInformation()),
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
isa_ok($reporterposition, q[Bio::MAGE::BioSequence::SequencePosition]);

