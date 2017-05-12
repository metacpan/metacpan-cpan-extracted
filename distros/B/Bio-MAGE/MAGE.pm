##############################
#
# Bio::MAGE
#
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



package Bio::MAGE;

use strict;

use base qw(Bio::MAGE::Base);

use Carp;
use Tie::IxHash;

use Bio::MAGE::NameValueType;
use Bio::MAGE::Extendable;
use Bio::MAGE::Identifiable;
use Bio::MAGE::Describable;

use base qw(Exporter);
use vars qw(%EXPORT_TAGS $__XML_PACKAGES $__CLASS2FULLCLASS $__XML_LISTS $VERSION);

$VERSION = 20030502.3;

 %EXPORT_TAGS = (ALL => ['']);

sub import {
  my ($pkg,@tags) = @_;
  foreach (@tags) {
    if ($_ =~ /ALL/) {
      import_all();
    }
  }
}

sub import_all {
  eval qq[
          require Bio::MAGE::HigherLevelAnalysis;
          require Bio::MAGE::BioEvent;
          require Bio::MAGE::BioMaterial;
          require Bio::MAGE::BioSequence;
          require Bio::MAGE::AuditAndSecurity;
          require Bio::MAGE::BioAssayData;
          require Bio::MAGE::BQS;
          require Bio::MAGE::Array;
          require Bio::MAGE::QuantitationType;
          require Bio::MAGE::Experiment;
          require Bio::MAGE::BioAssay;
          require Bio::MAGE::DesignElement;
          require Bio::MAGE::Protocol;
          require Bio::MAGE::Description;
          require Bio::MAGE::ArrayDesign;
          require Bio::MAGE::Measurement;
	 ];
  if ($@) {
    die __PACKAGE__ . "::import_all: load error: $@\n";
  }
}

sub initialize {
  my ($self) = shift;
  $self->identifiers({});
  $self->packages({});		# create packages on a per-need basis
  $self->registered_objects({});
  $self->tagname('MAGE-ML')
    unless defined $self->tagname();
  $self->add_objects($self->objects())
    if defined $self->objects();
  return 1;
}



=head1 NAME

Bio::MAGE - Container module for classes in the MAGE package: MAGE

=head1 SYNOPSIS

  use Bio::MAGE;

=head1 DESCRIPTION

This is a I<package> module that encapsulates a number of classes in
the Bio::MAGE hierarchy. These classes belong to the
MAGE package of the MAGE-OM object model.

=head1 CLASSES

The Bio::MAGE module contains the following
Bio::MAGE classes:

=over


=item * NameValueType


=item * Extendable


=item * Identifiable


=item * Describable


=back



=head1 CLASS METHODS

=over

=item @class_list = Bio::MAGE::classes();

This method returns a list of non-fully qualified class names
(i.e. they do not have 'Bio::MAGE::' as a prefix) in this package.

=cut

sub classes {
  return ('NameValueType','Extendable','Identifiable','Describable');
}

