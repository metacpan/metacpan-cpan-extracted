##############################
#
# Bio::MAGE::BioAssayData
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



package Bio::MAGE::BioAssayData;

use strict;

use base qw(Bio::MAGE::Base);

use Carp;
use Tie::IxHash;

use vars qw($__XML_LISTS);

use Bio::MAGE::BioAssayData::BioAssayData;
use Bio::MAGE::BioAssayData::QuantitationTypeDimension;
use Bio::MAGE::BioAssayData::BioAssayMapping;
use Bio::MAGE::BioAssayData::DesignElementDimension;
use Bio::MAGE::BioAssayData::BioAssayDatum;
use Bio::MAGE::BioAssayData::DerivedBioAssayData;
use Bio::MAGE::BioAssayData::MeasuredBioAssayData;
use Bio::MAGE::BioAssayData::QuantitationTypeMapping;
use Bio::MAGE::BioAssayData::DesignElementMapping;
use Bio::MAGE::BioAssayData::BioDataCube;
use Bio::MAGE::BioAssayData::BioDataValues;
use Bio::MAGE::BioAssayData::BioDataTuples;
use Bio::MAGE::BioAssayData::BioAssayDimension;
use Bio::MAGE::BioAssayData::QuantitationTypeMap;
use Bio::MAGE::BioAssayData::Transformation;
use Bio::MAGE::BioAssayData::DesignElementMap;
use Bio::MAGE::BioAssayData::BioAssayMap;
use Bio::MAGE::BioAssayData::CompositeSequenceDimension;
use Bio::MAGE::BioAssayData::ReporterDimension;
use Bio::MAGE::BioAssayData::FeatureDimension;


=head1 NAME

Bio::MAGE::BioAssayData - Container module for classes in the MAGE package: BioAssayData

=head1 SYNOPSIS

  use Bio::MAGE::BioAssayData;

=head1 DESCRIPTION

This is a I<package> module that encapsulates a number of classes in
the Bio::MAGE hierarchy. These classes belong to the
BioAssayData package of the MAGE-OM object model.

=head1 CLASSES

The Bio::MAGE::BioAssayData module contains the following
Bio::MAGE classes:

=over


=item * BioAssayData


=item * QuantitationTypeDimension


=item * BioAssayMapping


=item * DesignElementDimension


=item * BioAssayDatum


=item * DerivedBioAssayData


=item * MeasuredBioAssayData


=item * QuantitationTypeMapping


=item * DesignElementMapping


=item * BioDataCube


=item * BioDataValues


=item * BioDataTuples


=item * BioAssayDimension


=item * QuantitationTypeMap


=item * Transformation


=item * DesignElementMap


=item * BioAssayMap


=item * CompositeSequenceDimension


=item * ReporterDimension


=item * FeatureDimension


=back



=head1 CLASS METHODS

=over

=item @class_list = Bio::MAGE::BioAssayData::classes();

This method returns a list of non-fully qualified class names
(i.e. they do not have 'Bio::MAGE::' as a prefix) in this package.

=cut

