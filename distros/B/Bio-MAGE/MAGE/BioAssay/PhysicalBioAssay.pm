##############################
#
# Bio::MAGE::BioAssay::PhysicalBioAssay
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



package Bio::MAGE::BioAssay::PhysicalBioAssay;
use strict;
use Carp;

use base qw(Bio::MAGE::BioAssay::BioAssay);

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

Bio::MAGE::BioAssay::PhysicalBioAssay - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::BioAssay::PhysicalBioAssay

  # creating an empty instance
  my $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new();

  # creating an instance with existing data
  my $physicalbioassay = Bio::MAGE::BioAssay::PhysicalBioAssay->new(
        name=>$name_val,
        identifier=>$identifier_val,
        channels=>\@channel_list,
        bioAssayCreation=>$bioassaycreation_ref,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        physicalBioAssayData=>\@image_list,
        bioAssayFactorValues=>\@factorvalue_list,
        bioAssayTreatments=>\@bioassaytreatment_list,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'name' attribute
  my $name_val = $physicalbioassay->name(); # getter
  $physicalbioassay->name($value); # setter

  # 'identifier' attribute
  my $identifier_val = $physicalbioassay->identifier(); # getter
  $physicalbioassay->identifier($value); # setter


  # 'channels' association
  my $channel_array_ref = $physicalbioassay->channels(); # getter
  $physicalbioassay->channels(\@channel_list); # setter

  # 'bioAssayCreation' association
  my $bioassaycreation_ref = $physicalbioassay->bioAssayCreation(); # getter
  $physicalbioassay->bioAssayCreation($bioassaycreation_ref); # setter

  # 'auditTrail' association
  my $audit_array_ref = $physicalbioassay->auditTrail(); # getter
  $physicalbioassay->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $physicalbioassay->propertySets(); # getter
  $physicalbioassay->propertySets(\@namevaluetype_list); # setter

  # 'physicalBioAssayData' association
  my $image_array_ref = $physicalbioassay->physicalBioAssayData(); # getter
  $physicalbioassay->physicalBioAssayData(\@image_list); # setter

  # 'bioAssayFactorValues' association
  my $factorvalue_array_ref = $physicalbioassay->bioAssayFactorValues(); # getter
  $physicalbioassay->bioAssayFactorValues(\@factorvalue_list); # setter

  # 'bioAssayTreatments' association
  my $bioassaytreatment_array_ref = $physicalbioassay->bioAssayTreatments(); # getter
  $physicalbioassay->bioAssayTreatments(\@bioassaytreatment_list); # setter

  # 'descriptions' association
  my $description_array_ref = $physicalbioassay->descriptions(); # getter
  $physicalbioassay->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $physicalbioassay->security(); # getter
  $physicalbioassay->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<PhysicalBioAssay> class:

A bioAssay created by the bioAssayCreation event (e.g. in gene expression analysis this event is represented by the hybridization event).



=cut

=head1 INHERITANCE


Bio::MAGE::BioAssay::PhysicalBioAssay has the following superclasses:

=over


=item * Bio::MAGE::BioAssay::BioAssay


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::BioAssay::PhysicalBioAssay];
  $__PACKAGE_NAME      = q[BioAssay];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::BioAssay::BioAssay'];
  $__ATTRIBUTE_NAMES   = ['name', 'identifier'];
  $__ASSOCIATION_NAMES = ['channels', 'auditTrail', 'bioAssayCreation', 'propertySets', 'physicalBioAssayData', 'bioAssayTreatments', 'bioAssayFactorValues', 'descriptions', 'security'];
  $__ASSOCIATIONS      = [
          'physicalBioAssayData',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The Images associated with this PhysicalBioAssay by ImageAcquisition.',
                                        '__CLASS_NAME' => 'PhysicalBioAssay',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'physicalBioAssayData',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The Images associated with this PhysicalBioAssay by ImageAcquisition.',
                                         '__CLASS_NAME' => 'Image',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'bioAssayCreation',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => 'physicalBioAssayTarget',
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                        '__CLASS_NAME' => 'PhysicalBioAssay',
                                        '__RANK' => '3',
                                        '__ORDERED' => 0
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'bioAssayCreation',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.',
                                         '__CLASS_NAME' => 'BioAssayCreation',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'bioAssayTreatments',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => 'physicalBioAssay',
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                        '__CLASS_NAME' => 'PhysicalBioAssay',
                                        '__RANK' => '1',
                                        '__ORDERED' => 0
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'bioAssayTreatments',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The set of treatments undergone by this PhysicalBioAssay.',
                                         '__CLASS_NAME' => 'BioAssayTreatment',
                                         '__RANK' => '3',
                                         '__ORDERED' => 1
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::BioAssay::PhysicalBioAssay->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).



=item * channels

Sets the value of the C<channels> association (this association was inherited from class C<Bio::MAGE::BioAssay::BioAssay>).


The value must be of type: array of C<Bio::MAGE::BioAssay::Channel>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * bioAssayCreation

Sets the value of the C<bioAssayCreation> association

The value must be of type: instance of C<Bio::MAGE::BioAssay::BioAssayCreation>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * physicalBioAssayData

