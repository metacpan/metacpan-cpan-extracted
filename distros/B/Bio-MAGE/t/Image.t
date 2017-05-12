##############################
#
# Image.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Image.t`

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
use Test::More tests => 126;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssay::Image') };

use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::NameValueType;
use Bio::MAGE::BioAssay::Channel;
use Bio::MAGE::AuditAndSecurity::Audit;
use Bio::MAGE::AuditAndSecurity::Security;
use Bio::MAGE::Description::Description;


# we test the new() method
my $image;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $image = Bio::MAGE::BioAssay::Image->new();
}
isa_ok($image, 'Bio::MAGE::BioAssay::Image');

# test the package_name class method
is($image->package_name(), q[BioAssay],
  'package');

# test the class_name class method
is($image->class_name(), q[Bio::MAGE::BioAssay::Image],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $image = Bio::MAGE::BioAssay::Image->new(URI => '1',
identifier => '2',
name => '3');
}


#
# testing attribute URI
#

# test attribute values can be set in new()
is($image->getURI(), '1',
  'URI new');

# test getter/setter
$image->setURI('1');
is($image->getURI(), '1',
  'URI getter/setter');

# test getter throws exception with argument
eval {$image->getURI(1)};
ok($@, 'URI getter throws exception with argument');

# test setter throws exception with no argument
eval {$image->setURI()};
ok($@, 'URI setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$image->setURI('1', '1')};
ok($@, 'URI setter throws exception with too many argument');

# test setter accepts undef
eval {$image->setURI(undef)};
ok((!$@ and not defined $image->getURI()),
   'URI setter accepts undef');



#
# testing attribute identifier
#

# test attribute values can be set in new()
is($image->getIdentifier(), '2',
  'identifier new');

# test getter/setter
$image->setIdentifier('2');
is($image->getIdentifier(), '2',
  'identifier getter/setter');

# test getter throws exception with argument
eval {$image->getIdentifier(1)};
ok($@, 'identifier getter throws exception with argument');

# test setter throws exception with no argument
eval {$image->setIdentifier()};
ok($@, 'identifier setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$image->setIdentifier('2', '2')};
ok($@, 'identifier setter throws exception with too many argument');

# test setter accepts undef
eval {$image->setIdentifier(undef)};
ok((!$@ and not defined $image->getIdentifier()),
   'identifier setter accepts undef');



#
# testing attribute name
#

# test attribute values can be set in new()
is($image->getName(), '3',
  'name new');

# test getter/setter
$image->setName('3');
is($image->getName(), '3',
  'name getter/setter');

# test getter throws exception with argument
eval {$image->getName(1)};
ok($@, 'name getter throws exception with argument');

# test setter throws exception with no argument
eval {$image->setName()};
ok($@, 'name setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$image->setName('3', '3')};
ok($@, 'name setter throws exception with too many argument');

# test setter accepts undef
eval {$image->setName(undef)};
ok((!$@ and not defined $image->getName()),
   'name setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssay::Image->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $image = Bio::MAGE::BioAssay::Image->new(channels => [Bio::MAGE::BioAssay::Channel->new()],
format => Bio::MAGE::Description::OntologyEntry->new(),
descriptions => [Bio::MAGE::Description::Description->new()],
security => Bio::MAGE::AuditAndSecurity::Security->new(),
auditTrail => [Bio::MAGE::AuditAndSecurity::Audit->new()],
propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association channels
my $channels_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $channels_assn = Bio::MAGE::BioAssay::Channel->new();
}


ok((UNIVERSAL::isa($image->getChannels,'ARRAY')
 and scalar @{$image->getChannels} == 1
 and UNIVERSAL::isa($image->getChannels->[0], q[Bio::MAGE::BioAssay::Channel])),
  'channels set in new()');

ok(eq_array($image->setChannels([$channels_assn]), [$channels_assn]),
   'setChannels returns correct value');

ok((UNIVERSAL::isa($image->getChannels,'ARRAY')
 and scalar @{$image->getChannels} == 1
 and $image->getChannels->[0] == $channels_assn),
   'getChannels fetches correct value');

is($image->addChannels($channels_assn), 2,
  'addChannels returns number of items in list');

ok((UNIVERSAL::isa($image->getChannels,'ARRAY')
 and scalar @{$image->getChannels} == 2
 and $image->getChannels->[0] == $channels_assn
 and $image->getChannels->[1] == $channels_assn),
  'addChannels adds correct value');

# test setChannels throws exception with non-array argument
eval {$image->setChannels(1)};
ok($@, 'setChannels throws exception with non-array argument');

# test setChannels throws exception with bad argument array
eval {$image->setChannels([1])};
ok($@, 'setChannels throws exception with bad argument array');

# test addChannels throws exception with no arguments
eval {$image->addChannels()};
ok($@, 'addChannels throws exception with no arguments');

# test addChannels throws exception with bad argument
eval {$image->addChannels(1)};
ok($@, 'addChannels throws exception with bad array');

# test setChannels accepts empty array ref
eval {$image->setChannels([])};
ok((!$@ and defined $image->getChannels()
    and UNIVERSAL::isa($image->getChannels, 'ARRAY')
    and scalar @{$image->getChannels} == 0),
   'setChannels accepts empty array ref');


# test getChannels throws exception with argument
eval {$image->getChannels(1)};
ok($@, 'getChannels throws exception with argument');

# test setChannels throws exception with no argument
eval {$image->setChannels()};
ok($@, 'setChannels throws exception with no argument');

# test setChannels throws exception with too many argument
eval {$image->setChannels(1,2)};
ok($@, 'setChannels throws exception with too many argument');

# test setChannels accepts undef
eval {$image->setChannels(undef)};
ok((!$@ and not defined $image->getChannels()),
   'setChannels accepts undef');

# test the meta-data for the assoication
$assn = $assns{channels};
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
   'channels->other() is a valid Bio::MAGE::Association::End'
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
   'channels->self() is a valid Bio::MAGE::Association::End'
  );



# testing association format
my $format_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $format_assn = Bio::MAGE::Description::OntologyEntry->new();
}


isa_ok($image->getFormat, q[Bio::MAGE::Description::OntologyEntry]);

is($image->setFormat($format_assn), $format_assn,
  'setFormat returns value');

ok($image->getFormat() == $format_assn,
   'getFormat fetches correct value');

# test setFormat throws exception with bad argument
eval {$image->setFormat(1)};
ok($@, 'setFormat throws exception with bad argument');


# test getFormat throws exception with argument
eval {$image->getFormat(1)};
ok($@, 'getFormat throws exception with argument');

# test setFormat throws exception with no argument
eval {$image->setFormat()};
ok($@, 'setFormat throws exception with no argument');

# test setFormat throws exception with too many argument
eval {$image->setFormat(1,2)};
ok($@, 'setFormat throws exception with too many argument');

# test setFormat accepts undef
eval {$image->setFormat(undef)};
ok((!$@ and not defined $image->getFormat()),
   'setFormat accepts undef');

# test the meta-data for the assoication
$assn = $assns{format};
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
   'format->other() is a valid Bio::MAGE::Association::End'
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
   'format->self() is a valid Bio::MAGE::Association::End'
  );



