##############################
#
# NodeContents.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NodeContents.t`

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
use Test::More tests => 115;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::HigherLevelAnalysis::NodeContents') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::BioAssayDimension;


# we test the new() method
my $nodecontents;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodecontents = Bio::MAGE::HigherLevelAnalysis::NodeContents->new();
}
isa_ok($nodecontents, 'Bio::MAGE::HigherLevelAnalysis::NodeContents');

# test the package_name class method
is($nodecontents->package_name(), q[HigherLevelAnalysis],
  'package');

# test the class_name class method
is($nodecontents->class_name(), q[Bio::MAGE::HigherLevelAnalysis::NodeContents],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodecontents = Bio::MAGE::HigherLevelAnalysis::NodeContents->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::HigherLevelAnalysis::NodeContents->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodecontents = Bio::MAGE::HigherLevelAnalysis::NodeContents->new(designElementDimension => Bio::MAGE::BioAssayData::DesignElementDimension->new(),
bioAssayDimension => Bio::MAGE::BioAssayData::BioAssayDimension->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
quantitationDimension => Bio::MAGE::BioAssayData::QuantitationTypeDimension->new());
}

my ($end, $assn);


# testing association designElementDimension
my $designelementdimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelementdimension_assn = Bio::MAGE::BioAssayData::DesignElementDimension->new();
}


isa_ok($nodecontents->getDesignElementDimension, q[Bio::MAGE::BioAssayData::DesignElementDimension]);

is($nodecontents->setDesignElementDimension($designelementdimension_assn), $designelementdimension_assn,
  'setDesignElementDimension returns value');

ok($nodecontents->getDesignElementDimension() == $designelementdimension_assn,
   'getDesignElementDimension fetches correct value');

# test setDesignElementDimension throws exception with bad argument
eval {$nodecontents->setDesignElementDimension(1)};
ok($@, 'setDesignElementDimension throws exception with bad argument');


# test getDesignElementDimension throws exception with argument
eval {$nodecontents->getDesignElementDimension(1)};
ok($@, 'getDesignElementDimension throws exception with argument');

# test setDesignElementDimension throws exception with no argument
eval {$nodecontents->setDesignElementDimension()};
ok($@, 'setDesignElementDimension throws exception with no argument');

# test setDesignElementDimension throws exception with too many argument
eval {$nodecontents->setDesignElementDimension(1,2)};
ok($@, 'setDesignElementDimension throws exception with too many argument');

# test setDesignElementDimension accepts undef
eval {$nodecontents->setDesignElementDimension(undef)};
ok((!$@ and not defined $nodecontents->getDesignElementDimension()),
   'setDesignElementDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{designElementDimension};
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
   'designElementDimension->other() is a valid Bio::MAGE::Association::End'
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
   'designElementDimension->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssayDimension
my $bioassaydimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension_assn = Bio::MAGE::BioAssayData::BioAssayDimension->new();
}


isa_ok($nodecontents->getBioAssayDimension, q[Bio::MAGE::BioAssayData::BioAssayDimension]);

is($nodecontents->setBioAssayDimension($bioassaydimension_assn), $bioassaydimension_assn,
  'setBioAssayDimension returns value');

ok($nodecontents->getBioAssayDimension() == $bioassaydimension_assn,
   'getBioAssayDimension fetches correct value');

# test setBioAssayDimension throws exception with bad argument
eval {$nodecontents->setBioAssayDimension(1)};
ok($@, 'setBioAssayDimension throws exception with bad argument');


# test getBioAssayDimension throws exception with argument
eval {$nodecontents->getBioAssayDimension(1)};
ok($@, 'getBioAssayDimension throws exception with argument');

# test setBioAssayDimension throws exception with no argument
eval {$nodecontents->setBioAssayDimension()};
ok($@, 'setBioAssayDimension throws exception with no argument');

# test setBioAssayDimension throws exception with too many argument
eval {$nodecontents->setBioAssayDimension(1,2)};
ok($@, 'setBioAssayDimension throws exception with too many argument');

