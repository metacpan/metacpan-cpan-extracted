##############################
#
# Bio::MAGE::Description::OntologyEntry
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



package Bio::MAGE::Description::OntologyEntry;
use strict;
use Carp;

use base qw(Bio::MAGE::Extendable);

use Bio::MAGE::Association;

use vars qw($__ASSOCIATIONS
	    $__CLASS_NAME
	    $__PACKAGE_NAME
	    $__SUBCLASSES
	    $__SUPERCLASSES
	    $__ATTRIBUTE_NAMES
	    $__ASSOCIATION_NAMES
	   );


=head1 NAME

Bio::MAGE::Description::OntologyEntry - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::Description::OntologyEntry

  # creating an empty instance
  my $ontologyentry = Bio::MAGE::Description::OntologyEntry->new();

  # creating an instance with existing data
  my $ontologyentry = Bio::MAGE::Description::OntologyEntry->new(
        value=>$value_val,
        description=>$description_val,
        category=>$category_val,
        ontologyReference=>$databaseentry_ref,
        propertySets=>\@namevaluetype_list,
        associations=>\@ontologyentry_list,
  );


  # 'value' attribute
  my $value_val = $ontologyentry->value(); # getter
  $ontologyentry->value($value); # setter

  # 'description' attribute
  my $description_val = $ontologyentry->description(); # getter
  $ontologyentry->description($value); # setter

  # 'category' attribute
  my $category_val = $ontologyentry->category(); # getter
  $ontologyentry->category($value); # setter


  # 'ontologyReference' association
  my $databaseentry_ref = $ontologyentry->ontologyReference(); # getter
  $ontologyentry->ontologyReference($databaseentry_ref); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $ontologyentry->propertySets(); # getter
  $ontologyentry->propertySets(\@namevaluetype_list); # setter

  # 'associations' association
  my $ontologyentry_array_ref = $ontologyentry->associations(); # getter
  $ontologyentry->associations(\@ontologyentry_list); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<OntologyEntry> class:

A single entry from an ontology or a controlled vocabulary.  For instance, category could be 'species name', value could be 'homo sapiens' and ontology would  be taxonomy database, NCBI.



=cut

=head1 INHERITANCE


Bio::MAGE::Description::OntologyEntry has the following superclasses:

=over