# testing association descriptions
my $descriptions_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $descriptions_assn = Bio::MAGE::Description::Description->new();
}


ok((UNIVERSAL::isa($image->getDescriptions,'ARRAY')
 and scalar @{$image->getDescriptions} == 1
 and UNIVERSAL::isa($image->getDescriptions->[0], q[Bio::MAGE::Description::Description])),
  'descriptions set in new()');

ok(eq_array($image->setDescriptions([$descriptions_assn]), [$descriptions_assn]),
   'setDescriptions returns correct value');

ok((UNIVERSAL::isa($image->getDescriptions,'ARRAY')
 and scalar @{$image->getDescriptions} == 1
 and $image->getDescriptions->[0] == $descriptions_assn),
   'getDescriptions fetches correct value');

is($image->addDescriptions($descriptions_assn), 2,
  'addDescriptions returns number of items in list');

ok((UNIVERSAL::isa($image->getDescriptions,'ARRAY')
 and scalar @{$image->getDescriptions} == 2
 and $image->getDescriptions->[0] == $descriptions_assn
 and $image->getDescriptions->[1] == $descriptions_assn),
  'addDescriptions adds correct value');

# test setDescriptions throws exception with non-array argument
eval {$image->setDescriptions(1)};
ok($@, 'setDescriptions throws exception with non-array argument');

# test setDescriptions throws exception with bad argument array
eval {$image->setDescriptions([1])};
ok($@, 'setDescriptions throws exception with bad argument array');

# test addDescriptions throws exception with no arguments
eval {$image->addDescriptions()};
ok($@, 'addDescriptions throws exception with no arguments');

# test addDescriptions throws exception with bad argument
eval {$image->addDescriptions(1)};
ok($@, 'addDescriptions throws exception with bad array');

# test setDescriptions accepts empty array ref
eval {$image->setDescriptions([])};
ok((!$@ and defined $image->getDescriptions()
    and UNIVERSAL::isa($image->getDescriptions, 'ARRAY')
    and scalar @{$image->getDescriptions} == 0),
   'setDescriptions accepts empty array ref');


# test getDescriptions throws exception with argument
eval {$image->getDescriptions(1)};
ok($@, 'getDescriptions throws exception with argument');

# test setDescriptions throws exception with no argument
eval {$image->setDescriptions()};
ok($@, 'setDescriptions throws exception with no argument');