BEGIN {
  $__XML_PACKAGES = [
          'AuditAndSecurity',
          'Description',
          'Measurement',
          'BQS',
          'BioEvent',
          'Protocol',
          'BioMaterial',
          'BioSequence',
          'DesignElement',
          'ArrayDesign',
          'Array',
          'BioAssay',
          'QuantitationType',
          'BioAssayData',
          'Experiment',
          'HigherLevelAnalysis'
        ]
;
  $__CLASS2FULLCLASS = {
          'ReporterGroup' => 'Bio::MAGE::ArrayDesign::ReporterGroup',
          'SeqFeatureLocation' => 'Bio::MAGE::BioSequence::SeqFeatureLocation',
          'BibliographicReference' => 'Bio::MAGE::BQS::BibliographicReference',
          'BioDataTuples' => 'Bio::MAGE::BioAssayData::BioDataTuples',
          'ArrayGroup' => 'Bio::MAGE::Array::ArrayGroup',
          'DistanceUnit' => 'Bio::MAGE::Measurement::DistanceUnit',
          'ProtocolApplication' => 'Bio::MAGE::Protocol::ProtocolApplication',
          'ManufactureLIMS' => 'Bio::MAGE::Array::ManufactureLIMS',
          'FeatureReporterMap' => 'Bio::MAGE::DesignElement::FeatureReporterMap',
          'Hybridization' => 'Bio::MAGE::BioAssay::Hybridization',
          'Security' => 'Bio::MAGE::AuditAndSecurity::Security',
          'PositionDelta' => 'Bio::MAGE::Array::PositionDelta',
          'DerivedBioAssayData' => 'Bio::MAGE::BioAssayData::DerivedBioAssayData',
          'CompositePosition' => 'Bio::MAGE::DesignElement::CompositePosition',
          'Hardware' => 'Bio::MAGE::Protocol::Hardware',
          'ParameterValue' => 'Bio::MAGE::Protocol::ParameterValue',
          'CompositeCompositeMap' => 'Bio::MAGE::DesignElement::CompositeCompositeMap',
          'Audit' => 'Bio::MAGE::AuditAndSecurity::Audit',
          'BioAssay' => 'Bio::MAGE::BioAssay::BioAssay',
          'HardwareApplication' => 'Bio::MAGE::Protocol::HardwareApplication',
          'Unit' => 'Bio::MAGE::Measurement::Unit',
          'BioSource' => 'Bio::MAGE::BioMaterial::BioSource',
          'CompositeSequence' => 'Bio::MAGE::DesignElement::CompositeSequence',
          'PValue' => 'Bio::MAGE::QuantitationType::PValue',
          'BioAssayDimension' => 'Bio::MAGE::BioAssayData::BioAssayDimension',
          'StandardQuantitationType' => 'Bio::MAGE::QuantitationType::StandardQuantitationType',
          'MismatchInformation' => 'Bio::MAGE::DesignElement::MismatchInformation',
          'DesignElementDimension' => 'Bio::MAGE::BioAssayData::DesignElementDimension',
          'Parameter' => 'Bio::MAGE::Protocol::Parameter',
          'Feature' => 'Bio::MAGE::DesignElement::Feature',
          'FeatureGroup' => 'Bio::MAGE::ArrayDesign::FeatureGroup',
          'QuantitationType' => 'Bio::MAGE::QuantitationType::QuantitationType',
          'ExternalReference' => 'Bio::MAGE::Description::ExternalReference',
          'SequencePosition' => 'Bio::MAGE::BioSequence::SequencePosition',
          'BioEvent' => 'Bio::MAGE::BioEvent::BioEvent',
          'MeasuredBioAssay' => 'Bio::MAGE::BioAssay::MeasuredBioAssay',
          'CompositeGroup' => 'Bio::MAGE::ArrayDesign::CompositeGroup',
          'BioAssayDatum' => 'Bio::MAGE::BioAssayData::BioAssayDatum',
          'BioAssayTreatment' => 'Bio::MAGE::BioAssay::BioAssayTreatment',
          'Extendable' => 'Bio::MAGE::Extendable',
          'SoftwareApplication' => 'Bio::MAGE::Protocol::SoftwareApplication',
          'Node' => 'Bio::MAGE::HigherLevelAnalysis::Node',
          'NodeValue' => 'Bio::MAGE::HigherLevelAnalysis::NodeValue',
          'DerivedBioAssay' => 'Bio::MAGE::BioAssay::DerivedBioAssay',
          'DatabaseEntry' => 'Bio::MAGE::Description::DatabaseEntry',
          'Compound' => 'Bio::MAGE::BioMaterial::Compound',
          'ArrayDesign' => 'Bio::MAGE::ArrayDesign::ArrayDesign',
          'BioMaterialMeasurement' => 'Bio::MAGE::BioMaterial::BioMaterialMeasurement',
          'ConcentrationUnit' => 'Bio::MAGE::Measurement::ConcentrationUnit',
          'Transformation' => 'Bio::MAGE::BioAssayData::Transformation',
          'BioMaterial' => 'Bio::MAGE::BioMaterial::BioMaterial',
          'Treatment' => 'Bio::MAGE::BioMaterial::Treatment',
          'BioAssayData' => 'Bio::MAGE::BioAssayData::BioAssayData',
          'BioAssayCreation' => 'Bio::MAGE::BioAssay::BioAssayCreation',
          'ReporterDimension' => 'Bio::MAGE::BioAssayData::ReporterDimension',
          'ConfidenceIndicator' => 'Bio::MAGE::QuantitationType::ConfidenceIndicator',
          'Failed' => 'Bio::MAGE::QuantitationType::Failed',
          'ArrayManufactureDeviation' => 'Bio::MAGE::Array::ArrayManufactureDeviation',
          'SpecializedQuantitationType' => 'Bio::MAGE::QuantitationType::SpecializedQuantitationType',
          'FeatureInformation' => 'Bio::MAGE::DesignElement::FeatureInformation',
          'ExperimentDesign' => 'Bio::MAGE::Experiment::ExperimentDesign',
          'PhysicalArrayDesign' => 'Bio::MAGE::ArrayDesign::PhysicalArrayDesign',
          'PhysicalBioAssay' => 'Bio::MAGE::BioAssay::PhysicalBioAssay',
          'Ratio' => 'Bio::MAGE::QuantitationType::Ratio',
          'FeatureLocation' => 'Bio::MAGE::DesignElement::FeatureLocation',
          'DesignElement' => 'Bio::MAGE::DesignElement::DesignElement',
          'QuantitationTypeDimension' => 'Bio::MAGE::BioAssayData::QuantitationTypeDimension',
          'DerivedSignal' => 'Bio::MAGE::QuantitationType::DerivedSignal',
          'Fiducial' => 'Bio::MAGE::Array::Fiducial',
          'BioSequence' => 'Bio::MAGE::BioSequence::BioSequence',
          'ReporterPosition' => 'Bio::MAGE::DesignElement::ReporterPosition',
          'QuantitationTypeMapping' => 'Bio::MAGE::BioAssayData::QuantitationTypeMapping',
          'MeasuredBioAssayData' => 'Bio::MAGE::BioAssayData::MeasuredBioAssayData',
          'Identifiable' => 'Bio::MAGE::Identifiable',
          'Position' => 'Bio::MAGE::DesignElement::Position',
          'Array' => 'Bio::MAGE::Array::Array',
          'ExperimentalFactor' => 'Bio::MAGE::Experiment::ExperimentalFactor',
          'BioAssayMap' => 'Bio::MAGE::BioAssayData::BioAssayMap',
          'SeqFeature' => 'Bio::MAGE::BioSequence::SeqFeature',
          'OntologyEntry' => 'Bio::MAGE::Description::OntologyEntry',
          'ImageAcquisition' => 'Bio::MAGE::BioAssay::ImageAcquisition',
          'FeatureExtraction' => 'Bio::MAGE::BioAssay::FeatureExtraction',
          'Error' => 'Bio::MAGE::QuantitationType::Error',
          'ArrayManufacture' => 'Bio::MAGE::Array::ArrayManufacture',
          'Map' => 'Bio::MAGE::BioEvent::Map',
          'Organization' => 'Bio::MAGE::AuditAndSecurity::Organization',
          'Database' => 'Bio::MAGE::Description::Database',
          'SecurityGroup' => 'Bio::MAGE::AuditAndSecurity::SecurityGroup',
          'CompositeSequenceDimension' => 'Bio::MAGE::BioAssayData::CompositeSequenceDimension',
          'Image' => 'Bio::MAGE::BioAssay::Image',
          'Zone' => 'Bio::MAGE::ArrayDesign::Zone',
          'NodeContents' => 'Bio::MAGE::HigherLevelAnalysis::NodeContents',
          'Reporter' => 'Bio::MAGE::DesignElement::Reporter',
          'FeatureDimension' => 'Bio::MAGE::BioAssayData::FeatureDimension',
          'Protocol' => 'Bio::MAGE::Protocol::Protocol',
          'Describable' => 'Bio::MAGE::Describable',
          'ExpectedValue' => 'Bio::MAGE::QuantitationType::ExpectedValue',
          'Contact' => 'Bio::MAGE::AuditAndSecurity::Contact',
          'CompoundMeasurement' => 'Bio::MAGE::BioMaterial::CompoundMeasurement',
          'MassUnit' => 'Bio::MAGE::Measurement::MassUnit',
          'FactorValue' => 'Bio::MAGE::Experiment::FactorValue',
          'ZoneDefect' => 'Bio::MAGE::Array::ZoneDefect',
          'VolumeUnit' => 'Bio::MAGE::Measurement::VolumeUnit',
          'DesignElementGroup' => 'Bio::MAGE::ArrayDesign::DesignElementGroup',
          'ReporterCompositeMap' => 'Bio::MAGE::DesignElement::ReporterCompositeMap',
          'LabeledExtract' => 'Bio::MAGE::BioMaterial::LabeledExtract',
          'TimeUnit' => 'Bio::MAGE::Measurement::TimeUnit',
          'FeatureDefect' => 'Bio::MAGE::Array::FeatureDefect',
          'QuantityUnit' => 'Bio::MAGE::Measurement::QuantityUnit',
          'BioAssayMapping' => 'Bio::MAGE::BioAssayData::BioAssayMapping',
          'ZoneGroup' => 'Bio::MAGE::ArrayDesign::ZoneGroup',
          'BioAssayDataCluster' => 'Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster',
          'DesignElementMapping' => 'Bio::MAGE::BioAssayData::DesignElementMapping',
          'Parameterizable' => 'Bio::MAGE::Protocol::Parameterizable',
          'BioDataValues' => 'Bio::MAGE::BioAssayData::BioDataValues',
          'DesignElementMap' => 'Bio::MAGE::BioAssayData::DesignElementMap',
          'QuantitationTypeMap' => 'Bio::MAGE::BioAssayData::QuantitationTypeMap',
          'Person' => 'Bio::MAGE::AuditAndSecurity::Person',
          'ZoneLayout' => 'Bio::MAGE::ArrayDesign::ZoneLayout',
          'ParameterizableApplication' => 'Bio::MAGE::Protocol::ParameterizableApplication',
          'Channel' => 'Bio::MAGE::BioAssay::Channel',
          'BioDataCube' => 'Bio::MAGE::BioAssayData::BioDataCube',
          'MeasuredSignal' => 'Bio::MAGE::QuantitationType::MeasuredSignal',
          'ManufactureLIMSBiomaterial' => 'Bio::MAGE::Array::ManufactureLIMSBiomaterial',
          'BioSample' => 'Bio::MAGE::BioMaterial::BioSample',
          'NameValueType' => 'Bio::MAGE::NameValueType',
          'TemperatureUnit' => 'Bio::MAGE::Measurement::TemperatureUnit',
          'Experiment' => 'Bio::MAGE::Experiment::Experiment',
          'Software' => 'Bio::MAGE::Protocol::Software',
          'PresentAbsent' => 'Bio::MAGE::QuantitationType::PresentAbsent',
          'Measurement' => 'Bio::MAGE::Measurement::Measurement',
          'Description' => 'Bio::MAGE::Description::Description'
        }
;
}

