
package Apache2::ASP::Mock::RequestRec;

use strict;
use warnings 'all';
use Carp 'confess';
use Apache2::ASP::Mock::Connection;
use Apache2::ASP::Mock::Pool;
use HTTP::Headers;


#==============================================================================
sub new
{
  my ($class) = shift;

  my $s = bless {
    buffer            => '',
    uri               => '',
    headers_out       => HTTP::Headers->new,
    headers_in        => { },
    pnotes            => { },
    status            => 200,
    cleanup_handlers  => [ ],
    pool              => Apache2::ASP::Mock::Pool->new(),
    connection        => Apache2::ASP::Mock::Connection->new(),
  }, $class;
  $s->{err_headers_out} = $s->{headers_out};
  return $s;
}# end new()


#==============================================================================
sub push_handlers
{
  my ($s, $ref, @args) = @_;
  
  push @{$s->{cleanup_handlers}}, {
    subref => $ref,
    args   => \@args,
  };
}# end push_handlers()


#==============================================================================
sub filename
{
  my $s = shift;
  
  my $config = Apache2::ASP::HTTPContext->current->config;
  
  return $config->web->www_root . $s->uri;
}# end filename()


#==============================================================================
sub pnotes
{
  my $s = shift;
  my $key = shift;
  
  @_ ? $s->{pnotes}->{$key} = shift : $s->{pnotes}->{$key};
}# end pnotes()


#==============================================================================
sub buffer
{
  $_[0]->{buffer};
}# end buffer()


#==============================================================================
sub pool
{
  $_[0]->{pool};
}# end buffer()


#==============================================================================
sub status
{
  my $s = shift;
  
  @_ ? $s->{status} = shift : $s->{status};
}# end status()


#==============================================================================
sub uri
{
  my $s = shift;
  
  if( @_ )
  {
    $s->{uri} = shift;
    # Should we also set $ENV{REQUEST_URI} here?
  }
  else
  {
    return $s->{uri};
  }# end if()
}# end uri()


#==============================================================================
sub args
{
  my $s = shift;
  @_ ? $s->{args} = shift : $s->{args};
}# end args()


#==============================================================================
sub method
{
  my $s = shift;
  @_ ? $s->{method} = shift : $s->{method};
}# end method()


#==============================================================================
#XXX Not documented.
sub headers_out
{
  $_[0]->{headers_out};
}# end headers_out()


#==============================================================================
#XXX Not documented.
sub err_headers_out
{
  $_[0]->{headers_out};
}# end err_headers_out()


#==============================================================================
#XXX Not documented.
sub headers_in
{
  $_[0]->{headers_in};
}# end headers_out()


#==============================================================================
#XXX Not documented.
sub send_headers
{
  my $s = shift;
  
  my $buffer = delete($s->{buffer});
  $s->print( join "\n", map { "$_: $s->{headers_out}->{$_}" } keys(%{$s->{headers_out}}) );
  $s->{buffer} = $buffer;
}# end send_headers()


#==============================================================================
sub content_type
{
  my $s = shift;
  @_ ? $s->{content_type} = shift : $s->{content_type};
}# end content_type()


#==============================================================================
sub print
{
  $_[0]->{buffer} .= $_[1];
}# end print()


#==============================================================================
sub rflush
{
  my $s = shift;
#warn "$s: rflush()";
}# end rflush()


#==============================================================================
sub connection
{
  $_[0]->{connection};
}# end connection()


#==============================================================================
sub document_root
{
  $ENV{DOCUMENT_ROOT};
}# end document_root()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::Mock::RequestRec - Mimics the mod_perl2 Apache2::RequestRec object ($r)

=head1 SYNOPSIS

  my $r = Apache2::ASP::HTTPContext->current->r;
  
  $r->filename( '/index.asp' );   # '/usr/local/projects/mysite.com/htdocs/index.asp
  
  $r->pnotes( foo => 'bar' );     # set foo = 'bar'
  my $foo = $r->pnotes( 'foo' );  # get foo
  
  my $output_buffer_contents = $r->buffer;
  
  my $mock_apr_pool = $r->pool;
  
  $r->status( '302 Found' );
  my $status = $r->status;
  
  my $uri = $r->uri;
  $r->uri('/new.asp');
  
  my $method = $r->method;  # get/post
  
  $r->content_type( 'text/html' );
  my $type = $r->content_type;
  
  my $mock_connection = $r->connection;
  
  $r->print( 'some string' );
  
  $r->rflush;

=head1 DESCRIPTION

This package provides "mock" access to what would normally be an L<Apache2::RequestRec> object - 
known by the name C<$r> in a normal mod_perl2 environment.

This package exists only to provide a layer of abstraction for L<Apache2::ASP::API>
and L<Apache2::ASP::Test::Base>.

B<NOTE>: The purpose of this package is only to mimic I<enough> of the functionality
of L<Apache2::RequestRec> to B<get by> without it - specifically during testing.

If you require additional functionality, B<patches are welcome!>

=head1 PUBLIC PROPERTIES

=head2 filename

Read-only.  Returns the absolute filename for the current request - i.e. C</usr/local/projects/mysite.com/htdocs/index.asp>

=head2 pnotes( $name [, $value ] )

Read/Write.  Set or get a variable for the duration of the current request.

=head2 buffer

Read-only.  Returns the contents of the current output buffer.

=head2 pool

Read-only.  Returns the current L<Apache2::ASP::Mock::Pool> object.

=head2 status( [$new_status] )

Read/Write.  Set or get the HTTP status code, I<a la> L<Apache2::Const>.

=head2 uri( [$new_uri] )

Read/Write.  Set or get the request URI.

=head2 method

Read-only.  Gets the request method - i.e. 'get' or 'post'.

=head2 content_type( [$new_content_type] )

Read/Write.  Set or get the B<outgoing> C<content-type> header.

=head2 connection

Read-only.  Returns the current L<Apache2::ASP::Mock::Connection> object.

=head1 PUBLIC METHODS

=head2 print( $string )

Adds C<$string> to the output buffer.

=head2 rflush( )

Does nothing.  Here only to maintain compatibility with a normal mod_perl2 environment.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

