##############################
#
# Bio::MAGE::Description::Description
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



package Bio::MAGE::Description::Description;
use strict;
use Carp;

use base qw(Bio::MAGE::Describable);

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

Bio::MAGE::Description::Description - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::Description::Description

  # creating an empty instance
  my $description = Bio::MAGE::Description::Description->new();

  # creating an instance with existing data
  my $description = Bio::MAGE::Description::Description->new(
        URI=>$uri_val,
        text=>$text_val,
        databaseReferences=>\@databaseentry_list,
        externalReference=>$externalreference_ref,
        bibliographicReferences=>\@bibliographicreference_list,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        annotations=>\@ontologyentry_list,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'URI' attribute
  my $URI_val = $description->URI(); # getter
  $description->URI($value); # setter

  # 'text' attribute
  my $text_val = $description->text(); # getter
  $description->text($value); # setter


  # 'databaseReferences' association
  my $databaseentry_array_ref = $description->databaseReferences(); # getter
  $description->databaseReferences(\@databaseentry_list); # setter

  # 'externalReference' association
  my $externalreference_ref = $description->externalReference(); # getter
  $description->externalReference($externalreference_ref); # setter

  # 'bibliographicReferences' association
  my $bibliographicreference_array_ref = $description->bibliographicReferences(); # getter
  $description->bibliographicReferences(\@bibliographicreference_list); # setter

  # 'auditTrail' association
  my $audit_array_ref = $description->auditTrail(); # getter
  $description->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $description->propertySets(); # getter
  $description->propertySets(\@namevaluetype_list); # setter

  # 'annotations' association
  my $ontologyentry_array_ref = $description->annotations(); # getter
  $description->annotations(\@ontologyentry_list); # setter

  # 'descriptions' association
  my $description_array_ref = $description->descriptions(); # getter
  $description->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $description->security(); # getter
  $description->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<Description> class:

A free text description of an object.



=cut

=head1 INHERITANCE


Bio::MAGE::Description::Description has the following superclasses:

=over


=item * Bio::MAGE::Describable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::Description::Description];
  $__PACKAGE_NAME      = q[Description];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Describable'];
  $__ATTRIBUTE_NAMES   = ['URI', 'text'];
  $__ASSOCIATION_NAMES = ['databaseReferences', 'externalReference', 'bibliographicReferences', 'auditTrail', 'propertySets', 'annotations', 'descriptions', 'security'];
  $__ASSOCIATIONS      = [
          'externalReference',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Specifies where the described instance was originally obtained from.',
                                        '__CLASS_NAME' => 'Description',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'externalReference',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'Specifies where the described instance was originally obtained from.',
                                         '__CLASS_NAME' => 'ExternalReference',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'annotations',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Allows specification of ontology entries related to the instance being described.',
                                        '__CLASS_NAME' => 'Description',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'annotations',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Allows specification of ontology entries related to the instance being described.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'databaseReferences',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'References to entries in databases.',
                                        '__CLASS_NAME' => 'Description',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'databaseReferences',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'References to entries in databases.',
                                         '__CLASS_NAME' => 'DatabaseEntry',
                                         '__RANK' => '3',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'bibliographicReferences',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'References to existing literature.',
                                        '__CLASS_NAME' => 'Description',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'bibliographicReferences',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'References to existing literature.',
                                         '__CLASS_NAME' => 'BibliographicReference',
                                         '__RANK' => '4',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::Description::Description->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * URI

Sets the value of the C<URI> attribute

=item * text

Sets the value of the C<text> attribute


=item * databaseReferences

Sets the value of the C<databaseReferences> association

The value must be of type: array of C<Bio::MAGE::Description::DatabaseEntry>.


=item * externalReference

Sets the value of the C<externalReference> association

The value must be of type: instance of C<Bio::MAGE::Description::ExternalReference>.


=item * bibliographicReferences

Sets the value of the C<bibliographicReferences> association

The value must be of type: array of C<Bio::MAGE::BQS::BibliographicReference>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * annotations

Sets the value of the C<annotations> association

The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


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

C<Bio::MAGE::Description::Description> has the following attribute accessor methods:

=over


=item URI

Methods for the C<URI> attribute.


From the MAGE-OM documentation:

A reference to the location and type of an outside resource.


=over


=item $val = $description->setURI($val)

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


=item $val = $description->getURI()

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


=item text

Methods for the C<text> attribute.


From the MAGE-OM documentation:

The description.


=over


=item $val = $description->setText($val)

The restricted setter method for the C<text> attribute.


Input parameters: the value to which the C<text> attribute will be set 

Return value: the current value of the C<text> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setText {
  my $self = shift;
  croak(__PACKAGE__ . "::setText: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setText: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__TEXT} = $val;
}


=item $val = $description->getText()

The restricted getter method for the C<text> attribute.

Input parameters: none

Return value: the current value of the C<text> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getText {
  my $self = shift;
  croak(__PACKAGE__ . "::getText: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TEXT};
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

Bio::MAGE::Description::Description has the following association accessor methods:

=over


=item databaseReferences

Methods for the C<databaseReferences> association.


From the MAGE-OM documentation:

References to entries in databases.


=over


=item $array_ref = $description->setDatabaseReferences($array_ref)

The restricted setter method for the C<databaseReferences> association.


Input parameters: the value to which the C<databaseReferences> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Return value: the current value of the C<databaseReferences> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::DatabaseEntry> instances

=cut


sub setDatabaseReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::setDatabaseReferences: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setDatabaseReferences: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setDatabaseReferences: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setDatabaseReferences: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::DatabaseEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::DatabaseEntry');
    }
  }

  return $self->{__DATABASEREFERENCES} = $val;
}


=item $array_ref = $description->getDatabaseReferences()

The restricted getter method for the C<databaseReferences> association.

Input parameters: none

Return value: the current value of the C<databaseReferences> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getDatabaseReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::getDatabaseReferences: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__DATABASEREFERENCES};
}




