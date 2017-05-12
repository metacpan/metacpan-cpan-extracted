##############################
#
# Bio::MAGE::Measurement::QuantityUnit
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



package Bio::MAGE::Measurement::QuantityUnit;
use strict;
use Carp;

use base qw(Bio::MAGE::Measurement::Unit);

use Bio::MAGE::Association;

use vars qw($__ASSOCIATIONS
	    $__CLASS_NAME
	    $__PACKAGE_NAME
	    $__SUBCLASSES
	    $__SUPERCLASSES
	    $__ATTRIBUTE_NAMES
	    $__ASSOCIATION_NAMES
	   );

use constant UNITNAMECV_AMOL => 'amol';
use constant UNITNAMECV_MOLECULES => 'molecules';
use constant UNITNAMECV_NMOL => 'nmol';
use constant UNITNAMECV_OTHER => 'other';
use constant UNITNAMECV_MOL => 'mol';
use constant UNITNAMECV_MMOL => 'mmol';
use constant UNITNAMECV_UMOL => 'umol';
use constant UNITNAMECV_PMOL => 'pmol';
use constant UNITNAMECV_FMOL => 'fmol';

=head1 NAME

Bio::MAGE::Measurement::QuantityUnit - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::Measurement::QuantityUnit

  # creating an empty instance
  my $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new();

  # creating an instance with existing data
  my $quantityunit = Bio::MAGE::Measurement::QuantityUnit->new(
        unitNameCV=>$unitnamecv_val,
        unitName=>$unitname_val,
        propertySets=>\@namevaluetype_list,
  );


  # 'unitNameCV' attribute
  my $unitNameCV_val = $quantityunit->unitNameCV(); # getter
  $quantityunit->unitNameCV($value); # setter

  # 'unitName' attribute
  my $unitName_val = $quantityunit->unitName(); # getter
  $quantityunit->unitName($value); # setter


  # 'propertySets' association
  my $namevaluetype_array_ref = $quantityunit->propertySets(); # getter
  $quantityunit->propertySets(\@namevaluetype_list); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<QuantityUnit> class:

Quantity



=cut

=head1 INHERITANCE


Bio::MAGE::Measurement::QuantityUnit has the following superclasses:

=over


=item * Bio::MAGE::Measurement::Unit


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::Measurement::QuantityUnit];
  $__PACKAGE_NAME      = q[Measurement];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Measurement::Unit'];
  $__ATTRIBUTE_NAMES   = ['unitNameCV', 'unitName'];
  $__ASSOCIATION_NAMES = ['propertySets'];
  $__ASSOCIATIONS      = []

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::Measurement::QuantityUnit->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * unitNameCV

Sets the value of the C<unitNameCV> attribute

=item * unitName

Sets the value of the C<unitName> attribute (this attribute was inherited from class C<Bio::MAGE::Measurement::Unit>).



=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=back

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


=head2 ATTRIBUTES

Attributes are simple data types that belong to a single instance of a
class. In the Perl implementation of the MAGE-OM classes, the
interface to attributes is implemented using separate setter and
getter methods for each attribute.

C<Bio::MAGE::Measurement::QuantityUnit> has the following attribute accessor methods:

=over


=item unitNameCV

Methods for the C<unitNameCV> attribute.


From the MAGE-OM documentation:




=over


=item $val = $quantityunit->setUnitNameCV($val)

The restricted setter method for the C<unitNameCV> attribute.

C<unitNameCV> is an B<enumerated> attribute - it can only be set to C<undef> or one of the following values: mol amol fmol pmol nmol umol mmol molecules other


Input parameters: the value to which the C<unitNameCV> attribute will be set 

Return value: the current value of the C<unitNameCV> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not one of the accepted enumeration values: mol amol fmol pmol nmol umol mmol molecules other

=cut


sub setUnitNameCV {
  my $self = shift;
  croak(__PACKAGE__ . "::setUnitNameCV: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setUnitNameCV: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setUnitNameCV: expected one of enum values : mol amol fmol pmol nmol umol mmol molecules other, got $val")
    unless (not defined $val) or (grep {$val eq $_} qw(mol amol fmol pmol nmol umol mmol molecules other));

  return $self->{__UNITNAMECV} = $val;
}


