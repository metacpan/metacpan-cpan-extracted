##############################
#
# BibliographicReference.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BibliographicReference.t`

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
use Test::More tests => 174;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BQS::BibliographicReference') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Description::Description;
use Bio::MAGE::Description::DatabaseEntry;


# we test the new() method
my $bibliographicreference;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new();
}
isa_ok($bibliographicreference, 'Bio::MAGE::BQS::BibliographicReference');

# test the package_name class method
is($bibliographicreference->package_name(), q[BQS],
  'package');

# test the class_name class method
is($bibliographicreference->class_name(), q[Bio::MAGE::BQS::BibliographicReference],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new(authors => '1',
URI => '2',
volume => '3',
issue => '4',
editor => '5',
title => '6',
publication => '7',
publisher => '8',
year => '9',
pages => '10');
}


#
# testing attribute authors
#

# test attribute values can be set in new()
is($bibliographicreference->getAuthors(), '1',
  'authors new');

# test getter/setter
$bibliographicreference->setAuthors('1');
is($bibliographicreference->getAuthors(), '1',
  'authors getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getAuthors(1)};
ok($@, 'authors getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setAuthors()};
ok($@, 'authors setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setAuthors('1', '1')};
ok($@, 'authors setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setAuthors(undef)};
ok((!$@ and not defined $bibliographicreference->getAuthors()),
   'authors setter accepts undef');



#
# testing attribute URI
#

# test attribute values can be set in new()
is($bibliographicreference->getURI(), '2',
  'URI new');

# test getter/setter
$bibliographicreference->setURI('2');
is($bibliographicreference->getURI(), '2',
  'URI getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setURI('2', '2')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setURI(undef)};
ok((!$@ and not defined $bibliographicreference->getURI()),
   'URI setter accepts undef');



#
# testing attribute volume
#

# test attribute values can be set in new()
is($bibliographicreference->getVolume(), '3',
  'volume new');

# test getter/setter
$bibliographicreference->setVolume('3');
is($bibliographicreference->getVolume(), '3',
  'volume getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getVolume(1)};
ok($@, 'volume getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setVolume()};
ok($@, 'volume setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setVolume('3', '3')};
ok($@, 'volume setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setVolume(undef)};
ok((!$@ and not defined $bibliographicreference->getVolume()),
   'volume setter accepts undef');



#
# testing attribute issue
#

# test attribute values can be set in new()
is($bibliographicreference->getIssue(), '4',
  'issue new');

# test getter/setter
$bibliographicreference->setIssue('4');
is($bibliographicreference->getIssue(), '4',
  'issue getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getIssue(1)};
ok($@, 'issue getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setIssue()};
ok($@, 'issue setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setIssue('4', '4')};
ok($@, 'issue setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setIssue(undef)};
ok((!$@ and not defined $bibliographicreference->getIssue()),
   'issue setter accepts undef');



#
# testing attribute editor
#

# test attribute values can be set in new()
is($bibliographicreference->getEditor(), '5',
  'editor new');

# test getter/setter
$bibliographicreference->setEditor('5');
is($bibliographicreference->getEditor(), '5',
  'editor getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getEditor(1)};
ok($@, 'editor getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setEditor()};
ok($@, 'editor setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setEditor('5', '5')};
ok($@, 'editor setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setEditor(undef)};
ok((!$@ and not defined $bibliographicreference->getEditor()),
   'editor setter accepts undef');



#
# testing attribute title
#

# test attribute values can be set in new()
is($bibliographicreference->getTitle(), '6',
  'title new');

# test getter/setter
$bibliographicreference->setTitle('6');
is($bibliographicreference->getTitle(), '6',
  'title getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getTitle(1)};
ok($@, 'title getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setTitle()};
ok($@, 'title setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setTitle('6', '6')};
ok($@, 'title setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setTitle(undef)};
ok((!$@ and not defined $bibliographicreference->getTitle()),
   'title setter accepts undef');



#
# testing attribute publication
#

# test attribute values can be set in new()
is($bibliographicreference->getPublication(), '7',
  'publication new');

# test getter/setter
$bibliographicreference->setPublication('7');
is($bibliographicreference->getPublication(), '7',
  'publication getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getPublication(1)};
ok($@, 'publication getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setPublication()};
ok($@, 'publication setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setPublication('7', '7')};
ok($@, 'publication setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setPublication(undef)};
ok((!$@ and not defined $bibliographicreference->getPublication()),
   'publication setter accepts undef');



#
# testing attribute publisher
#

# test attribute values can be set in new()
is($bibliographicreference->getPublisher(), '8',
  'publisher new');

# test getter/setter
$bibliographicreference->setPublisher('8');
is($bibliographicreference->getPublisher(), '8',
  'publisher getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getPublisher(1)};
ok($@, 'publisher getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setPublisher()};
ok($@, 'publisher setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setPublisher('8', '8')};
ok($@, 'publisher setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setPublisher(undef)};
ok((!$@ and not defined $bibliographicreference->getPublisher()),
   'publisher setter accepts undef');



#
# testing attribute year
#

# test attribute values can be set in new()
is($bibliographicreference->getYear(), '9',
  'year new');

# test getter/setter
$bibliographicreference->setYear('9');
is($bibliographicreference->getYear(), '9',
  'year getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getYear(1)};
ok($@, 'year getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setYear()};
ok($@, 'year setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setYear('9', '9')};
ok($@, 'year setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setYear(undef)};
ok((!$@ and not defined $bibliographicreference->getYear()),
   'year setter accepts undef');



#
# testing attribute pages
#

# test attribute values can be set in new()
is($bibliographicreference->getPages(), '10',
  'pages new');

# test getter/setter
$bibliographicreference->setPages('10');
is($bibliographicreference->getPages(), '10',
  'pages getter/setter');

# test getter throws exception with argument
eval {$bibliographicreference->getPages(1)};
ok($@, 'pages getter throws exception with argument');

# test setter throws exception with no argument
eval {$bibliographicreference->setPages()};
ok($@, 'pages setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bibliographicreference->setPages('10', '10')};
ok($@, 'pages setter throws exception with too many argument');

# test setter accepts undef
eval {$bibliographicreference->setPages(undef)};
ok((!$@ and not defined $bibliographicreference->getPages()),
   'pages setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BQS::BibliographicReference->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new(parameters => [Bio::MAGE::Description::OntologyEntry->new()],
accessions => [Bio::MAGE::Description::DatabaseEntry->new()],
descriptions => [Bio::MAGE::Description::Description->new()],
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association parameters
my $parameters_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $parameters_assn = Bio::MAGE::Description::OntologyEntry->new();
}


ok((UNIVERSAL::isa($bibliographicreference->getParameters,'ARRAY')
 and scalar @{$bibliographicreference->getParameters} == 1
 and UNIVERSAL::isa($bibliographicreference->getParameters->[0], q[Bio::MAGE::Description::OntologyEntry])),
  'parameters set in new()');

ok(eq_array($bibliographicreference->setParameters([$parameters_assn]), [$parameters_assn]),
   'setParameters returns correct value');

ok((UNIVERSAL::isa($bibliographicreference->getParameters,'ARRAY')
 and scalar @{$bibliographicreference->getParameters} == 1
 and $bibliographicreference->getParameters->[0] == $parameters_assn),
   'getParameters fetches correct value');

is($bibliographicreference->addParameters($parameters_assn), 2,
  'addParameters returns number of items in list');

ok((UNIVERSAL::isa($bibliographicreference->getParameters,'ARRAY')
 and scalar @{$bibliographicreference->getParameters} == 2
 and $bibliographicreference->getParameters->[0] == $parameters_assn
 and $bibliographicreference->getParameters->[1] == $parameters_assn),
  'addParameters adds correct value');

# test setParameters throws exception with non-array argument
eval {$bibliographicreference->setParameters(1)};
ok($@, 'setParameters throws exception with non-array argument');

# test setParameters throws exception with bad argument array
eval {$bibliographicreference->setParameters([1])};
ok($@, 'setParameters throws exception with bad argument array');

# test addParameters throws exception with no arguments
eval {$bibliographicreference->addParameters()};
ok($@, 'addParameters throws exception with no arguments');

# test addParameters throws exception with bad argument
eval {$bibliographicreference->addParameters(1)};
ok($@, 'addParameters throws exception with bad array');

# test setParameters accepts empty array ref
eval {$bibliographicreference->setParameters([])};
ok((!$@ and defined $bibliographicreference->getParameters()
    and UNIVERSAL::isa($bibliographicreference->getParameters, 'ARRAY')
    and scalar @{$bibliographicreference->getParameters} == 0),
   'setParameters accepts empty array ref');


# test getParameters throws exception with argument
eval {$bibliographicreference->getParameters(1)};
ok($@, 'getParameters throws exception with argument');

# test setParameters throws exception with no argument
eval {$bibliographicreference->setParameters()};
ok($@, 'setParameters throws exception with no argument');

# test setParameters throws exception with too many argument
eval {$bibliographicreference->setParameters(1,2)};
ok($@, 'setParameters throws exception with too many argument');

# test setParameters accepts undef
eval {$bibliographicreference->setParameters(undef)};
ok((!$@ and not defined $bibliographicreference->getParameters()),
   'setParameters accepts undef');

# test the meta-data for the assoication
$assn = $assns{parameters};
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
   'parameters->other() is a valid Bio::MAGE::Association::End'
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
   'parameters->self() is a valid Bio::MAGE::Association::End'
  );



# testing association accessions
my $accessions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $accessions_assn = Bio::MAGE::Description::DatabaseEntry->new();
}


ok((UNIVERSAL::isa($bibliographicreference->getAccessions,'ARRAY')
 and scalar @{$bibliographicreference->getAccessions} == 1
 and UNIVERSAL::isa($bibliographicreference->getAccessions->[0], q[Bio::MAGE::Description::DatabaseEntry])),
  'accessions set in new()');

ok(eq_array($bibliographicreference->setAccessions([$accessions_assn]), [$accessions_assn]),
   'setAccessions returns correct value');

ok((UNIVERSAL::isa($bibliographicreference->getAccessions,'ARRAY')
 and scalar @{$bibliographicreference->getAccessions} == 1
 and $bibliographicreference->getAccessions->[0] == $accessions_assn),
   'getAccessions fetches correct value');

is($bibliographicreference->addAccessions($accessions_assn), 2,
  'addAccessions returns number of items in list');

ok((UNIVERSAL::isa($bibliographicreference->getAccessions,'ARRAY')
 and scalar @{$bibliographicreference->getAccessions} == 2
 and $bibliographicreference->getAccessions->[0] == $accessions_assn
 and $bibliographicreference->getAccessions->[1] == $accessions_assn),
  'addAccessions adds correct value');

# test setAccessions throws exception with non-array argument
eval {$bibliographicreference->setAccessions(1)};
ok($@, 'setAccessions throws exception with non-array argument');

# test setAccessions throws exception with bad argument array
eval {$bibliographicreference->setAccessions([1])};
ok($@, 'setAccessions throws exception with bad argument array');

# test addAccessions throws exception with no arguments
eval {$bibliographicreference->addAccessions()};
ok($@, 'addAccessions throws exception with no arguments');

# test addAccessions throws exception with bad argument
eval {$bibliographicreference->addAccessions(1)};
ok($@, 'addAccessions throws exception with bad array');

# test setAccessions accepts empty array ref
eval {$bibliographicreference->setAccessions([])};
ok((!$@ and defined $bibliographicreference->getAccessions()
    and UNIVERSAL::isa($bibliographicreference->getAccessions, 'ARRAY')
    and scalar @{$bibliographicreference->getAccessions} == 0),
   'setAccessions accepts empty array ref');


# test getAccessions throws exception with argument
eval {$bibliographicreference->getAccessions(1)};
ok($@, 'getAccessions throws exception with argument');

# test setAccessions throws exception with no argument
eval {$bibliographicreference->setAccessions()};
ok($@, 'setAccessions throws exception with no argument');

# test setAccessions throws exception with too many argument
eval {$bibliographicreference->setAccessions(1,2)};
ok($@, 'setAccessions throws exception with too many argument');

# test setAccessions accepts undef
eval {$bibliographicreference->setAccessions(undef)};
ok((!$@ and not defined $bibliographicreference->getAccessions()),
   'setAccessions accepts undef');

# test the meta-data for the assoication
$assn = $assns{accessions};
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
   'accessions->other() is a valid Bio::MAGE::Association::End'
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
   'accessions->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($bibliographicreference->getDescriptions,'ARRAY')
 and scalar @{$bibliographicreference->getDescriptions} == 1
 and UNIVERSAL::isa($bibliographicreference->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($bibliographicreference->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($bibliographicreference->getDescriptions,'ARRAY')
 and scalar @{$bibliographicreference->getDescriptions} == 1
 and $bibliographicreference->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($bibliographicreference->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($bibliographicreference->getDescriptions,'ARRAY')
 and scalar @{$bibliographicreference->getDescriptions} == 2
 and $bibliographicreference->getDescriptions->[0] == $descriptions_assn
 and $bibliographicreference->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$bibliographicreference->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$bibliographicreference->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$bibliographicreference->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$bibliographicreference->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$bibliographicreference->setDescriptions([])};
ok((!$@ and defined $bibliographicreference->getDescriptions()
    and UNIVERSAL::isa($bibliographicreference->getDescriptions, 'ARRAY')
    and scalar @{$bibliographicreference->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$bibliographicreference->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$bibliographicreference->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$bibliographicreference->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$bibliographicreference->setDescriptions(undef)};
ok((!$@ and not defined $bibliographicreference->getDescriptions()),
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


ok((UNIVERSAL::isa($bibliographicreference->getAuditTrail,'ARRAY')
 and scalar @{$bibliographicreference->getAuditTrail} == 1
 and UNIVERSAL::isa($bibliographicreference->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($bibliographicreference->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($bibliographicreference->getAuditTrail,'ARRAY')
 and scalar @{$bibliographicreference->getAuditTrail} == 1
 and $bibliographicreference->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($bibliographicreference->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($bibliographicreference->getAuditTrail,'ARRAY')
 and scalar @{$bibliographicreference->getAuditTrail} == 2
 and $bibliographicreference->getAuditTrail->[0] == $audittrail_assn
 and $bibliographicreference->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$bibliographicreference->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$bibliographicreference->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$bibliographicreference->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$bibliographicreference->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$bibliographicreference->setAuditTrail([])};
ok((!$@ and defined $bibliographicreference->getAuditTrail()
    and UNIVERSAL::isa($bibliographicreference->getAuditTrail, 'ARRAY')
    and scalar @{$bibliographicreference->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$bibliographicreference->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$bibliographicreference->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$bibliographicreference->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$bibliographicreference->setAuditTrail(undef)};
ok((!$@ and not defined $bibliographicreference->getAuditTrail()),
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


isa_ok($bibliographicreference->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($bibliographicreference->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($bibliographicreference->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$bibliographicreference->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$bibliographicreference->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$bibliographicreference->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$bibliographicreference->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$bibliographicreference->setSecurity(undef)};
ok((!$@ and not defined $bibliographicreference->getSecurity()),
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


ok((UNIVERSAL::isa($bibliographicreference->getPropertySets,'ARRAY')
 and scalar @{$bibliographicreference->getPropertySets} == 1
 and UNIVERSAL::isa($bibliographicreference->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bibliographicreference->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bibliographicreference->getPropertySets,'ARRAY')
 and scalar @{$bibliographicreference->getPropertySets} == 1
 and $bibliographicreference->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bibliographicreference->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bibliographicreference->getPropertySets,'ARRAY')
 and scalar @{$bibliographicreference->getPropertySets} == 2
 and $bibliographicreference->getPropertySets->[0] == $propertysets_assn
 and $bibliographicreference->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bibliographicreference->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bibliographicreference->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bibliographicreference->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bibliographicreference->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bibliographicreference->setPropertySets([])};
ok((!$@ and defined $bibliographicreference->getPropertySets()
    and UNIVERSAL::isa($bibliographicreference->getPropertySets, 'ARRAY')
    and scalar @{$bibliographicreference->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bibliographicreference->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bibliographicreference->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bibliographicreference->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bibliographicreference->setPropertySets(undef)};
ok((!$@ and not defined $bibliographicreference->getPropertySets()),
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
isa_ok($bibliographicreference, q[Bio::MAGE::Describable]);

