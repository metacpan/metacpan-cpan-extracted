##############################
#
# Bio::MAGE::ArrayDesign::PhysicalArrayDesign
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



package Bio::MAGE::ArrayDesign::PhysicalArrayDesign;
use strict;
use Carp;

use base qw(Bio::MAGE::ArrayDesign::ArrayDesign);

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

Bio::MAGE::ArrayDesign::PhysicalArrayDesign - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::ArrayDesign::PhysicalArrayDesign

  # creating an empty instance
  my $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new();

  # creating an instance with existing data
  my $physicalarraydesign = Bio::MAGE::ArrayDesign::PhysicalArrayDesign->new(
        numberOfFeatures=>$numberoffeatures_val,
        version=>$version_val,
        name=>$name_val,
        identifier=>$identifier_val,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        surfaceType=>$ontologyentry_ref,
        designProviders=>\@contact_list,
        protocolApplications=>\@protocolapplication_list,
        reporterGroups=>\@reportergroup_list,
        zoneGroups=>\@zonegroup_list,
        featureGroups=>\@featuregroup_list,
        descriptions=>\@description_list,
        security=>$security_ref,
        compositeGroups=>\@compositegroup_list,
  );


  # 'numberOfFeatures' attribute
  my $numberOfFeatures_val = $physicalarraydesign->numberOfFeatures(); # getter
  $physicalarraydesign->numberOfFeatures($value); # setter

  # 'version' attribute
  my $version_val = $physicalarraydesign->version(); # getter
  $physicalarraydesign->version($value); # setter

  # 'name' attribute
  my $name_val = $physicalarraydesign->name(); # getter
  $physicalarraydesign->name($value); # setter

  # 'identifier' attribute
  my $identifier_val = $physicalarraydesign->identifier(); # getter
  $physicalarraydesign->identifier($value); # setter


  # 'auditTrail' association
  my $audit_array_ref = $physicalarraydesign->auditTrail(); # getter
  $physicalarraydesign->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $physicalarraydesign->propertySets(); # getter
  $physicalarraydesign->propertySets(\@namevaluetype_list); # setter

  # 'surfaceType' association
  my $ontologyentry_ref = $physicalarraydesign->surfaceType(); # getter
  $physicalarraydesign->surfaceType($ontologyentry_ref); # setter

  # 'designProviders' association
  my $contact_array_ref = $physicalarraydesign->designProviders(); # getter
  $physicalarraydesign->designProviders(\@contact_list); # setter

  # 'protocolApplications' association
  my $protocolapplication_array_ref = $physicalarraydesign->protocolApplications(); # getter
  $physicalarraydesign->protocolApplications(\@protocolapplication_list); # setter

  # 'reporterGroups' association
  my $reportergroup_array_ref = $physicalarraydesign->reporterGroups(); # getter
  $physicalarraydesign->reporterGroups(\@reportergroup_list); # setter

  # 'zoneGroups' association
  my $zonegroup_array_ref = $physicalarraydesign->zoneGroups(); # getter
  $physicalarraydesign->zoneGroups(\@zonegroup_list); # setter

  # 'featureGroups' association
  my $featuregroup_array_ref = $physicalarraydesign->featureGroups(); # getter
  $physicalarraydesign->featureGroups(\@featuregroup_list); # setter

  # 'descriptions' association
  my $description_array_ref = $physicalarraydesign->descriptions(); # getter
  $physicalarraydesign->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $physicalarraydesign->security(); # getter
  $physicalarraydesign->security($security_ref); # setter

  # 'compositeGroups' association
  my $compositegroup_array_ref = $physicalarraydesign->compositeGroups(); # getter
  $physicalarraydesign->compositeGroups(\@compositegroup_list); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<PhysicalArrayDesign> class:

A design that is expected to be used to manufacture physical arrays.



=cut

=head1 INHERITANCE


Bio::MAGE::ArrayDesign::PhysicalArrayDesign has the following superclasses:

=over


