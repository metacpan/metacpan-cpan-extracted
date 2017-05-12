##############################
#
# Bio::MAGE::ArrayDesign::FeatureGroup
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



package Bio::MAGE::ArrayDesign::FeatureGroup;
use strict;
use Carp;

use base qw(Bio::MAGE::ArrayDesign::DesignElementGroup);

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

Bio::MAGE::ArrayDesign::FeatureGroup - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::ArrayDesign::FeatureGroup

  # creating an empty instance
  my $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new();

  # creating an instance with existing data
  my $featuregroup = Bio::MAGE::ArrayDesign::FeatureGroup->new(
        featureLength=>$featurelength_val,
        name=>$name_val,
        identifier=>$identifier_val,
        featureWidth=>$featurewidth_val,
        featureHeight=>$featureheight_val,
        types=>\@ontologyentry_list,
        features=>\@feature_list,
        featureShape=>$ontologyentry_ref,
        auditTrail=>\@audit_list,
        technologyType=>$ontologyentry_ref,
        propertySets=>\@namevaluetype_list,
        species=>$ontologyentry_ref,
        distanceUnit=>$distanceunit_ref,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'featureLength' attribute
  my $featureLength_val = $featuregroup->featureLength(); # getter
  $featuregroup->featureLength($value); # setter

  # 'name' attribute
  my $name_val = $featuregroup->name(); # getter
  $featuregroup->name($value); # setter

  # 'identifier' attribute
  my $identifier_val = $featuregroup->identifier(); # getter
  $featuregroup->identifier($value); # setter

  # 'featureWidth' attribute
  my $featureWidth_val = $featuregroup->featureWidth(); # getter
  $featuregroup->featureWidth($value); # setter

  # 'featureHeight' attribute
  my $featureHeight_val = $featuregroup->featureHeight(); # getter
  $featuregroup->featureHeight($value); # setter


  # 'types' association
  my $ontologyentry_array_ref = $featuregroup->types(); # getter
  $featuregroup->types(\@ontologyentry_list); # setter

  # 'features' association
  my $feature_array_ref = $featuregroup->features(); # getter
  $featuregroup->features(\@feature_list); # setter

  # 'featureShape' association
  my $ontologyentry_ref = $featuregroup->featureShape(); # getter
  $featuregroup->featureShape($ontologyentry_ref); # setter

  # 'auditTrail' association
  my $audit_array_ref = $featuregroup->auditTrail(); # getter
  $featuregroup->auditTrail(\@audit_list); # setter

  # 'technologyType' association
  my $ontologyentry_ref = $featuregroup->technologyType(); # getter
  $featuregroup->technologyType($ontologyentry_ref); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $featuregroup->propertySets(); # getter
  $featuregroup->propertySets(\@namevaluetype_list); # setter

  # 'species' association
  my $ontologyentry_ref = $featuregroup->species(); # getter
  $featuregroup->species($ontologyentry_ref); # setter

  # 'distanceUnit' association
  my $distanceunit_ref = $featuregroup->distanceUnit(); # getter
  $featuregroup->distanceUnit($distanceunit_ref); # setter

  # 'descriptions' association
  my $description_array_ref = $featuregroup->descriptions(); # getter
  $featuregroup->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $featuregroup->security(); # getter
  $featuregroup->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<FeatureGroup> class:

A collection of like features.



=cut

=head1 INHERITANCE


Bio::MAGE::ArrayDesign::FeatureGroup has the following superclasses:

=over


=item * Bio::MAGE::ArrayDesign::DesignElementGroup


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::ArrayDesign::FeatureGroup];
  $__PACKAGE_NAME      = q[ArrayDesign];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::ArrayDesign::DesignElementGroup'];
  $__ATTRIBUTE_NAMES   = ['featureLength', 'name', 'identifier', 'featureWidth', 'featureHeight'];
  $__ASSOCIATION_NAMES = ['types', 'featureShape', 'features', 'auditTrail', 'species', 'propertySets', 'technologyType', 'descriptions', 'distanceUnit', 'security'];
  $__ASSOCIATIONS      = [
          'technologyType',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The technology type of this design.  By specifying a technology type, higher level analysis can use appropriate algorithms to compare the results from multiple arrays.  The technology type may be spotted cDNA or in situ photolithography.',
                                        '__CLASS_NAME' => 'FeatureGroup',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'technologyType',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The technology type of this design.  By specifying a technology type, higher level analysis can use appropriate algorithms to compare the results from multiple arrays.  The technology type may be spotted cDNA or in situ photolithography.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'featureShape',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The expected shape of the feature on the array: circular, oval, square, etc.',
                                        '__CLASS_NAME' => 'FeatureGroup',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'featureShape',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The expected shape of the feature on the array: circular, oval, square, etc.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'distanceUnit',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The unit for the feature measures.',
                                        '__CLASS_NAME' => 'FeatureGroup',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'distanceUnit',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The unit for the feature measures.',
                                         '__CLASS_NAME' => 'DistanceUnit',
                                         '__RANK' => '3',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'features',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => 'featureGroup',
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The features that belong to this group.',
                                        '__CLASS_NAME' => 'FeatureGroup',
                                        '__RANK' => '6',
                                        '__ORDERED' => 0
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'features',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '1..N',
                                         '__DOCUMENTATION' => 'The features that belong to this group.',
                                         '__CLASS_NAME' => 'Feature',
                                         '__RANK' => '4',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::ArrayDesign::FeatureGroup->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * featureLength

Sets the value of the C<featureLength> attribute

=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * featureWidth

Sets the value of the C<featureWidth> attribute

=item * featureHeight

Sets the value of the C<featureHeight> attribute


=item * types

Sets the value of the C<types> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::DesignElementGroup>).


