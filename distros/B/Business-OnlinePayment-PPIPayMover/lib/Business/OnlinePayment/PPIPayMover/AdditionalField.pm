
# * AdditionalFields are used to hold fields that do not have separate
# * specifications. Each AdditionalField consists of a name and a value,
# * which are set in the constructor and are retrieved using the get methods.
# * <P>
# * TransactionRequests (including CreditCardRequests) hold
# * a Vector of AdditionalField objects to permit them to be
# * interoperable with future releases.
# * <P>
# * @see TransactionRequest#setAdditionalField
# * @see TransactionRequest#setAdditionalFields
# */


#*
# * Make an AdditionalField object with the given name and value.
# * <P>
# * @param name Must not be NULL or "". May not contain ' ', '=', or '+'.
# */

use strict;
#use overload;
package Business::OnlinePayment::PPIPayMover::AdditionalField;
use overload
'== ' => \&equals;
my $paramSeparator = "&";

sub new {
  my $class = shift;
  my $self = {};
  my ($name, $value) = @_;  # name and value as two arguements
  $self->{strError} = "";
  if (!$name || $name eq "" ) {
    $self->{strError} .= "AdditionalField constructor: must provide a name";
  }
  if (!$value || $value eq "") {
    $self->{strError} .= "AdditionalField constructor: must provide a value";
  }
  if (index($name, " ") != -1 || index($name, "=") != -1) {
    $self->{strError} .= "AdditionalField constructor: name may not contain space or =";
  }
  if (index($value, " ") != -1 || index($value, "=") != -1) {
    $self->{strError} .= "AdditionalField constructor: value may not contain space or =";
  }
  if (index($value, "+") != -1) {
    $self->{strError} .= "AdditionalField constructor: value may not contain +";
  }
  if (defined $name) { $self->{name} = $name }
  if (defined $value) { $self->{value} = $value }
  
  bless $self, $class;
}

#**
# * Get the name associated with this AdditionalField object.
# * <P>
# * @return The name of the additional field.
#
sub getName {
  my $self = shift;
  $self->{name};
}

#**
# * Get the value associated with this AdditionalField object.
# * <P>
# * @return The value of the additional field.
#
sub getValue {
  my $self = shift;
  $self->{value};
}

sub getError {
  my $self = shift;
  $self->{strError};
}

#**
# * This method only checks the name field. This is ok because
# * a TransactionRequest is not allowed to have two AdditionalField
# * objects with the same name.
#
sub equals {
  my $self = shift;
  my $other = shift;
  if($self->{name} eq $other->getName) { return 1 }
  else { return 0 };
}


sub write {
  my $self = shift;
  my $outString = shift;
  $self->{value} =~ tr/ /+/;
  $$outString .= $self->{name};
  $$outString .= "=";
  $$outString .= $self->{value};
  $$outString .= $paramSeparator;
}

1;
