##############################
#
# Bio::MAGE::BQS::BibliographicReference
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



package Bio::MAGE::BQS::BibliographicReference;
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

Bio::MAGE::BQS::BibliographicReference - Class for the MAGE-OM API

=head1 SYNOPSIS

  use Bio::MAGE::BQS::BibliographicReference

  # creating an empty instance
  my $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new();

  # creating an instance with existing data
  my $bibliographicreference = Bio::MAGE::BQS::BibliographicReference->new(
        authors=>$authors_val,
        URI=>$uri_val,
        volume=>$volume_val,
        issue=>$issue_val,
        editor=>$editor_val,
        publication=>$publication_val,
        title=>$title_val,
        publisher=>$publisher_val,
        pages=>$pages_val,
        year=>$year_val,
        auditTrail=>\@audit_list,
        propertySets=>\@namevaluetype_list,
        parameters=>\@ontologyentry_list,
        accessions=>\@databaseentry_list,
        descriptions=>\@description_list,
        security=>$security_ref,
  );


  # 'authors' attribute
  my $authors_val = $bibliographicreference->authors(); # getter
  $bibliographicreference->authors($value); # setter

  # 'URI' attribute
  my $URI_val = $bibliographicreference->URI(); # getter
  $bibliographicreference->URI($value); # setter

  # 'volume' attribute
  my $volume_val = $bibliographicreference->volume(); # getter
  $bibliographicreference->volume($value); # setter

  # 'issue' attribute
  my $issue_val = $bibliographicreference->issue(); # getter
  $bibliographicreference->issue($value); # setter

  # 'editor' attribute
  my $editor_val = $bibliographicreference->editor(); # getter
  $bibliographicreference->editor($value); # setter

  # 'publication' attribute
  my $publication_val = $bibliographicreference->publication(); # getter
  $bibliographicreference->publication($value); # setter

  # 'title' attribute
  my $title_val = $bibliographicreference->title(); # getter
  $bibliographicreference->title($value); # setter

  # 'publisher' attribute
  my $publisher_val = $bibliographicreference->publisher(); # getter
  $bibliographicreference->publisher($value); # setter

  # 'pages' attribute
  my $pages_val = $bibliographicreference->pages(); # getter
  $bibliographicreference->pages($value); # setter

  # 'year' attribute
  my $year_val = $bibliographicreference->year(); # getter
  $bibliographicreference->year($value); # setter


  # 'auditTrail' association
  my $audit_array_ref = $bibliographicreference->auditTrail(); # getter
  $bibliographicreference->auditTrail(\@audit_list); # setter

  # 'propertySets' association
  my $namevaluetype_array_ref = $bibliographicreference->propertySets(); # getter
  $bibliographicreference->propertySets(\@namevaluetype_list); # setter

  # 'parameters' association
  my $ontologyentry_array_ref = $bibliographicreference->parameters(); # getter
  $bibliographicreference->parameters(\@ontologyentry_list); # setter

  # 'accessions' association
  my $databaseentry_array_ref = $bibliographicreference->accessions(); # getter
  $bibliographicreference->accessions(\@databaseentry_list); # setter

  # 'descriptions' association
  my $description_array_ref = $bibliographicreference->descriptions(); # getter
  $bibliographicreference->descriptions(\@description_list); # setter

  # 'security' association
  my $security_ref = $bibliographicreference->security(); # getter
  $bibliographicreference->security($security_ref); # setter



=head1 DESCRIPTION

From the MAGE-OM documentation for the C<BibliographicReference> class:

Attributes for the most common criteria and association with OntologyEntry allows criteria to be specified for searching for a Bibliographic reference.




=cut

=head1 INHERITANCE


Bio::MAGE::BQS::BibliographicReference has the following superclasses:

=over


=item * Bio::MAGE::Describable


=back



=cut

