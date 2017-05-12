##############################
#
# Protocol.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Protocol.t`

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
use Test::More tests => 176;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Protocol::Protocol') };

use Bio::MAGE::Protocol::Software;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Protocol::Hardware;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Protocol::Parameter;
use Bio::MAGE::Description::Description;


# we test the new() method
my $protocol;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocol = Bio::MAGE::Protocol::Protocol->new();
}
isa_ok($protocol, 'Bio::MAGE::Protocol::Protocol');

# test the package_name class method
is($protocol->package_name(), q[Protocol],
  'package');

# test the class_name class method
is($protocol->class_name(), q[Bio::MAGE::Protocol::Protocol],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocol = Bio::MAGE::Protocol::Protocol->new(identifier => '1',
URI => '2',
text => '3',
name => '4',
title => '5');
}


#
# testing attribute identifier
#

# test attribute values can be set in new()
is($protocol->getIdentifier(), '1',
  'identifier new');

# test getter/setter
$protocol->setIdentifier('1');
is($protocol->getIdentifier(), '1',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$protocol->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocol->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocol->setIdentifier('1', '1')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$protocol->setIdentifier(undef)};
ok((!$@ and not defined $protocol->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($protocol->getURI(), '2',
  'URI new');

# test getter/setter
$protocol->setURI('2');
is($protocol->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$protocol->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocol->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocol->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$protocol->setURI(undef)};
ok((!$@ and not defined $protocol->getURI()),
   'URI setter accepts undef');



#
# testing attribute text
#

# test attribute values can be set in new()
is($protocol->getText(), '3',
  'text new');

# test getter/setter
$protocol->setText('3');
is($protocol->getText(), '3',
  'text getter/setter');

# test getter throws exception with argument
eval {$protocol->getText(1)};
ok($@, 'text getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocol->setText()};
ok($@, 'text setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocol->setText('3', '3')};
ok($@, 'text setter throws exception with too many argument');

# test setter accepts undef
eval {$protocol->setText(undef)};
ok((!$@ and not defined $protocol->getText()),
   'text setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($protocol->getName(), '4',
  'name new');

# test getter/setter
$protocol->setName('4');
is($protocol->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$protocol->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocol->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocol->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$protocol->setName(undef)};
ok((!$@ and not defined $protocol->getName()),
   'name setter accepts undef');



#
# testing attribute title
#

# test attribute values can be set in new()
is($protocol->getTitle(), '5',
  'title new');

# test getter/setter
$protocol->setTitle('5');
is($protocol->getTitle(), '5',
  'title getter/setter');

# test getter throws exception with argument
eval {$protocol->getTitle(1)};
ok($@, 'title getter throws exception with argument');

# test setter throws exception with no argument
eval {$protocol->setTitle()};
ok($@, 'title setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$protocol->setTitle('5', '5')};
ok($@, 'title setter throws exception with too many argument');

# test setter accepts undef
eval {$protocol->setTitle(undef)};
ok((!$@ and not defined $protocol->getTitle()),
   'title setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Protocol::Protocol->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $protocol = Bio::MAGE::Protocol::Protocol->new(parameterTypes => [Bio::MAGE::Protocol::Parameter->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()],
hardwares => [Bio::MAGE::Protocol::Hardware->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
softwares => [Bio::MAGE::Protocol::Software->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
type => Bio::MAGE::Description::OntologyEntry->new());
}

my ($end, $assn);


# testing association parameterTypes
my $parametertypes_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parametertypes_assn = Bio::MAGE::Protocol::Parameter->new();
}


ok((UNIVERSAL::isa($protocol->getParameterTypes,'ARRAY')
 and scalar @{$protocol->getParameterTypes} == 1
 and UNIVERSAL::isa($protocol->getParameterTypes->[0], q[Bio::MAGE::Protocol::Parameter])),
  'parameterTypes set in new()');

ok(eq_array($protocol->setParameterTypes([$parametertypes_assn]), [$parametertypes_assn]),
   'setParameterTypes returns correct value');

ok((UNIVERSAL::isa($protocol->getParameterTypes,'ARRAY')
 and scalar @{$protocol->getParameterTypes} == 1
 and $protocol->getParameterTypes->[0] == $parametertypes_assn),
   'getParameterTypes fetches correct value');

is($protocol->addParameterTypes($parametertypes_assn), 2,
  'addParameterTypes returns number of items in list');

ok((UNIVERSAL::isa($protocol->getParameterTypes,'ARRAY')
 and scalar @{$protocol->getParameterTypes} == 2
 and $protocol->getParameterTypes->[0] == $parametertypes_assn
 and $protocol->getParameterTypes->[1] == $parametertypes_assn),
  'addParameterTypes adds correct value');

# test setParameterTypes throws exception with non-array argument
eval {$protocol->setParameterTypes(1)};
ok($@, 'setParameterTypes throws exception with non-array argument');

# test setParameterTypes throws exception with bad argument array
eval {$protocol->setParameterTypes([1])};
ok($@, 'setParameterTypes throws exception with bad argument array');

# test addParameterTypes throws exception with no arguments
eval {$protocol->addParameterTypes()};
ok($@, 'addParameterTypes throws exception with no arguments');

# test addParameterTypes throws exception with bad argument
eval {$protocol->addParameterTypes(1)};
ok($@, 'addParameterTypes throws exception with bad array');

# test setParameterTypes accepts empty array ref
eval {$protocol->setParameterTypes([])};
ok((!$@ and defined $protocol->getParameterTypes()
    and UNIVERSAL::isa($protocol->getParameterTypes, 'ARRAY')
    and scalar @{$protocol->getParameterTypes} == 0),
   'setParameterTypes accepts empty array ref');


# test getParameterTypes throws exception with argument
eval {$protocol->getParameterTypes(1)};
ok($@, 'getParameterTypes throws exception with argument');

# test setParameterTypes throws exception with no argument
eval {$protocol->setParameterTypes()};
ok($@, 'setParameterTypes throws exception with no argument');

# test setParameterTypes throws exception with too many argument
eval {$protocol->setParameterTypes(1,2)};
ok($@, 'setParameterTypes throws exception with too many argument');

# test setParameterTypes accepts undef
eval {$protocol->setParameterTypes(undef)};
ok((!$@ and not defined $protocol->getParameterTypes()),
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



# testing association auditTrail
my $audittrail_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $audittrail_assn = Bio::MAGE::AuditAndSecurity::Audit->new();
}


ok((UNIVERSAL::isa($protocol->getAuditTrail,'ARRAY')
 and scalar @{$protocol->getAuditTrail} == 1
 and UNIVERSAL::isa($protocol->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($protocol->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($protocol->getAuditTrail,'ARRAY')
 and scalar @{$protocol->getAuditTrail} == 1
 and $protocol->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($protocol->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($protocol->getAuditTrail,'ARRAY')
 and scalar @{$protocol->getAuditTrail} == 2
 and $protocol->getAuditTrail->[0] == $audittrail_assn
 and $protocol->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$protocol->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$protocol->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$protocol->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$protocol->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$protocol->setAuditTrail([])};
ok((!$@ and defined $protocol->getAuditTrail()
    and UNIVERSAL::isa($protocol->getAuditTrail, 'ARRAY')
    and scalar @{$protocol->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$protocol->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$protocol->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$protocol->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$protocol->setAuditTrail(undef)};
ok((!$@ and not defined $protocol->getAuditTrail()),
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


ok((UNIVERSAL::isa($protocol->getPropertySets,'ARRAY')
 and scalar @{$protocol->getPropertySets} == 1
 and UNIVERSAL::isa($protocol->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($protocol->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($protocol->getPropertySets,'ARRAY')
 and scalar @{$protocol->getPropertySets} == 1
 and $protocol->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($protocol->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($protocol->getPropertySets,'ARRAY')
 and scalar @{$protocol->getPropertySets} == 2
 and $protocol->getPropertySets->[0] == $propertysets_assn
 and $protocol->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$protocol->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$protocol->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$protocol->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$protocol->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$protocol->setPropertySets([])};
ok((!$@ and defined $protocol->getPropertySets()
    and UNIVERSAL::isa($protocol->getPropertySets, 'ARRAY')
    and scalar @{$protocol->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$protocol->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$protocol->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$protocol->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$protocol->setPropertySets(undef)};
ok((!$@ and not defined $protocol->getPropertySets()),
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



# testing association hardwares
my $hardwares_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $hardwares_assn = Bio::MAGE::Protocol::Hardware->new();
}


ok((UNIVERSAL::isa($protocol->getHardwares,'ARRAY')
 and scalar @{$protocol->getHardwares} == 1
 and UNIVERSAL::isa($protocol->getHardwares->[0], q[Bio::MAGE::Protocol::Hardware])),
  'hardwares set in new()');

ok(eq_array($protocol->setHardwares([$hardwares_assn]), [$hardwares_assn]),
   'setHardwares returns correct value');

ok((UNIVERSAL::isa($protocol->getHardwares,'ARRAY')
 and scalar @{$protocol->getHardwares} == 1
 and $protocol->getHardwares->[0] == $hardwares_assn),
   'getHardwares fetches correct value');

is($protocol->addHardwares($hardwares_assn), 2,
  'addHardwares returns number of items in list');

ok((UNIVERSAL::isa($protocol->getHardwares,'ARRAY')
 and scalar @{$protocol->getHardwares} == 2
 and $protocol->getHardwares->[0] == $hardwares_assn
 and $protocol->getHardwares->[1] == $hardwares_assn),
  'addHardwares adds correct value');

# test setHardwares throws exception with non-array argument
eval {$protocol->setHardwares(1)};
ok($@, 'setHardwares throws exception with non-array argument');

# test setHardwares throws exception with bad argument array
eval {$protocol->setHardwares([1])};
ok($@, 'setHardwares throws exception with bad argument array');

# test addHardwares throws exception with no arguments
eval {$protocol->addHardwares()};
ok($@, 'addHardwares throws exception with no arguments');

# test addHardwares throws exception with bad argument
eval {$protocol->addHardwares(1)};
ok($@, 'addHardwares throws exception with bad array');

# test setHardwares accepts empty array ref
eval {$protocol->setHardwares([])};
ok((!$@ and defined $protocol->getHardwares()
    and UNIVERSAL::isa($protocol->getHardwares, 'ARRAY')
    and scalar @{$protocol->getHardwares} == 0),
   'setHardwares accepts empty array ref');


# test getHardwares throws exception with argument
eval {$protocol->getHardwares(1)};
ok($@, 'getHardwares throws exception with argument');

# test setHardwares throws exception with no argument
eval {$protocol->setHardwares()};
ok($@, 'setHardwares throws exception with no argument');

# test setHardwares throws exception with too many argument
eval {$protocol->setHardwares(1,2)};
ok($@, 'setHardwares throws exception with too many argument');

# test setHardwares accepts undef
eval {$protocol->setHardwares(undef)};
ok((!$@ and not defined $protocol->getHardwares()),
   'setHardwares accepts undef');

# test the meta-data for the assoication
$assn = $assns{hardwares};
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
   'hardwares->other() is a valid Bio::MAGE::Association::End'
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
   'hardwares->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($protocol->getDescriptions,'ARRAY')
 and scalar @{$protocol->getDescriptions} == 1
 and UNIVERSAL::isa($protocol->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($protocol->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($protocol->getDescriptions,'ARRAY')
 and scalar @{$protocol->getDescriptions} == 1
 and $protocol->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($protocol->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($protocol->getDescriptions,'ARRAY')
 and scalar @{$protocol->getDescriptions} == 2
 and $protocol->getDescriptions->[0] == $descriptions_assn
 and $protocol->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$protocol->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$protocol->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$protocol->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$protocol->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$protocol->setDescriptions([])};
ok((!$@ and defined $protocol->getDescriptions()
    and UNIVERSAL::isa($protocol->getDescriptions, 'ARRAY')
    and scalar @{$protocol->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$protocol->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$protocol->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$protocol->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$protocol->setDescriptions(undef)};
ok((!$@ and not defined $protocol->getDescriptions()),
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



# testing association softwares
my $softwares_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $softwares_assn = Bio::MAGE::Protocol::Software->new();
}


ok((UNIVERSAL::isa($protocol->getSoftwares,'ARRAY')
 and scalar @{$protocol->getSoftwares} == 1
 and UNIVERSAL::isa($protocol->getSoftwares->[0], q[Bio::MAGE::Protocol::Software])),
  'softwares set in new()');

ok(eq_array($protocol->setSoftwares([$softwares_assn]), [$softwares_assn]),
   'setSoftwares returns correct value');

ok((UNIVERSAL::isa($protocol->getSoftwares,'ARRAY')
 and scalar @{$protocol->getSoftwares} == 1
 and $protocol->getSoftwares->[0] == $softwares_assn),
   'getSoftwares fetches correct value');

is($protocol->addSoftwares($softwares_assn), 2,
  'addSoftwares returns number of items in list');

ok((UNIVERSAL::isa($protocol->getSoftwares,'ARRAY')
 and scalar @{$protocol->getSoftwares} == 2
 and $protocol->getSoftwares->[0] == $softwares_assn
 and $protocol->getSoftwares->[1] == $softwares_assn),
  'addSoftwares adds correct value');

# test setSoftwares throws exception with non-array argument
eval {$protocol->setSoftwares(1)};
ok($@, 'setSoftwares throws exception with non-array argument');

# test setSoftwares throws exception with bad argument array
eval {$protocol->setSoftwares([1])};
ok($@, 'setSoftwares throws exception with bad argument array');

# test addSoftwares throws exception with no arguments
eval {$protocol->addSoftwares()};
ok($@, 'addSoftwares throws exception with no arguments');

# test addSoftwares throws exception with bad argument
eval {$protocol->addSoftwares(1)};
ok($@, 'addSoftwares throws exception with bad array');

# test setSoftwares accepts empty array ref
eval {$protocol->setSoftwares([])};
ok((!$@ and defined $protocol->getSoftwares()
    and UNIVERSAL::isa($protocol->getSoftwares, 'ARRAY')
    and scalar @{$protocol->getSoftwares} == 0),
   'setSoftwares accepts empty array ref');


# test getSoftwares throws exception with argument
eval {$protocol->getSoftwares(1)};
ok($@, 'getSoftwares throws exception with argument');

# test setSoftwares throws exception with no argument
eval {$protocol->setSoftwares()};
ok($@, 'setSoftwares throws exception with no argument');

# test setSoftwares throws exception with too many argument
eval {$protocol->setSoftwares(1,2)};
ok($@, 'setSoftwares throws exception with too many argument');

# test setSoftwares accepts undef
eval {$protocol->setSoftwares(undef)};
ok((!$@ and not defined $protocol->getSoftwares()),
   'setSoftwares accepts undef');

# test the meta-data for the assoication
$assn = $assns{softwares};
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
   'softwares->other() is a valid Bio::MAGE::Association::End'
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
   'softwares->self() is a valid Bio::MAGE::Association::End'
  );



# testing association security
my $security_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $security_assn = Bio::MAGE::AuditAndSecurity::Security->new();
}


isa_ok($protocol->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($protocol->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($protocol->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$protocol->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$protocol->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$protocol->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$protocol->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$protocol->setSecurity(undef)};
ok((!$@ and not defined $protocol->getSecurity()),
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



# testing association type
my $type_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $type_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($protocol->getType, q[Bio::MAGE::Description::OntologyEntry]);

is($protocol->setType($type_assn), $type_assn,
  'setType returns value');

ok($protocol->getType() == $type_assn,
   'getType fetches correct value');

# test setType throws exception with bad argument
eval {$protocol->setType(1)};
ok($@, 'setType throws exception with bad argument');


# test getType throws exception with argument
eval {$protocol->getType(1)};
ok($@, 'getType throws exception with argument');

# test setType throws exception with no argument
eval {$protocol->setType()};
ok($@, 'setType throws exception with no argument');

# test setType throws exception with too many argument
eval {$protocol->setType(1,2)};
ok($@, 'setType throws exception with too many argument');

# test setType accepts undef
eval {$protocol->setType(undef)};
ok((!$@ and not defined $protocol->getType()),
   'setType accepts undef');

# test the meta-data for the assoication
$assn = $assns{type};
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
   'type->other() is a valid Bio::MAGE::Association::End'
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
   'type->self() is a valid Bio::MAGE::Association::End'
  );





my $parameterizable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $parameterizable = Bio::MAGE::Protocol::Parameterizable->new();
}

# testing superclass Parameterizable
isa_ok($parameterizable, q[Bio::MAGE::Protocol::Parameterizable]);
isa_ok($protocol, q[Bio::MAGE::Protocol::Parameterizable]);

