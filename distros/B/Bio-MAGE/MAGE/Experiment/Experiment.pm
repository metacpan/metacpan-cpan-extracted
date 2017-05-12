##############################
#
# Bio::MAGE::Experiment::Experiment
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



package Bio::MAGE::Experiment::Experiment;
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

Bio::MAGE::Experiment::Experiment - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::Experiment::Experiment

  # creating an empty instance
  my $experiment = Bio::MAGE::Experiment::Experiment->new();

  # creating an instance with existing data
  my $experiment = Bio::MAGE::Experiment::Experiment->new(
        name=>$name_val,
        identifier=>$identifier_val,
        experimentDesigns=>\@experimentdesign_list,
        providers=>\@contact_list,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        analysisResults=>\@bioassaydatacluster_list,
        bioAssays=>\@bioassay_list,
        descriptions=>\@description_list,
        bioAssayData=>\@bioassaydata_list,
        security=>$security_ref,
  );


  # 'name' attribute
  my $name_val = $experiment->name(); # getter
  $experiment->name($value); # setter

  # 'identifier' attribute
  my $identifier_val = $experiment->identifier(); # getter
  $experiment->identifier($value); # setter


  # 'experimentDesigns' association
  my $experimentdesign_array_ref = $experiment->experimentDesigns(); # getter
  $experiment->experimentDesigns(\@experimentdesign_list); # setter

  # 'providers' association
  my $contact_array_ref = $experiment->providers(); # getter
  $experiment->providers(\@contact_list); # setter

  # 'auditTrail' association
  my $audit_array_ref = $experiment->auditTrail(); # getter
  $experiment->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $experiment->propertySets(); # getter
  $experiment->propertySets(\@namevaluetype_list); # setter

  # 'analysisResults' association
  my $bioassaydatacluster_array_ref = $experiment->analysisResults(); # getter
  $experiment->analysisResults(\@bioassaydatacluster_list); # setter

  # 'bioAssays' association
  my $bioassay_array_ref = $experiment->bioAssays(); # getter
  $experiment->bioAssays(\@bioassay_list); # setter

  # 'descriptions' association
  my $description_array_ref = $experiment->descriptions(); # getter
  $experiment->descriptions(\@description_list); # setter

  # 'bioAssayData' association
  my $bioassaydata_array_ref = $experiment->bioAssayData(); # getter
  $experiment->bioAssayData(\@bioassaydata_list); # setter

  # 'security' association
  my $security_ref = $experiment->security(); # getter
  $experiment->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<Experiment> class:

The Experiment is the collection of all the BioAssays that are related by the ExperimentDesign.



=cut

=head1 INHERITANCE


Bio::MAGE::Experiment::Experiment has the following superclasses:

=over


=item * Bio::MAGE::Identifiable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::Experiment::Experiment];
  $__PACKAGE_NAME      = q[Experiment];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Identifiable'];
  $__ATTRIBUTE_NAMES   = ['name', 'identifier'];
  $__ASSOCIATION_NAMES = ['experimentDesigns', 'providers', 'auditTrail', 'propertySets', 'analysisResults', 'bioAssays', 'bioAssayData', 'descriptions', 'security'];
  $__ASSOCIATIONS      = [
          'providers',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 1,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'The providers of the Experiment, its data and annotation.',
                                        '__CLASS_NAME' => 'Experiment',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'providers',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The providers of the Experiment, its data and annotation.',
                                         '__CLASS_NAME' => 'Contact',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'analysisResults',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 1,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'The results of analyzing the data, typically with a clustering algorithm.',
                                        '__CLASS_NAME' => 'Experiment',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'analysisResults',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The results of analyzing the data, typically with a clustering algorithm.',
                                         '__CLASS_NAME' => 'BioAssayDataCluster',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'bioAssayData',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 1,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'The collection of BioAssayDatas for this Experiment.',
                                        '__CLASS_NAME' => 'Experiment',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'bioAssayData',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The collection of BioAssayDatas for this Experiment.',
                                         '__CLASS_NAME' => 'BioAssayData',
                                         '__RANK' => '3',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'bioAssays',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 1,
                                        '__CARDINALITY' => '0..N',
                                        '__DOCUMENTATION' => 'The collection of BioAssays for this Experiment.',
                                        '__CLASS_NAME' => 'Experiment',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'bioAssays',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The collection of BioAssays for this Experiment.',
                                         '__CLASS_NAME' => 'BioAssay',
                                         '__RANK' => '4',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'experimentDesigns',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The association to the description and annotation of the Experiment, along with the grouping of the top-level BioAssays.',
                                        '__CLASS_NAME' => 'Experiment',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'experimentDesigns',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '1..N',
                                         '__DOCUMENTATION' => 'The association to the description and annotation of the Experiment, along with the grouping of the top-level BioAssays.',
                                         '__CLASS_NAME' => 'ExperimentDesign',
                                         '__RANK' => '5',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::Experiment::Experiment->methodname() syntax.

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



=item * experimentDesigns

Sets the value of the C<experimentDesigns> association

The value must be of type: array of C<Bio::MAGE::Experiment::ExperimentDesign>.


=item * providers

Sets the value of the C<providers> association

The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Contact>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * analysisResults

Sets the value of the C<analysisResults> association

The value must be of type: array of C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster>.


=item * bioAssays

Sets the value of the C<bioAssays> association

The value must be of type: array of C<Bio::MAGE::BioAssay::BioAssay>.


=item * bioAssayData

Sets the value of the C<bioAssayData> association

The value must be of type: array of C<Bio::MAGE::BioAssayData::BioAssayData>.


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

C<Bio::MAGE::Experiment::Experiment> has the following attribute accessor methods:

=over


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $experiment->setName($val)

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


=item $val = $experiment->getName()

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


=item $val = $experiment->setIdentifier($val)

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


=item $val = $experiment->getIdentifier()

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

Bio::MAGE::Experiment::Experiment has the following association accessor methods:

=over


=item experimentDesigns

Methods for the C<experimentDesigns> association.


From the MAGE-OM documentation:

The association to the description and annotation of the Experiment, along with the grouping of the top-level BioAssays.


=over


=item $array_ref = $experiment->setExperimentDesigns($array_ref)

The restricted setter method for the C<experimentDesigns> association.


Input parameters: the value to which the C<experimentDesigns> association will be set : a reference to an array of objects of type C<Bio::MAGE::Experiment::ExperimentDesign>

Return value: the current value of the C<experimentDesigns> association : a reference to an array of objects of type C<Bio::MAGE::Experiment::ExperimentDesign>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Experiment::ExperimentDesign> instances

=cut


sub setExperimentDesigns {
  my $self = shift;
  croak(__PACKAGE__ . "::setExperimentDesigns: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setExperimentDesigns: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setExperimentDesigns: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setExperimentDesigns: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Experiment::ExperimentDesign")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Experiment::ExperimentDesign');
    }
  }

  return $self->{__EXPERIMENTDESIGNS} = $val;
}


