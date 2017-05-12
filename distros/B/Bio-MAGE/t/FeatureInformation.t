##############################
#
# FeatureInformation.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FeatureInformation.t`

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
use Test::More tests => 57;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::DesignElement::FeatureInformation') };

use Bio::MAGE::DesignElement::MismatchInformation;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::Feature;


# we test the new() method
my $featureinformation;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureinformation = Bio::MAGE::DesignElement::FeatureInformation->new();
}
isa_ok($featureinformation, 'Bio::MAGE::DesignElement::FeatureInformation');

# test the package_name class method
is($featureinformation->package_name(), q[DesignElement],
  'package');

# test the class_name class method
is($featureinformation->class_name(), q[Bio::MAGE::DesignElement::FeatureInformation],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureinformation = Bio::MAGE::DesignElement::FeatureInformation->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::DesignElement::FeatureInformation->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $featureinformation = Bio::MAGE::DesignElement::FeatureInformation->new(feature => Bio::MAGE::DesignElement::Feature->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
mismatchInformation => [Bio::MAGE::DesignElement::MismatchInformation->new()]);
}

my ($end, $assn);


# testing association feature
my $feature_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $feature_assn = Bio::MAGE::DesignElement::Feature->new();
}


isa_ok($featureinformation->getFeature, q[Bio::MAGE::DesignElement::Feature]);

is($featureinformation->setFeature($feature_assn), $feature_assn,
  'setFeature returns value');

ok($featureinformation->getFeature() == $feature_assn,
   'getFeature fetches correct value');

# test setFeature throws exception with bad argument
eval {$featureinformation->setFeature(1)};
ok($@, 'setFeature throws exception with bad argument');


# test getFeature throws exception with argument
eval {$featureinformation->getFeature(1)};
ok($@, 'getFeature throws exception with argument');

# test setFeature throws exception with no argument
eval {$featureinformation->setFeature()};
ok($@, 'setFeature throws exception with no argument');

# test setFeature throws exception with too many argument
eval {$featureinformation->setFeature(1,2)};
ok($@, 'setFeature throws exception with too many argument');

# test setFeature accepts undef
eval {$featureinformation->setFeature(undef)};
ok((!$@ and not defined $featureinformation->getFeature()),
   'setFeature accepts undef');

# test the meta-data for the assoication
$assn = $assns{feature};
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
   'feature->other() is a valid Bio::MAGE::Association::End'
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
   'feature->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($featureinformation->getPropertySets,'ARRAY')
 and scalar @{$featureinformation->getPropertySets} == 1
 and UNIVERSAL::isa($featureinformation->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($featureinformation->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($featureinformation->getPropertySets,'ARRAY')
 and scalar @{$featureinformation->getPropertySets} == 1
 and $featureinformation->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($featureinformation->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($featureinformation->getPropertySets,'ARRAY')
 and scalar @{$featureinformation->getPropertySets} == 2
 and $featureinformation->getPropertySets->[0] == $propertysets_assn
 and $featureinformation->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$featureinformation->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$featureinformation->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$featureinformation->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$featureinformation->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$featureinformation->setPropertySets([])};
ok((!$@ and defined $featureinformation->getPropertySets()
    and UNIVERSAL::isa($featureinformation->getPropertySets, 'ARRAY')
    and scalar @{$featureinformation->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$featureinformation->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$featureinformation->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$featureinformation->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$featureinformation->setPropertySets(undef)};
ok((!$@ and not defined $featureinformation->getPropertySets()),
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



# testing association mismatchInformation
my $mismatchinformation_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $mismatchinformation_assn = Bio::MAGE::DesignElement::MismatchInformation->new();
}


ok((UNIVERSAL::isa($featureinformation->getMismatchInformation,'ARRAY')
 and scalar @{$featureinformation->getMismatchInformation} == 1
 and UNIVERSAL::isa($featureinformation->getMismatchInformation->[0], q[Bio::MAGE::DesignElement::MismatchInformation])),
  'mismatchInformation set in new()');

ok(eq_array($featureinformation->setMismatchInformation([$mismatchinformation_assn]), [$mismatchinformation_assn]),
   'setMismatchInformation returns correct value');

ok((UNIVERSAL::isa($featureinformation->getMismatchInformation,'ARRAY')
 and scalar @{$featureinformation->getMismatchInformation} == 1
 and $featureinformation->getMismatchInformation->[0] == $mismatchinformation_assn),
   'getMismatchInformation fetches correct value');

is($featureinformation->addMismatchInformation($mismatchinformation_assn), 2,
  'addMismatchInformation returns number of items in list');

ok((UNIVERSAL::isa($featureinformation->getMismatchInformation,'ARRAY')
 and scalar @{$featureinformation->getMismatchInformation} == 2
 and $featureinformation->getMismatchInformation->[0] == $mismatchinformation_assn
 and $featureinformation->getMismatchInformation->[1] == $mismatchinformation_assn),
  'addMismatchInformation adds correct value');

# test setMismatchInformation throws exception with non-array argument
eval {$featureinformation->setMismatchInformation(1)};
ok($@, 'setMismatchInformation throws exception with non-array argument');

# test setMismatchInformation throws exception with bad argument array
eval {$featureinformation->setMismatchInformation([1])};
ok($@, 'setMismatchInformation throws exception with bad argument array');

# test addMismatchInformation throws exception with no arguments
eval {$featureinformation->addMismatchInformation()};
ok($@, 'addMismatchInformation throws exception with no arguments');

# test addMismatchInformation throws exception with bad argument
eval {$featureinformation->addMismatchInformation(1)};
ok($@, 'addMismatchInformation throws exception with bad array');

# test setMismatchInformation accepts empty array ref
eval {$featureinformation->setMismatchInformation([])};
ok((!$@ and defined $featureinformation->getMismatchInformation()
    and UNIVERSAL::isa($featureinformation->getMismatchInformation, 'ARRAY')
    and scalar @{$featureinformation->getMismatchInformation} == 0),
   'setMismatchInformation accepts empty array ref');


# test getMismatchInformation throws exception with argument
eval {$featureinformation->getMismatchInformation(1)};
ok($@, 'getMismatchInformation throws exception with argument');

# test setMismatchInformation throws exception with no argument
eval {$featureinformation->setMismatchInformation()};
ok($@, 'setMismatchInformation throws exception with no argument');

# test setMismatchInformation throws exception with too many argument
eval {$featureinformation->setMismatchInformation(1,2)};
ok($@, 'setMismatchInformation throws exception with too many argument');

# test setMismatchInformation accepts undef
eval {$featureinformation->setMismatchInformation(undef)};
ok((!$@ and not defined $featureinformation->getMismatchInformation()),
   'setMismatchInformation accepts undef');

# test the meta-data for the assoication
$assn = $assns{mismatchInformation};
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
   'mismatchInformation->other() is a valid Bio::MAGE::Association::End'
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
   'mismatchInformation->self() is a valid Bio::MAGE::Association::End'
  );





my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};

  # create a superclass
  $extendable = Bio::MAGE::Extendable->new();
}

# testing superclass Extendable
isa_ok($extendable, q[Bio::MAGE::Extendable]);
isa_ok($featureinformation, q[Bio::MAGE::Extendable]);

