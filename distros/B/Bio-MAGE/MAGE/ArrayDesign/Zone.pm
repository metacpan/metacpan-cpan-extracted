##############################
#
# Bio::MAGE::ArrayDesign::Zone
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



package Bio::MAGE::ArrayDesign::Zone;
use strict;
use Carp;

use base qw(Bio::MAGE::Identifiable);

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

Bio::MAGE::ArrayDesign::Zone - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::ArrayDesign::Zone

  # creating an empty instance
  my $zone = Bio::MAGE::ArrayDesign::Zone->new();

  # creating an instance with existing data
  my $zone = Bio::MAGE::ArrayDesign::Zone->new(
        lowerRightY=>$lowerrighty_val,
        lowerRightX=>$lowerrightx_val,
        upperLeftX=>$upperleftx_val,
        name=>$name_val,
        upperLeftY=>$upperlefty_val,
        identifier=>$identifier_val,
        row=>$row_val,
        column=>$column_val,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        distanceUnit=>$distanceunit_ref,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'lowerRightY' attribute
  my $lowerRightY_val = $zone->lowerRightY(); # getter
  $zone->lowerRightY($value); # setter

  # 'lowerRightX' attribute
  my $lowerRightX_val = $zone->lowerRightX(); # getter
  $zone->lowerRightX($value); # setter

  # 'upperLeftX' attribute
  my $upperLeftX_val = $zone->upperLeftX(); # getter
  $zone->upperLeftX($value); # setter

  # 'name' attribute
  my $name_val = $zone->name(); # getter
  $zone->name($value); # setter

  # 'upperLeftY' attribute
  my $upperLeftY_val = $zone->upperLeftY(); # getter
  $zone->upperLeftY($value); # setter

  # 'identifier' attribute
  my $identifier_val = $zone->identifier(); # getter
  $zone->identifier($value); # setter

  # 'row' attribute
  my $row_val = $zone->row(); # getter
  $zone->row($value); # setter

  # 'column' attribute
  my $column_val = $zone->column(); # getter
  $zone->column($value); # setter


  # 'auditTrail' association
  my $audit_array_ref = $zone->auditTrail(); # getter
  $zone->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $zone->propertySets(); # getter
  $zone->propertySets(\@namevaluetype_list); # setter

  # 'distanceUnit' association
  my $distanceunit_ref = $zone->distanceUnit(); # getter
  $zone->distanceUnit($distanceunit_ref); # setter

  # 'descriptions' association
  my $description_array_ref = $zone->descriptions(); # getter
  $zone->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $zone->security(); # getter
  $zone->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<Zone> class:

Specifies the location of a zone on an array.



=cut

=head1 INHERITANCE


Bio::MAGE::ArrayDesign::Zone has the following superclasses:

=over


=item * Bio::MAGE::Identifiable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::ArrayDesign::Zone];
  $__PACKAGE_NAME      = q[ArrayDesign];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Identifiable'];
  $__ATTRIBUTE_NAMES   = ['lowerRightY', 'lowerRightX', 'upperLeftX', 'name', 'upperLeftY', 'identifier', 'row', 'column'];
  $__ASSOCIATION_NAMES = ['auditTrail', 'propertySets', 'descriptions', 'distanceUnit', 'security'];
  $__ASSOCIATIONS      = [
          'distanceUnit',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Unit for the Zone attributes.',
                                        '__CLASS_NAME' => 'Zone',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'distanceUnit',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'Unit for the Zone attributes.',
                                         '__CLASS_NAME' => 'DistanceUnit',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::ArrayDesign::Zone->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * lowerRightY

Sets the value of the C<lowerRightY> attribute

=item * lowerRightX

Sets the value of the C<lowerRightX> attribute

=item * upperLeftX

Sets the value of the C<upperLeftX> attribute

=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * upperLeftY

Sets the value of the C<upperLeftY> attribute

=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * row

Sets the value of the C<row> attribute

=item * column

Sets the value of the C<column> attribute


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


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

C<Bio::MAGE::ArrayDesign::Zone> has the following attribute accessor methods:

=over


=item lowerRightY

Methods for the C<lowerRightY> attribute.


From the MAGE-OM documentation:

Boundary horizontal lower right position relative to (0,0).


=over


=item $val = $zone->setLowerRightY($val)

The restricted setter method for the C<lowerRightY> attribute.


Input parameters: the value to which the C<lowerRightY> attribute will be set 

Return value: the current value of the C<lowerRightY> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setLowerRightY {
  my $self = shift;
  croak(__PACKAGE__ . "::setLowerRightY: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setLowerRightY: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__LOWERRIGHTY} = $val;
}


=item $val = $zone->getLowerRightY()

The restricted getter method for the C<lowerRightY> attribute.

Input parameters: none

Return value: the current value of the C<lowerRightY> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getLowerRightY {
  my $self = shift;
  croak(__PACKAGE__ . "::getLowerRightY: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__LOWERRIGHTY};
}





=back


=item lowerRightX

Methods for the C<lowerRightX> attribute.


From the MAGE-OM documentation:

Boundary vertical lower right position relative to (0,0).


=over


=item $val = $zone->setLowerRightX($val)

The restricted setter method for the C<lowerRightX> attribute.


Input parameters: the value to which the C<lowerRightX> attribute will be set 

Return value: the current value of the C<lowerRightX> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setLowerRightX {
  my $self = shift;
  croak(__PACKAGE__ . "::setLowerRightX: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setLowerRightX: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__LOWERRIGHTX} = $val;
}


=item $val = $zone->getLowerRightX()

The restricted getter method for the C<lowerRightX> attribute.

Input parameters: none

Return value: the current value of the C<lowerRightX> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getLowerRightX {
  my $self = shift;
  croak(__PACKAGE__ . "::getLowerRightX: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__LOWERRIGHTX};
}





=back


=item upperLeftX

Methods for the C<upperLeftX> attribute.


From the MAGE-OM documentation:

Boundary vertical upper left position relative to (0,0).


=over


=item $val = $zone->setUpperLeftX($val)

The restricted setter method for the C<upperLeftX> attribute.


Input parameters: the value to which the C<upperLeftX> attribute will be set 

Return value: the current value of the C<upperLeftX> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setUpperLeftX {
  my $self = shift;
  croak(__PACKAGE__ . "::setUpperLeftX: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setUpperLeftX: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__UPPERLEFTX} = $val;
}


=item $val = $zone->getUpperLeftX()

The restricted getter method for the C<upperLeftX> attribute.

Input parameters: none

Return value: the current value of the C<upperLeftX> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getUpperLeftX {
  my $self = shift;
  croak(__PACKAGE__ . "::getUpperLeftX: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__UPPERLEFTX};
}





=back


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $zone->setName($val)

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


=item $val = $zone->getName()

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


=item upperLeftY

Methods for the C<upperLeftY> attribute.


From the MAGE-OM documentation:

Boundary horizontal upper left position relative to (0,0).


=over


=item $val = $zone->setUpperLeftY($val)

The restricted setter method for the C<upperLeftY> attribute.


Input parameters: the value to which the C<upperLeftY> attribute will be set 

Return value: the current value of the C<upperLeftY> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setUpperLeftY {
  my $self = shift;
  croak(__PACKAGE__ . "::setUpperLeftY: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setUpperLeftY: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__UPPERLEFTY} = $val;
}


=item $val = $zone->getUpperLeftY()

The restricted getter method for the C<upperLeftY> attribute.

Input parameters: none

Return value: the current value of the C<upperLeftY> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getUpperLeftY {
  my $self = shift;
  croak(__PACKAGE__ . "::getUpperLeftY: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__UPPERLEFTY};
}





=back


=item identifier

Methods for the C<identifier> attribute.


From the MAGE-OM documentation:

An identifier is an unambiguous string that is unique within the scope (i.e. a document, a set of related documents, or a repository) of its use.


=over


=item $val = $zone->setIdentifier($val)

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


=item $val = $zone->getIdentifier()

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


=item row

Methods for the C<row> attribute.


From the MAGE-OM documentation:

row position in the ZoneGroup


=over


=item $val = $zone->setRow($val)

The restricted setter method for the C<row> attribute.


Input parameters: the value to which the C<row> attribute will be set 

Return value: the current value of the C<row> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setRow {
  my $self = shift;
  croak(__PACKAGE__ . "::setRow: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setRow: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__ROW} = $val;
}


=item $val = $zone->getRow()

The restricted getter method for the C<row> attribute.

Input parameters: none

Return value: the current value of the C<row> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getRow {
  my $self = shift;
  croak(__PACKAGE__ . "::getRow: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ROW};
}





=back


=item column

Methods for the C<column> attribute.


From the MAGE-OM documentation:

column position in the ZoneGroup.


=over


=item $val = $zone->setColumn($val)

The restricted setter method for the C<column> attribute.


Input parameters: the value to which the C<column> attribute will be set 

Return value: the current value of the C<column> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setColumn {
  my $self = shift;
  croak(__PACKAGE__ . "::setColumn: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setColumn: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__COLUMN} = $val;
}


=item $val = $zone->getColumn()

The restricted getter method for the C<column> attribute.

Input parameters: none

Return value: the current value of the C<column> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getColumn {
  my $self = shift;
  croak(__PACKAGE__ . "::getColumn: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__COLUMN};
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

Bio::MAGE::ArrayDesign::Zone has the following association accessor methods:

=over


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $zone->setAuditTrail($array_ref)

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


=item $array_ref = $zone->getAuditTrail()

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




=item $val = $zone->addAuditTrail(@vals)

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


=item $array_ref = $zone->setPropertySets($array_ref)

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


=item $array_ref = $zone->getPropertySets()

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




=item $val = $zone->addPropertySets(@vals)

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


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $zone->setDescriptions($array_ref)

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


=item $array_ref = $zone->getDescriptions()

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




=item $val = $zone->addDescriptions(@vals)

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

Unit for the Zone attributes.


=over


=item $val = $zone->setDistanceUnit($val)

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


=item $val = $zone->getDistanceUnit()

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


=item $val = $zone->setSecurity($val)

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


=item $val = $zone->getSecurity()

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

