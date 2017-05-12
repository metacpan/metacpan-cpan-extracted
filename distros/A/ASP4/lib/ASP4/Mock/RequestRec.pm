
package ASP4::Mock::RequestRec;

use strict;
use warnings 'all';
use ASP4::Mock::Pool;
use ASP4::Mock::Connection;
use ASP4::ConfigLoader;
use Scalar::Util 'weaken';


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    status        => 200,
    content_type  => 'text/plain',
    buffer        => '',
    document_root => ASP4::ConfigLoader->load()->web->www_root,
    headers_in    => { },
    headers_out   => { },
    uri           => $args{uri} || $ENV{REQUEST_URI},
    args          => $args{args} || $ENV{QUERY_STRING},
    pnotes        => { },
    method        => $args{method},
    pool          => ASP4::Mock::Pool->new(),
    connection    => ASP4::Mock::Connection->new(),
  }, $class;
  
  weaken($s->{connection});
  $s->{err_headers_out} = $s->{headers_out};
  $s->{filename}        = $s->document_root . $s->uri;
  
  return $s;
}# end new()


# Public read-write properties:
sub pnotes
{
  my $s = shift;
  my $name = shift;
   @_ ? $s->{pnotes}->{$name} = shift : $s->{pnotes}->{$name};
}# end pnotes()

sub uri
{
  my $s = shift;
  @_ ? $s->{uri} = shift : $s->{uri};
}# end uri()

sub args
{
  my $s = shift;
  @_ ? $s->{args} = shift : $s->{args};
}# end args()

sub status {
  my $s = shift;
  @_ ? $s->{status} = +shift : $s->{status};
}# end status()


# Public read-only properties:
sub document_root   { shift->{document_root} }
sub method          { uc( shift->{method} ) }
sub pool            { shift->{pool} }
sub connection      { shift->{connection} }
sub headers_out     { shift->{headers_out} }
sub headers_in      { shift->{headers_in} }
sub err_headers_out { shift->{err_headers_out} }

sub buffer          { shift->{buffer} } # Not documented:


# Public methods:
sub print { my ($s,$str) = @_; $s->{buffer} .= $str; }
sub content_type
{
  my ($s, $type) = @_;
  return $s->headers_out->{'content-type'} unless $type;
  $s->headers_out->{'content-type'} = $type;
}# end content_type()

sub rflush { }

1;# return true:

=pod

=head1 NAME

ASP4::Mock::RequestRec - Mimic an Apache2::RequestRec object

=head1 DESCRIPTION

When an ASP4 request is executed outside of a mod_perl2 environment, it uses an
instance of C<ASP4::Mock::RequestRec> in place of the L<Apache2::RequestRec> it
would otherwise have.

=head1 PUBLIC PROPERTIES

=head2 pnotes( $name [, $value ] )

Sets or gets the value of a named "pnote" for the duration of the request.

Example:

  $r->pnotes( foo => "foovalue" );
  my $val = $r->pnotes( 'foo' );

=head2 args( [$new_args] )

Sets or gets the querystring for the request.

Example:

  my $str = $r->args();
  $r->args( 'foo=bar&baz=bux' );

=head2 uri( [$new_uri] )

Sets or gets the URI for the current request:

Example:

  my $uri = $r->uri;
  $r->uri( '/path/to/page.asp' );

=head2 document_root( )

Gets the document root for the server.  This is the same as $config->web->www_root.

  my $root = $r->document_root; # /var/www/mysite.com/htdocs

=head2 method( )

Gets the request method for the current request.  Eg: C<GET> or C<POST>.

  if( $r->method eq 'GET' ) {
    # It's a "GET" request:
  }
  elsif( $r->method eq 'POST' ) {
    # It's a "POST" request:
  }

=head2 pool( )

Returns the current L<ASP4::Mock::Pool> object.

  my $pool = $r->pool;

=head2 connection( )

Returns the current L<ASP4::Mock::Connection> object.

  my $connection = $r->connection;

=head2 headers_out( )

Returns a hashref representing the outgoing headers.

=head2 err_headers_out( )

Returns a hashref representing the outgoing headers.

=head2 status( [$new_status] )

Sets or gets the status code for the response.  200 for "OK", 301 for "Moved" - 404 for "not found" etc.

=head2 content_type( [$new_content_type] )

Sets or gets the mime-header for the outgoing response.  Default is C<text/plain>.

=head1 PUBLIC METHODS

=head2 print( $str )

Adds C<$str> to the outgoing response buffer.

=head2 rflush( )

Does nothing.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

