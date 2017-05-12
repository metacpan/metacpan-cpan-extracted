use strict;
package Business::OnlinePayment::PPIPayMover::TransactionClient;
use Business::OnlinePayment::PPIPayMover::TransactionResponse;
use Business::OnlinePayment::PPIPayMover::TransactionRequest;
use Business::OnlinePayment::PPIPayMover::CreditCardRequest;
use Business::OnlinePayment::PPIPayMover::CreditCardResponse;
use Business::OnlinePayment::PPIPayMover::SecureHttp;
use Business::OnlinePayment::PPIPayMover::constants;
1;

# default constructor
sub new  {
  my $class = shift;
  my $self = {};
  $self->{strError} = "";
  $self->{strResponse} = "";
  bless $self, $class;
  return $self;
}

sub doTransaction # take three arguements
{
  my $self = shift;
  my $TransactionKey = shift; # the first arguement(string)
  my $transReq = shift; # the second arguement(class object)
  my $AccountToken = shift; # the third arguement(string)
  
  my $PostString = "";
  my $ResponseString = "";
  
  # write out account_token ...
  $PostString .= "account_token=$AccountToken";
  $PostString .= "&";
  
  # write out transaction_key ...
  #$PostString .= "transaction_key=$TransactionKey";
  #$PostString .= "&";
  
  # write out version_id ...
  my $temp = VERSION;
  $temp =~ tr/ /+/;
  $PostString .= "version_id=$temp";
  $PostString .= "&";
 
  $transReq->WriteRequest(\$PostString); # get post information
  
  my $ResponseContent;
  my $secureHttp = new Business::OnlinePayment::PPIPayMover::SecureHttp;
  my $strServer = PAY_HOST;
  my $strPath = PAY_HOST_PATH;
  my $iPort = PAY_HOST_PORT;
  
  
  if(!$secureHttp->Init) {
    $self->{strError} = $secureHttp->GetErrorString;
    return undef;
  }
  
  if(!$secureHttp->Connect($strServer, $iPort)) {
    $self->{strError} = $secureHttp->GetErrorString;
    return undef;
  }
  if(!$secureHttp->DoSecurePost($strPath, $PostString, \$self->{strResponse})) {
    $self->{strError} .= $secureHttp->GetErrorString;
    return undef;
  }
  
  $secureHttp->DisconnectFromServer;
  $secureHttp->CleanUp;
  
  my $i = index($self->{strResponse}, "response_code");
  if($i>=0) {
    $ResponseContent = substr($self->{strResponse}, $i);
    return $transReq->GetTransResponseObject(\$ResponseContent);
  }
  else {
    return undef;
  }
}



sub GetErrorString
{
  my $self = shift;
  return $self->{strError};
}

#JString TransactionClient::GetResponseString()
#{
#	return m_jstrResponse;
#}