=item * Bio::MAGE::ArrayDesign::ArrayDesign


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::ArrayDesign::PhysicalArrayDesign];
  $__PACKAGE_NAME      = q[ArrayDesign];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::ArrayDesign::ArrayDesign'];
  $__ATTRIBUTE_NAMES   = ['numberOfFeatures', 'version', 'name', 'identifier'];
  $__ASSOCIATION_NAMES = ['auditTrail', 'propertySets', 'surfaceType', 'designProviders', 'reporterGroups', 'protocolApplications', 'zoneGroups', 'descriptions', 'featureGroups', 'security', 'compositeGroups'];
  $__ASSOCIATIONS      = [
          'surfaceType',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The type of surface from a controlled vocabulary that would include terms such as non-absorptive, absorptive, etc.',
                                        '__CLASS_NAME' => 'PhysicalArrayDesign',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'surfaceType',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The type of surface from a controlled vocabulary that would include terms such as non-absorptive, absorptive, etc.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'zoneGroups',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'In the case where the array design is specified by one or more zones, allows specifying where those zones are located.',
                                        '__CLASS_NAME' => 'PhysicalArrayDesign',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'zoneGroups',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'In the case where the array design is specified by one or more zones, allows specifying where those zones are located.',
                                         '__CLASS_NAME' => 'ZoneGroup',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::ArrayDesign::PhysicalArrayDesign->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * numberOfFeatures

Sets the value of the C<numberOfFeatures> attribute (this attribute was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


=item * version

Sets the value of the C<version> attribute (this attribute was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).



=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * surfaceType

Sets the value of the C<surfaceType> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * designProviders

Sets the value of the C<designProviders> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Contact>.


=item * reporterGroups

Sets the value of the C<reporterGroups> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


The value must be of type: array of C<Bio::MAGE::ArrayDesign::ReporterGroup>.


=item * protocolApplications

Sets the value of the C<protocolApplications> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


The value must be of type: array of C<Bio::MAGE::Protocol::ProtocolApplication>.


=item * zoneGroups

Sets the value of the C<zoneGroups> association

The value must be of type: array of C<Bio::MAGE::ArrayDesign::ZoneGroup>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * featureGroups

Sets the value of the C<featureGroups> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


The value must be of type: array of C<Bio::MAGE::ArrayDesign::FeatureGroup>.


=item * security

Sets the value of the C<security> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Security>.


=item * compositeGroups

Sets the value of the C<compositeGroups> association (this association was inherited from class C<Bio::MAGE::ArrayDesign::ArrayDesign>).


The value must be of type: array of C<Bio::MAGE::ArrayDesign::CompositeGroup>.


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

C<Bio::MAGE::ArrayDesign::PhysicalArrayDesign> has the following attribute accessor methods:

=over


=item numberOfFeatures

Methods for the C<numberOfFeatures> attribute.


From the MAGE-OM documentation:

The number of features for this array


=over


=item $val = $physicalarraydesign->setNumberOfFeatures($val)

The restricted setter method for the C<numberOfFeatures> attribute.


Input parameters: the value to which the C<numberOfFeatures> attribute will be set 

Return value: the current value of the C<numberOfFeatures> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setNumberOfFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::setNumberOfFeatures: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setNumberOfFeatures: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__NUMBEROFFEATURES} = $val;
}


=item $val = $physicalarraydesign->getNumberOfFeatures()

The restricted getter method for the C<numberOfFeatures> attribute.

Input parameters: none

Return value: the current value of the C<numberOfFeatures> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getNumberOfFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::getNumberOfFeatures: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__NUMBEROFFEATURES};
}





=back


=item version

Methods for the C<version> attribute.


From the MAGE-OM documentation:

The version of this design.


=over


=item $val = $physicalarraydesign->setVersion($val)

The restricted setter method for the C<version> attribute.


Input parameters: the value to which the C<version> attribute will be set 

