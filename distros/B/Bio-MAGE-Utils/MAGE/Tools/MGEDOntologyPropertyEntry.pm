##############################
#
# Bio::MAGE::Tools::MGEDOntologyPropertyEntry
#
##############################
# C O P Y R I G H T   N O T I C E
#  Copyright (c) 2001-2002 by:
#    * The MicroArray Gene Expression Database Society (MGED)
#    * Rosetta Inpharmatics
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

package  Bio::MAGE::Tools::MGEDOntologyPropertyEntry;

use strict;
use Carp;
use Bio::MAGE::Base;
use Bio::MAGE::Association;
use Bio::MAGE::Extendable;


use vars qw($VERSION $DEBUG);

# Inherit methods from superclass
use base qw(Bio::MAGE::Tools::MGEDOntologyEntry);

$VERSION = 2006_08_16.1;

=head1 Bio::MAGE::Tools::MGEDOntologyPropertyEntry

=head2 SYNOPSIS

Bio::MAGE::Tools::MGEDOntologyPropertyEntry is a concrete class.

  Superclass is:
    Bio::MAGE::Tools::MGEDOntologyEntry

  Subclasses are:
    none

=head2 DESCRIPTION

This provides functionaliy for an ontology-aware OntologyEntry class
for entries of type Property.

=cut

$DEBUG = 0;

###############################################################################
#
# Constructor
#
###############################################################################
sub new {
  my $class = shift;
  if (ref($class)) {
    $class = ref($class);
  }
  my $self = bless {}, $class;

  my %args = @_;

  #### Create this entry and all possible children
  $self->createEntry(%args);

  return $self;
}



###############################################################################
#
# Getter and Setter methods for class attributes
#
###############################################################################

=head2 ATTRIBUTES

Attributes are simple data types that belong to a single instance of a
class. In the Perl implementation of the MAGE-OM classes, the
interface to attributes is implemented using separate setter and
getter methods for each attribute.

=over

=item propertyType

Store the type of the property

=cut


###############################################################################
# setPropertyType
###############################################################################
sub setPropertyType {
  my $self = shift;
  my $attributeName = 'propertyType';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getPropertyType
###############################################################################
sub getPropertyType {
  my $self = shift;
  my $attributeName = 'propertyType';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item mgedOntologyProperty

Stores the name of the equivalent class or property in the MGED
Ontology for this OntologyEntry

=cut


###############################################################################
# setMgedOntologyProperty
###############################################################################
sub setMgedOntologyProperty {
  my $self = shift;
  my $attributeName = 'mgedOntologyProperty';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getMgedOntologyProperty
###############################################################################
sub getMgedOntologyProperty {
  my $self = shift;
  my $attributeName = 'mgedOntologyProperty';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}



###############################################################################
#
# Regular methods
#
###############################################################################

###############################################################################
# createEntry
###############################################################################
sub createEntry {
  my $self = shift || die ("self not passed");

  my %args = @_;
  my $propertyName = $args{'propertyName'} || die "ERROR: propertyName not passed";
  my $propertyType = $args{'propertyType'} || die "ERROR: propertyType not passed";
  my $values = $args{'values'} || die("ERROR: values not passed");
  my $usedValues = $args{'usedValues'};
  my $ontology = $args{'ontology'} || die "ERROR: ontology not passed";

  #### Store the parameters in the class attributes
  $self->setMgedOntologyProperty($propertyName);
  $self->setPropertyType($propertyType);

  $DEBUG && print STDERR "DEBUG: Entering [MGEDOntologyPropertyEntry] $propertyName,$propertyType\n";

  if ($ontology->classExists($propertyType)) {
    ## Filler is a MGED Ontology Class
    #print "  This is a class\n";
    $self->setIsAssignable(0);

    $self->setCategory($self->getMgedOntologyProperty());
    $self->setValue($self->getMgedOntologyProperty());
    $self->setOntologyReference($ontology->getOntologyReference($self->getMgedOntologyProperty()));

    #$self->addToAssociations(new MGEDOntologyClassEntry($propertyType,$ontology));
    $DEBUG && print STDERR "  Create new ClassEntry of name $propertyType\n";
    my $childObject = Bio::MAGE::Tools::MGEDOntologyClassEntry->new(
      className => $propertyType,
      values => $values,
      usedValues => $usedValues,
      ontology => $ontology,
    );
    $self->addAssociations($childObject);
    $DEBUG && print STDERR "  Add to parent\n";


  } elsif ($propertyType eq "enum") {
    ## Filler is of the type one-of

    $self->setIsAssignable(1);

    $self->setCategory($self->getMgedOntologyProperty());

    ## need to be able to store possible choises
    my @assignableValues = $ontology->getEnumValues($self->getMgedOntologyProperty());
    $self->setAssignableValues(\@assignableValues);

    #### Create all the structure below this using $ontology
    $self->setOntologyReference($ontology->getOntologyReference("placeholder"));

  } elsif ($propertyType eq "any" || $propertyType eq "?") {
    ## Filler is thing, int etc.

    $self->setIsAssignable(0);

    ## adjust method names to prevailing style in class (jaw)
    #$self->set_category($self->getMgedOntologyProperty());
    #$self->set_value($self->getMgedOntologyProperty());
    $self->setCategory($self->getMgedOntologyProperty());

    # FIXME presumably we need to deal with potential subclasses here as well (string values only at the moment)...
    $self->setValue($values->{$propertyName});
#    $self->setOntologyReference($ontology->getOntologyReference($self->getMgedOntologyProperty()));

#    $self->addToAssociations(Bio::MAGE::Tools::MGEDOntologyPropertyEntry($self->getMgedOntologyProperty(), "thingFiller",
#									     $ontology));

  } elsif ($propertyType eq "thingFiller") {
    ## Thing filler
    $self->setIsAssignable(1);

    ## Fix java style setter.(jaw)
    $self->setCategory($self->getMgedOntologyProperty());
    ## Add missing call to set_value (jaw)
    $self->setValue($self->getMgedOntologyProperty());
    ## No MO reference
  }


  return 1;

}



###############################################################################
# assignValue
###############################################################################
sub assignValue {
  my $self = shift || die ("self not passed");
  my $val = shift;

  if ($self->getIsAssignable && !$self->getIsAssigned) {

    if ($self->getPropertyType() eq "enum" && grep(/^$val$/,@{$self->getAssignableValues()})) {

      $self->setValue($val);

      ## Correct the temporary MO DB reference
      my $ontologyReference = $self->getOntologyReference();
      $ontologyReference->setAccession("#$val");
      my $URI = $ontologyReference->getURI();
      $URI =~ s/placeholder/$val/;
      $ontologyReference->setURI($URI);

    } elsif ($self->getPropertyType() eq "thingFiller") {
      $self->setValue($val);
    }

    $self->setIsAssigned(1);
  }
}






=head1 BUGS

Please send bug reports to mged-mage@lists.sf.net

=head1 AUTHOR

Eric W. Deutsch (edeutsch@systemsbiology.org)

=head1 SEE ALSO

perl(1).

=cut

#
# End the module by returning a true value
#
1;

