##############################
#
# BioAssayDatum.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BioAssayDatum.t`

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
use Test::More tests => 70;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::BioAssayData::BioAssayDatum') };

use Bio::MAGE::BioAssay::BioAssay;
use Bio::MAGE::NameValueType;
use Bio::MAGE::DesignElement::DesignElement;
use Bio::MAGE::QuantitationType::QuantitationType;


# we test the new() method
my $bioassaydatum;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatum = Bio::MAGE::BioAssayData::BioAssayDatum->new();
}
isa_ok($bioassaydatum, 'Bio::MAGE::BioAssayData::BioAssayDatum');

# test the package_name class method
is($bioassaydatum->package_name(), q[BioAssayData],
  'package');

# test the class_name class method
is($bioassaydatum->class_name(), q[Bio::MAGE::BioAssayData::BioAssayDatum],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatum = Bio::MAGE::BioAssayData::BioAssayDatum->new(value => '1');
}


#
# testing attribute value
#

# test attribute values can be set in new()
is($bioassaydatum->getValue(), '1',
  'value new');

# test getter/setter
$bioassaydatum->setValue('1');
is($bioassaydatum->getValue(), '1',
  'value getter/setter');

# test getter throws exception with argument
eval {$bioassaydatum->getValue(1)};
ok($@, 'value getter throws exception with argument');

# test setter throws exception with no argument
eval {$bioassaydatum->setValue()};
ok($@, 'value setter throws exception with no argument');

# test setter throws exception with too many argument
eval {$bioassaydatum->setValue('1', '1')};
ok($@, 'value setter throws exception with too many argument');

# test setter accepts undef
eval {$bioassaydatum->setValue(undef)};
ok((!$@ and not defined $bioassaydatum->getValue()),
   'value setter accepts undef');



# retrieve the list of association meta-data
my %assns = Bio::MAGE::BioAssayData::BioAssayDatum->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassaydatum = Bio::MAGE::BioAssayData::BioAssayDatum->new(quantitationType => Bio::MAGE::QuantitationType::QuantitationType->new(),
bioAssay => Bio::MAGE::BioAssay::BioAssay->new(),
propertySets => [Bio::MAGE::NameValueType->new()],
designElement => Bio::MAGE::DesignElement::DesignElement->new());
}

my ($end, $assn);


# testing association quantitationType
my $quantitationtype_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $quantitationtype_assn = Bio::MAGE::QuantitationType::QuantitationType->new();
}


isa_ok($bioassaydatum->getQuantitationType, q[Bio::MAGE::QuantitationType::QuantitationType]);

is($bioassaydatum->setQuantitationType($quantitationtype_assn), $quantitationtype_assn,
  'setQuantitationType returns value');

ok($bioassaydatum->getQuantitationType() == $quantitationtype_assn,
   'getQuantitationType fetches correct value');

# test setQuantitationType throws exception with bad argument
eval {$bioassaydatum->setQuantitationType(1)};
ok($@, 'setQuantitationType throws exception with bad argument');


# test getQuantitationType throws exception with argument
eval {$bioassaydatum->getQuantitationType(1)};
ok($@, 'getQuantitationType throws exception with argument');

# test setQuantitationType throws exception with no argument
eval {$bioassaydatum->setQuantitationType()};
ok($@, 'setQuantitationType throws exception with no argument');

# test setQuantitationType throws exception with too many argument
eval {$bioassaydatum->setQuantitationType(1,2)};
ok($@, 'setQuantitationType throws exception with too many argument');

# test setQuantitationType accepts undef
eval {$bioassaydatum->setQuantitationType(undef)};
ok((!$@ and not defined $bioassaydatum->getQuantitationType()),
   'setQuantitationType accepts undef');

# test the meta-data for the assoication
$assn = $assns{quantitationType};
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
   'quantitationType->other() is a valid Bio::MAGE::Association::End'
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
   'quantitationType->self() is a valid Bio::MAGE::Association::End'
  );



# testing association bioAssay
my $bioassay_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $bioassay_assn = Bio::MAGE::BioAssay::BioAssay->new();
}


