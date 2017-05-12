##############################
#
# ExperimentalFactor.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ExperimentalFactor.t`

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
use Test::More tests => 139;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Experiment::ExperimentalFactor') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Experiment::FactorValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $experimentalfactor;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentalfactor = Bio::MAGE::Experiment::ExperimentalFactor->new();
}
isa_ok($experimentalfactor, 'Bio::MAGE::Experiment::ExperimentalFactor');

# test the package_name class method
is($experimentalfactor->package_name(), q[Experiment],
  'package');

# test the class_name class method
is($experimentalfactor->class_name(), q[Bio::MAGE::Experiment::ExperimentalFactor],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentalfactor = Bio::MAGE::Experiment::ExperimentalFactor->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($experimentalfactor->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$experimentalfactor->setIdentifier('1');
is($experimentalfactor->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$experimentalfactor->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$experimentalfactor->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$experimentalfactor->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$experimentalfactor->setIdentifier(undef)};
ok((!$@ and not defined $experimentalfactor->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($experimentalfactor->getName(), '2',
  'name new');

# test getter/setter
$experimentalfactor->setName('2');
is($experimentalfactor->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$experimentalfactor->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$experimentalfactor->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$experimentalfactor->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$experimentalfactor->setName(undef)};
ok((!$@ and not defined $experimentalfactor->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Experiment::ExperimentalFactor->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $experimentalfactor = Bio::MAGE::Experiment::ExperimentalFactor->new(descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
category => Bio::MAGE::Description::OntologyEntry->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
factorValues => [Bio::MAGE::Experiment::FactorValue->new()],
annotations => [Bio::MAGE::Description::OntologyEntry->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($experimentalfactor->getDescriptions,'ARRAY')
 and scalar @{$experimentalfactor->getDescriptions} == 1
 and UNIVERSAL::isa($experimentalfactor->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($experimentalfactor->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($experimentalfactor->getDescriptions,'ARRAY')
 and scalar @{$experimentalfactor->getDescriptions} == 1
 and $experimentalfactor->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($experimentalfactor->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($experimentalfactor->getDescriptions,'ARRAY')
 and scalar @{$experimentalfactor->getDescriptions} == 2
 and $experimentalfactor->getDescriptions->[0] == $descriptions_assn
 and $experimentalfactor->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$experimentalfactor->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$experimentalfactor->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$experimentalfactor->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$experimentalfactor->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$experimentalfactor->setDescriptions([])};
ok((!$@ and defined $experimentalfactor->getDescriptions()
    and UNIVERSAL::isa($experimentalfactor->getDescriptions, 'ARRAY')
    and scalar @{$experimentalfactor->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$experimentalfactor->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$experimentalfactor->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$experimentalfactor->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$experimentalfactor->setDescriptions(undef)};
ok((!$@ and not defined $experimentalfactor->getDescriptions()),
   'setDescriptions accepts undef');

# test the meta-data for the assoication
$assn = $assns{descriptions};
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
   'descriptions->other() is a valid Bio::MAGE::Association::End'
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
   'descriptions->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($experimentalfactor->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($experimentalfactor->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($experimentalfactor->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$experimentalfactor->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$experimentalfactor->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$experimentalfactor->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$experimentalfactor->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$experimentalfactor->setSecurity(undef)};
ok((!$@ and not defined $experimentalfactor->getSecurity()),
   'setSecurity accepts undef');

# test the meta-data for the assoication
$assn = $assns{security};
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
   'security->other() is a valid Bio::MAGE::Association::End'
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
   'security->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($experimentalfactor->getAuditTrail,'ARRAY')
 and scalar @{$experimentalfactor->getAuditTrail} == 1
 and UNIVERSAL::isa($experimentalfactor->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($experimentalfactor->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($experimentalfactor->getAuditTrail,'ARRAY')
 and scalar @{$experimentalfactor->getAuditTrail} == 1
 and $experimentalfactor->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($experimentalfactor->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($experimentalfactor->getAuditTrail,'ARRAY')
 and scalar @{$experimentalfactor->getAuditTrail} == 2
 and $experimentalfactor->getAuditTrail->[0] == $audittrail_assn
 and $experimentalfactor->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$experimentalfactor->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$experimentalfactor->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$experimentalfactor->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$experimentalfactor->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$experimentalfactor->setAuditTrail([])};
ok((!$@ and defined $experimentalfactor->getAuditTrail()
    and UNIVERSAL::isa($experimentalfactor->getAuditTrail, 'ARRAY')
    and scalar @{$experimentalfactor->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$experimentalfactor->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$experimentalfactor->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$experimentalfactor->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$experimentalfactor->setAuditTrail(undef)};
ok((!$@ and not defined $experimentalfactor->getAuditTrail()),
   'setAuditTrail accepts undef');

# test the meta-data for the assoication
$assn = $assns{auditTrail};
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
   'auditTrail->other() is a valid Bio::MAGE::Association::End'
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
   'auditTrail->self() is a valid Bio::MAGE::Association::End'
  );



# testing association category
my $category_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $category_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($experimentalfactor->getCategory, q[Bio::MAGE::Description::OntologyEntry]);

is($experimentalfactor->setCategory($category_assn), $category_assn,
  'setCategory returns value');

ok($experimentalfactor->getCategory() == $category_assn,
   'getCategory fetches correct value');

# test setCategory throws exception with bad argument
eval {$experimentalfactor->setCategory(1)};
ok($@, 'setCategory throws exception with bad argument');


# test getCategory throws exception with argument
eval {$experimentalfactor->getCategory(1)};
ok($@, 'getCategory throws exception with argument');

# test setCategory throws exception with no argument
eval {$experimentalfactor->setCategory()};
ok($@, 'setCategory throws exception with no argument');

# test setCategory throws exception with too many argument
eval {$experimentalfactor->setCategory(1,2)};
ok($@, 'setCategory throws exception with too many argument');

# test setCategory accepts undef
eval {$experimentalfactor->setCategory(undef)};
ok((!$@ and not defined $experimentalfactor->getCategory()),
   'setCategory accepts undef');

# test the meta-data for the assoication
$assn = $assns{category};
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
   'category->other() is a valid Bio::MAGE::Association::End'
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
   'category->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($experimentalfactor->getPropertySets,'ARRAY')
 and scalar @{$experimentalfactor->getPropertySets} == 1
 and UNIVERSAL::isa($experimentalfactor->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($experimentalfactor->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($experimentalfactor->getPropertySets,'ARRAY')
 and scalar @{$experimentalfactor->getPropertySets} == 1
 and $experimentalfactor->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($experimentalfactor->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($experimentalfactor->getPropertySets,'ARRAY')
 and scalar @{$experimentalfactor->getPropertySets} == 2
 and $experimentalfactor->getPropertySets->[0] == $propertysets_assn
 and $experimentalfactor->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$experimentalfactor->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$experimentalfactor->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$experimentalfactor->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$experimentalfactor->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$experimentalfactor->setPropertySets([])};
ok((!$@ and defined $experimentalfactor->getPropertySets()
    and UNIVERSAL::isa($experimentalfactor->getPropertySets, 'ARRAY')
    and scalar @{$experimentalfactor->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$experimentalfactor->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$experimentalfactor->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$experimentalfactor->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$experimentalfactor->setPropertySets(undef)};
ok((!$@ and not defined $experimentalfactor->getPropertySets()),
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



# testing association factorValues
my $factorvalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $factorvalues_assn = Bio::MAGE::Experiment::FactorValue->new();
}


ok((UNIVERSAL::isa($experimentalfactor->getFactorValues,'ARRAY')
 and scalar @{$experimentalfactor->getFactorValues} == 1
 and UNIVERSAL::isa($experimentalfactor->getFactorValues->[0], q[Bio::MAGE::Experiment::FactorValue])),
  'factorValues set in new()');

ok(eq_array($experimentalfactor->setFactorValues([$factorvalues_assn]), [$factorvalues_assn]),
   'setFactorValues returns correct value');

ok((UNIVERSAL::isa($experimentalfactor->getFactorValues,'ARRAY')
 and scalar @{$experimentalfactor->getFactorValues} == 1
 and $experimentalfactor->getFactorValues->[0] == $factorvalues_assn),
   'getFactorValues fetches correct value');

is($experimentalfactor->addFactorValues($factorvalues_assn), 2,
  'addFactorValues returns number of items in list');

ok((UNIVERSAL::isa($experimentalfactor->getFactorValues,'ARRAY')
 and scalar @{$experimentalfactor->getFactorValues} == 2
 and $experimentalfactor->getFactorValues->[0] == $factorvalues_assn
 and $experimentalfactor->getFactorValues->[1] == $factorvalues_assn),
  'addFactorValues adds correct value');

# test setFactorValues throws exception with non-array argument
eval {$experimentalfactor->setFactorValues(1)};
ok($@, 'setFactorValues throws exception with non-array argument');

# test setFactorValues throws exception with bad argument array
eval {$experimentalfactor->setFactorValues([1])};
ok($@, 'setFactorValues throws exception with bad argument array');

# test addFactorValues throws exception with no arguments
eval {$experimentalfactor->addFactorValues()};
ok($@, 'addFactorValues throws exception with no arguments');

# test addFactorValues throws exception with bad argument
eval {$experimentalfactor->addFactorValues(1)};
ok($@, 'addFactorValues throws exception with bad array');

# test setFactorValues accepts empty array ref
eval {$experimentalfactor->setFactorValues([])};
ok((!$@ and defined $experimentalfactor->getFactorValues()
    and UNIVERSAL::isa($experimentalfactor->getFactorValues, 'ARRAY')
    and scalar @{$experimentalfactor->getFactorValues} == 0),
   'setFactorValues accepts empty array ref');


# test getFactorValues throws exception with argument
eval {$experimentalfactor->getFactorValues(1)};
ok($@, 'getFactorValues throws exception with argument');

# test setFactorValues throws exception with no argument
eval {$experimentalfactor->setFactorValues()};
ok($@, 'setFactorValues throws exception with no argument');

# test setFactorValues throws exception with too many argument
eval {$experimentalfactor->setFactorValues(1,2)};
ok($@, 'setFactorValues throws exception with too many argument');

# test setFactorValues accepts undef
eval {$experimentalfactor->setFactorValues(undef)};
ok((!$@ and not defined $experimentalfactor->getFactorValues()),
   'setFactorValues accepts undef');

# test the meta-data for the assoication
$assn = $assns{factorValues};
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
   'factorValues->other() is a valid Bio::MAGE::Association::End'
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
   'factorValues->self() is a valid Bio::MAGE::Association::End'
  );



# testing association annotations
my $annotations_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $annotations_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($experimentalfactor->getAnnotations,'ARRAY')
 and scalar @{$experimentalfactor->getAnnotations} == 1
 and UNIVERSAL::isa($experimentalfactor->getAnnotations->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'annotations set in new()');

ok(eq_array($experimentalfactor->setAnnotations([$annotations_assn]), [$annotations_assn]),
   'setAnnotations returns correct value');

ok((UNIVERSAL::isa($experimentalfactor->getAnnotations,'ARRAY')
 and scalar @{$experimentalfactor->getAnnotations} == 1
 and $experimentalfactor->getAnnotations->[0] == $annotations_assn),
   'getAnnotations fetches correct value');

is($experimentalfactor->addAnnotations($annotations_assn), 2,
  'addAnnotations returns number of items in list');

ok((UNIVERSAL::isa($experimentalfactor->getAnnotations,'ARRAY')
 and scalar @{$experimentalfactor->getAnnotations} == 2
 and $experimentalfactor->getAnnotations->[0] == $annotations_assn
 and $experimentalfactor->getAnnotations->[1] == $annotations_assn),
  'addAnnotations adds correct value');

# test setAnnotations throws exception with non-array argument
eval {$experimentalfactor->setAnnotations(1)};
ok($@, 'setAnnotations throws exception with non-array argument');

# test setAnnotations throws exception with bad argument array
eval {$experimentalfactor->setAnnotations([1])};
ok($@, 'setAnnotations throws exception with bad argument array');

# test addAnnotations throws exception with no arguments
eval {$experimentalfactor->addAnnotations()};
ok($@, 'addAnnotations throws exception with no arguments');

# test addAnnotations throws exception with bad argument
eval {$experimentalfactor->addAnnotations(1)};
ok($@, 'addAnnotations throws exception with bad array');

# test setAnnotations accepts empty array ref
eval {$experimentalfactor->setAnnotations([])};
ok((!$@ and defined $experimentalfactor->getAnnotations()
    and UNIVERSAL::isa($experimentalfactor->getAnnotations, 'ARRAY')
    and scalar @{$experimentalfactor->getAnnotations} == 0),
   'setAnnotations accepts empty array ref');


# test getAnnotations throws exception with argument
eval {$experimentalfactor->getAnnotations(1)};
ok($@, 'getAnnotations throws exception with argument');

# test setAnnotations throws exception with no argument
eval {$experimentalfactor->setAnnotations()};
ok($@, 'setAnnotations throws exception with no argument');

# test setAnnotations throws exception with too many argument
eval {$experimentalfactor->setAnnotations(1,2)};
ok($@, 'setAnnotations throws exception with too many argument');

# test setAnnotations accepts undef
eval {$experimentalfactor->setAnnotations(undef)};
ok((!$@ and not defined $experimentalfactor->getAnnotations()),
   'setAnnotations accepts undef');

# test the meta-data for the assoication
$assn = $assns{annotations};
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
   'annotations->other() is a valid Bio::MAGE::Association::End'
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
   'annotations->self() is a valid Bio::MAGE::Association::End'
  );





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($experimentalfactor, q[Bio::MAGE::Identifiable]);

