##############################
#
# ManufactureLIMSBiomaterial.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ManufactureLIMSBiomaterial.t`

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

BEGIN { use_ok('Bio::MAGE::Array::ManufactureLIMSBiomaterial') };

use Bio::MAGE::BioMaterial::BioMaterial;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::DatabaseEntry;


# we test the new() method
my $manufacturelimsbiomaterial;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new();
}
isa_ok($manufacturelimsbiomaterial, 'Bio::MAGE::Array::ManufactureLIMSBiomaterial');

# test the package_name class method
is($manufacturelimsbiomaterial->package_name(), q[Array],
  'package');

# test the class_name class method
is($manufacturelimsbiomaterial->class_name(), q[Bio::MAGE::Array::ManufactureLIMSBiomaterial],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new(bioMaterialPlateCol => '1',
bioMaterialPlateRow => '2',
bioMaterialPlateIdentifier => '3',
quality => '4');
}


#
# testing attribute bioMaterialPlateCol
#

# test attribute values can be set in new()
is($manufacturelimsbiomaterial->getBioMaterialPlateCol(), '1',
  'bioMaterialPlateCol new');

# test getter/setter
$manufacturelimsbiomaterial->setBioMaterialPlateCol('1');
is($manufacturelimsbiomaterial->getBioMaterialPlateCol(), '1',
  'bioMaterialPlateCol getter/setter');

# test getter throws exception with argument
eval {$manufacturelimsbiomaterial->getBioMaterialPlateCol(1)};
ok($@, 'bioMaterialPlateCol getter throws exception with argument');

