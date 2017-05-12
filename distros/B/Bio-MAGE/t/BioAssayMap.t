##############################
#
# BioAssayMap.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayMap.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioAssayMap') };

use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::BioAssay::DerivedBioAssay;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $bioassaymap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymap = Bio::MAGE::BioAssayData::BioAssayMap->new();
}
isa_ok($bioassaymap, 'Bio::MAGE::BioAssayData::BioAssayMap');

# test the package_name class method
is($bioassaymap->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($bioassaymap->class_name(), q[Bio::MAGE::BioAssayData::BioAssayMap],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymap = Bio::MAGE::BioAssayData::BioAssayMap->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaymap->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaymap->setIdentifier('1');
is($bioassaymap->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaymap->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaymap->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaymap->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaymap->setIdentifier(undef)};
ok((!$@ and not defined $bioassaymap->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaymap->getName(), '2',
  'name new');

# test getter/setter
$bioassaymap->setName('2');
is($bioassaymap->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaymap->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaymap->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaymap->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaymap->setName(undef)};
ok((!$@ and not defined $bioassaymap->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioAssayMap->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymap = Bio::MAGE::BioAssayData::BioAssayMap->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
bioAssayMapTarget => Bio::MAGE::BioAssay::DerivedBioAssay->new(),
sourceBioAssays => [Bio::MAGE::BioAssay::BioAssay->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
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


ok((UNIVERSAL::isa($bioassaymap->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaymap->getProtocolApplications} == 1
 and UNIVERSAL::isa($bioassaymap->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($bioassaymap->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($bioassaymap->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaymap->getProtocolApplications} == 1
 and $bioassaymap->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($bioassaymap->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($bioassaymap->getProtocolApplications,'ARRAY')
 and scalar @{$bioassaymap->getProtocolApplications} == 2
 and $bioassaymap->getProtocolApplications->[0] == $protocolapplications_assn
 and $bioassaymap->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$bioassaymap->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$bioassaymap->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$bioassaymap->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$bioassaymap->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$bioassaymap->setProtocolApplications([])};
ok((!$@ and defined $bioassaymap->getProtocolApplications()
    and UNIVERSAL::isa($bioassaymap->getProtocolApplications, 'ARRAY')
    and scalar @{$bioassaymap->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$bioassaymap->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$bioassaymap->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$bioassaymap->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$bioassaymap->setProtocolApplications(undef)};
ok((!$@ and not defined $bioassaymap->getProtocolApplications()),
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


ok((UNIVERSAL::isa($bioassaymap->getDescriptions,'ARRAY')
 and scalar @{$bioassaymap->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaymap->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaymap->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaymap->getDescriptions,'ARRAY')
 and scalar @{$bioassaymap->getDescriptions} == 1
 and $bioassaymap->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaymap->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaymap->getDescriptions,'ARRAY')
 and scalar @{$bioassaymap->getDescriptions} == 2
 and $bioassaymap->getDescriptions->[0] == $descriptions_assn
 and $bioassaymap->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaymap->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaymap->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaymap->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaymap->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaymap->setDescriptions([])};
ok((!$@ and defined $bioassaymap->getDescriptions()
    and UNIVERSAL::isa($bioassaymap->getDescriptions, 'ARRAY')
    and scalar @{$bioassaymap->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaymap->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaymap->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaymap->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaymap->setDescriptions(undef)};
ok((!$@ and not defined $bioassaymap->getDescriptions()),
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



# testing association bioAssayMapTarget
my $bioassaymaptarget_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaymaptarget_assn = Bio::MAGE::BioAssay::DerivedBioAssay->new();
}


isa_ok($bioassaymap->getBioAssayMapTarget, q[Bio::MAGE::BioAssay::DerivedBioAssay]);

is($bioassaymap->setBioAssayMapTarget($bioassaymaptarget_assn), $bioassaymaptarget_assn,
  'setBioAssayMapTarget returns value');

ok($bioassaymap->getBioAssayMapTarget() == $bioassaymaptarget_assn,
   'getBioAssayMapTarget fetches correct value');

# test setBioAssayMapTarget throws exception with bad argument
eval {$bioassaymap->setBioAssayMapTarget(1)};
ok($@, 'setBioAssayMapTarget throws exception with bad argument');


# test getBioAssayMapTarget throws exception with argument
eval {$bioassaymap->getBioAssayMapTarget(1)};
ok($@, 'getBioAssayMapTarget throws exception with argument');

# test setBioAssayMapTarget throws exception with no argument
eval {$bioassaymap->setBioAssayMapTarget()};
ok($@, 'setBioAssayMapTarget throws exception with no argument');

# test setBioAssayMapTarget throws exception with too many argument
eval {$bioassaymap->setBioAssayMapTarget(1,2)};
ok($@, 'setBioAssayMapTarget throws exception with too many argument');

# test setBioAssayMapTarget accepts undef
eval {$bioassaymap->setBioAssayMapTarget(undef)};
ok((!$@ and not defined $bioassaymap->getBioAssayMapTarget()),
   'setBioAssayMapTarget accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssayMapTarget};
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
   'bioAssayMapTarget->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssayMapTarget->self() is a valid Bio::MAGE::Association::End'
  );



# testing association sourceBioAssays
my $sourcebioassays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sourcebioassays_assn = Bio::MAGE::BioAssay::BioAssay->new();
}


ok((UNIVERSAL::isa($bioassaymap->getSourceBioAssays,'ARRAY')
 and scalar @{$bioassaymap->getSourceBioAssays} == 1
 and UNIVERSAL::isa($bioassaymap->getSourceBioAssays->[0], q[Bio::MAGE::BioAssay::BioAssay])),
  'sourceBioAssays set in new()');

ok(eq_array($bioassaymap->setSourceBioAssays([$sourcebioassays_assn]), [$sourcebioassays_assn]),
   'setSourceBioAssays returns correct value');

ok((UNIVERSAL::isa($bioassaymap->getSourceBioAssays,'ARRAY')
 and scalar @{$bioassaymap->getSourceBioAssays} == 1
 and $bioassaymap->getSourceBioAssays->[0] == $sourcebioassays_assn),
   'getSourceBioAssays fetches correct value');

is($bioassaymap->addSourceBioAssays($sourcebioassays_assn), 2,
  'addSourceBioAssays returns number of items in list');

ok((UNIVERSAL::isa($bioassaymap->getSourceBioAssays,'ARRAY')
 and scalar @{$bioassaymap->getSourceBioAssays} == 2
 and $bioassaymap->getSourceBioAssays->[0] == $sourcebioassays_assn
 and $bioassaymap->getSourceBioAssays->[1] == $sourcebioassays_assn),
  'addSourceBioAssays adds correct value');

# test setSourceBioAssays throws exception with non-array argument
eval {$bioassaymap->setSourceBioAssays(1)};
ok($@, 'setSourceBioAssays throws exception with non-array argument');

# test setSourceBioAssays throws exception with bad argument array
eval {$bioassaymap->setSourceBioAssays([1])};
ok($@, 'setSourceBioAssays throws exception with bad argument array');

# test addSourceBioAssays throws exception with no arguments
eval {$bioassaymap->addSourceBioAssays()};
ok($@, 'addSourceBioAssays throws exception with no arguments');

# test addSourceBioAssays throws exception with bad argument
eval {$bioassaymap->addSourceBioAssays(1)};
ok($@, 'addSourceBioAssays throws exception with bad array');

# test setSourceBioAssays accepts empty array ref
eval {$bioassaymap->setSourceBioAssays([])};
ok((!$@ and defined $bioassaymap->getSourceBioAssays()
    and UNIVERSAL::isa($bioassaymap->getSourceBioAssays, 'ARRAY')
    and scalar @{$bioassaymap->getSourceBioAssays} == 0),
   'setSourceBioAssays accepts empty array ref');


# test getSourceBioAssays throws exception with argument
eval {$bioassaymap->getSourceBioAssays(1)};
ok($@, 'getSourceBioAssays throws exception with argument');

# test setSourceBioAssays throws exception with no argument
eval {$bioassaymap->setSourceBioAssays()};
ok($@, 'setSourceBioAssays throws exception with no argument');

# test setSourceBioAssays throws exception with too many argument
eval {$bioassaymap->setSourceBioAssays(1,2)};
ok($@, 'setSourceBioAssays throws exception with too many argument');

# test setSourceBioAssays accepts undef
eval {$bioassaymap->setSourceBioAssays(undef)};
ok((!$@ and not defined $bioassaymap->getSourceBioAssays()),
   'setSourceBioAssays accepts undef');

# test the meta-data for the assoication
$assn = $assns{sourceBioAssays};
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
   'sourceBioAssays->other() is a valid Bio::MAGE::Association::End'
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
   'sourceBioAssays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($bioassaymap->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaymap->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaymap->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaymap->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaymap->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaymap->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaymap->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaymap->setSecurity(undef)};
ok((!$@ and not defined $bioassaymap->getSecurity()),
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


ok((UNIVERSAL::isa($bioassaymap->getAuditTrail,'ARRAY')
 and scalar @{$bioassaymap->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaymap->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaymap->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaymap->getAuditTrail,'ARRAY')
 and scalar @{$bioassaymap->getAuditTrail} == 1
 and $bioassaymap->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaymap->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaymap->getAuditTrail,'ARRAY')
 and scalar @{$bioassaymap->getAuditTrail} == 2
 and $bioassaymap->getAuditTrail->[0] == $audittrail_assn
 and $bioassaymap->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaymap->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaymap->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaymap->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaymap->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaymap->setAuditTrail([])};
ok((!$@ and defined $bioassaymap->getAuditTrail()
    and UNIVERSAL::isa($bioassaymap->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaymap->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaymap->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaymap->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaymap->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaymap->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaymap->getAuditTrail()),
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


ok((UNIVERSAL::isa($bioassaymap->getPropertySets,'ARRAY')
 and scalar @{$bioassaymap->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaymap->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaymap->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaymap->getPropertySets,'ARRAY')
 and scalar @{$bioassaymap->getPropertySets} == 1
 and $bioassaymap->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaymap->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaymap->getPropertySets,'ARRAY')
 and scalar @{$bioassaymap->getPropertySets} == 2
 and $bioassaymap->getPropertySets->[0] == $propertysets_assn
 and $bioassaymap->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaymap->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaymap->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaymap->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaymap->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaymap->setPropertySets([])};
ok((!$@ and defined $bioassaymap->getPropertySets()
    and UNIVERSAL::isa($bioassaymap->getPropertySets, 'ARRAY')
    and scalar @{$bioassaymap->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaymap->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaymap->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaymap->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaymap->setPropertySets(undef)};
ok((!$@ and not defined $bioassaymap->getPropertySets()),
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





my $map;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $map = Bio::MAGE::BioEvent::Map->new();
}

# testing superclass Map
isa_ok($map, q[Bio::MAGE::BioEvent::Map]);
isa_ok($bioassaymap, q[Bio::MAGE::BioEvent::Map]);

