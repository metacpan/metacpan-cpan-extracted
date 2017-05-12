##############################
#
# Describable.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Describable.t`

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
use Test::More tests => 98;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Describable') };

use Bio::MAGE::NameValueType;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;

use Bio::MAGE::HigherLevelAnalysis::Node;
use Bio::MAGE::HigherLevelAnalysis::NodeContents;
use Bio::MAGE::Description::Description;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::Identifiable;
use Bio::MAGE::Array::Fiducial;
use Bio::MAGE::BQS::BibliographicReference;
use Bio::MAGE::Experiment::ExperimentDesign;
use Bio::MAGE::Array::ManufactureLIMS;
use Bio::MAGE::BioSequence::SeqFeature;
use Bio::MAGE::Protocol::ParameterizableApplication;

# we test the new() method
my $describable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $describable = Bio::MAGE::Describable->new();
}
isa_ok($describable, 'Bio::MAGE::Describable');

# test the package_name class method
is($describable->package_name(), q[MAGE],
  'package');

# test the class_name class method
is($describable->class_name(), q[Bio::MAGE::Describable],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $describable = Bio::MAGE::Describable->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Describable->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $describable = Bio::MAGE::Describable->new(descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($describable->getDescriptions,'ARRAY')
 and scalar @{$describable->getDescriptions} == 1
 and UNIVERSAL::isa($describable->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($describable->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($describable->getDescriptions,'ARRAY')
 and scalar @{$describable->getDescriptions} == 1
 and $describable->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($describable->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($describable->getDescriptions,'ARRAY')
 and scalar @{$describable->getDescriptions} == 2
 and $describable->getDescriptions->[0] == $descriptions_assn
 and $describable->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$describable->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$describable->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$describable->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$describable->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$describable->setDescriptions([])};
ok((!$@ and defined $describable->getDescriptions()
    and UNIVERSAL::isa($describable->getDescriptions, 'ARRAY')
    and scalar @{$describable->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$describable->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$describable->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$describable->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$describable->setDescriptions(undef)};
ok((!$@ and not defined $describable->getDescriptions()),
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


isa_ok($describable->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($describable->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($describable->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$describable->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$describable->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$describable->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$describable->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$describable->setSecurity(undef)};
ok((!$@ and not defined $describable->getSecurity()),
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


ok((UNIVERSAL::isa($describable->getAuditTrail,'ARRAY')
 and scalar @{$describable->getAuditTrail} == 1
 and UNIVERSAL::isa($describable->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($describable->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($describable->getAuditTrail,'ARRAY')
 and scalar @{$describable->getAuditTrail} == 1
 and $describable->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($describable->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($describable->getAuditTrail,'ARRAY')
 and scalar @{$describable->getAuditTrail} == 2
 and $describable->getAuditTrail->[0] == $audittrail_assn
 and $describable->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$describable->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$describable->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$describable->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$describable->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$describable->setAuditTrail([])};
ok((!$@ and defined $describable->getAuditTrail()
    and UNIVERSAL::isa($describable->getAuditTrail, 'ARRAY')
    and scalar @{$describable->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$describable->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$describable->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$describable->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$describable->setAuditTrail(undef)};
ok((!$@ and not defined $describable->getAuditTrail()),
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


ok((UNIVERSAL::isa($describable->getPropertySets,'ARRAY')
 and scalar @{$describable->getPropertySets} == 1
 and UNIVERSAL::isa($describable->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($describable->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($describable->getPropertySets,'ARRAY')
 and scalar @{$describable->getPropertySets} == 1
 and $describable->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($describable->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($describable->getPropertySets,'ARRAY')
 and scalar @{$describable->getPropertySets} == 2
 and $describable->getPropertySets->[0] == $propertysets_assn
 and $describable->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$describable->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$describable->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$describable->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$describable->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$describable->setPropertySets([])};
ok((!$@ and defined $describable->getPropertySets()
    and UNIVERSAL::isa($describable->getPropertySets, 'ARRAY')
    and scalar @{$describable->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$describable->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$describable->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$describable->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$describable->setPropertySets(undef)};
ok((!$@ and not defined $describable->getPropertySets()),
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
my $node = Bio::MAGE::HigherLevelAnalysis::Node->new();

# testing subclass Node
isa_ok($node, q[Bio::MAGE::HigherLevelAnalysis::Node]);
isa_ok($node, q[Bio::MAGE::Describable]);


# create a subclass
my $nodecontents = Bio::MAGE::HigherLevelAnalysis::NodeContents->new();

# testing subclass NodeContents
isa_ok($nodecontents, q[Bio::MAGE::HigherLevelAnalysis::NodeContents]);
isa_ok($nodecontents, q[Bio::MAGE::Describable]);


# create a subclass
my $description = Bio::MAGE::Description::Description->new();

# testing subclass Description
isa_ok($description, q[Bio::MAGE::Description::Description]);
isa_ok($description, q[Bio::MAGE::Describable]);


# create a subclass
my $audit = Bio::MAGE::AuditAndSecurity::Audit->new();

# testing subclass Audit
isa_ok($audit, q[Bio::MAGE::AuditAndSecurity::Audit]);
isa_ok($audit, q[Bio::MAGE::Describable]);


# create a subclass
my $identifiable = Bio::MAGE::Identifiable->new();

# testing subclass Identifiable
isa_ok($identifiable, q[Bio::MAGE::Identifiable]);
isa_ok($identifiable, q[Bio::MAGE::Describable]);


# create a subclass
my $fiducial = Bio::MAGE::Array::Fiducial->new();

# testing subclass Fiducial
isa_ok($fiducial, q[Bio::MAGE::Array::Fiducial]);
isa_ok($fiducial, q[Bio::MAGE::Describable]);


# create a subclass
my $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new();

# testing subclass BibliographicReference
isa_ok($bibliographicreference, q[Bio::MAGE::BQS::BibliographicReference]);
isa_ok($bibliographicreference, q[Bio::MAGE::Describable]);


# create a subclass
my $experimentdesign = Bio::MAGE::Experiment::ExperimentDesign->new();

# testing subclass ExperimentDesign
isa_ok($experimentdesign, q[Bio::MAGE::Experiment::ExperimentDesign]);
isa_ok($experimentdesign, q[Bio::MAGE::Describable]);


# create a subclass
my $manufacturelims = Bio::MAGE::Array::ManufactureLIMS->new();

# testing subclass ManufactureLIMS
isa_ok($manufacturelims, q[Bio::MAGE::Array::ManufactureLIMS]);
isa_ok($manufacturelims, q[Bio::MAGE::Describable]);


# create a subclass
my $seqfeature = Bio::MAGE::BioSequence::SeqFeature->new();

# testing subclass SeqFeature
isa_ok($seqfeature, q[Bio::MAGE::BioSequence::SeqFeature]);
isa_ok($seqfeature, q[Bio::MAGE::Describable]);


# create a subclass
my $parameterizableapplication = Bio::MAGE::Protocol::ParameterizableApplication->new();

# testing subclass ParameterizableApplication
isa_ok($parameterizableapplication, q[Bio::MAGE::Protocol::ParameterizableApplication]);
isa_ok($parameterizableapplication, q[Bio::MAGE::Describable]);



my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($describable, q[Bio::MAGE::Extendable]);