BEGIN {
  $__CLASS_NAME        = q[Bio::MAGE::BQS::BibliographicReference];
  $__PACKAGE_NAME      = q[BQS];
  $__SUBCLASSES        = [];
  $__SUPERCLASSES      = ['Bio::MAGE::Describable'];
  $__ATTRIBUTE_NAMES   = ['authors', 'URI', 'volume', 'issue', 'editor', 'publication', 'title', 'publisher', 'pages', 'year'];
  $__ASSOCIATION_NAMES = ['auditTrail', 'propertySets', 'parameters', 'descriptions', 'accessions', 'security'];
  $__ASSOCIATIONS      = [
          'parameters',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'Criteria that can be used to look up the reference in a repository.',
                                        '__CLASS_NAME' => 'BibliographicReference',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'parameters',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '1..N',
                                         '__DOCUMENTATION' => 'Criteria that can be used to look up the reference in a repository.',
                                         '__CLASS_NAME' => 'OntologyEntry',
                                         '__RANK' => '1',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' ),
          'accessions',
          bless( {
                   '__SELF' => bless( {
                                        '__NAME' => undef,
                                        '__IS_REF' => 0,
                                        '__CARDINALITY' => '1',
                                        '__DOCUMENTATION' => 'References in publications, eg Medline and PubMed, for this BibliographicReference.',
                                        '__CLASS_NAME' => 'BibliographicReference',
                                        '__RANK' => undef,
                                        '__ORDERED' => undef
                                      }, 'Bio::MAGE::Association::End' ),
                   '__OTHER' => bless( {
                                         '__NAME' => 'accessions',
                                         '__IS_REF' => 1,
                                         '__CARDINALITY' => '0..N',
                                         '__DOCUMENTATION' => 'References in publications, eg Medline and PubMed, for this BibliographicReference.',
                                         '__CLASS_NAME' => 'DatabaseEntry',
                                         '__RANK' => '2',
                                         '__ORDERED' => 0
                                       }, 'Bio::MAGE::Association::End' )
                 }, 'Bio::MAGE::Association' )
        ]

}

=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the Bio::MAGE::BQS::BibliographicReference->methodname() syntax.

=over

=item new()

=item new(%args)


The object constructor C<new()> accepts the following optional
named-value style arguments:

=over

=item * authors

Sets the value of the C<authors> attribute

=item * URI

Sets the value of the C<URI> attribute

=item * volume

Sets the value of the C<volume> attribute

=item * issue

Sets the value of the C<issue> attribute

=item * editor

Sets the value of the C<editor> attribute

=item * publication

Sets the value of the C<publication> attribute

=item * title

Sets the value of the C<title> attribute

=item * publisher

Sets the value of the C<publisher> attribute

=item * pages

Sets the value of the C<pages> attribute

=item * year

Sets the value of the C<year> attribute


=item * auditTrail

Sets the value of the C<auditTrail> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::AuditAndSecurity::Audit>.


=item * propertySets

Sets the value of the C<propertySets> association (this association was inherited from class C<Bio::MAGE::Extendable>).


The value must be of type: array of C<Bio::MAGE::NameValueType>.


=item * parameters

Sets the value of the C<parameters> association

The value must be of type: array of C<Bio::MAGE::Description::OntologyEntry>.


=item * descriptions

Sets the value of the C<descriptions> association (this association was inherited from class C<Bio::MAGE::Describable>).


The value must be of type: array of C<Bio::MAGE::Description::Description>.


=item * accessions

Sets the value of the C<accessions> association

The value must be of type: array of C<Bio::MAGE::Description::DatabaseEntry>.


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

C<Bio::MAGE::BQS::BibliographicReference> has the following attribute accessor methods:

=over


=item authors

Methods for the C<authors> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setAuthors($val)

The restricted setter method for the C<authors> attribute.


Input parameters: the value to which the C<authors> attribute will be set 