Return value: the current value of the C<version> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setVersion {
  my $self = shift;
  croak(__PACKAGE__ . "::setVersion: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setVersion: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__VERSION} = $val;
}


=item $val = $physicalarraydesign->getVersion()

The restricted getter method for the C<version> attribute.

Input parameters: none

Return value: the current value of the C<version> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getVersion {
  my $self = shift;
  croak(__PACKAGE__ . "::getVersion: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__VERSION};
}





=back


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $physicalarraydesign->setName($val)

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


=item $val = $physicalarraydesign->getName()

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


=item $val = $physicalarraydesign->setIdentifier($val)

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


=item $val = $physicalarraydesign->getIdentifier()

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

Bio::MAGE::ArrayDesign::PhysicalArrayDesign has the following association accessor methods:

=over


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $physicalarraydesign->setAuditTrail($array_ref)

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


=item $array_ref = $physicalarraydesign->getAuditTrail()

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




=item $val = $physicalarraydesign->addAuditTrail(@vals)

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


=item $array_ref = $physicalarraydesign->setPropertySets($array_ref)

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


=item $array_ref = $physicalarraydesign->getPropertySets()

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




=item $val = $physicalarraydesign->addPropertySets(@vals)

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


=item surfaceType

Methods for the C<surfaceType> association.


From the MAGE-OM documentation:

The type of surface from a controlled vocabulary that would include terms such as non-absorptive, absorptive, etc.


=over


=item $val = $physicalarraydesign->setSurfaceType($val)

The restricted setter method for the C<surfaceType> association.


Input parameters: the value to which the C<surfaceType> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<surfaceType> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setSurfaceType {
  my $self = shift;
  croak(__PACKAGE__ . "::setSurfaceType: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSurfaceType: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setSurfaceType: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__SURFACETYPE} = $val;
}


=item $val = $physicalarraydesign->getSurfaceType()

The restricted getter method for the C<surfaceType> association.

Input parameters: none

Return value: the current value of the C<surfaceType> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSurfaceType {
  my $self = shift;
  croak(__PACKAGE__ . "::getSurfaceType: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SURFACETYPE};
}





=back


=item designProviders

Methods for the C<designProviders> association.


From the MAGE-OM documentation:

The primary contact for information on the array design


=over


=item $array_ref = $physicalarraydesign->setDesignProviders($array_ref)

The restricted setter method for the C<designProviders> association.


Input parameters: the value to which the C<designProviders> association will be set : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Return value: the current value of the C<designProviders> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::AuditAndSecurity::Contact> instances

=cut


sub setDesignProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::setDesignProviders: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setDesignProviders: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setDesignProviders: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setDesignProviders: wrong type: " . ref($val_ent) . " expected Bio::MAGE::AuditAndSecurity::Contact")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::AuditAndSecurity::Contact');
    }
  }

  return $self->{__DESIGNPROVIDERS} = $val;
}


=item $array_ref = $physicalarraydesign->getDesignProviders()

The restricted getter method for the C<designProviders> association.

Input parameters: none

Return value: the current value of the C<designProviders> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getDesignProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::getDesignProviders: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__DESIGNPROVIDERS};
}




=item $val = $physicalarraydesign->addDesignProviders(@vals)

Because the designProviders association has list cardinality, it may store more
than one value. This method adds the current list of objects in the designProviders association.

Input parameters: the list of values C<@vals> to add to the designProviders association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::AuditAndSecurity::Contact>

=cut


sub addDesignProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::addDesignProviders: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addDesignProviders: wrong type: " . ref($val) . " expected Bio::MAGE::AuditAndSecurity::Contact")
      unless UNIVERSAL::isa($val,'Bio::MAGE::AuditAndSecurity::Contact');
  }

  return push(@{$self->{__DESIGNPROVIDERS}},@vals);
}





=back


=item reporterGroups

Methods for the C<reporterGroups> association.


From the MAGE-OM documentation:

The grouping of like Reporter together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple ReporterGroups to segregate the technology types.


=over


=item $array_ref = $physicalarraydesign->setReporterGroups($array_ref)

The restricted setter method for the C<reporterGroups> association.


Input parameters: the value to which the C<reporterGroups> association will be set : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ReporterGroup>

Return value: the current value of the C<reporterGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ReporterGroup>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::ArrayDesign::ReporterGroup> instances

=cut


sub setReporterGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::setReporterGroups: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setReporterGroups: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setReporterGroups: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setReporterGroups: wrong type: " . ref($val_ent) . " expected Bio::MAGE::ArrayDesign::ReporterGroup")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::ArrayDesign::ReporterGroup');
    }
  }

  return $self->{__REPORTERGROUPS} = $val;
}


=item $array_ref = $physicalarraydesign->getReporterGroups()

The restricted getter method for the C<reporterGroups> association.

Input parameters: none

Return value: the current value of the C<reporterGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ReporterGroup>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getReporterGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::getReporterGroups: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__REPORTERGROUPS};
}




=item $val = $physicalarraydesign->addReporterGroups(@vals)

Because the reporterGroups association has list cardinality, it may store more
than one value. This method adds the current list of objects in the reporterGroups association.

Input parameters: the list of values C<@vals> to add to the reporterGroups association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::ArrayDesign::ReporterGroup>

=cut