=item @list_names = Bio::MAGE::xml_packages();

This method returns an ordered list of the MAGE-ML packages that exist
in the top level MAGE-ML element.

=cut

sub xml_packages {
  return @{$__XML_PACKAGES};
}

=item $hash_ref = Bio::MAGE::class2fullclass();

This method returns a hash table that maps the fully qualified class
name of a class given the abbreviated name for the complete
Bio::MAGE class hierarchy.

=cut

sub class2fullclass {
  return %{$__CLASS2FULLCLASS};
}




=item $obj = class->new(%parameters)

The C<new()> method is the class constructor.

B<Parameters>: if given a list of name/value parameters the
corresponding slots, attributes, or associations will have their
initial values set by the constructor.

B<Return value>: It returns a reference to an object of the class.

B<Side effects>: It invokes the C<initialize()> method if it is defined
by the class.

=cut

#
# code for new() inherited from Base.pm
#

=item @names = class->get_slot_names()

The C<get_slot_names()> method is used to retrieve the name of all
slots defined in a given class.

B<NOTE>: the list of names does not include attribute or association
names.

B<Return value>: A list of the names of all slots defined for this class.

B<Side effects>: none

=cut

#
# code for get_slot_names() inherited from Base.pm
#

=item @name_list = get_attribute_names()

