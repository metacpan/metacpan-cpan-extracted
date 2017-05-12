##############################
#
# Description.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Description.t`

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
use Test::More tests => 158;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Description::Description') };

use Bio::MAGE::BQS::BibliographicReference;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::Description::ExternalReference;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::DatabaseEntry;


# we test the new() method
my $description;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $description = Bio::MAGE::Description::Description->new();
}
isa_ok($description, 'Bio::MAGE::Description::Description');

# test the package_name class method
is($description->package_name(), q[Description],
  'package');

# test the class_name class method
is($description->class_name(), q[Bio::MAGE::Description::Description],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $description = Bio::MAGE::Description::Description->new(URI => '1',
text => '2');
}


#
# testing attribute URI
#

# test attribute values can be set in new()
is($description->getURI(), '1',
  'URI new');

# test getter/setter
$description->setURI('1');
is($description->getURI(), '1',
  'URI getter/setter');

# test getter throws exception with argument
eval {$description->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$description->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$description->setURI('1', '1')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$description->setURI(undef)};
ok((!$@ and not defined $description->getURI()),
   'URI setter accepts undef');



#
# testing attribute text
#

# test attribute values can be set in new()
is($description->getText(), '2',
  'text new');

# test getter/setter
$description->setText('2');
is($description->getText(), '2',
  'text getter/setter');

# test getter throws exception with argument
eval {$description->getText(1)};
ok($@, 'text getter throws exception with argument');

# test setter throws exception with no argument
eval {$description->setText()};
ok($@, 'text setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$description->setText('2', '2')};
ok($@, 'text setter throws exception with too many argument');

# test setter accepts undef
eval {$description->setText(undef)};
ok((!$@ and not defined $description->getText()),
   'text setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::Description::Description->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $description = Bio::MAGE::Description::Description->new(databaseReferences => [Bio::MAGE::Description::DatabaseEntry->new()],
externalReference => Bio::MAGE::Description::ExternalReference->new(),
bibliographicReferences => [Bio::MAGE::BQS::BibliographicReference->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
annotations => [Bio::MAGE::Description::OntologyEntry->new()]);
}

my ($end, $assn);


# testing association databaseReferences
my $databasereferences_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $databasereferences_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


ok((UNIVERSAL::isa($description->getDatabaseReferences,'ARRAY')
 and scalar @{$description->getDatabaseReferences} == 1
 and UNIVERSAL::isa($description->getDatabaseReferences->[0], q[Bio::MAGE::Description::DatabaseEntry])),
  'databaseReferences set in new()');

ok(eq_array($description->setDatabaseReferences([$databasereferences_assn]), [$databasereferences_assn]),
   'setDatabaseReferences returns correct value');

ok((UNIVERSAL::isa($description->getDatabaseReferences,'ARRAY')
 and scalar @{$description->getDatabaseReferences} == 1
 and $description->getDatabaseReferences->[0] == $databasereferences_assn),
   'getDatabaseReferences fetches correct value');

is($description->addDatabaseReferences($databasereferences_assn), 2,
  'addDatabaseReferences returns number of items in list');

ok((UNIVERSAL::isa($description->getDatabaseReferences,'ARRAY')
 and scalar @{$description->getDatabaseReferences} == 2
 and $description->getDatabaseReferences->[0] == $databasereferences_assn
 and $description->getDatabaseReferences->[1] == $databasereferences_assn),
  'addDatabaseReferences adds correct value');

# test setDatabaseReferences throws exception with non-array argument
eval {$description->setDatabaseReferences(1)};
ok($@, 'setDatabaseReferences throws exception with non-array argument');

# test setDatabaseReferences throws exception with bad argument array
eval {$description->setDatabaseReferences([1])};
ok($@, 'setDatabaseReferences throws exception with bad argument array');

# test addDatabaseReferences throws exception with no arguments
eval {$description->addDatabaseReferences()};
ok($@, 'addDatabaseReferences throws exception with no arguments');

# test addDatabaseReferences throws exception with bad argument
eval {$description->addDatabaseReferences(1)};
ok($@, 'addDatabaseReferences throws exception with bad array');

# test setDatabaseReferences accepts empty array ref
eval {$description->setDatabaseReferences([])};
ok((!$@ and defined $description->getDatabaseReferences()
    and UNIVERSAL::isa($description->getDatabaseReferences, 'ARRAY')
    and scalar @{$description->getDatabaseReferences} == 0),
   'setDatabaseReferences accepts empty array ref');


# test getDatabaseReferences throws exception with argument
eval {$description->getDatabaseReferences(1)};
ok($@, 'getDatabaseReferences throws exception with argument');

# test setDatabaseReferences throws exception with no argument
eval {$description->setDatabaseReferences()};
ok($@, 'setDatabaseReferences throws exception with no argument');

# test setDatabaseReferences throws exception with too many argument
eval {$description->setDatabaseReferences(1,2)};
ok($@, 'setDatabaseReferences throws exception with too many argument');

# test setDatabaseReferences accepts undef
eval {$description->setDatabaseReferences(undef)};
ok((!$@ and not defined $description->getDatabaseReferences()),
   'setDatabaseReferences accepts undef');

# test the meta-data for the assoication
$assn = $assns{databaseReferences};
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
   'databaseReferences->other() is a valid Bio::MAGE::Association::End'
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
   'databaseReferences->self() is a valid Bio::MAGE::Association::End'
  );