Sets the value of the C<physicalBioAssayData> association

The value must be of type: array of C<Bio::MAGE::BioAssay::Image>.


=item * bioAssayTreatments

Sets the value of the C<bioAssayTreatments> association

The value must be of type: array of C<Bio::MAGE::BioAssay::BioAssayTreatment>.


=item * bioAssayFactorValues

Sets the value of the C<bioAssayFactorValues> association (this association was inherited from class C<Bio::MAGE::BioAssay::BioAssay>).


The value must be of type: array of C<Bio::MAGE::Experiment::FactorValue>.


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

C<Bio::MAGE::BioAssay::PhysicalBioAssay> has the following attribute accessor methods:

=over


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $physicalbioassay->setName($val)

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


=item $val = $physicalbioassay->getName()

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


=item $val = $physicalbioassay->setIdentifier($val)

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


=item $val = $physicalbioassay->getIdentifier()

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

Bio::MAGE::BioAssay::PhysicalBioAssay has the following association accessor methods:

=over


=item channels

Methods for the C<channels> association.


From the MAGE-OM documentation:

Channels can be non-null for all subclasses.  For instance, collapsing across replicate features will create a DerivedBioAssay that will potentially reference channels.


=over


=item $array_ref = $physicalbioassay->setChannels($array_ref)

The restricted setter method for the C<channels> association.


Input parameters: the value to which the C<channels> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Channel>

Return value: the current value of the C<channels> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Channel>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioAssay::Channel> instances

=cut


sub setChannels {
  my $self = shift;
  croak(__PACKAGE__ . "::setChannels: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setChannels: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setChannels: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setChannels: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioAssay::Channel")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioAssay::Channel');
    }
  }

  return $self->{__CHANNELS} = $val;
}


=item $array_ref = $physicalbioassay->getChannels()

The restricted getter method for the C<channels> association.

Input parameters: none

Return value: the current value of the C<channels> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Channel>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getChannels {
  my $self = shift;
  croak(__PACKAGE__ . "::getChannels: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__CHANNELS};
}




=item $val = $physicalbioassay->addChannels(@vals)

Because the channels association has list cardinality, it may store more
than one value. This method adds the current list of objects in the channels association.

Input parameters: the list of values C<@vals> to add to the channels association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioAssay::Channel>

=cut


sub addChannels {
  my $self = shift;
  croak(__PACKAGE__ . "::addChannels: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addChannels: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssay::Channel")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssay::Channel');
  }

  return push(@{$self->{__CHANNELS}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $physicalbioassay->setAuditTrail($array_ref)

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


=item $array_ref = $physicalbioassay->getAuditTrail()

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




=item $val = $physicalbioassay->addAuditTrail(@vals)

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


=item bioAssayCreation

Methods for the C<bioAssayCreation> association.


From the MAGE-OM documentation:

The association between the BioAssayCreation event (typically Hybridization) and the PhysicalBioAssay and its annotation of this event.


=over


=item $val = $physicalbioassay->setBioAssayCreation($val)

The restricted setter method for the C<bioAssayCreation> association.


Input parameters: the value to which the C<bioAssayCreation> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<bioAssayCreation> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::BioAssay::BioAssayCreation>

=cut


sub setBioAssayCreation {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioAssayCreation: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioAssayCreation: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setBioAssayCreation: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssay::BioAssayCreation") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::BioAssay::BioAssayCreation');
  return $self->{__BIOASSAYCREATION} = $val;
}


=item $val = $physicalbioassay->getBioAssayCreation()

The restricted getter method for the C<bioAssayCreation> association.

Input parameters: none

Return value: the current value of the C<bioAssayCreation> association : an instance of type C<Bio::MAGE::BioAssay::BioAssayCreation>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioAssayCreation {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioAssayCreation: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOASSAYCREATION};
}





=back


=item propertySets

Methods for the C<propertySets> association.


From the MAGE-OM documentation:

Allows specification of name/value pairs.  Meant to primarily help in-house, pipeline processing of instances by providing a place for values that aren't part of the specification proper.


=over


=item $array_ref = $physicalbioassay->setPropertySets($array_ref)

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


=item $array_ref = $physicalbioassay->getPropertySets()

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




=item $val = $physicalbioassay->addPropertySets(@vals)

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


=item physicalBioAssayData

Methods for the C<physicalBioAssayData> association.


From the MAGE-OM documentation:

The Images associated with this PhysicalBioAssay by ImageAcquisition.


=over


=item $array_ref = $physicalbioassay->setPhysicalBioAssayData($array_ref)

The restricted setter method for the C<physicalBioAssayData> association.


Input parameters: the value to which the C<physicalBioAssayData> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Image>

Return value: the current value of the C<physicalBioAssayData> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Image>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioAssay::Image> instances

=cut


sub setPhysicalBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::setPhysicalBioAssayData: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPhysicalBioAssayData: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setPhysicalBioAssayData: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setPhysicalBioAssayData: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioAssay::Image")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioAssay::Image');
    }
  }

  return $self->{__PHYSICALBIOASSAYDATA} = $val;
}


