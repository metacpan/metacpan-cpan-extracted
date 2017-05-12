##############################
#
# Bio::MAGE::DesignElement
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



package Bio::MAGE::DesignElement;

use strict;

use base qw(Bio::MAGE::Base);

use Carp;
use Tie::IxHash;

use vars qw($__XML_LISTS);

use Bio::MAGE::DesignElement::DesignElement;
use Bio::MAGE::DesignElement::Position;
use Bio::MAGE::DesignElement::Reporter;
use Bio::MAGE::DesignElement::ReporterPosition;
use Bio::MAGE::DesignElement::CompositePosition;
use Bio::MAGE::DesignElement::CompositeSequence;
use Bio::MAGE::DesignElement::Feature;
use Bio::MAGE::DesignElement::MismatchInformation;
use Bio::MAGE::DesignElement::FeatureInformation;
use Bio::MAGE::DesignElement::CompositeCompositeMap;
use Bio::MAGE::DesignElement::FeatureReporterMap;
use Bio::MAGE::DesignElement::ReporterCompositeMap;
use Bio::MAGE::DesignElement::FeatureLocation;


=head1 NAME

Bio::MAGE::DesignElement - Container module for classes in the MAGE package: DesignElement

=head1 SYNOPSIS

  use Bio::MAGE::DesignElement;

=head1 DESCRIPTION

This is a I<package> module that encapsulates a number of classes in
the Bio::MAGE hierarchy. These classes belong to the
DesignElement package of the MAGE-OM object model.

=head1 CLASSES

The Bio::MAGE::DesignElement module contains the following
Bio::MAGE classes:

=over


=item * DesignElement


=item * Position


=item * Reporter


=item * ReporterPosition


=item * CompositePosition


=item * CompositeSequence


=item * Feature


=item * MismatchInformation


=item * FeatureInformation


=item * CompositeCompositeMap


=item * FeatureReporterMap


=item * ReporterCompositeMap


=item * FeatureLocation


=back



=head1 CLASS METHODS

=over

=item @class_list = Bio::MAGE::DesignElement::classes();

This method returns a list of non-fully qualified class names
(i.e. they do not have 'Bio::MAGE::' as a prefix) in this package.

=cut

sub classes {
  return ('DesignElement','Position','Reporter','ReporterPosition','CompositePosition','CompositeSequence','Feature','MismatchInformation','FeatureInformation','CompositeCompositeMap','FeatureReporterMap','ReporterCompositeMap','FeatureLocation');
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



=item $val = $designelement->xml_lists()

=item $inval = $designelement->xml_lists($inval)

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





=item $val = $designelement->tagname()

=item $inval = $designelement->tagname($inval)

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





=item $val = $designelement->compositesequence_list()

=item $inval = $designelement->compositesequence_list($inval)

This is the unified setter/getter method for the compositesequence_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the compositesequence_list
slot

Side effects: none

Exceptions: none

=cut


sub compositesequence_list {
  my $self = shift;
  if (@_) {
    $self->{__COMPOSITESEQUENCE_LIST} = shift;
  }
  return $self->{__COMPOSITESEQUENCE_LIST};
}





=item $val = $designelement->reporter_list()

=item $inval = $designelement->reporter_list($inval)

This is the unified setter/getter method for the reporter_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the reporter_list
slot

Side effects: none

Exceptions: none

=cut


sub reporter_list {
  my $self = shift;
  if (@_) {
    $self->{__REPORTER_LIST} = shift;
  }
  return $self->{__REPORTER_LIST};
}





=item $val = $designelement->compositecompositemap_list()

=item $inval = $designelement->compositecompositemap_list($inval)

This is the unified setter/getter method for the compositecompositemap_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the compositecompositemap_list
slot

Side effects: none

Exceptions: none

=cut


sub compositecompositemap_list {
  my $self = shift;
  if (@_) {
    $self->{__COMPOSITECOMPOSITEMAP_LIST} = shift;
  }
  return $self->{__COMPOSITECOMPOSITEMAP_LIST};
}





=item $val = $designelement->reportercompositemap_list()

=item $inval = $designelement->reportercompositemap_list($inval)

This is the unified setter/getter method for the reportercompositemap_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the reportercompositemap_list
slot

Side effects: none

Exceptions: none

=cut


sub reportercompositemap_list {
  my $self = shift;
  if (@_) {
    $self->{__REPORTERCOMPOSITEMAP_LIST} = shift;
  }
  return $self->{__REPORTERCOMPOSITEMAP_LIST};
}





=item $val = $designelement->featurereportermap_list()

=item $inval = $designelement->featurereportermap_list($inval)

This is the unified setter/getter method for the featurereportermap_list slot.

If C<$inval> is specified, the setter method is invoked, with no
parameters, the getter method is invoked.

Input parameters: the optional C<$inval> will invoke the setter method.

Return value: for both setter and getter the current value of the featurereportermap_list
slot

Side effects: none

Exceptions: none

=cut


sub featurereportermap_list {
  my $self = shift;
  if (@_) {
    $self->{__FEATUREREPORTERMAP_LIST} = shift;
  }
  return $self->{__FEATUREREPORTERMAP_LIST};
}






sub initialize {
  my $self = shift;

  $self->compositesequence_list([]);
  $self->reporter_list([]);
  $self->compositecompositemap_list([]);
  $self->reportercompositemap_list([]);
  $self->featurereportermap_list([]);

  $self->xml_lists([CompositeSequence=>$self->compositesequence_list(), Reporter=>$self->reporter_list(), CompositeCompositeMap=>$self->compositecompositemap_list(), ReporterCompositeMap=>$self->reportercompositemap_list(), FeatureReporterMap=>$self->featurereportermap_list()]);

  $self->tagname(q[DesignElement_package]);
  return 1;
}


=item $array_ref = $designelement->getCompositeSequence_list()

This method handles the list for the C<Bio::MAGE::DesignElement::CompositeSequence> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getCompositeSequence_list {
  my $self = shift;
  return $self->compositesequence_list();
}

=item $designelement->addCompositeSequence(@vals)

This method is an interface for adding C<Bio::MAGE::DesignElement::CompositeSequence> objects to
the C<compositesequence_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::DesignElement::CompositeSequence>

=cut

sub addCompositeSequence {
  my $self = shift;
  croak(__PACKAGE__ . "::addCompositeSequence: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addCompositeSequence: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::CompositeSequence")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::CompositeSequence');
  }

  push(@{$self->compositesequence_list},@_);
}


