##############################
#
# Extendable.t
#

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Extendable.t`

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
use Test::More tests => 77;

use strict;

use Bio::MAGE;
use Bio::MAGE::Association;

BEGIN { use_ok('Bio::MAGE::Extendable') };

use Bio::MAGE::NameValueType;

use Bio::MAGE::HigherLevelAnalysis::NodeValue;
use Bio::MAGE::Description::DatabaseEntry;
use Bio::MAGE::ArrayDesign::ZoneLayout;
use Bio::MAGE::ArrayDesign::ZoneGroup;
use Bio::MAGE::Description::ExternalReference;
use Bio::MAGE::DesignElement::Position;
use Bio::MAGE::Description::OntologyEntry;
use Bio::MAGE::DesignElement::MismatchInformation;
use Bio::MAGE::Measurement::Measurement;
use Bio::MAGE::DesignElement::FeatureInformation;
use Bio::MAGE::Measurement::Unit;
use Bio::MAGE::BioAssayData::BioAssayMapping;
use Bio::MAGE::BioAssayData::BioAssayDatum;
use Bio::MAGE::Describable;
use Bio::MAGE::BioAssayData::QuantitationTypeMapping;
use Bio::MAGE::BioAssayData::DesignElementMapping;
use Bio::MAGE::DesignElement::FeatureLocation;
use Bio::MAGE::Array::FeatureDefect;
use Bio::MAGE::BioAssayData::BioDataValues;
use Bio::MAGE::Array::ArrayManufactureDeviation;
use Bio::MAGE::Array::PositionDelta;
use Bio::MAGE::Array::ZoneDefect;
use Bio::MAGE::Protocol::ParameterValue;
use Bio::MAGE::BioSequence::SeqFeatureLocation;
use Bio::MAGE::BioMaterial::CompoundMeasurement;
use Bio::MAGE::BioMaterial::BioMaterialMeasurement;
use Bio::MAGE::BioSequence::SequencePosition;

# we test the new() method
my $extendable;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $extendable = Bio::MAGE::Extendable->new();
}
isa_ok($extendable, 'Bio::MAGE::Extendable');

# test the package_name class method
is($extendable->package_name(), q[MAGE],
  'package');

# test the class_name class method
is($extendable->class_name(), q[Bio::MAGE::Extendable],
  'class_name');

# set the attribute values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $extendable = Bio::MAGE::Extendable->new();
}


# retrieve the list of association meta-data
my %assns = Bio::MAGE::Extendable->associations();

# set the association values in the call to new()
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $extendable = Bio::MAGE::Extendable->new(propertySets => [Bio::MAGE::NameValueType->new()]);
}

my ($end, $assn);


# testing association propertySets
my $propertysets_assn;
{
  # silence the abstract class warnings
  local $SIG{__WARN__} = sub {'IGNORE'};
  $propertysets_assn = Bio::MAGE::NameValueType->new();
}


ok((UNIVERSAL::isa($extendable->getPropertySets,'ARRAY')
 and scalar @{$extendable->getPropertySets} == 1
 and UNIVERSAL::isa($extendable->getPropertySets->[0], q[Bio::MAGE::NameValueType])),
  'propertySets set in new()');

ok(eq_array($extendable->setPropertySets([$propertysets_assn]), [$propertysets_assn]),
   'setPropertySets returns correct value');

ok((UNIVERSAL::isa($extendable->getPropertySets,'ARRAY')
 and scalar @{$extendable->getPropertySets} == 1
 and $extendable->getPropertySets->[0] == $propertysets_assn),
   'getPropertySets fetches correct value');

is($extendable->addPropertySets($propertysets_assn), 2,
  'addPropertySets returns number of items in list');

ok((UNIVERSAL::isa($extendable->getPropertySets,'ARRAY')
 and scalar @{$extendable->getPropertySets} == 2
 and $extendable->getPropertySets->[0] == $propertysets_assn
 and $extendable->getPropertySets->[1] == $propertysets_assn),
  'addPropertySets adds correct value');

# test setPropertySets throws exception with non-array argument
eval {$extendable->setPropertySets(1)};
ok($@, 'setPropertySets throws exception with non-array argument');

# test setPropertySets throws exception with bad argument array
eval {$extendable->setPropertySets([1])};
ok($@, 'setPropertySets throws exception with bad argument array');

# test addPropertySets throws exception with no arguments
eval {$extendable->addPropertySets()};
ok($@, 'addPropertySets throws exception with no arguments');

# test addPropertySets throws exception with bad argument
eval {$extendable->addPropertySets(1)};
ok($@, 'addPropertySets throws exception with bad array');

# test setPropertySets accepts empty array ref
eval {$extendable->setPropertySets([])};
ok((!$@ and defined $extendable->getPropertySets()
    and UNIVERSAL::isa($extendable->getPropertySets, 'ARRAY')
    and scalar @{$extendable->getPropertySets} == 0),
   'setPropertySets accepts empty array ref');


# test getPropertySets throws exception with argument
eval {$extendable->getPropertySets(1)};
ok($@, 'getPropertySets throws exception with argument');

# test setPropertySets throws exception with no argument
eval {$extendable->setPropertySets()};
ok($@, 'setPropertySets throws exception with no argument');

# test setPropertySets throws exception with too many argument
eval {$extendable->setPropertySets(1,2)};
ok($@, 'setPropertySets throws exception with too many argument');

# test setPropertySets accepts undef
eval {$extendable->setPropertySets(undef)};
ok((!$@ and not defined $extendable->getPropertySets()),
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
my $nodevalue = Bio::MAGE::HigherLevelAnalysis::NodeValue->new();

# testing subclass NodeValue
isa_ok($nodevalue, q[Bio::MAGE::HigherLevelAnalysis::NodeValue]);
isa_ok($nodevalue, q[Bio::MAGE::Extendable]);


# create a subclass
my $databaseentry = Bio::MAGE::Description::DatabaseEntry->new();

# testing subclass DatabaseEntry
isa_ok($databaseentry, q[Bio::MAGE::Description::DatabaseEntry]);
isa_ok($databaseentry, q[Bio::MAGE::Extendable]);


# create a subclass
my $zonelayout = Bio::MAGE::ArrayDesign::ZoneLayout->new();

# testing subclass ZoneLayout
isa_ok($zonelayout, q[Bio::MAGE::ArrayDesign::ZoneLayout]);
isa_ok($zonelayout, q[Bio::MAGE::Extendable]);


# create a subclass
my $zonegroup = Bio::MAGE::ArrayDesign::ZoneGroup->new();

# testing subclass ZoneGroup
isa_ok($zonegroup, q[Bio::MAGE::ArrayDesign::ZoneGroup]);
isa_ok($zonegroup, q[Bio::MAGE::Extendable]);


# create a subclass
my $externalreference = Bio::MAGE::Description::ExternalReference->new();

# testing subclass ExternalReference
isa_ok($externalreference, q[Bio::MAGE::Description::ExternalReference]);
isa_ok($externalreference, q[Bio::MAGE::Extendable]);


# create a subclass
my $position = Bio::MAGE::DesignElement::Position->new();

# testing subclass Position
isa_ok($position, q[Bio::MAGE::DesignElement::Position]);
isa_ok($position, q[Bio::MAGE::Extendable]);


# create a subclass
my $ontologyentry = Bio::MAGE::Description::OntologyEntry->new();

# testing subclass OntologyEntry
isa_ok($ontologyentry, q[Bio::MAGE::Description::OntologyEntry]);
isa_ok($ontologyentry, q[Bio::MAGE::Extendable]);


# create a subclass
my $mismatchinformation = Bio::MAGE::DesignElement::MismatchInformation->new();

# testing subclass MismatchInformation
isa_ok($mismatchinformation, q[Bio::MAGE::DesignElement::MismatchInformation]);
isa_ok($mismatchinformation, q[Bio::MAGE::Extendable]);


# create a subclass
my $measurement = Bio::MAGE::Measurement::Measurement->new();

# testing subclass Measurement
isa_ok($measurement, q[Bio::MAGE::Measurement::Measurement]);
isa_ok($measurement, q[Bio::MAGE::Extendable]);


# create a subclass
my $featureinformation = Bio::MAGE::DesignElement::FeatureInformation->new();

# testing subclass FeatureInformation
isa_ok($featureinformation, q[Bio::MAGE::DesignElement::FeatureInformation]);
isa_ok($featureinformation, q[Bio::MAGE::Extendable]);


# create a subclass
my $unit = Bio::MAGE::Measurement::Unit->new();

# testing subclass Unit
isa_ok($unit, q[Bio::MAGE::Measurement::Unit]);
isa_ok($unit, q[Bio::MAGE::Extendable]);


# create a subclass
my $bioassaymapping = Bio::MAGE::BioAssayData::BioAssayMapping->new();

# testing subclass BioAssayMapping
isa_ok($bioassaymapping, q[Bio::MAGE::BioAssayData::BioAssayMapping]);
isa_ok($bioassaymapping, q[Bio::MAGE::Extendable]);


# create a subclass
my $bioassaydatum = Bio::MAGE::BioAssayData::BioAssayDatum->new();

# testing subclass BioAssayDatum
isa_ok($bioassaydatum, q[Bio::MAGE::BioAssayData::BioAssayDatum]);
isa_ok($bioassaydatum, q[Bio::MAGE::Extendable]);


# create a subclass
my $describable = Bio::MAGE::Describable->new();

# testing subclass Describable
isa_ok($describable, q[Bio::MAGE::Describable]);
isa_ok($describable, q[Bio::MAGE::Extendable]);


# create a subclass
my $quantitationtypemapping = Bio::MAGE::BioAssayData::QuantitationTypeMapping->new();

# testing subclass QuantitationTypeMapping
isa_ok($quantitationtypemapping, q[Bio::MAGE::BioAssayData::QuantitationTypeMapping]);
isa_ok($quantitationtypemapping, q[Bio::MAGE::Extendable]);


# create a subclass
my $designelementmapping = Bio::MAGE::BioAssayData::DesignElementMapping->new();

# testing subclass DesignElementMapping
isa_ok($designelementmapping, q[Bio::MAGE::BioAssayData::DesignElementMapping]);
isa_ok($designelementmapping, q[Bio::MAGE::Extendable]);


# create a subclass
my $featurelocation = Bio::MAGE::DesignElement::FeatureLocation->new();

# testing subclass FeatureLocation
isa_ok($featurelocation, q[Bio::MAGE::DesignElement::FeatureLocation]);
isa_ok($featurelocation, q[Bio::MAGE::Extendable]);


# create a subclass
my $featuredefect = Bio::MAGE::Array::FeatureDefect->new();

# testing subclass FeatureDefect
isa_ok($featuredefect, q[Bio::MAGE::Array::FeatureDefect]);
isa_ok($featuredefect, q[Bio::MAGE::Extendable]);


# create a subclass
my $biodatavalues = Bio::MAGE::BioAssayData::BioDataValues->new();

# testing subclass BioDataValues
isa_ok($biodatavalues, q[Bio::MAGE::BioAssayData::BioDataValues]);
isa_ok($biodatavalues, q[Bio::MAGE::Extendable]);


# create a subclass
my $arraymanufacturedeviation = Bio::MAGE::Array::ArrayManufactureDeviation->new();

# testing subclass ArrayManufactureDeviation
isa_ok($arraymanufacturedeviation, q[Bio::MAGE::Array::ArrayManufactureDeviation]);
isa_ok($arraymanufacturedeviation, q[Bio::MAGE::Extendable]);


# create a subclass
my $positiondelta = Bio::MAGE::Array::PositionDelta->new();

# testing subclass PositionDelta
isa_ok($positiondelta, q[Bio::MAGE::Array::PositionDelta]);
isa_ok($positiondelta, q[Bio::MAGE::Extendable]);


# create a subclass
my $zonedefect = Bio::MAGE::Array::ZoneDefect->new();

# testing subclass ZoneDefect
isa_ok($zonedefect, q[Bio::MAGE::Array::ZoneDefect]);
isa_ok($zonedefect, q[Bio::MAGE::Extendable]);


# create a subclass
my $parametervalue = Bio::MAGE::Protocol::ParameterValue->new();

# testing subclass ParameterValue
isa_ok($parametervalue, q[Bio::MAGE::Protocol::ParameterValue]);
isa_ok($parametervalue, q[Bio::MAGE::Extendable]);


# create a subclass
my $seqfeaturelocation = Bio::MAGE::BioSequence::SeqFeatureLocation->new();

# testing subclass SeqFeatureLocation
isa_ok($seqfeaturelocation, q[Bio::MAGE::BioSequence::SeqFeatureLocation]);
isa_ok($seqfeaturelocation, q[Bio::MAGE::Extendable]);


# create a subclass
my $compoundmeasurement = Bio::MAGE::BioMaterial::CompoundMeasurement->new();

# testing subclass CompoundMeasurement
isa_ok($compoundmeasurement, q[Bio::MAGE::BioMaterial::CompoundMeasurement]);
isa_ok($compoundmeasurement, q[Bio::MAGE::Extendable]);


# create a subclass
my $biomaterialmeasurement = Bio::MAGE::BioMaterial::BioMaterialMeasurement->new();

# testing subclass BioMaterialMeasurement
isa_ok($biomaterialmeasurement, q[Bio::MAGE::BioMaterial::BioMaterialMeasurement]);
isa_ok($biomaterialmeasurement, q[Bio::MAGE::Extendable]);


# create a subclass
my $sequenceposition = Bio::MAGE::BioSequence::SequencePosition->new();

# testing subclass SequencePosition
isa_ok($sequenceposition, q[Bio::MAGE::BioSequence::SequencePosition]);
isa_ok($sequenceposition, q[Bio::MAGE::Extendable]);


