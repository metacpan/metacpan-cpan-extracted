##############################
#
# DesignElementMapping.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DesignElementMapping.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::DesignElementMapping') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::DesignElementMap;


# we test the new() method
my $designelementmapping;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementmapping = Bio::MAGE::BioAssayData::DesignElementMapping->new();
}
isa_ok($designelementmapping, 'Bio::MAGE::BioAssayData::DesignElementMapping');

# test the package_name class method
is($designelementmapping->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($designelementmapping->class_name(), q[Bio::MAGE::BioAssayData::DesignElementMapping],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementmapping = Bio::MAGE::BioAssayData::DesignElementMapping->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::DesignElementMapping->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementmapping = Bio::MAGE::BioAssayData::DesignElementMapping->new(propertySets => [Bio::MAGE::NameValueType->new()],
designElementMaps => [Bio::MAGE::BioAssayData::DesignElementMap->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($designelementmapping->getPropertySets,'ARRAY')
 and scalar @{$designelementmapping->getPropertySets} == 1
 and UNIVERSAL::isa($designelementmapping->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($designelementmapping->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($designelementmapping->getPropertySets,'ARRAY')
 and scalar @{$designelementmapping->getPropertySets} == 1
 and $designelementmapping->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($designelementmapping->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($designelementmapping->getPropertySets,'ARRAY')
 and scalar @{$designelementmapping->getPropertySets} == 2
 and $designelementmapping->getPropertySets->[0] == $propertysets_assn
 and $designelementmapping->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$designelementmapping->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$designelementmapping->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$designelementmapping->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$designelementmapping->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$designelementmapping->setPropertySets([])};
ok((!$@ and defined $designelementmapping->getPropertySets()
    and UNIVERSAL::isa($designelementmapping->getPropertySets, 'ARRAY')
    and scalar @{$designelementmapping->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$designelementmapping->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$designelementmapping->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$designelementmapping->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$designelementmapping->setPropertySets(undef)};
ok((!$@ and not defined $designelementmapping->getPropertySets()),
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



# testing association designElementMaps
my $designelementmaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementmaps_assn = Bio::MAGE::BioAssayData::DesignElementMap->new();
}


ok((UNIVERSAL::isa($designelementmapping->getDesignElementMaps,'ARRAY')
 and scalar @{$designelementmapping->getDesignElementMaps} == 1
 and UNIVERSAL::isa($designelementmapping->getDesignElementMaps->[0], q[Bio::MAGE::BioAssayData::DesignElementMap])),
  'designElementMaps set in new()');

ok(eq_array($designelementmapping->setDesignElementMaps([$designelementmaps_assn]), [$designelementmaps_assn]),
   'setDesignElementMaps returns correct value');

ok((UNIVERSAL::isa($designelementmapping->getDesignElementMaps,'ARRAY')
 and scalar @{$designelementmapping->getDesignElementMaps} == 1
 and $designelementmapping->getDesignElementMaps->[0] == $designelementmaps_assn),
   'getDesignElementMaps fetches correct value');

is($designelementmapping->addDesignElementMaps($designelementmaps_assn), 2,
  'addDesignElementMaps returns number of items in list');

ok((UNIVERSAL::isa($designelementmapping->getDesignElementMaps,'ARRAY')
 and scalar @{$designelementmapping->getDesignElementMaps} == 2
 and $designelementmapping->getDesignElementMaps->[0] == $designelementmaps_assn
 and $designelementmapping->getDesignElementMaps->[1] == $designelementmaps_assn),
  'addDesignElementMaps adds correct value');

# test setDesignElementMaps throws exception with non-array argument
eval {$designelementmapping->setDesignElementMaps(1)};
ok($@, 'setDesignElementMaps throws exception with non-array argument');

# test setDesignElementMaps throws exception with bad argument array
eval {$designelementmapping->setDesignElementMaps([1])};
ok($@, 'setDesignElementMaps throws exception with bad argument array');

# test addDesignElementMaps throws exception with no arguments
eval {$designelementmapping->addDesignElementMaps()};
ok($@, 'addDesignElementMaps throws exception with no arguments');

# test addDesignElementMaps throws exception with bad argument
eval {$designelementmapping->addDesignElementMaps(1)};
ok($@, 'addDesignElementMaps throws exception with bad array');

# test setDesignElementMaps accepts empty array ref
eval {$designelementmapping->setDesignElementMaps([])};
ok((!$@ and defined $designelementmapping->getDesignElementMaps()
    and UNIVERSAL::isa($designelementmapping->getDesignElementMaps, 'ARRAY')
    and scalar @{$designelementmapping->getDesignElementMaps} == 0),
   'setDesignElementMaps accepts empty array ref');


# test getDesignElementMaps throws exception with argument
eval {$designelementmapping->getDesignElementMaps(1)};
ok($@, 'getDesignElementMaps throws exception with argument');

# test setDesignElementMaps throws exception with no argument
eval {$designelementmapping->setDesignElementMaps()};
ok($@, 'setDesignElementMaps throws exception with no argument');

# test setDesignElementMaps throws exception with too many argument
eval {$designelementmapping->setDesignElementMaps(1,2)};
ok($@, 'setDesignElementMaps throws exception with too many argument');

# test setDesignElementMaps accepts undef
eval {$designelementmapping->setDesignElementMaps(undef)};
ok((!$@ and not defined $designelementmapping->getDesignElementMaps()),
   'setDesignElementMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{designElementMaps};
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
   'designElementMaps->other() is a valid Bio::MAGE::Association::End'
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
   'designElementMaps->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($designelementmapping, q[Bio::MAGE::Extendable]);