# test setDescriptions throws exception with too many argument
eval {$image->setDescriptions(1,2)};
ok($@, 'setDescriptions throws exception with too many argument');

# test setDescriptions accepts undef
eval {$image->setDescriptions(undef)};
ok((!$@ and not defined $image->getDescriptions()),
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


isa_ok($image->getSecurity, q[Bio::MAGE::AuditAndSecurity::Security]);

is($image->setSecurity($security_assn), $security_assn,
  'setSecurity returns value');

ok($image->getSecurity() == $security_assn,
   'getSecurity fetches correct value');

# test setSecurity throws exception with bad argument
eval {$image->setSecurity(1)};
ok($@, 'setSecurity throws exception with bad argument');


# test getSecurity throws exception with argument
eval {$image->getSecurity(1)};
ok($@, 'getSecurity throws exception with argument');

# test setSecurity throws exception with no argument
eval {$image->setSecurity()};
ok($@, 'setSecurity throws exception with no argument');

# test setSecurity throws exception with too many argument
eval {$image->setSecurity(1,2)};
ok($@, 'setSecurity throws exception with too many argument');

# test setSecurity accepts undef
eval {$image->setSecurity(undef)};
ok((!$@ and not defined $image->getSecurity()),
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


ok((UNIVERSAL::isa($image->getAuditTrail,'ARRAY')
 and scalar @{$image->getAuditTrail} == 1
 and UNIVERSAL::isa($image->getAuditTrail->[0], q[Bio::MAGE::AuditAndSecurity::Audit])),
  'auditTrail set in new()');

ok(eq_array($image->setAuditTrail([$audittrail_assn]), [$audittrail_assn]),
   'setAuditTrail returns correct value');

ok((UNIVERSAL::isa($image->getAuditTrail,'ARRAY')
 and scalar @{$image->getAuditTrail} == 1
 and $image->getAuditTrail->[0] == $audittrail_assn),
   'getAuditTrail fetches correct value');

is($image->addAuditTrail($audittrail_assn), 2,
  'addAuditTrail returns number of items in list');

ok((UNIVERSAL::isa($image->getAuditTrail,'ARRAY')
 and scalar @{$image->getAuditTrail} == 2
 and $image->getAuditTrail->[0] == $audittrail_assn
 and $image->getAuditTrail->[1] == $audittrail_assn),
  'addAuditTrail adds correct value');

# test setAuditTrail throws exception with non-array argument
eval {$image->setAuditTrail(1)};
ok($@, 'setAuditTrail throws exception with non-array argument');

# test setAuditTrail throws exception with bad argument array
eval {$image->setAuditTrail([1])};
ok($@, 'setAuditTrail throws exception with bad argument array');

# test addAuditTrail throws exception with no arguments
eval {$image->addAuditTrail()};
ok($@, 'addAuditTrail throws exception with no arguments');

# test addAuditTrail throws exception with bad argument
eval {$image->addAuditTrail(1)};
ok($@, 'addAuditTrail throws exception with bad array');

# test setAuditTrail accepts empty array ref
eval {$image->setAuditTrail([])};
ok((!$@ and defined $image->getAuditTrail()
    and UNIVERSAL::isa($image->getAuditTrail, 'ARRAY')
    and scalar @{$image->getAuditTrail} == 0),
   'setAuditTrail accepts empty array ref');


# test getAuditTrail throws exception with argument
eval {$image->getAuditTrail(1)};
ok($@, 'getAuditTrail throws exception with argument');

# test setAuditTrail throws exception with no argument
eval {$image->setAuditTrail()};
ok($@, 'setAuditTrail throws exception with no argument');

# test setAuditTrail throws exception with too many argument
eval {$image->setAuditTrail(1,2)};
ok($@, 'setAuditTrail throws exception with too many argument');

# test setAuditTrail accepts undef
eval {$image->setAuditTrail(undef)};
ok((!$@ and not defined $image->getAuditTrail()),
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


ok((UNIVERSAL::isa($image->getPropertySets,'ARRAY')
 and scalar @{$image->getPropertySets} == 1
 and UNIVERSAL::isa($image->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($image->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($image->getPropertySets,'ARRAY')
 and scalar @{$image->getPropertySets} == 1
 and $image->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($image->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($image->getPropertySets,'ARRAY')
 and scalar @{$image->getPropertySets} == 2
 and $image->getPropertySets->[0] == $propertysets_assn
 and $image->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$image->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$image->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$image->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$image->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$image->setPropertySets([])};
ok((!$@ and defined $image->getPropertySets()
    and UNIVERSAL::isa($image->getPropertySets, 'ARRAY')
    and scalar @{$image->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$image->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$image->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$image->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$image->setPropertySets(undef)};
ok((!$@ and not defined $image->getPropertySets()),
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
isa_ok($image, q[Bio::MAGE::Identifiable]);

