use strict;
package Business::OnlinePayment::PPIPayMover::TransactionResponse;
use Business::OnlinePayment::PPIPayMover::constants;
1;

sub new {
  my $class = shift;
  my @param = @_;
  my $paramNo = @param;
  my $self = {};
  bless $self, $class;
  
  $self->{strError} = "";
  $self->{iRetVal} = undef;
  $self->{iResponseCode} = undef;
  $self->{strResponseCode} = undef;
  $self->{strResponseCodeText} = undef;
  $self->{strTimeStamp} = undef;
  $self->{bRetryRecommended} = undef;
  
  
# constructor for only one or two string arguement
  if ($paramNo == 1 || $paramNo == 2) {
    my $InString = shift;
    my $prefix = "";
    
    if($paramNo == 2){
    	$prefix = shift;
    }
    
    if ($$InString eq "") {
      $self->{strError} .=  "Empty response string";
      $self->{iRetVal} = 0;
      return $self;
    }
    my @tmp;
    @tmp = split(/\n/, $$InString);
        
    my $name;
    my $value;
    foreach (@tmp) {
    
      # Anything after the first = is part
      # of the value (including other ='s)
      ($name, $value) = split(/=/, $_, 2);
      
      if (index($name, "<") == 0) {
        $self->{strError} .= "Server not available";
        $self->{iRetVal} = 0;
        
        $self->{iResponseCode} = TRANSACTION_SERVER_ERROR;
        $self->{strResponseCode} = "".$self->{iResponseCode};
        $self->{strResponseCodeText} = "The Transaction Server is currently not available";
        return $self;
      }

      if ($name eq $prefix."response_code") {
        
        if($value.""  eq "0" || $value."" eq "") {
          $self->{strError} .= "Invalid response code";
          $self->{iRetVal} = 0;
          return $self;
        }
        else  {
          $self->{strResponseCode} = $value;
          $self->{iResponseCode} = 1 * $value;
        }
      }
      elsif ($name eq $prefix."response_code_text"){
        $self->{strResponseCodeText} = $value;
      }
      elsif ($name eq $prefix."time_stamp") {
        $self->{strTimeStamp} = $value;
      }
      elsif ($name eq $prefix."retry_recommended") {
        if ($value eq "true") {
          $self->{bRetryRecommended} = 1;
        }
        elsif ($value eq "false") {
          $self->{bRetryRecommended} = 0;
        }
        else {
          $self->{strError} .= "invalid retry flag";
          return $self;
        }
      }
      else {
        $self->{strError} .= "Invalid data name: ";
      }
    }
  }
  
# constructor for 4 arguements. More arguements are ignored
# (1) ResponseCode(integer), (2) ResponseCodeText(string), (3) TimeStamp(string),
# (4) RetryRecommended(bool: 1 or 0  in the form of integer)
  
  elsif ($paramNo >= 4) {
    my ($iResponseCode, $strResponseCodeText, $strTimeStamp, $bRetryRecommended) = @param[0..3];
    if (!defined($iResponseCode) || $iResponseCode < 1 || !defined($strResponseCodeText) ||
      !defined($strTimeStamp) || !defined($bRetryRecommended)) {
      $self->{strError} .= "Wrong parameter";
      return $self;
    }
    $self->{iResponseCode} = $iResponseCode;
    $self->{strResponseCode} = "".$iResponseCode;
    $self->{strResponseCodeText} = $strResponseCodeText;
    $self->{strTimeStamp} = $strTimeStamp;
    $self->{bRetryRecommended} = $bRetryRecommended;
  }
  else {
    $self->{strError} .= "Parameter number is only $paramNo and more are needed";
    return $self;
  }
  return $self;
}


sub GetError {
  my $self = shift;
  $self->{strError};
}
sub GetResponseCode {
  my $self = shift;
  $self->{iResponseCode};
}

sub GetResponseCodeStrVal {
  my $self = shift;
  $self->{strResponseCode};
}

sub GetResponseCodeText{
  my $self = shift;
  $self->{strResponseCodeText};
}

sub GetTimeStamp {
  my $self = shift;
  $self->{strTimeStamp};
}

sub GetRetryRecommended {
  my $self = shift;
  $self->{bRetryRecommended};
}


sub WriteResponse {
  my $self = shift;
  my $outString = shift;
  
  $self->{strResponseCodeText} =~ tr/\n/ /;
  $self->{strTimeStamp} =~ tr/\n/ /;
  $$outString .= "response_code=";
  $$outString .= $self->{strResponseCode};
  $$outString .= "\n";
  $$outString .= "response_code_text=";
  $$outString .= $self->{strResponseCodeText};
  $$outString .= "\n";
  $$outString .= "time_stamp=";
  $$outString .= $self->{strTimeStamp};
  $$outString .= "\n";
  
  if ($self->{bRetryRecommended}) {
    $$outString .= "retry_recommended=true\n";
  }
  else {
    $$outString .= "retry_recommended=false\n";
  }
  return CCR_NO_ERROR;
}
