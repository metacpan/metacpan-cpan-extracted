##############################
#
# Compound.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Compound.t`

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
use Test::More tests => 145;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioMaterial::Compound') };

use Bio::MAGE::BioMaterial::CompoundMeasurement;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::DatabaseEntry;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::OntologyEntry;


# we test the new() method
my $compound;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compound = Bio::MAGE::BioMaterial::Compound->new();
}
isa_ok($compound, 'Bio::MAGE::BioMaterial::Compound');

# test the package_name class method
is($compound->package_name(), q[BioMaterial],
  'package');

# test the class_name class method
is($compound->class_name(), q[Bio::MAGE::BioMaterial::Compound],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compound = Bio::MAGE::BioMaterial::Compound->new(identifier => '1',
name => '2',
isSolvent => '3');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($compound->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$compound->setIdentifier('1');
is($compound->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$compound->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$compound->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compound->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$compound->setIdentifier(undef)};
ok((!$@ and not defined $compound->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($compound->getName(), '2',
  'name new');

# test getter/setter
$compound->setName('2');
is($compound->getName(), '2',
  'name getter/setter');

# test getter throws exception with argument
eval {$compound->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$compound->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compound->setName('2', '2')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$compound->setName(undef)};
ok((!$@ and not defined $compound->getName()),
   'name setter accepts undef');



#
# testing attribute isSolvent
#

# test attribute values can be set in new()
is($compound->getIsSolvent(), '3',
  'isSolvent new');

# test getter/setter
$compound->setIsSolvent('3');
is($compound->getIsSolvent(), '3',
  'isSolvent getter/setter');

# test getter throws exception with argument
eval {$compound->getIsSolvent(1)};
ok($@, 'isSolvent getter throws exception with argument');

# test setter throws exception with no argument
eval {$compound->setIsSolvent()};
ok($@, 'isSolvent setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$compound->setIsSolvent('3', '3')};
ok($@, 'isSolvent setter throws exception with too many argument');

# test setter accepts undef
eval {$compound->setIsSolvent(undef)};
ok((!$@ and not defined $compound->getIsSolvent()),
   'isSolvent setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioMaterial::Compound->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compound = Bio::MAGE::BioMaterial::Compound->new(compoundIndices => [Bio::MAGE::Description::OntologyEntry->new()],
componentCompounds => [Bio::MAGE::BioMaterial::CompoundMeasurement->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
externalLIMS => Bio::MAGE::Description::DatabaseEntry->new(),
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association compoundIndices
my $compoundindices_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $compoundindices_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($compound->getCompoundIndices,'ARRAY')
 and scalar @{$compound->getCompoundIndices} == 1
 and UNIVERSAL::isa($compound->getCompoundIndices->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'compoundIndices set in new()');

ok(eq_array($compound->setCompoundIndices([$compoundindices_assn]), [$compoundindices_assn]),
   'setCompoundIndices returns correct value');

ok((UNIVERSAL::isa($compound->getCompoundIndices,'ARRAY')
 and scalar @{$compound->getCompoundIndices} == 1
 and $compound->getCompoundIndices->[0] == $compoundindices_assn),
   'getCompoundIndices fetches correct value');

is($compound->addCompoundIndices($compoundindices_assn), 2,
  'addCompoundIndices returns number of items in list');

ok((UNIVERSAL::isa($compound->getCompoundIndices,'ARRAY')
 and scalar @{$compound->getCompoundIndices} == 2
 and $compound->getCompoundIndices->[0] == $compoundindices_assn
 and $compound->getCompoundIndices->[1] == $compoundindices_assn),
  'addCompoundIndices adds correct value');

# test setCompoundIndices throws exception with non-array argument
eval {$compound->setCompoundIndices(1)};
ok($@, 'setCompoundIndices throws exception with non-array argument');

# test setCompoundIndices throws exception with bad argument array
eval {$compound->setCompoundIndices([1])};
ok($@, 'setCompoundIndices throws exception with bad argument array');

# test addCompoundIndices throws exception with no arguments
eval {$compound->addCompoundIndices()};
ok($@, 'addCompoundIndices throws exception with no arguments');

# test addCompoundIndices throws exception with bad argument
eval {$compound->addCompoundIndices(1)};
ok($@, 'addCompoundIndices throws exception with bad array');

# test setCompoundIndices accepts empty array ref
eval {$compound->setCompoundIndices([])};
ok((!$@ and defined $compound->getCompoundIndices()
    and UNIVERSAL::isa($compound->getCompoundIndices, 'ARRAY')
    and scalar @{$compound->getCompoundIndices} == 0),
   'setCompoundIndices accepts empty array ref');


# test getCompoundIndices throws exception with argument
eval {$compound->getCompoundIndices(1)};
ok($@, 'getCompoundIndices throws exception with argument');

# test setCompoundIndices throws exception with no argument
eval {$compound->setCompoundIndices()};
ok($@, 'setCompoundIndices throws exception with no argument');

# test setCompoundIndices throws exception with too many argument
eval {$compound->setCompoundIndices(1,2)};
ok($@, 'setCompoundIndices throws exception with too many argument');

# test setCompoundIndices accepts undef
eval {$compound->setCompoundIndices(undef)};
ok((!$@ and not defined $compound->getCompoundIndices()),
   'setCompoundIndices accepts undef');

# test the meta-data for the assoication
$assn = $assns{compoundIndices};
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
   'compoundIndices->other() is a valid Bio::MAGE::Association::End'
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
   'compoundIndices->self() is a valid Bio::MAGE::Association::End'
  );



# testing association componentCompounds
my $componentcompounds_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $componentcompounds_assn = Bio::MAGE::BioMaterial::CompoundMeasurement->new();
}


ok((UNIVERSAL::isa($compound->getComponentCompounds,'ARRAY')
 and scalar @{$compound->getComponentCompounds} == 1
 and UNIVERSAL::isa($compound->getComponentCompounds->[0], q[Bio::MAGE::BioMaterial::CompoundMeasurement])),
  'componentCompounds set in new()');

ok(eq_array($compound->setComponentCompounds([$componentcompounds_assn]), [$componentcompounds_assn]),
   'setComponentCompounds returns correct value');

ok((UNIVERSAL::isa($compound->getComponentCompounds,'ARRAY')
 and scalar @{$compound->getComponentCompounds} == 1
 and $compound->getComponentCompounds->[0] == $componentcompounds_assn),
   'getComponentCompounds fetches correct value');

is($compound->addComponentCompounds($componentcompounds_assn), 2,
  'addComponentCompounds returns number of items in list');

ok((UNIVERSAL::isa($compound->getComponentCompounds,'ARRAY')
 and scalar @{$compound->getComponentCompounds} == 2
 and $compound->getComponentCompounds->[0] == $componentcompounds_assn
 and $compound->getComponentCompounds->[1] == $componentcompounds_assn),
  'addComponentCompounds adds correct value');

# test setComponentCompounds throws exception with non-array argument
eval {$compound->setComponentCompounds(1)};
ok($@, 'setComponentCompounds throws exception with non-array argument');

# test setComponentCompounds throws exception with bad argument array
eval {$compound->setComponentCompounds([1])};
ok($@, 'setComponentCompounds throws exception with bad argument array');

# test addComponentCompounds throws exception with no arguments
eval {$compound->addComponentCompounds()};
ok($@, 'addComponentCompounds throws exception with no arguments');

# test addComponentCompounds throws exception with bad argument
eval {$compound->addComponentCompounds(1)};
ok($@, 'addComponentCompounds throws exception with bad array');

# test setComponentCompounds accepts empty array ref
eval {$compound->setComponentCompounds([])};
ok((!$@ and defined $compound->getComponentCompounds()
    and UNIVERSAL::isa($compound->getComponentCompounds, 'ARRAY')
    and scalar @{$compound->getComponentCompounds} == 0),
   'setComponentCompounds accepts empty array ref');


# test getComponentCompounds throws exception with argument
eval {$compound->getComponentCompounds(1)};
ok($@, 'getComponentCompounds throws exception with argument');

# test setComponentCompounds throws exception with no argument
eval {$compound->setComponentCompounds()};
ok($@, 'setComponentCompounds throws exception with no argument');

# test setComponentCompounds throws exception with too many argument
eval {$compound->setComponentCompounds(1,2)};
ok($@, 'setComponentCompounds throws exception with too many argument');

# test setComponentCompounds accepts undef
eval {$compound->setComponentCompounds(undef)};
ok((!$@ and not defined $compound->getComponentCompounds()),
   'setComponentCompounds accepts undef');

# test the meta-data for the assoication
$assn = $assns{componentCompounds};
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
   'componentCompounds->other() is a valid Bio::MAGE::Association::End'
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
   'componentCompounds->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($compound->getDescriptions,'ARRAY')
 and scalar @{$compound->getDescriptions} == 1
 and UNIVERSAL::isa($compound->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($compound->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($compound->getDescriptions,'ARRAY')
 and scalar @{$compound->getDescriptions} == 1
 and $compound->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($compound->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($compound->getDescriptions,'ARRAY')
 and scalar @{$compound->getDescriptions} == 2
 and $compound->getDescriptions->[0] == $descriptions_assn
 and $compound->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$compound->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$compound->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$compound->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$compound->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$compound->setDescriptions([])};
ok((!$@ and defined $compound->getDescriptions()
    and UNIVERSAL::isa($compound->getDescriptions, 'ARRAY')
    and scalar @{$compound->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$compound->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$compound->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$compound->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$compound->setDescriptions(undef)};
ok((!$@ and not defined $compound->getDescriptions()),
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



# testing association externalLIMS
my $externallims_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $externallims_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


isa_ok($compound->getExternalLIMS, q[Bio::MAGE::Description::DatabaseEntry]);

is($compound->setExternalLIMS($externallims_assn), $externallims_assn,
  'setExternalLIMS returns value');

ok($compound->getExternalLIMS() == $externallims_assn,
   'getExternalLIMS fetches correct value');

# test setExternalLIMS throws exception with bad argument
eval {$compound->setExternalLIMS(1)};
ok($@, 'setExternalLIMS throws exception with bad argument');


# test getExternalLIMS throws exception with argument
eval {$compound->getExternalLIMS(1)};
ok($@, 'getExternalLIMS throws exception with argument');

# test setExternalLIMS throws exception with no argument
eval {$compound->setExternalLIMS()};
ok($@, 'setExternalLIMS throws exception with no argument');

# test setExternalLIMS throws exception with too many argument
eval {$compound->setExternalLIMS(1,2)};
ok($@, 'setExternalLIMS throws exception with too many argument');

# test setExternalLIMS accepts undef
eval {$compound->setExternalLIMS(undef)};
ok((!$@ and not defined $compound->getExternalLIMS()),
   'setExternalLIMS accepts undef');

# test the meta-data for the assoication
$assn = $assns{externalLIMS};
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
   'externalLIMS->other() is a valid Bio::MAGE::Association::End'
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
   'externalLIMS->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($compound->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($compound->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($compound->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$compound->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$compound->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$compound->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$compound->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$compound->setSecurity(undef)};
ok((!$@ and not defined $compound->getSecurity()),
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


ok((UNIVERSAL::isa($compound->getAuditTrail,'ARRAY')
 and scalar @{$compound->getAuditTrail} == 1
 and UNIVERSAL::isa($compound->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($compound->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($compound->getAuditTrail,'ARRAY')
 and scalar @{$compound->getAuditTrail} == 1
 and $compound->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($compound->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($compound->getAuditTrail,'ARRAY')
 and scalar @{$compound->getAuditTrail} == 2
 and $compound->getAuditTrail->[0] == $audittrail_assn
 and $compound->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$compound->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$compound->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$compound->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$compound->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$compound->setAuditTrail([])};
ok((!$@ and defined $compound->getAuditTrail()
    and UNIVERSAL::isa($compound->getAuditTrail, 'ARRAY')
    and scalar @{$compound->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$compound->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$compound->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$compound->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$compound->setAuditTrail(undef)};
ok((!$@ and not defined $compound->getAuditTrail()),
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


ok((UNIVERSAL::isa($compound->getPropertySets,'ARRAY')
 and scalar @{$compound->getPropertySets} == 1
 and UNIVERSAL::isa($compound->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($compound->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($compound->getPropertySets,'ARRAY')
 and scalar @{$compound->getPropertySets} == 1
 and $compound->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($compound->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($compound->getPropertySets,'ARRAY')
 and scalar @{$compound->getPropertySets} == 2
 and $compound->getPropertySets->[0] == $propertysets_assn
 and $compound->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$compound->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$compound->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$compound->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$compound->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$compound->setPropertySets([])};
ok((!$@ and defined $compound->getPropertySets()
    and UNIVERSAL::isa($compound->getPropertySets, 'ARRAY')
    and scalar @{$compound->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$compound->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$compound->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$compound->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$compound->setPropertySets(undef)};
ok((!$@ and not defined $compound->getPropertySets()),
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
isa_ok($compound, q[Bio::MAGE::Identifiable]);

