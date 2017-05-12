
package 
AWS::CloudFront::ResponseParser;

use VSO;
use XML::Simple;

has 'expect_nothing' => (
  is        => 'ro',
  isa       => 'Int',
  required  => 1,
  default   => sub { 0 }
);

has 'response'  => (
  is        => 'ro',
  isa       => 'HTTP::Response',
  required  => 1,
);

has 'type'  => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'libxml'  => (
  is        => 'ro',
  isa       => 'XML::LibXML',
  required  => 1,
  default   => sub { XML::LibXML->new() },
);

has 'error_code' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
);

has 'error_message' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 0,
);

has 'xpc' => (
  is        => 'ro',
  isa       => 'XML::LibXML::XPathContext',
  required  => 0,
);

has 'friendly_error' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 0,
  default   => sub {
    my $s = shift;
    return unless $s->error_code || $s->error_message;
    $s->type . " call had errors: [" . $s->error_code . "] " . $s->error_message;
  }
);


sub BUILD
{
  my $s = shift;
  
  my $code = $s->response->code;
  
  # If we got a successful response and nothing was expected, we're done:
  if( $s->expect_nothing )
  {
    if( $code =~ m{^2\d\d} && ! $s->response->content )
    {
      return;
    }
    else
    {
      if( $s->_parse_errors() )
      {
#        die $s->friendly_error();
      }
      else
      {
        return;
      }# end if()
    }# end if()
  }
  else
  {
    $s->{xpc} = $s->_xpc_of_content();
  }# end if()
}# end BUILD()


sub _parse_errors
{
  my ($s) = @_;
  
  my $src = $s->response->content;
  
  # Do not try to parse non-xml:
  unless( $src =~ m/^[[:space:]]*</s )
  {
    ( my $code = $src ) =~ s/^[[:space:]]*\([0-9]*\).*$/$1/s;
    $s->error_code( $code );
    $s->error_message( $src );
    return 1;
  }# end unless()
  
  return 0;
}# end _parse_errors()


sub _xpc_of_content
{
  my ($s) = @_;
  
  my $src = $s->response->content;
  return unless $src =~ m/^[[:space:]]*</s;
  my $doc = $s->libxml->parse_string( $s->response->content );
  
  my $xpc = XML::LibXML::XPathContext->new($doc);
  $xpc->registerNs( 'cf', 'http://cloudfront.amazonaws.com/doc/2010-11-01/' );

  return $xpc;
}# end _xpc_of_content()

1;# return true:

