##############################
#
# Bio::MAGE::Tools::MGEDOntologyEntry
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

package  Bio::MAGE::Tools::MGEDOntologyEntry;

use strict;
use Carp;

use vars qw($VERSION);

use base qw(Bio::MAGE::Description::OntologyEntry);

$VERSION = 2006_08_16.0;

=head1 Bio::MAGE::Tools::MGEDOntologyEntry

=head2 SYNOPSIS

  Bio::MAGE::Tools::MGEDOntologyEntry is an abstract class.

  Superclass is:
    Bio::MAGE::Tools::OntologyEntry

  Subclasses are:
    Bio::MAGE::Tools::MGEDOntologyClassEntry
    Bio::MAGE::Tools::MGEDOntologyPropertyEntry

=head2 DESCRIPTION

This is an abstract class for MGEDOntologyClassEntry and
MGEDOntologyPropertyEntry with very little mind of its own.

=cut


###############################################################################
#
# Constructor
#
###############################################################################

# Constructor is inherited from Base.pm



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

=item isAssignable

Stores whether the represented MGED Ontology concept needs to get a
value assigned before use or not.  (static feature)

=cut


###############################################################################
# setIsAssignable
###############################################################################
sub setIsAssignable {
  my $self = shift;
  my $attributeName = 'isAssignable';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getIsAssignable
###############################################################################
sub getIsAssignable {
  my $self = shift;
  my $attributeName = 'isAssignable';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item isAssigned

Stores whether an assignable concept has been assigned a value or not
(dynamic feature)

=cut


###############################################################################
# setIsAssigned
###############################################################################
sub setIsAssigned {
  my $self = shift;
  my $attributeName = 'isAssigned';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getIsAssigned
###############################################################################
sub getIsAssigned {
  my $self = shift;
  my $attributeName = 'isAssigned';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item errorMessage

Stores a possible error message that arose while trying to set the category
or more likely value attributes of this class.

=cut


###############################################################################
# setErrorMessage
###############################################################################
sub setErrorMessage {
  my $self = shift;
  my $attributeName = 'errorMessage';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getErrorMessage
###############################################################################
sub getErrorMessage {
  my $self = shift;
  my $attributeName = 'errorMessage';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}


=item assignableValues

Stores the list of values that can be assigned to this category

=cut


###############################################################################
# SetAssignableValues
###############################################################################
sub setAssignableValues {
  my $self = shift;
  my $attributeName = 'assignableValues';
  my $methodName = 'set'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: no arguments passed to setter")
    unless @_;
  confess(__PACKAGE__ . "::$methodName: too many arguments passed to setter")
    if @_ > 1;

  my $val = shift;

  return $self->{"__$attributeName"} = $val;
}


###############################################################################
# getAssignableValues
###############################################################################
sub getAssignableValues {
  my $self = shift;
  my $attributeName = 'assignableValues';
  my $methodName = 'get'.ucfirst($attributeName);

  confess(__PACKAGE__ . "::$methodName: arguments passed to getter")
    if @_;

  return $self->{"__$attributeName"};
}



###############################################################################
#
# Methods that should be in overridden in subclasses
#
###############################################################################


###############################################################################
# assignValue
###############################################################################
sub assignValue {
  die("ERROR: Method assignValue must be overridden in subclass");
}


###############################################################################
#
# Regular methods
#
###############################################################################





###############################################################################

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