# test setBioAssayDimension accepts undef
eval {$nodecontents->setBioAssayDimension(undef)};
ok((!$@ and not defined $nodecontents->getBioAssayDimension()),
   'setBioAssayDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayDimension};
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
   'bioAssayDimension->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayDimension->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($nodecontents->getDescriptions,'ARRAY')
 and scalar @{$nodecontents->getDescriptions} == 1
 and UNIVERSAL::isa($nodecontents->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($nodecontents->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($nodecontents->getDescriptions,'ARRAY')
 and scalar @{$nodecontents->getDescriptions} == 1
 and $nodecontents->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($nodecontents->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($nodecontents->getDescriptions,'ARRAY')
 and scalar @{$nodecontents->getDescriptions} == 2
 and $nodecontents->getDescriptions->[0] == $descriptions_assn
 and $nodecontents->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$nodecontents->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$nodecontents->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$nodecontents->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$nodecontents->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$nodecontents->setDescriptions([])};
ok((!$@ and defined $nodecontents->getDescriptions()
    and UNIVERSAL::isa($nodecontents->getDescriptions, 'ARRAY')
    and scalar @{$nodecontents->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$nodecontents->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$nodecontents->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$nodecontents->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$nodecontents->setDescriptions(undef)};
ok((!$@ and not defined $nodecontents->getDescriptions()),
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


ok((UNIVERSAL::isa($nodecontents->getAuditTrail,'ARRAY')
 and scalar @{$nodecontents->getAuditTrail} == 1
 and UNIVERSAL::isa($nodecontents->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($nodecontents->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($nodecontents->getAuditTrail,'ARRAY')
 and scalar @{$nodecontents->getAuditTrail} == 1
 and $nodecontents->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($nodecontents->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($nodecontents->getAuditTrail,'ARRAY')
 and scalar @{$nodecontents->getAuditTrail} == 2
 and $nodecontents->getAuditTrail->[0] == $audittrail_assn
 and $nodecontents->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$nodecontents->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$nodecontents->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$nodecontents->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$nodecontents->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$nodecontents->setAuditTrail([])};
ok((!$@ and defined $nodecontents->getAuditTrail()
    and UNIVERSAL::isa($nodecontents->getAuditTrail, 'ARRAY')
    and scalar @{$nodecontents->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$nodecontents->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$nodecontents->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$nodecontents->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$nodecontents->setAuditTrail(undef)};
ok((!$@ and not defined $nodecontents->getAuditTrail()),
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


isa_ok($nodecontents->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($nodecontents->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($nodecontents->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$nodecontents->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$nodecontents->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$nodecontents->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$nodecontents->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$nodecontents->setSecurity(undef)};
ok((!$@ and not defined $nodecontents->getSecurity()),
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


ok((UNIVERSAL::isa($nodecontents->getPropertySets,'ARRAY')
 and scalar @{$nodecontents->getPropertySets} == 1
 and UNIVERSAL::isa($nodecontents->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($nodecontents->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($nodecontents->getPropertySets,'ARRAY')
 and scalar @{$nodecontents->getPropertySets} == 1
 and $nodecontents->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($nodecontents->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($nodecontents->getPropertySets,'ARRAY')
 and scalar @{$nodecontents->getPropertySets} == 2
 and $nodecontents->getPropertySets->[0] == $propertysets_assn
 and $nodecontents->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$nodecontents->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$nodecontents->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$nodecontents->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$nodecontents->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$nodecontents->setPropertySets([])};
ok((!$@ and defined $nodecontents->getPropertySets()
    and UNIVERSAL::isa($nodecontents->getPropertySets, 'ARRAY')
    and scalar @{$nodecontents->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$nodecontents->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$nodecontents->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$nodecontents->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$nodecontents->setPropertySets(undef)};
ok((!$@ and not defined $nodecontents->getPropertySets()),
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



# testing association quantitationDimension
my $quantitationdimension_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationdimension_assn = Bio::MAGE::BioAssayData::QuantitationTypeDimension->new();
}


isa_ok($nodecontents->getQuantitationDimension, q[Bio::MAGE::BioAssayData::QuantitationTypeDimension]);

is($nodecontents->setQuantitationDimension($quantitationdimension_assn), $quantitationdimension_assn,
  'setQuantitationDimension returns value');

ok($nodecontents->getQuantitationDimension() == $quantitationdimension_assn,
   'getQuantitationDimension fetches correct value');

# test setQuantitationDimension throws exception with bad argument
eval {$nodecontents->setQuantitationDimension(1)};
ok($@, 'setQuantitationDimension throws exception with bad argument');


# test getQuantitationDimension throws exception with argument
eval {$nodecontents->getQuantitationDimension(1)};
ok($@, 'getQuantitationDimension throws exception with argument');

# test setQuantitationDimension throws exception with no argument
eval {$nodecontents->setQuantitationDimension()};
ok($@, 'setQuantitationDimension throws exception with no argument');

# test setQuantitationDimension throws exception with too many argument
eval {$nodecontents->setQuantitationDimension(1,2)};
ok($@, 'setQuantitationDimension throws exception with too many argument');

# test setQuantitationDimension accepts undef
eval {$nodecontents->setQuantitationDimension(undef)};
ok((!$@ and not defined $nodecontents->getQuantitationDimension()),
   'setQuantitationDimension accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationDimension};
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
   'quantitationDimension->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationDimension->self() is a valid Bio::MAGE::Association::End'
  );





my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($nodecontents, q[Bio::MAGE::Describable]);

