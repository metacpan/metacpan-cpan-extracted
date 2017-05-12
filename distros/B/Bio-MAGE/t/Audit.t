##############################
#
# Audit.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Audit.t`

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
use Test::More tests => 104;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::AuditAndSecurity::Audit') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;


# we test the new() method
my $audit;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audit = Bio::MAGE::AuditAndSecurity::Audit->new();
}
isa_ok($audit, 'Bio::MAGE::AuditAndSecurity::Audit');

# test the package_name class method
is($audit->package_name(), q[AuditAndSecurity],
  'package');

# test the class_name class method
is($audit->class_name(), q[Bio::MAGE::AuditAndSecurity::Audit],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audit = Bio::MAGE::AuditAndSecurity::Audit->new(date => '1',
action => 'creation');
}


#
# testing attribute date
#

# test attribute values can be set in new()
is($audit->getDate(), '1',
  'date new');

# test getter/setter
$audit->setDate('1');
is($audit->getDate(), '1',
  'date getter/setter');

# test getter throws exception with argument
eval {$audit->getDate(1)};
ok($@, 'date getter throws exception with argument');

# test setter throws exception with no argument
eval {$audit->setDate()};
ok($@, 'date setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$audit->setDate('1', '1')};
ok($@, 'date setter throws exception with too many argument');

# test setter accepts undef
eval {$audit->setDate(undef)};
ok((!$@ and not defined $audit->getDate()),
   'date setter accepts undef');



#
# testing attribute action
#

# test attribute values can be set in new()
is($audit->getAction(), 'creation',
  'action new');

# test getter/setter
$audit->setAction('creation');
is($audit->getAction(), 'creation',
  'action getter/setter');

# test getter throws exception with argument
eval {$audit->getAction(1)};
ok($@, 'action getter throws exception with argument');

# test setter throws exception with no argument
eval {$audit->setAction()};
ok($@, 'action setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$audit->setAction('creation', 'creation')};
ok($@, 'action setter throws exception with too many argument');

# test setter accepts undef
eval {$audit->setAction(undef)};
ok((!$@ and not defined $audit->getAction()),
   'action setter accepts undef');


# test setter throws exception with bad argument
eval {$audit->setAction(1)};
ok($@, 'action setter throws exception with bad argument');


# test setter accepts enumerated value: creation

eval {$audit->setAction('creation')};
ok((not $@ and $audit->getAction() eq 'creation'),
   'action accepts creation');


# test setter accepts enumerated value: modification

eval {$audit->setAction('modification')};
ok((not $@ and $audit->getAction() eq 'modification'),
   'action accepts modification');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::AuditAndSecurity::Audit->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audit = Bio::MAGE::AuditAndSecurity::Audit->new(performer => Bio::MAGE::AuditAndSecurity::Contact->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association performer
my $performer_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $performer_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


isa_ok($audit->getPerformer, q[Bio::MAGE::AuditAndSecurity::Contact]);

is($audit->setPerformer($performer_assn), $performer_assn,
  'setPerformer returns value');

ok($audit->getPerformer() == $performer_assn,
   'getPerformer fetches correct value');

# test setPerformer throws exception with bad argument
eval {$audit->setPerformer(1)};
ok($@, 'setPerformer throws exception with bad argument');


# test getPerformer throws exception with argument
eval {$audit->getPerformer(1)};
ok($@, 'getPerformer throws exception with argument');

# test setPerformer throws exception with no argument
eval {$audit->setPerformer()};
ok($@, 'setPerformer throws exception with no argument');

# test setPerformer throws exception with too many argument
eval {$audit->setPerformer(1,2)};
ok($@, 'setPerformer throws exception with too many argument');

# test setPerformer accepts undef
eval {$audit->setPerformer(undef)};
ok((!$@ and not defined $audit->getPerformer()),
   'setPerformer accepts undef');

# test the meta-data for the assoication
$assn = $assns{performer};
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
   'performer->other() is a valid Bio::MAGE::Association::End'
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
   'performer->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($audit->getDescriptions,'ARRAY')
 and scalar @{$audit->getDescriptions} == 1
 and UNIVERSAL::isa($audit->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($audit->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($audit->getDescriptions,'ARRAY')
 and scalar @{$audit->getDescriptions} == 1
 and $audit->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($audit->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($audit->getDescriptions,'ARRAY')
 and scalar @{$audit->getDescriptions} == 2
 and $audit->getDescriptions->[0] == $descriptions_assn
 and $audit->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$audit->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$audit->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$audit->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$audit->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$audit->setDescriptions([])};
ok((!$@ and defined $audit->getDescriptions()
    and UNIVERSAL::isa($audit->getDescriptions, 'ARRAY')
    and scalar @{$audit->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$audit->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$audit->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$audit->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$audit->setDescriptions(undef)};
ok((!$@ and not defined $audit->getDescriptions()),
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


ok((UNIVERSAL::isa($audit->getAuditTrail,'ARRAY')
 and scalar @{$audit->getAuditTrail} == 1
 and UNIVERSAL::isa($audit->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($audit->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($audit->getAuditTrail,'ARRAY')
 and scalar @{$audit->getAuditTrail} == 1
 and $audit->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($audit->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($audit->getAuditTrail,'ARRAY')
 and scalar @{$audit->getAuditTrail} == 2
 and $audit->getAuditTrail->[0] == $audittrail_assn
 and $audit->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$audit->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$audit->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$audit->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$audit->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$audit->setAuditTrail([])};
ok((!$@ and defined $audit->getAuditTrail()
    and UNIVERSAL::isa($audit->getAuditTrail, 'ARRAY')
    and scalar @{$audit->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$audit->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$audit->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$audit->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$audit->setAuditTrail(undef)};
ok((!$@ and not defined $audit->getAuditTrail()),
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


isa_ok($audit->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($audit->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($audit->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$audit->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$audit->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$audit->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$audit->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$audit->setSecurity(undef)};
ok((!$@ and not defined $audit->getSecurity()),
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


ok((UNIVERSAL::isa($audit->getPropertySets,'ARRAY')
 and scalar @{$audit->getPropertySets} == 1
 and UNIVERSAL::isa($audit->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($audit->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($audit->getPropertySets,'ARRAY')
 and scalar @{$audit->getPropertySets} == 1
 and $audit->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($audit->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($audit->getPropertySets,'ARRAY')
 and scalar @{$audit->getPropertySets} == 2
 and $audit->getPropertySets->[0] == $propertysets_assn
 and $audit->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$audit->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$audit->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$audit->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$audit->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$audit->setPropertySets([])};
ok((!$@ and defined $audit->getPropertySets()
    and UNIVERSAL::isa($audit->getPropertySets, 'ARRAY')
    and scalar @{$audit->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$audit->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$audit->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$audit->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$audit->setPropertySets(undef)};
ok((!$@ and not defined $audit->getPropertySets()),
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





my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($audit, q[Bio::MAGE::Describable]);