=item $array_ref = $designelement->getReporter_list()

This method handles the list for the C<Bio::MAGE::DesignElement::Reporter> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getReporter_list {
  my $self = shift;
  return $self->reporter_list();
}

=item $designelement->addReporter(@vals)

This method is an interface for adding C<Bio::MAGE::DesignElement::Reporter> objects to
the C<reporter_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::DesignElement::Reporter>

=cut

sub addReporter {
  my $self = shift;
  croak(__PACKAGE__ . "::addReporter: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addReporter: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::Reporter")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::Reporter');
  }

  push(@{$self->reporter_list},@_);
}


=item $array_ref = $designelement->getCompositeCompositeMap_list()

This method handles the list for the C<Bio::MAGE::DesignElement::CompositeCompositeMap> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getCompositeCompositeMap_list {
  my $self = shift;
  return $self->compositecompositemap_list();
}

=item $designelement->addCompositeCompositeMap(@vals)

This method is an interface for adding C<Bio::MAGE::DesignElement::CompositeCompositeMap> objects to
the C<compositecompositemap_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::DesignElement::CompositeCompositeMap>

=cut

sub addCompositeCompositeMap {
  my $self = shift;
  croak(__PACKAGE__ . "::addCompositeCompositeMap: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addCompositeCompositeMap: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::CompositeCompositeMap")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::CompositeCompositeMap');
  }

  push(@{$self->compositecompositemap_list},@_);
}


=item $array_ref = $designelement->getReporterCompositeMap_list()

This method handles the list for the C<Bio::MAGE::DesignElement::ReporterCompositeMap> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getReporterCompositeMap_list {
  my $self = shift;
  return $self->reportercompositemap_list();
}

=item $designelement->addReporterCompositeMap(@vals)

This method is an interface for adding C<Bio::MAGE::DesignElement::ReporterCompositeMap> objects to
the C<reportercompositemap_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::DesignElement::ReporterCompositeMap>

=cut

sub addReporterCompositeMap {
  my $self = shift;
  croak(__PACKAGE__ . "::addReporterCompositeMap: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addReporterCompositeMap: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::ReporterCompositeMap")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::ReporterCompositeMap');
  }

  push(@{$self->reportercompositemap_list},@_);
}


=item $array_ref = $designelement->getFeatureReporterMap_list()

This method handles the list for the C<Bio::MAGE::DesignElement::FeatureReporterMap> class. It
returns a reference to an array of the class objects that have been
associated with the package instance.

This is useful when retrieving data from parsed MAGE-ML file.

=cut

sub getFeatureReporterMap_list {
  my $self = shift;
  return $self->featurereportermap_list();
}

=item $designelement->addFeatureReporterMap(@vals)

This method is an interface for adding C<Bio::MAGE::DesignElement::FeatureReporterMap> objects to
the C<featurereportermap_list> list. It is generally used by generic methods such
as those in the XMLWriter.

Input parameters: the list of values C<@vals> to add to the owner
association. B<NOTE>: submitting a single value is permitted.

Return value: none

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified
, or if any of the objects in @vals is not a subclass of class C<Bio::MAGE::DesignElement::FeatureReporterMap>

=cut

sub addFeatureReporterMap {
  my $self = shift;
  croak(__PACKAGE__ . "::addFeatureReporterMap: no arguments passed to setter")
    unless scalar @_;
  foreach my $val (@_) {
    croak(__PACKAGE__ . "::addFeatureReporterMap: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::FeatureReporterMap")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::FeatureReporterMap');
  }

  push(@{$self->featurereportermap_list},@_);
}


=item $designelement->obj2xml($writer)

Write out this object, and all sub-objects, as XML using the supplied
$writer to actually do the XML formatting.

Input parameters: $writer must be an XML writer, e.g. an instance of
Bio::MAGE::XML::Writer. It must have methods: write_start_tag(),
write_end_tag(), and obj2xml().

Return value: none

Side effects: all writing is delegated to the $writer - it's
write_start_tag() and write_end_tag() methods are invoked with the
appropriate data, and all class sub-objects of the C<Bio::MAGE::DesignElement> instance will have their obj2xml() methods
invoked in turn. By allowing the $writer to do the actual formatting
of the output XML, it enables the user to precisely control the
format.

Exceptions: will call C<croak()> if no identifier has been set for the
C<Bio::MAGE::DesignElement> instance.

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

=item $designelement->register($obj)

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
    if ($obj->isa("Bio::MAGE::DesignElement::$class")) {
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