=item $val = $description->addDatabaseReferences(@vals)

Because the databaseReferences association has list cardinality, it may store more
than one value. This method adds the current list of objects in the databaseReferences association.

Input parameters: the list of values C<@vals> to add to the databaseReferences association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::DatabaseEntry>

=cut


sub addDatabaseReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::addDatabaseReferences: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addDatabaseReferences: wrong type: " . ref($val) . " expected Bio::MAGE::Description::DatabaseEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::DatabaseEntry');
  }

  return push(@{$self->{__DATABASEREFERENCES}},@vals);
}





=back


=item externalReference

Methods for the C<externalReference> association.


From the MAGE-OM documentation:

Specifies where the described instance was originally obtained from.


=over


=item $val = $description->setExternalReference($val)

The restricted setter method for the C<externalReference> association.


Input parameters: the value to which the C<externalReference> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<externalReference> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::ExternalReference>

=cut


sub setExternalReference {
  my $self = shift;
  croak(__PACKAGE__ . "::setExternalReference: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setExternalReference: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setExternalReference: wrong type: " . ref($val) . " expected Bio::MAGE::Description::ExternalReference") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::ExternalReference');
  return $self->{__EXTERNALREFERENCE} = $val;
}


=item $val = $description->getExternalReference()

The restricted getter method for the C<externalReference> association.

Input parameters: none

Return value: the current value of the C<externalReference> association : an instance of type C<Bio::MAGE::Description::ExternalReference>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getExternalReference {
  my $self = shift;
  croak(__PACKAGE__ . "::getExternalReference: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__EXTERNALREFERENCE};
}





=back


=item bibliographicReferences

Methods for the C<bibliographicReferences> association.


From the MAGE-OM documentation:

References to existing literature.


=over


=item $array_ref = $description->setBibliographicReferences($array_ref)

The restricted setter method for the C<bibliographicReferences> association.


Input parameters: the value to which the C<bibliographicReferences> association will be set : a reference to an array of objects of type C<Bio::MAGE::BQS::BibliographicReference>

Return value: the current value of the C<bibliographicReferences> association : a reference to an array of objects of type C<Bio::MAGE::BQS::BibliographicReference>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BQS::BibliographicReference> instances

=cut


sub setBibliographicReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::setBibliographicReferences: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBibliographicReferences: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setBibliographicReferences: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setBibliographicReferences: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BQS::BibliographicReference")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BQS::BibliographicReference');
    }
  }

  return $self->{__BIBLIOGRAPHICREFERENCES} = $val;
}


=item $array_ref = $description->getBibliographicReferences()

The restricted getter method for the C<bibliographicReferences> association.

Input parameters: none

Return value: the current value of the C<bibliographicReferences> association : a reference to an array of objects of type C<Bio::MAGE::BQS::BibliographicReference>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBibliographicReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::getBibliographicReferences: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIBLIOGRAPHICREFERENCES};
}




=item $val = $description->addBibliographicReferences(@vals)

Because the bibliographicReferences association has list cardinality, it may store more
than one value. This method adds the current list of objects in the bibliographicReferences association.

Input parameters: the list of values C<@vals> to add to the bibliographicReferences association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BQS::BibliographicReference>

=cut


sub addBibliographicReferences {
  my $self = shift;
  croak(__PACKAGE__ . "::addBibliographicReferences: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addBibliographicReferences: wrong type: " . ref($val) . " expected Bio::MAGE::BQS::BibliographicReference")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BQS::BibliographicReference');
  }

  return push(@{$self->{__BIBLIOGRAPHICREFERENCES}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $description->setAuditTrail($array_ref)

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


=item $array_ref = $description->getAuditTrail()

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




=item $val = $description->addAuditTrail(@vals)

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


=item $array_ref = $description->setPropertySets($array_ref)

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


=item $array_ref = $description->getPropertySets()

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




=item $val = $description->addPropertySets(@vals)

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


=item annotations

Methods for the C<annotations> association.


From the MAGE-OM documentation:

Allows specification of ontology entries related to the instance being described.


=over


=item $array_ref = $description->setAnnotations($array_ref)

The restricted setter method for the C<annotations> association.


Input parameters: the value to which the C<annotations> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<annotations> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setAnnotations {
  my $self = shift;
  croak(__PACKAGE__ . "::setAnnotations: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAnnotations: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setAnnotations: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setAnnotations: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__ANNOTATIONS} = $val;
}


=item $array_ref = $description->getAnnotations()

The restricted getter method for the C<annotations> association.

Input parameters: none

Return value: the current value of the C<annotations> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAnnotations {
  my $self = shift;
  croak(__PACKAGE__ . "::getAnnotations: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ANNOTATIONS};
}




=item $val = $description->addAnnotations(@vals)

Because the annotations association has list cardinality, it may store more
than one value. This method adds the current list of objects in the annotations association.

Input parameters: the list of values C<@vals> to add to the annotations association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addAnnotations {
  my $self = shift;
  croak(__PACKAGE__ . "::addAnnotations: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addAnnotations: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__ANNOTATIONS}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $description->setDescriptions($array_ref)

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


=item $array_ref = $description->getDescriptions()

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




=item $val = $description->addDescriptions(@vals)

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


=item $val = $description->setSecurity($val)

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


=item $val = $description->getSecurity()

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