=item $array_ref = $experiment->getExperimentDesigns()

The restricted getter method for the C<experimentDesigns> association.

Input parameters: none

Return value: the current value of the C<experimentDesigns> association : a reference to an array of objects of type C<Bio::MAGE::Experiment::ExperimentDesign>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getExperimentDesigns {
  my $self = shift;
  croak(__PACKAGE__ . "::getExperimentDesigns: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__EXPERIMENTDESIGNS};
}




=item $val = $experiment->addExperimentDesigns(@vals)

Because the experimentDesigns association has list cardinality, it may store more
than one value. This method adds the current list of objects in the experimentDesigns association.

Input parameters: the list of values C<@vals> to add to the experimentDesigns association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Experiment::ExperimentDesign>

=cut


sub addExperimentDesigns {
  my $self = shift;
  croak(__PACKAGE__ . "::addExperimentDesigns: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addExperimentDesigns: wrong type: " . ref($val) . " expected Bio::MAGE::Experiment::ExperimentDesign")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Experiment::ExperimentDesign');
  }

  return push(@{$self->{__EXPERIMENTDESIGNS}},@vals);
}





=back


=item providers

Methods for the C<providers> association.


From the MAGE-OM documentation:

The providers of the Experiment, its data and annotation.


=over


=item $array_ref = $experiment->setProviders($array_ref)

The restricted setter method for the C<providers> association.


Input parameters: the value to which the C<providers> association will be set : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Return value: the current value of the C<providers> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::AuditAndSecurity::Contact> instances

=cut


sub setProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::setProviders: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setProviders: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setProviders: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setProviders: wrong type: " . ref($val_ent) . " expected Bio::MAGE::AuditAndSecurity::Contact")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::AuditAndSecurity::Contact');
    }
  }

  return $self->{__PROVIDERS} = $val;
}


=item $array_ref = $experiment->getProviders()

The restricted getter method for the C<providers> association.

Input parameters: none

Return value: the current value of the C<providers> association : a reference to an array of objects of type C<Bio::MAGE::AuditAndSecurity::Contact>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::getProviders: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PROVIDERS};
}




=item $val = $experiment->addProviders(@vals)

Because the providers association has list cardinality, it may store more
than one value. This method adds the current list of objects in the providers association.

Input parameters: the list of values C<@vals> to add to the providers association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::AuditAndSecurity::Contact>

=cut


