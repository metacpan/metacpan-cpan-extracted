##############################
#
# ParameterizableApplication.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ParameterizableApplication.t`

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
use Test::More tests => 101;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::ParameterizableApplication') };

use Bio::MAGE::Protocol::ParameterValue;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;

use Bio::MAGE::Protocol::ProtocolApplication;
use Bio::MAGE::Protocol::HardwareApplication;
use Bio::MAGE::Protocol::SoftwareApplication;

# we test the new() method
my $parameterizableapplication;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new();
}
isa_ok($parameterizableapplication, 'Bio::MAGE::Protocol::ParameterizableApplication');

# test the package_name class method
is($parameterizableapplication->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($parameterizableapplication->class_name(), q[Bio::MAGE::Protocol::ParameterizableApplication],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::ParameterizableApplication->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new(descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
parameterValues => [Bio::MAGE::Protocol::ParameterValue->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($parameterizableapplication->getDescriptions,'ARRAY')
 and scalar @{$parameterizableapplication->getDescriptions} == 1
 and UNIVERSAL::isa($parameterizableapplication->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($parameterizableapplication->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($parameterizableapplication->getDescriptions,'ARRAY')
 and scalar @{$parameterizableapplication->getDescriptions} == 1
 and $parameterizableapplication->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($parameterizableapplication->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($parameterizableapplication->getDescriptions,'ARRAY')
 and scalar @{$parameterizableapplication->getDescriptions} == 2
 and $parameterizableapplication->getDescriptions->[0] == $descriptions_assn
 and $parameterizableapplication->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$parameterizableapplication->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$parameterizableapplication->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$parameterizableapplication->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$parameterizableapplication->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$parameterizableapplication->setDescriptions([])};
ok((!$@ and defined $parameterizableapplication->getDescriptions()
    and UNIVERSAL::isa($parameterizableapplication->getDescriptions, 'ARRAY')
    and scalar @{$parameterizableapplication->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$parameterizableapplication->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$parameterizableapplication->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$parameterizableapplication->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$parameterizableapplication->setDescriptions(undef)};
ok((!$@ and not defined $parameterizableapplication->getDescriptions()),
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


ok((UNIVERSAL::isa($parameterizableapplication->getAuditTrail,'ARRAY')
 and scalar @{$parameterizableapplication->getAuditTrail} == 1
 and UNIVERSAL::isa($parameterizableapplication->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($parameterizableapplication->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($parameterizableapplication->getAuditTrail,'ARRAY')
 and scalar @{$parameterizableapplication->getAuditTrail} == 1
 and $parameterizableapplication->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($parameterizableapplication->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($parameterizableapplication->getAuditTrail,'ARRAY')
 and scalar @{$parameterizableapplication->getAuditTrail} == 2
 and $parameterizableapplication->getAuditTrail->[0] == $audittrail_assn
 and $parameterizableapplication->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$parameterizableapplication->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$parameterizableapplication->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$parameterizableapplication->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$parameterizableapplication->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$parameterizableapplication->setAuditTrail([])};
ok((!$@ and defined $parameterizableapplication->getAuditTrail()
    and UNIVERSAL::isa($parameterizableapplication->getAuditTrail, 'ARRAY')
    and scalar @{$parameterizableapplication->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$parameterizableapplication->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$parameterizableapplication->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$parameterizableapplication->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$parameterizableapplication->setAuditTrail(undef)};
ok((!$@ and not defined $parameterizableapplication->getAuditTrail()),
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


isa_ok($parameterizableapplication->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($parameterizableapplication->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($parameterizableapplication->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$parameterizableapplication->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$parameterizableapplication->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$parameterizableapplication->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$parameterizableapplication->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$parameterizableapplication->setSecurity(undef)};
ok((!$@ and not defined $parameterizableapplication->getSecurity()),
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


ok((UNIVERSAL::isa($parameterizableapplication->getPropertySets,'ARRAY')
 and scalar @{$parameterizableapplication->getPropertySets} == 1
 and UNIVERSAL::isa($parameterizableapplication->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($parameterizableapplication->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($parameterizableapplication->getPropertySets,'ARRAY')
 and scalar @{$parameterizableapplication->getPropertySets} == 1
 and $parameterizableapplication->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($parameterizableapplication->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($parameterizableapplication->getPropertySets,'ARRAY')
 and scalar @{$parameterizableapplication->getPropertySets} == 2
 and $parameterizableapplication->getPropertySets->[0] == $propertysets_assn
 and $parameterizableapplication->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$parameterizableapplication->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$parameterizableapplication->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$parameterizableapplication->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$parameterizableapplication->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$parameterizableapplication->setPropertySets([])};
ok((!$@ and defined $parameterizableapplication->getPropertySets()
    and UNIVERSAL::isa($parameterizableapplication->getPropertySets, 'ARRAY')
    and scalar @{$parameterizableapplication->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$parameterizableapplication->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$parameterizableapplication->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$parameterizableapplication->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$parameterizableapplication->setPropertySets(undef)};
ok((!$@ and not defined $parameterizableapplication->getPropertySets()),
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


ok((UNIVERSAL::isa($parameterizableapplication->getParameterValues,'ARRAY')
 and scalar @{$parameterizableapplication->getParameterValues} == 1
 and UNIVERSAL::isa($parameterizableapplication->getParameterValues->[0], q[Bio::MAGE::Protocol::ParameterValue])),
  'parameterValues set in new()');

ok(eq_array($parameterizableapplication->setParameterValues([$parametervalues_assn]), [$parametervalues_assn]),
   'setParameterValues returns correct value');

ok((UNIVERSAL::isa($parameterizableapplication->getParameterValues,'ARRAY')
 and scalar @{$parameterizableapplication->getParameterValues} == 1
 and $parameterizableapplication->getParameterValues->[0] == $parametervalues_assn),
   'getParameterValues fetches correct value');

is($parameterizableapplication->addParameterValues($parametervalues_assn), 2,
  'addParameterValues returns number of items in list');

ok((UNIVERSAL::isa($parameterizableapplication->getParameterValues,'ARRAY')
 and scalar @{$parameterizableapplication->getParameterValues} == 2
 and $parameterizableapplication->getParameterValues->[0] == $parametervalues_assn
 and $parameterizableapplication->getParameterValues->[1] == $parametervalues_assn),
  'addParameterValues adds correct value');

# test setParameterValues throws exception with non-array argument
eval {$parameterizableapplication->setParameterValues(1)};
ok($@, 'setParameterValues throws exception with non-array argument');

# test setParameterValues throws exception with bad argument array
eval {$parameterizableapplication->setParameterValues([1])};
ok($@, 'setParameterValues throws exception with bad argument array');

# test addParameterValues throws exception with no arguments
eval {$parameterizableapplication->addParameterValues()};
ok($@, 'addParameterValues throws exception with no arguments');

# test addParameterValues throws exception with bad argument
eval {$parameterizableapplication->addParameterValues(1)};
ok($@, 'addParameterValues throws exception with bad array');

# test setParameterValues accepts empty array ref
eval {$parameterizableapplication->setParameterValues([])};
ok((!$@ and defined $parameterizableapplication->getParameterValues()
    and UNIVERSAL::isa($parameterizableapplication->getParameterValues, 'ARRAY')
    and scalar @{$parameterizableapplication->getParameterValues} == 0),
   'setParameterValues accepts empty array ref');


# test getParameterValues throws exception with argument
eval {$parameterizableapplication->getParameterValues(1)};
ok($@, 'getParameterValues throws exception with argument');

# test setParameterValues throws exception with no argument
eval {$parameterizableapplication->setParameterValues()};
ok($@, 'setParameterValues throws exception with no argument');

# test setParameterValues throws exception with too many argument
eval {$parameterizableapplication->setParameterValues(1,2)};
ok($@, 'setParameterValues throws exception with too many argument');

# test setParameterValues accepts undef
eval {$parameterizableapplication->setParameterValues(undef)};
ok((!$@ and not defined $parameterizableapplication->getParameterValues()),
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




# create a subclass
my $protocolapplication = Bio::MAGE::Protocol::ProtocolApplication->new();

# testing subclass ProtocolApplication
isa_ok($protocolapplication, q[Bio::MAGE::Protocol::ProtocolApplication]);
isa_ok($protocolapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);


# create a subclass
my $hardwareapplication = Bio::MAGE::Protocol::HardwareApplication->new();

# testing subclass HardwareApplication
isa_ok($hardwareapplication, q[Bio::MAGE::Protocol::HardwareApplication]);
isa_ok($hardwareapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);


# create a subclass
my $softwareapplication = Bio::MAGE::Protocol::SoftwareApplication->new();

# testing subclass SoftwareApplication
isa_ok($softwareapplication, q[Bio::MAGE::Protocol::SoftwareApplication]);
isa_ok($softwareapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);



my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $describable = Bio::MAGE::Describable->new();
}

# testing superclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($parameterizableapplication, q[Bio::MAGE::Describable]);