isa_ok($bioassaydatum->getBioAssay, q[Bio::MAGE::BioAssay::BioAssay]);

is($bioassaydatum->setBioAssay($bioassay_assn), $bioassay_assn,
  'setBioAssay returns value');

ok($bioassaydatum->getBioAssay() == $bioassay_assn,
   'getBioAssay fetches correct value');

# test setBioAssay throws exception with bad argument
eval {$bioassaydatum->setBioAssay(1)};
ok($@, 'setBioAssay throws exception with bad argument');


# test getBioAssay throws exception with argument
eval {$bioassaydatum->getBioAssay(1)};
ok($@, 'getBioAssay throws exception with argument');

# test setBioAssay throws exception with no argument
eval {$bioassaydatum->setBioAssay()};
ok($@, 'setBioAssay throws exception with no argument');

# test setBioAssay throws exception with too many argument
eval {$bioassaydatum->setBioAssay(1,2)};
ok($@, 'setBioAssay throws exception with too many argument');

# test setBioAssay accepts undef
eval {$bioassaydatum->setBioAssay(undef)};
ok((!$@ and not defined $bioassaydatum->getBioAssay()),
   'setBioAssay accepts undef');

# test the meta-data for the assoication
$assn = $assns{bioAssay};
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
   'bioAssay->other() is a valid Bio::MAGE::Association::End'
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
   'bioAssay->self() is a valid Bio::MAGE::Association::End'
  );



# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($bioassaydatum->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatum->getPropertySets} == 1
 and UNIVERSAL::isa($bioassaydatum->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($bioassaydatum->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($bioassaydatum->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatum->getPropertySets} == 1
 and $bioassaydatum->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($bioassaydatum->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($bioassaydatum->getPropertySets,'ARRAY')
 and scalar @{$bioassaydatum->getPropertySets} == 2
 and $bioassaydatum->getPropertySets->[0] == $propertysets_assn
 and $bioassaydatum->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$bioassaydatum->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$bioassaydatum->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$bioassaydatum->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$bioassaydatum->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$bioassaydatum->setPropertySets([])};
ok((!$@ and defined $bioassaydatum->getPropertySets()
    and UNIVERSAL::isa($bioassaydatum->getPropertySets, 'ARRAY')
    and scalar @{$bioassaydatum->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$bioassaydatum->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$bioassaydatum->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$bioassaydatum->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$bioassaydatum->setPropertySets(undef)};
ok((!$@ and not defined $bioassaydatum->getPropertySets()),
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



# testing association designElement
my $designelement_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $designelement_assn = Bio::MAGE::DesignElement::DesignElement->new();
}


isa_ok($bioassaydatum->getDesignElement, q[Bio::MAGE::DesignElement::DesignElement]);

is($bioassaydatum->setDesignElement($designelement_assn), $designelement_assn,
  'setDesignElement returns value');

ok($bioassaydatum->getDesignElement() == $designelement_assn,
   'getDesignElement fetches correct value');

# test setDesignElement throws exception with bad argument
eval {$bioassaydatum->setDesignElement(1)};
ok($@, 'setDesignElement throws exception with bad argument');


# test getDesignElement throws exception with argument
eval {$bioassaydatum->getDesignElement(1)};
ok($@, 'getDesignElement throws exception with argument');

# test setDesignElement throws exception with no argument
eval {$bioassaydatum->setDesignElement()};
ok($@, 'setDesignElement throws exception with no argument');

# test setDesignElement throws exception with too many argument
eval {$bioassaydatum->setDesignElement(1,2)};
ok($@, 'setDesignElement throws exception with too many argument');

# test setDesignElement accepts undef
eval {$bioassaydatum->setDesignElement(undef)};
ok((!$@ and not defined $bioassaydatum->getDesignElement()),
   'setDesignElement accepts undef');

# test the meta-data for the assoication
$assn = $assns{designElement};
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
   'designElement->other() is a valid Bio::MAGE::Association::End'
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
   'designElement->self() is a valid Bio::MAGE::Association::End'
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
isa_ok($bioassaydatum, q[Bio::MAGE::Extendable]);

