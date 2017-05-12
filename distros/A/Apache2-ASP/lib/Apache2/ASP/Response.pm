
package Apache2::ASP::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2iso str2time time2str );
use Carp qw( croak confess );
use Apache2::ASP::Mock::RequestRec;
use Apache2::ASP::HTTPContext::SubContext;

our $MAX_BUFFER_LENGTH = 1024 ** 2;

#$SIG{__DIE__} = \&confess;
our $IS_TRAPINCLUDE = 0;

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  delete($args{context});
  my $s = bless {
    _status           => 200,
    _output_buffer    => [ ],
    _do_buffer        => 1,
    _buffer_length    => 0,
  }, $class;
  $s->ContentType('text/html'); 
  $s->Expires( 0 );
  return $s;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub ContentType
{
  my $s = shift;
  
  if( @_ )
  {
#    confess "Response.ContentType cannot be changed after headers have been sent"
    return
      if $s->context->{_did_send_headers};
    $s->context->content_type( shift );
  }
  else
  {
   return $s->context->content_type;
  }# end if()
}# end ContentType()


#==============================================================================
sub Status
{
  my $s = shift;
  
  if( @_ )
  {
#    confess "Response.Status cannot be changed after headers have been sent"
    return
      if $s->context->{_did_send_headers};
    
    $s->{_status} = shift;
    $s->context->r->status( $s->{_status} );
  }
  else
  {
    return $s->{_status};
  }# end if()
}# end Status()


#==============================================================================
sub Expires
{
  my $s = shift;
  
  if( @_ )
  {
    # Setter:
    $s->{_expires} = shift;
    $s->ExpiresAbsolute( time2str(time + $s->{_expires} * 60 ) );
  }
  else
  {
    # Getter:
    return $s->{_expires};
  }# end if()
}# end Expires()


#==============================================================================
sub ExpiresAbsolute
{
  my $s = shift;
  if( my $when = shift )
  {
    $s->DeleteHeader('expires');
    $s->{_expires_absolute} = $when;
  }
  else
  {
    return $s->{_expires_absolute};
  }# end if()
}# end ExpiresAbsolute()


#==============================================================================
sub Declined
{
  return -1;
}# end Declined()


#==============================================================================
sub Redirect
{
  my ($s, $url) = @_;
  
  confess "Response.Redirect cannot be called after headers have been sent"
    if $s->context->{_did_send_headers};
  
  $s->Clear;
  $s->AddHeader( location => $url );
  $s->Status( 302 );
  $s->End;
  return 302; # New behavior - used to return '1':
}# end Redirect()


#==============================================================================
sub End
{
  my $s = shift;
  
  $s->Flush;
  $s->context->set_prop( did_end => 1 );
}# end End()


#==============================================================================
sub Flush
{
  my $s = shift;
  
  $s->context->rflush;
}# end Flush()


#==============================================================================
sub Write
{
  my $s = shift;
  return unless defined($_[0]);

  $s->context->print( shift );
}# end Write()


#==============================================================================
sub Include
{
  my ($s, $path, $args) = @_;
  return if $s->context->{did_end};
  
  my $ctx = $s->context;
  my $subcontext = Apache2::ASP::HTTPContext::SubContext->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  use Apache2::ASP::Mock::RequestRec;
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $subcontext->setup_request( $clone_r, $ctx->cgi );
  my $res = $subcontext->execute( $args );
  $ctx->print( $subcontext->{r}->{buffer} );
  $subcontext->DESTROY;

  if( $res > 200 )
  {
    $s->Status( $res );
  }# end if()

  undef( $subcontext );
}# end Include()


#==============================================================================
sub TrapInclude
{
  my ($s, $path, $args) = @_;
  return if $s->context->{did_end};
  
  use Apache2::ASP::HTTPContext::SubContext;
  
  my $ctx = $s->context;
  my $subcontext = Apache2::ASP::HTTPContext::SubContext->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  use Apache2::ASP::Mock::RequestRec;
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $subcontext->setup_request( $clone_r, $ctx->cgi );
  my $res = $subcontext->execute( $args );
  my $result = $subcontext->{r}->{buffer};
  $subcontext->DESTROY;

  undef( $subcontext );
  return $result;
}# end TrapInclude()


