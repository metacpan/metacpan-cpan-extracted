##############################
#
# BioAssayDimension.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayDimension.t`

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

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioAssayDimension') };

use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $bioassaydimension;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension = Bio::MAGE::BioAssayData::BioAssayDimension->new();
}
isa_ok($bioassaydimension, 'Bio::MAGE::BioAssayData::BioAssayDimension');

# test the package_name class method
is($bioassaydimension->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($bioassaydimension->class_name(), q[Bio::MAGE::BioAssayData::BioAssayDimension],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension = Bio::MAGE::BioAssayData::BioAssayDimension->new(identifier => '1',
name => '2');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($bioassaydimension->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$bioassaydimension->setIdentifier('1');
is($bioassaydimension->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$bioassaydimension->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydimension->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydimension->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydimension->setIdentifier(undef)};
ok((!$@ and not defined $bioassaydimension->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($bioassaydimension->getName(), '2',
  'name new');

# test getter/setter
$bioassaydimension->setName('2');
is($bioassaydimension->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$bioassaydimension->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydimension->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydimension->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydimension->setName(undef)};
ok((!$@ and not defined $bioassaydimension->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioAssayDimension->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydimension = Bio::MAGE::BioAssayData::BioAssayDimension->new(bioAssays => [Bio::MAGE::BioAssay::BioAssay->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association bioAssays
my $bioassays_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassays_assn = Bio::MAGE::BioAssay::BioAssay->new();
}


ok((UNIVERSAL::isa($bioassaydimension->getBioAssays,'ARRAY')
 and scalar @{$bioassaydimension->getBioAssays} == 1
 and UNIVERSAL::isa($bioassaydimension->getBioAssays->[0], q[Bio::MAGE::BioAssay::BioAssay])),
  'bioAssays set in new()');

ok(eq_array($bioassaydimension->setBioAssays([$bioassays_assn]), [$bioassays_assn]),
   'setBioAssays returns correct value');

ok((UNIVERSAL::isa($bioassaydimension->getBioAssays,'ARRAY')
 and scalar @{$bioassaydimension->getBioAssays} == 1
 and $bioassaydimension->getBioAssays->[0] == $bioassays_assn),
   'getBioAssays fetches correct value');

is($bioassaydimension->addBioAssays($bioassays_assn), 2,
  'addBioAssays returns number of items in list');

ok((UNIVERSAL::isa($bioassaydimension->getBioAssays,'ARRAY')
 and scalar @{$bioassaydimension->getBioAssays} == 2
 and $bioassaydimension->getBioAssays->[0] == $bioassays_assn
 and $bioassaydimension->getBioAssays->[1] == $bioassays_assn),
  'addBioAssays adds correct value');

# test setBioAssays throws exception with non-array argument
eval {$bioassaydimension->setBioAssays(1)};
ok($@, 'setBioAssays throws exception with non-array argument');

# test setBioAssays throws exception with bad argument array
eval {$bioassaydimension->setBioAssays([1])};
ok($@, 'setBioAssays throws exception with bad argument array');

# test addBioAssays throws exception with no arguments
eval {$bioassaydimension->addBioAssays()};
ok($@, 'addBioAssays throws exception with no arguments');

# test addBioAssays throws exception with bad argument
eval {$bioassaydimension->addBioAssays(1)};
ok($@, 'addBioAssays throws exception with bad array');

# test setBioAssays accepts empty array ref
eval {$bioassaydimension->setBioAssays([])};
ok((!$@ and defined $bioassaydimension->getBioAssays()
    and UNIVERSAL::isa($bioassaydimension->getBioAssays, 'ARRAY')
    and scalar @{$bioassaydimension->getBioAssays} == 0),
   'setBioAssays accepts empty array ref');


# test getBioAssays throws exception with argument
eval {$bioassaydimension->getBioAssays(1)};
ok($@, 'getBioAssays throws exception with argument');

# test setBioAssays throws exception with no argument
eval {$bioassaydimension->setBioAssays()};
ok($@, 'setBioAssays throws exception with no argument');

# test setBioAssays throws exception with too many argument
eval {$bioassaydimension->setBioAssays(1,2)};
ok($@, 'setBioAssays throws exception with too many argument');

# test setBioAssays accepts undef
eval {$bioassaydimension->setBioAssays(undef)};
ok((!$@ and not defined $bioassaydimension->getBioAssays()),
   'setBioAssays accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssays};
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
   'bioAssays->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssays->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bioassaydimension->getDescriptions,'ARRAY')
 and scalar @{$bioassaydimension->getDescriptions} == 1
 and UNIVERSAL::isa($bioassaydimension->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bioassaydimension->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bioassaydimension->getDescriptions,'ARRAY')
 and scalar @{$bioassaydimension->getDescriptions} == 1
 and $bioassaydimension->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bioassaydimension->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bioassaydimension->getDescriptions,'ARRAY')
 and scalar @{$bioassaydimension->getDescriptions} == 2
 and $bioassaydimension->getDescriptions->[0] == $descriptions_assn
 and $bioassaydimension->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bioassaydimension->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bioassaydimension->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bioassaydimension->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bioassaydimension->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bioassaydimension->setDescriptions([])};
ok((!$@ and defined $bioassaydimension->getDescriptions()
    and UNIVERSAL::isa($bioassaydimension->getDescriptions, 'ARRAY')
    and scalar @{$bioassaydimension->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bioassaydimension->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bioassaydimension->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bioassaydimension->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bioassaydimension->setDescriptions(undef)};
ok((!$@ and not defined $bioassaydimension->getDescriptions()),
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


isa_ok($bioassaydimension->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bioassaydimension->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bioassaydimension->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bioassaydimension->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bioassaydimension->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bioassaydimension->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bioassaydimension->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bioassaydimension->setSecurity(undef)};
ok((!$@ and not defined $bioassaydimension->getSecurity()),
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


ok((UNIVERSAL::isa($bioassaydimension->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydimension->getAuditTrail} == 1
 and UNIVERSAL::isa($bioassaydimension->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bioassaydimension->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bioassaydimension->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydimension->getAuditTrail} == 1
 and $bioassaydimension->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bioassaydimension->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bioassaydimension->getAuditTrail,'ARRAY')
 and scalar @{$bioassaydimension->getAuditTrail} == 2
 and $bioassaydimension->getAuditTrail->[0] == $audittrail_assn
 and $bioassaydimension->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bioassaydimension->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bioassaydimension->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bioassaydimension->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bioassaydimension->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bioassaydimension->setAuditTrail([])};
ok((!$@ and defined $bioassaydimension->getAuditTrail()
    and UNIVERSAL::isa($bioassaydimension->getAuditTrail, 'ARRAY')
    and scalar @{$bioassaydimension->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bioassaydimension->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bioassaydimension->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bioassaydimension->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bioassaydimension->setAuditTrail(undef)};
ok((!$@ and not defined $bioassaydimension->getAuditTrail()),
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


ok((UNIVERSAL::isa($bioassaydimension->getPropertySets,'ARRAY')
 and scalar @{$bioassaydimension->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaydimension->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaydimension->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaydimension->getPropertySets,'ARRAY')
 and scalar @{$bioassaydimension->getPropertySets} == 1
 and $bioassaydimension->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaydimension->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaydimension->getPropertySets,'ARRAY')
 and scalar @{$bioassaydimension->getPropertySets} == 2
 and $bioassaydimension->getPropertySets->[0] == $propertysets_assn
 and $bioassaydimension->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaydimension->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaydimension->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaydimension->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaydimension->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaydimension->setPropertySets([])};
ok((!$@ and defined $bioassaydimension->getPropertySets()
    and UNIVERSAL::isa($bioassaydimension->getPropertySets, 'ARRAY')
    and scalar @{$bioassaydimension->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaydimension->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaydimension->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaydimension->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaydimension->setPropertySets(undef)};
ok((!$@ and not defined $bioassaydimension->getPropertySets()),
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





my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($bioassaydimension, q[Bio::MAGE::Identifiable]);