returns the list of attribute data members for this class.

=cut

#
# code for get_attribute_names() inherited from Base.pm
#

=item @name_list = get_association_names()

returns the list of association data members for this class.

=cut

#
# code for get_association_names() inherited from Base.pm
#

=item @class_list = get_superclasses()

returns the list of superclasses for this class.

=cut

#
# code for get_superclasses() inherited from Base.pm
#

=item @class_list = get_subclasses()

returns the list of subclasses for this class.

=cut

#
# code for get_subclasses() inherited from Base.pm
#

=item $name = class_name()

Returns the full class name for this class.

=cut

#
# code for class_name() inherited from Base.pm
#

=item $package_name = package_name()

Returns the base package name (i.e. no 'namespace::') of the package
that contains this class.

=cut

#
# code for package_name() inherited from Base.pm
#

=item %assns = associations()

returns the association meta-information in a hash where the keys are
the association names and the values are C<Association> objects that
provide the meta-information for the association.

=cut

#
# code for associations() inherited from Base.pm
#



=back

=head1 INSTANCE METHODS

=over

=cut

=item $obj_copy = $obj->new()

When invoked with an existing object reference and not a class name,
the C<new()> method acts as a copy constructor - with the new object's
initial values set to be those of the existing object.

B<Parameters>: No input parameters  are used in the copy  constructor,
the initial values are taken directly from the object to be copied.

B<Return value>: It returns a reference to an object of the class.

B<Side effects>: It invokes the C<initialize()> method if it is defined
by the class.

=cut

#
# code for new() inherited from Base.pm
#

