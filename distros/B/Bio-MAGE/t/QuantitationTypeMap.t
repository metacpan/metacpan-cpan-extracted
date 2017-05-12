##############################
#
# QuantitationTypeMap.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl QuantitationTypeMap.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::QuantitationTypeMap') };

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;
use Bio::MAGE::QuantitationType::QuantitationType;


# we test the new() method
my $quantitationtypemap;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemap = Bio::MAGE::BioAssayData::QuantitationTypeMap->new();
}
isa_ok($quantitationtypemap, 'Bio::MAGE::BioAssayData::QuantitationTypeMap');

# test the package_name class method
is($quantitationtypemap->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($quantitationtypemap->class_name(), q[Bio::MAGE::BioAssayData::QuantitationTypeMap],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemap = Bio::MAGE::BioAssayData::QuantitationTypeMap->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($quantitationtypemap->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$quantitationtypemap->setIdentifier('1');
is($quantitationtypemap->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$quantitationtypemap->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantitationtypemap->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantitationtypemap->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$quantitationtypemap->setIdentifier(undef)};
ok((!$@ and not defined $quantitationtypemap->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($quantitationtypemap->getName(), '2',
  'name new');

# test getter/setter
$quantitationtypemap->setName('2');
is($quantitationtypemap->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$quantitationtypemap->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$quantitationtypemap->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$quantitationtypemap->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$quantitationtypemap->setName(undef)};
ok((!$@ and not defined $quantitationtypemap->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::QuantitationTypeMap->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtypemap = Bio::MAGE::BioAssayData::QuantitationTypeMap->new(protocolApplications => [Bio::MAGE::Protocol::ProtocolApplication->new()],
sourcesQuantitationType => [Bio::MAGE::QuantitationType::QuantitationType->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
targetQuantitationType => Bio::MAGE::QuantitationType::QuantitationType->new(),
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


ok((UNIVERSAL::isa($quantitationtypemap->getProtocolApplications,'ARRAY')
 and scalar @{$quantitationtypemap->getProtocolApplications} == 1
 and UNIVERSAL::isa($quantitationtypemap->getProtocolApplications->[0], q[Bio::MAGE::Protocol::ProtocolApplication])),
  'protocolApplications set in new()');

ok(eq_array($quantitationtypemap->setProtocolApplications([$protocolapplications_assn]), [$protocolapplications_assn]),
   'setProtocolApplications returns correct value');

ok((UNIVERSAL::isa($quantitationtypemap->getProtocolApplications,'ARRAY')
 and scalar @{$quantitationtypemap->getProtocolApplications} == 1
 and $quantitationtypemap->getProtocolApplications->[0] == $protocolapplications_assn),
   'getProtocolApplications fetches correct value');

is($quantitationtypemap->addProtocolApplications($protocolapplications_assn), 2,
  'addProtocolApplications returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypemap->getProtocolApplications,'ARRAY')
 and scalar @{$quantitationtypemap->getProtocolApplications} == 2
 and $quantitationtypemap->getProtocolApplications->[0] == $protocolapplications_assn
 and $quantitationtypemap->getProtocolApplications->[1] == $protocolapplications_assn),
  'addProtocolApplications adds correct value');

# test setProtocolApplications throws exception with non-array argument
eval {$quantitationtypemap->setProtocolApplications(1)};
ok($@, 'setProtocolApplications throws exception with non-array argument');

# test setProtocolApplications throws exception with bad argument array
eval {$quantitationtypemap->setProtocolApplications([1])};
ok($@, 'setProtocolApplications throws exception with bad argument array');

# test addProtocolApplications throws exception with no arguments
eval {$quantitationtypemap->addProtocolApplications()};
ok($@, 'addProtocolApplications throws exception with no arguments');

# test addProtocolApplications throws exception with bad argument
eval {$quantitationtypemap->addProtocolApplications(1)};
ok($@, 'addProtocolApplications throws exception with bad array');

# test setProtocolApplications accepts empty array ref
eval {$quantitationtypemap->setProtocolApplications([])};
ok((!$@ and defined $quantitationtypemap->getProtocolApplications()
    and UNIVERSAL::isa($quantitationtypemap->getProtocolApplications, 'ARRAY')
    and scalar @{$quantitationtypemap->getProtocolApplications} == 0),
   'setProtocolApplications accepts empty array ref');


# test getProtocolApplications throws exception with argument
eval {$quantitationtypemap->getProtocolApplications(1)};
ok($@, 'getProtocolApplications throws exception with argument');

# test setProtocolApplications throws exception with no argument
eval {$quantitationtypemap->setProtocolApplications()};
ok($@, 'setProtocolApplications throws exception with no argument');

# test setProtocolApplications throws exception with too many argument
eval {$quantitationtypemap->setProtocolApplications(1,2)};
ok($@, 'setProtocolApplications throws exception with too many argument');

# test setProtocolApplications accepts undef
eval {$quantitationtypemap->setProtocolApplications(undef)};
ok((!$@ and not defined $quantitationtypemap->getProtocolApplications()),
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



# testing association sourcesQuantitationType
my $sourcesquantitationtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $sourcesquantitationtype_assn = Bio::MAGE::QuantitationType::QuantitationType->new();
}


ok((UNIVERSAL::isa($quantitationtypemap->getSourcesQuantitationType,'ARRAY')
 and scalar @{$quantitationtypemap->getSourcesQuantitationType} == 1
 and UNIVERSAL::isa($quantitationtypemap->getSourcesQuantitationType->[0], q[Bio::MAGE::QuantitationType::QuantitationType])),
  'sourcesQuantitationType set in new()');

ok(eq_array($quantitationtypemap->setSourcesQuantitationType([$sourcesquantitationtype_assn]), [$sourcesquantitationtype_assn]),
   'setSourcesQuantitationType returns correct value');

ok((UNIVERSAL::isa($quantitationtypemap->getSourcesQuantitationType,'ARRAY')
 and scalar @{$quantitationtypemap->getSourcesQuantitationType} == 1
 and $quantitationtypemap->getSourcesQuantitationType->[0] == $sourcesquantitationtype_assn),
   'getSourcesQuantitationType fetches correct value');

is($quantitationtypemap->addSourcesQuantitationType($sourcesquantitationtype_assn), 2,
  'addSourcesQuantitationType returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypemap->getSourcesQuantitationType,'ARRAY')
 and scalar @{$quantitationtypemap->getSourcesQuantitationType} == 2
 and $quantitationtypemap->getSourcesQuantitationType->[0] == $sourcesquantitationtype_assn
 and $quantitationtypemap->getSourcesQuantitationType->[1] == $sourcesquantitationtype_assn),
  'addSourcesQuantitationType adds correct value');

# test setSourcesQuantitationType throws exception with non-array argument
eval {$quantitationtypemap->setSourcesQuantitationType(1)};
ok($@, 'setSourcesQuantitationType throws exception with non-array argument');

# test setSourcesQuantitationType throws exception with bad argument array
eval {$quantitationtypemap->setSourcesQuantitationType([1])};
ok($@, 'setSourcesQuantitationType throws exception with bad argument array');

# test addSourcesQuantitationType throws exception with no arguments
eval {$quantitationtypemap->addSourcesQuantitationType()};
ok($@, 'addSourcesQuantitationType throws exception with no arguments');

# test addSourcesQuantitationType throws exception with bad argument
eval {$quantitationtypemap->addSourcesQuantitationType(1)};
ok($@, 'addSourcesQuantitationType throws exception with bad array');

# test setSourcesQuantitationType accepts empty array ref
eval {$quantitationtypemap->setSourcesQuantitationType([])};
ok((!$@ and defined $quantitationtypemap->getSourcesQuantitationType()
    and UNIVERSAL::isa($quantitationtypemap->getSourcesQuantitationType, 'ARRAY')
    and scalar @{$quantitationtypemap->getSourcesQuantitationType} == 0),
   'setSourcesQuantitationType accepts empty array ref');


# test getSourcesQuantitationType throws exception with argument
eval {$quantitationtypemap->getSourcesQuantitationType(1)};
ok($@, 'getSourcesQuantitationType throws exception with argument');

# test setSourcesQuantitationType throws exception with no argument
eval {$quantitationtypemap->setSourcesQuantitationType()};
ok($@, 'setSourcesQuantitationType throws exception with no argument');

# test setSourcesQuantitationType throws exception with too many argument
eval {$quantitationtypemap->setSourcesQuantitationType(1,2)};
ok($@, 'setSourcesQuantitationType throws exception with too many argument');

# test setSourcesQuantitationType accepts undef
eval {$quantitationtypemap->setSourcesQuantitationType(undef)};
ok((!$@ and not defined $quantitationtypemap->getSourcesQuantitationType()),
   'setSourcesQuantitationType accepts undef');

# test the meta-data for the assoication
$assn = $assns{sourcesQuantitationType};
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
   'sourcesQuantitationType->other() is a valid Bio::MAGE::Association::End'
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
   'sourcesQuantitationType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($quantitationtypemap->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypemap->getDescriptions} == 1
 and UNIVERSAL::isa($quantitationtypemap->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($quantitationtypemap->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($quantitationtypemap->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypemap->getDescriptions} == 1
 and $quantitationtypemap->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($quantitationtypemap->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypemap->getDescriptions,'ARRAY')
 and scalar @{$quantitationtypemap->getDescriptions} == 2
 and $quantitationtypemap->getDescriptions->[0] == $descriptions_assn
 and $quantitationtypemap->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$quantitationtypemap->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$quantitationtypemap->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$quantitationtypemap->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$quantitationtypemap->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$quantitationtypemap->setDescriptions([])};
ok((!$@ and defined $quantitationtypemap->getDescriptions()
    and UNIVERSAL::isa($quantitationtypemap->getDescriptions, 'ARRAY')
    and scalar @{$quantitationtypemap->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$quantitationtypemap->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$quantitationtypemap->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$quantitationtypemap->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$quantitationtypemap->setDescriptions(undef)};
ok((!$@ and not defined $quantitationtypemap->getDescriptions()),
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


isa_ok($quantitationtypemap->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($quantitationtypemap->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($quantitationtypemap->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$quantitationtypemap->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$quantitationtypemap->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$quantitationtypemap->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$quantitationtypemap->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$quantitationtypemap->setSecurity(undef)};
ok((!$@ and not defined $quantitationtypemap->getSecurity()),
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


ok((UNIVERSAL::isa($quantitationtypemap->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypemap->getAuditTrail} == 1
 and UNIVERSAL::isa($quantitationtypemap->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($quantitationtypemap->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($quantitationtypemap->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypemap->getAuditTrail} == 1
 and $quantitationtypemap->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($quantitationtypemap->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypemap->getAuditTrail,'ARRAY')
 and scalar @{$quantitationtypemap->getAuditTrail} == 2
 and $quantitationtypemap->getAuditTrail->[0] == $audittrail_assn
 and $quantitationtypemap->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$quantitationtypemap->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$quantitationtypemap->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$quantitationtypemap->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$quantitationtypemap->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$quantitationtypemap->setAuditTrail([])};
ok((!$@ and defined $quantitationtypemap->getAuditTrail()
    and UNIVERSAL::isa($quantitationtypemap->getAuditTrail, 'ARRAY')
    and scalar @{$quantitationtypemap->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$quantitationtypemap->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$quantitationtypemap->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$quantitationtypemap->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$quantitationtypemap->setAuditTrail(undef)};
ok((!$@ and not defined $quantitationtypemap->getAuditTrail()),
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



# testing association targetQuantitationType
my $targetquantitationtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $targetquantitationtype_assn = Bio::MAGE::QuantitationType::QuantitationType->new();
}


isa_ok($quantitationtypemap->getTargetQuantitationType, q[Bio::MAGE::QuantitationType::QuantitationType]);

is($quantitationtypemap->setTargetQuantitationType($targetquantitationtype_assn), $targetquantitationtype_assn,
  'setTargetQuantitationType returns value');

ok($quantitationtypemap->getTargetQuantitationType() == $targetquantitationtype_assn,
   'getTargetQuantitationType fetches correct value');

# test setTargetQuantitationType throws exception with bad argument
eval {$quantitationtypemap->setTargetQuantitationType(1)};
ok($@, 'setTargetQuantitationType throws exception with bad argument');


# test getTargetQuantitationType throws exception with argument
eval {$quantitationtypemap->getTargetQuantitationType(1)};
ok($@, 'getTargetQuantitationType throws exception with argument');

# test setTargetQuantitationType throws exception with no argument
eval {$quantitationtypemap->setTargetQuantitationType()};
ok($@, 'setTargetQuantitationType throws exception with no argument');

# test setTargetQuantitationType throws exception with too many argument
eval {$quantitationtypemap->setTargetQuantitationType(1,2)};
ok($@, 'setTargetQuantitationType throws exception with too many argument');

# test setTargetQuantitationType accepts undef
eval {$quantitationtypemap->setTargetQuantitationType(undef)};
ok((!$@ and not defined $quantitationtypemap->getTargetQuantitationType()),
   'setTargetQuantitationType accepts undef');

# test the meta-data for the assoication
$assn = $assns{targetQuantitationType};
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
   'targetQuantitationType->other() is a valid Bio::MAGE::Association::End'
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
   'targetQuantitationType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($quantitationtypemap->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypemap->getPropertySets} == 1
 and UNIVERSAL::isa($quantitationtypemap->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($quantitationtypemap->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($quantitationtypemap->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypemap->getPropertySets} == 1
 and $quantitationtypemap->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($quantitationtypemap->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($quantitationtypemap->getPropertySets,'ARRAY')
 and scalar @{$quantitationtypemap->getPropertySets} == 2
 and $quantitationtypemap->getPropertySets->[0] == $propertysets_assn
 and $quantitationtypemap->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$quantitationtypemap->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$quantitationtypemap->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$quantitationtypemap->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$quantitationtypemap->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$quantitationtypemap->setPropertySets([])};
ok((!$@ and defined $quantitationtypemap->getPropertySets()
    and UNIVERSAL::isa($quantitationtypemap->getPropertySets, 'ARRAY')
    and scalar @{$quantitationtypemap->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$quantitationtypemap->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$quantitationtypemap->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$quantitationtypemap->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$quantitationtypemap->setPropertySets(undef)};
ok((!$@ and not defined $quantitationtypemap->getPropertySets()),
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
isa_ok($quantitationtypemap, q[Bio::MAGE::BioEvent::Map]);

