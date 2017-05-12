##############################
#
# SeqFeatureLocation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SeqFeatureLocation.t`

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
use Test::More tests => 63;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioSequence::SeqFeatureLocation') };

use Bio::MAGE::BioSequence::SequencePosition;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioSequence::SeqFeatureLocation;


# we test the new() method
my $seqfeaturelocation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeaturelocation = Bio::MAGE::BioSequence::SeqFeatureLocation->new();
}
isa_ok($seqfeaturelocation, 'Bio::MAGE::BioSequence::SeqFeatureLocation');

# test the package_name class method
is($seqfeaturelocation->package_name(), q[BioSequence],
  'package');

# test the class_name class method
is($seqfeaturelocation->class_name(), q[Bio::MAGE::BioSequence::SeqFeatureLocation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeaturelocation = Bio::MAGE::BioSequence::SeqFeatureLocation->new(strandType => '1');
}


#
# testing attribute strandType
#

# test attribute values can be set in new()
is($seqfeaturelocation->getStrandType(), '1',
  'strandType new');

# test getter/setter
$seqfeaturelocation->setStrandType('1');
is($seqfeaturelocation->getStrandType(), '1',
  'strandType getter/setter');

# test getter throws exception with argument
eval {$seqfeaturelocation->getStrandType(1)};
ok($@, 'strandType getter throws exception with argument');

# test setter throws exception with no argument
eval {$seqfeaturelocation->setStrandType()};
ok($@, 'strandType setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$seqfeaturelocation->setStrandType('1', '1')};
ok($@, 'strandType setter throws exception with too many argument');

# test setter accepts undef
eval {$seqfeaturelocation->setStrandType(undef)};
ok((!$@ and not defined $seqfeaturelocation->getStrandType()),
   'strandType setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioSequence::SeqFeatureLocation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeaturelocation = Bio::MAGE::BioSequence::SeqFeatureLocation->new(coordinate => Bio::MAGE::BioSequence::SequencePosition->new(),
subregions => [Bio::MAGE::BioSequence::SeqFeatureLocation->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association coordinate
my $coordinate_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $coordinate_assn = Bio::MAGE::BioSequence::SequencePosition->new();
}


isa_ok($seqfeaturelocation->getCoordinate, q[Bio::MAGE::BioSequence::SequencePosition]);

is($seqfeaturelocation->setCoordinate($coordinate_assn), $coordinate_assn,
  'setCoordinate returns value');

ok($seqfeaturelocation->getCoordinate() == $coordinate_assn,
   'getCoordinate fetches correct value');

# test setCoordinate throws exception with bad argument
eval {$seqfeaturelocation->setCoordinate(1)};
ok($@, 'setCoordinate throws exception with bad argument');


# test getCoordinate throws exception with argument
eval {$seqfeaturelocation->getCoordinate(1)};
ok($@, 'getCoordinate throws exception with argument');

# test setCoordinate throws exception with no argument
eval {$seqfeaturelocation->setCoordinate()};
ok($@, 'setCoordinate throws exception with no argument');

# test setCoordinate throws exception with too many argument
eval {$seqfeaturelocation->setCoordinate(1,2)};
ok($@, 'setCoordinate throws exception with too many argument');

# test setCoordinate accepts undef
eval {$seqfeaturelocation->setCoordinate(undef)};
ok((!$@ and not defined $seqfeaturelocation->getCoordinate()),
   'setCoordinate accepts undef');

# test the meta-data for the assoication
$assn = $assns{coordinate};
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
   'coordinate->other() is a valid Bio::MAGE::Association::End'
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
   'coordinate->self() is a valid Bio::MAGE::Association::End'
  );



# testing association subregions
my $subregions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $subregions_assn = Bio::MAGE::BioSequence::SeqFeatureLocation->new();
}


ok((UNIVERSAL::isa($seqfeaturelocation->getSubregions,'ARRAY')
 and scalar @{$seqfeaturelocation->getSubregions} == 1
 and UNIVERSAL::isa($seqfeaturelocation->getSubregions->[0], q[Bio::MAGE::BioSequence::SeqFeatureLocation])),
  'subregions set in new()');

ok(eq_array($seqfeaturelocation->setSubregions([$subregions_assn]), [$subregions_assn]),
   'setSubregions returns correct value');

ok((UNIVERSAL::isa($seqfeaturelocation->getSubregions,'ARRAY')
 and scalar @{$seqfeaturelocation->getSubregions} == 1
 and $seqfeaturelocation->getSubregions->[0] == $subregions_assn),
   'getSubregions fetches correct value');

is($seqfeaturelocation->addSubregions($subregions_assn), 2,
  'addSubregions returns number of items in list');

ok((UNIVERSAL::isa($seqfeaturelocation->getSubregions,'ARRAY')
 and scalar @{$seqfeaturelocation->getSubregions} == 2
 and $seqfeaturelocation->getSubregions->[0] == $subregions_assn
 and $seqfeaturelocation->getSubregions->[1] == $subregions_assn),
  'addSubregions adds correct value');

# test setSubregions throws exception with non-array argument
eval {$seqfeaturelocation->setSubregions(1)};
ok($@, 'setSubregions throws exception with non-array argument');

# test setSubregions throws exception with bad argument array
eval {$seqfeaturelocation->setSubregions([1])};
ok($@, 'setSubregions throws exception with bad argument array');

# test addSubregions throws exception with no arguments
eval {$seqfeaturelocation->addSubregions()};
ok($@, 'addSubregions throws exception with no arguments');

# test addSubregions throws exception with bad argument
eval {$seqfeaturelocation->addSubregions(1)};
ok($@, 'addSubregions throws exception with bad array');

# test setSubregions accepts empty array ref
eval {$seqfeaturelocation->setSubregions([])};
ok((!$@ and defined $seqfeaturelocation->getSubregions()
    and UNIVERSAL::isa($seqfeaturelocation->getSubregions, 'ARRAY')
    and scalar @{$seqfeaturelocation->getSubregions} == 0),
   'setSubregions accepts empty array ref');


# test getSubregions throws exception with argument
eval {$seqfeaturelocation->getSubregions(1)};
ok($@, 'getSubregions throws exception with argument');

# test setSubregions throws exception with no argument
eval {$seqfeaturelocation->setSubregions()};
ok($@, 'setSubregions throws exception with no argument');

# test setSubregions throws exception with too many argument
eval {$seqfeaturelocation->setSubregions(1,2)};
ok($@, 'setSubregions throws exception with too many argument');

# test setSubregions accepts undef
eval {$seqfeaturelocation->setSubregions(undef)};
ok((!$@ and not defined $seqfeaturelocation->getSubregions()),
   'setSubregions accepts undef');

# test the meta-data for the assoication
$assn = $assns{subregions};
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
   'subregions->other() is a valid Bio::MAGE::Association::End'
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
   'subregions->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($seqfeaturelocation->getPropertySets,'ARRAY')
 and scalar @{$seqfeaturelocation->getPropertySets} == 1
 and UNIVERSAL::isa($seqfeaturelocation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($seqfeaturelocation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($seqfeaturelocation->getPropertySets,'ARRAY')
 and scalar @{$seqfeaturelocation->getPropertySets} == 1
 and $seqfeaturelocation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($seqfeaturelocation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($seqfeaturelocation->getPropertySets,'ARRAY')
 and scalar @{$seqfeaturelocation->getPropertySets} == 2
 and $seqfeaturelocation->getPropertySets->[0] == $propertysets_assn
 and $seqfeaturelocation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$seqfeaturelocation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$seqfeaturelocation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$seqfeaturelocation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$seqfeaturelocation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$seqfeaturelocation->setPropertySets([])};
ok((!$@ and defined $seqfeaturelocation->getPropertySets()
    and UNIVERSAL::isa($seqfeaturelocation->getPropertySets, 'ARRAY')
    and scalar @{$seqfeaturelocation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$seqfeaturelocation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$seqfeaturelocation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$seqfeaturelocation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$seqfeaturelocation->setPropertySets(undef)};
ok((!$@ and not defined $seqfeaturelocation->getPropertySets()),
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
isa_ok($seqfeaturelocation, q[Bio::MAGE::Extendable]);