=item $obj->set_slots(%parameters)

=item $obj->set_slots(\@name_list, \@value_list)

The C<set_slots()> method is used to set a number of slots at the same
time. It has two different invocation methods. The first takes a named
parameter list, and the second takes two array references.

B<Return value>: none

B<Side effects>: will call C<croak()> if a slot_name is used that the class
does not define.

=cut

#
# code for set_slots() inherited from Base.pm
#

=item @obj_list = $obj->get_slots(@name_list)

The C<get_slots()> method is used to get the values of a number of
slots at the same time.

B<Return value>: a list of instance objects

B<Side effects>: none

=cut

#
# code for get_slots() inherited from Base.pm
#

=item $val = $obj->set_slot($name,$val)

The C<set_slot()> method sets the slot C<$name> to the value C<$val>

B<Return value>: the new value of the slot, i.e. C<$val>

B<Side effects>: none

=cut

#
# code for set_slot() inherited from Base.pm
#

=item $val = $obj->get_slot($name)

The C<get_slot()> method is used to get the values of a number of
slots at the same time.

B<Return value>: a single slot value, or undef if the slot has not been
initialized.

B<Side effects>: none

=cut

#
# code for get_slot() inherited from Base.pm
#



=item $val = $mage->objects()

=item $inval = $mage->objects($inval)

This is the unified setter/getter method for the objects slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the objects
slot

Side effects: none

Exceptions: none

=cut


sub objects {
  my $self = shift;
  if (@_) {
    $self->{__OBJECTS} = shift;
  }
  return $self->{__OBJECTS};
}





=item $val = $mage->tagname()

=item $inval = $mage->tagname($inval)

This is the unified setter/getter method for the tagname slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the tagname
slot

Side effects: none

Exceptions: none

=cut


sub tagname {
  my $self = shift;
  if (@_) {
    $self->{__TAGNAME} = shift;
  }
  return $self->{__TAGNAME};
}





=item $val = $mage->identifier()

=item $inval = $mage->identifier($inval)

This is the unified setter/getter method for the identifier slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the identifier
slot

Side effects: none

Exceptions: none

=cut


sub identifier {
  my $self = shift;
  if (@_) {
    $self->{__IDENTIFIER} = shift;
  }
  return $self->{__IDENTIFIER};
}





=item $val = $mage->registered_objects()

=item $inval = $mage->registered_objects($inval)

This is the unified setter/getter method for the registered_objects slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the registered_objects
slot

Side effects: none

Exceptions: none

=cut


sub registered_objects {
  my $self = shift;
  if (@_) {
    $self->{__REGISTERED_OBJECTS} = shift;
  }
  return $self->{__REGISTERED_OBJECTS};
}





=item $val = $mage->identifiers()

=item $inval = $mage->identifiers($inval)

This is the unified setter/getter method for the identifiers slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the identifiers
slot

Side effects: none

Exceptions: none

=cut


sub identifiers {
  my $self = shift;
  if (@_) {
    $self->{__IDENTIFIERS} = shift;
  }
  return $self->{__IDENTIFIERS};
}





=item $val = $mage->packages()

=item $inval = $mage->packages($inval)

This is the unified setter/getter method for the packages slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the packages
slot

Side effects: none

Exceptions: none

=cut


sub packages {
  my $self = shift;
  if (@_) {
    $self->{__PACKAGES} = shift;
  }
  return $self->{__PACKAGES};
}






=item $mage->add_objects(@list)

The objects in C<@list> are added to the MAGE
object. This method will recursively descend that association hierarcy
of each object and place all Identifiable objects in their appropriate
lists for writing as MAGE-ML.

=cut

sub add_objects {
  my ($self,$list_ref) = @_;
  croak __PACKAGE__ . "::add_objects: Expected array reference but got $list_ref"
    unless UNIVERSAL::isa($list_ref,'ARRAY');
  foreach my $object (@{$list_ref}) {
    # we've been asked to register the objects, so we do it
    $self->register($object,1);
  }
}


=item $pkg_obj = $mage->getHigherLevelAnalysis_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::HigherLevelAnalysis> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getHigherLevelAnalysis_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'HigherLevelAnalysis'}) {
    eval "require Bio::MAGE::HigherLevelAnalysis";
    die "Couldn't require Bio::MAGE::HigherLevelAnalysis"
      if $@;
    $self->{__PACKAGES}{'HigherLevelAnalysis'} = Bio::MAGE::HigherLevelAnalysis->new();
  }
  return $self->{__PACKAGES}{'HigherLevelAnalysis'};
}