# testing association externalReference
my $externalreference_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $externalreference_assn = Bio::MAGE::Description::ExternalReference->new();
}


isa_ok($description->getExternalReference, q[Bio::MAGE::Description::ExternalReference]);

is($description->setExternalReference($externalreference_assn), $externalreference_assn,
  'setExternalReference returns value');

ok($description->getExternalReference() == $externalreference_assn,
   'getExternalReference fetches correct value');

# test setExternalReference throws exception with bad argument
eval {$description->setExternalReference(1)};
ok($@, 'setExternalReference throws exception with bad argument');


# test getExternalReference throws exception with argument
eval {$description->getExternalReference(1)};
ok($@, 'getExternalReference throws exception with argument');

# test setExternalReference throws exception with no argument
eval {$description->setExternalReference()};
ok($@, 'setExternalReference throws exception with no argument');

# test setExternalReference throws exception with too many argument
eval {$description->setExternalReference(1,2)};
ok($@, 'setExternalReference throws exception with too many argument');

# test setExternalReference accepts undef
eval {$description->setExternalReference(undef)};
ok((!$@ and not defined $description->getExternalReference()),
   'setExternalReference accepts undef');

# test the meta-data for the assoication
$assn = $assns{externalReference};
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
   'externalReference->other() is a valid Bio::MAGE::Association::End'
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
   'externalReference->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bibliographicReferences
my $bibliographicreferences_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bibliographicreferences_assn = Bio::MAGE::BQS::BibliographicReference->new();
}


ok((UNIVERSAL::isa($description->getBibliographicReferences,'ARRAY')
 and scalar @{$description->getBibliographicReferences} == 1
 and UNIVERSAL::isa($description->getBibliographicReferences->[0], q[Bio::MAGE::BQS::BibliographicReference])),
  'bibliographicReferences set in new()');

ok(eq_array($description->setBibliographicReferences([$bibliographicreferences_assn]), [$bibliographicreferences_assn]),
   'setBibliographicReferences returns correct value');

ok((UNIVERSAL::isa($description->getBibliographicReferences,'ARRAY')
 and scalar @{$description->getBibliographicReferences} == 1
 and $description->getBibliographicReferences->[0] == $bibliographicreferences_assn),
   'getBibliographicReferences fetches correct value');

is($description->addBibliographicReferences($bibliographicreferences_assn), 2,
  'addBibliographicReferences returns number of items in list');

