##############################
#
# Bio::MAGE::Array::ManufactureLIMSBiomaterial
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



package Bio::MAGE::Array::ManufactureLIMSBiomaterial;
use strict;
use Carp;

use base qw(Bio::MAGE::Array::ManufactureLIMS);

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

Bio::MAGE::Array::ManufactureLIMSBiomaterial - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::Array::ManufactureLIMSBiomaterial

  # creating an empty instance
  my $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new();

  # creating an instance with existing data
  my $manufacturelimsbiomaterial = Bio::MAGE::Array::ManufactureLIMSBiomaterial->new(
        bioMaterialPlateCol=>$biomaterialplatecol_val,
        bioMaterialPlateRow=>$biomaterialplaterow_val,
        bioMaterialPlateIdentifier=>$biomaterialplateidentifier_val,
        quality=>$quality_val,
        bioMaterial=>$biomaterial_ref,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        feature=>$feature_ref,
        identifierLIMS=>$databaseentry_ref,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'bioMaterialPlateCol' attribute
  my $bioMaterialPlateCol_val = $manufacturelimsbiomaterial->bioMaterialPlateCol(); # getter
  $manufacturelimsbiomaterial->bioMaterialPlateCol($value); # setter

  # 'bioMaterialPlateRow' attribute
  my $bioMaterialPlateRow_val = $manufacturelimsbiomaterial->bioMaterialPlateRow(); # getter
  $manufacturelimsbiomaterial->bioMaterialPlateRow($value); # setter

  # 'bioMaterialPlateIdentifier' attribute
  my $bioMaterialPlateIdentifier_val = $manufacturelimsbiomaterial->bioMaterialPlateIdentifier(); # getter
  $manufacturelimsbiomaterial->bioMaterialPlateIdentifier($value); # setter

  # 'quality' attribute
  my $quality_val = $manufacturelimsbiomaterial->quality(); # getter
  $manufacturelimsbiomaterial->quality($value); # setter


  # 'bioMaterial' association
  my $biomaterial_ref = $manufacturelimsbiomaterial->bioMaterial(); # getter
  $manufacturelimsbiomaterial->bioMaterial($biomaterial_ref); # setter

  # 'auditTrail' association
  my $audit_array_ref = $manufacturelimsbiomaterial->auditTrail(); # getter
  $manufacturelimsbiomaterial->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $manufacturelimsbiomaterial->propertySets(); # getter
  $manufacturelimsbiomaterial->propertySets(\@namevaluetype_list); # setter

  # 'feature' association
  my $feature_ref = $manufacturelimsbiomaterial->feature(); # getter
  $manufacturelimsbiomaterial->feature($feature_ref); # setter

  # 'identifierLIMS' association
  my $databaseentry_ref = $manufacturelimsbiomaterial->identifierLIMS(); # getter
  $manufacturelimsbiomaterial->identifierLIMS($databaseentry_ref); # setter

  # 'descriptions' association
  my $description_array_ref = $manufacturelimsbiomaterial->descriptions(); # getter
  $manufacturelimsbiomaterial->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $manufacturelimsbiomaterial->security(); # getter
  $manufacturelimsbiomaterial->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<ManufactureLIMSBiomaterial> class:

Stores the location from which a biomaterial was obtained.



=cut

=head1 INHERITANCE


Bio::MAGE::Array::ManufactureLIMSBiomaterial has the following superclasses:

=over


=item * Bio::MAGE::Array::ManufactureLIMS


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::Array::ManufactureLIMSBiomaterial];
  $__PACKAGE_NAME      = q[Array];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Array::ManufactureLIMS'];
  $__ATTRIBUTE_NAMES   = ['bioMaterialPlateCol', 'bioMaterialPlateRow', 'bioMaterialPlateIdentifier', 'quality'];
  $__ASSOCIATION_NAMES = ['bioMaterial', 'auditTrail', 'propertySets', 'feature', 'identifierLIMS', 'descriptions', 'security'];
  $__ASSOCIATIONS      = []

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::Array::ManufactureLIMSBiomaterial->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * bioMaterialPlateCol

Sets the value of the C<bioMaterialPlateCol> attribute

=item * bioMaterialPlateRow

Sets the value of the C<bioMaterialPlateRow> attribute

=item * bioMaterialPlateIdentifier

Sets the value of the C<bioMaterialPlateIdentifier> attribute

=item * quality

Sets the value of the C<quality> attribute (this attribute was inherited from class C<Bio::MAGE::Array::ManufactureLIMS>).



=item * bioMaterial