sub classes {
  return ('BioAssayData','QuantitationTypeDimension','BioAssayMapping','DesignElementDimension','BioAssayDatum','DerivedBioAssayData','MeasuredBioAssayData','QuantitationTypeMapping','DesignElementMapping','BioDataCube','BioDataValues','BioDataTuples','BioAssayDimension','QuantitationTypeMap','Transformation','DesignElementMap','BioAssayMap','CompositeSequenceDimension','ReporterDimension','FeatureDimension');
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



=item $val = $bioassaydata->xml_lists()

=item $inval = $bioassaydata->xml_lists($inval)

This is the unified setter/getter method for the xml_lists slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the xml_lists
slot

Side effects: none

Exceptions: none

=cut


sub xml_lists {
  my $self = shift;
  if (@_) {
    $self->{__XML_LISTS} = shift;
  }
  return $self->{__XML_LISTS};
}





=item $val = $bioassaydata->tagname()

=item $inval = $bioassaydata->tagname($inval)

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





=item $val = $bioassaydata->bioassaydimension_list()

=item $inval = $bioassaydata->bioassaydimension_list($inval)

This is the unified setter/getter method for the bioassaydimension_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the bioassaydimension_list
slot

Side effects: none

Exceptions: none

=cut


sub bioassaydimension_list {
  my $self = shift;
  if (@_) {
    $self->{__BIOASSAYDIMENSION_LIST} = shift;
  }
  return $self->{__BIOASSAYDIMENSION_LIST};
}





=item $val = $bioassaydata->designelementdimension_list()

=item $inval = $bioassaydata->designelementdimension_list($inval)

This is the unified setter/getter method for the designelementdimension_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the designelementdimension_list
slot

Side effects: none

Exceptions: none

=cut


sub designelementdimension_list {
  my $self = shift;
  if (@_) {
    $self->{__DESIGNELEMENTDIMENSION_LIST} = shift;
  }
  return $self->{__DESIGNELEMENTDIMENSION_LIST};
}





=item $val = $bioassaydata->quantitationtypedimension_list()

=item $inval = $bioassaydata->quantitationtypedimension_list($inval)

This is the unified setter/getter method for the quantitationtypedimension_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the quantitationtypedimension_list
slot

Side effects: none

Exceptions: none

=cut


sub quantitationtypedimension_list {
  my $self = shift;
  if (@_) {
    $self->{__QUANTITATIONTYPEDIMENSION_LIST} = shift;
  }
  return $self->{__QUANTITATIONTYPEDIMENSION_LIST};
}





=item $val = $bioassaydata->bioassaymap_list()

=item $inval = $bioassaydata->bioassaymap_list($inval)

This is the unified setter/getter method for the bioassaymap_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the bioassaymap_list
slot

Side effects: none

Exceptions: none

=cut


sub bioassaymap_list {
  my $self = shift;
  if (@_) {
    $self->{__BIOASSAYMAP_LIST} = shift;
  }
  return $self->{__BIOASSAYMAP_LIST};
}





=item $val = $bioassaydata->quantitationtypemap_list()

=item $inval = $bioassaydata->quantitationtypemap_list($inval)

This is the unified setter/getter method for the quantitationtypemap_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the quantitationtypemap_list
slot

Side effects: none

Exceptions: none

=cut


sub quantitationtypemap_list {
  my $self = shift;
  if (@_) {
    $self->{__QUANTITATIONTYPEMAP_LIST} = shift;
  }
  return $self->{__QUANTITATIONTYPEMAP_LIST};
}





=item $val = $bioassaydata->bioassaydata_list()

=item $inval = $bioassaydata->bioassaydata_list($inval)

This is the unified setter/getter method for the bioassaydata_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the bioassaydata_list
slot

Side effects: none

Exceptions: none

=cut


sub bioassaydata_list {
  my $self = shift;
  if (@_) {
    $self->{__BIOASSAYDATA_LIST} = shift;
  }
  return $self->{__BIOASSAYDATA_LIST};
}






sub initialize {
  my $self = shift;

  $self->bioassaydimension_list([]);
  $self->designelementdimension_list([]);
  $self->quantitationtypedimension_list([]);
  $self->bioassaymap_list([]);
  $self->quantitationtypemap_list([]);
  $self->bioassaydata_list([]);

  $self->xml_lists([BioAssayDimension=>$self->bioassaydimension_list(), DesignElementDimension=>$self->designelementdimension_list(), QuantitationTypeDimension=>$self->quantitationtypedimension_list(), BioAssayMap=>$self->bioassaymap_list(), QuantitationTypeMap=>$self->quantitationtypemap_list(), BioAssayData=>$self->bioassaydata_list()]);

  $self->tagname(q[BioAssayData_package]);
  return 1;
}


=item $array_ref = $bioassaydata->getBioAssayDimension_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::BioAssayDimension> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioAssayDimension_list {
  my $self = shift;
  return $self->bioassaydimension_list();
}

=item $bioassaydata->addBioAssayDimension(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::BioAssayDimension> objects to
the C<bioassaydimension_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::BioAssayDimension>

=cut

sub addBioAssayDimension {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayDimension: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addBioAssayDimension: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::BioAssayDimension")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::BioAssayDimension');
  }

  push(@{$self->bioassaydimension_list},@_);
}


=item $array_ref = $bioassaydata->getDesignElementDimension_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::DesignElementDimension> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getDesignElementDimension_list {
  my $self = shift;
  return $self->designelementdimension_list();
}

=item $bioassaydata->addDesignElementDimension(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::DesignElementDimension> objects to
the C<designelementdimension_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::DesignElementDimension>

=cut

sub addDesignElementDimension {
  my $self = shift;
  croak(__PACKAGE__ . "::addDesignElementDimension: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addDesignElementDimension: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::DesignElementDimension")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::DesignElementDimension');
  }

  push(@{$self->designelementdimension_list},@_);
}


=item $array_ref = $bioassaydata->getQuantitationTypeDimension_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::QuantitationTypeDimension> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getQuantitationTypeDimension_list {
  my $self = shift;
  return $self->quantitationtypedimension_list();
}

=item $bioassaydata->addQuantitationTypeDimension(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::QuantitationTypeDimension> objects to
the C<quantitationtypedimension_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::QuantitationTypeDimension>

=cut

sub addQuantitationTypeDimension {
  my $self = shift;
  croak(__PACKAGE__ . "::addQuantitationTypeDimension: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addQuantitationTypeDimension: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::QuantitationTypeDimension")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::QuantitationTypeDimension');
  }

  push(@{$self->quantitationtypedimension_list},@_);
}


=item $array_ref = $bioassaydata->getBioAssayMap_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::BioAssayMap> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioAssayMap_list {
  my $self = shift;
  return $self->bioassaymap_list();
}

=item $bioassaydata->addBioAssayMap(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::BioAssayMap> objects to
the C<bioassaymap_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::BioAssayMap>

=cut

sub addBioAssayMap {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayMap: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addBioAssayMap: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::BioAssayMap")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::BioAssayMap');
  }

  push(@{$self->bioassaymap_list},@_);
}


=item $array_ref = $bioassaydata->getQuantitationTypeMap_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::QuantitationTypeMap> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getQuantitationTypeMap_list {
  my $self = shift;
  return $self->quantitationtypemap_list();
}

=item $bioassaydata->addQuantitationTypeMap(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::QuantitationTypeMap> objects to
the C<quantitationtypemap_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::QuantitationTypeMap>

=cut

sub addQuantitationTypeMap {
  my $self = shift;
  croak(__PACKAGE__ . "::addQuantitationTypeMap: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addQuantitationTypeMap: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::QuantitationTypeMap")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::QuantitationTypeMap');
  }

  push(@{$self->quantitationtypemap_list},@_);
}


=item $array_ref = $bioassaydata->getBioAssayData_list()

This method handles the list for the C<Bio::MAGE::BioAssayData::BioAssayData> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getBioAssayData_list {
  my $self = shift;
  return $self->bioassaydata_list();
}

=item $bioassaydata->addBioAssayData(@vals)

This method is an interface for adding C<Bio::MAGE::BioAssayData::BioAssayData> objects to
the C<bioassaydata_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::BioAssayData::BioAssayData>

=cut

sub addBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayData: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addBioAssayData: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::BioAssayData")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::BioAssayData');
  }

  push(@{$self->bioassaydata_list},@_);
}


