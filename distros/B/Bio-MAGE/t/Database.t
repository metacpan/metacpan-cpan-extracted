##############################
#
# Database.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Database.t`

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

BEGIN { use_ok('Bio::MAGE::Description::Database') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Contact;
use Bio::MAGE::Description::Description;


# we test the new() method
my $database;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $database = Bio::MAGE::Description::Database->new();
}
isa_ok($database, 'Bio::MAGE::Description::Database');

# test the package_name class method
is($database->package_name(), q[Description],
  'package');

# test the class_name class method
is($database->class_name(), q[Bio::MAGE::Description::Database],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $database = Bio::MAGE::Description::Database->new(URI => '1',
identifier => '2',
version => '3',
name => '4');
}


#
# testing attribute URI
#

# test attribute values can be set in new()
is($database->getURI(), '1',
  'URI new');

# test getter/setter
$database->setURI('1');
is($database->getURI(), '1',
  'URI getter/setter');

# test getter throws exception with argument
eval {$database->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$database->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$database->setURI('1', '1')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$database->setURI(undef)};
ok((!$@ and not defined $database->getURI()),
   'URI setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($database->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$database->setIdentifier('2');
is($database->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$database->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$database->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$database->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$database->setIdentifier(undef)};
ok((!$@ and not defined $database->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute version
#

# test attribute values can be set in new()
is($database->getVersion(), '3',
  'version new');

# test getter/setter
$database->setVersion('3');
is($database->getVersion(), '3',
  'version getter/setter');

# test getter throws exception with argument
eval {$database->getVersion(1)};
ok($@, 'version getter throws exception with argument');

# test setter throws exception with no argument
eval {$database->setVersion()};
ok($@, 'version setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$database->setVersion('3', '3')};
ok($@, 'version setter throws exception with too many argument');

# test setter accepts undef
eval {$database->setVersion(undef)};
ok((!$@ and not defined $database->getVersion()),
   'version setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($database->getName(), '4',
  'name new');

# test getter/setter
$database->setName('4');
is($database->getName(), '4',
  'name getter/setter');

# test getter throws exception with argument
eval {$database->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$database->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$database->setName('4', '4')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$database->setName(undef)};
ok((!$@ and not defined $database->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Description::Database->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $database = Bio::MAGE::Description::Database->new(contacts => [Bio::MAGE::AuditAndSecurity::Contact->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association contacts
my $contacts_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $contacts_assn = Bio::MAGE::AuditAndSecurity::Contact->new();
}


ok((UNIVERSAL::isa($database->getContacts,'ARRAY')
 and scalar @{$database->getContacts} == 1
 and UNIVERSAL::isa($database->getContacts->[0], q[Bio::MAGE::AuditAndSecurity::Contact])),
  'contacts set in new()');

ok(eq_array($database->setContacts([$contacts_assn]), [$contacts_assn]),
   'setContacts returns correct value');

ok((UNIVERSAL::isa($database->getContacts,'ARRAY')
 and scalar @{$database->getContacts} == 1
 and $database->getContacts->[0] == $contacts_assn),
   'getContacts fetches correct value');

is($database->addContacts($contacts_assn), 2,
  'addContacts returns number of items in list');

ok((UNIVERSAL::isa($database->getContacts,'ARRAY')
 and scalar @{$database->getContacts} == 2
 and $database->getContacts->[0] == $contacts_assn
 and $database->getContacts->[1] == $contacts_assn),
  'addContacts adds correct value');

# test setContacts throws exception with non-array argument
eval {$database->setContacts(1)};
ok($@, 'setContacts throws exception with non-array argument');

# test setContacts throws exception with bad argument array
eval {$database->setContacts([1])};
ok($@, 'setContacts throws exception with bad argument array');

# test addContacts throws exception with no arguments
eval {$database->addContacts()};
ok($@, 'addContacts throws exception with no arguments');

# test addContacts throws exception with bad argument
eval {$database->addContacts(1)};
ok($@, 'addContacts throws exception with bad array');

# test setContacts accepts empty array ref
eval {$database->setContacts([])};
ok((!$@ and defined $database->getContacts()
    and UNIVERSAL::isa($database->getContacts, 'ARRAY')
    and scalar @{$database->getContacts} == 0),
   'setContacts accepts empty array ref');


# test getContacts throws exception with argument
eval {$database->getContacts(1)};
ok($@, 'getContacts throws exception with argument');

# test setContacts throws exception with no argument
eval {$database->setContacts()};
ok($@, 'setContacts throws exception with no argument');

# test setContacts throws exception with too many argument
eval {$database->setContacts(1,2)};
ok($@, 'setContacts throws exception with too many argument');

# test setContacts accepts undef
eval {$database->setContacts(undef)};
ok((!$@ and not defined $database->getContacts()),
   'setContacts accepts undef');

# test the meta-data for the assoication
$assn = $assns{contacts};
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
   'contacts->other() is a valid Bio::MAGE::Association::End'
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
   'contacts->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($database->getDescriptions,'ARRAY')
 and scalar @{$database->getDescriptions} == 1
 and UNIVERSAL::isa($database->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($database->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($database->getDescriptions,'ARRAY')
 and scalar @{$database->getDescriptions} == 1
 and $database->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($database->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($database->getDescriptions,'ARRAY')
 and scalar @{$database->getDescriptions} == 2
 and $database->getDescriptions->[0] == $descriptions_assn
 and $database->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$database->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$database->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$database->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$database->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$database->setDescriptions([])};
ok((!$@ and defined $database->getDescriptions()
    and UNIVERSAL::isa($database->getDescriptions, 'ARRAY')
    and scalar @{$database->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$database->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$database->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$database->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$database->setDescriptions(undef)};
ok((!$@ and not defined $database->getDescriptions()),
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


isa_ok($database->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($database->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($database->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$database->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$database->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$database->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$database->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$database->setSecurity(undef)};
ok((!$@ and not defined $database->getSecurity()),
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


ok((UNIVERSAL::isa($database->getAuditTrail,'ARRAY')
 and scalar @{$database->getAuditTrail} == 1
 and UNIVERSAL::isa($database->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($database->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($database->getAuditTrail,'ARRAY')
 and scalar @{$database->getAuditTrail} == 1
 and $database->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($database->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($database->getAuditTrail,'ARRAY')
 and scalar @{$database->getAuditTrail} == 2
 and $database->getAuditTrail->[0] == $audittrail_assn
 and $database->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$database->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$database->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$database->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$database->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$database->setAuditTrail([])};
ok((!$@ and defined $database->getAuditTrail()
    and UNIVERSAL::isa($database->getAuditTrail, 'ARRAY')
    and scalar @{$database->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$database->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$database->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$database->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$database->setAuditTrail(undef)};
ok((!$@ and not defined $database->getAuditTrail()),
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


ok((UNIVERSAL::isa($database->getPropertySets,'ARRAY')
 and scalar @{$database->getPropertySets} == 1
 and UNIVERSAL::isa($database->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($database->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($database->getPropertySets,'ARRAY')
 and scalar @{$database->getPropertySets} == 1
 and $database->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($database->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($database->getPropertySets,'ARRAY')
 and scalar @{$database->getPropertySets} == 2
 and $database->getPropertySets->[0] == $propertysets_assn
 and $database->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$database->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$database->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$database->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$database->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$database->setPropertySets([])};
ok((!$@ and defined $database->getPropertySets()
    and UNIVERSAL::isa($database->getPropertySets, 'ARRAY')
    and scalar @{$database->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$database->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$database->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$database->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$database->setPropertySets(undef)};
ok((!$@ and not defined $database->getPropertySets()),
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
isa_ok($database, q[Bio::MAGE::Identifiable]);

