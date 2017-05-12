##############################
#
# SeqFeature.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SeqFeature.t`

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

BEGIN { use_ok('Bio::MAGE::BioSequence::SeqFeature') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::BioSequence::SeqFeatureLocation;


# we test the new() method
my $seqfeature;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeature = Bio::MAGE::BioSequence::SeqFeature->new();
}
isa_ok($seqfeature, 'Bio::MAGE::BioSequence::SeqFeature');

# test the package_name class method
is($seqfeature->package_name(), q[BioSequence],
  'package');

# test the class_name class method
is($seqfeature->class_name(), q[Bio::MAGE::BioSequence::SeqFeature],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeature = Bio::MAGE::BioSequence::SeqFeature->new(basis => 'experimental');
}


#
# testing attribute basis
#

# test attribute values can be set in new()
is($seqfeature->getBasis(), 'experimental',
  'basis new');

# test getter/setter
$seqfeature->setBasis('experimental');
is($seqfeature->getBasis(), 'experimental',
  'basis getter/setter');

# test getter throws exception with argument
eval {$seqfeature->getBasis(1)};
ok($@, 'basis getter throws exception with argument');

# test setter throws exception with no argument
eval {$seqfeature->setBasis()};
ok($@, 'basis setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$seqfeature->setBasis('experimental', 'experimental')};
ok($@, 'basis setter throws exception with too many argument');

# test setter accepts undef
eval {$seqfeature->setBasis(undef)};
ok((!$@ and not defined $seqfeature->getBasis()),
   'basis setter accepts undef');


# test setter throws exception with bad argument
eval {$seqfeature->setBasis(1)};
ok($@, 'basis setter throws exception with bad argument');


# test setter accepts enumerated value: experimental

eval {$seqfeature->setBasis('experimental')};
ok((not $@ and $seqfeature->getBasis() eq 'experimental'),
   'basis accepts experimental');


# test setter accepts enumerated value: computational

eval {$seqfeature->setBasis('computational')};
ok((not $@ and $seqfeature->getBasis() eq 'computational'),
   'basis accepts computational');


# test setter accepts enumerated value: both

eval {$seqfeature->setBasis('both')};
ok((not $@ and $seqfeature->getBasis() eq 'both'),
   'basis accepts both');


# test setter accepts enumerated value: unknown

eval {$seqfeature->setBasis('unknown')};
ok((not $@ and $seqfeature->getBasis() eq 'unknown'),
   'basis accepts unknown');


# test setter accepts enumerated value: NA

eval {$seqfeature->setBasis('NA')};
ok((not $@ and $seqfeature->getBasis() eq 'NA'),
   'basis accepts NA');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioSequence::SeqFeature->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $seqfeature = Bio::MAGE::BioSequence::SeqFeature->new(regions => [Bio::MAGE::BioSequence::SeqFeatureLocation->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association regions
my $regions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $regions_assn = Bio::MAGE::BioSequence::SeqFeatureLocation->new();
}


ok((UNIVERSAL::isa($seqfeature->getRegions,'ARRAY')
 and scalar @{$seqfeature->getRegions} == 1
 and UNIVERSAL::isa($seqfeature->getRegions->[0], q[Bio::MAGE::BioSequence::SeqFeatureLocation])),
  'regions set in new()');

ok(eq_array($seqfeature->setRegions([$regions_assn]), [$regions_assn]),
   'setRegions returns correct value');

ok((UNIVERSAL::isa($seqfeature->getRegions,'ARRAY')
 and scalar @{$seqfeature->getRegions} == 1
 and $seqfeature->getRegions->[0] == $regions_assn),
   'getRegions fetches correct value');

is($seqfeature->addRegions($regions_assn), 2,
  'addRegions returns number of items in list');

ok((UNIVERSAL::isa($seqfeature->getRegions,'ARRAY')
 and scalar @{$seqfeature->getRegions} == 2
 and $seqfeature->getRegions->[0] == $regions_assn
 and $seqfeature->getRegions->[1] == $regions_assn),
  'addRegions adds correct value');

# test setRegions throws exception with non-array argument
eval {$seqfeature->setRegions(1)};
ok($@, 'setRegions throws exception with non-array argument');

# test setRegions throws exception with bad argument array
eval {$seqfeature->setRegions([1])};
ok($@, 'setRegions throws exception with bad argument array');

# test addRegions throws exception with no arguments
eval {$seqfeature->addRegions()};
ok($@, 'addRegions throws exception with no arguments');

# test addRegions throws exception with bad argument
eval {$seqfeature->addRegions(1)};
ok($@, 'addRegions throws exception with bad array');

# test setRegions accepts empty array ref
eval {$seqfeature->setRegions([])};
ok((!$@ and defined $seqfeature->getRegions()
    and UNIVERSAL::isa($seqfeature->getRegions, 'ARRAY')
    and scalar @{$seqfeature->getRegions} == 0),
   'setRegions accepts empty array ref');


# test getRegions throws exception with argument
eval {$seqfeature->getRegions(1)};
ok($@, 'getRegions throws exception with argument');

# test setRegions throws exception with no argument
eval {$seqfeature->setRegions()};
ok($@, 'setRegions throws exception with no argument');

# test setRegions throws exception with too many argument
eval {$seqfeature->setRegions(1,2)};
ok($@, 'setRegions throws exception with too many argument');

# test setRegions accepts undef
eval {$seqfeature->setRegions(undef)};
ok((!$@ and not defined $seqfeature->getRegions()),
   'setRegions accepts undef');

# test the meta-data for the assoication
$assn = $assns{regions};
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
   'regions->other() is a valid Bio::MAGE::Association::End'
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
   'regions->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($seqfeature->getDescriptions,'ARRAY')
 and scalar @{$seqfeature->getDescriptions} == 1
 and UNIVERSAL::isa($seqfeature->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($seqfeature->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($seqfeature->getDescriptions,'ARRAY')
 and scalar @{$seqfeature->getDescriptions} == 1
 and $seqfeature->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($seqfeature->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($seqfeature->getDescriptions,'ARRAY')
 and scalar @{$seqfeature->getDescriptions} == 2
 and $seqfeature->getDescriptions->[0] == $descriptions_assn
 and $seqfeature->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$seqfeature->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$seqfeature->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$seqfeature->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$seqfeature->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$seqfeature->setDescriptions([])};
ok((!$@ and defined $seqfeature->getDescriptions()
    and UNIVERSAL::isa($seqfeature->getDescriptions, 'ARRAY')
    and scalar @{$seqfeature->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$seqfeature->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$seqfeature->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$seqfeature->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$seqfeature->setDescriptions(undef)};
ok((!$@ and not defined $seqfeature->getDescriptions()),
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


ok((UNIVERSAL::isa($seqfeature->getAuditTrail,'ARRAY')
 and scalar @{$seqfeature->getAuditTrail} == 1
 and UNIVERSAL::isa($seqfeature->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($seqfeature->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($seqfeature->getAuditTrail,'ARRAY')
 and scalar @{$seqfeature->getAuditTrail} == 1
 and $seqfeature->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($seqfeature->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($seqfeature->getAuditTrail,'ARRAY')
 and scalar @{$seqfeature->getAuditTrail} == 2
 and $seqfeature->getAuditTrail->[0] == $audittrail_assn
 and $seqfeature->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$seqfeature->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$seqfeature->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$seqfeature->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$seqfeature->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$seqfeature->setAuditTrail([])};
ok((!$@ and defined $seqfeature->getAuditTrail()
    and UNIVERSAL::isa($seqfeature->getAuditTrail, 'ARRAY')
    and scalar @{$seqfeature->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$seqfeature->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$seqfeature->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$seqfeature->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$seqfeature->setAuditTrail(undef)};
ok((!$@ and not defined $seqfeature->getAuditTrail()),
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


isa_ok($seqfeature->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($seqfeature->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($seqfeature->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$seqfeature->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$seqfeature->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$seqfeature->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$seqfeature->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$seqfeature->setSecurity(undef)};
ok((!$@ and not defined $seqfeature->getSecurity()),
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


ok((UNIVERSAL::isa($seqfeature->getPropertySets,'ARRAY')
 and scalar @{$seqfeature->getPropertySets} == 1
 and UNIVERSAL::isa($seqfeature->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($seqfeature->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($seqfeature->getPropertySets,'ARRAY')
 and scalar @{$seqfeature->getPropertySets} == 1
 and $seqfeature->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($seqfeature->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($seqfeature->getPropertySets,'ARRAY')
 and scalar @{$seqfeature->getPropertySets} == 2
 and $seqfeature->getPropertySets->[0] == $propertysets_assn
 and $seqfeature->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$seqfeature->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$seqfeature->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$seqfeature->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$seqfeature->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$seqfeature->setPropertySets([])};
ok((!$@ and defined $seqfeature->getPropertySets()
    and UNIVERSAL::isa($seqfeature->getPropertySets, 'ARRAY')
    and scalar @{$seqfeature->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$seqfeature->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$seqfeature->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$seqfeature->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$seqfeature->setPropertySets(undef)};
ok((!$@ and not defined $seqfeature->getPropertySets()),
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
isa_ok($seqfeature, q[Bio::MAGE::Describable]);