The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


=item * featureShape

Sets the value of the C<featureShape> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * features

Sets the value of the C<features> association

The value must be of type: array of C<Bio::MAGE::DesignElement::Feature>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * species

Sets the value of the C<species> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::DesignElementGroup>).


The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * technologyType

Sets the value of the C<technologyType> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * distanceUnit

Sets the value of the C<distanceUnit> association

The value must be of type: instance of C<Bio::MAGE::Measurement::DistanceUnit>.


=item * security

Sets the value of the C<security> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Security>.


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

C<Bio::MAGE::ArrayDesign::FeatureGroup> has the following attribute accessor methods:

=over


=item featureLength

Methods for the C<featureLength> attribute.


From the MAGE-OM documentation:

The length of the feature.


=over


=item $val = $featuregroup->setFeatureLength($val)

The restricted setter method for the C<featureLength> attribute.


Input parameters: the value to which the C<featureLength> attribute will be set 

Return value: the current value of the C<featureLength> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setFeatureLength {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatureLength: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatureLength: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__FEATURELENGTH} = $val;
}


=item $val = $featuregroup->getFeatureLength()

The restricted getter method for the C<featureLength> attribute.

Input parameters: none

Return value: the current value of the C<featureLength> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatureLength {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatureLength: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATURELENGTH};
}





=back


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $featuregroup->setName($val)

The restricted setter method for the C<name> attribute.


Input parameters: the value to which the C<name> attribute will be set 