ok((UNIVERSAL::isa($description->getBibliographicReferences,'ARRAY')
 and scalar @{$description->getBibliographicReferences} == 2
 and $description->getBibliographicReferences->[0] == $bibliographicreferences_assn
 and $description->getBibliographicReferences->[1] == $bibliographicreferences_assn),
  'addBibliographicReferences adds correct value');

# test setBibliographicReferences throws exception with non-array argument
eval {$description->setBibliographicReferences(1)};
ok($@, 'setBibliographicReferences throws exception with non-array argument');

# test setBibliographicReferences throws exception with bad argument array
eval {$description->setBibliographicReferences([1])};
ok($@, 'setBibliographicReferences throws exception with bad argument array');

# test addBibliographicReferences throws exception with no arguments
eval {$description->addBibliographicReferences()};
ok($@, 'addBibliographicReferences throws exception with no arguments');

# test addBibliographicReferences throws exception with bad argument
eval {$description->addBibliographicReferences(1)};
ok($@, 'addBibliographicReferences throws exception with bad array');

# test setBibliographicReferences accepts empty array ref
eval {$description->setBibliographicReferences([])};
ok((!$@ and defined $description->getBibliographicReferences()
    and UNIVERSAL::isa($description->getBibliographicReferences, 'ARRAY')
    and scalar @{$description->getBibliographicReferences} == 0),
   'setBibliographicReferences accepts empty array ref');


# test getBibliographicReferences throws exception with argument
eval {$description->getBibliographicReferences(1)};
ok($@, 'getBibliographicReferences throws exception with argument');

# test setBibliographicReferences throws exception with no argument
eval {$description->setBibliographicReferences()};
ok($@, 'setBibliographicReferences throws exception with no argument');

# test setBibliographicReferences throws exception with too many argument
eval {$description->setBibliographicReferences(1,2)};
ok($@, 'setBibliographicReferences throws exception with too many argument');

# test setBibliographicReferences accepts undef
eval {$description->setBibliographicReferences(undef)};
ok((!$@ and not defined $description->getBibliographicReferences()),
   'setBibliographicReferences accepts undef');

