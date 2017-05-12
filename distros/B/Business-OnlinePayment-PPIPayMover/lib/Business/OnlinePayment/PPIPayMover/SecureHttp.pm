use strict;
package Business::OnlinePayment::PPIPayMover::SecureHttp;
use Socket;
use Net::SSLeay qw(die_now die_if_ssl_error) ;
1;

# constuctor
sub new
{
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->{ctx} = undef;
  $self->{ssl} = undef;
  $self->{strError} = ""; 
  return $self;
}

sub Init
{
  my $self = shift;  
  
  Net::SSLeay::load_error_strings();
  Net::SSLeay::ERR_load_crypto_strings();
  Net::SSLeay::SSLeay_add_ssl_algorithms();
  Net::SSLeay::randomize();
  
  $self->{ctx} = Net::SSLeay::CTX_new();
  if(!$self->{ctx}) {
      $self->{strError} .= "Failed to create SSL_CTX. \n" .
         "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
      return 0;
  }
  
  if(!Net::SSLeay::CTX_set_options($self->{ctx}, &Net::SSLeay::OP_ALL)) {
      # For some reason the if statement above always returns false,
      # but SSLeay reports no error.  Ignore this error, since
      # everything still works fine.
      #
      #$self->{strError} .= "Failed to set SSL_CTX options. \n" .
      #   "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error) . "\n";
  }
  
  $self->{ssl} = Net::SSLeay::new($self->{ctx});
  if(!$self->{ssl}) {
      $self->{strError} .= "Failed to create an SSL. \n" .
         "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
      return 0;
  }
  
  return 1;
}

sub Connect
{
  my $self = shift;
  my ($destServer, $port) = @_;
  $port = getservbyname($port, 'tcp') unless $port =~ /^\d+$/;
  
  my $destIp = gethostbyname ($destServer);
  if(!defined($destIp)) { 
      $self->{strError} .= "Couldn't resolve host name (gethostbyname) using host: $destServer\n";
      return 0;
  } 
  
  my $destServerSockAddr = sockaddr_in($port, $destIp);
  
  if(!socket (S, AF_INET, SOCK_STREAM, 0)) {
      $self->{strError} .= "Failed to create a socket. $!";
      return 0;
  }
  
  if(!connect (S, $destServerSockAddr)) {
      $self->{strError} .= "Failed to connect. $!";
      return 0;
  }
  
  select (S); $| = 1; select (STDOUT);   # Eliminate STDIO buffering
  Net::SSLeay::set_fd($self->{ssl}, fileno(S));   # Must use fileno
  if (! Net::SSLeay::connect($self->{ssl})) {
    $self->{strError} .= "Failed to make an ssl connect. \n" .
      "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
     return 0;
  }
  
  return 1;
}

sub DoSecurePost
{
  my $self = shift;
  my ($strPath, $strContent, $Response) = @_;
  my $PostString = "POST ";
  $PostString .= $strPath;
  $PostString .= " HTTP/1.0\r\nContent-Type: application/x-www-form-urlencoded\r\n";
  $PostString .= "Content-Length: ";
  $PostString .= length($strContent);
  $PostString .= "  \r\n\r\n";
  $PostString .= $strContent;
  
  if(!Net::SSLeay::ssl_write_all($self->{ssl}, $PostString)) {
      $self->{strError} .= "Failed to write. " .
         "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
    return 0;
  }
  
  shutdown S, 1;  # Half close --> No more output, sends EOF to server

  if( $^O eq "MSWin32" ) {
    # Windows doesn't implement ALRM signal, 
    # so don't use a timeout.  
    # May hang client system.
    $$Response = Net::SSLeay::ssl_read_all($self->{ssl});
  } else {
    # This block uses the alarm signal
    # to see if the server times out responding.
    eval {
      local $SIG{ ALRM } = sub {
        $self->{strError} .= "Server timed out.";
        close S;
      };
      alarm 270;    # Alarm on 4.5 min timeout
      # Read in response from server
      $$Response = Net::SSLeay::ssl_read_all($self->{ssl});
    };
    alarm 0;    # Alarm off
    
  }

  if ( !defined( $$Response ) ) {
    $self->{strError} .= "Failed to read from socket. " .
         "SSLeay error: " . Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error);
    return 0;
  }
  return 1;
}

sub DisconnectFromServer
{
  my $self = shift;
  Net::SSLeay::free ($self->{ssl});               # Tear down connection
  Net::SSLeay::CTX_free ($self->{ctx});
  close S;
}

sub CleanUp
{
  return 1;
}

sub GetErrorString
{
  my $self = shift;
  return $self->{strError};
}
