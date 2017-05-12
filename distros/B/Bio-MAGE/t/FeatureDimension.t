##############################
#
# FeatureDimension.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureDimension.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::FeatureDimension') };

use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;


# we test the new() method
my $featuredimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredimension = Bio::MAGE::BioAssayData::FeatureDimension->new();
}
isa_ok($featuredimension, 'Bio::MAGE::BioAssayData::FeatureDimension');

# test the package_name class method
is($featuredimension->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($featuredimension->class_name(), q[Bio::MAGE::BioAssayData::FeatureDimension],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredimension = Bio::MAGE::BioAssayData::FeatureDimension->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($featuredimension->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$featuredimension->setIdentifier('1');
is($featuredimension->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$featuredimension->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuredimension->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuredimension->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$featuredimension->setIdentifier(undef)};
ok((!$@ and not defined $featuredimension->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($featuredimension->getName(), '2',
  'name new');

# test getter/setter
$featuredimension->setName('2');
is($featuredimension->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$featuredimension->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$featuredimension->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$featuredimension->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$featuredimension->setName(undef)};
ok((!$@ and not defined $featuredimension->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::FeatureDimension->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featuredimension = Bio::MAGE::BioAssayData::FeatureDimension->new(descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
containedFeatures => [Bio::MAGE::DesignElement::Feature->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($featuredimension->getDescriptions,'ARRAY')
 and scalar @{$featuredimension->getDescriptions} == 1
 and UNIVERSAL::isa($featuredimension->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($featuredimension->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($featuredimension->getDescriptions,'ARRAY')
 and scalar @{$featuredimension->getDescriptions} == 1
 and $featuredimension->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($featuredimension->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($featuredimension->getDescriptions,'ARRAY')
 and scalar @{$featuredimension->getDescriptions} == 2
 and $featuredimension->getDescriptions->[0] == $descriptions_assn
 and $featuredimension->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$featuredimension->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$featuredimension->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$featuredimension->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$featuredimension->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$featuredimension->setDescriptions([])};
ok((!$@ and defined $featuredimension->getDescriptions()
    and UNIVERSAL::isa($featuredimension->getDescriptions, 'ARRAY')
    and scalar @{$featuredimension->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$featuredimension->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$featuredimension->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$featuredimension->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$featuredimension->setDescriptions(undef)};
ok((!$@ and not defined $featuredimension->getDescriptions()),
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


ok((UNIVERSAL::isa($featuredimension->getAuditTrail,'ARRAY')
 and scalar @{$featuredimension->getAuditTrail} == 1
 and UNIVERSAL::isa($featuredimension->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($featuredimension->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($featuredimension->getAuditTrail,'ARRAY')
 and scalar @{$featuredimension->getAuditTrail} == 1
 and $featuredimension->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($featuredimension->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($featuredimension->getAuditTrail,'ARRAY')
 and scalar @{$featuredimension->getAuditTrail} == 2
 and $featuredimension->getAuditTrail->[0] == $audittrail_assn
 and $featuredimension->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$featuredimension->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$featuredimension->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$featuredimension->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$featuredimension->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$featuredimension->setAuditTrail([])};
ok((!$@ and defined $featuredimension->getAuditTrail()
    and UNIVERSAL::isa($featuredimension->getAuditTrail, 'ARRAY')
    and scalar @{$featuredimension->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$featuredimension->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$featuredimension->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$featuredimension->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$featuredimension->setAuditTrail(undef)};
ok((!$@ and not defined $featuredimension->getAuditTrail()),
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


isa_ok($featuredimension->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($featuredimension->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($featuredimension->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$featuredimension->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$featuredimension->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$featuredimension->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$featuredimension->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$featuredimension->setSecurity(undef)};
ok((!$@ and not defined $featuredimension->getSecurity()),
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


ok((UNIVERSAL::isa($featuredimension->getPropertySets,'ARRAY')
 and scalar @{$featuredimension->getPropertySets} == 1
 and UNIVERSAL::isa($featuredimension->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featuredimension->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featuredimension->getPropertySets,'ARRAY')
 and scalar @{$featuredimension->getPropertySets} == 1
 and $featuredimension->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featuredimension->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featuredimension->getPropertySets,'ARRAY')
 and scalar @{$featuredimension->getPropertySets} == 2
 and $featuredimension->getPropertySets->[0] == $propertysets_assn
 and $featuredimension->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featuredimension->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featuredimension->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featuredimension->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featuredimension->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featuredimension->setPropertySets([])};
ok((!$@ and defined $featuredimension->getPropertySets()
    and UNIVERSAL::isa($featuredimension->getPropertySets, 'ARRAY')
    and scalar @{$featuredimension->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featuredimension->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featuredimension->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featuredimension->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featuredimension->setPropertySets(undef)};
ok((!$@ and not defined $featuredimension->getPropertySets()),
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



# testing association containedFeatures
my $containedfeatures_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $containedfeatures_assn = Bio::MAGE::DesignElement::Feature->new();
}


ok((UNIVERSAL::isa($featuredimension->getContainedFeatures,'ARRAY')
 and scalar @{$featuredimension->getContainedFeatures} == 1
 and UNIVERSAL::isa($featuredimension->getContainedFeatures->[0], q[Bio::MAGE::DesignElement::Feature])),
  'containedFeatures set in new()');

ok(eq_array($featuredimension->setContainedFeatures([$containedfeatures_assn]), [$containedfeatures_assn]),
   'setContainedFeatures returns correct value');

ok((UNIVERSAL::isa($featuredimension->getContainedFeatures,'ARRAY')
 and scalar @{$featuredimension->getContainedFeatures} == 1
 and $featuredimension->getContainedFeatures->[0] == $containedfeatures_assn),
   'getContainedFeatures fetches correct value');

is($featuredimension->addContainedFeatures($containedfeatures_assn), 2,
  'addContainedFeatures returns number of items in list');

ok((UNIVERSAL::isa($featuredimension->getContainedFeatures,'ARRAY')
 and scalar @{$featuredimension->getContainedFeatures} == 2
 and $featuredimension->getContainedFeatures->[0] == $containedfeatures_assn
 and $featuredimension->getContainedFeatures->[1] == $containedfeatures_assn),
  'addContainedFeatures adds correct value');

# test setContainedFeatures throws exception with non-array argument
eval {$featuredimension->setContainedFeatures(1)};
ok($@, 'setContainedFeatures throws exception with non-array argument');

# test setContainedFeatures throws exception with bad argument array
eval {$featuredimension->setContainedFeatures([1])};
ok($@, 'setContainedFeatures throws exception with bad argument array');

# test addContainedFeatures throws exception with no arguments
eval {$featuredimension->addContainedFeatures()};
ok($@, 'addContainedFeatures throws exception with no arguments');

# test addContainedFeatures throws exception with bad argument
eval {$featuredimension->addContainedFeatures(1)};
ok($@, 'addContainedFeatures throws exception with bad array');

# test setContainedFeatures accepts empty array ref
eval {$featuredimension->setContainedFeatures([])};
ok((!$@ and defined $featuredimension->getContainedFeatures()
    and UNIVERSAL::isa($featuredimension->getContainedFeatures, 'ARRAY')
    and scalar @{$featuredimension->getContainedFeatures} == 0),
   'setContainedFeatures accepts empty array ref');


# test getContainedFeatures throws exception with argument
eval {$featuredimension->getContainedFeatures(1)};
ok($@, 'getContainedFeatures throws exception with argument');

# test setContainedFeatures throws exception with no argument
eval {$featuredimension->setContainedFeatures()};
ok($@, 'setContainedFeatures throws exception with no argument');

# test setContainedFeatures throws exception with too many argument
eval {$featuredimension->setContainedFeatures(1,2)};
ok($@, 'setContainedFeatures throws exception with too many argument');

# test setContainedFeatures accepts undef
eval {$featuredimension->setContainedFeatures(undef)};
ok((!$@ and not defined $featuredimension->getContainedFeatures()),
   'setContainedFeatures accepts undef');

# test the meta-data for the assoication
$assn = $assns{containedFeatures};
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
   'containedFeatures->other() is a valid Bio::MAGE::Association::End'
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
   'containedFeatures->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($featuredimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