# test setter throws exception with no argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateCol()};
ok($@, 'bioMaterialPlateCol setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateCol('1', '1')};
ok($@, 'bioMaterialPlateCol setter throws exception with too many argument');

# test setter accepts undef
eval {$manufacturelimsbiomaterial->setBioMaterialPlateCol(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getBioMaterialPlateCol()),
   'bioMaterialPlateCol setter accepts undef');



#
# testing attribute bioMaterialPlateRow
#

# test attribute values can be set in new()
is($manufacturelimsbiomaterial->getBioMaterialPlateRow(), '2',
  'bioMaterialPlateRow new');

# test getter/setter
$manufacturelimsbiomaterial->setBioMaterialPlateRow('2');
is($manufacturelimsbiomaterial->getBioMaterialPlateRow(), '2',
  'bioMaterialPlateRow getter/setter');

# test getter throws exception with argument
eval {$manufacturelimsbiomaterial->getBioMaterialPlateRow(1)};
ok($@, 'bioMaterialPlateRow getter throws exception with argument');

# test setter throws exception with no argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateRow()};
ok($@, 'bioMaterialPlateRow setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateRow('2', '2')};
ok($@, 'bioMaterialPlateRow setter throws exception with too many argument');

# test setter accepts undef
eval {$manufacturelimsbiomaterial->setBioMaterialPlateRow(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getBioMaterialPlateRow()),
   'bioMaterialPlateRow setter accepts undef');



#
# testing attribute bioMaterialPlateIdentifier
#

# test attribute values can be set in new()
is($manufacturelimsbiomaterial->getBioMaterialPlateIdentifier(), '3',
  'bioMaterialPlateIdentifier new');

# test getter/setter
$manufacturelimsbiomaterial->setBioMaterialPlateIdentifier('3');
is($manufacturelimsbiomaterial->getBioMaterialPlateIdentifier(), '3',
  'bioMaterialPlateIdentifier getter/setter');

# test getter throws exception with argument
eval {$manufacturelimsbiomaterial->getBioMaterialPlateIdentifier(1)};
ok($@, 'bioMaterialPlateIdentifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateIdentifier()};
ok($@, 'bioMaterialPlateIdentifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$manufacturelimsbiomaterial->setBioMaterialPlateIdentifier('3', '3')};
ok($@, 'bioMaterialPlateIdentifier setter throws exception with too many argument');

# test setter accepts undef
eval {$manufacturelimsbiomaterial->setBioMaterialPlateIdentifier(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getBioMaterialPlateIdentifier()),
   'bioMaterialPlateIdentifier setter accepts undef');



#
# testing attribute quality
#

# test attribute values can be set in new()
is($manufacturelimsbiomaterial->getQuality(), '4',
  'quality new');

# test getter/setter
$manufacturelimsbiomaterial->setQuality('4');
is($manufacturelimsbiomaterial->getQuality(), '4',
  'quality getter/setter');

# test getter throws exception with argument
eval {$manufacturelimsbiomaterial->getQuality(1)};
ok($@, 'quality getter throws exception with argument');

# test setter throws exception with no argument
eval {$manufacturelimsbiomaterial->setQuality()};
ok($@, 'quality setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$manufacturelimsbiomaterial->setQuality('4', '4')};
ok($@, 'quality setter throws exception with too many argument');

# test setter accepts undef
eval {$manufacturelimsbiomaterial->setQuality(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getQuality()),
   'quality setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ManufactureLIMSBiomaterial->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new(feature => Bio::MAGE::DesignElement::Feature->new(),
identifierLIMS => Bio::MAGE::Description::DatabaseEntry->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
bioMaterial => Bio::MAGE::BioMaterial::BioMaterial->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association feature
my $feature_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature_assn = Bio::MAGE::DesignElement::Feature->new();
}


isa_ok($manufacturelimsbiomaterial->getFeature, q[Bio::MAGE::DesignElement::Feature]);

is($manufacturelimsbiomaterial->setFeature($feature_assn), $feature_assn,
  'setFeature returns value');

ok($manufacturelimsbiomaterial->getFeature() == $feature_assn,
   'getFeature fetches correct value');

# test setFeature throws exception with bad argument
eval {$manufacturelimsbiomaterial->setFeature(1)};
ok($@, 'setFeature throws exception with bad argument');


# test getFeature throws exception with argument
eval {$manufacturelimsbiomaterial->getFeature(1)};
ok($@, 'getFeature throws exception with argument');

# test setFeature throws exception with no argument
eval {$manufacturelimsbiomaterial->setFeature()};
ok($@, 'setFeature throws exception with no argument');

# test setFeature throws exception with too many argument
eval {$manufacturelimsbiomaterial->setFeature(1,2)};
ok($@, 'setFeature throws exception with too many argument');

# test setFeature accepts undef
eval {$manufacturelimsbiomaterial->setFeature(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getFeature()),
   'setFeature accepts undef');

# test the meta-data for the assoication
$assn = $assns{feature};
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
   'feature->other() is a valid Bio::MAGE::Association::End'
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
   'feature->self() is a valid Bio::MAGE::Association::End'
  );



# testing association identifierLIMS
my $identifierlims_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $identifierlims_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


isa_ok($manufacturelimsbiomaterial->getIdentifierLIMS, q[Bio::MAGE::Description::DatabaseEntry]);

is($manufacturelimsbiomaterial->setIdentifierLIMS($identifierlims_assn), $identifierlims_assn,
  'setIdentifierLIMS returns value');

ok($manufacturelimsbiomaterial->getIdentifierLIMS() == $identifierlims_assn,
   'getIdentifierLIMS fetches correct value');

# test setIdentifierLIMS throws exception with bad argument
eval {$manufacturelimsbiomaterial->setIdentifierLIMS(1)};
ok($@, 'setIdentifierLIMS throws exception with bad argument');


# test getIdentifierLIMS throws exception with argument
eval {$manufacturelimsbiomaterial->getIdentifierLIMS(1)};
ok($@, 'getIdentifierLIMS throws exception with argument');

# test setIdentifierLIMS throws exception with no argument
eval {$manufacturelimsbiomaterial->setIdentifierLIMS()};
ok($@, 'setIdentifierLIMS throws exception with no argument');

# test setIdentifierLIMS throws exception with too many argument
eval {$manufacturelimsbiomaterial->setIdentifierLIMS(1,2)};
ok($@, 'setIdentifierLIMS throws exception with too many argument');

# test setIdentifierLIMS accepts undef
eval {$manufacturelimsbiomaterial->setIdentifierLIMS(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getIdentifierLIMS()),
   'setIdentifierLIMS accepts undef');

# test the meta-data for the assoication
$assn = $assns{identifierLIMS};
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
   'identifierLIMS->other() is a valid Bio::MAGE::Association::End'
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
   'identifierLIMS->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getDescriptions,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getDescriptions} == 1
 and UNIVERSAL::isa($manufacturelimsbiomaterial->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($manufacturelimsbiomaterial->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getDescriptions,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getDescriptions} == 1
 and $manufacturelimsbiomaterial->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($manufacturelimsbiomaterial->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getDescriptions,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getDescriptions} == 2
 and $manufacturelimsbiomaterial->getDescriptions->[0] == $descriptions_assn
 and $manufacturelimsbiomaterial->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$manufacturelimsbiomaterial->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$manufacturelimsbiomaterial->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$manufacturelimsbiomaterial->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$manufacturelimsbiomaterial->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$manufacturelimsbiomaterial->setDescriptions([])};
ok((!$@ and defined $manufacturelimsbiomaterial->getDescriptions()
    and UNIVERSAL::isa($manufacturelimsbiomaterial->getDescriptions, 'ARRAY')
    and scalar @{$manufacturelimsbiomaterial->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$manufacturelimsbiomaterial->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$manufacturelimsbiomaterial->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$manufacturelimsbiomaterial->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$manufacturelimsbiomaterial->setDescriptions(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getDescriptions()),
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



# testing association bioMaterial
my $biomaterial_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial_assn = Bio::MAGE::BioMaterial::BioMaterial->new();
}


isa_ok($manufacturelimsbiomaterial->getBioMaterial, q[Bio::MAGE::BioMaterial::BioMaterial]);

is($manufacturelimsbiomaterial->setBioMaterial($biomaterial_assn), $biomaterial_assn,
  'setBioMaterial returns value');

ok($manufacturelimsbiomaterial->getBioMaterial() == $biomaterial_assn,
   'getBioMaterial fetches correct value');

# test setBioMaterial throws exception with bad argument
eval {$manufacturelimsbiomaterial->setBioMaterial(1)};
ok($@, 'setBioMaterial throws exception with bad argument');


# test getBioMaterial throws exception with argument
eval {$manufacturelimsbiomaterial->getBioMaterial(1)};
ok($@, 'getBioMaterial throws exception with argument');

# test setBioMaterial throws exception with no argument
eval {$manufacturelimsbiomaterial->setBioMaterial()};
ok($@, 'setBioMaterial throws exception with no argument');

# test setBioMaterial throws exception with too many argument
eval {$manufacturelimsbiomaterial->setBioMaterial(1,2)};
ok($@, 'setBioMaterial throws exception with too many argument');

# test setBioMaterial accepts undef
eval {$manufacturelimsbiomaterial->setBioMaterial(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getBioMaterial()),
   'setBioMaterial accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioMaterial};
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
   'bioMaterial->other() is a valid Bio::MAGE::Association::End'
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
   'bioMaterial->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($manufacturelimsbiomaterial->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($manufacturelimsbiomaterial->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($manufacturelimsbiomaterial->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$manufacturelimsbiomaterial->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$manufacturelimsbiomaterial->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$manufacturelimsbiomaterial->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$manufacturelimsbiomaterial->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$manufacturelimsbiomaterial->setSecurity(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getSecurity()),
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


ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getAuditTrail} == 1
 and UNIVERSAL::isa($manufacturelimsbiomaterial->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($manufacturelimsbiomaterial->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getAuditTrail} == 1
 and $manufacturelimsbiomaterial->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($manufacturelimsbiomaterial->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getAuditTrail} == 2
 and $manufacturelimsbiomaterial->getAuditTrail->[0] == $audittrail_assn
 and $manufacturelimsbiomaterial->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$manufacturelimsbiomaterial->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$manufacturelimsbiomaterial->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$manufacturelimsbiomaterial->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$manufacturelimsbiomaterial->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$manufacturelimsbiomaterial->setAuditTrail([])};
ok((!$@ and defined $manufacturelimsbiomaterial->getAuditTrail()
    and UNIVERSAL::isa($manufacturelimsbiomaterial->getAuditTrail, 'ARRAY')
    and scalar @{$manufacturelimsbiomaterial->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$manufacturelimsbiomaterial->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$manufacturelimsbiomaterial->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$manufacturelimsbiomaterial->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$manufacturelimsbiomaterial->setAuditTrail(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getAuditTrail()),
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


ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getPropertySets,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getPropertySets} == 1
 and UNIVERSAL::isa($manufacturelimsbiomaterial->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($manufacturelimsbiomaterial->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getPropertySets,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getPropertySets} == 1
 and $manufacturelimsbiomaterial->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($manufacturelimsbiomaterial->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($manufacturelimsbiomaterial->getPropertySets,'ARRAY')
 and scalar @{$manufacturelimsbiomaterial->getPropertySets} == 2
 and $manufacturelimsbiomaterial->getPropertySets->[0] == $propertysets_assn
 and $manufacturelimsbiomaterial->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$manufacturelimsbiomaterial->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$manufacturelimsbiomaterial->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$manufacturelimsbiomaterial->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$manufacturelimsbiomaterial->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$manufacturelimsbiomaterial->setPropertySets([])};
ok((!$@ and defined $manufacturelimsbiomaterial->getPropertySets()
    and UNIVERSAL::isa($manufacturelimsbiomaterial->getPropertySets, 'ARRAY')
    and scalar @{$manufacturelimsbiomaterial->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$manufacturelimsbiomaterial->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$manufacturelimsbiomaterial->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$manufacturelimsbiomaterial->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$manufacturelimsbiomaterial->setPropertySets(undef)};
ok((!$@ and not defined $manufacturelimsbiomaterial->getPropertySets()),
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





my $manufacturelims;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $manufacturelims = Bio::MAGE::Array::ManufactureLIMS->new();
}

# testing superclass ManufactureLIMS
isa_ok($manufacturelims, q[Bio::MAGE::Array::ManufactureLIMS]);
isa_ok($manufacturelimsbiomaterial, q[Bio::MAGE::Array::ManufactureLIMS]);

