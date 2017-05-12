##############################
#
# Bio::MAGE::BioSequence::BioSequence
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



package Bio::MAGE::BioSequence::BioSequence;
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

Bio::MAGE::BioSequence::BioSequence - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::BioSequence::BioSequence

  # creating an empty instance
  my $biosequence = Bio::MAGE::BioSequence::BioSequence->new();

  # creating an instance with existing data
  my $biosequence = Bio::MAGE::BioSequence::BioSequence->new(
        identifier=>$identifier_val,
        isApproximateLength=>$isapproximatelength_val,
        length=>$length_val,
        sequence=>$sequence_val,
        name=>$name_val,
        isCircular=>$iscircular_val,
        sequenceDatabases=>\@databaseentry_list,
        auditTrail=>\@audit_list,
        polymerType=>$ontologyentry_ref,
        species=>$ontologyentry_ref,
        propertySets=>\@namevaluetype_list,
        ontologyEntries=>\@ontologyentry_list,
        descriptions=>\@description_list,
        seqFeatures=>\@seqfeature_list,
        security=>$security_ref,
        type=>$ontologyentry_ref,
  );


  # 'identifier' attribute
  my $identifier_val = $biosequence->identifier(); # getter
  $biosequence->identifier($value); # setter

  # 'isApproximateLength' attribute
  my $isApproximateLength_val = $biosequence->isApproximateLength(); # getter
  $biosequence->isApproximateLength($value); # setter

  # 'length' attribute
  my $length_val = $biosequence->length(); # getter
  $biosequence->length($value); # setter

  # 'sequence' attribute
  my $sequence_val = $biosequence->sequence(); # getter
  $biosequence->sequence($value); # setter

  # 'name' attribute
  my $name_val = $biosequence->name(); # getter
  $biosequence->name($value); # setter

  # 'isCircular' attribute
  my $isCircular_val = $biosequence->isCircular(); # getter
  $biosequence->isCircular($value); # setter


  # 'sequenceDatabases' association
  my $databaseentry_array_ref = $biosequence->sequenceDatabases(); # getter
  $biosequence->sequenceDatabases(\@databaseentry_list); # setter

  # 'auditTrail' association
  my $audit_array_ref = $biosequence->auditTrail(); # getter
  $biosequence->auditTrail(\@audit_list); # setter

  # 'polymerType' association
  my $ontologyentry_ref = $biosequence->polymerType(); # getter
  $biosequence->polymerType($ontologyentry_ref); # setter

  # 'species' association
  my $ontologyentry_ref = $biosequence->species(); # getter
  $biosequence->species($ontologyentry_ref); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $biosequence->propertySets(); # getter
  $biosequence->propertySets(\@namevaluetype_list); # setter

  # 'ontologyEntries' association
  my $ontologyentry_array_ref = $biosequence->ontologyEntries(); # getter
  $biosequence->ontologyEntries(\@ontologyentry_list); # setter

  # 'descriptions' association
  my $description_array_ref = $biosequence->descriptions(); # getter
  $biosequence->descriptions(\@description_list); # setter

  # 'seqFeatures' association
  my $seqfeature_array_ref = $biosequence->seqFeatures(); # getter
  $biosequence->seqFeatures(\@seqfeature_list); # setter

  # 'security' association
  my $security_ref = $biosequence->security(); # getter
  $biosequence->security($security_ref); # setter

  # 'type' association
  my $ontologyentry_ref = $biosequence->type(); # getter
  $biosequence->type($ontologyentry_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<BioSequence> class:

A BioSequence is a representation of a DNA, RNA, or protein sequence.  It can be represented by a Clone, Gene, or the sequence.



=cut

=head1 INHERITANCE


Bio::MAGE::BioSequence::BioSequence has the following superclasses:

=over


=item * Bio::MAGE::Identifiable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::BioSequence::BioSequence];
  $__PACKAGE_NAME      = q[BioSequence];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Identifiable'];
  $__ATTRIBUTE_NAMES   = ['identifier', 'isApproximateLength', 'length', 'sequence', 'name', 'isCircular'];
  $__ASSOCIATION_NAMES = ['sequenceDatabases', 'auditTrail', 'propertySets', 'species', 'polymerType', 'ontologyEntries', 'seqFeatures', 'descriptions', 'security', 'type'];
  $__ASSOCIATIONS      = [
          'sequenceDatabases',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'References an entry in a species database, like GenBank, UniGene, etc.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'sequenceDatabases',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'References an entry in a species database, like GenBank, UniGene, etc.',
                                         '__CLASS_NAME' => 'DatabaseEntry',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'ontologyEntries',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Ontology entries referring to common values associated with BioSequences, such as gene names, go ids, etc.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'ontologyEntries',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Ontology entries referring to common values associated with BioSequences, such as gene names, go ids, etc.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'polymerType',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'A choice of protein, RNA, or DNA.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'polymerType',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '1',
                                         '__DOCUMENTATION' => 'A choice of protein, RNA, or DNA.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '3',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'type',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The type of biosequence, i.e. gene, exon, UniGene cluster, fragment, BAC, EST, etc.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'type',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '1',
                                         '__DOCUMENTATION' => 'The type of biosequence, i.e. gene, exon, UniGene cluster, fragment, BAC, EST, etc.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '4',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'species',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'The organism from which this sequence was obtained.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'species',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..1',
                                         '__DOCUMENTATION' => 'The organism from which this sequence was obtained.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '5',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'seqFeatures',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Association to annotations for subsequences.  Corresponds to the GenBank Frame Table.',
                                        '__CLASS_NAME' => 'BioSequence',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'seqFeatures',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'Association to annotations for subsequences.  Corresponds to the GenBank Frame Table.',
                                         '__CLASS_NAME' => 'SeqFeature',
                                         '__RANK' => '6',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::BioSequence::BioSequence->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * identifier

Sets the value of the C<identifier> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * isApproximateLength

Sets the value of the C<isApproximateLength> attribute

=item * length

Sets the value of the C<length> attribute

=item * sequence

Sets the value of the C<sequence> attribute

=item * name

Sets the value of the C<name> attribute (this attribute was inherited from class C<Bio::MAGE::Identifiable>).


=item * isCircular

Sets the value of the C<isCircular> attribute


=item * sequenceDatabases

Sets the value of the C<sequenceDatabases> association

The value must be of type: array of C<Bio::MAGE::Description::DatabaseEntry>.


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * species

Sets the value of the C<species> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * polymerType

Sets the value of the C<polymerType> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


=item * ontologyEntries

Sets the value of the C<ontologyEntries> association

The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


=item * seqFeatures

Sets the value of the C<seqFeatures> association

The value must be of type: array of C<Bio::MAGE::BioSequence::SeqFeature>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * security

Sets the value of the C<security> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: instance of C<Bio::MAGE::AuditAndSecurity::Security>.


=item * type

Sets the value of the C<type> association

The value must be of type: instance of C<Bio::MAGE::Description::OntologyEntry>.


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

C<Bio::MAGE::BioSequence::BioSequence> has the following attribute accessor methods:

=over


=item identifier

Methods for the C<identifier> attribute.


From the MAGE-OM documentation:

An identifier is an unambiguous string that is unique within the scope (i.e. a document, a set of related documents, or a repository) of its use.


=over


=item $val = $biosequence->setIdentifier($val)

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


=item $val = $biosequence->getIdentifier()

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


=item isApproximateLength

Methods for the C<isApproximateLength> attribute.


From the MAGE-OM documentation:

If length not positively known will be true


=over


=item $val = $biosequence->setIsApproximateLength($val)

The restricted setter method for the C<isApproximateLength> attribute.


Input parameters: the value to which the C<isApproximateLength> attribute will be set 

Return value: the current value of the C<isApproximateLength> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setIsApproximateLength {
  my $self = shift;
  croak(__PACKAGE__ . "::setIsApproximateLength: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setIsApproximateLength: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__ISAPPROXIMATELENGTH} = $val;
}


=item $val = $biosequence->getIsApproximateLength()

The restricted getter method for the C<isApproximateLength> attribute.

Input parameters: none

Return value: the current value of the C<isApproximateLength> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getIsApproximateLength {
  my $self = shift;
  croak(__PACKAGE__ . "::getIsApproximateLength: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ISAPPROXIMATELENGTH};
}





=back


=item length

Methods for the C<length> attribute.


From the MAGE-OM documentation:

The number of residues in the biosequence.


=over


=item $val = $biosequence->setLength($val)

The restricted setter method for the C<length> attribute.


Input parameters: the value to which the C<length> attribute will be set 

Return value: the current value of the C<length> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setLength {
  my $self = shift;
  croak(__PACKAGE__ . "::setLength: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setLength: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__LENGTH} = $val;
}


=item $val = $biosequence->getLength()

The restricted getter method for the C<length> attribute.

Input parameters: none

Return value: the current value of the C<length> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getLength {
  my $self = shift;
  croak(__PACKAGE__ . "::getLength: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__LENGTH};
}





=back


=item sequence

Methods for the C<sequence> attribute.


From the MAGE-OM documentation:

The actual components of the sequence, for instance, for DNA a string consisting of A,T,C and G.

The attribute is optional and instead of specified here, can be found through the DatabaseEntry. 


=over


=item $val = $biosequence->setSequence($val)

The restricted setter method for the C<sequence> attribute.


Input parameters: the value to which the C<sequence> attribute will be set 

Return value: the current value of the C<sequence> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setSequence {
  my $self = shift;
  croak(__PACKAGE__ . "::setSequence: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSequence: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__SEQUENCE} = $val;
}


=item $val = $biosequence->getSequence()

The restricted getter method for the C<sequence> attribute.

Input parameters: none

Return value: the current value of the C<sequence> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSequence {
  my $self = shift;
  croak(__PACKAGE__ . "::getSequence: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SEQUENCE};
}





=back


=item name

Methods for the C<name> attribute.


From the MAGE-OM documentation:

The potentially ambiguous common identifier.


=over


=item $val = $biosequence->setName($val)

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


=item $val = $biosequence->getName()

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


=item isCircular

Methods for the C<isCircular> attribute.


From the MAGE-OM documentation:

Indicates if the BioSequence is circular in nature.


=over


=item $val = $biosequence->setIsCircular($val)

The restricted setter method for the C<isCircular> attribute.


Input parameters: the value to which the C<isCircular> attribute will be set 

Return value: the current value of the C<isCircular> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setIsCircular {
  my $self = shift;
  croak(__PACKAGE__ . "::setIsCircular: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setIsCircular: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__ISCIRCULAR} = $val;
}


=item $val = $biosequence->getIsCircular()

The restricted getter method for the C<isCircular> attribute.

Input parameters: none

Return value: the current value of the C<isCircular> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getIsCircular {
  my $self = shift;
  croak(__PACKAGE__ . "::getIsCircular: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ISCIRCULAR};
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

Bio::MAGE::BioSequence::BioSequence has the following association accessor methods:

=over


=item sequenceDatabases

Methods for the C<sequenceDatabases> association.


From the MAGE-OM documentation:

References an entry in a species database, like GenBank, UniGene, etc.


=over


=item $array_ref = $biosequence->setSequenceDatabases($array_ref)

The restricted setter method for the C<sequenceDatabases> association.


Input parameters: the value to which the C<sequenceDatabases> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Return value: the current value of the C<sequenceDatabases> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::DatabaseEntry> instances

=cut


sub setSequenceDatabases {
  my $self = shift;
  croak(__PACKAGE__ . "::setSequenceDatabases: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSequenceDatabases: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setSequenceDatabases: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setSequenceDatabases: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::DatabaseEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::DatabaseEntry');
    }
  }

  return $self->{__SEQUENCEDATABASES} = $val;
}


=item $array_ref = $biosequence->getSequenceDatabases()

The restricted getter method for the C<sequenceDatabases> association.

Input parameters: none

Return value: the current value of the C<sequenceDatabases> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSequenceDatabases {
  my $self = shift;
  croak(__PACKAGE__ . "::getSequenceDatabases: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SEQUENCEDATABASES};
}




=item $val = $biosequence->addSequenceDatabases(@vals)

Because the sequenceDatabases association has list cardinality, it may store more
than one value. This method adds the current list of objects in the sequenceDatabases association.

Input parameters: the list of values C<@vals> to add to the sequenceDatabases association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::DatabaseEntry>

=cut


sub addSequenceDatabases {
  my $self = shift;
  croak(__PACKAGE__ . "::addSequenceDatabases: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addSequenceDatabases: wrong type: " . ref($val) . " expected Bio::MAGE::Description::DatabaseEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::DatabaseEntry');
  }

  return push(@{$self->{__SEQUENCEDATABASES}},@vals);
}





=back


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $biosequence->setAuditTrail($array_ref)

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


=item $array_ref = $biosequence->getAuditTrail()

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




=item $val = $biosequence->addAuditTrail(@vals)

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


=item $array_ref = $biosequence->setPropertySets($array_ref)

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


=item $array_ref = $biosequence->getPropertySets()

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




=item $val = $biosequence->addPropertySets(@vals)

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


=item species

Methods for the C<species> association.


From the MAGE-OM documentation:

The organism from which this sequence was obtained.


=over


=item $val = $biosequence->setSpecies($val)

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


=item $val = $biosequence->getSpecies()

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


=item polymerType

Methods for the C<polymerType> association.


From the MAGE-OM documentation:

A choice of protein, RNA, or DNA.


=over


=item $val = $biosequence->setPolymerType($val)

The restricted setter method for the C<polymerType> association.


Input parameters: the value to which the C<polymerType> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<polymerType> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setPolymerType {
  my $self = shift;
  croak(__PACKAGE__ . "::setPolymerType: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPolymerType: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setPolymerType: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__POLYMERTYPE} = $val;
}


=item $val = $biosequence->getPolymerType()

The restricted getter method for the C<polymerType> association.

Input parameters: none

Return value: the current value of the C<polymerType> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPolymerType {
  my $self = shift;
  croak(__PACKAGE__ . "::getPolymerType: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__POLYMERTYPE};
}





=back


=item ontologyEntries

Methods for the C<ontologyEntries> association.


From the MAGE-OM documentation:

Ontology entries referring to common values associated with BioSequences, such as gene names, go ids, etc.


=over


=item $array_ref = $biosequence->setOntologyEntries($array_ref)

The restricted setter method for the C<ontologyEntries> association.


Input parameters: the value to which the C<ontologyEntries> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<ontologyEntries> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setOntologyEntries {
  my $self = shift;
  croak(__PACKAGE__ . "::setOntologyEntries: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setOntologyEntries: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setOntologyEntries: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setOntologyEntries: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__ONTOLOGYENTRIES} = $val;
}


=item $array_ref = $biosequence->getOntologyEntries()

The restricted getter method for the C<ontologyEntries> association.

Input parameters: none

Return value: the current value of the C<ontologyEntries> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getOntologyEntries {
  my $self = shift;
  croak(__PACKAGE__ . "::getOntologyEntries: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ONTOLOGYENTRIES};
}




=item $val = $biosequence->addOntologyEntries(@vals)

Because the ontologyEntries association has list cardinality, it may store more
than one value. This method adds the current list of objects in the ontologyEntries association.

Input parameters: the list of values C<@vals> to add to the ontologyEntries association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addOntologyEntries {
  my $self = shift;
  croak(__PACKAGE__ . "::addOntologyEntries: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addOntologyEntries: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__ONTOLOGYENTRIES}},@vals);
}





=back


=item seqFeatures

Methods for the C<seqFeatures> association.


From the MAGE-OM documentation:

Association to annotations for subsequences.  Corresponds to the GenBank Frame Table.


=over


=item $array_ref = $biosequence->setSeqFeatures($array_ref)

The restricted setter method for the C<seqFeatures> association.


Input parameters: the value to which the C<seqFeatures> association will be set : a reference to an array of objects of type C<Bio::MAGE::BioSequence::SeqFeature>

Return value: the current value of the C<seqFeatures> association : a reference to an array of objects of type C<Bio::MAGE::BioSequence::SeqFeature>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::BioSequence::SeqFeature> instances

=cut


sub setSeqFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::setSeqFeatures: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setSeqFeatures: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setSeqFeatures: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setSeqFeatures: wrong type: " . ref($val_ent) . " expected Bio::MAGE::BioSequence::SeqFeature")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::BioSequence::SeqFeature');
    }
  }

  return $self->{__SEQFEATURES} = $val;
}


=item $array_ref = $biosequence->getSeqFeatures()

The restricted getter method for the C<seqFeatures> association.

Input parameters: none

Return value: the current value of the C<seqFeatures> association : a reference to an array of objects of type C<Bio::MAGE::BioSequence::SeqFeature>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getSeqFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::getSeqFeatures: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__SEQFEATURES};
}




=item $val = $biosequence->addSeqFeatures(@vals)

Because the seqFeatures association has list cardinality, it may store more
than one value. This method adds the current list of objects in the seqFeatures association.

Input parameters: the list of values C<@vals> to add to the seqFeatures association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::BioSequence::SeqFeature>

=cut


sub addSeqFeatures {
  my $self = shift;
  croak(__PACKAGE__ . "::addSeqFeatures: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addSeqFeatures: wrong type: " . ref($val) . " expected Bio::MAGE::BioSequence::SeqFeature")
      unless UNIVERSAL::isa($val,'Bio::MAGE::BioSequence::SeqFeature');
  }

  return push(@{$self->{__SEQFEATURES}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $biosequence->setDescriptions($array_ref)

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


=item $array_ref = $biosequence->getDescriptions()

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




=item $val = $biosequence->addDescriptions(@vals)

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


=item $val = $biosequence->setSecurity($val)

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


=item $val = $biosequence->getSecurity()

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


=item type

Methods for the C<type> association.


From the MAGE-OM documentation:

The type of biosequence, i.e. gene, exon, UniGene cluster, fragment, BAC, EST, etc.


=over


=item $val = $biosequence->setType($val)

The restricted setter method for the C<type> association.


Input parameters: the value to which the C<type> association will be set : one of the accepted enumerated values.

Return value: the current value of the C<type> association : one of the accepted enumerated values.

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$val> is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub setType {
  my $self = shift;
  croak(__PACKAGE__ . "::setType: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setType: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  croak(__PACKAGE__ . "::setType: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry") unless (not defined $val) or UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  return $self->{__TYPE} = $val;
}


=item $val = $biosequence->getType()

The restricted getter method for the C<type> association.

Input parameters: none

Return value: the current value of the C<type> association : an instance of type C<Bio::MAGE::Description::OntologyEntry>.

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getType {
  my $self = shift;
  croak(__PACKAGE__ . "::getType: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TYPE};
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

