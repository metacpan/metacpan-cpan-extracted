##############################
#
# DatabaseEntry.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DatabaseEntry.t`

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

BEGIN { use_ok('Bio::MAGE::Description::DatabaseEntry') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Description::Database;
use Bio::MAGE::NameValueType;


# we test the new() method
my $databaseentry;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $databaseentry = Bio::MAGE::Description::DatabaseEntry->new();
}
isa_ok($databaseentry, 'Bio::MAGE::Description::DatabaseEntry');

# test the package_name class method
is($databaseentry->package_name(), q[Description],
  'package');

# test the class_name class method
is($databaseentry->class_name(), q[Bio::MAGE::Description::DatabaseEntry],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $databaseentry = Bio::MAGE::Description::DatabaseEntry->new(accessionVersion => '1',
URI => '2',
accession => '3');
}


#
# testing attribute accessionVersion
#

# test attribute values can be set in new()
is($databaseentry->getAccessionVersion(), '1',
  'accessionVersion new');

# test getter/setter
$databaseentry->setAccessionVersion('1');
is($databaseentry->getAccessionVersion(), '1',
  'accessionVersion getter/setter');

# test getter throws exception with argument
eval {$databaseentry->getAccessionVersion(1)};
ok($@, 'accessionVersion getter throws exception with argument');

# test setter throws exception with no argument
eval {$databaseentry->setAccessionVersion()};
ok($@, 'accessionVersion setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$databaseentry->setAccessionVersion('1', '1')};
ok($@, 'accessionVersion setter throws exception with too many argument');

# test setter accepts undef
eval {$databaseentry->setAccessionVersion(undef)};
ok((!$@ and not defined $databaseentry->getAccessionVersion()),
   'accessionVersion setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($databaseentry->getURI(), '2',
  'URI new');

# test getter/setter
$databaseentry->setURI('2');
is($databaseentry->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$databaseentry->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$databaseentry->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$databaseentry->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$databaseentry->setURI(undef)};
ok((!$@ and not defined $databaseentry->getURI()),
   'URI setter accepts undef');



#
# testing attribute accession
#

# test attribute values can be set in new()
is($databaseentry->getAccession(), '3',
  'accession new');

# test getter/setter
$databaseentry->setAccession('3');
is($databaseentry->getAccession(), '3',
  'accession getter/setter');

# test getter throws exception with argument
eval {$databaseentry->getAccession(1)};
ok($@, 'accession getter throws exception with argument');

# test setter throws exception with no argument
eval {$databaseentry->setAccession()};
ok($@, 'accession setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$databaseentry->setAccession('3', '3')};
ok($@, 'accession setter throws exception with too many argument');

# test setter accepts undef
eval {$databaseentry->setAccession(undef)};
ok((!$@ and not defined $databaseentry->getAccession()),
   'accession setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Description::DatabaseEntry->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $databaseentry = Bio::MAGE::Description::DatabaseEntry->new(database => Bio::MAGE::Description::Database->new(),
type => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association database
my $database_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $database_assn = Bio::MAGE::Description::Database->new();
}


isa_ok($databaseentry->getDatabase, q[Bio::MAGE::Description::Database]);

is($databaseentry->setDatabase($database_assn), $database_assn,
  'setDatabase returns value');

ok($databaseentry->getDatabase() == $database_assn,
   'getDatabase fetches correct value');

# test setDatabase throws exception with bad argument
eval {$databaseentry->setDatabase(1)};
ok($@, 'setDatabase throws exception with bad argument');


# test getDatabase throws exception with argument
eval {$databaseentry->getDatabase(1)};
ok($@, 'getDatabase throws exception with argument');

# test setDatabase throws exception with no argument
eval {$databaseentry->setDatabase()};
ok($@, 'setDatabase throws exception with no argument');

# test setDatabase throws exception with too many argument
eval {$databaseentry->setDatabase(1,2)};
ok($@, 'setDatabase throws exception with too many argument');

# test setDatabase accepts undef
eval {$databaseentry->setDatabase(undef)};
ok((!$@ and not defined $databaseentry->getDatabase()),
   'setDatabase accepts undef');

# test the meta-data for the assoication
$assn = $assns{database};
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
   'database->other() is a valid Bio::MAGE::Association::End'
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
   'database->self() is a valid Bio::MAGE::Association::End'
  );



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($databaseentry->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($databaseentry->setType($type_assn), $type_assn,
  'setType returns value');

ok($databaseentry->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$databaseentry->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$databaseentry->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$databaseentry->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$databaseentry->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$databaseentry->setType(undef)};
ok((!$@ and not defined $databaseentry->getType()),
   'setType accepts undef');

# test the meta-data for the assoication
$assn = $assns{type};
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
   'type->other() is a valid Bio::MAGE::Association::End'
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
   'type->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($databaseentry->getPropertySets,'ARRAY')
 and scalar @{$databaseentry->getPropertySets} == 1
 and UNIVERSAL::isa($databaseentry->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($databaseentry->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($databaseentry->getPropertySets,'ARRAY')
 and scalar @{$databaseentry->getPropertySets} == 1
 and $databaseentry->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($databaseentry->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($databaseentry->getPropertySets,'ARRAY')
 and scalar @{$databaseentry->getPropertySets} == 2
 and $databaseentry->getPropertySets->[0] == $propertysets_assn
 and $databaseentry->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$databaseentry->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$databaseentry->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$databaseentry->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$databaseentry->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$databaseentry->setPropertySets([])};
ok((!$@ and defined $databaseentry->getPropertySets()
    and UNIVERSAL::isa($databaseentry->getPropertySets, 'ARRAY')
    and scalar @{$databaseentry->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$databaseentry->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$databaseentry->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$databaseentry->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$databaseentry->setPropertySets(undef)};
ok((!$@ and not defined $databaseentry->getPropertySets()),
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
isa_ok($databaseentry, q[Bio::MAGE::Extendable]);

