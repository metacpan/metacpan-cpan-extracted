
package ASP4::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2str );
use ASP4::HTTPContext;
use ASP4::Mock::RequestRec;


sub new
{
  my $s = bless {
    _status           => 200,
    _expires          => 0,
    _content_type     => 'text/html',
    _expires_absolute => time2str( time() ),
  }, shift;
  $s->Status( $s->Status );
  $s->Expires( $s->Expires );
  $s->ContentType( $s->ContentType );
  
  return $s;
}# end new()

sub context { ASP4::HTTPContext->current }


sub ContentType
{
  my $s = shift;
  
  if( @_ )
  {
    my $type = shift;
    $s->{_content_type} = $type;
    $s->context->r->content_type( $type );
    $s->SetHeader( 'content-type' => $type );
  }
  else
  {
    return $s->{_content_type};
  }# end if()
}# end ContentType()


sub Expires
{
  my $s = shift;
  if( my $value = shift )
  {
    my $time;
    if( my ($num,$type) = $value =~ m/^(\-?\d+)([MHD])$/ )
    {
      my $expires;
      if( $type eq 'M' ) {
        # Minutes:
        $expires = time() + ( $num * 60 );
      }
      elsif( $type eq 'H' ) {
        # Hours:
        $expires = time() + ( $num * 60 * 60 );
      }
      elsif( $type eq 'D' ) {
        # Days:
        $expires = time() + ( $num * 60 * 60 * 24 );
      }# end if()
      $time = $expires;
    }
    else
    {
      $time = $value;
    }# end if()
    
    $s->{_expires} = $time;
    $s->{_expires_absolute} = time2str( $time );
    $s->SetHeader( expires  => $s->ExpiresAbsolute );
  }# end if()
  
  return $s->{_expires};
}# end Expires()


sub ExpiresAbsolute { shift->{_expires_absolute} }


sub Status
{
  my $s = shift;
  
  @_ ? $s->context->r->status( $s->{_status} = +shift ) : $s->{_status};
}# end Status()


sub End
{
  my $s = shift;
  
  if( $s->Status =~ m{^2} )
  {
    $s->Flush;
  }
  else
  {
    delete $s->context->headers_out->{'content-type'};
  }# end if()
  
  # Would be nice to somehow stop all execution:
  $s->context->did_end( 1 );
}# end End()


sub Flush
{
  my $s = shift;
  $s->context->rflush;
}# end Flush()


sub Clear
{
  shift->context->rclear
}# end Clear()


sub IsClientConnected
{
  ! shift->context->r->connection->aborted();
}# end IsClientConnected()


sub Write
{
  my $s = shift;
  $s->context->rprint( shift(@_) )
}# end Write()


sub SetCookie
{
  my ($s, %args) = @_;
  
  $args{domain} ||= eval { $s->context->config->data_connections->session->cookie_domain } || $ENV{HTTP_HOST};
  $args{path}   ||= '/';
  my @parts = ( );
  push @parts, $s->context->server->URLEncode($args{name}) . '=' . $s->context->server->URLEncode($args{value});
  unless( $args{domain} eq '*' )
  {
    push @parts, 'domain=' . $s->context->server->URLEncode($args{domain});
  }# end unless()
  push @parts, 'path=' . $args{path};
  if( $args{expires} )
  {
    if( my ($num,$type) = $args{expires} =~ m/^(\-?\d+)([MHD])$/ )
    {
      my $expires;
      if( $type eq 'M' ) {
        # Minutes:
        $expires = time() + ( $num * 60 );
      }
      elsif( $type eq 'H' ) {
        # Hours:
        $expires = time() + ( $num * 60 * 60 );
      }
      elsif( $type eq 'D' ) {
        # Days:
        $expires = time() + ( $num * 60 * 60 * 24 );
      }# end if()
      push @parts, 'expires=' . time2str( $expires );
    }
    else
    {
      push @parts, 'expires=' . time2str( $args{expires} );
    }# end if()
  }# end if()
  $s->AddHeader( 'Set-Cookie' => join('; ', @parts) . ';' );
}# end SetCookie()