=item $array_ref = $physicalbioassay->getPhysicalBioAssayData()

The restricted getter method for the C<physicalBioAssayData> association.

Input parameters: none

Return value: the current value of the C<physicalBioAssayData> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::Image>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPhysicalBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::getPhysicalBioAssayData: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PHYSICALBIOASSAYDATA};
}




=item $val = $physicalbioassay->addPhysicalBioAssayData(@vals)

Because the physicalBioAssayData association has list cardinality, it may store more
than one value. This method adds the current list of objects in the physicalBioAssayData association.

Input parameters: the list of values C<@vals> to add to the physicalBioAssayData association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioAssay::Image>

=cut


sub addPhysicalBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::addPhysicalBioAssayData: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addPhysicalBioAssayData: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssay::Image")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssay::Image');
  }

  return push(@{$self->{__PHYSICALBIOASSAYDATA}},@vals);
}





=back


=item bioAssayTreatments

Methods for the C<bioAssayTreatments> association.


From the MAGE-OM documentation:

The set of treatments undergone by this PhysicalBioAssay.


=over


=item $array_ref = $physicalbioassay->setBioAssayTreatments($array_ref)

The restricted setter method for the C<bioAssayTreatments> association.


Input parameters: the value to which the C<bioAssayTreatments> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssayTreatment>

Return value: the current value of the C<bioAssayTreatments> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssayTreatment>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioAssay::BioAssayTreatment> instances

=cut


sub setBioAssayTreatments {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioAssayTreatments: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioAssayTreatments: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setBioAssayTreatments: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setBioAssayTreatments: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioAssay::BioAssayTreatment")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioAssay::BioAssayTreatment');
    }
  }

  return $self->{__BIOASSAYTREATMENTS} = $val;
}


=item $array_ref = $physicalbioassay->getBioAssayTreatments()

The restricted getter method for the C<bioAssayTreatments> association.

Input parameters: none

Return value: the current value of the C<bioAssayTreatments> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssayTreatment>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioAssayTreatments {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioAssayTreatments: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOASSAYTREATMENTS};
}




=item $val = $physicalbioassay->addBioAssayTreatments(@vals)

Because the bioAssayTreatments association has list cardinality, it may store more
than one value. This method adds the current list of objects in the bioAssayTreatments association.

Input parameters: the list of values C<@vals> to add to the bioAssayTreatments association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioAssay::BioAssayTreatment>

=cut


sub addBioAssayTreatments {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayTreatments: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addBioAssayTreatments: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssay::BioAssayTreatment")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssay::BioAssayTreatment');
  }

  return push(@{$self->{__BIOASSAYTREATMENTS}},@vals);
}





=back


=item bioAssayFactorValues

Methods for the C<bioAssayFactorValues> association.


From the MAGE-OM documentation:

The values that this BioAssay is associated with for the experiment.


=over


=item $array_ref = $physicalbioassay->setBioAssayFactorValues($array_ref)

The restricted setter method for the C<bioAssayFactorValues> association.


Input parameters: the value to which the C<bioAssayFactorValues> association will be set : a reference to an array of objects of type C<Bio::MAGE::Experiment::FactorValue>

Return value: the current value of the C<bioAssayFactorValues> association : a reference to an array of objects of type C<Bio::MAGE::Experiment::FactorValue>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Experiment::FactorValue> instances

=cut


sub setBioAssayFactorValues {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioAssayFactorValues: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioAssayFactorValues: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setBioAssayFactorValues: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setBioAssayFactorValues: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Experiment::FactorValue")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Experiment::FactorValue');
    }
  }

  return $self->{__BIOASSAYFACTORVALUES} = $val;
}


=item $array_ref = $physicalbioassay->getBioAssayFactorValues()

The restricted getter method for the C<bioAssayFactorValues> association.

Input parameters: none

Return value: the current value of the C<bioAssayFactorValues> association : a reference to an array of objects of type C<Bio::MAGE::Experiment::FactorValue>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioAssayFactorValues {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioAssayFactorValues: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOASSAYFACTORVALUES};
}




=item $val = $physicalbioassay->addBioAssayFactorValues(@vals)

Because the bioAssayFactorValues association has list cardinality, it may store more
than one value. This method adds the current list of objects in the bioAssayFactorValues association.

Input parameters: the list of values C<@vals> to add to the bioAssayFactorValues association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Experiment::FactorValue>

=cut


sub addBioAssayFactorValues {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayFactorValues: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addBioAssayFactorValues: wrong type: " . ref($val) . " expected Bio::MAGE::Experiment::FactorValue")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Experiment::FactorValue');
  }

  return push(@{$self->{__BIOASSAYFACTORVALUES}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $physicalbioassay->setDescriptions($array_ref)

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


=item $array_ref = $physicalbioassay->getDescriptions()

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




=item $val = $physicalbioassay->addDescriptions(@vals)

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


=item $val = $physicalbioassay->setSecurity($val)

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


=item $val = $physicalbioassay->getSecurity()

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

