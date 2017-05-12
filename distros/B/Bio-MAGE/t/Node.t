##############################
#
# Node.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Node.t`

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
use Test::More tests => 133;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::HigherLevelAnalysis::Node') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::HigherLevelAnalysis::Node;
use Bio::MAGE::HigherLevelAnalysis::NodeContents;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::HigherLevelAnalysis::NodeValue;


# we test the new() method
my $node;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $node = Bio::MAGE::HigherLevelAnalysis::Node->new();
}
isa_ok($node, 'Bio::MAGE::HigherLevelAnalysis::Node');

# test the package_name class method
is($node->package_name(), q[HigherLevelAnalysis],
  'package');

# test the class_name class method
is($node->class_name(), q[Bio::MAGE::HigherLevelAnalysis::Node],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $node = Bio::MAGE::HigherLevelAnalysis::Node->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::HigherLevelAnalysis::Node->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $node = Bio::MAGE::HigherLevelAnalysis::Node->new(nodeValue => [Bio::MAGE::HigherLevelAnalysis::NodeValue->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
nodes => [Bio::MAGE::HigherLevelAnalysis::Node->new()],
nodeContents => [Bio::MAGE::HigherLevelAnalysis::NodeContents->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association nodeValue
my $nodevalue_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodevalue_assn = Bio::MAGE::HigherLevelAnalysis::NodeValue->new();
}


ok((UNIVERSAL::isa($node->getNodeValue,'ARRAY')
 and scalar @{$node->getNodeValue} == 1
 and UNIVERSAL::isa($node->getNodeValue->[0], q[Bio::MAGE::HigherLevelAnalysis::NodeValue])),
  'nodeValue set in new()');

ok(eq_array($node->setNodeValue([$nodevalue_assn]), [$nodevalue_assn]),
   'setNodeValue returns correct value');

ok((UNIVERSAL::isa($node->getNodeValue,'ARRAY')
 and scalar @{$node->getNodeValue} == 1
 and $node->getNodeValue->[0] == $nodevalue_assn),
   'getNodeValue fetches correct value');

is($node->addNodeValue($nodevalue_assn), 2,
  'addNodeValue returns number of items in list');

ok((UNIVERSAL::isa($node->getNodeValue,'ARRAY')
 and scalar @{$node->getNodeValue} == 2
 and $node->getNodeValue->[0] == $nodevalue_assn
 and $node->getNodeValue->[1] == $nodevalue_assn),
  'addNodeValue adds correct value');

# test setNodeValue throws exception with non-array argument
eval {$node->setNodeValue(1)};
ok($@, 'setNodeValue throws exception with non-array argument');

# test setNodeValue throws exception with bad argument array
eval {$node->setNodeValue([1])};
ok($@, 'setNodeValue throws exception with bad argument array');

# test addNodeValue throws exception with no arguments
eval {$node->addNodeValue()};
ok($@, 'addNodeValue throws exception with no arguments');

# test addNodeValue throws exception with bad argument
eval {$node->addNodeValue(1)};
ok($@, 'addNodeValue throws exception with bad array');

# test setNodeValue accepts empty array ref
eval {$node->setNodeValue([])};
ok((!$@ and defined $node->getNodeValue()
    and UNIVERSAL::isa($node->getNodeValue, 'ARRAY')
    and scalar @{$node->getNodeValue} == 0),
   'setNodeValue accepts empty array ref');


# test getNodeValue throws exception with argument
eval {$node->getNodeValue(1)};
ok($@, 'getNodeValue throws exception with argument');

# test setNodeValue throws exception with no argument
eval {$node->setNodeValue()};
ok($@, 'setNodeValue throws exception with no argument');

# test setNodeValue throws exception with too many argument
eval {$node->setNodeValue(1,2)};
ok($@, 'setNodeValue throws exception with too many argument');

# test setNodeValue accepts undef
eval {$node->setNodeValue(undef)};
ok((!$@ and not defined $node->getNodeValue()),
   'setNodeValue accepts undef');

# test the meta-data for the assoication
$assn = $assns{nodeValue};
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
   'nodeValue->other() is a valid Bio::MAGE::Association::End'
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
   'nodeValue->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($node->getDescriptions,'ARRAY')
 and scalar @{$node->getDescriptions} == 1
 and UNIVERSAL::isa($node->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($node->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($node->getDescriptions,'ARRAY')
 and scalar @{$node->getDescriptions} == 1
 and $node->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($node->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($node->getDescriptions,'ARRAY')
 and scalar @{$node->getDescriptions} == 2
 and $node->getDescriptions->[0] == $descriptions_assn
 and $node->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$node->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$node->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$node->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$node->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$node->setDescriptions([])};
ok((!$@ and defined $node->getDescriptions()
    and UNIVERSAL::isa($node->getDescriptions, 'ARRAY')
    and scalar @{$node->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$node->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$node->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$node->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$node->setDescriptions(undef)};
ok((!$@ and not defined $node->getDescriptions()),
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


ok((UNIVERSAL::isa($node->getAuditTrail,'ARRAY')
 and scalar @{$node->getAuditTrail} == 1
 and UNIVERSAL::isa($node->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($node->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($node->getAuditTrail,'ARRAY')
 and scalar @{$node->getAuditTrail} == 1
 and $node->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($node->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($node->getAuditTrail,'ARRAY')
 and scalar @{$node->getAuditTrail} == 2
 and $node->getAuditTrail->[0] == $audittrail_assn
 and $node->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$node->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$node->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$node->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$node->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$node->setAuditTrail([])};
ok((!$@ and defined $node->getAuditTrail()
    and UNIVERSAL::isa($node->getAuditTrail, 'ARRAY')
    and scalar @{$node->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$node->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$node->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$node->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$node->setAuditTrail(undef)};
ok((!$@ and not defined $node->getAuditTrail()),
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


isa_ok($node->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($node->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($node->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$node->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$node->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$node->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$node->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$node->setSecurity(undef)};
ok((!$@ and not defined $node->getSecurity()),
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



# testing association nodes
my $nodes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodes_assn = Bio::MAGE::HigherLevelAnalysis::Node->new();
}


ok((UNIVERSAL::isa($node->getNodes,'ARRAY')
 and scalar @{$node->getNodes} == 1
 and UNIVERSAL::isa($node->getNodes->[0], q[Bio::MAGE::HigherLevelAnalysis::Node])),
  'nodes set in new()');

ok(eq_array($node->setNodes([$nodes_assn]), [$nodes_assn]),
   'setNodes returns correct value');

ok((UNIVERSAL::isa($node->getNodes,'ARRAY')
 and scalar @{$node->getNodes} == 1
 and $node->getNodes->[0] == $nodes_assn),
   'getNodes fetches correct value');

is($node->addNodes($nodes_assn), 2,
  'addNodes returns number of items in list');

ok((UNIVERSAL::isa($node->getNodes,'ARRAY')
 and scalar @{$node->getNodes} == 2
 and $node->getNodes->[0] == $nodes_assn
 and $node->getNodes->[1] == $nodes_assn),
  'addNodes adds correct value');

# test setNodes throws exception with non-array argument
eval {$node->setNodes(1)};
ok($@, 'setNodes throws exception with non-array argument');

# test setNodes throws exception with bad argument array
eval {$node->setNodes([1])};
ok($@, 'setNodes throws exception with bad argument array');

# test addNodes throws exception with no arguments
eval {$node->addNodes()};
ok($@, 'addNodes throws exception with no arguments');

# test addNodes throws exception with bad argument
eval {$node->addNodes(1)};
ok($@, 'addNodes throws exception with bad array');

# test setNodes accepts empty array ref
eval {$node->setNodes([])};
ok((!$@ and defined $node->getNodes()
    and UNIVERSAL::isa($node->getNodes, 'ARRAY')
    and scalar @{$node->getNodes} == 0),
   'setNodes accepts empty array ref');


# test getNodes throws exception with argument
eval {$node->getNodes(1)};
ok($@, 'getNodes throws exception with argument');

# test setNodes throws exception with no argument
eval {$node->setNodes()};
ok($@, 'setNodes throws exception with no argument');

# test setNodes throws exception with too many argument
eval {$node->setNodes(1,2)};
ok($@, 'setNodes throws exception with too many argument');

# test setNodes accepts undef
eval {$node->setNodes(undef)};
ok((!$@ and not defined $node->getNodes()),
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



# testing association nodeContents
my $nodecontents_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $nodecontents_assn = Bio::MAGE::HigherLevelAnalysis::NodeContents->new();
}


ok((UNIVERSAL::isa($node->getNodeContents,'ARRAY')
 and scalar @{$node->getNodeContents} == 1
 and UNIVERSAL::isa($node->getNodeContents->[0], q[Bio::MAGE::HigherLevelAnalysis::NodeContents])),
  'nodeContents set in new()');

ok(eq_array($node->setNodeContents([$nodecontents_assn]), [$nodecontents_assn]),
   'setNodeContents returns correct value');

ok((UNIVERSAL::isa($node->getNodeContents,'ARRAY')
 and scalar @{$node->getNodeContents} == 1
 and $node->getNodeContents->[0] == $nodecontents_assn),
   'getNodeContents fetches correct value');

is($node->addNodeContents($nodecontents_assn), 2,
  'addNodeContents returns number of items in list');

ok((UNIVERSAL::isa($node->getNodeContents,'ARRAY')
 and scalar @{$node->getNodeContents} == 2
 and $node->getNodeContents->[0] == $nodecontents_assn
 and $node->getNodeContents->[1] == $nodecontents_assn),
  'addNodeContents adds correct value');

# test setNodeContents throws exception with non-array argument
eval {$node->setNodeContents(1)};
ok($@, 'setNodeContents throws exception with non-array argument');

# test setNodeContents throws exception with bad argument array
eval {$node->setNodeContents([1])};
ok($@, 'setNodeContents throws exception with bad argument array');

# test addNodeContents throws exception with no arguments
eval {$node->addNodeContents()};
ok($@, 'addNodeContents throws exception with no arguments');

# test addNodeContents throws exception with bad argument
eval {$node->addNodeContents(1)};
ok($@, 'addNodeContents throws exception with bad array');

# test setNodeContents accepts empty array ref
eval {$node->setNodeContents([])};
ok((!$@ and defined $node->getNodeContents()
    and UNIVERSAL::isa($node->getNodeContents, 'ARRAY')
    and scalar @{$node->getNodeContents} == 0),
   'setNodeContents accepts empty array ref');


# test getNodeContents throws exception with argument
eval {$node->getNodeContents(1)};
ok($@, 'getNodeContents throws exception with argument');

# test setNodeContents throws exception with no argument
eval {$node->setNodeContents()};
ok($@, 'setNodeContents throws exception with no argument');

# test setNodeContents throws exception with too many argument
eval {$node->setNodeContents(1,2)};
ok($@, 'setNodeContents throws exception with too many argument');

# test setNodeContents accepts undef
eval {$node->setNodeContents(undef)};
ok((!$@ and not defined $node->getNodeContents()),
   'setNodeContents accepts undef');

# test the meta-data for the assoication
$assn = $assns{nodeContents};
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
   'nodeContents->other() is a valid Bio::MAGE::Association::End'
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
   'nodeContents->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($node->getPropertySets,'ARRAY')
 and scalar @{$node->getPropertySets} == 1
 and UNIVERSAL::isa($node->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($node->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($node->getPropertySets,'ARRAY')
 and scalar @{$node->getPropertySets} == 1
 and $node->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($node->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($node->getPropertySets,'ARRAY')
 and scalar @{$node->getPropertySets} == 2
 and $node->getPropertySets->[0] == $propertysets_assn
 and $node->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$node->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$node->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$node->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$node->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$node->setPropertySets([])};
ok((!$@ and defined $node->getPropertySets()
    and UNIVERSAL::isa($node->getPropertySets, 'ARRAY')
    and scalar @{$node->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$node->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$node->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$node->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$node->setPropertySets(undef)};
ok((!$@ and not defined $node->getPropertySets()),
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





my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($node, q[Bio::MAGE::Describable]);

