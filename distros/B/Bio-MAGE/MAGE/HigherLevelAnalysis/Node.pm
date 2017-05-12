##############################
#
# Bio::MAGE::HigherLevelAnalysis::Node
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



package Bio::MAGE::HigherLevelAnalysis::Node;
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

Bio::MAGE::HigherLevelAnalysis::Node - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::HigherLevelAnalysis::Node

  # creating an empty instance
  my $node = Bio::MAGE::HigherLevelAnalysis::Node->new();

  # creating an instance with existing data
  my $node = Bio::MAGE::HigherLevelAnalysis::Node->new(
        nodeValue=>\@nodevalue_list,
        descriptions=>\@description_list,
        auditTrail=>\@audit_list,
        security=>$security_ref,
        nodes=>\@node_list,
        nodeContents=>\@nodecontents_list,
        propertySets=>\@namevaluetype_list,
  );



  # 'nodeValue' association
  my $nodevalue_array_ref = $node->nodeValue(); # getter
  $node->nodeValue(\@nodevalue_list); # setter

  # 'descriptions' association
  my $description_array_ref = $node->descriptions(); # getter
  $node->descriptions(\@description_list); # setter

  # 'auditTrail' association
  my $audit_array_ref = $node->auditTrail(); # getter
  $node->auditTrail(\@audit_list); # setter

  # 'security' association
  my $security_ref = $node->security(); # getter
  $node->security($security_ref); # setter

  # 'nodes' association
  my $node_array_ref = $node->nodes(); # getter
  $node->nodes(\@node_list); # setter

  # 'nodeContents' association
  my $nodecontents_array_ref = $node->nodeContents(); # getter
  $node->nodeContents(\@nodecontents_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $node->propertySets(); # getter
  $node->propertySets(\@namevaluetype_list); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<Node> class:

An individual component of a clustering.  May contain other nodes.



=cut

=head1 INHERITANCE


Bio::MAGE::HigherLevelAnalysis::Node has the following superclasses:

=over


=item * Bio::MAGE::Describable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::HigherLevelAnalysis::Node];
  $__PACKAGE_NAME      = q[HigherLevelAnalysis];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Describable'];
  $__ATTRIBUTE_NAMES   = [''];
  $__ASSOCIATION_NAMES = ['nodeValue', 'descriptions', 'security', 'auditTrail', 'propertySets', 'nodeContents', 'nodes'];
  $__ASSOCIATIONS      = [
          'nodes',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Nested nodes of the BioAssayDataCluster.',
                                        '__CLASS_NAME' => 'Node',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'nodes',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Nested nodes of the BioAssayDataCluster.',
                                         '__CLASS_NAME' => 'Node',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'nodeContents',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The contents of the node, expressed as either a one, two or three dimensional object.',
                                        '__CLASS_NAME' => 'Node',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'nodeContents',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'The contents of the node, expressed as either a one, two or three dimensional object.',
                                         '__CLASS_NAME' => 'NodeContents',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'nodeValue',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Values or measurements for this node that may be produced by the clustering algorithm.  Typical are distance values for the nodes.',
                                        '__CLASS_NAME' => 'Node',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'nodeValue',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Values or measurements for this node that may be produced by the clustering algorithm.  Typical are distance values for the nodes.',
                                         '__CLASS_NAME' => 'NodeValue',
                                         '__RANK' => '3',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::HigherLevelAnalysis::Node->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over


=item * nodeValue

Sets the value of the C<nodeValue> association

The value must be of type: array of C<Bio::MAGE::HigherLevelAnalysis::NodeValue>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * security

Sets the value of the C<security> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Security>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * nodeContents

Sets the value of the C<nodeContents> association

The value must be of type: array of C<Bio::MAGE::HigherLevelAnalysis::NodeContents>.


=item * nodes

Sets the value of the C<nodes> association

The value must be of type: array of C<Bio::MAGE::HigherLevelAnalysis::Node>.


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

C<Bio::MAGE::HigherLevelAnalysis::Node> has the following attribute accessor methods:

=over


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

Bio::MAGE::HigherLevelAnalysis::Node has the following association accessor methods:

=over


=item nodeValue

Methods for the C<nodeValue> association.


From the MAGE-OM documentation:

Values or measurements for this node that may be produced by the clustering algorithm.  Typical are distance values for the nodes.


=over


=item $array_ref = $node->setNodeValue($array_ref)

The restricted setter method for the C<nodeValue> association.


Input parameters: the value to which the C<nodeValue> association will be set : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeValue>

Return value: the current value of the C<nodeValue> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeValue>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::HigherLevelAnalysis::NodeValue> instances

=cut


sub setNodeValue {
  my $self = shift;
  croak(__PACKAGE__ . "::setNodeValue: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setNodeValue: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setNodeValue: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setNodeValue: wrong type: " . ref($val_ent) . " expected Bio::MAGE::HigherLevelAnalysis::NodeValue")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::HigherLevelAnalysis::NodeValue');
    }
  }

  return $self->{__NODEVALUE} = $val;
}


=item $array_ref = $node->getNodeValue()

The restricted getter method for the C<nodeValue> association.

Input parameters: none