# test the meta-data for the assoication
$assn = $assns{bibliographicReferences};
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
   'bibliographicReferences->other() is a valid Bio::MAGE::Association::End'
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
   'bibliographicReferences->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($description->getDescriptions,'ARRAY')
 and scalar @{$description->getDescriptions} == 1
 and UNIVERSAL::isa($description->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($description->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($description->getDescriptions,'ARRAY')
 and scalar @{$description->getDescriptions} == 1
 and $description->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($description->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($description->getDescriptions,'ARRAY')
 and scalar @{$description->getDescriptions} == 2
 and $description->getDescriptions->[0] == $descriptions_assn
 and $description->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$description->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$description->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$description->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$description->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$description->setDescriptions([])};
ok((!$@ and defined $description->getDescriptions()
    and UNIVERSAL::isa($description->getDescriptions, 'ARRAY')
    and scalar @{$description->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$description->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$description->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$description->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$description->setDescriptions(undef)};
ok((!$@ and not defined $description->getDescriptions()),
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


ok((UNIVERSAL::isa($description->getAuditTrail,'ARRAY')
 and scalar @{$description->getAuditTrail} == 1
 and UNIVERSAL::isa($description->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($description->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($description->getAuditTrail,'ARRAY')
 and scalar @{$description->getAuditTrail} == 1
 and $description->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($description->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($description->getAuditTrail,'ARRAY')
 and scalar @{$description->getAuditTrail} == 2
 and $description->getAuditTrail->[0] == $audittrail_assn
 and $description->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$description->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$description->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$description->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$description->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$description->setAuditTrail([])};
ok((!$@ and defined $description->getAuditTrail()
    and UNIVERSAL::isa($description->getAuditTrail, 'ARRAY')
    and scalar @{$description->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$description->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$description->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$description->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$description->setAuditTrail(undef)};
ok((!$@ and not defined $description->getAuditTrail()),
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


isa_ok($description->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($description->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($description->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$description->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$description->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$description->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$description->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$description->setSecurity(undef)};
ok((!$@ and not defined $description->getSecurity()),
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


ok((UNIVERSAL::isa($description->getPropertySets,'ARRAY')
 and scalar @{$description->getPropertySets} == 1
 and UNIVERSAL::isa($description->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($description->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($description->getPropertySets,'ARRAY')
 and scalar @{$description->getPropertySets} == 1
 and $description->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($description->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($description->getPropertySets,'ARRAY')
 and scalar @{$description->getPropertySets} == 2
 and $description->getPropertySets->[0] == $propertysets_assn
 and $description->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$description->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$description->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$description->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$description->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$description->setPropertySets([])};
ok((!$@ and defined $description->getPropertySets()
    and UNIVERSAL::isa($description->getPropertySets, 'ARRAY')
    and scalar @{$description->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$description->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$description->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$description->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$description->setPropertySets(undef)};
ok((!$@ and not defined $description->getPropertySets()),
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



# testing association annotations
my $annotations_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $annotations_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($description->getAnnotations,'ARRAY')
 and scalar @{$description->getAnnotations} == 1
 and UNIVERSAL::isa($description->getAnnotations->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'annotations set in new()');

ok(eq_array($description->setAnnotations([$annotations_assn]), [$annotations_assn]),
   'setAnnotations returns correct value');

ok((UNIVERSAL::isa($description->getAnnotations,'ARRAY')
 and scalar @{$description->getAnnotations} == 1
 and $description->getAnnotations->[0] == $annotations_assn),
   'getAnnotations fetches correct value');

is($description->addAnnotations($annotations_assn), 2,
  'addAnnotations returns number of items in list');

ok((UNIVERSAL::isa($description->getAnnotations,'ARRAY')
 and scalar @{$description->getAnnotations} == 2
 and $description->getAnnotations->[0] == $annotations_assn
 and $description->getAnnotations->[1] == $annotations_assn),
  'addAnnotations adds correct value');

# test setAnnotations throws exception with non-array argument
eval {$description->setAnnotations(1)};
ok($@, 'setAnnotations throws exception with non-array argument');

# test setAnnotations throws exception with bad argument array
eval {$description->setAnnotations([1])};
ok($@, 'setAnnotations throws exception with bad argument array');

# test addAnnotations throws exception with no arguments
eval {$description->addAnnotations()};
ok($@, 'addAnnotations throws exception with no arguments');

# test addAnnotations throws exception with bad argument
eval {$description->addAnnotations(1)};
ok($@, 'addAnnotations throws exception with bad array');

# test setAnnotations accepts empty array ref
eval {$description->setAnnotations([])};
ok((!$@ and defined $description->getAnnotations()
    and UNIVERSAL::isa($description->getAnnotations, 'ARRAY')
    and scalar @{$description->getAnnotations} == 0),
   'setAnnotations accepts empty array ref');


# test getAnnotations throws exception with argument
eval {$description->getAnnotations(1)};
ok($@, 'getAnnotations throws exception with argument');

# test setAnnotations throws exception with no argument
eval {$description->setAnnotations()};
ok($@, 'setAnnotations throws exception with no argument');

# test setAnnotations throws exception with too many argument
eval {$description->setAnnotations(1,2)};
ok($@, 'setAnnotations throws exception with too many argument');

# test setAnnotations accepts undef
eval {$description->setAnnotations(undef)};
ok((!$@ and not defined $description->getAnnotations()),
   'setAnnotations accepts undef');

# test the meta-data for the assoication
$assn = $assns{annotations};
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
   'annotations->other() is a valid Bio::MAGE::Association::End'
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
   'annotations->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($description, q[Bio::MAGE::Describable]);