Sets the value of the C<bioMaterial> association (this association was inherited from class C<Bio::MAGE::Array::ManufactureLIMS>).


The value must be of type: instance of C<Bio::MAGE::BioMaterial::BioMaterial>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * feature

Sets the value of the C<feature> association (this association was inherited from class C<Bio::MAGE::Array::ManufactureLIMS>).


The value must be of type: instance of C<Bio::MAGE::DesignElement::Feature>.


=item * identifierLIMS

Sets the value of the C<identifierLIMS> association (this association was inherited from class C<Bio::MAGE::Array::ManufactureLIMS>).


The value must be of type: instance of C<Bio::MAGE::Description::DatabaseEntry>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


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

C<Bio::MAGE::Array::ManufactureLIMSBiomaterial> has the following attribute accessor methods:

=over


=item bioMaterialPlateCol

Methods for the C<bioMaterialPlateCol> attribute.


From the MAGE-OM documentation:

The plate column from which a biomaterial was obtained.  Specified by a number.


=over


=item $val = $manufacturelimsbiomaterial->setBioMaterialPlateCol($val)

The restricted setter method for the C<bioMaterialPlateCol> attribute.


Input parameters: the value to which the C<bioMaterialPlateCol> attribute will be set 

Return value: the current value of the C<bioMaterialPlateCol> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setBioMaterialPlateCol {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioMaterialPlateCol: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioMaterialPlateCol: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__BIOMATERIALPLATECOL} = $val;
}


=item $val = $manufacturelimsbiomaterial->getBioMaterialPlateCol()

The restricted getter method for the C<bioMaterialPlateCol> attribute.

Input parameters: none

Return value: the current value of the C<bioMaterialPlateCol> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioMaterialPlateCol {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioMaterialPlateCol: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOMATERIALPLATECOL};
}





=back


=item bioMaterialPlateRow

Methods for the C<bioMaterialPlateRow> attribute.


From the MAGE-OM documentation:

The plate row from which a biomaterial was obtained.  Specified by a letter.


=over


=item $val = $manufacturelimsbiomaterial->setBioMaterialPlateRow($val)

The restricted setter method for the C<bioMaterialPlateRow> attribute.


Input parameters: the value to which the C<bioMaterialPlateRow> attribute will be set 

Return value: the current value of the C<bioMaterialPlateRow> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setBioMaterialPlateRow {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioMaterialPlateRow: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioMaterialPlateRow: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__BIOMATERIALPLATEROW} = $val;
}


=item $val = $manufacturelimsbiomaterial->getBioMaterialPlateRow()

The restricted getter method for the C<bioMaterialPlateRow> attribute.

Input parameters: none

Return value: the current value of the C<bioMaterialPlateRow> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioMaterialPlateRow {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioMaterialPlateRow: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOMATERIALPLATEROW};
}





=back


=item bioMaterialPlateIdentifier

Methods for the C<bioMaterialPlateIdentifier> attribute.


From the MAGE-OM documentation:

The plate from which a biomaterial was obtained.


=over


=item $val = $manufacturelimsbiomaterial->setBioMaterialPlateIdentifier($val)

The restricted setter method for the C<bioMaterialPlateIdentifier> attribute.


Input parameters: the value to which the C<bioMaterialPlateIdentifier> attribute will be set 

Return value: the current value of the C<bioMaterialPlateIdentifier> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setBioMaterialPlateIdentifier {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioMaterialPlateIdentifier: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioMaterialPlateIdentifier: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__BIOMATERIALPLATEIDENTIFIER} = $val;
}


=item $val = $manufacturelimsbiomaterial->getBioMaterialPlateIdentifier()

The restricted getter method for the C<bioMaterialPlateIdentifier> attribute.

Input parameters: none

Return value: the current value of the C<bioMaterialPlateIdentifier> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioMaterialPlateIdentifier {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioMaterialPlateIdentifier: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOMATERIALPLATEIDENTIFIER};
}





=back


=item quality

Methods for the C<quality> attribute.


From the MAGE-OM documentation:

A brief description of the quality of the array manufacture process.


=over


=item $val = $manufacturelimsbiomaterial->setQuality($val)

The restricted setter method for the C<quality> attribute.


Input parameters: the value to which the C<quality> attribute will be set 