sub addProviders {
  my $self = shift;
  croak(__PACKAGE__ . "::addProviders: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addProviders: wrong type: " . ref($val) . " expected Bio::MAGE::AuditAndSecurity::Contact")
      unless UNIVERSAL::isa($val,'Bio::MAGE::AuditAndSecurity::Contact');
  }

  return push(@{$self->{__PROVIDERS}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $experiment->setAuditTrail($array_ref)

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


=item $array_ref = $experiment->getAuditTrail()

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




=item $val = $experiment->addAuditTrail(@vals)

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


=item $array_ref = $experiment->setPropertySets($array_ref)

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


=item $array_ref = $experiment->getPropertySets()

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




=item $val = $experiment->addPropertySets(@vals)

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


=item analysisResults

Methods for the C<analysisResults> association.


From the MAGE-OM documentation:

The results of analyzing the data, typically with a clustering algorithm.


=over


=item $array_ref = $experiment->setAnalysisResults($array_ref)

The restricted setter method for the C<analysisResults> association.


Input parameters: the value to which the C<analysisResults> association will be set : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster>

Return value: the current value of the C<analysisResults> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster> instances

=cut


sub setAnalysisResults {
  my $self = shift;
  croak(__PACKAGE__ . "::setAnalysisResults: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAnalysisResults: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setAnalysisResults: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setAnalysisResults: wrong type: " . ref($val_ent) . " expected Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster');
    }
  }

  return $self->{__ANALYSISRESULTS} = $val;
}


=item $array_ref = $experiment->getAnalysisResults()

The restricted getter method for the C<analysisResults> association.

Input parameters: none

Return value: the current value of the C<analysisResults> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAnalysisResults {
  my $self = shift;
  croak(__PACKAGE__ . "::getAnalysisResults: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ANALYSISRESULTS};
}




=item $val = $experiment->addAnalysisResults(@vals)

Because the analysisResults association has list cardinality, it may store more
than one value. This method adds the current list of objects in the analysisResults association.

Input parameters: the list of values C<@vals> to add to the analysisResults association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster>

=cut


sub addAnalysisResults {
  my $self = shift;
  croak(__PACKAGE__ . "::addAnalysisResults: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addAnalysisResults: wrong type: " . ref($val) . " expected Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster")
      unless UNIVERSAL::isa($val,'Bio::MAGE::HigherLevelAnalysis::BioAssayDataCluster');
  }

  return push(@{$self->{__ANALYSISRESULTS}},@vals);
}





=back


=item bioAssays

Methods for the C<bioAssays> association.


From the MAGE-OM documentation:

The collection of BioAssays for this Experiment.


=over


=item $array_ref = $experiment->setBioAssays($array_ref)

The restricted setter method for the C<bioAssays> association.


Input parameters: the value to which the C<bioAssays> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssay>

Return value: the current value of the C<bioAssays> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssay>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioAssay::BioAssay> instances

=cut


sub setBioAssays {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioAssays: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioAssays: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setBioAssays: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setBioAssays: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioAssay::BioAssay")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioAssay::BioAssay');
    }
  }

  return $self->{__BIOASSAYS} = $val;
}


=item $array_ref = $experiment->getBioAssays()

The restricted getter method for the C<bioAssays> association.

Input parameters: none

Return value: the current value of the C<bioAssays> association : a reference to an array of objects of type C<Bio::MAGE::BioAssay::BioAssay>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioAssays {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioAssays: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOASSAYS};
}




=item $val = $experiment->addBioAssays(@vals)

Because the bioAssays association has list cardinality, it may store more
than one value. This method adds the current list of objects in the bioAssays association.

Input parameters: the list of values C<@vals> to add to the bioAssays association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioAssay::BioAssay>

=cut


sub addBioAssays {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssays: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addBioAssays: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssay::BioAssay")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssay::BioAssay');
  }

  return push(@{$self->{__BIOASSAYS}},@vals);
}





=back


=item bioAssayData

Methods for the C<bioAssayData> association.


From the MAGE-OM documentation:

The collection of BioAssayDatas for this Experiment.


=over


=item $array_ref = $experiment->setBioAssayData($array_ref)

The restricted setter method for the C<bioAssayData> association.


Input parameters: the value to which the C<bioAssayData> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioAssayData::BioAssayData>

Return value: the current value of the C<bioAssayData> association : a reference to an array of objects of type C<Bio::MAGE::BioAssayData::BioAssayData>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioAssayData::BioAssayData> instances

=cut


sub setBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::setBioAssayData: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setBioAssayData: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setBioAssayData: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setBioAssayData: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioAssayData::BioAssayData")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioAssayData::BioAssayData');
    }
  }

  return $self->{__BIOASSAYDATA} = $val;
}


=item $array_ref = $experiment->getBioAssayData()

The restricted getter method for the C<bioAssayData> association.

Input parameters: none

Return value: the current value of the C<bioAssayData> association : a reference to an array of objects of type C<Bio::MAGE::BioAssayData::BioAssayData>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::getBioAssayData: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__BIOASSAYDATA};
}




=item $val = $experiment->addBioAssayData(@vals)

Because the bioAssayData association has list cardinality, it may store more
than one value. This method adds the current list of objects in the bioAssayData association.

Input parameters: the list of values C<@vals> to add to the bioAssayData association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioAssayData::BioAssayData>

=cut


sub addBioAssayData {
  my $self = shift;
  croak(__PACKAGE__ . "::addBioAssayData: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addBioAssayData: wrong type: " . ref($val) . " expected Bio::MAGE::BioAssayData::BioAssayData")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioAssayData::BioAssayData');
  }

  return push(@{$self->{__BIOASSAYDATA}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $experiment->setDescriptions($array_ref)

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


=item $array_ref = $experiment->getDescriptions()

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




=item $val = $experiment->addDescriptions(@vals)

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


=item $val = $experiment->setSecurity($val)

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


=item $val = $experiment->getSecurity()

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

