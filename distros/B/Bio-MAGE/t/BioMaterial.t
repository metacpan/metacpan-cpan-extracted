##############################
#
# BioMaterial.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioMaterial.t`

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
use Test::More tests => 164;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::BioMaterial') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioMaterial::Treatment;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;

use Bio::MAGE::BioMaterial::BioSource;
use Bio::MAGE::BioMaterial::LabeledExtract;
use Bio::MAGE::BioMaterial::BioSample;

# we test the new() method
my $biomaterial;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial = Bio::MAGE::BioMaterial::BioMaterial->new();
}
isa_ok($biomaterial, 'Bio::MAGE::BioMaterial::BioMaterial');

# test the package_name class method
is($biomaterial->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($biomaterial->class_name(), q[Bio::MAGE::BioMaterial::BioMaterial],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial = Bio::MAGE::BioMaterial::BioMaterial->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($biomaterial->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$biomaterial->setIdentifier('1');
is($biomaterial->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$biomaterial->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$biomaterial->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biomaterial->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$biomaterial->setIdentifier(undef)};
ok((!$@ and not defined $biomaterial->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($biomaterial->getName(), '2',
  'name new');

# test getter/setter
$biomaterial->setName('2');
is($biomaterial->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$biomaterial->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$biomaterial->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$biomaterial->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$biomaterial->setName(undef)};
ok((!$@ and not defined $biomaterial->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::BioMaterial->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial = Bio::MAGE::BioMaterial::BioMaterial->new(auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
qualityControlStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
characteristics => [Bio::MAGE::Description::OntologyEntry->new()],
treatments => [Bio::MAGE::BioMaterial::Treatment->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
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


ok((UNIVERSAL::isa($biomaterial->getAuditTrail,'ARRAY')
 and scalar @{$biomaterial->getAuditTrail} == 1
 and UNIVERSAL::isa($biomaterial->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($biomaterial->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($biomaterial->getAuditTrail,'ARRAY')
 and scalar @{$biomaterial->getAuditTrail} == 1
 and $biomaterial->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($biomaterial->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getAuditTrail,'ARRAY')
 and scalar @{$biomaterial->getAuditTrail} == 2
 and $biomaterial->getAuditTrail->[0] == $audittrail_assn
 and $biomaterial->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$biomaterial->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$biomaterial->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$biomaterial->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$biomaterial->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$biomaterial->setAuditTrail([])};
ok((!$@ and defined $biomaterial->getAuditTrail()
    and UNIVERSAL::isa($biomaterial->getAuditTrail, 'ARRAY')
    and scalar @{$biomaterial->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$biomaterial->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$biomaterial->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$biomaterial->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$biomaterial->setAuditTrail(undef)};
ok((!$@ and not defined $biomaterial->getAuditTrail()),
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


ok((UNIVERSAL::isa($biomaterial->getPropertySets,'ARRAY')
 and scalar @{$biomaterial->getPropertySets} == 1
 and UNIVERSAL::isa($biomaterial->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($biomaterial->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($biomaterial->getPropertySets,'ARRAY')
 and scalar @{$biomaterial->getPropertySets} == 1
 and $biomaterial->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($biomaterial->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getPropertySets,'ARRAY')
 and scalar @{$biomaterial->getPropertySets} == 2
 and $biomaterial->getPropertySets->[0] == $propertysets_assn
 and $biomaterial->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$biomaterial->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$biomaterial->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$biomaterial->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$biomaterial->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$biomaterial->setPropertySets([])};
ok((!$@ and defined $biomaterial->getPropertySets()
    and UNIVERSAL::isa($biomaterial->getPropertySets, 'ARRAY')
    and scalar @{$biomaterial->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$biomaterial->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$biomaterial->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$biomaterial->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$biomaterial->setPropertySets(undef)};
ok((!$@ and not defined $biomaterial->getPropertySets()),
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


ok((UNIVERSAL::isa($biomaterial->getQualityControlStatistics,'ARRAY')
 and scalar @{$biomaterial->getQualityControlStatistics} == 1
 and UNIVERSAL::isa($biomaterial->getQualityControlStatistics->[0], q[Bio::MAGE::NameValueType])),
  'qualityControlStatistics set in new()');

ok(eq_array($biomaterial->setQualityControlStatistics([$qualitycontrolstatistics_assn]), [$qualitycontrolstatistics_assn]),
   'setQualityControlStatistics returns correct value');

ok((UNIVERSAL::isa($biomaterial->getQualityControlStatistics,'ARRAY')
 and scalar @{$biomaterial->getQualityControlStatistics} == 1
 and $biomaterial->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn),
   'getQualityControlStatistics fetches correct value');

is($biomaterial->addQualityControlStatistics($qualitycontrolstatistics_assn), 2,
  'addQualityControlStatistics returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getQualityControlStatistics,'ARRAY')
 and scalar @{$biomaterial->getQualityControlStatistics} == 2
 and $biomaterial->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn
 and $biomaterial->getQualityControlStatistics->[1] == $qualitycontrolstatistics_assn),
  'addQualityControlStatistics adds correct value');

# test setQualityControlStatistics throws exception with non-array argument
eval {$biomaterial->setQualityControlStatistics(1)};
ok($@, 'setQualityControlStatistics throws exception with non-array argument');

# test setQualityControlStatistics throws exception with bad argument array
eval {$biomaterial->setQualityControlStatistics([1])};
ok($@, 'setQualityControlStatistics throws exception with bad argument array');

# test addQualityControlStatistics throws exception with no arguments
eval {$biomaterial->addQualityControlStatistics()};
ok($@, 'addQualityControlStatistics throws exception with no arguments');

# test addQualityControlStatistics throws exception with bad argument
eval {$biomaterial->addQualityControlStatistics(1)};
ok($@, 'addQualityControlStatistics throws exception with bad array');

# test setQualityControlStatistics accepts empty array ref
eval {$biomaterial->setQualityControlStatistics([])};
ok((!$@ and defined $biomaterial->getQualityControlStatistics()
    and UNIVERSAL::isa($biomaterial->getQualityControlStatistics, 'ARRAY')
    and scalar @{$biomaterial->getQualityControlStatistics} == 0),
   'setQualityControlStatistics accepts empty array ref');


# test getQualityControlStatistics throws exception with argument
eval {$biomaterial->getQualityControlStatistics(1)};
ok($@, 'getQualityControlStatistics throws exception with argument');

# test setQualityControlStatistics throws exception with no argument
eval {$biomaterial->setQualityControlStatistics()};
ok($@, 'setQualityControlStatistics throws exception with no argument');

# test setQualityControlStatistics throws exception with too many argument
eval {$biomaterial->setQualityControlStatistics(1,2)};
ok($@, 'setQualityControlStatistics throws exception with too many argument');

# test setQualityControlStatistics accepts undef
eval {$biomaterial->setQualityControlStatistics(undef)};
ok((!$@ and not defined $biomaterial->getQualityControlStatistics()),
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


ok((UNIVERSAL::isa($biomaterial->getDescriptions,'ARRAY')
 and scalar @{$biomaterial->getDescriptions} == 1
 and UNIVERSAL::isa($biomaterial->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($biomaterial->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($biomaterial->getDescriptions,'ARRAY')
 and scalar @{$biomaterial->getDescriptions} == 1
 and $biomaterial->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($biomaterial->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getDescriptions,'ARRAY')
 and scalar @{$biomaterial->getDescriptions} == 2
 and $biomaterial->getDescriptions->[0] == $descriptions_assn
 and $biomaterial->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$biomaterial->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$biomaterial->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$biomaterial->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$biomaterial->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$biomaterial->setDescriptions([])};
ok((!$@ and defined $biomaterial->getDescriptions()
    and UNIVERSAL::isa($biomaterial->getDescriptions, 'ARRAY')
    and scalar @{$biomaterial->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$biomaterial->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$biomaterial->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$biomaterial->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$biomaterial->setDescriptions(undef)};
ok((!$@ and not defined $biomaterial->getDescriptions()),
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


ok((UNIVERSAL::isa($biomaterial->getCharacteristics,'ARRAY')
 and scalar @{$biomaterial->getCharacteristics} == 1
 and UNIVERSAL::isa($biomaterial->getCharacteristics->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'characteristics set in new()');

ok(eq_array($biomaterial->setCharacteristics([$characteristics_assn]), [$characteristics_assn]),
   'setCharacteristics returns correct value');

ok((UNIVERSAL::isa($biomaterial->getCharacteristics,'ARRAY')
 and scalar @{$biomaterial->getCharacteristics} == 1
 and $biomaterial->getCharacteristics->[0] == $characteristics_assn),
   'getCharacteristics fetches correct value');

is($biomaterial->addCharacteristics($characteristics_assn), 2,
  'addCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getCharacteristics,'ARRAY')
 and scalar @{$biomaterial->getCharacteristics} == 2
 and $biomaterial->getCharacteristics->[0] == $characteristics_assn
 and $biomaterial->getCharacteristics->[1] == $characteristics_assn),
  'addCharacteristics adds correct value');

# test setCharacteristics throws exception with non-array argument
eval {$biomaterial->setCharacteristics(1)};
ok($@, 'setCharacteristics throws exception with non-array argument');

# test setCharacteristics throws exception with bad argument array
eval {$biomaterial->setCharacteristics([1])};
ok($@, 'setCharacteristics throws exception with bad argument array');

# test addCharacteristics throws exception with no arguments
eval {$biomaterial->addCharacteristics()};
ok($@, 'addCharacteristics throws exception with no arguments');

# test addCharacteristics throws exception with bad argument
eval {$biomaterial->addCharacteristics(1)};
ok($@, 'addCharacteristics throws exception with bad array');

# test setCharacteristics accepts empty array ref
eval {$biomaterial->setCharacteristics([])};
ok((!$@ and defined $biomaterial->getCharacteristics()
    and UNIVERSAL::isa($biomaterial->getCharacteristics, 'ARRAY')
    and scalar @{$biomaterial->getCharacteristics} == 0),
   'setCharacteristics accepts empty array ref');


# test getCharacteristics throws exception with argument
eval {$biomaterial->getCharacteristics(1)};
ok($@, 'getCharacteristics throws exception with argument');

# test setCharacteristics throws exception with no argument
eval {$biomaterial->setCharacteristics()};
ok($@, 'setCharacteristics throws exception with no argument');

# test setCharacteristics throws exception with too many argument
eval {$biomaterial->setCharacteristics(1,2)};
ok($@, 'setCharacteristics throws exception with too many argument');

# test setCharacteristics accepts undef
eval {$biomaterial->setCharacteristics(undef)};
ok((!$@ and not defined $biomaterial->getCharacteristics()),
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


ok((UNIVERSAL::isa($biomaterial->getTreatments,'ARRAY')
 and scalar @{$biomaterial->getTreatments} == 1
 and UNIVERSAL::isa($biomaterial->getTreatments->[0], q[Bio::MAGE::BioMaterial::Treatment])),
  'treatments set in new()');

ok(eq_array($biomaterial->setTreatments([$treatments_assn]), [$treatments_assn]),
   'setTreatments returns correct value');

ok((UNIVERSAL::isa($biomaterial->getTreatments,'ARRAY')
 and scalar @{$biomaterial->getTreatments} == 1
 and $biomaterial->getTreatments->[0] == $treatments_assn),
   'getTreatments fetches correct value');

is($biomaterial->addTreatments($treatments_assn), 2,
  'addTreatments returns number of items in list');

ok((UNIVERSAL::isa($biomaterial->getTreatments,'ARRAY')
 and scalar @{$biomaterial->getTreatments} == 2
 and $biomaterial->getTreatments->[0] == $treatments_assn
 and $biomaterial->getTreatments->[1] == $treatments_assn),
  'addTreatments adds correct value');

# test setTreatments throws exception with non-array argument
eval {$biomaterial->setTreatments(1)};
ok($@, 'setTreatments throws exception with non-array argument');

# test setTreatments throws exception with bad argument array
eval {$biomaterial->setTreatments([1])};
ok($@, 'setTreatments throws exception with bad argument array');

# test addTreatments throws exception with no arguments
eval {$biomaterial->addTreatments()};
ok($@, 'addTreatments throws exception with no arguments');

# test addTreatments throws exception with bad argument
eval {$biomaterial->addTreatments(1)};
ok($@, 'addTreatments throws exception with bad array');

# test setTreatments accepts empty array ref
eval {$biomaterial->setTreatments([])};
ok((!$@ and defined $biomaterial->getTreatments()
    and UNIVERSAL::isa($biomaterial->getTreatments, 'ARRAY')
    and scalar @{$biomaterial->getTreatments} == 0),
   'setTreatments accepts empty array ref');


# test getTreatments throws exception with argument
eval {$biomaterial->getTreatments(1)};
ok($@, 'getTreatments throws exception with argument');

# test setTreatments throws exception with no argument
eval {$biomaterial->setTreatments()};
ok($@, 'setTreatments throws exception with no argument');

# test setTreatments throws exception with too many argument
eval {$biomaterial->setTreatments(1,2)};
ok($@, 'setTreatments throws exception with too many argument');

# test setTreatments accepts undef
eval {$biomaterial->setTreatments(undef)};
ok((!$@ and not defined $biomaterial->getTreatments()),
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


isa_ok($biomaterial->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($biomaterial->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($biomaterial->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$biomaterial->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$biomaterial->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$biomaterial->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$biomaterial->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$biomaterial->setSecurity(undef)};
ok((!$@ and not defined $biomaterial->getSecurity()),
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


isa_ok($biomaterial->getMaterialType, q[Bio::MAGE::Description::OntologyEntry]);

is($biomaterial->setMaterialType($materialtype_assn), $materialtype_assn,
  'setMaterialType returns value');

ok($biomaterial->getMaterialType() == $materialtype_assn,
   'getMaterialType fetches correct value');

# test setMaterialType throws exception with bad argument
eval {$biomaterial->setMaterialType(1)};
ok($@, 'setMaterialType throws exception with bad argument');


# test getMaterialType throws exception with argument
eval {$biomaterial->getMaterialType(1)};
ok($@, 'getMaterialType throws exception with argument');

# test setMaterialType throws exception with no argument
eval {$biomaterial->setMaterialType()};
ok($@, 'setMaterialType throws exception with no argument');

# test setMaterialType throws exception with too many argument
eval {$biomaterial->setMaterialType(1,2)};
ok($@, 'setMaterialType throws exception with too many argument');

# test setMaterialType accepts undef
eval {$biomaterial->setMaterialType(undef)};
ok((!$@ and not defined $biomaterial->getMaterialType()),
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




# create a subclass
my $biosource = Bio::MAGE::BioMaterial::BioSource->new();

# testing subclass BioSource
isa_ok($biosource, q[Bio::MAGE::BioMaterial::BioSource]);
isa_ok($biosource, q[Bio::MAGE::BioMaterial::BioMaterial]);


# create a subclass
my $labeledextract = Bio::MAGE::BioMaterial::LabeledExtract->new();

# testing subclass LabeledExtract
isa_ok($labeledextract, q[Bio::MAGE::BioMaterial::LabeledExtract]);
isa_ok($labeledextract, q[Bio::MAGE::BioMaterial::BioMaterial]);


# create a subclass
my $biosample = Bio::MAGE::BioMaterial::BioSample->new();

# testing subclass BioSample
isa_ok($biosample, q[Bio::MAGE::BioMaterial::BioSample]);
isa_ok($biosample, q[Bio::MAGE::BioMaterial::BioMaterial]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($biomaterial, q[Bio::MAGE::Identifiable]);

