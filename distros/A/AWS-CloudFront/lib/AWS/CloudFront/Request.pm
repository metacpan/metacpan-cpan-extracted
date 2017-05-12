
package
AWS::CloudFront::Request;
use VSO;
use HTTP::Request;
use AWS::CloudFront::ResponseParser;

has 'cf' => (
  is        => 'ro',
  isa       => 'AWS::CloudFront',
  required  => 1,
);

has 'type' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'protocol' => (
  is        => 'ro',
  isa       => 'Str',
  lazy      => 1,
  default   => sub { 'https' }
);


sub _send_request
{
  my ($s, $method, $uri, $headers, $content) = @_;
  
  my $req = HTTP::Request->new( $method => $uri );
  $req->content( $content ) if $content;
  map { 
    $req->header( $_ => $headers->{$_} )
  } keys %$headers;
  
  my $res = $s->cf->ua->request( $req );
  
#  # After creating a bucket and setting its location constraint, we get this
#  # strange 'TemporaryRedirect' response.  Deal with it.
#  if( $res->header('location') && $res->content =~ m{>TemporaryRedirect<}s )
#  {
#    $req->uri( $res->header('location') );
#    $res = $s->s3->ua->request( $req );
#  }# end if()
  return $s->parse_response( $res );
}# end _send_request()


sub parse_response
{
  my ($s, $res) = @_;
  
  die "parse_response() is not yet implemented!";
}# end parse_response()

1;# return true:

