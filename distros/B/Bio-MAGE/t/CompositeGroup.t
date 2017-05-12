##############################
#
# CompositeGroup.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompositeGroup.t`

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

BEGIN { use_ok('Bio::MAGE::ArrayDesign::CompositeGroup') };

use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $compositegroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositegroup = Bio::MAGE::ArrayDesign::CompositeGroup->new();
}
isa_ok($compositegroup, 'Bio::MAGE::ArrayDesign::CompositeGroup');

# test the package_name class method
is($compositegroup->package_name(), q[ArrayDesign],
  'package');

# test the class_name class method
is($compositegroup->class_name(), q[Bio::MAGE::ArrayDesign::CompositeGroup],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositegroup = Bio::MAGE::ArrayDesign::CompositeGroup->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($compositegroup->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$compositegroup->setIdentifier('1');
is($compositegroup->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$compositegroup->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositegroup->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositegroup->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$compositegroup->setIdentifier(undef)};
ok((!$@ and not defined $compositegroup->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($compositegroup->getName(), '2',
  'name new');

# test getter/setter
$compositegroup->setName('2');
is($compositegroup->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$compositegroup->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositegroup->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositegroup->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$compositegroup->setName(undef)};
ok((!$@ and not defined $compositegroup->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::ArrayDesign::CompositeGroup->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositegroup = Bio::MAGE::ArrayDesign::CompositeGroup->new(types => [Bio::MAGE::Description::OntologyEntry->new()],
compositeSequences => [Bio::MAGE::DesignElement::CompositeSequence->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
species => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association types
my $types_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $types_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($compositegroup->getTypes,'ARRAY')
 and scalar @{$compositegroup->getTypes} == 1
 and UNIVERSAL::isa($compositegroup->getTypes->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'types set in new()');

ok(eq_array($compositegroup->setTypes([$types_assn]), [$types_assn]),
   'setTypes returns correct value');

ok((UNIVERSAL::isa($compositegroup->getTypes,'ARRAY')
 and scalar @{$compositegroup->getTypes} == 1
 and $compositegroup->getTypes->[0] == $types_assn),
   'getTypes fetches correct value');

is($compositegroup->addTypes($types_assn), 2,
  'addTypes returns number of items in list');

ok((UNIVERSAL::isa($compositegroup->getTypes,'ARRAY')
 and scalar @{$compositegroup->getTypes} == 2
 and $compositegroup->getTypes->[0] == $types_assn
 and $compositegroup->getTypes->[1] == $types_assn),
  'addTypes adds correct value');

# test setTypes throws exception with non-array argument
eval {$compositegroup->setTypes(1)};
ok($@, 'setTypes throws exception with non-array argument');

# test setTypes throws exception with bad argument array
eval {$compositegroup->setTypes([1])};
ok($@, 'setTypes throws exception with bad argument array');

# test addTypes throws exception with no arguments
eval {$compositegroup->addTypes()};
ok($@, 'addTypes throws exception with no arguments');

# test addTypes throws exception with bad argument
eval {$compositegroup->addTypes(1)};
ok($@, 'addTypes throws exception with bad array');

# test setTypes accepts empty array ref
eval {$compositegroup->setTypes([])};
ok((!$@ and defined $compositegroup->getTypes()
    and UNIVERSAL::isa($compositegroup->getTypes, 'ARRAY')
    and scalar @{$compositegroup->getTypes} == 0),
   'setTypes accepts empty array ref');


# test getTypes throws exception with argument
eval {$compositegroup->getTypes(1)};
ok($@, 'getTypes throws exception with argument');

# test setTypes throws exception with no argument
eval {$compositegroup->setTypes()};
ok($@, 'setTypes throws exception with no argument');

# test setTypes throws exception with too many argument
eval {$compositegroup->setTypes(1,2)};
ok($@, 'setTypes throws exception with too many argument');

# test setTypes accepts undef
eval {$compositegroup->setTypes(undef)};
ok((!$@ and not defined $compositegroup->getTypes()),
   'setTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{types};
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
   'types->other() is a valid Bio::MAGE::Association::End'
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
   'types->self() is a valid Bio::MAGE::Association::End'
  );



# testing association compositeSequences
my $compositesequences_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequences_assn = Bio::MAGE::DesignElement::CompositeSequence->new();
}


ok((UNIVERSAL::isa($compositegroup->getCompositeSequences,'ARRAY')
 and scalar @{$compositegroup->getCompositeSequences} == 1
 and UNIVERSAL::isa($compositegroup->getCompositeSequences->[0], q[Bio::MAGE::DesignElement::CompositeSequence])),
  'compositeSequences set in new()');

ok(eq_array($compositegroup->setCompositeSequences([$compositesequences_assn]), [$compositesequences_assn]),
   'setCompositeSequences returns correct value');

ok((UNIVERSAL::isa($compositegroup->getCompositeSequences,'ARRAY')
 and scalar @{$compositegroup->getCompositeSequences} == 1
 and $compositegroup->getCompositeSequences->[0] == $compositesequences_assn),
   'getCompositeSequences fetches correct value');

is($compositegroup->addCompositeSequences($compositesequences_assn), 2,
  'addCompositeSequences returns number of items in list');

ok((UNIVERSAL::isa($compositegroup->getCompositeSequences,'ARRAY')
 and scalar @{$compositegroup->getCompositeSequences} == 2
 and $compositegroup->getCompositeSequences->[0] == $compositesequences_assn
 and $compositegroup->getCompositeSequences->[1] == $compositesequences_assn),
  'addCompositeSequences adds correct value');

# test setCompositeSequences throws exception with non-array argument
eval {$compositegroup->setCompositeSequences(1)};
ok($@, 'setCompositeSequences throws exception with non-array argument');

# test setCompositeSequences throws exception with bad argument array
eval {$compositegroup->setCompositeSequences([1])};
ok($@, 'setCompositeSequences throws exception with bad argument array');

# test addCompositeSequences throws exception with no arguments
eval {$compositegroup->addCompositeSequences()};
ok($@, 'addCompositeSequences throws exception with no arguments');

# test addCompositeSequences throws exception with bad argument
eval {$compositegroup->addCompositeSequences(1)};
ok($@, 'addCompositeSequences throws exception with bad array');

# test setCompositeSequences accepts empty array ref
eval {$compositegroup->setCompositeSequences([])};
ok((!$@ and defined $compositegroup->getCompositeSequences()
    and UNIVERSAL::isa($compositegroup->getCompositeSequences, 'ARRAY')
    and scalar @{$compositegroup->getCompositeSequences} == 0),
   'setCompositeSequences accepts empty array ref');


# test getCompositeSequences throws exception with argument
eval {$compositegroup->getCompositeSequences(1)};
ok($@, 'getCompositeSequences throws exception with argument');

# test setCompositeSequences throws exception with no argument
eval {$compositegroup->setCompositeSequences()};
ok($@, 'setCompositeSequences throws exception with no argument');

# test setCompositeSequences throws exception with too many argument
eval {$compositegroup->setCompositeSequences(1,2)};
ok($@, 'setCompositeSequences throws exception with too many argument');

# test setCompositeSequences accepts undef
eval {$compositegroup->setCompositeSequences(undef)};
ok((!$@ and not defined $compositegroup->getCompositeSequences()),
   'setCompositeSequences accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeSequences};
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
   'compositeSequences->other() is a valid Bio::MAGE::Association::End'
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
   'compositeSequences->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($compositegroup->getDescriptions,'ARRAY')
 and scalar @{$compositegroup->getDescriptions} == 1
 and UNIVERSAL::isa($compositegroup->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($compositegroup->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($compositegroup->getDescriptions,'ARRAY')
 and scalar @{$compositegroup->getDescriptions} == 1
 and $compositegroup->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($compositegroup->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($compositegroup->getDescriptions,'ARRAY')
 and scalar @{$compositegroup->getDescriptions} == 2
 and $compositegroup->getDescriptions->[0] == $descriptions_assn
 and $compositegroup->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$compositegroup->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$compositegroup->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$compositegroup->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$compositegroup->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$compositegroup->setDescriptions([])};
ok((!$@ and defined $compositegroup->getDescriptions()
    and UNIVERSAL::isa($compositegroup->getDescriptions, 'ARRAY')
    and scalar @{$compositegroup->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$compositegroup->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$compositegroup->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$compositegroup->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$compositegroup->setDescriptions(undef)};
ok((!$@ and not defined $compositegroup->getDescriptions()),
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



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($compositegroup->getAuditTrail,'ARRAY')
 and scalar @{$compositegroup->getAuditTrail} == 1
 and UNIVERSAL::isa($compositegroup->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($compositegroup->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($compositegroup->getAuditTrail,'ARRAY')
 and scalar @{$compositegroup->getAuditTrail} == 1
 and $compositegroup->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($compositegroup->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($compositegroup->getAuditTrail,'ARRAY')
 and scalar @{$compositegroup->getAuditTrail} == 2
 and $compositegroup->getAuditTrail->[0] == $audittrail_assn
 and $compositegroup->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$compositegroup->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$compositegroup->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$compositegroup->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$compositegroup->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$compositegroup->setAuditTrail([])};
ok((!$@ and defined $compositegroup->getAuditTrail()
    and UNIVERSAL::isa($compositegroup->getAuditTrail, 'ARRAY')
    and scalar @{$compositegroup->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$compositegroup->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$compositegroup->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$compositegroup->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$compositegroup->setAuditTrail(undef)};
ok((!$@ and not defined $compositegroup->getAuditTrail()),
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



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($compositegroup->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($compositegroup->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($compositegroup->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$compositegroup->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$compositegroup->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$compositegroup->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$compositegroup->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$compositegroup->setSecurity(undef)};
ok((!$@ and not defined $compositegroup->getSecurity()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($compositegroup->getPropertySets,'ARRAY')
 and scalar @{$compositegroup->getPropertySets} == 1
 and UNIVERSAL::isa($compositegroup->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compositegroup->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compositegroup->getPropertySets,'ARRAY')
 and scalar @{$compositegroup->getPropertySets} == 1
 and $compositegroup->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compositegroup->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compositegroup->getPropertySets,'ARRAY')
 and scalar @{$compositegroup->getPropertySets} == 2
 and $compositegroup->getPropertySets->[0] == $propertysets_assn
 and $compositegroup->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compositegroup->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compositegroup->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compositegroup->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compositegroup->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compositegroup->setPropertySets([])};
ok((!$@ and defined $compositegroup->getPropertySets()
    and UNIVERSAL::isa($compositegroup->getPropertySets, 'ARRAY')
    and scalar @{$compositegroup->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compositegroup->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compositegroup->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compositegroup->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compositegroup->setPropertySets(undef)};
ok((!$@ and not defined $compositegroup->getPropertySets()),
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



# testing association species
my $species_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $species_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($compositegroup->getSpecies, q[Bio::MAGE::Description::OntologyEntry]);

is($compositegroup->setSpecies($species_assn), $species_assn,
  'setSpecies returns value');

ok($compositegroup->getSpecies() == $species_assn,
   'getSpecies fetches correct value');

# test setSpecies throws exception with bad argument
eval {$compositegroup->setSpecies(1)};
ok($@, 'setSpecies throws exception with bad argument');


# test getSpecies throws exception with argument
eval {$compositegroup->getSpecies(1)};
ok($@, 'getSpecies throws exception with argument');

# test setSpecies throws exception with no argument
eval {$compositegroup->setSpecies()};
ok($@, 'setSpecies throws exception with no argument');

# test setSpecies throws exception with too many argument
eval {$compositegroup->setSpecies(1,2)};
ok($@, 'setSpecies throws exception with too many argument');

# test setSpecies accepts undef
eval {$compositegroup->setSpecies(undef)};
ok((!$@ and not defined $compositegroup->getSpecies()),
   'setSpecies accepts undef');

# test the meta-data for the assoication
$assn = $assns{species};
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
   'species->other() is a valid Bio::MAGE::Association::End'
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
   'species->self() is a valid Bio::MAGE::Association::End'
  );





my $designelementgroup;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementgroup = Bio::MAGE::ArrayDesign::DesignElementGroup->new();
}

# testing superclass DesignElementGroup
isa_ok($designelementgroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);
isa_ok($compositegroup, q[Bio::MAGE::ArrayDesign::DesignElementGroup]);