Return value: the current value of the C<nodeValue> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeValue>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getNodeValue {
  my $self = shift;
  croak(__PACKAGE__ . "::getNodeValue: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__NODEVALUE};
}




=item $val = $node->addNodeValue(@vals)

Because the nodeValue association has list cardinality, it may store more
than one value. This method adds the current list of objects in the nodeValue association.

Input parameters: the list of values C<@vals> to add to the nodeValue association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::HigherLevelAnalysis::NodeValue>

=cut


sub addNodeValue {
  my $self = shift;
  croak(__PACKAGE__ . "::addNodeValue: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addNodeValue: wrong type: " . ref($val) . " expected Bio::MAGE::HigherLevelAnalysis::NodeValue")
      unless UNIVERSAL::isa($val,'Bio::MAGE::HigherLevelAnalysis::NodeValue');
  }

  return push(@{$self->{__NODEVALUE}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $node->setDescriptions($array_ref)

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


=item $array_ref = $node->getDescriptions()

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




=item $val = $node->addDescriptions(@vals)

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


=item $val = $node->setSecurity($val)

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


=item $val = $node->getSecurity()

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


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $node->setAuditTrail($array_ref)

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


=item $array_ref = $node->getAuditTrail()

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




=item $val = $node->addAuditTrail(@vals)

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


=item $array_ref = $node->setPropertySets($array_ref)

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


=item $array_ref = $node->getPropertySets()

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




=item $val = $node->addPropertySets(@vals)

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


=item nodeContents

Methods for the C<nodeContents> association.


From the MAGE-OM documentation:

The contents of the node, expressed as either a one, two or three dimensional object.


=over


=item $array_ref = $node->setNodeContents($array_ref)

The restricted setter method for the C<nodeContents> association.


Input parameters: the value to which the C<nodeContents> association will be set : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeContents>

Return value: the current value of the C<nodeContents> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeContents>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::HigherLevelAnalysis::NodeContents> instances

=cut


sub setNodeContents {
  my $self = shift;
  croak(__PACKAGE__ . "::setNodeContents: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setNodeContents: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setNodeContents: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setNodeContents: wrong type: " . ref($val_ent) . " expected Bio::MAGE::HigherLevelAnalysis::NodeContents")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::HigherLevelAnalysis::NodeContents');
    }
  }

  return $self->{__NODECONTENTS} = $val;
}


=item $array_ref = $node->getNodeContents()

The restricted getter method for the C<nodeContents> association.

Input parameters: none

Return value: the current value of the C<nodeContents> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::NodeContents>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getNodeContents {
  my $self = shift;
  croak(__PACKAGE__ . "::getNodeContents: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__NODECONTENTS};
}




=item $val = $node->addNodeContents(@vals)

Because the nodeContents association has list cardinality, it may store more
than one value. This method adds the current list of objects in the nodeContents association.

Input parameters: the list of values C<@vals> to add to the nodeContents association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::HigherLevelAnalysis::NodeContents>

=cut


sub addNodeContents {
  my $self = shift;
  croak(__PACKAGE__ . "::addNodeContents: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addNodeContents: wrong type: " . ref($val) . " expected Bio::MAGE::HigherLevelAnalysis::NodeContents")
      unless UNIVERSAL::isa($val,'Bio::MAGE::HigherLevelAnalysis::NodeContents');
  }

  return push(@{$self->{__NODECONTENTS}},@vals);
}





=back


=item nodes

Methods for the C<nodes> association.


From the MAGE-OM documentation:

Nested nodes of the BioAssayDataCluster.


=over


=item $array_ref = $node->setNodes($array_ref)

The restricted setter method for the C<nodes> association.


Input parameters: the value to which the C<nodes> association will be set : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::Node>

Return value: the current value of the C<nodes> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::Node>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::HigherLevelAnalysis::Node> instances

=cut


sub setNodes {
  my $self = shift;
  croak(__PACKAGE__ . "::setNodes: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setNodes: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setNodes: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setNodes: wrong type: " . ref($val_ent) . " expected Bio::MAGE::HigherLevelAnalysis::Node")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::HigherLevelAnalysis::Node');
    }
  }

  return $self->{__NODES} = $val;
}


=item $array_ref = $node->getNodes()

The restricted getter method for the C<nodes> association.

Input parameters: none

Return value: the current value of the C<nodes> association : a reference to an array of objects of type C<Bio::MAGE::HigherLevelAnalysis::Node>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getNodes {
  my $self = shift;
  croak(__PACKAGE__ . "::getNodes: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__NODES};
}




=item $val = $node->addNodes(@vals)

Because the nodes association has list cardinality, it may store more
than one value. This method adds the current list of objects in the nodes association.

Input parameters: the list of values C<@vals> to add to the nodes association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::HigherLevelAnalysis::Node>

=cut


sub addNodes {
  my $self = shift;
  croak(__PACKAGE__ . "::addNodes: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addNodes: wrong type: " . ref($val) . " expected Bio::MAGE::HigherLevelAnalysis::Node")
      unless UNIVERSAL::isa($val,'Bio::MAGE::HigherLevelAnalysis::Node');
  }

  return push(@{$self->{__NODES}},@vals);
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

