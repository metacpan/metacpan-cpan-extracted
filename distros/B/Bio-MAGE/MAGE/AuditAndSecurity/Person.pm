##############################
#
# Bio::MAGE::AuditAndSecurity::Person
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



package Bio::MAGE::AuditAndSecurity::Person;
use strict;
use Carp;

use base qw(Bio::MAGE::AuditAndSecurity::Contact);

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

Bio::MAGE::AuditAndSecurity::Person - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::AuditAndSecurity::Person

  # creating an empty instance
  my $person = Bio::MAGE::AuditAndSecurity::Person->new();

  # creating an instance with existing data
  my $person = Bio::MAGE::AuditAndSecurity::Person->new(
        firstName=>$firstname_val,
        URI=>$uri_val,
        name=>$name_val,
        midInitials=>$midinitials_val,
        phone=>$phone_val,
        email=>$email_val,
        identifier=>$identifier_val,
        tollFreePhone=>$tollfreephone_val,
        fax=>$fax_val,
        address=>$address_val,
        lastName=>$lastname_val,
        roles=>\@ontologyentry_list,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        descriptions=>\@description_list,
        security=>$security_ref,
        affiliation=>$organization_ref,
  );


  # 'firstName' attribute
  my $firstName_val = $person->firstName(); # getter
  $person->firstName($value); # setter

  # 'URI' attribute
  my $URI_val = $person->URI(); # getter
  $person->URI($value); # setter

  # 'name' attribute
  my $name_val = $person->name(); # getter
  $person->name($value); # setter

  # 'midInitials' attribute
  my $midInitials_val = $person->midInitials(); # getter
  $person->midInitials($value); # setter

  # 'phone' attribute
  my $phone_val = $person->phone(); # getter
  $person->phone($value); # setter

  # 'email' attribute
  my $email_val = $person->email(); # getter
  $person->email($value); # setter

  # 'identifier' attribute
  my $identifier_val = $person->identifier(); # getter
  $person->identifier($value); # setter

  # 'tollFreePhone' attribute
  my $tollFreePhone_val = $person->tollFreePhone(); # getter
  $person->tollFreePhone($value); # setter

  # 'fax' attribute
  my $fax_val = $person->fax(); # getter
  $person->fax($value); # setter

  # 'address' attribute
  my $address_val = $person->address(); # getter
  $person->address($value); # setter

  # 'lastName' attribute
  my $lastName_val = $person->lastName(); # getter
  $person->lastName($value); # setter


  # 'roles' association
  my $ontologyentry_array_ref = $person->roles(); # getter
  $person->roles(\@ontologyentry_list); # setter

  # 'auditTrail' association
  my $audit_array_ref = $person->auditTrail(); # getter
  $person->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $person->propertySets(); # getter
  $person->propertySets(\@namevaluetype_list); # setter

  # 'descriptions' association
  my $description_array_ref = $person->descriptions(); # getter
  $person->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $person->security(); # getter
  $person->security($security_ref); # setter

  # 'affiliation' association
  my $organization_ref = $person->affiliation(); # getter
  $person->affiliation($organization_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<Person> class:

A person for which the attributes are self describing.



=cut

=head1 INHERITANCE


Bio::MAGE::AuditAndSecurity::Person has the following superclasses:

=over


=item * Bio::MAGE::AuditAndSecurity::Contact


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::AuditAndSecurity::Person];
  $__PACKAGE_NAME      = q[AuditAndSecurity];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::AuditAndSecurity::Contact'];
  $__ATTRIBUTE_NAMES   = ['firstName', 'URI', 'name', 'midInitials', 'phone', 'email', 'identifier', 'tollFreePhone', 'fax', 'address', 'lastName'];
  $__ASSOCIATION_NAMES = ['roles', 'auditTrail', 'propertySets', 'descriptions', 'security', 'affiliation'];
  $__ASSOCIATIONS      = [
          'affiliation',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 1,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'The organization a person belongs to.',
                                        '__CLASS_NAME' => 'Person',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'affiliation',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The organization a person belongs to.',
                                         '__CLASS_NAME' => 'Organization',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::AuditAndSecurity::Person->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * firstName

Sets the value of the C<firstName> attribute

=item * URI

Sets the value of the C<URI> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * midInitials

Sets the value of the C<midInitials> attribute

=item * phone

Sets the value of the C<phone> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * email

Sets the value of the C<email> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * tollFreePhone

Sets the value of the C<tollFreePhone> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * fax

Sets the value of the C<fax> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * address

Sets the value of the C<address> attribute (this attribute was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


=item * lastName

Sets the value of the C<lastName> attribute


=item * roles

Sets the value of the C<roles> association (this association was inherited from class C<Bio::MAGE::AuditAndSecurity::Contact>).


The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * security

Sets the value of the C<security> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Security>.


=item * affiliation

Sets the value of the C<affiliation> association

The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Organization>.


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

C<Bio::MAGE::AuditAndSecurity::Person> has the following attribute accessor methods:

=over


=item firstName

Methods for the C<firstName> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setFirstName($val)

The restricted setter method for the C<firstName> attribute.


Input parameters: the value to which the C<firstName> attribute will be set 

Return value: the current value of the C<firstName> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setFirstName {
  my $self = shift;
  croak(__PACKAGE__ . "::setFirstName: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFirstName: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__FIRSTNAME} = $val;
}


=item $val = $person->getFirstName()

The restricted getter method for the C<firstName> attribute.

Input parameters: none

Return value: the current value of the C<firstName> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFirstName {
  my $self = shift;
  croak(__PACKAGE__ . "::getFirstName: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FIRSTNAME};
}





=back


=item URI

Methods for the C<URI> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setURI($val)

The restricted setter method for the C<URI> attribute.


Input parameters: the value to which the C<URI> attribute will be set 

Return value: the current value of the C<URI> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setURI {
  my $self = shift;
  croak(__PACKAGE__ . "::setURI: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setURI: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__URI} = $val;
}


=item $val = $person->getURI()

The restricted getter method for the C<URI> attribute.

Input parameters: none

Return value: the current value of the C<URI> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getURI {
  my $self = shift;
  croak(__PACKAGE__ . "::getURI: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__URI};
}





=back


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $person->setName($val)

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


=item $val = $person->getName()

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


=item midInitials

Methods for the C<midInitials> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setMidInitials($val)

The restricted setter method for the C<midInitials> attribute.


Input parameters: the value to which the C<midInitials> attribute will be set 

Return value: the current value of the C<midInitials> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setMidInitials {
  my $self = shift;
  croak(__PACKAGE__ . "::setMidInitials: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setMidInitials: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__MIDINITIALS} = $val;
}


=item $val = $person->getMidInitials()

The restricted getter method for the C<midInitials> attribute.

Input parameters: none

Return value: the current value of the C<midInitials> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getMidInitials {
  my $self = shift;
  croak(__PACKAGE__ . "::getMidInitials: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__MIDINITIALS};
}





=back


=item phone

Methods for the C<phone> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setPhone($val)

The restricted setter method for the C<phone> attribute.


Input parameters: the value to which the C<phone> attribute will be set 

Return value: the current value of the C<phone> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setPhone {
  my $self = shift;
  croak(__PACKAGE__ . "::setPhone: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPhone: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__PHONE} = $val;
}


=item $val = $person->getPhone()

The restricted getter method for the C<phone> attribute.

Input parameters: none

Return value: the current value of the C<phone> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPhone {
  my $self = shift;
  croak(__PACKAGE__ . "::getPhone: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PHONE};
}





=back


=item email

Methods for the C<email> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setEmail($val)

The restricted setter method for the C<email> attribute.


Input parameters: the value to which the C<email> attribute will be set 

Return value: the current value of the C<email> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setEmail {
  my $self = shift;
  croak(__PACKAGE__ . "::setEmail: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setEmail: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__EMAIL} = $val;
}


=item $val = $person->getEmail()

The restricted getter method for the C<email> attribute.

Input parameters: none

Return value: the current value of the C<email> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getEmail {
  my $self = shift;
  croak(__PACKAGE__ . "::getEmail: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__EMAIL};
}





=back


=item identifier

Methods for the C<identifier> attribute.


From the MAGE-OM documentation:

An identifier is an unambiguous string that is unique within the scope (i.e. a document, a set of related documents, or a repository) of its use.


=over


=item $val = $person->setIdentifier($val)

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


=item $val = $person->getIdentifier()

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


=item tollFreePhone

Methods for the C<tollFreePhone> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setTollFreePhone($val)

The restricted setter method for the C<tollFreePhone> attribute.


Input parameters: the value to which the C<tollFreePhone> attribute will be set 

Return value: the current value of the C<tollFreePhone> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setTollFreePhone {
  my $self = shift;
  croak(__PACKAGE__ . "::setTollFreePhone: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setTollFreePhone: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__TOLLFREEPHONE} = $val;
}


=item $val = $person->getTollFreePhone()

The restricted getter method for the C<tollFreePhone> attribute.

Input parameters: none

Return value: the current value of the C<tollFreePhone> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getTollFreePhone {
  my $self = shift;
  croak(__PACKAGE__ . "::getTollFreePhone: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TOLLFREEPHONE};
}





=back


=item fax

Methods for the C<fax> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setFax($val)

The restricted setter method for the C<fax> attribute.


Input parameters: the value to which the C<fax> attribute will be set 

Return value: the current value of the C<fax> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setFax {
  my $self = shift;
  croak(__PACKAGE__ . "::setFax: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFax: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__FAX} = $val;
}


=item $val = $person->getFax()

The restricted getter method for the C<fax> attribute.

Input parameters: none

Return value: the current value of the C<fax> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFax {
  my $self = shift;
  croak(__PACKAGE__ . "::getFax: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FAX};
}





=back


=item address

Methods for the C<address> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setAddress($val)

The restricted setter method for the C<address> attribute.


Input parameters: the value to which the C<address> attribute will be set 

Return value: the current value of the C<address> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setAddress {
  my $self = shift;
  croak(__PACKAGE__ . "::setAddress: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAddress: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__ADDRESS} = $val;
}


=item $val = $person->getAddress()

The restricted getter method for the C<address> attribute.

Input parameters: none

Return value: the current value of the C<address> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAddress {
  my $self = shift;
  croak(__PACKAGE__ . "::getAddress: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ADDRESS};
}





=back


=item lastName

Methods for the C<lastName> attribute.


From the MAGE-OM documentation:




=over


=item $val = $person->setLastName($val)

The restricted setter method for the C<lastName> attribute.


Input parameters: the value to which the C<lastName> attribute will be set 

Return value: the current value of the C<lastName> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setLastName {
  my $self = shift;
  croak(__PACKAGE__ . "::setLastName: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setLastName: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__LASTNAME} = $val;
}


=item $val = $person->getLastName()

The restricted getter method for the C<lastName> attribute.

Input parameters: none

Return value: the current value of the C<lastName> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getLastName {
  my $self = shift;
  croak(__PACKAGE__ . "::getLastName: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__LASTNAME};
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

Bio::MAGE::AuditAndSecurity::Person has the following association accessor methods:

=over


=item roles

Methods for the C<roles> association.


From the MAGE-OM documentation:

The roles (lab equipment sales, contractor, etc.) the contact fills.


=over


=item $array_ref = $person->setRoles($array_ref)

The restricted setter method for the C<roles> association.


Input parameters: the value to which the C<roles> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<roles> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setRoles {
  my $self = shift;
  croak(__PACKAGE__ . "::setRoles: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setRoles: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setRoles: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setRoles: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__ROLES} = $val;
}


=item $array_ref = $person->getRoles()

The restricted getter method for the C<roles> association.

Input parameters: none

Return value: the current value of the C<roles> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getRoles {
  my $self = shift;
  croak(__PACKAGE__ . "::getRoles: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ROLES};
}




=item $val = $person->addRoles(@vals)

Because the roles association has list cardinality, it may store more
than one value. This method adds the current list of objects in the roles association.

Input parameters: the list of values C<@vals> to add to the roles association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addRoles {
  my $self = shift;
  croak(__PACKAGE__ . "::addRoles: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addRoles: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__ROLES}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $person->setAuditTrail($array_ref)

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


=item $array_ref = $person->getAuditTrail()

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




=item $val = $person->addAuditTrail(@vals)

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


=item $array_ref = $person->setPropertySets($array_ref)

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


=item $array_ref = $person->getPropertySets()

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




=item $val = $person->addPropertySets(@vals)

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


=item $array_ref = $person->setDescriptions($array_ref)

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


=item $array_ref = $person->getDescriptions()

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




=item $val = $person->addDescriptions(@vals)

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


=item $val = $person->setSecurity($val)

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


=item $val = $person->getSecurity()

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


=item affiliation

Methods for the C<affiliation> association.


From the MAGE-OM documentation:

The organization a person belongs to.


=over


=item $val = $person->setAffiliation($val)

The restricted setter method for the C<affiliation> association.


Input parameters: the value to which the C<affiliation> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<affiliation> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::AuditAndSecurity::Organization>

=cut


sub setAffiliation {
  my $self = shift;
  croak(__PACKAGE__ . "::setAffiliation: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAffiliation: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setAffiliation: wrong type: " . ref($val) . " expected Bio::MAGE::AuditAndSecurity::Organization") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::AuditAndSecurity::Organization');
  return $self->{__AFFILIATION} = $val;
}


=item $val = $person->getAffiliation()

The restricted getter method for the C<affiliation> association.

Input parameters: none

Return value: the current value of the C<affiliation> association : an instance of type C<Bio::MAGE::AuditAndSecurity::Organization>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAffiliation {
  my $self = shift;
  croak(__PACKAGE__ . "::getAffiliation: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__AFFILIATION};
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