=item $pkg_obj = $mage->getBioEvent_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BioEvent> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioEvent_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BioEvent'}) {
    eval "require Bio::MAGE::BioEvent";
    die "Couldn't require Bio::MAGE::BioEvent"
      if $@;
    $self->{__PACKAGES}{'BioEvent'} = Bio::MAGE::BioEvent->new();
  }
  return $self->{__PACKAGES}{'BioEvent'};
}


=item $pkg_obj = $mage->getBioMaterial_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BioMaterial> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioMaterial_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BioMaterial'}) {
    eval "require Bio::MAGE::BioMaterial";
    die "Couldn't require Bio::MAGE::BioMaterial"
      if $@;
    $self->{__PACKAGES}{'BioMaterial'} = Bio::MAGE::BioMaterial->new();
  }
  return $self->{__PACKAGES}{'BioMaterial'};
}


=item $pkg_obj = $mage->getBioSequence_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BioSequence> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioSequence_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BioSequence'}) {
    eval "require Bio::MAGE::BioSequence";
    die "Couldn't require Bio::MAGE::BioSequence"
      if $@;
    $self->{__PACKAGES}{'BioSequence'} = Bio::MAGE::BioSequence->new();
  }
  return $self->{__PACKAGES}{'BioSequence'};
}


=item $pkg_obj = $mage->getAuditAndSecurity_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::AuditAndSecurity> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getAuditAndSecurity_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'AuditAndSecurity'}) {
    eval "require Bio::MAGE::AuditAndSecurity";
    die "Couldn't require Bio::MAGE::AuditAndSecurity"
      if $@;
    $self->{__PACKAGES}{'AuditAndSecurity'} = Bio::MAGE::AuditAndSecurity->new();
  }
  return $self->{__PACKAGES}{'AuditAndSecurity'};
}


=item $pkg_obj = $mage->getBioAssayData_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BioAssayData> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioAssayData_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BioAssayData'}) {
    eval "require Bio::MAGE::BioAssayData";
    die "Couldn't require Bio::MAGE::BioAssayData"
      if $@;
    $self->{__PACKAGES}{'BioAssayData'} = Bio::MAGE::BioAssayData->new();
  }
  return $self->{__PACKAGES}{'BioAssayData'};
}


=item $pkg_obj = $mage->getBQS_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BQS> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBQS_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BQS'}) {
    eval "require Bio::MAGE::BQS";
    die "Couldn't require Bio::MAGE::BQS"
      if $@;
    $self->{__PACKAGES}{'BQS'} = Bio::MAGE::BQS->new();
  }
  return $self->{__PACKAGES}{'BQS'};
}


=item $pkg_obj = $mage->getArray_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::Array> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getArray_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'Array'}) {
    eval "require Bio::MAGE::Array";
    die "Couldn't require Bio::MAGE::Array"
      if $@;
    $self->{__PACKAGES}{'Array'} = Bio::MAGE::Array->new();
  }
  return $self->{__PACKAGES}{'Array'};
}


=item $pkg_obj = $mage->getQuantitationType_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::QuantitationType> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getQuantitationType_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'QuantitationType'}) {
    eval "require Bio::MAGE::QuantitationType";
    die "Couldn't require Bio::MAGE::QuantitationType"
      if $@;
    $self->{__PACKAGES}{'QuantitationType'} = Bio::MAGE::QuantitationType->new();
  }
  return $self->{__PACKAGES}{'QuantitationType'};
}


=item $pkg_obj = $mage->getExperiment_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::Experiment> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getExperiment_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'Experiment'}) {
    eval "require Bio::MAGE::Experiment";
    die "Couldn't require Bio::MAGE::Experiment"
      if $@;
    $self->{__PACKAGES}{'Experiment'} = Bio::MAGE::Experiment->new();
  }
  return $self->{__PACKAGES}{'Experiment'};
}


=item $pkg_obj = $mage->getBioAssay_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::BioAssay> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioAssay_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'BioAssay'}) {
    eval "require Bio::MAGE::BioAssay";
    die "Couldn't require Bio::MAGE::BioAssay"
      if $@;
    $self->{__PACKAGES}{'BioAssay'} = Bio::MAGE::BioAssay->new();
  }
  return $self->{__PACKAGES}{'BioAssay'};
}


=item $pkg_obj = $mage->getDesignElement_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::DesignElement> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getDesignElement_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'DesignElement'}) {
    eval "require Bio::MAGE::DesignElement";
    die "Couldn't require Bio::MAGE::DesignElement"
      if $@;
    $self->{__PACKAGES}{'DesignElement'} = Bio::MAGE::DesignElement->new();
  }
  return $self->{__PACKAGES}{'DesignElement'};
}


