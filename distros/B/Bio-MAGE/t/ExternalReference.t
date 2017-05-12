##############################
#
# ExternalReference.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ExternalReference.t`

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
use Test::More tests => 49;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Description::ExternalReference') };

use Bio::MAGE::NameValueType;


# we test the new() method
my $externalreference;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $externalreference = Bio::MAGE::Description::ExternalReference->new();
}
isa_ok($externalreference, 'Bio::MAGE::Description::ExternalReference');

# test the package_name class method
is($externalreference->package_name(), q[Description],
  'package');

# test the class_name class method
is($externalreference->class_name(), q[Bio::MAGE::Description::ExternalReference],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $externalreference = Bio::MAGE::Description::ExternalReference->new(exportedFromDB => '1',
exportName => '2',
exportedFromServer => '3',
exportID => '4');
}


#
# testing attribute exportedFromDB
#

# test attribute values can be set in new()
is($externalreference->getExportedFromDB(), '1',
  'exportedFromDB new');

# test getter/setter
$externalreference->setExportedFromDB('1');
is($externalreference->getExportedFromDB(), '1',
  'exportedFromDB getter/setter');

# test getter throws exception with argument
eval {$externalreference->getExportedFromDB(1)};
ok($@, 'exportedFromDB getter throws exception with argument');

# test setter throws exception with no argument
eval {$externalreference->setExportedFromDB()};
ok($@, 'exportedFromDB setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$externalreference->setExportedFromDB('1', '1')};
ok($@, 'exportedFromDB setter throws exception with too many argument');

# test setter accepts undef
eval {$externalreference->setExportedFromDB(undef)};
ok((!$@ and not defined $externalreference->getExportedFromDB()),
   'exportedFromDB setter accepts undef');



#
# testing attribute exportName
#

# test attribute values can be set in new()
is($externalreference->getExportName(), '2',
  'exportName new');

# test getter/setter
$externalreference->setExportName('2');
is($externalreference->getExportName(), '2',
  'exportName getter/setter');

# test getter throws exception with argument
eval {$externalreference->getExportName(1)};
ok($@, 'exportName getter throws exception with argument');

# test setter throws exception with no argument
eval {$externalreference->setExportName()};
ok($@, 'exportName setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$externalreference->setExportName('2', '2')};
ok($@, 'exportName setter throws exception with too many argument');

# test setter accepts undef
eval {$externalreference->setExportName(undef)};
ok((!$@ and not defined $externalreference->getExportName()),
   'exportName setter accepts undef');



#
# testing attribute exportedFromServer
#

# test attribute values can be set in new()
is($externalreference->getExportedFromServer(), '3',
  'exportedFromServer new');

# test getter/setter
$externalreference->setExportedFromServer('3');
is($externalreference->getExportedFromServer(), '3',
  'exportedFromServer getter/setter');

# test getter throws exception with argument
eval {$externalreference->getExportedFromServer(1)};
ok($@, 'exportedFromServer getter throws exception with argument');

# test setter throws exception with no argument
eval {$externalreference->setExportedFromServer()};
ok($@, 'exportedFromServer setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$externalreference->setExportedFromServer('3', '3')};
ok($@, 'exportedFromServer setter throws exception with too many argument');

# test setter accepts undef
eval {$externalreference->setExportedFromServer(undef)};
ok((!$@ and not defined $externalreference->getExportedFromServer()),
   'exportedFromServer setter accepts undef');



#
# testing attribute exportID
#

# test attribute values can be set in new()
is($externalreference->getExportID(), '4',
  'exportID new');

# test getter/setter
$externalreference->setExportID('4');
is($externalreference->getExportID(), '4',
  'exportID getter/setter');

# test getter throws exception with argument
eval {$externalreference->getExportID(1)};
ok($@, 'exportID getter throws exception with argument');

# test setter throws exception with no argument
eval {$externalreference->setExportID()};
ok($@, 'exportID setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$externalreference->setExportID('4', '4')};
ok($@, 'exportID setter throws exception with too many argument');

# test setter accepts undef
eval {$externalreference->setExportID(undef)};
ok((!$@ and not defined $externalreference->getExportID()),
   'exportID setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Description::ExternalReference->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $externalreference = Bio::MAGE::Description::ExternalReference->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($externalreference->getPropertySets,'ARRAY')
 and scalar @{$externalreference->getPropertySets} == 1
 and UNIVERSAL::isa($externalreference->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($externalreference->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($externalreference->getPropertySets,'ARRAY')
 and scalar @{$externalreference->getPropertySets} == 1
 and $externalreference->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($externalreference->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($externalreference->getPropertySets,'ARRAY')
 and scalar @{$externalreference->getPropertySets} == 2
 and $externalreference->getPropertySets->[0] == $propertysets_assn
 and $externalreference->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$externalreference->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$externalreference->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$externalreference->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$externalreference->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$externalreference->setPropertySets([])};
ok((!$@ and defined $externalreference->getPropertySets()
    and UNIVERSAL::isa($externalreference->getPropertySets, 'ARRAY')
    and scalar @{$externalreference->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$externalreference->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$externalreference->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$externalreference->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$externalreference->setPropertySets(undef)};
ok((!$@ and not defined $externalreference->getPropertySets()),
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
isa_ok($externalreference, q[Bio::MAGE::Extendable]);

