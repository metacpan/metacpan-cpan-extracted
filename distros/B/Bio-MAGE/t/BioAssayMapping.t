##############################
#
# BioAssayMapping.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayMapping.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioAssayMapping') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::BioAssayMap;


# we test the new() method
my $bioassaymapping;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymapping = Bio::MAGE::BioAssayData::BioAssayMapping->new();
}
isa_ok($bioassaymapping, 'Bio::MAGE::BioAssayData::BioAssayMapping');

# test the package_name class method
is($bioassaymapping->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($bioassaymapping->class_name(), q[Bio::MAGE::BioAssayData::BioAssayMapping],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymapping = Bio::MAGE::BioAssayData::BioAssayMapping->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioAssayMapping->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymapping = Bio::MAGE::BioAssayData::BioAssayMapping->new(propertySets => [Bio::MAGE::NameValueType->new()],
bioAssayMaps => [Bio::MAGE::BioAssayData::BioAssayMap->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($bioassaymapping->getPropertySets,'ARRAY')
 and scalar @{$bioassaymapping->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaymapping->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaymapping->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaymapping->getPropertySets,'ARRAY')
 and scalar @{$bioassaymapping->getPropertySets} == 1
 and $bioassaymapping->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaymapping->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaymapping->getPropertySets,'ARRAY')
 and scalar @{$bioassaymapping->getPropertySets} == 2
 and $bioassaymapping->getPropertySets->[0] == $propertysets_assn
 and $bioassaymapping->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaymapping->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaymapping->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaymapping->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaymapping->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaymapping->setPropertySets([])};
ok((!$@ and defined $bioassaymapping->getPropertySets()
    and UNIVERSAL::isa($bioassaymapping->getPropertySets, 'ARRAY')
    and scalar @{$bioassaymapping->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaymapping->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaymapping->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaymapping->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaymapping->setPropertySets(undef)};
ok((!$@ and not defined $bioassaymapping->getPropertySets()),
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



# testing association bioAssayMaps
my $bioassaymaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymaps_assn = Bio::MAGE::BioAssayData::BioAssayMap->new();
}


ok((UNIVERSAL::isa($bioassaymapping->getBioAssayMaps,'ARRAY')
 and scalar @{$bioassaymapping->getBioAssayMaps} == 1
 and UNIVERSAL::isa($bioassaymapping->getBioAssayMaps->[0], q[Bio::MAGE::BioAssayData::BioAssayMap])),
  'bioAssayMaps set in new()');

ok(eq_array($bioassaymapping->setBioAssayMaps([$bioassaymaps_assn]), [$bioassaymaps_assn]),
   'setBioAssayMaps returns correct value');

ok((UNIVERSAL::isa($bioassaymapping->getBioAssayMaps,'ARRAY')
 and scalar @{$bioassaymapping->getBioAssayMaps} == 1
 and $bioassaymapping->getBioAssayMaps->[0] == $bioassaymaps_assn),
   'getBioAssayMaps fetches correct value');

is($bioassaymapping->addBioAssayMaps($bioassaymaps_assn), 2,
  'addBioAssayMaps returns number of items in list');

ok((UNIVERSAL::isa($bioassaymapping->getBioAssayMaps,'ARRAY')
 and scalar @{$bioassaymapping->getBioAssayMaps} == 2
 and $bioassaymapping->getBioAssayMaps->[0] == $bioassaymaps_assn
 and $bioassaymapping->getBioAssayMaps->[1] == $bioassaymaps_assn),
  'addBioAssayMaps adds correct value');

# test setBioAssayMaps throws exception with non-array argument
eval {$bioassaymapping->setBioAssayMaps(1)};
ok($@, 'setBioAssayMaps throws exception with non-array argument');

# test setBioAssayMaps throws exception with bad argument array
eval {$bioassaymapping->setBioAssayMaps([1])};
ok($@, 'setBioAssayMaps throws exception with bad argument array');

# test addBioAssayMaps throws exception with no arguments
eval {$bioassaymapping->addBioAssayMaps()};
ok($@, 'addBioAssayMaps throws exception with no arguments');

# test addBioAssayMaps throws exception with bad argument
eval {$bioassaymapping->addBioAssayMaps(1)};
ok($@, 'addBioAssayMaps throws exception with bad array');

# test setBioAssayMaps accepts empty array ref
eval {$bioassaymapping->setBioAssayMaps([])};
ok((!$@ and defined $bioassaymapping->getBioAssayMaps()
    and UNIVERSAL::isa($bioassaymapping->getBioAssayMaps, 'ARRAY')
    and scalar @{$bioassaymapping->getBioAssayMaps} == 0),
   'setBioAssayMaps accepts empty array ref');


# test getBioAssayMaps throws exception with argument
eval {$bioassaymapping->getBioAssayMaps(1)};
ok($@, 'getBioAssayMaps throws exception with argument');

# test setBioAssayMaps throws exception with no argument
eval {$bioassaymapping->setBioAssayMaps()};
ok($@, 'setBioAssayMaps throws exception with no argument');

# test setBioAssayMaps throws exception with too many argument
eval {$bioassaymapping->setBioAssayMaps(1,2)};
ok($@, 'setBioAssayMaps throws exception with too many argument');

# test setBioAssayMaps accepts undef
eval {$bioassaymapping->setBioAssayMaps(undef)};
ok((!$@ and not defined $bioassaymapping->getBioAssayMaps()),
   'setBioAssayMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayMaps};
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
   'bioAssayMaps->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayMaps->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($bioassaymapping, q[Bio::MAGE::Extendable]);