Return value: the current value of the C<quality> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setQuality {
  my $self = shift;
  croak(__PACKAGE__ . "::setQuality: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setQuality: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__QUALITY} = $val;
}


=item $val = $manufacturelimsbiomaterial->getQuality()

The restricted getter method for the C<quality> attribute.

Input parameters: none

Return value: the current value of the C<quality> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getQuality {
  my $self = shift;
  croak(__PACKAGE__ . "::getQuality: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__QUALITY};
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

Bio::MAGE::Array::ManufactureLIMSBiomaterial has the following association accessor methods:

=over


=item bioMaterial

Methods for the C<bioMaterial> association.


From the MAGE-OM documentation:

The BioMaterial used for the feature.


=over


=item $val = $manufacturelimsbiomaterial->setBioMaterial($val)

The restricted setter method for the C<bioMaterial> association.


Input parameters: the value to which the C<bioMaterial> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<bioMaterial> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::BioMaterial::BioMaterial>

=cut


sub setBioMaterial {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioMaterial: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioMaterial: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setBioMaterial: wrong type: " . ref($val) . " expected Bio::MAGE::BioMaterial::BioMaterial") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::BioMaterial::BioMaterial');
  return $self->{__BIOMATERIAL} = $val;
}


=item $val = $manufacturelimsbiomaterial->getBioMaterial()

The restricted getter method for the C<bioMaterial> association.

Input parameters: none

Return value: the current value of the C<bioMaterial> association : an instance of type C<Bio::MAGE::BioMaterial::BioMaterial>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioMaterial {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioMaterial: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOMATERIAL};
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $manufacturelimsbiomaterial->setAuditTrail($array_ref)

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


=item $array_ref = $manufacturelimsbiomaterial->getAuditTrail()

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




=item $val = $manufacturelimsbiomaterial->addAuditTrail(@vals)

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


=item propertySets

Methods for the C<propertySets> association.


From the MAGE-OM documentation:

Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren't part of the specification proper.


=over


=item $array_ref = $manufacturelimsbiomaterial->setPropertySets($array_ref)

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


=item $array_ref = $manufacturelimsbiomaterial->getPropertySets()

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




=item $val = $manufacturelimsbiomaterial->addPropertySets(@vals)

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


=item feature

Methods for the C<feature> association.


From the MAGE-OM documentation:

The feature whose LIMS information is being described.


=over


=item $val = $manufacturelimsbiomaterial->setFeature($val)

The restricted setter method for the C<feature> association.


Input parameters: the value to which the C<feature> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<feature> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::DesignElement::Feature>

=cut


sub setFeature {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeature: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeature: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setFeature: wrong type: " . ref($val) . " expected Bio::MAGE::DesignElement::Feature") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::DesignElement::Feature');
  return $self->{__FEATURE} = $val;
}


=item $val = $manufacturelimsbiomaterial->getFeature()

The restricted getter method for the C<feature> association.

Input parameters: none

Return value: the current value of the C<feature> association : an instance of type C<Bio::MAGE::DesignElement::Feature>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeature {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeature: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATURE};
}





=back


=item identifierLIMS

Methods for the C<identifierLIMS> association.


From the MAGE-OM documentation:

Association to a LIMS data source for further information on the manufacturing process.


=over


=item $val = $manufacturelimsbiomaterial->setIdentifierLIMS($val)

The restricted setter method for the C<identifierLIMS> association.


Input parameters: the value to which the C<identifierLIMS> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<identifierLIMS> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::DatabaseEntry>

=cut


sub setIdentifierLIMS {
  my $self = shift;
  croak(__PACKAGE__ . "::setIdentifierLIMS: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setIdentifierLIMS: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setIdentifierLIMS: wrong type: " . ref($val) . " expected Bio::MAGE::Description::DatabaseEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::DatabaseEntry');
  return $self->{__IDENTIFIERLIMS} = $val;
}


=item $val = $manufacturelimsbiomaterial->getIdentifierLIMS()

The restricted getter method for the C<identifierLIMS> association.

Input parameters: none

Return value: the current value of the C<identifierLIMS> association : an instance of type C<Bio::MAGE::Description::DatabaseEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getIdentifierLIMS {
  my $self = shift;
  croak(__PACKAGE__ . "::getIdentifierLIMS: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__IDENTIFIERLIMS};
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $manufacturelimsbiomaterial->setDescriptions($array_ref)

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


=item $array_ref = $manufacturelimsbiomaterial->getDescriptions()

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




=item $val = $manufacturelimsbiomaterial->addDescriptions(@vals)

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


=item security

Methods for the C<security> association.


From the MAGE-OM documentation:

Information on the security for the instance of the class.


=over


=item $val = $manufacturelimsbiomaterial->setSecurity($val)

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


=item $val = $manufacturelimsbiomaterial->getSecurity()

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

