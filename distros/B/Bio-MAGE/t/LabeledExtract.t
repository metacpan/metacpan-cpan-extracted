##############################
#
# LabeledExtract.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl LabeledExtract.t`

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

BEGIN { use_ok('Bio::MAGE::BioMaterial::LabeledExtract') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::BioMaterial::Compound;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::BioMaterial::Treatment;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $labeledextract;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $labeledextract = Bio::MAGE::BioMaterial::LabeledExtract->new();
}
isa_ok($labeledextract, 'Bio::MAGE::BioMaterial::LabeledExtract');

# test the package_name class method
is($labeledextract->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($labeledextract->class_name(), q[Bio::MAGE::BioMaterial::LabeledExtract],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $labeledextract = Bio::MAGE::BioMaterial::LabeledExtract->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($labeledextract->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$labeledextract->setIdentifier('1');
is($labeledextract->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$labeledextract->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$labeledextract->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$labeledextract->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$labeledextract->setIdentifier(undef)};
ok((!$@ and not defined $labeledextract->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($labeledextract->getName(), '2',
  'name new');

# test getter/setter
$labeledextract->setName('2');
is($labeledextract->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$labeledextract->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$labeledextract->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$labeledextract->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$labeledextract->setName(undef)};
ok((!$@ and not defined $labeledextract->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::LabeledExtract->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $labeledextract = Bio::MAGE::BioMaterial::LabeledExtract->new(auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
qualityControlStatistics => [Bio::MAGE::NameValueType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
characteristics => [Bio::MAGE::Description::OntologyEntry->new()],
treatments => [Bio::MAGE::BioMaterial::Treatment->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
labels => [Bio::MAGE::BioMaterial::Compound->new()],
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


ok((UNIVERSAL::isa($labeledextract->getAuditTrail,'ARRAY')
 and scalar @{$labeledextract->getAuditTrail} == 1
 and UNIVERSAL::isa($labeledextract->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($labeledextract->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($labeledextract->getAuditTrail,'ARRAY')
 and scalar @{$labeledextract->getAuditTrail} == 1
 and $labeledextract->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($labeledextract->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getAuditTrail,'ARRAY')
 and scalar @{$labeledextract->getAuditTrail} == 2
 and $labeledextract->getAuditTrail->[0] == $audittrail_assn
 and $labeledextract->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$labeledextract->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$labeledextract->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$labeledextract->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$labeledextract->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$labeledextract->setAuditTrail([])};
ok((!$@ and defined $labeledextract->getAuditTrail()
    and UNIVERSAL::isa($labeledextract->getAuditTrail, 'ARRAY')
    and scalar @{$labeledextract->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$labeledextract->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$labeledextract->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$labeledextract->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$labeledextract->setAuditTrail(undef)};
ok((!$@ and not defined $labeledextract->getAuditTrail()),
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


ok((UNIVERSAL::isa($labeledextract->getPropertySets,'ARRAY')
 and scalar @{$labeledextract->getPropertySets} == 1
 and UNIVERSAL::isa($labeledextract->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($labeledextract->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($labeledextract->getPropertySets,'ARRAY')
 and scalar @{$labeledextract->getPropertySets} == 1
 and $labeledextract->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($labeledextract->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getPropertySets,'ARRAY')
 and scalar @{$labeledextract->getPropertySets} == 2
 and $labeledextract->getPropertySets->[0] == $propertysets_assn
 and $labeledextract->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$labeledextract->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$labeledextract->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$labeledextract->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$labeledextract->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$labeledextract->setPropertySets([])};
ok((!$@ and defined $labeledextract->getPropertySets()
    and UNIVERSAL::isa($labeledextract->getPropertySets, 'ARRAY')
    and scalar @{$labeledextract->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$labeledextract->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$labeledextract->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$labeledextract->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$labeledextract->setPropertySets(undef)};
ok((!$@ and not defined $labeledextract->getPropertySets()),
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


ok((UNIVERSAL::isa($labeledextract->getQualityControlStatistics,'ARRAY')
 and scalar @{$labeledextract->getQualityControlStatistics} == 1
 and UNIVERSAL::isa($labeledextract->getQualityControlStatistics->[0], q[Bio::MAGE::NameValueType])),
  'qualityControlStatistics set in new()');

ok(eq_array($labeledextract->setQualityControlStatistics([$qualitycontrolstatistics_assn]), [$qualitycontrolstatistics_assn]),
   'setQualityControlStatistics returns correct value');

ok((UNIVERSAL::isa($labeledextract->getQualityControlStatistics,'ARRAY')
 and scalar @{$labeledextract->getQualityControlStatistics} == 1
 and $labeledextract->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn),
   'getQualityControlStatistics fetches correct value');

is($labeledextract->addQualityControlStatistics($qualitycontrolstatistics_assn), 2,
  'addQualityControlStatistics returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getQualityControlStatistics,'ARRAY')
 and scalar @{$labeledextract->getQualityControlStatistics} == 2
 and $labeledextract->getQualityControlStatistics->[0] == $qualitycontrolstatistics_assn
 and $labeledextract->getQualityControlStatistics->[1] == $qualitycontrolstatistics_assn),
  'addQualityControlStatistics adds correct value');

# test setQualityControlStatistics throws exception with non-array argument
eval {$labeledextract->setQualityControlStatistics(1)};
ok($@, 'setQualityControlStatistics throws exception with non-array argument');

# test setQualityControlStatistics throws exception with bad argument array
eval {$labeledextract->setQualityControlStatistics([1])};
ok($@, 'setQualityControlStatistics throws exception with bad argument array');

# test addQualityControlStatistics throws exception with no arguments
eval {$labeledextract->addQualityControlStatistics()};
ok($@, 'addQualityControlStatistics throws exception with no arguments');

# test addQualityControlStatistics throws exception with bad argument
eval {$labeledextract->addQualityControlStatistics(1)};
ok($@, 'addQualityControlStatistics throws exception with bad array');

# test setQualityControlStatistics accepts empty array ref
eval {$labeledextract->setQualityControlStatistics([])};
ok((!$@ and defined $labeledextract->getQualityControlStatistics()
    and UNIVERSAL::isa($labeledextract->getQualityControlStatistics, 'ARRAY')
    and scalar @{$labeledextract->getQualityControlStatistics} == 0),
   'setQualityControlStatistics accepts empty array ref');


# test getQualityControlStatistics throws exception with argument
eval {$labeledextract->getQualityControlStatistics(1)};
ok($@, 'getQualityControlStatistics throws exception with argument');

# test setQualityControlStatistics throws exception with no argument
eval {$labeledextract->setQualityControlStatistics()};
ok($@, 'setQualityControlStatistics throws exception with no argument');

# test setQualityControlStatistics throws exception with too many argument
eval {$labeledextract->setQualityControlStatistics(1,2)};
ok($@, 'setQualityControlStatistics throws exception with too many argument');

# test setQualityControlStatistics accepts undef
eval {$labeledextract->setQualityControlStatistics(undef)};
ok((!$@ and not defined $labeledextract->getQualityControlStatistics()),
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


ok((UNIVERSAL::isa($labeledextract->getDescriptions,'ARRAY')
 and scalar @{$labeledextract->getDescriptions} == 1
 and UNIVERSAL::isa($labeledextract->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($labeledextract->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($labeledextract->getDescriptions,'ARRAY')
 and scalar @{$labeledextract->getDescriptions} == 1
 and $labeledextract->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($labeledextract->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getDescriptions,'ARRAY')
 and scalar @{$labeledextract->getDescriptions} == 2
 and $labeledextract->getDescriptions->[0] == $descriptions_assn
 and $labeledextract->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$labeledextract->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$labeledextract->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$labeledextract->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$labeledextract->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$labeledextract->setDescriptions([])};
ok((!$@ and defined $labeledextract->getDescriptions()
    and UNIVERSAL::isa($labeledextract->getDescriptions, 'ARRAY')
    and scalar @{$labeledextract->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$labeledextract->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$labeledextract->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$labeledextract->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$labeledextract->setDescriptions(undef)};
ok((!$@ and not defined $labeledextract->getDescriptions()),
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


ok((UNIVERSAL::isa($labeledextract->getCharacteristics,'ARRAY')
 and scalar @{$labeledextract->getCharacteristics} == 1
 and UNIVERSAL::isa($labeledextract->getCharacteristics->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'characteristics set in new()');

ok(eq_array($labeledextract->setCharacteristics([$characteristics_assn]), [$characteristics_assn]),
   'setCharacteristics returns correct value');

ok((UNIVERSAL::isa($labeledextract->getCharacteristics,'ARRAY')
 and scalar @{$labeledextract->getCharacteristics} == 1
 and $labeledextract->getCharacteristics->[0] == $characteristics_assn),
   'getCharacteristics fetches correct value');

is($labeledextract->addCharacteristics($characteristics_assn), 2,
  'addCharacteristics returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getCharacteristics,'ARRAY')
 and scalar @{$labeledextract->getCharacteristics} == 2
 and $labeledextract->getCharacteristics->[0] == $characteristics_assn
 and $labeledextract->getCharacteristics->[1] == $characteristics_assn),
  'addCharacteristics adds correct value');

# test setCharacteristics throws exception with non-array argument
eval {$labeledextract->setCharacteristics(1)};
ok($@, 'setCharacteristics throws exception with non-array argument');

# test setCharacteristics throws exception with bad argument array
eval {$labeledextract->setCharacteristics([1])};
ok($@, 'setCharacteristics throws exception with bad argument array');

# test addCharacteristics throws exception with no arguments
eval {$labeledextract->addCharacteristics()};
ok($@, 'addCharacteristics throws exception with no arguments');

# test addCharacteristics throws exception with bad argument
eval {$labeledextract->addCharacteristics(1)};
ok($@, 'addCharacteristics throws exception with bad array');

# test setCharacteristics accepts empty array ref
eval {$labeledextract->setCharacteristics([])};
ok((!$@ and defined $labeledextract->getCharacteristics()
    and UNIVERSAL::isa($labeledextract->getCharacteristics, 'ARRAY')
    and scalar @{$labeledextract->getCharacteristics} == 0),
   'setCharacteristics accepts empty array ref');


# test getCharacteristics throws exception with argument
eval {$labeledextract->getCharacteristics(1)};
ok($@, 'getCharacteristics throws exception with argument');

# test setCharacteristics throws exception with no argument
eval {$labeledextract->setCharacteristics()};
ok($@, 'setCharacteristics throws exception with no argument');

# test setCharacteristics throws exception with too many argument
eval {$labeledextract->setCharacteristics(1,2)};
ok($@, 'setCharacteristics throws exception with too many argument');

# test setCharacteristics accepts undef
eval {$labeledextract->setCharacteristics(undef)};
ok((!$@ and not defined $labeledextract->getCharacteristics()),
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


ok((UNIVERSAL::isa($labeledextract->getTreatments,'ARRAY')
 and scalar @{$labeledextract->getTreatments} == 1
 and UNIVERSAL::isa($labeledextract->getTreatments->[0], q[Bio::MAGE::BioMaterial::Treatment])),
  'treatments set in new()');

ok(eq_array($labeledextract->setTreatments([$treatments_assn]), [$treatments_assn]),
   'setTreatments returns correct value');

ok((UNIVERSAL::isa($labeledextract->getTreatments,'ARRAY')
 and scalar @{$labeledextract->getTreatments} == 1
 and $labeledextract->getTreatments->[0] == $treatments_assn),
   'getTreatments fetches correct value');

is($labeledextract->addTreatments($treatments_assn), 2,
  'addTreatments returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getTreatments,'ARRAY')
 and scalar @{$labeledextract->getTreatments} == 2
 and $labeledextract->getTreatments->[0] == $treatments_assn
 and $labeledextract->getTreatments->[1] == $treatments_assn),
  'addTreatments adds correct value');

# test setTreatments throws exception with non-array argument
eval {$labeledextract->setTreatments(1)};
ok($@, 'setTreatments throws exception with non-array argument');

# test setTreatments throws exception with bad argument array
eval {$labeledextract->setTreatments([1])};
ok($@, 'setTreatments throws exception with bad argument array');

# test addTreatments throws exception with no arguments
eval {$labeledextract->addTreatments()};
ok($@, 'addTreatments throws exception with no arguments');

# test addTreatments throws exception with bad argument
eval {$labeledextract->addTreatments(1)};
ok($@, 'addTreatments throws exception with bad array');

# test setTreatments accepts empty array ref
eval {$labeledextract->setTreatments([])};
ok((!$@ and defined $labeledextract->getTreatments()
    and UNIVERSAL::isa($labeledextract->getTreatments, 'ARRAY')
    and scalar @{$labeledextract->getTreatments} == 0),
   'setTreatments accepts empty array ref');


# test getTreatments throws exception with argument
eval {$labeledextract->getTreatments(1)};
ok($@, 'getTreatments throws exception with argument');

# test setTreatments throws exception with no argument
eval {$labeledextract->setTreatments()};
ok($@, 'setTreatments throws exception with no argument');

# test setTreatments throws exception with too many argument
eval {$labeledextract->setTreatments(1,2)};
ok($@, 'setTreatments throws exception with too many argument');

# test setTreatments accepts undef
eval {$labeledextract->setTreatments(undef)};
ok((!$@ and not defined $labeledextract->getTreatments()),
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


isa_ok($labeledextract->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($labeledextract->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($labeledextract->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$labeledextract->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$labeledextract->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$labeledextract->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$labeledextract->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$labeledextract->setSecurity(undef)};
ok((!$@ and not defined $labeledextract->getSecurity()),
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



# testing association labels
my $labels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $labels_assn = Bio::MAGE::BioMaterial::Compound->new();
}


ok((UNIVERSAL::isa($labeledextract->getLabels,'ARRAY')
 and scalar @{$labeledextract->getLabels} == 1
 and UNIVERSAL::isa($labeledextract->getLabels->[0], q[Bio::MAGE::BioMaterial::Compound])),
  'labels set in new()');

ok(eq_array($labeledextract->setLabels([$labels_assn]), [$labels_assn]),
   'setLabels returns correct value');

ok((UNIVERSAL::isa($labeledextract->getLabels,'ARRAY')
 and scalar @{$labeledextract->getLabels} == 1
 and $labeledextract->getLabels->[0] == $labels_assn),
   'getLabels fetches correct value');

is($labeledextract->addLabels($labels_assn), 2,
  'addLabels returns number of items in list');

ok((UNIVERSAL::isa($labeledextract->getLabels,'ARRAY')
 and scalar @{$labeledextract->getLabels} == 2
 and $labeledextract->getLabels->[0] == $labels_assn
 and $labeledextract->getLabels->[1] == $labels_assn),
  'addLabels adds correct value');

# test setLabels throws exception with non-array argument
eval {$labeledextract->setLabels(1)};
ok($@, 'setLabels throws exception with non-array argument');

# test setLabels throws exception with bad argument array
eval {$labeledextract->setLabels([1])};
ok($@, 'setLabels throws exception with bad argument array');

# test addLabels throws exception with no arguments
eval {$labeledextract->addLabels()};
ok($@, 'addLabels throws exception with no arguments');

# test addLabels throws exception with bad argument
eval {$labeledextract->addLabels(1)};
ok($@, 'addLabels throws exception with bad array');

# test setLabels accepts empty array ref
eval {$labeledextract->setLabels([])};
ok((!$@ and defined $labeledextract->getLabels()
    and UNIVERSAL::isa($labeledextract->getLabels, 'ARRAY')
    and scalar @{$labeledextract->getLabels} == 0),
   'setLabels accepts empty array ref');


# test getLabels throws exception with argument
eval {$labeledextract->getLabels(1)};
ok($@, 'getLabels throws exception with argument');

# test setLabels throws exception with no argument
eval {$labeledextract->setLabels()};
ok($@, 'setLabels throws exception with no argument');

# test setLabels throws exception with too many argument
eval {$labeledextract->setLabels(1,2)};
ok($@, 'setLabels throws exception with too many argument');

# test setLabels accepts undef
eval {$labeledextract->setLabels(undef)};
ok((!$@ and not defined $labeledextract->getLabels()),
   'setLabels accepts undef');

# test the meta-data for the assoication
$assn = $assns{labels};
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
   'labels->other() is a valid Bio::MAGE::Association::End'
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
   'labels->self() is a valid Bio::MAGE::Association::End'
  );



# testing association materialType
my $materialtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $materialtype_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($labeledextract->getMaterialType, q[Bio::MAGE::Description::OntologyEntry]);

is($labeledextract->setMaterialType($materialtype_assn), $materialtype_assn,
  'setMaterialType returns value');

ok($labeledextract->getMaterialType() == $materialtype_assn,
   'getMaterialType fetches correct value');

# test setMaterialType throws exception with bad argument
eval {$labeledextract->setMaterialType(1)};
ok($@, 'setMaterialType throws exception with bad argument');


# test getMaterialType throws exception with argument
eval {$labeledextract->getMaterialType(1)};
ok($@, 'getMaterialType throws exception with argument');

# test setMaterialType throws exception with no argument
eval {$labeledextract->setMaterialType()};
ok($@, 'setMaterialType throws exception with no argument');

# test setMaterialType throws exception with too many argument
eval {$labeledextract->setMaterialType(1,2)};
ok($@, 'setMaterialType throws exception with too many argument');

# test setMaterialType accepts undef
eval {$labeledextract->setMaterialType(undef)};
ok((!$@ and not defined $labeledextract->getMaterialType()),
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
isa_ok($labeledextract, q[Bio::MAGE::BioMaterial::BioMaterial]);