=item $val = $quantityunit->getUnitNameCV()

The restricted getter method for the C<unitNameCV> attribute.

Input parameters: none

Return value: the current value of the C<unitNameCV> attribute : an instance of type C<mol amol fmol pmol nmol umol mmol molecules other>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getUnitNameCV {
  my $self = shift;
  croak(__PACKAGE__ . "::getUnitNameCV: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__UNITNAMECV};
}





=back


=item unitName

Methods for the C<unitName> attribute.


From the MAGE-OM documentation:

The name of the unit.


=over


=item $val = $quantityunit->setUnitName($val)

The restricted setter method for the C<unitName> attribute.


Input parameters: the value to which the C<unitName> attribute will be set 

Return value: the current value of the C<unitName> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setUnitName {
  my $self = shift;
  croak(__PACKAGE__ . "::setUnitName: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setUnitName: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__UNITNAME} = $val;
}


=item $val = $quantityunit->getUnitName()

The restricted getter method for the C<unitName> attribute.

Input parameters: none

Return value: the current value of the C<unitName> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getUnitName {
  my $self = shift;
  croak(__PACKAGE__ . "::getUnitName: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__UNITNAME};
}





=back


=back


=head2 ASSOCIATIONS

Associations are references to other classes. Associations in MAGE-OM have a cardinality that determines the minimum and
maximum number of instances of the 'other' class that maybe included
in the association:

=over

=item 1

There B<must> be exactly one item in the association, i.e. this is a
mandatory data field.

=item 0..1

There B<may> be one item in the association, i.e. this is an optional
data field.

=item 1..N

There B<must> be one or more items in the association, i.e. this is a
mandatory data field, with list cardinality.

=item 0..N

There B<may> be one or more items in the association, i.e. this is an
optional data field, with list cardinality.

=back

Bio::MAGE::Measurement::QuantityUnit has the following association accessor methods:

=over


=item propertySets

Methods for the C<propertySets> association.


From the MAGE-OM documentation:

Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren't part of the specification proper.


=over


=item $array_ref = $quantityunit->setPropertySets($array_ref)

The restricted setter method for the C<propertySets> association.


Input parameters: the value to which the C<propertySets> association will be set : a reference to an array of objects of type C<Bio::MAGE::NameValueType>

Return value: the current value of the C<propertySets> association : a reference to an array of objects of type C<Bio::MAGE::NameValueType>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::NameValueType> instances

=cut


sub setPropertySets {
  my $self = shift;
  croak(__PACKAGE__ . "::setPropertySets: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPropertySets: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setPropertySets: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setPropertySets: wrong type: " . ref($val_ent) . " expected Bio::MAGE::NameValueType")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::NameValueType');
    }
  }

  return $self->{__PROPERTYSETS} = $val;
}


=item $array_ref = $quantityunit->getPropertySets()

The restricted getter method for the C<propertySets> association.

Input parameters: none

Return value: the current value of the C<propertySets> association : a reference to an array of objects of type C<Bio::MAGE::NameValueType>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPropertySets {
  my $self = shift;
  croak(__PACKAGE__ . "::getPropertySets: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PROPERTYSETS};
}




=item $val = $quantityunit->addPropertySets(@vals)

Because the propertySets association has list cardinality, it may store more
than one value. This method adds the current list of objects in the propertySets association.

Input parameters: the list of values C<@vals> to add to the propertySets association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::NameValueType>

=cut


sub addPropertySets {
  my $self = shift;
  croak(__PACKAGE__ . "::addPropertySets: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addPropertySets: wrong type: " . ref($val) . " expected Bio::MAGE::NameValueType")
      unless UNIVERSAL::isa($val,'Bio::MAGE::NameValueType');
  }

  return push(@{$self->{__PROPERTYSETS}},@vals);
}





=back


sub initialize {


  my $self = shift;
  return 1;


}

=back


=cut


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

