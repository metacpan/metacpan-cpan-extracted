##############################
#
# SoftwareApplication.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SoftwareApplication.t`

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

BEGIN { use_ok('Bio::MAGE::Protocol::SoftwareApplication') };

use Bio::MAGE::Protocol::Software;
use Bio::MAGE::Protocol::ParameterValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $softwareapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwareapplication = Bio::MAGE::Protocol::SoftwareApplication->new();
}
isa_ok($softwareapplication, 'Bio::MAGE::Protocol::SoftwareApplication');

# test the package_name class method
is($softwareapplication->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($softwareapplication->class_name(), q[Bio::MAGE::Protocol::SoftwareApplication],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwareapplication = Bio::MAGE::Protocol::SoftwareApplication->new(releaseDate => '1',
version => '2');
}


#
# testing attribute releaseDate
#

# test attribute values can be set in new()
is($softwareapplication->getReleaseDate(), '1',
  'releaseDate new');

# test getter/setter
$softwareapplication->setReleaseDate('1');
is($softwareapplication->getReleaseDate(), '1',
  'releaseDate getter/setter');

# test getter throws exception with argument
eval {$softwareapplication->getReleaseDate(1)};
ok($@, 'releaseDate getter throws exception with argument');

# test setter throws exception with no argument
eval {$softwareapplication->setReleaseDate()};
ok($@, 'releaseDate setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$softwareapplication->setReleaseDate('1', '1')};
ok($@, 'releaseDate setter throws exception with too many argument');

# test setter accepts undef
eval {$softwareapplication->setReleaseDate(undef)};
ok((!$@ and not defined $softwareapplication->getReleaseDate()),
   'releaseDate setter accepts undef');



#
# testing attribute version
#

# test attribute values can be set in new()
is($softwareapplication->getVersion(), '2',
  'version new');

# test getter/setter
$softwareapplication->setVersion('2');
is($softwareapplication->getVersion(), '2',
  'version getter/setter');

# test getter throws exception with argument
eval {$softwareapplication->getVersion(1)};
ok($@, 'version getter throws exception with argument');

# test setter throws exception with no argument
eval {$softwareapplication->setVersion()};
ok($@, 'version setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$softwareapplication->setVersion('2', '2')};
ok($@, 'version setter throws exception with too many argument');

# test setter accepts undef
eval {$softwareapplication->setVersion(undef)};
ok((!$@ and not defined $softwareapplication->getVersion()),
   'version setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::SoftwareApplication->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwareapplication = Bio::MAGE::Protocol::SoftwareApplication->new(software => Bio::MAGE::Protocol::Software->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
parameterValues => [Bio::MAGE::Protocol::ParameterValue->new()]);
}

my ($end, $assn);


# testing association software
my $software_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $software_assn = Bio::MAGE::Protocol::Software->new();
}


isa_ok($softwareapplication->getSoftware, q[Bio::MAGE::Protocol::Software]);

is($softwareapplication->setSoftware($software_assn), $software_assn,
  'setSoftware returns value');

ok($softwareapplication->getSoftware() == $software_assn,
   'getSoftware fetches correct value');

# test setSoftware throws exception with bad argument
eval {$softwareapplication->setSoftware(1)};
ok($@, 'setSoftware throws exception with bad argument');


# test getSoftware throws exception with argument
eval {$softwareapplication->getSoftware(1)};
ok($@, 'getSoftware throws exception with argument');

# test setSoftware throws exception with no argument
eval {$softwareapplication->setSoftware()};
ok($@, 'setSoftware throws exception with no argument');

# test setSoftware throws exception with too many argument
eval {$softwareapplication->setSoftware(1,2)};
ok($@, 'setSoftware throws exception with too many argument');

# test setSoftware accepts undef
eval {$softwareapplication->setSoftware(undef)};
ok((!$@ and not defined $softwareapplication->getSoftware()),
   'setSoftware accepts undef');

# test the meta-data for the assoication
$assn = $assns{software};
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
   'software->other() is a valid Bio::MAGE::Association::End'
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
   'software->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($softwareapplication->getDescriptions,'ARRAY')
 and scalar @{$softwareapplication->getDescriptions} == 1
 and UNIVERSAL::isa($softwareapplication->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($softwareapplication->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($softwareapplication->getDescriptions,'ARRAY')
 and scalar @{$softwareapplication->getDescriptions} == 1
 and $softwareapplication->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($softwareapplication->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($softwareapplication->getDescriptions,'ARRAY')
 and scalar @{$softwareapplication->getDescriptions} == 2
 and $softwareapplication->getDescriptions->[0] == $descriptions_assn
 and $softwareapplication->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$softwareapplication->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$softwareapplication->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$softwareapplication->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$softwareapplication->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$softwareapplication->setDescriptions([])};
ok((!$@ and defined $softwareapplication->getDescriptions()
    and UNIVERSAL::isa($softwareapplication->getDescriptions, 'ARRAY')
    and scalar @{$softwareapplication->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$softwareapplication->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$softwareapplication->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$softwareapplication->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$softwareapplication->setDescriptions(undef)};
ok((!$@ and not defined $softwareapplication->getDescriptions()),
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


isa_ok($softwareapplication->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($softwareapplication->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($softwareapplication->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$softwareapplication->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$softwareapplication->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$softwareapplication->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$softwareapplication->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$softwareapplication->setSecurity(undef)};
ok((!$@ and not defined $softwareapplication->getSecurity()),
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


ok((UNIVERSAL::isa($softwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$softwareapplication->getAuditTrail} == 1
 and UNIVERSAL::isa($softwareapplication->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($softwareapplication->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($softwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$softwareapplication->getAuditTrail} == 1
 and $softwareapplication->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($softwareapplication->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($softwareapplication->getAuditTrail,'ARRAY')
 and scalar @{$softwareapplication->getAuditTrail} == 2
 and $softwareapplication->getAuditTrail->[0] == $audittrail_assn
 and $softwareapplication->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$softwareapplication->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$softwareapplication->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$softwareapplication->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$softwareapplication->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$softwareapplication->setAuditTrail([])};
ok((!$@ and defined $softwareapplication->getAuditTrail()
    and UNIVERSAL::isa($softwareapplication->getAuditTrail, 'ARRAY')
    and scalar @{$softwareapplication->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$softwareapplication->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$softwareapplication->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$softwareapplication->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$softwareapplication->setAuditTrail(undef)};
ok((!$@ and not defined $softwareapplication->getAuditTrail()),
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


ok((UNIVERSAL::isa($softwareapplication->getPropertySets,'ARRAY')
 and scalar @{$softwareapplication->getPropertySets} == 1
 and UNIVERSAL::isa($softwareapplication->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($softwareapplication->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($softwareapplication->getPropertySets,'ARRAY')
 and scalar @{$softwareapplication->getPropertySets} == 1
 and $softwareapplication->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($softwareapplication->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($softwareapplication->getPropertySets,'ARRAY')
 and scalar @{$softwareapplication->getPropertySets} == 2
 and $softwareapplication->getPropertySets->[0] == $propertysets_assn
 and $softwareapplication->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$softwareapplication->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$softwareapplication->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$softwareapplication->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$softwareapplication->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$softwareapplication->setPropertySets([])};
ok((!$@ and defined $softwareapplication->getPropertySets()
    and UNIVERSAL::isa($softwareapplication->getPropertySets, 'ARRAY')
    and scalar @{$softwareapplication->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$softwareapplication->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$softwareapplication->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$softwareapplication->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$softwareapplication->setPropertySets(undef)};
ok((!$@ and not defined $softwareapplication->getPropertySets()),
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



# testing association parameterValues
my $parametervalues_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametervalues_assn = Bio::MAGE::Protocol::ParameterValue->new();
}


ok((UNIVERSAL::isa($softwareapplication->getParameterValues,'ARRAY')
 and scalar @{$softwareapplication->getParameterValues} == 1
 and UNIVERSAL::isa($softwareapplication->getParameterValues->[0], q[Bio::MAGE::Protocol::ParameterValue])),
  'parameterValues set in new()');

ok(eq_array($softwareapplication->setParameterValues([$parametervalues_assn]), [$parametervalues_assn]),
   'setParameterValues returns correct value');

ok((UNIVERSAL::isa($softwareapplication->getParameterValues,'ARRAY')
 and scalar @{$softwareapplication->getParameterValues} == 1
 and $softwareapplication->getParameterValues->[0] == $parametervalues_assn),
   'getParameterValues fetches correct value');

is($softwareapplication->addParameterValues($parametervalues_assn), 2,
  'addParameterValues returns number of items in list');

ok((UNIVERSAL::isa($softwareapplication->getParameterValues,'ARRAY')
 and scalar @{$softwareapplication->getParameterValues} == 2
 and $softwareapplication->getParameterValues->[0] == $parametervalues_assn
 and $softwareapplication->getParameterValues->[1] == $parametervalues_assn),
  'addParameterValues adds correct value');

# test setParameterValues throws exception with non-array argument
eval {$softwareapplication->setParameterValues(1)};
ok($@, 'setParameterValues throws exception with non-array argument');

# test setParameterValues throws exception with bad argument array
eval {$softwareapplication->setParameterValues([1])};
ok($@, 'setParameterValues throws exception with bad argument array');

# test addParameterValues throws exception with no arguments
eval {$softwareapplication->addParameterValues()};
ok($@, 'addParameterValues throws exception with no arguments');

# test addParameterValues throws exception with bad argument
eval {$softwareapplication->addParameterValues(1)};
ok($@, 'addParameterValues throws exception with bad array');

# test setParameterValues accepts empty array ref
eval {$softwareapplication->setParameterValues([])};
ok((!$@ and defined $softwareapplication->getParameterValues()
    and UNIVERSAL::isa($softwareapplication->getParameterValues, 'ARRAY')
    and scalar @{$softwareapplication->getParameterValues} == 0),
   'setParameterValues accepts empty array ref');


# test getParameterValues throws exception with argument
eval {$softwareapplication->getParameterValues(1)};
ok($@, 'getParameterValues throws exception with argument');

# test setParameterValues throws exception with no argument
eval {$softwareapplication->setParameterValues()};
ok($@, 'setParameterValues throws exception with no argument');

# test setParameterValues throws exception with too many argument
eval {$softwareapplication->setParameterValues(1,2)};
ok($@, 'setParameterValues throws exception with too many argument');

# test setParameterValues accepts undef
eval {$softwareapplication->setParameterValues(undef)};
ok((!$@ and not defined $softwareapplication->getParameterValues()),
   'setParameterValues accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameterValues};
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
   'parameterValues->other() is a valid Bio::MAGE::Association::End'
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
   'parameterValues->self() is a valid Bio::MAGE::Association::End'
  );





my $parameterizableapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new();
}

# testing superclass ParameterizableApplication
isa_ok($parameterizableapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);
isa_ok($softwareapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);