Return value: the current value of the C<name> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setName {
  my $self = shift;
  croak(__PACKAGE__ . "::setName: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setName: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__NAME} = $val;
}


=item $val = $featuregroup->getName()

The restricted getter method for the C<name> attribute.

Input parameters: none

Return value: the current value of the C<name> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getName {
  my $self = shift;
  croak(__PACKAGE__ . "::getName: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__NAME};
}





=back


=item identifier

Methods for the C<identifier> attribute.


From the MAGE-OM documentation:

An identifier is an unambiguous string that is unique within the scope (i.e. a document, a set of related documents, or a repository) of its use.


=over


=item $val = $featuregroup->setIdentifier($val)

The restricted setter method for the C<identifier> attribute.


Input parameters: the value to which the C<identifier> attribute will be set 

Return value: the current value of the C<identifier> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setIdentifier {
  my $self = shift;
  croak(__PACKAGE__ . "::setIdentifier: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setIdentifier: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__IDENTIFIER} = $val;
}


=item $val = $featuregroup->getIdentifier()

The restricted getter method for the C<identifier> attribute.

Input parameters: none

Return value: the current value of the C<identifier> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getIdentifier {
  my $self = shift;
  croak(__PACKAGE__ . "::getIdentifier: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__IDENTIFIER};
}





=back


=item featureWidth

Methods for the C<featureWidth> attribute.


From the MAGE-OM documentation:

The width of the feature.


=over


=item $val = $featuregroup->setFeatureWidth($val)

The restricted setter method for the C<featureWidth> attribute.


Input parameters: the value to which the C<featureWidth> attribute will be set 

Return value: the current value of the C<featureWidth> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setFeatureWidth {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatureWidth: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatureWidth: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__FEATUREWIDTH} = $val;
}


=item $val = $featuregroup->getFeatureWidth()

The restricted getter method for the C<featureWidth> attribute.

Input parameters: none

Return value: the current value of the C<featureWidth> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatureWidth {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatureWidth: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATUREWIDTH};
}





=back


=item featureHeight

Methods for the C<featureHeight> attribute.


From the MAGE-OM documentation:

The height of the feature.


=over


=item $val = $featuregroup->setFeatureHeight($val)

The restricted setter method for the C<featureHeight> attribute.


Input parameters: the value to which the C<featureHeight> attribute will be set 

Return value: the current value of the C<featureHeight> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setFeatureHeight {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatureHeight: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatureHeight: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__FEATUREHEIGHT} = $val;
}


=item $val = $featuregroup->getFeatureHeight()

The restricted getter method for the C<featureHeight> attribute.

Input parameters: none

Return value: the current value of the C<featureHeight> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatureHeight {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatureHeight: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATUREHEIGHT};
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

Bio::MAGE::ArrayDesign::FeatureGroup has the following association accessor methods:

=over


=item types

Methods for the C<types> association.


From the MAGE-OM documentation:

The specific type of a feature, reporter, or composite.  A composite type might be a gene while a reporter type might be a cDNA clone or an oligo.


=over


=item $array_ref = $featuregroup->setTypes($array_ref)

The restricted setter method for the C<types> association.


Input parameters: the value to which the C<types> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<types> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setTypes {
  my $self = shift;
  croak(__PACKAGE__ . "::setTypes: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setTypes: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setTypes: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setTypes: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__TYPES} = $val;
}


=item $array_ref = $featuregroup->getTypes()

The restricted getter method for the C<types> association.

Input parameters: none

Return value: the current value of the C<types> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getTypes {
  my $self = shift;
  croak(__PACKAGE__ . "::getTypes: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TYPES};
}




=item $val = $featuregroup->addTypes(@vals)

Because the types association has list cardinality, it may store more
than one value. This method adds the current list of objects in the types association.

Input parameters: the list of values C<@vals> to add to the types association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addTypes {
  my $self = shift;
  croak(__PACKAGE__ . "::addTypes: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addTypes: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__TYPES}},@vals);
}





=back


=item featureShape

Methods for the C<featureShape> association.


From the MAGE-OM documentation:

The expected shape of the feature on the array: circular, oval, square, etc.


=over


=item $val = $featuregroup->setFeatureShape($val)

The restricted setter method for the C<featureShape> association.


Input parameters: the value to which the C<featureShape> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<featureShape> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setFeatureShape {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatureShape: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatureShape: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setFeatureShape: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__FEATURESHAPE} = $val;
}


=item $val = $featuregroup->getFeatureShape()

The restricted getter method for the C<featureShape> association.

Input parameters: none

Return value: the current value of the C<featureShape> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatureShape {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatureShape: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATURESHAPE};
}





=back


=item features

Methods for the C<features> association.


From the MAGE-OM documentation:

The features that belong to this group.


=over


=item $array_ref = $featuregroup->setFeatures($array_ref)

The restricted setter method for the C<features> association.


Input parameters: the value to which the C<features> association will be set : a reference to an array of objects of type C<Bio::MAGE::DesignElement::Feature>

Return value: the current value of the C<features> association : a reference to an array of objects of type C<Bio::MAGE::DesignElement::Feature>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::DesignElement::Feature> instances

=cut


sub setFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatures: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatures: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setFeatures: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setFeatures: wrong type: " . ref($val_ent) . " expected Bio::MAGE::DesignElement::Feature")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::DesignElement::Feature');
    }
  }

  return $self->{__FEATURES} = $val;
}


