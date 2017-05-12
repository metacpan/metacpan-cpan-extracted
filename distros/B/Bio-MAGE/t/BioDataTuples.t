##############################
#
# BioDataTuples.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioDataTuples.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioDataTuples') };

use Bio::MAGE::BioAssayData::BioAssayDatum;
use Bio::MAGE::NameValueType;


# we test the new() method
my $biodatatuples;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatatuples = Bio::MAGE::BioAssayData::BioDataTuples->new();
}
isa_ok($biodatatuples, 'Bio::MAGE::BioAssayData::BioDataTuples');

# test the package_name class method
is($biodatatuples->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($biodatatuples->class_name(), q[Bio::MAGE::BioAssayData::BioDataTuples],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatatuples = Bio::MAGE::BioAssayData::BioDataTuples->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioDataTuples->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biodatatuples = Bio::MAGE::BioAssayData::BioDataTuples->new(bioAssayTupleData => [Bio::MAGE::BioAssayData::BioAssayDatum->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association bioAssayTupleData
my $bioassaytupledata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaytupledata_assn = Bio::MAGE::BioAssayData::BioAssayDatum->new();
}


ok((UNIVERSAL::isa($biodatatuples->getBioAssayTupleData,'ARRAY')
 and scalar @{$biodatatuples->getBioAssayTupleData} == 1
 and UNIVERSAL::isa($biodatatuples->getBioAssayTupleData->[0], q[Bio::MAGE::BioAssayData::BioAssayDatum])),
  'bioAssayTupleData set in new()');

ok(eq_array($biodatatuples->setBioAssayTupleData([$bioassaytupledata_assn]), [$bioassaytupledata_assn]),
   'setBioAssayTupleData returns correct value');

ok((UNIVERSAL::isa($biodatatuples->getBioAssayTupleData,'ARRAY')
 and scalar @{$biodatatuples->getBioAssayTupleData} == 1
 and $biodatatuples->getBioAssayTupleData->[0] == $bioassaytupledata_assn),
   'getBioAssayTupleData fetches correct value');

is($biodatatuples->addBioAssayTupleData($bioassaytupledata_assn), 2,
  'addBioAssayTupleData returns number of items in list');

ok((UNIVERSAL::isa($biodatatuples->getBioAssayTupleData,'ARRAY')
 and scalar @{$biodatatuples->getBioAssayTupleData} == 2
 and $biodatatuples->getBioAssayTupleData->[0] == $bioassaytupledata_assn
 and $biodatatuples->getBioAssayTupleData->[1] == $bioassaytupledata_assn),
  'addBioAssayTupleData adds correct value');

# test setBioAssayTupleData throws exception with non-array argument
eval {$biodatatuples->setBioAssayTupleData(1)};
ok($@, 'setBioAssayTupleData throws exception with non-array argument');

# test setBioAssayTupleData throws exception with bad argument array
eval {$biodatatuples->setBioAssayTupleData([1])};
ok($@, 'setBioAssayTupleData throws exception with bad argument array');

# test addBioAssayTupleData throws exception with no arguments
eval {$biodatatuples->addBioAssayTupleData()};
ok($@, 'addBioAssayTupleData throws exception with no arguments');

# test addBioAssayTupleData throws exception with bad argument
eval {$biodatatuples->addBioAssayTupleData(1)};
ok($@, 'addBioAssayTupleData throws exception with bad array');

# test setBioAssayTupleData accepts empty array ref
eval {$biodatatuples->setBioAssayTupleData([])};
ok((!$@ and defined $biodatatuples->getBioAssayTupleData()
    and UNIVERSAL::isa($biodatatuples->getBioAssayTupleData, 'ARRAY')
    and scalar @{$biodatatuples->getBioAssayTupleData} == 0),
   'setBioAssayTupleData accepts empty array ref');


# test getBioAssayTupleData throws exception with argument
eval {$biodatatuples->getBioAssayTupleData(1)};
ok($@, 'getBioAssayTupleData throws exception with argument');

# test setBioAssayTupleData throws exception with no argument
eval {$biodatatuples->setBioAssayTupleData()};
ok($@, 'setBioAssayTupleData throws exception with no argument');

# test setBioAssayTupleData throws exception with too many argument
eval {$biodatatuples->setBioAssayTupleData(1,2)};
ok($@, 'setBioAssayTupleData throws exception with too many argument');

# test setBioAssayTupleData accepts undef
eval {$biodatatuples->setBioAssayTupleData(undef)};
ok((!$@ and not defined $biodatatuples->getBioAssayTupleData()),
   'setBioAssayTupleData accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayTupleData};
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
   'bioAssayTupleData->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayTupleData->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($biodatatuples->getPropertySets,'ARRAY')
 and scalar @{$biodatatuples->getPropertySets} == 1
 and UNIVERSAL::isa($biodatatuples->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biodatatuples->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biodatatuples->getPropertySets,'ARRAY')
 and scalar @{$biodatatuples->getPropertySets} == 1
 and $biodatatuples->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biodatatuples->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biodatatuples->getPropertySets,'ARRAY')
 and scalar @{$biodatatuples->getPropertySets} == 2
 and $biodatatuples->getPropertySets->[0] == $propertysets_assn
 and $biodatatuples->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biodatatuples->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biodatatuples->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biodatatuples->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biodatatuples->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biodatatuples->setPropertySets([])};
ok((!$@ and defined $biodatatuples->getPropertySets()
    and UNIVERSAL::isa($biodatatuples->getPropertySets, 'ARRAY')
    and scalar @{$biodatatuples->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biodatatuples->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biodatatuples->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biodatatuples->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biodatatuples->setPropertySets(undef)};
ok((!$@ and not defined $biodatatuples->getPropertySets()),
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
isa_ok($biodatatuples, q[Bio::MAGE::BioAssayData::BioDataValues]);