sub addReporterGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::addReporterGroups: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addReporterGroups: wrong type: " . ref($val) . " expected Bio::MAGE::ArrayDesign::ReporterGroup")
      unless UNIVERSAL::isa($val,'Bio::MAGE::ArrayDesign::ReporterGroup');
  }

  return push(@{$self->{__REPORTERGROUPS}},@vals);
}





=back


=item protocolApplications

Methods for the C<protocolApplications> association.


From the MAGE-OM documentation:

Describes the application of any protocols, such as the methodology used to pick oligos, in the design of the array.


=over


=item $array_ref = $physicalarraydesign->setProtocolApplications($array_ref)

The restricted setter method for the C<protocolApplications> association.


Input parameters: the value to which the C<protocolApplications> association will be set : a reference to an array of objects of type C<Bio::MAGE::Protocol::ProtocolApplication>

Return value: the current value of the C<protocolApplications> association : a reference to an array of objects of type C<Bio::MAGE::Protocol::ProtocolApplication>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Protocol::ProtocolApplication> instances

=cut


sub setProtocolApplications {
  my $self = shift;
  croak(__PACKAGE__ . "::setProtocolApplications: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setProtocolApplications: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setProtocolApplications: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setProtocolApplications: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Protocol::ProtocolApplication")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Protocol::ProtocolApplication');
    }
  }

  return $self->{__PROTOCOLAPPLICATIONS} = $val;
}


=item $array_ref = $physicalarraydesign->getProtocolApplications()

The restricted getter method for the C<protocolApplications> association.

Input parameters: none

Return value: the current value of the C<protocolApplications> association : a reference to an array of objects of type C<Bio::MAGE::Protocol::ProtocolApplication>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getProtocolApplications {
  my $self = shift;
  croak(__PACKAGE__ . "::getProtocolApplications: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PROTOCOLAPPLICATIONS};
}




=item $val = $physicalarraydesign->addProtocolApplications(@vals)

Because the protocolApplications association has list cardinality, it may store more
than one value. This method adds the current list of objects in the protocolApplications association.

Input parameters: the list of values C<@vals> to add to the protocolApplications association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Protocol::ProtocolApplication>

=cut


sub addProtocolApplications {
  my $self = shift;
  croak(__PACKAGE__ . "::addProtocolApplications: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addProtocolApplications: wrong type: " . ref($val) . " expected Bio::MAGE::Protocol::ProtocolApplication")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Protocol::ProtocolApplication');
  }

  return push(@{$self->{__PROTOCOLAPPLICATIONS}},@vals);
}





=back


=item zoneGroups

Methods for the C<zoneGroups> association.


From the MAGE-OM documentation:

In the case where the array design is specified by one or more zones, allows specifying where those zones are located.


=over


=item $array_ref = $physicalarraydesign->setZoneGroups($array_ref)

The restricted setter method for the C<zoneGroups> association.


Input parameters: the value to which the C<zoneGroups> association will be set : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ZoneGroup>

Return value: the current value of the C<zoneGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ZoneGroup>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::ArrayDesign::ZoneGroup> instances

=cut


sub setZoneGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::setZoneGroups: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setZoneGroups: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setZoneGroups: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setZoneGroups: wrong type: " . ref($val_ent) . " expected Bio::MAGE::ArrayDesign::ZoneGroup")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::ArrayDesign::ZoneGroup');
    }
  }

  return $self->{__ZONEGROUPS} = $val;
}


=item $array_ref = $physicalarraydesign->getZoneGroups()

The restricted getter method for the C<zoneGroups> association.

Input parameters: none

Return value: the current value of the C<zoneGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::ZoneGroup>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getZoneGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::getZoneGroups: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ZONEGROUPS};
}




=item $val = $physicalarraydesign->addZoneGroups(@vals)

Because the zoneGroups association has list cardinality, it may store more
than one value. This method adds the current list of objects in the zoneGroups association.

Input parameters: the list of values C<@vals> to add to the zoneGroups association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::ArrayDesign::ZoneGroup>

=cut