=item $array_ref = $featuregroup->getFeatures()

The restricted getter method for the C<features> association.

Input parameters: none

Return value: the current value of the C<features> association : a reference to an array of objects of type C<Bio::MAGE::DesignElement::Feature>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatures: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATURES};
}




=item $val = $featuregroup->addFeatures(@vals)

Because the features association has list cardinality, it may store more
than one value. This method adds the current list of objects in the features association.

Input parameters: the list of values C<@vals> to add to the features association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::DesignElement::Feature>

=cut


sub addFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::addFeatures: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addFeatures: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::Feature")
      unless UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::Feature');
  }

  return push(@{$self->{__FEATURES}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $featuregroup->setAuditTrail($array_ref)

The restricted setter method for the C<auditTrail> association.


Input parameters: the value to which the C<auditTrail> association will be set : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Audit>

Return value: the current value of the C<auditTrail> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Audit>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::AuditAndSecurity::Audit> instances

=cut


sub setAuditTrail {
  my $self = shift;
  croak(__PACKAGE__ . "::setAuditTrail: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAuditTrail: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setAuditTrail: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setAuditTrail: wrong type: " . ref($val_ent) . " expected Bio::MAGE::AuditAndSecurity::Audit")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::AuditAndSecurity::Audit');
    }
  }

  return $self->{__AUDITTRAIL} = $val;
}


=item $array_ref = $featuregroup->getAuditTrail()

The restricted getter method for the C<auditTrail> association.

Input parameters: none

Return value: the current value of the C<auditTrail> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Audit>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAuditTrail {
  my $self = shift;
  croak(__PACKAGE__ . "::getAuditTrail: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__AUDITTRAIL};
}




=item $val = $featuregroup->addAuditTrail(@vals)

Because the auditTrail association has list cardinality, it may store more
than one value. This method adds the current list of objects in the auditTrail association.

Input parameters: the list of values C<@vals> to add to the auditTrail association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::AuditAndSecurity::Audit>

=cut


sub addAuditTrail {
  my $self = shift;
  croak(__PACKAGE__ . "::addAuditTrail: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addAuditTrail: wrong type: " . ref($val) . " expected Bio::MAGE::AuditAndSecurity::Audit")
      unless UNIVERSAL::isa($val,'Bio::MAGE::AuditAndSecurity::Audit');
  }

  return push(@{$self->{__AUDITTRAIL}},@vals);
}





=back


=item species

Methods for the C<species> association.


From the MAGE-OM documentation:

The organism from which the biosequences of this group are from.


=over


=item $val = $featuregroup->setSpecies($val)

The restricted setter method for the C<species> association.