=item $pkg_obj = $mage->getProtocol_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::Protocol> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getProtocol_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'Protocol'}) {
    eval "require Bio::MAGE::Protocol";
    die "Couldn't require Bio::MAGE::Protocol"
      if $@;
    $self->{__PACKAGES}{'Protocol'} = Bio::MAGE::Protocol->new();
  }
  return $self->{__PACKAGES}{'Protocol'};
}


=item $pkg_obj = $mage->getDescription_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::Description> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getDescription_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'Description'}) {
    eval "require Bio::MAGE::Description";
    die "Couldn't require Bio::MAGE::Description"
      if $@;
    $self->{__PACKAGES}{'Description'} = Bio::MAGE::Description->new();
  }
  return $self->{__PACKAGES}{'Description'};
}


=item $pkg_obj = $mage->getArrayDesign_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::ArrayDesign> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getArrayDesign_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'ArrayDesign'}) {
    eval "require Bio::MAGE::ArrayDesign";
    die "Couldn't require Bio::MAGE::ArrayDesign"
      if $@;
    $self->{__PACKAGES}{'ArrayDesign'} = Bio::MAGE::ArrayDesign->new();
  }
  return $self->{__PACKAGES}{'ArrayDesign'};
}


=item $pkg_obj = $mage->getMeasurement_package()

This method manages the handling of the singleton class object for the
C<Bio::MAGE::Measurement> class. When called it will return
the object, creating one if it has not already been created.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getMeasurement_package {
  my $self = shift;
  if (not exists $self->{__PACKAGES}{'Measurement'}) {
    eval "require Bio::MAGE::Measurement";
    die "Couldn't require Bio::MAGE::Measurement"
      if $@;
    $self->{__PACKAGES}{'Measurement'} = Bio::MAGE::Measurement->new();
  }
  return $self->{__PACKAGES}{'Measurement'};
}


=item $mage->obj2xml($writer)

Write out this object, and all sub-objects, as XML using the supplied
$writer to actually do the XML formatting.

Input parameters: $writer must be an XML writer, e.g. an instance of
Bio::MAGE::XML::Writer. It must have methods: write_start_tag() and
write_end_tag().

Return value: none

Side effects: all writing is delegated to the $writer - it's
write_start_tag() and write_end_tag() methods are invoked with the
appropriate data, and all package sub-objects of the C<Bio::MAGE> instance will have their obj2xml() methods
invoked in turn. By allowing the $writer to do the actual formatting
of the output XML, it enables the user to precisely control the
format.

Exceptions: will call C<croak()> if no identifier has been set for the
C<Bio::MAGE> instance.

=cut

sub obj2xml {
  my ($self,$writer) = @_;

  # require and identifier for the top-level XML element
  my $identifier = $self->identifier();
  croak __PACKAGE__ . '::obj2xml: Identifier not specified for topmost level object'
    unless defined $identifier;
  my @attrs = (identifier=>$identifier);

  my $empty = 0;
  my $tag = $self->tagname();
  $writer->write_start_tag($tag,$empty,@attrs);

  my %packages = %{$self->packages()};
  foreach my $package ($self->xml_packages()) {
    next unless exists $packages{$package};
    my $pkg_obj = $packages{$package};
    $pkg_obj->obj2xml($writer);
  }

  # and we're done
  $writer->write_end_tag($tag);
}

=item $mage->register($obj)

Store an object for later writing as XML.

Input parameters: object to be added to the list of registered objects.

Return value: none

Side effects: if $obj needs to be stored by this class, a reference
will be stored in the correct XML list for this class.

Exceptions: die() will be called if the object does not have it's
identifier set, or if the object has incorrectly set an association of
list cardinality to a single object.

=cut