=item * Bio::MAGE::Extendable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::Description::OntologyEntry];
  $__PACKAGE_NAME      = q[Description];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Extendable'];
  $__ATTRIBUTE_NAMES   = ['value', 'description', 'category'];
  $__ASSOCIATION_NAMES = ['ontologyReference', 'propertySets', 'associations'];
  $__ASSOCIATIONS      = [
          'ontologyReference',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Many ontology entries will not yet have formalized ontologies.  In those cases, they will not have a database reference to the ontology.

In the future it is highly encouraged that these ontologies be developed and ontologyEntry be subclassed from DatabaseReference.',
                                        '__CLASS_NAME' => 'OntologyEntry',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'ontologyReference',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'Many ontology entries will not yet have formalized ontologies.  In those cases, they will not have a database reference to the ontology.

In the future it is highly encouraged that these ontologies be developed and ontologyEntry be subclassed from DatabaseReference.',
                                         '__CLASS_NAME' => 'DatabaseEntry',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'associations',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Allows an instance of an OntologyEntry to be further qualified.',
                                        '__CLASS_NAME' => 'OntologyEntry',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'associations',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Allows an instance of an OntologyEntry to be further qualified.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::Description::OntologyEntry->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * value

Sets the value of the C<value> attribute

=item * description

Sets the value of the C<description> attribute

=item * category

Sets the value of the C<category> attribute


=item * ontologyReference

Sets the value of the C<ontologyReference> association

The value must be of type: instance of C<Bio::MAGE::Description::DatabaseEntry>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * associations

Sets the value of the C<associations> association

The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


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

C<Bio::MAGE::Description::OntologyEntry> has the following attribute accessor methods:

=over


=item value

Methods for the C<value> attribute.


From the MAGE-OM documentation:

The value for this entry in this category.  


=over


=item $val = $ontologyentry->setValue($val)

The restricted setter method for the C<value> attribute.


Input parameters: the value to which the C<value> attribute will be set 

Return value: the current value of the C<value> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setValue {
  my $self = shift;
  croak(__PACKAGE__ . "::setValue: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setValue: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__VALUE} = $val;
}


=item $val = $ontologyentry->getValue()

The restricted getter method for the C<value> attribute.

Input parameters: none

Return value: the current value of the C<value> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getValue {
  my $self = shift;
  croak(__PACKAGE__ . "::getValue: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__VALUE};
}





=back


=item description

Methods for the C<description> attribute.


From the MAGE-OM documentation:

The description of the meaning for this entry.


=over


=item $val = $ontologyentry->setDescription($val)

The restricted setter method for the C<description> attribute.


Input parameters: the value to which the C<description> attribute will be set 

Return value: the current value of the C<description> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setDescription {
  my $self = shift;
  croak(__PACKAGE__ . "::setDescription: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setDescription: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__DESCRIPTION} = $val;
}


=item $val = $ontologyentry->getDescription()

The restricted getter method for the C<description> attribute.

Input parameters: none

Return value: the current value of the C<description> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getDescription {
  my $self = shift;
  croak(__PACKAGE__ . "::getDescription: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__DESCRIPTION};
}





=back


=item category

Methods for the C<category> attribute.


From the MAGE-OM documentation:

The category to which this entry belongs.


=over


=item $val = $ontologyentry->setCategory($val)

The restricted setter method for the C<category> attribute.


Input parameters: the value to which the C<category> attribute will be set 

Return value: the current value of the C<category> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setCategory {
  my $self = shift;
  croak(__PACKAGE__ . "::setCategory: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setCategory: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__CATEGORY} = $val;
}


=item $val = $ontologyentry->getCategory()

The restricted getter method for the C<category> attribute.

Input parameters: none

Return value: the current value of the C<category> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getCategory {
  my $self = shift;
  croak(__PACKAGE__ . "::getCategory: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__CATEGORY};
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

Bio::MAGE::Description::OntologyEntry has the following association accessor methods:

=over


=item ontologyReference

Methods for the C<ontologyReference> association.


From the MAGE-OM documentation:

Many ontology entries will not yet have formalized ontologies.  In those cases, they will not have a database reference to the ontology.

In the future it is highly encouraged that these ontologies be developed and ontologyEntry be subclassed from DatabaseReference.


=over


=item $val = $ontologyentry->setOntologyReference($val)

The restricted setter method for the C<ontologyReference> association.


Input parameters: the value to which the C<ontologyReference> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<ontologyReference> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::DatabaseEntry>

=cut


sub setOntologyReference {
  my $self = shift;
  croak(__PACKAGE__ . "::setOntologyReference: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setOntologyReference: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setOntologyReference: wrong type: " . ref($val) . " expected Bio::MAGE::Description::DatabaseEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::DatabaseEntry');
  return $self->{__ONTOLOGYREFERENCE} = $val;
}


=item $val = $ontologyentry->getOntologyReference()

The restricted getter method for the C<ontologyReference> association.

Input parameters: none

Return value: the current value of the C<ontologyReference> association : an instance of type C<Bio::MAGE::Description::DatabaseEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getOntologyReference {
  my $self = shift;
  croak(__PACKAGE__ . "::getOntologyReference: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ONTOLOGYREFERENCE};
}





=back


=item propertySets

Methods for the C<propertySets> association.


From the MAGE-OM documentation:

Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren't part of the specification proper.


=over


=item $array_ref = $ontologyentry->setPropertySets($array_ref)

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


=item $array_ref = $ontologyentry->getPropertySets()

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




=item $val = $ontologyentry->addPropertySets(@vals)

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


=item associations

Methods for the C<associations> association.


From the MAGE-OM documentation:

Allows an instance of an OntologyEntry to be further qualified.


=over


=item $array_ref = $ontologyentry->setAssociations($array_ref)

The restricted setter method for the C<associations> association.


Input parameters: the value to which the C<associations> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<associations> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setAssociations {
  my $self = shift;
  croak(__PACKAGE__ . "::setAssociations: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAssociations: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setAssociations: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setAssociations: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__ASSOCIATIONS} = $val;
}


=item $array_ref = $ontologyentry->getAssociations()

The restricted getter method for the C<associations> association.

Input parameters: none

Return value: the current value of the C<associations> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAssociations {
  my $self = shift;
  croak(__PACKAGE__ . "::getAssociations: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ASSOCIATIONS};
}




=item $val = $ontologyentry->addAssociations(@vals)

Because the associations association has list cardinality, it may store more
than one value. This method adds the current list of objects in the associations association.

Input parameters: the list of values C<@vals> to add to the associations association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addAssociations {
  my $self = shift;
  croak(__PACKAGE__ . "::addAssociations: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addAssociations: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__ASSOCIATIONS}},@vals);
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

