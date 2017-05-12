##############################
#
# ManufactureLIMS.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ManufactureLIMS.t`

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
use Test::More tests => 123;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Array::ManufactureLIMS') };

use Bio::MAGE::BioMaterial::BioMaterial;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::DatabaseEntry;

use Bio::MAGE::Array::ManufactureLIMSBiomaterial;

# we test the new() method
my $manufacturelims;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelims = Bio::MAGE::Array::ManufactureLIMS->new();
}
isa_ok($manufacturelims, 'Bio::MAGE::Array::ManufactureLIMS');

# test the package_name class method
is($manufacturelims->package_name(), q[Array],
  'package');

# test the class_name class method
is($manufacturelims->class_name(), q[Bio::MAGE::Array::ManufactureLIMS],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelims = Bio::MAGE::Array::ManufactureLIMS->new(quality => '1');
}


#
# testing attribute quality
#

# test attribute values can be set in new()
is($manufacturelims->getQuality(), '1',
  'quality new');

# test getter/setter
$manufacturelims->setQuality('1');
is($manufacturelims->getQuality(), '1',
  'quality getter/setter');

# test getter throws exception with argument
eval {$manufacturelims->getQuality(1)};
ok($@, 'quality getter throws exception with argument');

# test setter throws exception with no argument
eval {$manufacturelims->setQuality()};
ok($@, 'quality setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$manufacturelims->setQuality('1', '1')};
ok($@, 'quality setter throws exception with too many argument');

# test setter accepts undef
eval {$manufacturelims->setQuality(undef)};
ok((!$@ and not defined $manufacturelims->getQuality()),
   'quality setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Array::ManufactureLIMS->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $manufacturelims = Bio::MAGE::Array::ManufactureLIMS->new(feature => Bio::MAGE::DesignElement::Feature->new(),
identifierLIMS => Bio::MAGE::Description::DatabaseEntry->new(),
bioMaterial => Bio::MAGE::BioMaterial::BioMaterial->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
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


isa_ok($manufacturelims->getFeature, q[Bio::MAGE::DesignElement::Feature]);

is($manufacturelims->setFeature($feature_assn), $feature_assn,
  'setFeature returns value');

ok($manufacturelims->getFeature() == $feature_assn,
   'getFeature fetches correct value');

# test setFeature throws exception with bad argument
eval {$manufacturelims->setFeature(1)};
ok($@, 'setFeature throws exception with bad argument');


# test getFeature throws exception with argument
eval {$manufacturelims->getFeature(1)};
ok($@, 'getFeature throws exception with argument');

# test setFeature throws exception with no argument
eval {$manufacturelims->setFeature()};
ok($@, 'setFeature throws exception with no argument');

# test setFeature throws exception with too many argument
eval {$manufacturelims->setFeature(1,2)};
ok($@, 'setFeature throws exception with too many argument');

# test setFeature accepts undef
eval {$manufacturelims->setFeature(undef)};
ok((!$@ and not defined $manufacturelims->getFeature()),
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


isa_ok($manufacturelims->getIdentifierLIMS, q[Bio::MAGE::Description::DatabaseEntry]);

is($manufacturelims->setIdentifierLIMS($identifierlims_assn), $identifierlims_assn,
  'setIdentifierLIMS returns value');

ok($manufacturelims->getIdentifierLIMS() == $identifierlims_assn,
   'getIdentifierLIMS fetches correct value');

# test setIdentifierLIMS throws exception with bad argument
eval {$manufacturelims->setIdentifierLIMS(1)};
ok($@, 'setIdentifierLIMS throws exception with bad argument');


# test getIdentifierLIMS throws exception with argument
eval {$manufacturelims->getIdentifierLIMS(1)};
ok($@, 'getIdentifierLIMS throws exception with argument');

# test setIdentifierLIMS throws exception with no argument
eval {$manufacturelims->setIdentifierLIMS()};
ok($@, 'setIdentifierLIMS throws exception with no argument');

# test setIdentifierLIMS throws exception with too many argument
eval {$manufacturelims->setIdentifierLIMS(1,2)};
ok($@, 'setIdentifierLIMS throws exception with too many argument');

# test setIdentifierLIMS accepts undef
eval {$manufacturelims->setIdentifierLIMS(undef)};
ok((!$@ and not defined $manufacturelims->getIdentifierLIMS()),
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



# testing association bioMaterial
my $biomaterial_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $biomaterial_assn = Bio::MAGE::BioMaterial::BioMaterial->new();
}


isa_ok($manufacturelims->getBioMaterial, q[Bio::MAGE::BioMaterial::BioMaterial]);

is($manufacturelims->setBioMaterial($biomaterial_assn), $biomaterial_assn,
  'setBioMaterial returns value');

ok($manufacturelims->getBioMaterial() == $biomaterial_assn,
   'getBioMaterial fetches correct value');

# test setBioMaterial throws exception with bad argument
eval {$manufacturelims->setBioMaterial(1)};
ok($@, 'setBioMaterial throws exception with bad argument');


# test getBioMaterial throws exception with argument
eval {$manufacturelims->getBioMaterial(1)};
ok($@, 'getBioMaterial throws exception with argument');

# test setBioMaterial throws exception with no argument
eval {$manufacturelims->setBioMaterial()};
ok($@, 'setBioMaterial throws exception with no argument');

# test setBioMaterial throws exception with too many argument
eval {$manufacturelims->setBioMaterial(1,2)};
ok($@, 'setBioMaterial throws exception with too many argument');

# test setBioMaterial accepts undef
eval {$manufacturelims->setBioMaterial(undef)};
ok((!$@ and not defined $manufacturelims->getBioMaterial()),
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



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($manufacturelims->getDescriptions,'ARRAY')
 and scalar @{$manufacturelims->getDescriptions} == 1
 and UNIVERSAL::isa($manufacturelims->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($manufacturelims->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($manufacturelims->getDescriptions,'ARRAY')
 and scalar @{$manufacturelims->getDescriptions} == 1
 and $manufacturelims->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($manufacturelims->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($manufacturelims->getDescriptions,'ARRAY')
 and scalar @{$manufacturelims->getDescriptions} == 2
 and $manufacturelims->getDescriptions->[0] == $descriptions_assn
 and $manufacturelims->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$manufacturelims->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$manufacturelims->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$manufacturelims->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$manufacturelims->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$manufacturelims->setDescriptions([])};
ok((!$@ and defined $manufacturelims->getDescriptions()
    and UNIVERSAL::isa($manufacturelims->getDescriptions, 'ARRAY')
    and scalar @{$manufacturelims->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$manufacturelims->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$manufacturelims->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$manufacturelims->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$manufacturelims->setDescriptions(undef)};
ok((!$@ and not defined $manufacturelims->getDescriptions()),
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


ok((UNIVERSAL::isa($manufacturelims->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelims->getAuditTrail} == 1
 and UNIVERSAL::isa($manufacturelims->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($manufacturelims->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($manufacturelims->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelims->getAuditTrail} == 1
 and $manufacturelims->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($manufacturelims->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($manufacturelims->getAuditTrail,'ARRAY')
 and scalar @{$manufacturelims->getAuditTrail} == 2
 and $manufacturelims->getAuditTrail->[0] == $audittrail_assn
 and $manufacturelims->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$manufacturelims->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$manufacturelims->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$manufacturelims->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$manufacturelims->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$manufacturelims->setAuditTrail([])};
ok((!$@ and defined $manufacturelims->getAuditTrail()
    and UNIVERSAL::isa($manufacturelims->getAuditTrail, 'ARRAY')
    and scalar @{$manufacturelims->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$manufacturelims->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$manufacturelims->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$manufacturelims->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$manufacturelims->setAuditTrail(undef)};
ok((!$@ and not defined $manufacturelims->getAuditTrail()),
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


isa_ok($manufacturelims->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($manufacturelims->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($manufacturelims->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$manufacturelims->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$manufacturelims->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$manufacturelims->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$manufacturelims->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$manufacturelims->setSecurity(undef)};
ok((!$@ and not defined $manufacturelims->getSecurity()),
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


ok((UNIVERSAL::isa($manufacturelims->getPropertySets,'ARRAY')
 and scalar @{$manufacturelims->getPropertySets} == 1
 and UNIVERSAL::isa($manufacturelims->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($manufacturelims->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($manufacturelims->getPropertySets,'ARRAY')
 and scalar @{$manufacturelims->getPropertySets} == 1
 and $manufacturelims->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($manufacturelims->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($manufacturelims->getPropertySets,'ARRAY')
 and scalar @{$manufacturelims->getPropertySets} == 2
 and $manufacturelims->getPropertySets->[0] == $propertysets_assn
 and $manufacturelims->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$manufacturelims->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$manufacturelims->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$manufacturelims->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$manufacturelims->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$manufacturelims->setPropertySets([])};
ok((!$@ and defined $manufacturelims->getPropertySets()
    and UNIVERSAL::isa($manufacturelims->getPropertySets, 'ARRAY')
    and scalar @{$manufacturelims->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$manufacturelims->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$manufacturelims->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$manufacturelims->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$manufacturelims->setPropertySets(undef)};
ok((!$@ and not defined $manufacturelims->getPropertySets()),
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




# create a subclass
my $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new();

# testing subclass ManufactureLIMSBiomaterial
isa_ok($manufacturelimsbiomaterial, q[Bio::MAGE::Array::ManufactureLIMSBiomaterial]);
isa_ok($manufacturelimsbiomaterial, q[Bio::MAGE::Array::ManufactureLIMS]);



my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($manufacturelims, q[Bio::MAGE::Describable]);