sub register {
  my ($self,$obj,$register) = @_;

  # to avoid circular references keep track of objects that
  # we have already or are in the process of registering
  #

  my $registered = $self->registered_objects();
  return if exists $registered->{$obj};
  $registered->{$obj}++;

  # objects only register themselves if they are Identifiable
  # and we have been told to register them
  my $known_identifiers = $self->identifiers();
  if ($register and $obj->isa('Bio::MAGE::Identifiable')) {
    my $id = $obj->getIdentifier();
    die __PACKAGE__ . "::register: object must have identifier: $obj"
      unless $id;
    unless (exists $known_identifiers->{$id}) {
      my $packages = $self->packages();
      my $package_name = $obj->package_name();
      my $pkg_obj = $packages->{$package_name};
      unless (defined $pkg_obj) {
	# we only create the package objects if we need them.
	# register is the first time they will be needed
	my $class = "Bio::MAGE::$package_name";
	$pkg_obj = $class->new();
	$packages->{$package_name} = $pkg_obj;
      }
      $pkg_obj->register($obj);
      $known_identifiers->{$id}++;
    }
  }

  # regardless, they must enable their sub objects to register themselves
  my %assns_hash = $obj->associations();
  foreach my $association ($obj->get_association_names()) {
    my $association_obj;
    {
      no strict 'refs';
      my $assoc_name = 'get' . ucfirst($association);
      $association_obj = $obj->$assoc_name();
    }
    next unless defined $association_obj;

    # we need to know what kind of an association this is if it is an
    # aggregate association we don't want to register it whether it is
    # Identifiable or not, but we still want to register it's
    # sub-objects so we need to alert register()
    #
    # to decide if the association is aggregate, we look at
    # the 'self' end of the association
    my $register = $assns_hash{$association}->self->is_ref();

    # register a list of sub objects or a single one
    if ($assns_hash{$association}->other->cardinality() eq "0..N" or
	$assns_hash{$association}->other->cardinality() eq "1..N") {
      if (UNIVERSAL::isa($association_obj, 'ARRAY')) {
	foreach my $element (@$association_obj) {
	  $self->register($element,$register)
	    if defined $element;
	}
      } else {
	die __PACKAGE__ . "::register: expected array ref: $obj, association: $association, got $association_obj\n";
      }
    } else {
      $self->register($association_obj,$register);
    }
  }
}




=back

=head1 SLOTS, ATTRIBUTES, AND ASSOCIATIONS

In the Perl implementation of MAGE-OM classes, there are
three types of class data members: C<slots>, C<attributes>, and
C<associations>.

=head2 SLOTS

This API uses the term C<slot> to indicate a data member of the class
that was not present in the UML model and is used for mainly internal
purposes - use only if you understand the inner workings of the
API. Most often slots are used by generic methods such as those in the
XML writing and reading classes.

Slots are implemented using unified getter/setter methods:

=over

=item $var = $obj->slot_name();

Retrieves the current value of the slot.

=item $new_var = $obj->slot_name($new_var);

Store $new_var in the slot - the return value is also $new_var.

=item @names = $obj->get_slot_names()

Returns the list of all slots in the class.

=back

B<DATA CHECKING>: No data type checking is made for these methods.

=head2 ATTRIBUTES AND ASSOCIATIONS

The terms C<attribute> and C<association> indicate data members of the
class that were specified directly from the UML model.

In the Perl implementation of MAGE-OM classes,
association and attribute accessors are implemented using three
separate methods:

=over

=item get*

Retrieves the current value.

B<NOTE>: For associations, if the association has list cardinality, an
array reference is returned.

B<DATA CHECKING>: Ensure that no argument is provided.

=item set*

Sets the current value, B<replacing> any existing value.

B<NOTE>: For associations, if the association has list cardinality,
the argument must be an array reference. Because of this, you probably
should be using the add* methods.

B<DATA CHECKING>: For attributes, ensure that a single value is
provided as the argument. For associations, if the association has
list cardinality, ensure that the argument is a reference to an array
of instances of the correct MAGE-OM class, otherwise
ensure that there is a single argument of the correct MAGE-OM class.

=item add*

B<NOTE>: Only present in associations with list cardinality. 

Appends a list of objects to any values that may already be stored
in the association.

B<DATA CHECKING>: Ensure that all arguments are of the correct MAGE-OM class.

=back

=head2 GENERIC METHODS

The unified base class of all MAGE-OM classes, C<Bio::MAGE::Base>, provides a set of generic methods that
will operate on slots, attributes, and associations:

=over

=item $val = $obj->get_slot($name)

=item \@list_ref = $obj->get_slots(@name_list);

=item $val = $obj->set_slot($name,$val)

=item $obj->set_slots(%parameters)

=item $obj->set_slots(\@name_list, \@value_list)

See elsewhere in this page for a detailed description of these
methods.

=back

=cut


=head1 BUGS

Please send bug reports to the project mailing list: (mged-mage 'at' lists 'dot' sf 'dot' net)

=head1 AUTHOR

Jason E. Stewart (jasons 'at' cpan 'dot' org)

=head1 SEE ALSO

perl(1).

=cut

# all perl modules must be true...
1;

