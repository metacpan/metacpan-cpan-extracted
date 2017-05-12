##############################
#
# BioSource.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioSource.t`

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
use Test::More tests => 177;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::BioSource') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::BioMaterial::Treatment;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $biosource;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosource = Bio::MAGE::BioMaterial::BioSource->new();
}
isa_ok($biosource, 'Bio::MAGE::BioMaterial::BioSource');

# test the package_name class method
is($biosource->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($biosource->class_name(), q[Bio::MAGE::BioMaterial::BioSource],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosource = Bio::MAGE::BioMaterial::BioSource->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($biosource->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$biosource->setIdentifier('1');
is($biosource->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$biosource->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosource->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosource->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$biosource->setIdentifier(undef)};
ok((!$@ and not defined $biosource->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($biosource->getName(), '2',
  'name new');

# test getter/setter
$biosource->setName('2');
is($biosource->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$biosource->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosource->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosource->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$biosource->setName(undef)};
ok((!$@ and not defined $biosource->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::BioSource->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosource = Bio::MAGE::BioMaterial::BioSource->new(sourceContact => [Bio::MAGE::AuditAndSecurity::Contact->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
qualityControlStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
characteristics => [Bio::MAGE::Description::OntologyEntry->new()],
treatments => [Bio::MAGE::BioMaterial::Treatment->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
materialType => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association sourceContact
my $sourcecontact_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sourcecontact_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($biosource->getSourceContact,'ARRAY')
 and scalar @{$biosource->getSourceContact} == 1
 and UNIVERSAL::isa($biosource->getSourceContact->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'sourceContact set in new()');

ok(eq_array($biosource->setSourceContact([$sourcecontact_assn]), [$sourcecontact_assn]),
   'setSourceContact returns correct value');

ok((UNIVERSAL::isa($biosource->getSourceContact,'ARRAY')
 and scalar @{$biosource->getSourceContact} == 1
 and $biosource->getSourceContact->[0] == $sourcecontact_assn),
   'getSourceContact fetches correct value');

is($biosource->addSourceContact($sourcecontact_assn), 2,
  'addSourceContact returns number of items in list');

ok((UNIVERSAL::isa($biosource->getSourceContact,'ARRAY')
 and scalar @{$biosource->getSourceContact} == 2
 and $biosource->getSourceContact->[0] == $sourcecontact_assn
 and $biosource->getSourceContact->[1] == $sourcecontact_assn),
  'addSourceContact adds correct value');

# test setSourceContact throws exception with non-array argument
eval {$biosource->setSourceContact(1)};
ok($@, 'setSourceContact throws exception with non-array argument');

# test setSourceContact throws exception with bad argument array
eval {$biosource->setSourceContact([1])};
ok($@, 'setSourceContact throws exception with bad argument array');

# test addSourceContact throws exception with no arguments
eval {$biosource->addSourceContact()};
ok($@, 'addSourceContact throws exception with no arguments');

# test addSourceContact throws exception with bad argument
eval {$biosource->addSourceContact(1)};
ok($@, 'addSourceContact throws exception with bad array');

# test setSourceContact accepts empty array ref
eval {$biosource->setSourceContact([])};
ok((!$@ and defined $biosource->getSourceContact()
    and UNIVERSAL::isa($biosource->getSourceContact, 'ARRAY')
    and scalar @{$biosource->getSourceContact} == 0),
   'setSourceContact accepts empty array ref');


# test getSourceContact throws exception with argument
eval {$biosource->getSourceContact(1)};
ok($@, 'getSourceContact throws exception with argument');

# test setSourceContact throws exception with no argument
eval {$biosource->setSourceContact()};
ok($@, 'setSourceContact throws exception with no argument');

# test setSourceContact throws exception with too many argument
eval {$biosource->setSourceContact(1,2)};
ok($@, 'setSourceContact throws exception with too many argument');

# test setSourceContact accepts undef
eval {$biosource->setSourceContact(undef)};
ok((!$@ and not defined $biosource->getSourceContact()),
   'setSourceContact accepts undef');

# test the meta-data for the assoication
$assn = $assns{sourceContact};
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
   'sourceContact->other() is a valid Bio::MAGE::Association::End'
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
   'sourceContact->self() is a valid Bio::MAGE::Association::End'
  );



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($biosource->getAuditTrail,'ARRAY')
 and scalar @{$biosource->getAuditTrail} == 1
 and UNIVERSAL::isa($biosource->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($biosource->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($biosource->getAuditTrail,'ARRAY')
 and scalar @{$biosource->getAuditTrail} == 1
 and $biosource->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($biosource->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($biosource->getAuditTrail,'ARRAY')
 and scalar @{$biosource->getAuditTrail} == 2
 and $biosource->getAuditTrail->[0] == $audittrail_assn
 and $biosource->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$biosource->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$biosource->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$biosource->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$biosource->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$biosource->setAuditTrail([])};
ok((!$@ and defined $biosource->getAuditTrail()
    and UNIVERSAL::isa($biosource->getAuditTrail, 'ARRAY')
    and scalar @{$biosource->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$biosource->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$biosource->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$biosource->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$biosource->setAuditTrail(undef)};
ok((!$@ and not defined $biosource->getAuditTrail()),
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


ok((UNIVERSAL::isa($biosource->getPropertySets,'ARRAY')
 and scalar @{$biosource->getPropertySets} == 1
 and UNIVERSAL::isa($biosource->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biosource->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biosource->getPropertySets,'ARRAY')
 and scalar @{$biosource->getPropertySets} == 1
 and $biosource->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biosource->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biosource->getPropertySets,'ARRAY')
 and scalar @{$biosource->getPropertySets} == 2
 and $biosource->getPropertySets->[0] == $propertysets_assn
 and $biosource->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biosource->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biosource->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biosource->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biosource->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biosource->setPropertySets([])};
ok((!$@ and defined $biosource->getPropertySets()
    and UNIVERSAL::isa($biosource->getPropertySets, 'ARRAY')
    and scalar @{$biosource->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biosource->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biosource->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biosource->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biosource->setPropertySets(undef)};
ok((!$@ and not defined $biosource->getPropertySets()),
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



# testing association qualityControlStatistics
my $qualitycontrolstatistics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $qualitycontrolstatistics_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($biosource->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosource->getQualityControlStatistics} == 1
 and UNIVERSAL::isa($biosource->getQualityControlStatistics->[0], q[Bio::MAGE::NameValueType])),
  'qualityControlStatistics set in new()');

ok(eq_array($biosource->setQualityControlStatistics([$qualitycontrolstatistics_assn]), [$qualitycontrolstatistics_assn]),
   'setQualityControlStatistics returns correct value');

ok((UNIVERSAL::isa($biosource->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosource->getQualityControlStatistics} == 1
 and $biosource->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn),
   'getQualityControlStatistics fetches correct value');

is($biosource->addQualityControlStatistics($qualitycontrolstatistics_assn), 2,
  'addQualityControlStatistics returns number of items in list');

ok((UNIVERSAL::isa($biosource->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosource->getQualityControlStatistics} == 2
 and $biosource->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn
 and $biosource->getQualityControlStatistics->[1] == $qualitycontrolstatistics_assn),
  'addQualityControlStatistics adds correct value');

# test setQualityControlStatistics throws exception with non-array argument
eval {$biosource->setQualityControlStatistics(1)};
ok($@, 'setQualityControlStatistics throws exception with non-array argument');

# test setQualityControlStatistics throws exception with bad argument array
eval {$biosource->setQualityControlStatistics([1])};
ok($@, 'setQualityControlStatistics throws exception with bad argument array');

# test addQualityControlStatistics throws exception with no arguments
eval {$biosource->addQualityControlStatistics()};
ok($@, 'addQualityControlStatistics throws exception with no arguments');

# test addQualityControlStatistics throws exception with bad argument
eval {$biosource->addQualityControlStatistics(1)};
ok($@, 'addQualityControlStatistics throws exception with bad array');

# test setQualityControlStatistics accepts empty array ref
eval {$biosource->setQualityControlStatistics([])};
ok((!$@ and defined $biosource->getQualityControlStatistics()
    and UNIVERSAL::isa($biosource->getQualityControlStatistics, 'ARRAY')
    and scalar @{$biosource->getQualityControlStatistics} == 0),
   'setQualityControlStatistics accepts empty array ref');


# test getQualityControlStatistics throws exception with argument
eval {$biosource->getQualityControlStatistics(1)};
ok($@, 'getQualityControlStatistics throws exception with argument');

# test setQualityControlStatistics throws exception with no argument
eval {$biosource->setQualityControlStatistics()};
ok($@, 'setQualityControlStatistics throws exception with no argument');

# test setQualityControlStatistics throws exception with too many argument
eval {$biosource->setQualityControlStatistics(1,2)};
ok($@, 'setQualityControlStatistics throws exception with too many argument');

# test setQualityControlStatistics accepts undef
eval {$biosource->setQualityControlStatistics(undef)};
ok((!$@ and not defined $biosource->getQualityControlStatistics()),
   'setQualityControlStatistics accepts undef');

# test the meta-data for the assoication
$assn = $assns{qualityControlStatistics};
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
   'qualityControlStatistics->other() is a valid Bio::MAGE::Association::End'
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
   'qualityControlStatistics->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($biosource->getDescriptions,'ARRAY')
 and scalar @{$biosource->getDescriptions} == 1
 and UNIVERSAL::isa($biosource->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($biosource->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($biosource->getDescriptions,'ARRAY')
 and scalar @{$biosource->getDescriptions} == 1
 and $biosource->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($biosource->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($biosource->getDescriptions,'ARRAY')
 and scalar @{$biosource->getDescriptions} == 2
 and $biosource->getDescriptions->[0] == $descriptions_assn
 and $biosource->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$biosource->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$biosource->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$biosource->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$biosource->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$biosource->setDescriptions([])};
ok((!$@ and defined $biosource->getDescriptions()
    and UNIVERSAL::isa($biosource->getDescriptions, 'ARRAY')
    and scalar @{$biosource->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$biosource->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$biosource->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$biosource->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$biosource->setDescriptions(undef)};
ok((!$@ and not defined $biosource->getDescriptions()),
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



# testing association characteristics
my $characteristics_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $characteristics_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($biosource->getCharacteristics,'ARRAY')
 and scalar @{$biosource->getCharacteristics} == 1
 and UNIVERSAL::isa($biosource->getCharacteristics->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'characteristics set in new()');

ok(eq_array($biosource->setCharacteristics([$characteristics_assn]), [$characteristics_assn]),
   'setCharacteristics returns correct value');

ok((UNIVERSAL::isa($biosource->getCharacteristics,'ARRAY')
 and scalar @{$biosource->getCharacteristics} == 1
 and $biosource->getCharacteristics->[0] == $characteristics_assn),
   'getCharacteristics fetches correct value');

is($biosource->addCharacteristics($characteristics_assn), 2,
  'addCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($biosource->getCharacteristics,'ARRAY')
 and scalar @{$biosource->getCharacteristics} == 2
 and $biosource->getCharacteristics->[0] == $characteristics_assn
 and $biosource->getCharacteristics->[1] == $characteristics_assn),
  'addCharacteristics adds correct value');

# test setCharacteristics throws exception with non-array argument
eval {$biosource->setCharacteristics(1)};
ok($@, 'setCharacteristics throws exception with non-array argument');

# test setCharacteristics throws exception with bad argument array
eval {$biosource->setCharacteristics([1])};
ok($@, 'setCharacteristics throws exception with bad argument array');

# test addCharacteristics throws exception with no arguments
eval {$biosource->addCharacteristics()};
ok($@, 'addCharacteristics throws exception with no arguments');

# test addCharacteristics throws exception with bad argument
eval {$biosource->addCharacteristics(1)};
ok($@, 'addCharacteristics throws exception with bad array');

# test setCharacteristics accepts empty array ref
eval {$biosource->setCharacteristics([])};
ok((!$@ and defined $biosource->getCharacteristics()
    and UNIVERSAL::isa($biosource->getCharacteristics, 'ARRAY')
    and scalar @{$biosource->getCharacteristics} == 0),
   'setCharacteristics accepts empty array ref');


# test getCharacteristics throws exception with argument
eval {$biosource->getCharacteristics(1)};
ok($@, 'getCharacteristics throws exception with argument');

# test setCharacteristics throws exception with no argument
eval {$biosource->setCharacteristics()};
ok($@, 'setCharacteristics throws exception with no argument');

# test setCharacteristics throws exception with too many argument
eval {$biosource->setCharacteristics(1,2)};
ok($@, 'setCharacteristics throws exception with too many argument');

# test setCharacteristics accepts undef
eval {$biosource->setCharacteristics(undef)};
ok((!$@ and not defined $biosource->getCharacteristics()),
   'setCharacteristics accepts undef');

# test the meta-data for the assoication
$assn = $assns{characteristics};
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
   'characteristics->other() is a valid Bio::MAGE::Association::End'
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
   'characteristics->self() is a valid Bio::MAGE::Association::End'
  );



# testing association treatments
my $treatments_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $treatments_assn = Bio::MAGE::BioMaterial::Treatment->new();
}


ok((UNIVERSAL::isa($biosource->getTreatments,'ARRAY')
 and scalar @{$biosource->getTreatments} == 1
 and UNIVERSAL::isa($biosource->getTreatments->[0], q[Bio::MAGE::BioMaterial::Treatment])),
  'treatments set in new()');

ok(eq_array($biosource->setTreatments([$treatments_assn]), [$treatments_assn]),
   'setTreatments returns correct value');

ok((UNIVERSAL::isa($biosource->getTreatments,'ARRAY')
 and scalar @{$biosource->getTreatments} == 1
 and $biosource->getTreatments->[0] == $treatments_assn),
   'getTreatments fetches correct value');

is($biosource->addTreatments($treatments_assn), 2,
  'addTreatments returns number of items in list');

ok((UNIVERSAL::isa($biosource->getTreatments,'ARRAY')
 and scalar @{$biosource->getTreatments} == 2
 and $biosource->getTreatments->[0] == $treatments_assn
 and $biosource->getTreatments->[1] == $treatments_assn),
  'addTreatments adds correct value');

# test setTreatments throws exception with non-array argument
eval {$biosource->setTreatments(1)};
ok($@, 'setTreatments throws exception with non-array argument');

# test setTreatments throws exception with bad argument array
eval {$biosource->setTreatments([1])};
ok($@, 'setTreatments throws exception with bad argument array');

# test addTreatments throws exception with no arguments
eval {$biosource->addTreatments()};
ok($@, 'addTreatments throws exception with no arguments');

# test addTreatments throws exception with bad argument
eval {$biosource->addTreatments(1)};
ok($@, 'addTreatments throws exception with bad array');

# test setTreatments accepts empty array ref
eval {$biosource->setTreatments([])};
ok((!$@ and defined $biosource->getTreatments()
    and UNIVERSAL::isa($biosource->getTreatments, 'ARRAY')
    and scalar @{$biosource->getTreatments} == 0),
   'setTreatments accepts empty array ref');


# test getTreatments throws exception with argument
eval {$biosource->getTreatments(1)};
ok($@, 'getTreatments throws exception with argument');

# test setTreatments throws exception with no argument
eval {$biosource->setTreatments()};
ok($@, 'setTreatments throws exception with no argument');

# test setTreatments throws exception with too many argument
eval {$biosource->setTreatments(1,2)};
ok($@, 'setTreatments throws exception with too many argument');

# test setTreatments accepts undef
eval {$biosource->setTreatments(undef)};
ok((!$@ and not defined $biosource->getTreatments()),
   'setTreatments accepts undef');

# test the meta-data for the assoication
$assn = $assns{treatments};
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
   'treatments->other() is a valid Bio::MAGE::Association::End'
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
   'treatments->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($biosource->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($biosource->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($biosource->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$biosource->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$biosource->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$biosource->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$biosource->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$biosource->setSecurity(undef)};
ok((!$@ and not defined $biosource->getSecurity()),
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



# testing association materialType
my $materialtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $materialtype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosource->getMaterialType, q[Bio::MAGE::Description::OntologyEntry]);

is($biosource->setMaterialType($materialtype_assn), $materialtype_assn,
  'setMaterialType returns value');

ok($biosource->getMaterialType() == $materialtype_assn,
   'getMaterialType fetches correct value');

# test setMaterialType throws exception with bad argument
eval {$biosource->setMaterialType(1)};
ok($@, 'setMaterialType throws exception with bad argument');


# test getMaterialType throws exception with argument
eval {$biosource->getMaterialType(1)};
ok($@, 'getMaterialType throws exception with argument');

# test setMaterialType throws exception with no argument
eval {$biosource->setMaterialType()};
ok($@, 'setMaterialType throws exception with no argument');

# test setMaterialType throws exception with too many argument
eval {$biosource->setMaterialType(1,2)};
ok($@, 'setMaterialType throws exception with too many argument');

# test setMaterialType accepts undef
eval {$biosource->setMaterialType(undef)};
ok((!$@ and not defined $biosource->getMaterialType()),
   'setMaterialType accepts undef');

# test the meta-data for the assoication
$assn = $assns{materialType};
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
   'materialType->other() is a valid Bio::MAGE::Association::End'
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
   'materialType->self() is a valid Bio::MAGE::Association::End'
  );





my $biomaterial;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $biomaterial = Bio::MAGE::BioMaterial::BioMaterial->new();
}

# testing superclass BioMaterial
isa_ok($biomaterial, q[Bio::MAGE::BioMaterial::BioMaterial]);
isa_ok($biosource, q[Bio::MAGE::BioMaterial::BioMaterial]);

