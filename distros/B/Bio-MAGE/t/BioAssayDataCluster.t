##############################
#
# BioAssayDataCluster.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayDataCluster.t`

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
use Test::More tests => 120;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::HigherLevelAnalysis::Node;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::BioAssayData::BioAssayData;
use Bio::MAGE::Description::Description;


# we test the new() method
my $bioassaydatacluster;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatacluster = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new();
}
isa_ok($bioassaydatacluster, 'Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster');

# test the package_name class method
is($bioassaydatacluster->package_name(), q[HigherLevelAnalysis],
  'package');

# test the class_name class method
is($bioassaydatacluster->class_name(), q[Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatacluster = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaydatacluster->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaydatacluster->setIdentifier('1');
is($bioassaydatacluster->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaydatacluster->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydatacluster->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydatacluster->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydatacluster->setIdentifier(undef)};
ok((!$@ and not defined $bioassaydatacluster->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaydatacluster->getName(), '2',
  'name new');

# test getter/setter
$bioassaydatacluster->setName('2');
is($bioassaydatacluster->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaydatacluster->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydatacluster->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydatacluster->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydatacluster->setName(undef)};
ok((!$@ and not defined $bioassaydatacluster->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatacluster = Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster->new(descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
nodes => [Bio::MAGE::HigherLevelAnalysis::Node->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
clusterBioAssayData => Bio::MAGE::BioAssayData::BioAssayData->new());
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bioassaydatacluster->getDescriptions,'ARRAY')
 and scalar @{$bioassaydatacluster->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaydatacluster->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaydatacluster->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaydatacluster->getDescriptions,'ARRAY')
 and scalar @{$bioassaydatacluster->getDescriptions} == 1
 and $bioassaydatacluster->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaydatacluster->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaydatacluster->getDescriptions,'ARRAY')
 and scalar @{$bioassaydatacluster->getDescriptions} == 2
 and $bioassaydatacluster->getDescriptions->[0] == $descriptions_assn
 and $bioassaydatacluster->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaydatacluster->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaydatacluster->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaydatacluster->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaydatacluster->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaydatacluster->setDescriptions([])};
ok((!$@ and defined $bioassaydatacluster->getDescriptions()
    and UNIVERSAL::isa($bioassaydatacluster->getDescriptions, 'ARRAY')
    and scalar @{$bioassaydatacluster->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaydatacluster->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaydatacluster->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaydatacluster->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaydatacluster->setDescriptions(undef)};
ok((!$@ and not defined $bioassaydatacluster->getDescriptions()),
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


isa_ok($bioassaydatacluster->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaydatacluster->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaydatacluster->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaydatacluster->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaydatacluster->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaydatacluster->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaydatacluster->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaydatacluster->setSecurity(undef)};
ok((!$@ and not defined $bioassaydatacluster->getSecurity()),
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


ok((UNIVERSAL::isa($bioassaydatacluster->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydatacluster->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaydatacluster->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaydatacluster->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaydatacluster->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydatacluster->getAuditTrail} == 1
 and $bioassaydatacluster->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaydatacluster->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaydatacluster->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydatacluster->getAuditTrail} == 2
 and $bioassaydatacluster->getAuditTrail->[0] == $audittrail_assn
 and $bioassaydatacluster->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaydatacluster->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaydatacluster->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaydatacluster->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaydatacluster->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaydatacluster->setAuditTrail([])};
ok((!$@ and defined $bioassaydatacluster->getAuditTrail()
    and UNIVERSAL::isa($bioassaydatacluster->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaydatacluster->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaydatacluster->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaydatacluster->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaydatacluster->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaydatacluster->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaydatacluster->getAuditTrail()),
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



# testing association nodes
my $nodes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodes_assn = Bio::MAGE::HigherLevelAnalysis::Node->new();
}


ok((UNIVERSAL::isa($bioassaydatacluster->getNodes,'ARRAY')
 and scalar @{$bioassaydatacluster->getNodes} == 1
 and UNIVERSAL::isa($bioassaydatacluster->getNodes->[0], q[Bio::MAGE::HigherLevelAnalysis::Node])),
  'nodes set in new()');

ok(eq_array($bioassaydatacluster->setNodes([$nodes_assn]), [$nodes_assn]),
   'setNodes returns correct value');

ok((UNIVERSAL::isa($bioassaydatacluster->getNodes,'ARRAY')
 and scalar @{$bioassaydatacluster->getNodes} == 1
 and $bioassaydatacluster->getNodes->[0] == $nodes_assn),
   'getNodes fetches correct value');

is($bioassaydatacluster->addNodes($nodes_assn), 2,
  'addNodes returns number of items in list');

ok((UNIVERSAL::isa($bioassaydatacluster->getNodes,'ARRAY')
 and scalar @{$bioassaydatacluster->getNodes} == 2
 and $bioassaydatacluster->getNodes->[0] == $nodes_assn
 and $bioassaydatacluster->getNodes->[1] == $nodes_assn),
  'addNodes adds correct value');

# test setNodes throws exception with non-array argument
eval {$bioassaydatacluster->setNodes(1)};
ok($@, 'setNodes throws exception with non-array argument');

# test setNodes throws exception with bad argument array
eval {$bioassaydatacluster->setNodes([1])};
ok($@, 'setNodes throws exception with bad argument array');

# test addNodes throws exception with no arguments
eval {$bioassaydatacluster->addNodes()};
ok($@, 'addNodes throws exception with no arguments');

# test addNodes throws exception with bad argument
eval {$bioassaydatacluster->addNodes(1)};
ok($@, 'addNodes throws exception with bad array');

# test setNodes accepts empty array ref
eval {$bioassaydatacluster->setNodes([])};
ok((!$@ and defined $bioassaydatacluster->getNodes()
    and UNIVERSAL::isa($bioassaydatacluster->getNodes, 'ARRAY')
    and scalar @{$bioassaydatacluster->getNodes} == 0),
   'setNodes accepts empty array ref');


# test getNodes throws exception with argument
eval {$bioassaydatacluster->getNodes(1)};
ok($@, 'getNodes throws exception with argument');

# test setNodes throws exception with no argument
eval {$bioassaydatacluster->setNodes()};
ok($@, 'setNodes throws exception with no argument');

# test setNodes throws exception with too many argument
eval {$bioassaydatacluster->setNodes(1,2)};
ok($@, 'setNodes throws exception with too many argument');

# test setNodes accepts undef
eval {$bioassaydatacluster->setNodes(undef)};
ok((!$@ and not defined $bioassaydatacluster->getNodes()),
   'setNodes accepts undef');

# test the meta-data for the assoication
$assn = $assns{nodes};
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
   'nodes->other() is a valid Bio::MAGE::Association::End'
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
   'nodes->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($bioassaydatacluster->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatacluster->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaydatacluster->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaydatacluster->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaydatacluster->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatacluster->getPropertySets} == 1
 and $bioassaydatacluster->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaydatacluster->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaydatacluster->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatacluster->getPropertySets} == 2
 and $bioassaydatacluster->getPropertySets->[0] == $propertysets_assn
 and $bioassaydatacluster->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaydatacluster->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaydatacluster->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaydatacluster->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaydatacluster->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaydatacluster->setPropertySets([])};
ok((!$@ and defined $bioassaydatacluster->getPropertySets()
    and UNIVERSAL::isa($bioassaydatacluster->getPropertySets, 'ARRAY')
    and scalar @{$bioassaydatacluster->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaydatacluster->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaydatacluster->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaydatacluster->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaydatacluster->setPropertySets(undef)};
ok((!$@ and not defined $bioassaydatacluster->getPropertySets()),
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



# testing association clusterBioAssayData
my $clusterbioassaydata_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $clusterbioassaydata_assn = Bio::MAGE::BioAssayData::BioAssayData->new();
}


isa_ok($bioassaydatacluster->getClusterBioAssayData, q[Bio::MAGE::BioAssayData::BioAssayData]);

is($bioassaydatacluster->setClusterBioAssayData($clusterbioassaydata_assn), $clusterbioassaydata_assn,
  'setClusterBioAssayData returns value');

ok($bioassaydatacluster->getClusterBioAssayData() == $clusterbioassaydata_assn,
   'getClusterBioAssayData fetches correct value');

# test setClusterBioAssayData throws exception with bad argument
eval {$bioassaydatacluster->setClusterBioAssayData(1)};
ok($@, 'setClusterBioAssayData throws exception with bad argument');


# test getClusterBioAssayData throws exception with argument
eval {$bioassaydatacluster->getClusterBioAssayData(1)};
ok($@, 'getClusterBioAssayData throws exception with argument');

# test setClusterBioAssayData throws exception with no argument
eval {$bioassaydatacluster->setClusterBioAssayData()};
ok($@, 'setClusterBioAssayData throws exception with no argument');

# test setClusterBioAssayData throws exception with too many argument
eval {$bioassaydatacluster->setClusterBioAssayData(1,2)};
ok($@, 'setClusterBioAssayData throws exception with too many argument');

# test setClusterBioAssayData accepts undef
eval {$bioassaydatacluster->setClusterBioAssayData(undef)};
ok((!$@ and not defined $bioassaydatacluster->getClusterBioAssayData()),
   'setClusterBioAssayData accepts undef');

# test the meta-data for the assoication
$assn = $assns{clusterBioAssayData};
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
   'clusterBioAssayData->other() is a valid Bio::MAGE::Association::End'
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
   'clusterBioAssayData->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($bioassaydatacluster, q[Bio::MAGE::Identifiable]);

