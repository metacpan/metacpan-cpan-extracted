use strict;
package Business::OnlinePayment::PPIPayMover::TransactionRequest;
use Business::OnlinePayment::PPIPayMover::constants;
use Business::OnlinePayment::PPIPayMover::AdditionalField;
use Business::OnlinePayment::PPIPayMover::TransactionResponse;
1;

sub new {
  my $class = shift;
  my $self = {};
  $self->{AdditionalFields} = [];
  $self->{strError} = "";
  $self->{strParamSeparator} = "&";
  
  bless $self, $class;
  return $self;
}


# *
# * A method to add a single additional field to the TransactionRequest or TransactionRequest subclass
# * (such as CreditCardRequest).
# * <P>
# * @param additionalField An AdditionalField object containing a name and a value. The name must be
# * unique. That is, one TransactionRequest object can contain only one additional field with a given name.
# * <P>
# * @see AdditionalField
# */
sub SetAdditionalField {
  my $self = shift;
  my $additionalField = shift; # take only one AdditionalField object arguement
  foreach (@{$self->{AdditionalFields}}) {
    if ($additionalField->equals($_)) {
      $self->{strError} .= "TransactionRequest.setAddtionalField: name already used";
      return CCR_ERROR;
    }
  }
  ${$self->{AdditionalFields}}[$#{$self->{AdditionalFields}} + 1] = $additionalField;
  return CCR_NO_ERROR;
}


#**
# * A method to add multiple additional fields to the TransactionRequest or TransactionRequest subclass
# * (such as CreditCardRequest).
# * <P>
# * @param additionalFields An Vector of AdditionalField objects, each containing a name and a value.
# * The parameter cannot be NULL and the Vector must be non-empty.
# * <P>
# * @see AdditionalField
# */
sub SetAdditionalFields {
  my $self = shift;
  my $additionalFields = shift; # take one AdditionalField array arguement
  my $size = @$additionalFields;
  if ($size == 0) {
    $self->{strError} .= "TransactionRequest.setAdditionalFields passed empty vector";
    return CCR_ERROR;
  }
  
  foreach (@$additionalFields) {
    if (defined($_)) {$self->SetAdditionalField($_)}
  }
  
  return CCR_NO_ERROR;
}

#**
# * A method to retrieve an additional field
# * @return Returns an AdditionalField object or NULL if name is unkown
# */
sub GetAdditionalField {
  my $self = shift;
  my $name = shift; # use name as arguement to get additional field arguememt
  foreach (@{$self->{AdditionalFields}}) {
    if ($name = $_->getName) { return $_ }
  }
  return undef;
}


#**
# * A method to retrieve a Vector of AdditionalField objects
# * @return Returns a Vector of AdditionalField objects or NULL
# */
sub GetAdditionalFields{
  my $self = shift;
  return @{$self->{AdditionalFields}};
}


#**
# * A method for Transaction Server developers that is not used by merchant developers.
# * <P>
# * This method should be overwritten by subclasses, but the subclasses
# * version of this method MUST CALL super.writeRequest(out).
# */
sub WriteRequest {
  my $self = shift;
  my $PostString = shift; #arguement as a pointer to string
  my $size = @{$self->{AdditionalFields}};
  if ($size == 0) {
    return CCR_ERROR;
  }
  
  foreach (@{$self->{AdditionalFields}}) {
    if (defined($_)) {
      $_->write($PostString);
    }
  }
  return CCR_NO_ERROR;
}

sub GetTransResponseObject {
  my $self = shift;
  my $InString = shift; # use one string arguement
  return new Business::OnlinePayment::PPIPayMover::TransactionResponse($InString);
}