#==============================================================================
sub Cookies
{
  $_[0]->context->headers_out->{'set-cookie'};
}# end Cookies()


#==============================================================================
sub AddCookie
{
  my $s = shift;
  
  my ($name, $val, $path, $expires) = @_;
  die "Usage: Response.AddCookie(name, value [, path [, expires ]])"
    unless defined($name) && defined($val);
  $path ||= '/';
  $expires ||= time() + ( 60 * 30 );
  my $expire_date ||= time2str( $expires );
  
  my $cookie = join '=', map { $s->context->cgi->escape( $_ ) } ( $name => $val );
  $s->context->headers_out->push_header( 'set-cookie' => "$cookie; path=$path; expires=$expire_date" );
}# end AddCookie()


#==============================================================================
sub AddHeader
{
  my ($s, $name, $val) = @_;
  
  return unless defined($name) && defined($val);
  
  return $s->context->headers_out->{ $name } = $val;
}# end AddHeader()


#==============================================================================
sub DeleteHeader
{
  my ($s, $name) = @_;
  
  $s->context->headers_out->remove_header( $name );
}# end DeleteHeader()


#==============================================================================
sub Headers
{
  $_[0]->context->headers_out;
}# end Headers()


#==============================================================================
sub Clear
{
  $_[0]->{_output_buffer} = [ ];
}# end Clear()


#==============================================================================
sub IsClientConnected
{
  return ! shift->context->get_prop('did_end');
}# end IsClientConnected()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef(%$s);
}# end DESTROY()

1;# return true:

=head1 NAME

Apache2::ASP::Response - Outgoing response object.

=head1 SYNOPSIS

  return $Response->Redirect("/another.asp");
  
  return $Response->Declined;
  
  $Response->End;
  
  $Response->ContentType("text/xml");
  
  $Response->Status( 404 );
  
  # Make this response expire 30 minutes ago:
  $Response->Expires( -30 );
  
  $Response->Include( $Server->MapPath("/inc/top.asp"), { foo => 'bar' } );
  
  my $html = $Response->TrapInclude( $Server->MapPath("/inc/top.asp"), { foo => 'bar' } );
  
  $Response->AddHeader("content-disposition: attachment;filename=report.csv");
  
  $Response->Write( "hello, world" );
  
  $Response->Clear;
  
  $Response->Flush;

=head1 DESCRIPTION

Apache2::ASP::Response offers a wrapper around the outgoing response to the client.

=head1 PUBLIC PROPERTIES

=head2 ContentType( [$type] )

Sets/gets the content-type response header (i.e. text/html, image/gif, etc).

Default: text/html

=head2 Status( [$status] )

Sets/gets the status response header (i.e. 200, 404, etc).

Default: 200

=head2 Expires( [$minutes] )

Default 0

=head2 ExpiresAbsolute( [$http_date] )

=head2 Declined( )

Returns C<-1>.

=head2 Cookies( )

Returns all outgoing cookies for this response.

=head2 Headers( )

Returns all outgoing headers for this response.

=head2 IsClientConnected( )

Returns true if the client is still connected, false otherwise.

=head1 PUBLIC METHODS

=head2 Write( $str )

Adds C<$str> to the response buffer.

=head2 Redirect( $path )

Clears the response buffer and sends a 301 redirect to the client.

Throws an exception if headers have already been sent.

=head2 Include( $path, \%args )

Executes the script located at C<$path>, passing along C<\%args>.  Output is
included as part of the current script's output.

=head2 TrapInclude( $path, \%args )

Executes the script located at C<$path>, passing along C<\%args>, and returns
the response as a string.

=head2 AddCookie( $name => $value )

Adds a cookie to the header.

=head2 AddHeader( $name => $value )

Adds a header to the response.

=head2 DeleteHeader( $name )

Removes an outgoing header.

Throws an exception if headers have already been sent.

=head2 Flush( )

Sends any buffered output to the client.

=head2 Clear( )

Clears the outgoing buffer.

=head2 End( )

Closes the connection to the client and terminates the current request.

Throws an exception if headers have already been sent.

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