Input parameters: the value to which the C<species> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<species> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setSpecies {
  my $self = shift;
  croak(__PACKAGE__ . "::setSpecies: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSpecies: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setSpecies: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__SPECIES} = $val;
}


=item $val = $featuregroup->getSpecies()

The restricted getter method for the C<species> association.

Input parameters: none

Return value: the current value of the C<species> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSpecies {
  my $self = shift;
  croak(__PACKAGE__ . "::getSpecies: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SPECIES};
}





=back


=item propertySets

Methods for the C<propertySets> association.


From the MAGE-OM documentation:

Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren't part of the specification proper.


=over


=item $array_ref = $featuregroup->setPropertySets($array_ref)

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


=item $array_ref = $featuregroup->getPropertySets()

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




=item $val = $featuregroup->addPropertySets(@vals)

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


=item technologyType

Methods for the C<technologyType> association.


From the MAGE-OM documentation:

The technology type of this design.  By specifying a technology type, higher level analysis can use appropriate algorithms to compare the results from multiple arrays.  The technology type may be spotted cDNA or in situ photolithography.


=over


=item $val = $featuregroup->setTechnologyType($val)

The restricted setter method for the C<technologyType> association.


Input parameters: the value to which the C<technologyType> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<technologyType> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setTechnologyType {
  my $self = shift;
  croak(__PACKAGE__ . "::setTechnologyType: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setTechnologyType: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setTechnologyType: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__TECHNOLOGYTYPE} = $val;
}


=item $val = $featuregroup->getTechnologyType()

The restricted getter method for the C<technologyType> association.

Input parameters: none

Return value: the current value of the C<technologyType> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getTechnologyType {
  my $self = shift;
  croak(__PACKAGE__ . "::getTechnologyType: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TECHNOLOGYTYPE};
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $featuregroup->setDescriptions($array_ref)

The restricted setter method for the C<descriptions> association.


Input parameters: the value to which the C<descriptions> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::Description>

Return value: the current value of the C<descriptions> association : a reference to an array of objects of type C<Bio::MAGE::Description::Description>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::Description> instances

=cut


sub setDescriptions {
  my $self = shift;
  croak(__PACKAGE__ . "::setDescriptions: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setDescriptions: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setDescriptions: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setDescriptions: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::Description")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::Description');
    }
  }

  return $self->{__DESCRIPTIONS} = $val;
}


=item $array_ref = $featuregroup->getDescriptions()

The restricted getter method for the C<descriptions> association.

Input parameters: none

Return value: the current value of the C<descriptions> association : a reference to an array of objects of type C<Bio::MAGE::Description::Description>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getDescriptions {
  my $self = shift;
  croak(__PACKAGE__ . "::getDescriptions: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__DESCRIPTIONS};
}




=item $val = $featuregroup->addDescriptions(@vals)

Because the descriptions association has list cardinality, it may store more
than one value. This method adds the current list of objects in the descriptions association.

Input parameters: the list of values C<@vals> to add to the descriptions association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::Description>

=cut


sub addDescriptions {
  my $self = shift;
  croak(__PACKAGE__ . "::addDescriptions: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addDescriptions: wrong type: " . ref($val) . " expected Bio::MAGE::Description::Description")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::Description');
  }

  return push(@{$self->{__DESCRIPTIONS}},@vals);
}





=back


=item distanceUnit

Methods for the C<distanceUnit> association.


From the MAGE-OM documentation:

The unit for the feature measures.


=over


=item $val = $featuregroup->setDistanceUnit($val)

The restricted setter method for the C<distanceUnit> association.


Input parameters: the value to which the C<distanceUnit> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<distanceUnit> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Measurement::DistanceUnit>

=cut


sub setDistanceUnit {
  my $self = shift;
  croak(__PACKAGE__ . "::setDistanceUnit: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setDistanceUnit: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setDistanceUnit: wrong type: " . ref($val) . " expected Bio::MAGE::Measurement::DistanceUnit") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Measurement::DistanceUnit');
  return $self->{__DISTANCEUNIT} = $val;
}


=item $val = $featuregroup->getDistanceUnit()

The restricted getter method for the C<distanceUnit> association.

Input parameters: none

Return value: the current value of the C<distanceUnit> association : an instance of type C<Bio::MAGE::Measurement::DistanceUnit>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getDistanceUnit {
  my $self = shift;
  croak(__PACKAGE__ . "::getDistanceUnit: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__DISTANCEUNIT};
}





=back


=item security

Methods for the C<security> association.


From the MAGE-OM documentation:

Information on the security for the instance of the class.


=over


=item $val = $featuregroup->setSecurity($val)

The restricted setter method for the C<security> association.


Input parameters: the value to which the C<security> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<security> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::AuditAndSecurity::Security>

=cut


sub setSecurity {
  my $self = shift;
  croak(__PACKAGE__ . "::setSecurity: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSecurity: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setSecurity: wrong type: " . ref($val) . " expected Bio::MAGE::AuditAndSecurity::Security") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::AuditAndSecurity::Security');
  return $self->{__SECURITY} = $val;
}


=item $val = $featuregroup->getSecurity()

The restricted getter method for the C<security> association.

Input parameters: none

Return value: the current value of the C<security> association : an instance of type C<Bio::MAGE::AuditAndSecurity::Security>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSecurity {
  my $self = shift;
  croak(__PACKAGE__ . "::getSecurity: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SECURITY};
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

