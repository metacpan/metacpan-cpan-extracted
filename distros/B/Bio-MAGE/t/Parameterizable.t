##############################
#
# Parameterizable.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Parameterizable.t`

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
use Test::More tests => 119;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::Parameterizable') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Protocol::Parameter;
use Bio::MAGE::Description::Description;

use Bio::MAGE::Protocol::Protocol;
use Bio::MAGE::Protocol::Software;
use Bio::MAGE::Protocol::Hardware;

# we test the new() method
my $parameterizable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizable = Bio::MAGE::Protocol::Parameterizable->new();
}
isa_ok($parameterizable, 'Bio::MAGE::Protocol::Parameterizable');

# test the package_name class method
is($parameterizable->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($parameterizable->class_name(), q[Bio::MAGE::Protocol::Parameterizable],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizable = Bio::MAGE::Protocol::Parameterizable->new(URI => '1',
identifier => '2',
name => '3');
}


#
# testing attribute URI
#

# test attribute values can be set in new()
is($parameterizable->getURI(), '1',
  'URI new');

# test getter/setter
$parameterizable->setURI('1');
is($parameterizable->getURI(), '1',
  'URI getter/setter');

# test getter throws exception with argument
eval {$parameterizable->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$parameterizable->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$parameterizable->setURI('1', '1')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$parameterizable->setURI(undef)};
ok((!$@ and not defined $parameterizable->getURI()),
   'URI setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($parameterizable->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$parameterizable->setIdentifier('2');
is($parameterizable->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$parameterizable->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$parameterizable->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$parameterizable->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$parameterizable->setIdentifier(undef)};
ok((!$@ and not defined $parameterizable->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($parameterizable->getName(), '3',
  'name new');

# test getter/setter
$parameterizable->setName('3');
is($parameterizable->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$parameterizable->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$parameterizable->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$parameterizable->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$parameterizable->setName(undef)};
ok((!$@ and not defined $parameterizable->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::Parameterizable->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameterizable = Bio::MAGE::Protocol::Parameterizable->new(parameterTypes => [Bio::MAGE::Protocol::Parameter->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association parameterTypes
my $parametertypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametertypes_assn = Bio::MAGE::Protocol::Parameter->new();
}


ok((UNIVERSAL::isa($parameterizable->getParameterTypes,'ARRAY')
 and scalar @{$parameterizable->getParameterTypes} == 1
 and UNIVERSAL::isa($parameterizable->getParameterTypes->[0], q[Bio::MAGE::Protocol::Parameter])),
  'parameterTypes set in new()');

ok(eq_array($parameterizable->setParameterTypes([$parametertypes_assn]), [$parametertypes_assn]),
   'setParameterTypes returns correct value');

ok((UNIVERSAL::isa($parameterizable->getParameterTypes,'ARRAY')
 and scalar @{$parameterizable->getParameterTypes} == 1
 and $parameterizable->getParameterTypes->[0] == $parametertypes_assn),
   'getParameterTypes fetches correct value');

is($parameterizable->addParameterTypes($parametertypes_assn), 2,
  'addParameterTypes returns number of items in list');

ok((UNIVERSAL::isa($parameterizable->getParameterTypes,'ARRAY')
 and scalar @{$parameterizable->getParameterTypes} == 2
 and $parameterizable->getParameterTypes->[0] == $parametertypes_assn
 and $parameterizable->getParameterTypes->[1] == $parametertypes_assn),
  'addParameterTypes adds correct value');

# test setParameterTypes throws exception with non-array argument
eval {$parameterizable->setParameterTypes(1)};
ok($@, 'setParameterTypes throws exception with non-array argument');

# test setParameterTypes throws exception with bad argument array
eval {$parameterizable->setParameterTypes([1])};
ok($@, 'setParameterTypes throws exception with bad argument array');

# test addParameterTypes throws exception with no arguments
eval {$parameterizable->addParameterTypes()};
ok($@, 'addParameterTypes throws exception with no arguments');

# test addParameterTypes throws exception with bad argument
eval {$parameterizable->addParameterTypes(1)};
ok($@, 'addParameterTypes throws exception with bad array');

# test setParameterTypes accepts empty array ref
eval {$parameterizable->setParameterTypes([])};
ok((!$@ and defined $parameterizable->getParameterTypes()
    and UNIVERSAL::isa($parameterizable->getParameterTypes, 'ARRAY')
    and scalar @{$parameterizable->getParameterTypes} == 0),
   'setParameterTypes accepts empty array ref');


# test getParameterTypes throws exception with argument
eval {$parameterizable->getParameterTypes(1)};
ok($@, 'getParameterTypes throws exception with argument');

# test setParameterTypes throws exception with no argument
eval {$parameterizable->setParameterTypes()};
ok($@, 'setParameterTypes throws exception with no argument');

# test setParameterTypes throws exception with too many argument
eval {$parameterizable->setParameterTypes(1,2)};
ok($@, 'setParameterTypes throws exception with too many argument');

# test setParameterTypes accepts undef
eval {$parameterizable->setParameterTypes(undef)};
ok((!$@ and not defined $parameterizable->getParameterTypes()),
   'setParameterTypes accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameterTypes};
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
   'parameterTypes->other() is a valid Bio::MAGE::Association::End'
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
   'parameterTypes->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($parameterizable->getDescriptions,'ARRAY')
 and scalar @{$parameterizable->getDescriptions} == 1
 and UNIVERSAL::isa($parameterizable->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($parameterizable->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($parameterizable->getDescriptions,'ARRAY')
 and scalar @{$parameterizable->getDescriptions} == 1
 and $parameterizable->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($parameterizable->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($parameterizable->getDescriptions,'ARRAY')
 and scalar @{$parameterizable->getDescriptions} == 2
 and $parameterizable->getDescriptions->[0] == $descriptions_assn
 and $parameterizable->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$parameterizable->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$parameterizable->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$parameterizable->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$parameterizable->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$parameterizable->setDescriptions([])};
ok((!$@ and defined $parameterizable->getDescriptions()
    and UNIVERSAL::isa($parameterizable->getDescriptions, 'ARRAY')
    and scalar @{$parameterizable->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$parameterizable->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$parameterizable->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$parameterizable->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$parameterizable->setDescriptions(undef)};
ok((!$@ and not defined $parameterizable->getDescriptions()),
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


isa_ok($parameterizable->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($parameterizable->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($parameterizable->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$parameterizable->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$parameterizable->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$parameterizable->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$parameterizable->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$parameterizable->setSecurity(undef)};
ok((!$@ and not defined $parameterizable->getSecurity()),
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


ok((UNIVERSAL::isa($parameterizable->getAuditTrail,'ARRAY')
 and scalar @{$parameterizable->getAuditTrail} == 1
 and UNIVERSAL::isa($parameterizable->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($parameterizable->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($parameterizable->getAuditTrail,'ARRAY')
 and scalar @{$parameterizable->getAuditTrail} == 1
 and $parameterizable->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($parameterizable->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($parameterizable->getAuditTrail,'ARRAY')
 and scalar @{$parameterizable->getAuditTrail} == 2
 and $parameterizable->getAuditTrail->[0] == $audittrail_assn
 and $parameterizable->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$parameterizable->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$parameterizable->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$parameterizable->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$parameterizable->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$parameterizable->setAuditTrail([])};
ok((!$@ and defined $parameterizable->getAuditTrail()
    and UNIVERSAL::isa($parameterizable->getAuditTrail, 'ARRAY')
    and scalar @{$parameterizable->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$parameterizable->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$parameterizable->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$parameterizable->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$parameterizable->setAuditTrail(undef)};
ok((!$@ and not defined $parameterizable->getAuditTrail()),
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


ok((UNIVERSAL::isa($parameterizable->getPropertySets,'ARRAY')
 and scalar @{$parameterizable->getPropertySets} == 1
 and UNIVERSAL::isa($parameterizable->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($parameterizable->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($parameterizable->getPropertySets,'ARRAY')
 and scalar @{$parameterizable->getPropertySets} == 1
 and $parameterizable->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($parameterizable->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($parameterizable->getPropertySets,'ARRAY')
 and scalar @{$parameterizable->getPropertySets} == 2
 and $parameterizable->getPropertySets->[0] == $propertysets_assn
 and $parameterizable->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$parameterizable->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$parameterizable->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$parameterizable->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$parameterizable->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$parameterizable->setPropertySets([])};
ok((!$@ and defined $parameterizable->getPropertySets()
    and UNIVERSAL::isa($parameterizable->getPropertySets, 'ARRAY')
    and scalar @{$parameterizable->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$parameterizable->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$parameterizable->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$parameterizable->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$parameterizable->setPropertySets(undef)};
ok((!$@ and not defined $parameterizable->getPropertySets()),
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
my $protocol = Bio::MAGE::Protocol::Protocol->new();

# testing subclass Protocol
isa_ok($protocol, q[Bio::MAGE::Protocol::Protocol]);
isa_ok($protocol, q[Bio::MAGE::Protocol::Parameterizable]);


# create a subclass
my $software = Bio::MAGE::Protocol::Software->new();

# testing subclass Software
isa_ok($software, q[Bio::MAGE::Protocol::Software]);
isa_ok($software, q[Bio::MAGE::Protocol::Parameterizable]);


# create a subclass
my $hardware = Bio::MAGE::Protocol::Hardware->new();

# testing subclass Hardware
isa_ok($hardware, q[Bio::MAGE::Protocol::Hardware]);
isa_ok($hardware, q[Bio::MAGE::Protocol::Parameterizable]);



my $identifiable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $identifiable = Bio::MAGE::Identifiable->new();
}

# testing superclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($parameterizable, q[Bio::MAGE::Identifiable]);