Return value: the current value of the C<authors> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setAuthors {
  my $self = shift;
  croak(__PACKAGE__ . "::setAuthors: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAuthors: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__AUTHORS} = $val;
}


=item $val = $bibliographicreference->getAuthors()

The restricted getter method for the C<authors> attribute.

Input parameters: none

Return value: the current value of the C<authors> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAuthors {
  my $self = shift;
  croak(__PACKAGE__ . "::getAuthors: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__AUTHORS};
}





=back


=item URI

Methods for the C<URI> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setURI($val)

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


=item $val = $bibliographicreference->getURI()

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


=item volume

Methods for the C<volume> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setVolume($val)

The restricted setter method for the C<volume> attribute.


Input parameters: the value to which the C<volume> attribute will be set 

Return value: the current value of the C<volume> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setVolume {
  my $self = shift;
  croak(__PACKAGE__ . "::setVolume: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setVolume: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__VOLUME} = $val;
}


=item $val = $bibliographicreference->getVolume()

The restricted getter method for the C<volume> attribute.

Input parameters: none

Return value: the current value of the C<volume> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getVolume {
  my $self = shift;
  croak(__PACKAGE__ . "::getVolume: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__VOLUME};
}





=back


=item issue

Methods for the C<issue> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setIssue($val)

The restricted setter method for the C<issue> attribute.


Input parameters: the value to which the C<issue> attribute will be set 

Return value: the current value of the C<issue> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setIssue {
  my $self = shift;
  croak(__PACKAGE__ . "::setIssue: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setIssue: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__ISSUE} = $val;
}


=item $val = $bibliographicreference->getIssue()

The restricted getter method for the C<issue> attribute.

Input parameters: none

Return value: the current value of the C<issue> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getIssue {
  my $self = shift;
  croak(__PACKAGE__ . "::getIssue: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ISSUE};
}





=back


=item editor

Methods for the C<editor> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setEditor($val)

The restricted setter method for the C<editor> attribute.


Input parameters: the value to which the C<editor> attribute will be set 

Return value: the current value of the C<editor> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setEditor {
  my $self = shift;
  croak(__PACKAGE__ . "::setEditor: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setEditor: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__EDITOR} = $val;
}


=item $val = $bibliographicreference->getEditor()

The restricted getter method for the C<editor> attribute.

Input parameters: none

Return value: the current value of the C<editor> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getEditor {
  my $self = shift;
  croak(__PACKAGE__ . "::getEditor: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__EDITOR};
}





=back


=item publication

Methods for the C<publication> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setPublication($val)

The restricted setter method for the C<publication> attribute.


Input parameters: the value to which the C<publication> attribute will be set 

Return value: the current value of the C<publication> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setPublication {
  my $self = shift;
  croak(__PACKAGE__ . "::setPublication: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPublication: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__PUBLICATION} = $val;
}


=item $val = $bibliographicreference->getPublication()

The restricted getter method for the C<publication> attribute.

Input parameters: none

Return value: the current value of the C<publication> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPublication {
  my $self = shift;
  croak(__PACKAGE__ . "::getPublication: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PUBLICATION};
}





=back


=item title

Methods for the C<title> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setTitle($val)

The restricted setter method for the C<title> attribute.


Input parameters: the value to which the C<title> attribute will be set 

Return value: the current value of the C<title> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setTitle {
  my $self = shift;
  croak(__PACKAGE__ . "::setTitle: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setTitle: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__TITLE} = $val;
}


=item $val = $bibliographicreference->getTitle()

The restricted getter method for the C<title> attribute.

Input parameters: none

Return value: the current value of the C<title> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getTitle {
  my $self = shift;
  croak(__PACKAGE__ . "::getTitle: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__TITLE};
}





=back


=item publisher

Methods for the C<publisher> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setPublisher($val)

The restricted setter method for the C<publisher> attribute.


Input parameters: the value to which the C<publisher> attribute will be set 

Return value: the current value of the C<publisher> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setPublisher {
  my $self = shift;
  croak(__PACKAGE__ . "::setPublisher: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPublisher: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__PUBLISHER} = $val;
}


=item $val = $bibliographicreference->getPublisher()

The restricted getter method for the C<publisher> attribute.

Input parameters: none

Return value: the current value of the C<publisher> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPublisher {
  my $self = shift;
  croak(__PACKAGE__ . "::getPublisher: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PUBLISHER};
}





=back


=item pages

Methods for the C<pages> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setPages($val)

The restricted setter method for the C<pages> attribute.


Input parameters: the value to which the C<pages> attribute will be set 

Return value: the current value of the C<pages> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setPages {
  my $self = shift;
  croak(__PACKAGE__ . "::setPages: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setPages: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__PAGES} = $val;
}


=item $val = $bibliographicreference->getPages()

The restricted getter method for the C<pages> attribute.

Input parameters: none

Return value: the current value of the C<pages> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getPages {
  my $self = shift;
  croak(__PACKAGE__ . "::getPages: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PAGES};
}





=back


=item year

Methods for the C<year> attribute.


From the MAGE-OM documentation:




=over


=item $val = $bibliographicreference->setYear($val)

The restricted setter method for the C<year> attribute.


Input parameters: the value to which the C<year> attribute will be set 

Return value: the current value of the C<year> attribute 

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified

=cut


sub setYear {
  my $self = shift;
  croak(__PACKAGE__ . "::setYear: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setYear: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
  
  return $self->{__YEAR} = $val;
}


=item $val = $bibliographicreference->getYear()

The restricted getter method for the C<year> attribute.

Input parameters: none

Return value: the current value of the C<year> attribute 

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getYear {
  my $self = shift;
  croak(__PACKAGE__ . "::getYear: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__YEAR};
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

Bio::MAGE::BQS::BibliographicReference has the following association accessor methods:

=over


=item auditTrail

Methods for the C<auditTrail> association.


From the MAGE-OM documentation:

A list of Audit instances that track changes to the instance of Describable.


=over


=item $array_ref = $bibliographicreference->setAuditTrail($array_ref)

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


=item $array_ref = $bibliographicreference->getAuditTrail()

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




=item $val = $bibliographicreference->addAuditTrail(@vals)

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


=item $array_ref = $bibliographicreference->setPropertySets($array_ref)

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


=item $array_ref = $bibliographicreference->getPropertySets()

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




=item $val = $bibliographicreference->addPropertySets(@vals)

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


=item parameters

Methods for the C<parameters> association.


From the MAGE-OM documentation:

Criteria that can be used to look up the reference in a repository.


=over


=item $array_ref = $bibliographicreference->setParameters($array_ref)

The restricted setter method for the C<parameters> association.


Input parameters: the value to which the C<parameters> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Return value: the current value of the C<parameters> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::OntologyEntry> instances

=cut


sub setParameters {
  my $self = shift;
  croak(__PACKAGE__ . "::setParameters: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setParameters: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setParameters: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setParameters: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::OntologyEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::OntologyEntry');
    }
  }

  return $self->{__PARAMETERS} = $val;
}


=item $array_ref = $bibliographicreference->getParameters()

The restricted getter method for the C<parameters> association.

Input parameters: none

Return value: the current value of the C<parameters> association : a reference to an array of objects of type C<Bio::MAGE::Description::OntologyEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getParameters {
  my $self = shift;
  croak(__PACKAGE__ . "::getParameters: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__PARAMETERS};
}




=item $val = $bibliographicreference->addParameters(@vals)

Because the parameters association has list cardinality, it may store more
than one value. This method adds the current list of objects in the parameters association.

Input parameters: the list of values C<@vals> to add to the parameters association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::OntologyEntry>

=cut


sub addParameters {
  my $self = shift;
  croak(__PACKAGE__ . "::addParameters: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addParameters: wrong type: " . ref($val) . " expected Bio::MAGE::Description::OntologyEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::OntologyEntry');
  }

  return push(@{$self->{__PARAMETERS}},@vals);
}





=back


=item descriptions

Methods for the C<descriptions> association.


From the MAGE-OM documentation:

Free hand text descriptions.  Makes available the associations of Description to an instance of Describable.


=over


=item $array_ref = $bibliographicreference->setDescriptions($array_ref)

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


=item $array_ref = $bibliographicreference->getDescriptions()

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




=item $val = $bibliographicreference->addDescriptions(@vals)

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


=item accessions

Methods for the C<accessions> association.


From the MAGE-OM documentation:

References in publications, eg Medline and PubMed, for this BibliographicReference.


=over


=item $array_ref = $bibliographicreference->setAccessions($array_ref)

The restricted setter method for the C<accessions> association.


Input parameters: the value to which the C<accessions> association will be set : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Return value: the current value of the C<accessions> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or
if too many input parameters are specified, or if C<$array_ref> is not a reference to an array class C<Bio::MAGE::Description::DatabaseEntry> instances

=cut


sub setAccessions {
  my $self = shift;
  croak(__PACKAGE__ . "::setAccessions: no arguments passed to setter")
    unless @_;
  croak(__PACKAGE__ . "::setAccessions: too many arguments passed to setter")
    if @_ > 1;
  my $val = shift;
    croak(__PACKAGE__ . "::setAccessions: expected array reference, got $self")
    unless (not defined $val) or UNIVERSAL::isa($val,'ARRAY');
  if (defined $val) {
    foreach my $val_ent (@{$val}) {
      croak(__PACKAGE__ . "::setAccessions: wrong type: " . ref($val_ent) . " expected Bio::MAGE::Description::DatabaseEntry")
        unless UNIVERSAL::isa($val_ent,'Bio::MAGE::Description::DatabaseEntry');
    }
  }

  return $self->{__ACCESSIONS} = $val;
}


=item $array_ref = $bibliographicreference->getAccessions()

The restricted getter method for the C<accessions> association.

Input parameters: none

Return value: the current value of the C<accessions> association : a reference to an array of objects of type C<Bio::MAGE::Description::DatabaseEntry>

Side effects: none

Exceptions: will call C<croak()> if any input parameters are specified

=cut


sub getAccessions {
  my $self = shift;
  croak(__PACKAGE__ . "::getAccessions: arguments passed to getter")
    if @_;
  my $val = shift;
  return $self->{__ACCESSIONS};
}




=item $val = $bibliographicreference->addAccessions(@vals)

Because the accessions association has list cardinality, it may store more
than one value. This method adds the current list of objects in the accessions association.

Input parameters: the list of values C<@vals> to add to the accessions association. B<NOTE>: submitting a single value is permitted.

Return value: the number of items stored in the slot B<after> adding C<@vals>

Side effects: none

Exceptions: will call C<croak()> if no input parameters are specified, or if any of the objects in @vals is not an instance of class C<Bio::MAGE::Description::DatabaseEntry>

=cut


sub addAccessions {
  my $self = shift;
  croak(__PACKAGE__ . "::addAccessions: no arguments passed to adder")
    unless @_;
  my @vals = @_;
    foreach my $val (@vals) {
    croak(__PACKAGE__ . "::addAccessions: wrong type: " . ref($val) . " expected Bio::MAGE::Description::DatabaseEntry")
      unless UNIVERSAL::isa($val,'Bio::MAGE::Description::DatabaseEntry');
  }

  return push(@{$self->{__ACCESSIONS}},@vals);
}





=back


=item security

Methods for the C<security> association.


From the MAGE-OM documentation:

Information on the security for the instance of the class.


=over


=item $val = $bibliographicreference->setSecurity($val)

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


=item $val = $bibliographicreference->getSecurity()

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

