package Business::OnlinePayment::PPIPayMover::CreditCardResponse;

use strict;
use vars qw(@ISA);
use Business::OnlinePayment::PPIPayMover::TransactionResponse;
use Business::OnlinePayment::PPIPayMover::PayerAuthenticationResponse;
use Business::OnlinePayment::PPIPayMover::constants;

@ISA = qw(Business::OnlinePayment::PPIPayMover::TransactionResponse);

sub new {
  my $class = shift;
  my $InString = shift;
  my $self = $class->SUPER::new($InString);
   
  $self->{oPayerAuthenticationResponse} = undef;
  $self->{strReferenceId} = undef;
  $self->{strBatchId} = undef;
  $self->{strBankTransactionId} = undef;
  $self->{strBankApprovalCode} = undef;
  $self->{strState} = undef;
  $self->{strAuthorizedAmount} = undef;
  $self->{strOriginalAuthorizedAmount} = undef;
  $self->{strCapturedAmount} = undef;
  $self->{strCreditedAmount} = undef;
  $self->{strTimeStampCreated} = undef;
  $self->{strOrderId} = undef;
  $self->{strIsoCode} = undef;
  $self->{strAVSCode} = "None";    # v1.5
  $self->{strCreditCardVerificationResponse} = undef;
  
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
  
  # Looking to see if there is a nested Payer Authentication Response
  my $payerAuthResponse = new Business::OnlinePayment::PPIPayMover::TransactionResponse($InString,AUTHENTICATION_PREFIX);
  
  if (defined($payerAuthResponse->GetResponseCode)){
  	$self->{oPayerAuthenticationResponse} = new Business::OnlinePayment::PPIPayMover::PayerAuthenticationResponse($InString,AUTHENTICATION_PREFIX);
  }
  
  my $name;
  my $value;
  foreach (@temp) {
  
    ($name, $value) = split(/=/, $_, 2);
    
    if ($name eq "capture_reference_id") {
      $self->{strReferenceId} = $value;
    }
    elsif ($name eq "order_id") {
      $self->{strOrderId} = $value;
    }
    elsif ($name eq "iso_code") {
      $self->{strIsoCode} = $value;
    }
    elsif ($name eq "bank_approval_code") {
      $self->{strBankApprovalCode} = $value;
    }
    elsif ($name eq "state") {
      $self->{strState} = $value;
    }
    elsif ($name eq "authorized_amount") {
      $self->{strAuthorizedAmount} = $value;
    }
    elsif ($name eq "original_authorized_amount") {
      $self->{strOriginalAuthorizedAmount} = $value;
    }
    elsif ($name eq "captured_amount") {
      $self->{strCapturedAmount} = $value;
    }
    elsif ($name eq "credited_amount") {
      $self->{strCreditedAmount} = $value;
    }
    elsif ($name eq "time_stamp_created") {
      $self->{strTimeStampCreated} = $value;
    }
    elsif ($name eq "bank_transaction_id") {
      $self->{strBankTransactionId} = $value;
    }
    elsif ($name eq "batch_id") {
      $self->{strBatchId } = $value;
    }
    elsif ($name eq "avs_code") {
      $self->{strAVSCode} = $value;
    }
    elsif ($name eq "credit_card_verification_response") {
      $self->{strCreditCardVerificationResponse} = $value;
    }
    else {
      $self->{strError} .= "Invalid data name: ";
    }
  }
  return $self;
}


sub GetBatchId
{
  my $self = shift;
  $self->{strBatchId};
}

sub GetBankTransactionId
{
  my $self = shift;
  $self->{strBankTransactionId};
}

sub GetBankApprovalCode
{
  my $self = shift;
  $self->{strBankApprovalCode};
}

sub GetState
{
  my $self = shift;
  $self->{strState};
}

sub GetAuthorizedAmount
{
  my $self = shift;
  $self->{strAuthorizedAmount};
}

sub GetOriginalAuthorizedAmount
{
  my $self = shift;
  $self->{strOriginalAuthorizedAmount};
}

sub GetCapturedAmount
{
  my $self = shift;
  $self->{strCapturedAmount};
}

sub GetCreditedAmount
{
  my $self = shift;
  $self->{strCreditedAmount};
}

sub GetTimeStampCreated
{
  my $self = shift;
  $self->{strTimeStampCreated};
}

sub GetOrderId
{
  my $self = shift;
  $self->{strOrderId};
}

sub GetIsoCode
{
  my $self = shift;
  $self->{strIsoCode};
}

sub GetCaptureReferenceId
{
  my $self = shift;
  $self->{strReferenceId};
}

sub GetReferenceId
{
  my $self = shift;
  $self->{strReferenceId};
}

sub GetAVSCode {
    my $self = shift;
    $self->{strAVSCode};
}

sub GetCreditCardVerificationResponse {
    my $self = shift;
    $self->{strCreditCardVerificationResponse};
}

sub GetPayerAuthenticationResponse {
    my $self = shift;
    $self->{oPayerAuthenticationResponse};
}
