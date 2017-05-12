##############################
#
# CompositeSequence.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompositeSequence.t`

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
use Test::More tests => 158;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::CompositeSequence') };

use Bio::MAGE::BioSequence::BioSequence;
use Bio::MAGE::DesignElement::CompositeCompositeMap;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::DesignElement::ReporterCompositeMap;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $compositesequence;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequence = Bio::MAGE::DesignElement::CompositeSequence->new();
}
isa_ok($compositesequence, 'Bio::MAGE::DesignElement::CompositeSequence');

# test the package_name class method
is($compositesequence->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($compositesequence->class_name(), q[Bio::MAGE::DesignElement::CompositeSequence],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequence = Bio::MAGE::DesignElement::CompositeSequence->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($compositesequence->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$compositesequence->setIdentifier('1');
is($compositesequence->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$compositesequence->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositesequence->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositesequence->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$compositesequence->setIdentifier(undef)};
ok((!$@ and not defined $compositesequence->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($compositesequence->getName(), '2',
  'name new');

# test getter/setter
$compositesequence->setName('2');
is($compositesequence->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$compositesequence->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositesequence->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositesequence->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$compositesequence->setName(undef)};
ok((!$@ and not defined $compositesequence->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::CompositeSequence->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequence = Bio::MAGE::DesignElement::CompositeSequence->new(controlType => Bio::MAGE::Description::OntologyEntry->new(),
compositeCompositeMaps => [Bio::MAGE::DesignElement::CompositeCompositeMap->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
biologicalCharacteristics => [Bio::MAGE::BioSequence::BioSequence->new()],
reporterCompositeMaps => [Bio::MAGE::DesignElement::ReporterCompositeMap->new()]);
}

my ($end, $assn);


# testing association controlType
my $controltype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $controltype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($compositesequence->getControlType, q[Bio::MAGE::Description::OntologyEntry]);

is($compositesequence->setControlType($controltype_assn), $controltype_assn,
  'setControlType returns value');

ok($compositesequence->getControlType() == $controltype_assn,
   'getControlType fetches correct value');

# test setControlType throws exception with bad argument
eval {$compositesequence->setControlType(1)};
ok($@, 'setControlType throws exception with bad argument');


# test getControlType throws exception with argument
eval {$compositesequence->getControlType(1)};
ok($@, 'getControlType throws exception with argument');

# test setControlType throws exception with no argument
eval {$compositesequence->setControlType()};
ok($@, 'setControlType throws exception with no argument');

# test setControlType throws exception with too many argument
eval {$compositesequence->setControlType(1,2)};
ok($@, 'setControlType throws exception with too many argument');

# test setControlType accepts undef
eval {$compositesequence->setControlType(undef)};
ok((!$@ and not defined $compositesequence->getControlType()),
   'setControlType accepts undef');

# test the meta-data for the assoication
$assn = $assns{controlType};
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
   'controlType->other() is a valid Bio::MAGE::Association::End'
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
   'controlType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association compositeCompositeMaps
my $compositecompositemaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositecompositemaps_assn = Bio::MAGE::DesignElement::CompositeCompositeMap->new();
}


ok((UNIVERSAL::isa($compositesequence->getCompositeCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getCompositeCompositeMaps} == 1
 and UNIVERSAL::isa($compositesequence->getCompositeCompositeMaps->[0], q[Bio::MAGE::DesignElement::CompositeCompositeMap])),
  'compositeCompositeMaps set in new()');

ok(eq_array($compositesequence->setCompositeCompositeMaps([$compositecompositemaps_assn]), [$compositecompositemaps_assn]),
   'setCompositeCompositeMaps returns correct value');

ok((UNIVERSAL::isa($compositesequence->getCompositeCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getCompositeCompositeMaps} == 1
 and $compositesequence->getCompositeCompositeMaps->[0] == $compositecompositemaps_assn),
   'getCompositeCompositeMaps fetches correct value');

is($compositesequence->addCompositeCompositeMaps($compositecompositemaps_assn), 2,
  'addCompositeCompositeMaps returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getCompositeCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getCompositeCompositeMaps} == 2
 and $compositesequence->getCompositeCompositeMaps->[0] == $compositecompositemaps_assn
 and $compositesequence->getCompositeCompositeMaps->[1] == $compositecompositemaps_assn),
  'addCompositeCompositeMaps adds correct value');

# test setCompositeCompositeMaps throws exception with non-array argument
eval {$compositesequence->setCompositeCompositeMaps(1)};
ok($@, 'setCompositeCompositeMaps throws exception with non-array argument');

# test setCompositeCompositeMaps throws exception with bad argument array
eval {$compositesequence->setCompositeCompositeMaps([1])};
ok($@, 'setCompositeCompositeMaps throws exception with bad argument array');

# test addCompositeCompositeMaps throws exception with no arguments
eval {$compositesequence->addCompositeCompositeMaps()};
ok($@, 'addCompositeCompositeMaps throws exception with no arguments');

# test addCompositeCompositeMaps throws exception with bad argument
eval {$compositesequence->addCompositeCompositeMaps(1)};
ok($@, 'addCompositeCompositeMaps throws exception with bad array');

# test setCompositeCompositeMaps accepts empty array ref
eval {$compositesequence->setCompositeCompositeMaps([])};
ok((!$@ and defined $compositesequence->getCompositeCompositeMaps()
    and UNIVERSAL::isa($compositesequence->getCompositeCompositeMaps, 'ARRAY')
    and scalar @{$compositesequence->getCompositeCompositeMaps} == 0),
   'setCompositeCompositeMaps accepts empty array ref');


# test getCompositeCompositeMaps throws exception with argument
eval {$compositesequence->getCompositeCompositeMaps(1)};
ok($@, 'getCompositeCompositeMaps throws exception with argument');

# test setCompositeCompositeMaps throws exception with no argument
eval {$compositesequence->setCompositeCompositeMaps()};
ok($@, 'setCompositeCompositeMaps throws exception with no argument');

# test setCompositeCompositeMaps throws exception with too many argument
eval {$compositesequence->setCompositeCompositeMaps(1,2)};
ok($@, 'setCompositeCompositeMaps throws exception with too many argument');

# test setCompositeCompositeMaps accepts undef
eval {$compositesequence->setCompositeCompositeMaps(undef)};
ok((!$@ and not defined $compositesequence->getCompositeCompositeMaps()),
   'setCompositeCompositeMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{compositeCompositeMaps};
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
   'compositeCompositeMaps->other() is a valid Bio::MAGE::Association::End'
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
   'compositeCompositeMaps->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($compositesequence->getAuditTrail,'ARRAY')
 and scalar @{$compositesequence->getAuditTrail} == 1
 and UNIVERSAL::isa($compositesequence->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($compositesequence->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($compositesequence->getAuditTrail,'ARRAY')
 and scalar @{$compositesequence->getAuditTrail} == 1
 and $compositesequence->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($compositesequence->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getAuditTrail,'ARRAY')
 and scalar @{$compositesequence->getAuditTrail} == 2
 and $compositesequence->getAuditTrail->[0] == $audittrail_assn
 and $compositesequence->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$compositesequence->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$compositesequence->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$compositesequence->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$compositesequence->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$compositesequence->setAuditTrail([])};
ok((!$@ and defined $compositesequence->getAuditTrail()
    and UNIVERSAL::isa($compositesequence->getAuditTrail, 'ARRAY')
    and scalar @{$compositesequence->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$compositesequence->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$compositesequence->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$compositesequence->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$compositesequence->setAuditTrail(undef)};
ok((!$@ and not defined $compositesequence->getAuditTrail()),
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



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($compositesequence->getPropertySets,'ARRAY')
 and scalar @{$compositesequence->getPropertySets} == 1
 and UNIVERSAL::isa($compositesequence->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compositesequence->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compositesequence->getPropertySets,'ARRAY')
 and scalar @{$compositesequence->getPropertySets} == 1
 and $compositesequence->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compositesequence->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getPropertySets,'ARRAY')
 and scalar @{$compositesequence->getPropertySets} == 2
 and $compositesequence->getPropertySets->[0] == $propertysets_assn
 and $compositesequence->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compositesequence->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compositesequence->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compositesequence->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compositesequence->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compositesequence->setPropertySets([])};
ok((!$@ and defined $compositesequence->getPropertySets()
    and UNIVERSAL::isa($compositesequence->getPropertySets, 'ARRAY')
    and scalar @{$compositesequence->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compositesequence->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compositesequence->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compositesequence->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compositesequence->setPropertySets(undef)};
ok((!$@ and not defined $compositesequence->getPropertySets()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($compositesequence->getDescriptions,'ARRAY')
 and scalar @{$compositesequence->getDescriptions} == 1
 and UNIVERSAL::isa($compositesequence->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($compositesequence->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($compositesequence->getDescriptions,'ARRAY')
 and scalar @{$compositesequence->getDescriptions} == 1
 and $compositesequence->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($compositesequence->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getDescriptions,'ARRAY')
 and scalar @{$compositesequence->getDescriptions} == 2
 and $compositesequence->getDescriptions->[0] == $descriptions_assn
 and $compositesequence->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$compositesequence->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$compositesequence->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$compositesequence->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$compositesequence->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$compositesequence->setDescriptions([])};
ok((!$@ and defined $compositesequence->getDescriptions()
    and UNIVERSAL::isa($compositesequence->getDescriptions, 'ARRAY')
    and scalar @{$compositesequence->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$compositesequence->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$compositesequence->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$compositesequence->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$compositesequence->setDescriptions(undef)};
ok((!$@ and not defined $compositesequence->getDescriptions()),
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


isa_ok($compositesequence->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($compositesequence->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($compositesequence->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$compositesequence->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$compositesequence->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$compositesequence->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$compositesequence->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$compositesequence->setSecurity(undef)};
ok((!$@ and not defined $compositesequence->getSecurity()),
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



# testing association biologicalCharacteristics
my $biologicalcharacteristics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biologicalcharacteristics_assn = Bio::MAGE::BioSequence::BioSequence->new();
}


ok((UNIVERSAL::isa($compositesequence->getBiologicalCharacteristics,'ARRAY')
 and scalar @{$compositesequence->getBiologicalCharacteristics} == 1
 and UNIVERSAL::isa($compositesequence->getBiologicalCharacteristics->[0], q[Bio::MAGE::BioSequence::BioSequence])),
  'biologicalCharacteristics set in new()');

ok(eq_array($compositesequence->setBiologicalCharacteristics([$biologicalcharacteristics_assn]), [$biologicalcharacteristics_assn]),
   'setBiologicalCharacteristics returns correct value');

ok((UNIVERSAL::isa($compositesequence->getBiologicalCharacteristics,'ARRAY')
 and scalar @{$compositesequence->getBiologicalCharacteristics} == 1
 and $compositesequence->getBiologicalCharacteristics->[0] == $biologicalcharacteristics_assn),
   'getBiologicalCharacteristics fetches correct value');

is($compositesequence->addBiologicalCharacteristics($biologicalcharacteristics_assn), 2,
  'addBiologicalCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getBiologicalCharacteristics,'ARRAY')
 and scalar @{$compositesequence->getBiologicalCharacteristics} == 2
 and $compositesequence->getBiologicalCharacteristics->[0] == $biologicalcharacteristics_assn
 and $compositesequence->getBiologicalCharacteristics->[1] == $biologicalcharacteristics_assn),
  'addBiologicalCharacteristics adds correct value');

# test setBiologicalCharacteristics throws exception with non-array argument
eval {$compositesequence->setBiologicalCharacteristics(1)};
ok($@, 'setBiologicalCharacteristics throws exception with non-array argument');

# test setBiologicalCharacteristics throws exception with bad argument array
eval {$compositesequence->setBiologicalCharacteristics([1])};
ok($@, 'setBiologicalCharacteristics throws exception with bad argument array');

# test addBiologicalCharacteristics throws exception with no arguments
eval {$compositesequence->addBiologicalCharacteristics()};
ok($@, 'addBiologicalCharacteristics throws exception with no arguments');

# test addBiologicalCharacteristics throws exception with bad argument
eval {$compositesequence->addBiologicalCharacteristics(1)};
ok($@, 'addBiologicalCharacteristics throws exception with bad array');

# test setBiologicalCharacteristics accepts empty array ref
eval {$compositesequence->setBiologicalCharacteristics([])};
ok((!$@ and defined $compositesequence->getBiologicalCharacteristics()
    and UNIVERSAL::isa($compositesequence->getBiologicalCharacteristics, 'ARRAY')
    and scalar @{$compositesequence->getBiologicalCharacteristics} == 0),
   'setBiologicalCharacteristics accepts empty array ref');


# test getBiologicalCharacteristics throws exception with argument
eval {$compositesequence->getBiologicalCharacteristics(1)};
ok($@, 'getBiologicalCharacteristics throws exception with argument');

# test setBiologicalCharacteristics throws exception with no argument
eval {$compositesequence->setBiologicalCharacteristics()};
ok($@, 'setBiologicalCharacteristics throws exception with no argument');

# test setBiologicalCharacteristics throws exception with too many argument
eval {$compositesequence->setBiologicalCharacteristics(1,2)};
ok($@, 'setBiologicalCharacteristics throws exception with too many argument');

# test setBiologicalCharacteristics accepts undef
eval {$compositesequence->setBiologicalCharacteristics(undef)};
ok((!$@ and not defined $compositesequence->getBiologicalCharacteristics()),
   'setBiologicalCharacteristics accepts undef');

# test the meta-data for the assoication
$assn = $assns{biologicalCharacteristics};
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
   'biologicalCharacteristics->other() is a valid Bio::MAGE::Association::End'
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
   'biologicalCharacteristics->self() is a valid Bio::MAGE::Association::End'
  );



# testing association reporterCompositeMaps
my $reportercompositemaps_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $reportercompositemaps_assn = Bio::MAGE::DesignElement::ReporterCompositeMap->new();
}


ok((UNIVERSAL::isa($compositesequence->getReporterCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getReporterCompositeMaps} == 1
 and UNIVERSAL::isa($compositesequence->getReporterCompositeMaps->[0], q[Bio::MAGE::DesignElement::ReporterCompositeMap])),
  'reporterCompositeMaps set in new()');

ok(eq_array($compositesequence->setReporterCompositeMaps([$reportercompositemaps_assn]), [$reportercompositemaps_assn]),
   'setReporterCompositeMaps returns correct value');

ok((UNIVERSAL::isa($compositesequence->getReporterCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getReporterCompositeMaps} == 1
 and $compositesequence->getReporterCompositeMaps->[0] == $reportercompositemaps_assn),
   'getReporterCompositeMaps fetches correct value');

is($compositesequence->addReporterCompositeMaps($reportercompositemaps_assn), 2,
  'addReporterCompositeMaps returns number of items in list');

ok((UNIVERSAL::isa($compositesequence->getReporterCompositeMaps,'ARRAY')
 and scalar @{$compositesequence->getReporterCompositeMaps} == 2
 and $compositesequence->getReporterCompositeMaps->[0] == $reportercompositemaps_assn
 and $compositesequence->getReporterCompositeMaps->[1] == $reportercompositemaps_assn),
  'addReporterCompositeMaps adds correct value');

# test setReporterCompositeMaps throws exception with non-array argument
eval {$compositesequence->setReporterCompositeMaps(1)};
ok($@, 'setReporterCompositeMaps throws exception with non-array argument');

# test setReporterCompositeMaps throws exception with bad argument array
eval {$compositesequence->setReporterCompositeMaps([1])};
ok($@, 'setReporterCompositeMaps throws exception with bad argument array');

# test addReporterCompositeMaps throws exception with no arguments
eval {$compositesequence->addReporterCompositeMaps()};
ok($@, 'addReporterCompositeMaps throws exception with no arguments');

# test addReporterCompositeMaps throws exception with bad argument
eval {$compositesequence->addReporterCompositeMaps(1)};
ok($@, 'addReporterCompositeMaps throws exception with bad array');

# test setReporterCompositeMaps accepts empty array ref
eval {$compositesequence->setReporterCompositeMaps([])};
ok((!$@ and defined $compositesequence->getReporterCompositeMaps()
    and UNIVERSAL::isa($compositesequence->getReporterCompositeMaps, 'ARRAY')
    and scalar @{$compositesequence->getReporterCompositeMaps} == 0),
   'setReporterCompositeMaps accepts empty array ref');


# test getReporterCompositeMaps throws exception with argument
eval {$compositesequence->getReporterCompositeMaps(1)};
ok($@, 'getReporterCompositeMaps throws exception with argument');

# test setReporterCompositeMaps throws exception with no argument
eval {$compositesequence->setReporterCompositeMaps()};
ok($@, 'setReporterCompositeMaps throws exception with no argument');

# test setReporterCompositeMaps throws exception with too many argument
eval {$compositesequence->setReporterCompositeMaps(1,2)};
ok($@, 'setReporterCompositeMaps throws exception with too many argument');

# test setReporterCompositeMaps accepts undef
eval {$compositesequence->setReporterCompositeMaps(undef)};
ok((!$@ and not defined $compositesequence->getReporterCompositeMaps()),
   'setReporterCompositeMaps accepts undef');

# test the meta-data for the assoication
$assn = $assns{reporterCompositeMaps};
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
   'reporterCompositeMaps->other() is a valid Bio::MAGE::Association::End'
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
   'reporterCompositeMaps->self() is a valid Bio::MAGE::Association::End'
  );





my $designelement;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelement = Bio::MAGE::DesignElement::DesignElement->new();
}

# testing superclass DesignElement
isa_ok($designelement, q[Bio::MAGE::DesignElement::DesignElement]);
isa_ok($compositesequence, q[Bio::MAGE::DesignElement::DesignElement]);

