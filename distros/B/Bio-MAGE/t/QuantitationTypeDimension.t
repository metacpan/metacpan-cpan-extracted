##############################
#
# QuantitationTypeDimension.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl QuantitationTypeDimension.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::QuantitationTypeDimension') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;
use Bio::MAGE::QuantitationType::QuantitationType;


# we test the new() method
my $quantitationtypedimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypedimension = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new();
}
isa_ok($quantitationtypedimension, 'Bio::MAGE::BioAssayData::QuantitationTypeDimension');

# test the package_name class method
is($quantitationtypedimension->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($quantitationtypedimension->class_name(), q[Bio::MAGE::BioAssayData::QuantitationTypeDimension],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypedimension = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($quantitationtypedimension->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$quantitationtypedimension->setIdentifier('1');
is($quantitationtypedimension->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$quantitationtypedimension->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantitationtypedimension->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantitationtypedimension->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$quantitationtypedimension->setIdentifier(undef)};
ok((!$@ and not defined $quantitationtypedimension->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($quantitationtypedimension->getName(), '2',
  'name new');

# test getter/setter
$quantitationtypedimension->setName('2');
is($quantitationtypedimension->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$quantitationtypedimension->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantitationtypedimension->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantitationtypedimension->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$quantitationtypedimension->setName(undef)};
ok((!$@ and not defined $quantitationtypedimension->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::QuantitationTypeDimension->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypedimension = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new(quantitationTypes => [Bio::MAGE::QuantitationType::QuantitationType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association quantitationTypes
my $quantitationtypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypes_assn = Bio::MAGE::QuantitationType::QuantitationType->new();
}


ok((UNIVERSAL::isa($quantitationtypedimension->getQuantitationTypes,'ARRAY')
 and scalar @{$quantitationtypedimension->getQuantitationTypes} == 1
 and UNIVERSAL::isa($quantitationtypedimension->getQuantitationTypes->[0], q[Bio::MAGE::QuantitationType::QuantitationType])),
  'quantitationTypes set in new()');

ok(eq_array($quantitationtypedimension->setQuantitationTypes([$quantitationtypes_assn]), [$quantitationtypes_assn]),
   'setQuantitationTypes returns correct value');

ok((UNIVERSAL::isa($quantitationtypedimension->getQuantitationTypes,'ARRAY')
 and scalar @{$quantitationtypedimension->getQuantitationTypes} == 1
 and $quantitationtypedimension->getQuantitationTypes->[0] == $quantitationtypes_assn),
   'getQuantitationTypes fetches correct value');

is($quantitationtypedimension->addQuantitationTypes($quantitationtypes_assn), 2,
  'addQuantitationTypes returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypedimension->getQuantitationTypes,'ARRAY')
 and scalar @{$quantitationtypedimension->getQuantitationTypes} == 2
 and $quantitationtypedimension->getQuantitationTypes->[0] == $quantitationtypes_assn
 and $quantitationtypedimension->getQuantitationTypes->[1] == $quantitationtypes_assn),
  'addQuantitationTypes adds correct value');

# test setQuantitationTypes throws exception with non-array argument
eval {$quantitationtypedimension->setQuantitationTypes(1)};
ok($@, 'setQuantitationTypes throws exception with non-array argument');

# test setQuantitationTypes throws exception with bad argument array
eval {$quantitationtypedimension->setQuantitationTypes([1])};
ok($@, 'setQuantitationTypes throws exception with bad argument array');

# test addQuantitationTypes throws exception with no arguments
eval {$quantitationtypedimension->addQuantitationTypes()};
ok($@, 'addQuantitationTypes throws exception with no arguments');

# test addQuantitationTypes throws exception with bad argument
eval {$quantitationtypedimension->addQuantitationTypes(1)};
ok($@, 'addQuantitationTypes throws exception with bad array');

# test setQuantitationTypes accepts empty array ref
eval {$quantitationtypedimension->setQuantitationTypes([])};
ok((!$@ and defined $quantitationtypedimension->getQuantitationTypes()
    and UNIVERSAL::isa($quantitationtypedimension->getQuantitationTypes, 'ARRAY')
    and scalar @{$quantitationtypedimension->getQuantitationTypes} == 0),
   'setQuantitationTypes accepts empty array ref');


# test getQuantitationTypes throws exception with argument
eval {$quantitationtypedimension->getQuantitationTypes(1)};
ok($@, 'getQuantitationTypes throws exception with argument');

# test setQuantitationTypes throws exception with no argument
eval {$quantitationtypedimension->setQuantitationTypes()};
ok($@, 'setQuantitationTypes throws exception with no argument');

# test setQuantitationTypes throws exception with too many argument
eval {$quantitationtypedimension->setQuantitationTypes(1,2)};
ok($@, 'setQuantitationTypes throws exception with too many argument');

# test setQuantitationTypes accepts undef
eval {$quantitationtypedimension->setQuantitationTypes(undef)};
ok((!$@ and not defined $quantitationtypedimension->getQuantitationTypes()),
   'setQuantitationTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationTypes};
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
   'quantitationTypes->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationTypes->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($quantitationtypedimension->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypedimension->getDescriptions} == 1
 and UNIVERSAL::isa($quantitationtypedimension->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($quantitationtypedimension->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($quantitationtypedimension->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypedimension->getDescriptions} == 1
 and $quantitationtypedimension->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($quantitationtypedimension->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypedimension->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypedimension->getDescriptions} == 2
 and $quantitationtypedimension->getDescriptions->[0] == $descriptions_assn
 and $quantitationtypedimension->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$quantitationtypedimension->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$quantitationtypedimension->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$quantitationtypedimension->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$quantitationtypedimension->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$quantitationtypedimension->setDescriptions([])};
ok((!$@ and defined $quantitationtypedimension->getDescriptions()
    and UNIVERSAL::isa($quantitationtypedimension->getDescriptions, 'ARRAY')
    and scalar @{$quantitationtypedimension->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$quantitationtypedimension->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$quantitationtypedimension->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$quantitationtypedimension->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$quantitationtypedimension->setDescriptions(undef)};
ok((!$@ and not defined $quantitationtypedimension->getDescriptions()),
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


isa_ok($quantitationtypedimension->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($quantitationtypedimension->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($quantitationtypedimension->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$quantitationtypedimension->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$quantitationtypedimension->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$quantitationtypedimension->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$quantitationtypedimension->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$quantitationtypedimension->setSecurity(undef)};
ok((!$@ and not defined $quantitationtypedimension->getSecurity()),
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


ok((UNIVERSAL::isa($quantitationtypedimension->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypedimension->getAuditTrail} == 1
 and UNIVERSAL::isa($quantitationtypedimension->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($quantitationtypedimension->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($quantitationtypedimension->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypedimension->getAuditTrail} == 1
 and $quantitationtypedimension->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($quantitationtypedimension->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypedimension->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypedimension->getAuditTrail} == 2
 and $quantitationtypedimension->getAuditTrail->[0] == $audittrail_assn
 and $quantitationtypedimension->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$quantitationtypedimension->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$quantitationtypedimension->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$quantitationtypedimension->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$quantitationtypedimension->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$quantitationtypedimension->setAuditTrail([])};
ok((!$@ and defined $quantitationtypedimension->getAuditTrail()
    and UNIVERSAL::isa($quantitationtypedimension->getAuditTrail, 'ARRAY')
    and scalar @{$quantitationtypedimension->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$quantitationtypedimension->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$quantitationtypedimension->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$quantitationtypedimension->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$quantitationtypedimension->setAuditTrail(undef)};
ok((!$@ and not defined $quantitationtypedimension->getAuditTrail()),
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


ok((UNIVERSAL::isa($quantitationtypedimension->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypedimension->getPropertySets} == 1
 and UNIVERSAL::isa($quantitationtypedimension->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($quantitationtypedimension->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($quantitationtypedimension->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypedimension->getPropertySets} == 1
 and $quantitationtypedimension->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($quantitationtypedimension->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypedimension->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypedimension->getPropertySets} == 2
 and $quantitationtypedimension->getPropertySets->[0] == $propertysets_assn
 and $quantitationtypedimension->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$quantitationtypedimension->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$quantitationtypedimension->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$quantitationtypedimension->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$quantitationtypedimension->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$quantitationtypedimension->setPropertySets([])};
ok((!$@ and defined $quantitationtypedimension->getPropertySets()
    and UNIVERSAL::isa($quantitationtypedimension->getPropertySets, 'ARRAY')
    and scalar @{$quantitationtypedimension->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$quantitationtypedimension->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$quantitationtypedimension->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$quantitationtypedimension->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$quantitationtypedimension->setPropertySets(undef)};
ok((!$@ and not defined $quantitationtypedimension->getPropertySets()),
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





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($quantitationtypedimension, q[Bio::MAGE::Identifiable]);

