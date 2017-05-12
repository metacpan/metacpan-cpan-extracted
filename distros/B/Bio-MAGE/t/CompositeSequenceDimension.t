##############################
#
# CompositeSequenceDimension.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CompositeSequenceDimension.t`

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
use Test::More tests => 107;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::CompositeSequenceDimension') };

use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $compositesequencedimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequencedimension = Bio::MAGE::BioAssayData::CompositeSequenceDimension->new();
}
isa_ok($compositesequencedimension, 'Bio::MAGE::BioAssayData::CompositeSequenceDimension');

# test the package_name class method
is($compositesequencedimension->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($compositesequencedimension->class_name(), q[Bio::MAGE::BioAssayData::CompositeSequenceDimension],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequencedimension = Bio::MAGE::BioAssayData::CompositeSequenceDimension->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($compositesequencedimension->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$compositesequencedimension->setIdentifier('1');
is($compositesequencedimension->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$compositesequencedimension->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositesequencedimension->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositesequencedimension->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$compositesequencedimension->setIdentifier(undef)};
ok((!$@ and not defined $compositesequencedimension->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($compositesequencedimension->getName(), '2',
  'name new');

# test getter/setter
$compositesequencedimension->setName('2');
is($compositesequencedimension->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$compositesequencedimension->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$compositesequencedimension->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compositesequencedimension->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$compositesequencedimension->setName(undef)};
ok((!$@ and not defined $compositesequencedimension->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::CompositeSequenceDimension->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequencedimension = Bio::MAGE::BioAssayData::CompositeSequenceDimension->new(compositeSequences => [Bio::MAGE::DesignElement::CompositeSequence->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association compositeSequences
my $compositesequences_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compositesequences_assn = Bio::MAGE::DesignElement::CompositeSequence->new();
}


ok((UNIVERSAL::isa($compositesequencedimension->getCompositeSequences,'ARRAY')
 and scalar @{$compositesequencedimension->getCompositeSequences} == 1
 and UNIVERSAL::isa($compositesequencedimension->getCompositeSequences->[0], q[Bio::MAGE::DesignElement::CompositeSequence])),
  'compositeSequences set in new()');

ok(eq_array($compositesequencedimension->setCompositeSequences([$compositesequences_assn]), [$compositesequences_assn]),
   'setCompositeSequences returns correct value');

ok((UNIVERSAL::isa($compositesequencedimension->getCompositeSequences,'ARRAY')
 and scalar @{$compositesequencedimension->getCompositeSequences} == 1
 and $compositesequencedimension->getCompositeSequences->[0] == $compositesequences_assn),
   'getCompositeSequences fetches correct value');

is($compositesequencedimension->addCompositeSequences($compositesequences_assn), 2,
  'addCompositeSequences returns number of items in list');

ok((UNIVERSAL::isa($compositesequencedimension->getCompositeSequences,'ARRAY')
 and scalar @{$compositesequencedimension->getCompositeSequences} == 2
 and $compositesequencedimension->getCompositeSequences->[0] == $compositesequences_assn
 and $compositesequencedimension->getCompositeSequences->[1] == $compositesequences_assn),
  'addCompositeSequences adds correct value');

# test setCompositeSequences throws exception with non-array argument
eval {$compositesequencedimension->setCompositeSequences(1)};
ok($@, 'setCompositeSequences throws exception with non-array argument');

# test setCompositeSequences throws exception with bad argument array
eval {$compositesequencedimension->setCompositeSequences([1])};
ok($@, 'setCompositeSequences throws exception with bad argument array');

# test addCompositeSequences throws exception with no arguments
eval {$compositesequencedimension->addCompositeSequences()};
ok($@, 'addCompositeSequences throws exception with no arguments');

# test addCompositeSequences throws exception with bad argument
eval {$compositesequencedimension->addCompositeSequences(1)};
ok($@, 'addCompositeSequences throws exception with bad array');

# test setCompositeSequences accepts empty array ref
eval {$compositesequencedimension->setCompositeSequences([])};
ok((!$@ and defined $compositesequencedimension->getCompositeSequences()
    and UNIVERSAL::isa($compositesequencedimension->getCompositeSequences, 'ARRAY')
    and scalar @{$compositesequencedimension->getCompositeSequences} == 0),
   'setCompositeSequences accepts empty array ref');


# test getCompositeSequences throws exception with argument
eval {$compositesequencedimension->getCompositeSequences(1)};
ok($@, 'getCompositeSequences throws exception with argument');

# test setCompositeSequences throws exception with no argument
eval {$compositesequencedimension->setCompositeSequences()};
ok($@, 'setCompositeSequences throws exception with no argument');

# test setCompositeSequences throws exception with too many argument
eval {$compositesequencedimension->setCompositeSequences(1,2)};
ok($@, 'setCompositeSequences throws exception with too many argument');

# test setCompositeSequences accepts undef
eval {$compositesequencedimension->setCompositeSequences(undef)};
ok((!$@ and not defined $compositesequencedimension->getCompositeSequences()),
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


ok((UNIVERSAL::isa($compositesequencedimension->getDescriptions,'ARRAY')
 and scalar @{$compositesequencedimension->getDescriptions} == 1
 and UNIVERSAL::isa($compositesequencedimension->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($compositesequencedimension->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($compositesequencedimension->getDescriptions,'ARRAY')
 and scalar @{$compositesequencedimension->getDescriptions} == 1
 and $compositesequencedimension->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($compositesequencedimension->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($compositesequencedimension->getDescriptions,'ARRAY')
 and scalar @{$compositesequencedimension->getDescriptions} == 2
 and $compositesequencedimension->getDescriptions->[0] == $descriptions_assn
 and $compositesequencedimension->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$compositesequencedimension->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$compositesequencedimension->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$compositesequencedimension->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$compositesequencedimension->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$compositesequencedimension->setDescriptions([])};
ok((!$@ and defined $compositesequencedimension->getDescriptions()
    and UNIVERSAL::isa($compositesequencedimension->getDescriptions, 'ARRAY')
    and scalar @{$compositesequencedimension->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$compositesequencedimension->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$compositesequencedimension->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$compositesequencedimension->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$compositesequencedimension->setDescriptions(undef)};
ok((!$@ and not defined $compositesequencedimension->getDescriptions()),
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


ok((UNIVERSAL::isa($compositesequencedimension->getAuditTrail,'ARRAY')
 and scalar @{$compositesequencedimension->getAuditTrail} == 1
 and UNIVERSAL::isa($compositesequencedimension->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($compositesequencedimension->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($compositesequencedimension->getAuditTrail,'ARRAY')
 and scalar @{$compositesequencedimension->getAuditTrail} == 1
 and $compositesequencedimension->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($compositesequencedimension->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($compositesequencedimension->getAuditTrail,'ARRAY')
 and scalar @{$compositesequencedimension->getAuditTrail} == 2
 and $compositesequencedimension->getAuditTrail->[0] == $audittrail_assn
 and $compositesequencedimension->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$compositesequencedimension->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$compositesequencedimension->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$compositesequencedimension->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$compositesequencedimension->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$compositesequencedimension->setAuditTrail([])};
ok((!$@ and defined $compositesequencedimension->getAuditTrail()
    and UNIVERSAL::isa($compositesequencedimension->getAuditTrail, 'ARRAY')
    and scalar @{$compositesequencedimension->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$compositesequencedimension->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$compositesequencedimension->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$compositesequencedimension->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$compositesequencedimension->setAuditTrail(undef)};
ok((!$@ and not defined $compositesequencedimension->getAuditTrail()),
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


isa_ok($compositesequencedimension->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($compositesequencedimension->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($compositesequencedimension->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$compositesequencedimension->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$compositesequencedimension->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$compositesequencedimension->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$compositesequencedimension->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$compositesequencedimension->setSecurity(undef)};
ok((!$@ and not defined $compositesequencedimension->getSecurity()),
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


ok((UNIVERSAL::isa($compositesequencedimension->getPropertySets,'ARRAY')
 and scalar @{$compositesequencedimension->getPropertySets} == 1
 and UNIVERSAL::isa($compositesequencedimension->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compositesequencedimension->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compositesequencedimension->getPropertySets,'ARRAY')
 and scalar @{$compositesequencedimension->getPropertySets} == 1
 and $compositesequencedimension->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compositesequencedimension->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compositesequencedimension->getPropertySets,'ARRAY')
 and scalar @{$compositesequencedimension->getPropertySets} == 2
 and $compositesequencedimension->getPropertySets->[0] == $propertysets_assn
 and $compositesequencedimension->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compositesequencedimension->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compositesequencedimension->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compositesequencedimension->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compositesequencedimension->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compositesequencedimension->setPropertySets([])};
ok((!$@ and defined $compositesequencedimension->getPropertySets()
    and UNIVERSAL::isa($compositesequencedimension->getPropertySets, 'ARRAY')
    and scalar @{$compositesequencedimension->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compositesequencedimension->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compositesequencedimension->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compositesequencedimension->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compositesequencedimension->setPropertySets(undef)};
ok((!$@ and not defined $compositesequencedimension->getPropertySets()),
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





my $designelementdimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $designelementdimension = Bio::MAGE::BioAssayData::DesignElementDimension->new();
}

# testing superclass DesignElementDimension
isa_ok($designelementdimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);
isa_ok($compositesequencedimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