sub AddHeader
{
  my ($s, $name, $value) = @_;
  
  $s->context->headers_out->push_header( $name => $value );
}# end AddHeader()


sub SetHeader
{
  my ($s, $name, $value) = @_;
  
  $s->context->headers_out->header( $name => $value );
}# end AddHeader()


sub Headers
{
  my $s = shift;
  
  my $out = $s->context->headers_out;
  map {{
    $_ => $out->{$_}
  }} keys %$out;
}# end Headers()


sub Redirect
{
  my ($s, $url) = @_;
  
  $s->Clear;
  $s->Status( 301 );
  $s->Expires( "-24H" )
    unless $s->Expires;
  $s->SetHeader( Location => $url );
  $s->End;
  return $s->Status;
}# end Redirect()


sub Declined { -1 }


sub Include
{
  my ($s, $file, $args) = @_;
  
  $s->Write( $s->_subrequest( $file, $args ) );
}# end Include()


sub TrapInclude
{
  my ($s, $file, $args) = @_;
  
  return $s->_subrequest( $file, $args );
}# end TrapInclude()


sub _subrequest
{
  my ($s, $file, $args) = @_;
  
  my $context = ASP4::HTTPContext->new( is_subrequest => 1 );
  my $original_r = $s->context->r;
  my $root = $s->context->config->web->www_root;
  my $cgi = $s->context->cgi;
  (my $uri = $file) =~ s/^\Q$root\E//;
  my $r = ASP4::Mock::RequestRec->new(
    uri   => $uri,
    args  => $original_r->args,
  );
  SCOPE: {
    local $ASP4::HTTPContext::_instance = $context;
    local $ENV{SCRIPT_NAME} = $uri;
    local $ENV{SCRIPT_FILENAME} = $file;
    $context->setup_request( $r, $cgi );
    $context->execute( $args, 1 );
  };
  
  return $context->r->buffer;
}# end _subrequest()


#sub _subrequest
#{
#  my ($s, $file, $args) = @_;
#  
#  $s->context->add_buffer();
#  my $original_r = $s->context->r;
#  my $root = $s->context->config->web->www_root;
#  (my $uri = $file) =~ s/^\Q$root\E//;
#  my $r = ASP4::Mock::RequestRec->new(
#    uri   => $uri,
#    args  => $original_r->args,
#  );
#  local $ENV{SCRIPT_NAME} = $uri;
#  local $ENV{SCRIPT_FILENAME} = $file;
#  my $original_status = $s->Status();
#  $s->context->setup_request( $r, $s->context->cgi );
#  $s->context->execute( $args, 1 );
#  $s->Flush;
#  $s->Status( $original_status );
#  my $buffer = $s->context->purge_buffer();
#  $s->context->{r} = $original_r;
#  $s->context->did_end( 0 );
#  return $r->buffer;
#}# end _subrequest()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

=pod

=head1 NAME

ASP4::Response - Interface to the outgoing HTTP response

=head1 SYNOPSIS

  $Response->ContentType("text/html");
  
  $Response->Status( 200 );
  
  $Response->Clear();
  
  $Response->Flush();

  $Response->Write("Hello, World!");
  
  $Response->AddHeader( 'x-awesomeness' => '100%' );
  
  $Response->SetHeader( 'x-velocity'  => '100MPH' );
  
  # Expires in the future:
  $Response->Expires( '30M' );  # 30 minutes from now
  $Response->Expires( '30H' );  # 30 hours from  now
  $Response->Expires( '30D' );  # 30 days from now
  
  # Expires in the past:
  $Response->Expires( '-30M' ); # 30 minutes ago
  $Response->Expires( '-30H' ); # 30 hours ago
  $Response->Expires( '-30D' ); # 30 days ago
  
  $Response->SetCookie(
    # Required parameters:
    name    => "customer-email",
    value   => $Form->{email},
    
    # The rest are optional:
    expires => '30D', # 30 days
    path    => '/',
    domain  => '.mysite.com',
  );
  
  $Response->Redirect( "/path/to/page.asp" );
  
  $Response->Include( $Server->MapPath("/my/include.asp") );
  $Response->Include( $Server->MapPath("/my/include.asp"), \%args );
  
  my $string = $Response->TrapInclude( $Server->MapPath("/my/widget.asp") );
  my $string = $Response->TrapInclude( $Server->MapPath("/my/widget.asp"), \%args );
  
  return $Response->Declined;
  
  $Response->End;
  
  while( 1 ) {
    last unless $Response->IsClientConnected();
    $Response->Write("Still Here!<br/>");
    sleep(1);
  }
  
  my HTTP::Headers $headers = $Response->Headers;
  
  # Read-only:
  my $expires_on = $Response->ExpiresAbsolute;

