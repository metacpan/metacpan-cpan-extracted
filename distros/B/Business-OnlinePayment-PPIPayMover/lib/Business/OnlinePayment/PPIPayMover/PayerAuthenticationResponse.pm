package Business::OnlinePayment::PPIPayMover::PayerAuthenticationResponse;

use strict;
use vars qw(@ISA);
use Business::OnlinePayment::PPIPayMover::TransactionResponse;
use Business::OnlinePayment::PPIPayMover::constants;

@ISA = qw(Business::OnlinePayment::PPIPayMover::TransactionResponse);

sub new {
  my $class = shift;
  my @param = @_;
  my $paramNo = @param;
  
  my $InString = shift;
  my $prefix = "";
    
  if( $paramNo == 2){
    $prefix = shift;
  }
  my $self = $class->SUPER::new($InString,$prefix);
  
  $self->{strAuthenticationTransactionId} = "";
  $self->{strLookupPayload} = "";
  $self->{strHiddenFields} = "";
  $self->{strOrderId} = "";
  $self->{strAuthenticationURL} = "";
  $self->{strCavv} = "";
  $self->{strXID} = "";
  $self->{strStatus} = "";
  $self->{strTransactionConditionCode} = "";
  if ($self->{iResponseCode} == TRANSACTION_SERVER_ERROR || $self->{iResponseCode} == INVALID_VERSION) {
    return $self;
  }
  if (!($$InString) && !($self->{iResponseCode} == SUCCESSFUL_TRANSACTION)) {
    return $self;
  }
  
  my @temp = split(/\n/, $$InString);
  my $size = @temp;
  if ($size < 10) {
    $self->{strError} .= "input string is in wrong format";
    $self->{iRetVal} = 0;
    return $self;
  }
  #splice(@temp, 0, 4);
  my $name;
  my $value;
  foreach (@temp) {
  
    # Anything after the first = is part
    # of the value (including other ='s)
    ($name, $value) = split(/=/, $_, 2);
    
    if ($name eq $prefix."authentication_transaction_id") {
      $self->{strAuthenticationTransactionId} = $value;
    }
    elsif ($name eq $prefix."lookup_payload") {
      $self->{strLookupPayload} = $value;
    }
    elsif ($name eq $prefix."hidden_fields") {
      $self->{strHiddenFields} = $value;
    }
    elsif ($name eq $prefix."order_id") {
      $self->{strOrderId} = $value;
    }
    elsif ($name eq $prefix."authentication_url") {
      $self->{strAuthenticationURL} = $value;
    }
    elsif ($name eq $prefix."cavv") {
      $self->{strCavv } = $value;
    }
    elsif ($name eq $prefix."x_id") {
      $self->{strXID} = $value;
    }
    elsif ($name eq $prefix."status") {
      $self->{strStatus} = $value;
    }
    elsif ($name eq $prefix."transaction_condition_code") {
          $self->{strTransactionConditionCode} = $value;
    }
    else {
      $self->{strError} .= "Invalid data name: ";
    }
  }
  return $self;
}


sub GetAuthenticationTransactionId
{
  my $self = shift;
  $self->{strAuthenticationTransactionId};
}

sub GetLookupPayload
{
  my $self = shift;
  $self->{strLookupPayload};
}

sub GetHiddenFields
{
  my $self = shift;
  $self->{strHiddenFields};
}

sub GetOrderId
{
  my $self = shift;
  $self->{strOrderId};
}

sub GetAuthenticationURL
{
  my $self = shift;
  $self->{strAuthenticationURL};
}

sub GetCavv
{
  my $self = shift;
  $self->{strCavv};
}

sub GetXID
{
  my $self = shift;
  $self->{strXID};
}

sub GetStatus {
    my $self = shift;
    $self->{strStatus};
}

sub GetTransactionConditionCode {
    my $self = shift;
    $self->{strTransactionConditionCode};
}
