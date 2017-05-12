##############################
#
# Map.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Map.t`

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
use Test::More tests => 113;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioEvent::Map') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;

use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::BioAssayData::DesignElementMap;
use Bio::MAGE::BioAssayData::BioAssayMap;

# we test the new() method
my $map;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $map = Bio::MAGE::BioEvent::Map->new();
}
isa_ok($map, 'Bio::MAGE::BioEvent::Map');

# test the package_name class method
is($map->package_name(), q[BioEvent],
  'package');

# test the class_name class method
is($map->class_name(), q[Bio::MAGE::BioEvent::Map],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $map = Bio::MAGE::BioEvent::Map->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($map->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$map->setIdentifier('1');
is($map->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$map->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$map->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$map->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$map->setIdentifier(undef)};
ok((!$@ and not defined $map->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($map->getName(), '2',
  'name new');

# test getter/setter
$map->setName('2');
is($map->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$map->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$map->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$map->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$map->setName(undef)};
ok((!$@ and not defined $map->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioEvent::Map->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $map = Bio::MAGE::BioEvent::Map->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association protocolApplications
my $protocolapplications_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocolapplications_assn = Bio::MAGE::Protocol::ProtocolApplication->new();
}


ok((UNIVERSAL::isa($map->getProtocolApplications,'ARRAY')
 and scalar @{$map->getProtocolApplications} == 1
 and UNIVERSAL::isa($map->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($map->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($map->getProtocolApplications,'ARRAY')
 and scalar @{$map->getProtocolApplications} == 1
 and $map->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($map->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($map->getProtocolApplications,'ARRAY')
 and scalar @{$map->getProtocolApplications} == 2
 and $map->getProtocolApplications->[0] == $protocolapplications_assn
 and $map->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$map->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$map->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$map->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$map->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$map->setProtocolApplications([])};
ok((!$@ and defined $map->getProtocolApplications()
    and UNIVERSAL::isa($map->getProtocolApplications, 'ARRAY')
    and scalar @{$map->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$map->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$map->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$map->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$map->setProtocolApplications(undef)};
ok((!$@ and not defined $map->getProtocolApplications()),
   'setProtocolApplications accepts undef');

# test the meta-data for the assoication
$assn = $assns{protocolApplications};
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
   'protocolApplications->other() is a valid Bio::MAGE::Association::End'
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
   'protocolApplications->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($map->getDescriptions,'ARRAY')
 and scalar @{$map->getDescriptions} == 1
 and UNIVERSAL::isa($map->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($map->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($map->getDescriptions,'ARRAY')
 and scalar @{$map->getDescriptions} == 1
 and $map->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($map->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($map->getDescriptions,'ARRAY')
 and scalar @{$map->getDescriptions} == 2
 and $map->getDescriptions->[0] == $descriptions_assn
 and $map->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$map->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$map->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$map->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$map->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$map->setDescriptions([])};
ok((!$@ and defined $map->getDescriptions()
    and UNIVERSAL::isa($map->getDescriptions, 'ARRAY')
    and scalar @{$map->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$map->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$map->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$map->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$map->setDescriptions(undef)};
ok((!$@ and not defined $map->getDescriptions()),
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


ok((UNIVERSAL::isa($map->getAuditTrail,'ARRAY')
 and scalar @{$map->getAuditTrail} == 1
 and UNIVERSAL::isa($map->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($map->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($map->getAuditTrail,'ARRAY')
 and scalar @{$map->getAuditTrail} == 1
 and $map->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($map->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($map->getAuditTrail,'ARRAY')
 and scalar @{$map->getAuditTrail} == 2
 and $map->getAuditTrail->[0] == $audittrail_assn
 and $map->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$map->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$map->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$map->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$map->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$map->setAuditTrail([])};
ok((!$@ and defined $map->getAuditTrail()
    and UNIVERSAL::isa($map->getAuditTrail, 'ARRAY')
    and scalar @{$map->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$map->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$map->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$map->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$map->setAuditTrail(undef)};
ok((!$@ and not defined $map->getAuditTrail()),
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


isa_ok($map->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($map->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($map->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$map->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$map->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$map->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$map->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$map->setSecurity(undef)};
ok((!$@ and not defined $map->getSecurity()),
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


ok((UNIVERSAL::isa($map->getPropertySets,'ARRAY')
 and scalar @{$map->getPropertySets} == 1
 and UNIVERSAL::isa($map->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($map->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($map->getPropertySets,'ARRAY')
 and scalar @{$map->getPropertySets} == 1
 and $map->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($map->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($map->getPropertySets,'ARRAY')
 and scalar @{$map->getPropertySets} == 2
 and $map->getPropertySets->[0] == $propertysets_assn
 and $map->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$map->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$map->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$map->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$map->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$map->setPropertySets([])};
ok((!$@ and defined $map->getPropertySets()
    and UNIVERSAL::isa($map->getPropertySets, 'ARRAY')
    and scalar @{$map->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$map->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$map->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$map->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$map->setPropertySets(undef)};
ok((!$@ and not defined $map->getPropertySets()),
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
my $quantitationtypemap = Bio::MAGE::BioAssayData::QuantitationTypeMap->new();

# testing subclass QuantitationTypeMap
isa_ok($quantitationtypemap, q[Bio::MAGE::BioAssayData::QuantitationTypeMap]);
isa_ok($quantitationtypemap, q[Bio::MAGE::BioEvent::Map]);


# create a subclass
my $designelementmap = Bio::MAGE::BioAssayData::DesignElementMap->new();

# testing subclass DesignElementMap
isa_ok($designelementmap, q[Bio::MAGE::BioAssayData::DesignElementMap]);
isa_ok($designelementmap, q[Bio::MAGE::BioEvent::Map]);


# create a subclass
my $bioassaymap = Bio::MAGE::BioAssayData::BioAssayMap->new();

# testing subclass BioAssayMap
isa_ok($bioassaymap, q[Bio::MAGE::BioAssayData::BioAssayMap]);
isa_ok($bioassaymap, q[Bio::MAGE::BioEvent::Map]);



my $bioevent;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $bioevent = Bio::MAGE::BioEvent::BioEvent->new();
}

# testing superclass BioEvent
isa_ok($bioevent, q[Bio::MAGE::BioEvent::BioEvent]);
isa_ok($map, q[Bio::MAGE::BioEvent::BioEvent]);