=item $bioassaydata->obj2xml($writer)

Write out this object, and all sub-objects, as XML using the supplied
$writer to actually do the XML formatting.

Input parameters: $writer must be an XML writer, e.g. an instance of
Bio::MAGE::XML::Writer. It must have methods: write_start_tag(),
write_end_tag(), and obj2xml().

Return value: none

Side effects: all writing is delegated to the $writer - it's
write_start_tag() and write_end_tag() methods are invoked with the
appropriate data, and all class sub-objects of the C<Bio::MAGE::BioAssayData> instance will have their obj2xml() methods
invoked in turn. By allowing the $writer to do the actual formatting
of the output XML, it enables the user to precisely control the
format.

Exceptions: will call C<croak()> if no identifier has been set for the
C<Bio::MAGE::BioAssayData> instance.

=cut

sub obj2xml {
  my ($self,$writer) = @_;

  my $empty = 0;
  my $tag = $self->tagname();
  $writer->write_start_tag($tag,$empty);

  # we use IxHash because we need to preserve insertion order
  tie my %list_hash, 'Tie::IxHash', @{$self->xml_lists()};
  foreach my $list_name (keys %list_hash) {
    if (scalar @{$list_hash{$list_name}}) {
      my $tag = $list_name . '_assnlist';
      $writer->write_start_tag($tag,$empty);
      foreach my $obj (@{$list_hash{$list_name}}) {
	# this may seem a little odd, but the writer knows how to
	# write out the objects - this allows you to create your own
	# subclass of Bio::MAGE::XML::Writer and modify
	# the output of the obj2xml process
	$writer->obj2xml($obj);
      }
      $writer->write_end_tag($tag);
    }
  }

  # and we're done
  $writer->write_end_tag($tag);

}

=item $bioassaydata->register($obj)

Store an object for later writing as XML.

Input parameters: object to be added to the list of registered objects.

Return value: none

Side effects: if $obj needs to be stored by this class, a reference
will be stored in the correct XML list for this class.

Exceptions: none

=cut

sub register {
  my ($self,$obj) = @_;

  # should we have the identifier checking code here??
  my %xml_lists = @{$self->xml_lists()};
  my $list_ref;
  foreach my $class (keys %xml_lists) {
    if ($obj->isa("Bio::MAGE::BioAssayData::$class")) {
      $list_ref = $xml_lists{$class};
      last;
    }
  }

  return unless defined $list_ref;
  push(@{$list_ref}, $obj);
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

