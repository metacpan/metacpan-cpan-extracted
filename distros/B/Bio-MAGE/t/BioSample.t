##############################
#
# BioSample.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioSample.t`

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
use Test::More tests => 171;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::BioSample') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioMaterial::Treatment;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $biosample;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosample = Bio::MAGE::BioMaterial::BioSample->new();
}
isa_ok($biosample, 'Bio::MAGE::BioMaterial::BioSample');

# test the package_name class method
is($biosample->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($biosample->class_name(), q[Bio::MAGE::BioMaterial::BioSample],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosample = Bio::MAGE::BioMaterial::BioSample->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($biosample->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$biosample->setIdentifier('1');
is($biosample->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$biosample->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosample->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosample->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$biosample->setIdentifier(undef)};
ok((!$@ and not defined $biosample->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($biosample->getName(), '2',
  'name new');

# test getter/setter
$biosample->setName('2');
is($biosample->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$biosample->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$biosample->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biosample->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$biosample->setName(undef)};
ok((!$@ and not defined $biosample->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::BioSample->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biosample = Bio::MAGE::BioMaterial::BioSample->new(auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
qualityControlStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
characteristics => [Bio::MAGE::Description::OntologyEntry->new()],
treatments => [Bio::MAGE::BioMaterial::Treatment->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
type => Bio::MAGE::Description::OntologyEntry->new(),
materialType => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($biosample->getAuditTrail,'ARRAY')
 and scalar @{$biosample->getAuditTrail} == 1
 and UNIVERSAL::isa($biosample->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($biosample->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($biosample->getAuditTrail,'ARRAY')
 and scalar @{$biosample->getAuditTrail} == 1
 and $biosample->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($biosample->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($biosample->getAuditTrail,'ARRAY')
 and scalar @{$biosample->getAuditTrail} == 2
 and $biosample->getAuditTrail->[0] == $audittrail_assn
 and $biosample->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$biosample->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$biosample->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$biosample->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$biosample->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$biosample->setAuditTrail([])};
ok((!$@ and defined $biosample->getAuditTrail()
    and UNIVERSAL::isa($biosample->getAuditTrail, 'ARRAY')
    and scalar @{$biosample->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$biosample->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$biosample->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$biosample->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$biosample->setAuditTrail(undef)};
ok((!$@ and not defined $biosample->getAuditTrail()),
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


ok((UNIVERSAL::isa($biosample->getPropertySets,'ARRAY')
 and scalar @{$biosample->getPropertySets} == 1
 and UNIVERSAL::isa($biosample->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biosample->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biosample->getPropertySets,'ARRAY')
 and scalar @{$biosample->getPropertySets} == 1
 and $biosample->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biosample->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biosample->getPropertySets,'ARRAY')
 and scalar @{$biosample->getPropertySets} == 2
 and $biosample->getPropertySets->[0] == $propertysets_assn
 and $biosample->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biosample->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biosample->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biosample->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biosample->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biosample->setPropertySets([])};
ok((!$@ and defined $biosample->getPropertySets()
    and UNIVERSAL::isa($biosample->getPropertySets, 'ARRAY')
    and scalar @{$biosample->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biosample->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biosample->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biosample->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biosample->setPropertySets(undef)};
ok((!$@ and not defined $biosample->getPropertySets()),
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


ok((UNIVERSAL::isa($biosample->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosample->getQualityControlStatistics} == 1
 and UNIVERSAL::isa($biosample->getQualityControlStatistics->[0], q[Bio::MAGE::NameValueType])),
  'qualityControlStatistics set in new()');

ok(eq_array($biosample->setQualityControlStatistics([$qualitycontrolstatistics_assn]), [$qualitycontrolstatistics_assn]),
   'setQualityControlStatistics returns correct value');

ok((UNIVERSAL::isa($biosample->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosample->getQualityControlStatistics} == 1
 and $biosample->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn),
   'getQualityControlStatistics fetches correct value');

is($biosample->addQualityControlStatistics($qualitycontrolstatistics_assn), 2,
  'addQualityControlStatistics returns number of items in list');

ok((UNIVERSAL::isa($biosample->getQualityControlStatistics,'ARRAY')
 and scalar @{$biosample->getQualityControlStatistics} == 2
 and $biosample->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn
 and $biosample->getQualityControlStatistics->[1] == $qualitycontrolstatistics_assn),
  'addQualityControlStatistics adds correct value');

# test setQualityControlStatistics throws exception with non-array argument
eval {$biosample->setQualityControlStatistics(1)};
ok($@, 'setQualityControlStatistics throws exception with non-array argument');

# test setQualityControlStatistics throws exception with bad argument array
eval {$biosample->setQualityControlStatistics([1])};
ok($@, 'setQualityControlStatistics throws exception with bad argument array');

# test addQualityControlStatistics throws exception with no arguments
eval {$biosample->addQualityControlStatistics()};
ok($@, 'addQualityControlStatistics throws exception with no arguments');

# test addQualityControlStatistics throws exception with bad argument
eval {$biosample->addQualityControlStatistics(1)};
ok($@, 'addQualityControlStatistics throws exception with bad array');

# test setQualityControlStatistics accepts empty array ref
eval {$biosample->setQualityControlStatistics([])};
ok((!$@ and defined $biosample->getQualityControlStatistics()
    and UNIVERSAL::isa($biosample->getQualityControlStatistics, 'ARRAY')
    and scalar @{$biosample->getQualityControlStatistics} == 0),
   'setQualityControlStatistics accepts empty array ref');


# test getQualityControlStatistics throws exception with argument
eval {$biosample->getQualityControlStatistics(1)};
ok($@, 'getQualityControlStatistics throws exception with argument');

# test setQualityControlStatistics throws exception with no argument
eval {$biosample->setQualityControlStatistics()};
ok($@, 'setQualityControlStatistics throws exception with no argument');

# test setQualityControlStatistics throws exception with too many argument
eval {$biosample->setQualityControlStatistics(1,2)};
ok($@, 'setQualityControlStatistics throws exception with too many argument');

# test setQualityControlStatistics accepts undef
eval {$biosample->setQualityControlStatistics(undef)};
ok((!$@ and not defined $biosample->getQualityControlStatistics()),
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


ok((UNIVERSAL::isa($biosample->getDescriptions,'ARRAY')
 and scalar @{$biosample->getDescriptions} == 1
 and UNIVERSAL::isa($biosample->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($biosample->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($biosample->getDescriptions,'ARRAY')
 and scalar @{$biosample->getDescriptions} == 1
 and $biosample->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($biosample->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($biosample->getDescriptions,'ARRAY')
 and scalar @{$biosample->getDescriptions} == 2
 and $biosample->getDescriptions->[0] == $descriptions_assn
 and $biosample->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$biosample->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$biosample->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$biosample->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$biosample->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$biosample->setDescriptions([])};
ok((!$@ and defined $biosample->getDescriptions()
    and UNIVERSAL::isa($biosample->getDescriptions, 'ARRAY')
    and scalar @{$biosample->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$biosample->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$biosample->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$biosample->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$biosample->setDescriptions(undef)};
ok((!$@ and not defined $biosample->getDescriptions()),
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


ok((UNIVERSAL::isa($biosample->getCharacteristics,'ARRAY')
 and scalar @{$biosample->getCharacteristics} == 1
 and UNIVERSAL::isa($biosample->getCharacteristics->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'characteristics set in new()');

ok(eq_array($biosample->setCharacteristics([$characteristics_assn]), [$characteristics_assn]),
   'setCharacteristics returns correct value');

ok((UNIVERSAL::isa($biosample->getCharacteristics,'ARRAY')
 and scalar @{$biosample->getCharacteristics} == 1
 and $biosample->getCharacteristics->[0] == $characteristics_assn),
   'getCharacteristics fetches correct value');

is($biosample->addCharacteristics($characteristics_assn), 2,
  'addCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($biosample->getCharacteristics,'ARRAY')
 and scalar @{$biosample->getCharacteristics} == 2
 and $biosample->getCharacteristics->[0] == $characteristics_assn
 and $biosample->getCharacteristics->[1] == $characteristics_assn),
  'addCharacteristics adds correct value');

# test setCharacteristics throws exception with non-array argument
eval {$biosample->setCharacteristics(1)};
ok($@, 'setCharacteristics throws exception with non-array argument');

# test setCharacteristics throws exception with bad argument array
eval {$biosample->setCharacteristics([1])};
ok($@, 'setCharacteristics throws exception with bad argument array');

# test addCharacteristics throws exception with no arguments
eval {$biosample->addCharacteristics()};
ok($@, 'addCharacteristics throws exception with no arguments');

# test addCharacteristics throws exception with bad argument
eval {$biosample->addCharacteristics(1)};
ok($@, 'addCharacteristics throws exception with bad array');

# test setCharacteristics accepts empty array ref
eval {$biosample->setCharacteristics([])};
ok((!$@ and defined $biosample->getCharacteristics()
    and UNIVERSAL::isa($biosample->getCharacteristics, 'ARRAY')
    and scalar @{$biosample->getCharacteristics} == 0),
   'setCharacteristics accepts empty array ref');


# test getCharacteristics throws exception with argument
eval {$biosample->getCharacteristics(1)};
ok($@, 'getCharacteristics throws exception with argument');

# test setCharacteristics throws exception with no argument
eval {$biosample->setCharacteristics()};
ok($@, 'setCharacteristics throws exception with no argument');

# test setCharacteristics throws exception with too many argument
eval {$biosample->setCharacteristics(1,2)};
ok($@, 'setCharacteristics throws exception with too many argument');

# test setCharacteristics accepts undef
eval {$biosample->setCharacteristics(undef)};
ok((!$@ and not defined $biosample->getCharacteristics()),
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


ok((UNIVERSAL::isa($biosample->getTreatments,'ARRAY')
 and scalar @{$biosample->getTreatments} == 1
 and UNIVERSAL::isa($biosample->getTreatments->[0], q[Bio::MAGE::BioMaterial::Treatment])),
  'treatments set in new()');

ok(eq_array($biosample->setTreatments([$treatments_assn]), [$treatments_assn]),
   'setTreatments returns correct value');

ok((UNIVERSAL::isa($biosample->getTreatments,'ARRAY')
 and scalar @{$biosample->getTreatments} == 1
 and $biosample->getTreatments->[0] == $treatments_assn),
   'getTreatments fetches correct value');

is($biosample->addTreatments($treatments_assn), 2,
  'addTreatments returns number of items in list');

ok((UNIVERSAL::isa($biosample->getTreatments,'ARRAY')
 and scalar @{$biosample->getTreatments} == 2
 and $biosample->getTreatments->[0] == $treatments_assn
 and $biosample->getTreatments->[1] == $treatments_assn),
  'addTreatments adds correct value');

# test setTreatments throws exception with non-array argument
eval {$biosample->setTreatments(1)};
ok($@, 'setTreatments throws exception with non-array argument');

# test setTreatments throws exception with bad argument array
eval {$biosample->setTreatments([1])};
ok($@, 'setTreatments throws exception with bad argument array');

# test addTreatments throws exception with no arguments
eval {$biosample->addTreatments()};
ok($@, 'addTreatments throws exception with no arguments');

# test addTreatments throws exception with bad argument
eval {$biosample->addTreatments(1)};
ok($@, 'addTreatments throws exception with bad array');

# test setTreatments accepts empty array ref
eval {$biosample->setTreatments([])};
ok((!$@ and defined $biosample->getTreatments()
    and UNIVERSAL::isa($biosample->getTreatments, 'ARRAY')
    and scalar @{$biosample->getTreatments} == 0),
   'setTreatments accepts empty array ref');


# test getTreatments throws exception with argument
eval {$biosample->getTreatments(1)};
ok($@, 'getTreatments throws exception with argument');

# test setTreatments throws exception with no argument
eval {$biosample->setTreatments()};
ok($@, 'setTreatments throws exception with no argument');

# test setTreatments throws exception with too many argument
eval {$biosample->setTreatments(1,2)};
ok($@, 'setTreatments throws exception with too many argument');

# test setTreatments accepts undef
eval {$biosample->setTreatments(undef)};
ok((!$@ and not defined $biosample->getTreatments()),
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


isa_ok($biosample->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($biosample->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($biosample->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$biosample->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$biosample->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$biosample->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$biosample->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$biosample->setSecurity(undef)};
ok((!$@ and not defined $biosample->getSecurity()),
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



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosample->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($biosample->setType($type_assn), $type_assn,
  'setType returns value');

ok($biosample->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$biosample->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$biosample->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$biosample->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$biosample->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$biosample->setType(undef)};
ok((!$@ and not defined $biosample->getType()),
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



# testing association materialType
my $materialtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $materialtype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($biosample->getMaterialType, q[Bio::MAGE::Description::OntologyEntry]);

is($biosample->setMaterialType($materialtype_assn), $materialtype_assn,
  'setMaterialType returns value');

ok($biosample->getMaterialType() == $materialtype_assn,
   'getMaterialType fetches correct value');

# test setMaterialType throws exception with bad argument
eval {$biosample->setMaterialType(1)};
ok($@, 'setMaterialType throws exception with bad argument');


# test getMaterialType throws exception with argument
eval {$biosample->getMaterialType(1)};
ok($@, 'getMaterialType throws exception with argument');

# test setMaterialType throws exception with no argument
eval {$biosample->setMaterialType()};
ok($@, 'setMaterialType throws exception with no argument');

# test setMaterialType throws exception with too many argument
eval {$biosample->setMaterialType(1,2)};
ok($@, 'setMaterialType throws exception with too many argument');

# test setMaterialType accepts undef
eval {$biosample->setMaterialType(undef)};
ok((!$@ and not defined $biosample->getMaterialType()),
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
isa_ok($biosample, q[Bio::MAGE::BioMaterial::BioMaterial]);