=head1 DESCRIPTION

The C<$Response> object offers a unified interface to send content back to the client.

=head1 PROPERTIES

=head2 ContentType( [$type] )

Sets or gets the C<content-type> header for the response.  Examples are C<text/html>, C<image/gif>, C<text/csv>, etc.

=head2 Status( [$status] )

Sets or gets the C<Status> header for the response.  See L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html> for details.

B<NOTE:> Only the numeric part is necessary - eg: 200, 301, 404, etc.

=head2 Headers()

Returns the L<HTTP::Headers> object that will be used for the outgoing response.

If necessary, you can manipulate this object in any way you see fit.

=head2 Declined

For use within a L<ASP4::RequestFilter> subclass, like this:

  sub run {
    # Permit requests only every other second:
    if( time() % 2 ) {
      return $Response->Declined;
    }
    else {
      $Response->Write("Try again");
      return $Response->End;
    }
  }

=head2 IsClientConnected

In a ModPerl environment, this can be used to determine whether the client has
closed the connection (hit the "Stop" button or closed their browser).  Useful within
a long-running loop.

=head1 METHODS

=head2 Write( $str )

Adds C<$str> to the output buffer.

=head2 Flush( )

Causes the output buffer to be flushed to the client.

=head2 End( )

Aborts the current request.

Example:

  # Good:
  return $Response->End;

Simply calling...

  # Bad!
  $Response->End;

...will not work as intended.

=head2 AddHeader( $name => $value )

Appends C<$value> to the header C<$name>.

=head2 SetHeader( $name => $value )

Sets (and replaces) the header C<$name> to the value of C<$value>.

=head2 SetCookie( %args )

Adds a new cookie to the response.

C<%args> B<must> contain the following:

=over 4

=item * name

A string - the name of the cookie.

=item * value

The value of the cookie.

=back

Other parameters are:

=over 4

=item * expires

Can be in one of the following formats:

=over 8

=item * 30B<M>

Minutes - how many minutes from "now" calculated as C<time() + (30 * 60)>

Example:

  expires => '30M'
  expires => '-5M'  # 5 minutes ago

=item * 2B<H>

Hours - how many hours from "now" calculated as C<time() + (2 * 60 * 60)>

Example:

  expires => '2H'   # 2 hours
  expires => '12H'  # 12 Hours

=item * 7B<D>

Days - how many days from "now" calculated as C<time() + (7 * 60 * 60 * 24)>

Example:

  expires => '7D'   # A week
  expires => '30D'  # A month

=back

=item * path

Defaults to "C</>" - you can restrict the "path" that the cookie will apply to.

=item * domain

Defaults to whatever you set your config->data_connections->session->cookie_domain to
in your asp4-config.json.  Otherwise defaults to C<$ENV{HTTP_HOST}>.

You can override the defaults by passing in a domain, but the browser may not accept
other domains.  See L<http://www.ietf.org/rfc/rfc2109.txt> for details.

=back

=head2 Redirect( $url )

Causes the following HTTP header to be sent:

  Status: 301 Moved
  Location: $url

=head2 Include( $path [, \%args ] )

Executes the ASP script at C<$path> and includes its output.  Additional C<\%args>
may be passed along to the include.

The passed-in args are accessible to the include like this:

  <%
    my ($self, $context, $args) = @_;
    
    # Args is a hashref:
  %>

=head2 TrapInclude( $path [, \%args ] )

Executes the ASP script at C<$path> and returns its output.  Additional C<\%args>
may be passed along to the include.

The passed-in args are accessible to the include like this:

  <%
    my ($self, $context, $args) = @_;
    
    # Args is a hashref:
  %>

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