sub addZoneGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::addZoneGroups: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addZoneGroups: wrong type: " . ref($val) . " expected Bio::MAGE::ArrayDesign::ZoneGroup")
      unless UNIVERSAL::isa($val,'Bio::MAGE::ArrayDesign::ZoneGroup');
  }

  return push(@{$self->{__ZONEGROUPS}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $physicalarraydesign->setDescriptions($array_ref)

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


=item $array_ref = $physicalarraydesign->getDescriptions()

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




=item $val = $physicalarraydesign->addDescriptions(@vals)

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


=item featureGroups

Methods for the C<featureGroups> association.


From the MAGE-OM documentation:

The grouping of like Features together.  Typically for a physical array design, this will be a single grouping of features whose type might be PCR Product or Oligo.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple FeatureGroups to segregate the technology types.


=over


=item $array_ref = $physicalarraydesign->setFeatureGroups($array_ref)

The restricted setter method for the C<featureGroups> association.


Input parameters: the value to which the C<featureGroups> association will be set : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::FeatureGroup>

Return value: the current value of the C<featureGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::FeatureGroup>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::ArrayDesign::FeatureGroup> instances

=cut


sub setFeatureGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::setFeatureGroups: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setFeatureGroups: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setFeatureGroups: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setFeatureGroups: wrong type: " . ref($val_ent) . " expected Bio::MAGE::ArrayDesign::FeatureGroup")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::ArrayDesign::FeatureGroup');
    }
  }

  return $self->{__FEATUREGROUPS} = $val;
}


=item $array_ref = $physicalarraydesign->getFeatureGroups()

The restricted getter method for the C<featureGroups> association.

Input parameters: none

Return value: the current value of the C<featureGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::FeatureGroup>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getFeatureGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::getFeatureGroups: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__FEATUREGROUPS};
}




=item $val = $physicalarraydesign->addFeatureGroups(@vals)

Because the featureGroups association has list cardinality, it may store more
than one value. This method adds the current list of objects in the featureGroups association.

Input parameters: the list of values C<@vals> to add to the featureGroups association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::ArrayDesign::FeatureGroup>

=cut


sub addFeatureGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::addFeatureGroups: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addFeatureGroups: wrong type: " . ref($val) . " expected Bio::MAGE::ArrayDesign::FeatureGroup")
      unless UNIVERSAL::isa($val,'Bio::MAGE::ArrayDesign::FeatureGroup');
  }

  return push(@{$self->{__FEATUREGROUPS}},@vals);
}





=back


=item security

Methods for the C<security> association.


From the MAGE-OM documentation:

Information on the security for the instance of the class.


=over


=item $val = $physicalarraydesign->setSecurity($val)

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


=item $val = $physicalarraydesign->getSecurity()

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


=item compositeGroups

Methods for the C<compositeGroups> association.


From the MAGE-OM documentation:

The grouping of like CompositeSequence together.  If more than one technology type occurs on the array, such as the mixing of Cloned BioMaterial and Oligos, then there would be multiple CompositeGroups to segregate the technology types.


=over


=item $array_ref = $physicalarraydesign->setCompositeGroups($array_ref)

The restricted setter method for the C<compositeGroups> association.


Input parameters: the value to which the C<compositeGroups> association will be set : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::CompositeGroup>

Return value: the current value of the C<compositeGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::CompositeGroup>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::ArrayDesign::CompositeGroup> instances

=cut


sub setCompositeGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::setCompositeGroups: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setCompositeGroups: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setCompositeGroups: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setCompositeGroups: wrong type: " . ref($val_ent) . " expected Bio::MAGE::ArrayDesign::CompositeGroup")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::ArrayDesign::CompositeGroup');
    }
  }

  return $self->{__COMPOSITEGROUPS} = $val;
}


=item $array_ref = $physicalarraydesign->getCompositeGroups()

The restricted getter method for the C<compositeGroups> association.

Input parameters: none

Return value: the current value of the C<compositeGroups> association : a reference to an array of objects of type C<Bio::MAGE::ArrayDesign::CompositeGroup>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getCompositeGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::getCompositeGroups: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__COMPOSITEGROUPS};
}




=item $val = $physicalarraydesign->addCompositeGroups(@vals)

Because the compositeGroups association has list cardinality, it may store more
than one value. This method adds the current list of objects in the compositeGroups association.

Input parameters: the list of values C<@vals> to add to the compositeGroups association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::ArrayDesign::CompositeGroup>

=cut


sub addCompositeGroups {
  my $self = shift;
  croak(__PACKAGE__ . "::addCompositeGroups: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addCompositeGroups: wrong type: " . ref($val) . " expected Bio::MAGE::ArrayDesign::CompositeGroup")
      unless UNIVERSAL::isa($val,'Bio::MAGE::ArrayDesign::CompositeGroup');
  }

  return push(@{$self->{__COMPOSITEGROUPS}},@vals);
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

