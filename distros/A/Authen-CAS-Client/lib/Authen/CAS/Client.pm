package Authen::CAS::Client;

require 5.006_001;

use strict;
use warnings;

use Authen::CAS::Client::Response;
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use XML::LibXML;

our $VERSION = '0.08';


#======================================================================
# constructor
#

sub new {
  my ( $class, $cas, %args ) = @_;

  my $self = {
    _cas   => URI->new( $cas ),
    _ua    => LWP::UserAgent->new( agent => "Authen-CAS-Client/$VERSION" ),
    _fatal => $args{fatal} ? 1 : 0,
  };

  bless $self, $class;
}


#======================================================================
# private methods
#

sub _error {
  my ( $self, $error, $doc ) = @_;

  die $error
    if $self->{_fatal};

  Authen::CAS::Client::Response::Error->new( error => $error, doc => $doc );
}

sub _parse_auth_response {
  my ( $self, $xml ) = @_;

  my $doc = eval { XML::LibXML->new->parse_string( $xml ) };
  return $self->_error( 'Failed to parse XML', $xml )
    if $@;

  my ( $node, $response );

  eval {
    if( $node = $doc->find( '/cas:serviceResponse/cas:authenticationSuccess' )->get_node( 1 ) ) {
      $response = eval {
        my $user = $node->find( './cas:user' )->get_node( 1 )->textContent;

        my $iou = $node->find( './cas:proxyGrantingTicket' )->get_node( 1 );
        $iou = $iou->textContent
          if( defined $iou );

        my $proxies = $node->findnodes( './cas:proxies/cas:proxy' );
        $proxies = [ map $_->textContent, @$proxies ]
          if defined $proxies;

        Authen::CAS::Client::Response::AuthSuccess->new(
          user    => $user,
          iou     => $iou,
          proxies => $proxies,
          doc     => $doc,
        );
      };

      $response = $self->_error( 'Failed to parse authentication success response', $doc )
        if $@;
    }
    elsif( $node = $doc->find( '/cas:serviceResponse/cas:authenticationFailure' )->get_node( 1 ) ) {
      $response = eval {
        die
          unless $node->hasAttribute( 'code' );
        my $code = $node->getAttribute( 'code' );
        
        my $message = $node->textContent;
        s/^\s+//, s/\s+\z//
          for $message;

        Authen::CAS::Client::Response::AuthFailure->new(
          code    => $code,
          message => $message,
          doc     => $doc,
        );
      };

      $response = $self->_error( 'Failed to parse authentication failure response', $doc )
        if $@;
    }
    else {
      die;
    }
  };

  $response = $self->_error( 'Invalid CAS response', $doc )
    if $@;

  return $response;
}

sub _parse_proxy_response {
  my ( $self, $xml ) = @_;

  my $doc = eval { XML::LibXML->new->parse_string( $xml ) };
  return $self->_error( 'Failed to parse XML', $xml )
    if $@;

  my ( $node, $response );

  eval {
    if( $node = $doc->find( '/cas:serviceResponse/cas:proxySuccess' )->get_node( 1 ) ) {
      $response = eval {
        my $proxy_ticket = $node->find( './cas:proxyTicket' )->get_node( 1 )->textContent;

        Authen::CAS::Client::Response::ProxySuccess->new(
          proxy_ticket => $proxy_ticket,
          doc          => $doc,
        );
      };
      $response = $self->_error( 'Failed to parse proxy success response', $doc )
        if $@;
      }
    elsif( $node = $doc->find( '/cas:serviceResponse/cas:proxyFailure' )->get_node( 1 ) ) {
      $response = eval {
        die
          unless $node->hasAttribute( 'code' );
        my $code = $node->getAttribute( 'code' );
        
        my $message = $node->textContent;
        s/^\s+//, s/\s+\z//
          for $message;

        Authen::CAS::Client::Response::ProxyFailure->new(
          code    => $code,
          message => $message,
          doc     => $doc,
        );
      };
      $response = $self->_error( 'Failed to parse proxy failure response', $doc )
        if $@;
    }
    else {
      die;
    }
  };

  $response = $self->_error( 'Invalid CAS response', $doc )
    if $@;

  return $response;
}

sub _server_request {
  my ( $self, $path, $params ) = @_;

  my $url      = $self->_url( $path, $params )->canonical;
  my $response = $self->{_ua}->get( $url );

  unless( $response->is_success ) {
    return $self->_error(
      'HTTP request failed: ' . $response->code . ': ' . $response->message,
      $response->content
    );
  }

  return $response->content;
}

sub _url {
  my ( $self, $path, $params ) = @_;

  my $url = $self->{_cas}->clone;

  $url->path( $url->path . $path );
  $url->query_param_append( $_ => $params->{$_} )
    for keys %$params;

  return $url;
}

sub _v20_validate {
  my ( $self, $path, $service, $ticket, %args ) = @_;

  my %params = ( service => $service, ticket  => $ticket );

  $params{renew} = 'true'
    if $args{renew};
  $params{pgtUrl} = URI->new( $args{pgtUrl} )->canonical
    if defined $args{pgtUrl};

  my $content = $self->_server_request( $path, \%params );
  return $content
    if ref $content;

  return $self->_parse_auth_response( $content );
}


#======================================================================
# public methods
#

sub login_url {
  my ( $self, $service, %args ) = @_;

  my %params = ( service => $service );

  for ( qw/ renew gateway / ) {
    $params{$_} = 'true', last
      if $args{$_};
  }

  return $self->_url( '/login', \%params )->canonical;
}

sub logout_url {
  my ( $self, %args ) = @_;

  my %params;

  $params{url} = $args{url}
    if defined $args{url};

  return $self->_url( '/logout', \%params )->canonical;
}

sub validate {
  my ( $self, $service, $ticket, %args ) = @_;

  my %params = ( service => $service, ticket  => $ticket );

  $params{renew} = 'true'
    if $args{renew};

  my $content = $self->_server_request( '/validate', \%params );
  return $content
    if ref $content;

  my $response;

  if( $content =~ /^no\n\n\z/ ) {
    $response = Authen::CAS::Client::Response::AuthFailure->new( code => 'V10_AUTH_FAILURE', doc => $content );
  }
  elsif( $content =~ /^yes\n([^\n]+)\n\z/ ) {
    $response = Authen::CAS::Client::Response::AuthSuccess->new( user => $1, doc => $content );
  }
  else {
    $response = $self->_error( 'Invalid CAS response', $content );
  }

  return $response;
}

sub service_validate {
  my ( $self, $service, $ticket, %args ) = @_;
  return $self->_v20_validate( '/serviceValidate', $service, $ticket, %args );
}

sub proxy_validate {
  my ( $self, $service, $ticket, %args ) = @_;
  return $self->_v20_validate( '/proxyValidate', $service, $ticket, %args );
}

sub proxy {
  my ( $self, $pgt, $target ) = @_;

  my %params = ( pgt => $pgt, targetService => URI->new( $target ) );

  my $content = $self->_server_request( '/proxy', \%params );
  return $content
    if ref $content;

  return $self->_parse_proxy_response( $content );
}


1
__END__

=pod

=head1 NAME

Authen::CAS::Client - Provides an easy-to-use interface for authentication using JA-SIG's Central Authentication Service

=head1 SYNOPSIS

  use Authen::CAS::Client;

  my $cas = Authen::CAS::Client->new( 'https://example.com/cas' );


  # generate an HTTP redirect to the CAS login URL
  my $r = HTTP::Response->new( 302 );
  $r->header( Location => $cas->login_url );


  # generate an HTTP redirect to the CAS logout URL
  my $r = HTTP::Response->new( 302 );
  $r->header( Location => $cas->logout_url );


  # validate a service ticket (CAS v1.0)
  my $r = $cas->validate( $service, $ticket );
  if( $r->is_success ) {
    print "User authenticated as: ", $r->user, "\n";
  }

  # validate a service ticket (CAS v2.0)
  my $r = $cas->service_validate( $service, $ticket );
  if( $r->is_success ) {
    print "User authenticated as: ", $r->user, "\n";
  }


  # validate a service/proxy ticket (CAS v2.0)
  my $r = $cas->proxy_validate( $service, $ticket );
  if( $r->is_success ) {
    print "User authenticated as: ", $r->user, "\n";
    print "Proxied through:\n";
    print "  $_\n"
      for $r->proxies;
  }


  # validate a service ticket and request a proxy ticket (CAS v2.0)
  my $r = $cas->service_validate( $server, $ticket, pgtUrl => $url );
  if( $r->is_success ) {
    print "User authenticated as: ", $r->user, "\n";

    unless( defined $r->iou ) {
      print "Service validation for proxying failed\n";
    }
    else {
      print "Proxy granting ticket IOU: ", $r->iou, "\n";

      ...
      # map IOU to proxy granting ticket via request to pgtUrl
      ...

      $r = $cas->proxy( $pgt, $target_service );
      if( $r->is_success ) {
        print "Proxy ticket issued: ", $r->proxy_ticket, "\n";
      }
    }
  }

=head1 DESCRIPTION

The Authen::CAS::Client module provides a simple interface for
authenticating users using JA-SIG's CAS protocol.  Both CAS v1.0
and v2.0 are supported.

=head1 METHODS

=head2 new $url [, %args]

C<new()> creates an instance of an C<Authen::CAS::Client> object.  C<$url>
refers to the CAS server's base URL.  C<%args> may contain the
following optional parameter:

=head3 fatal =E<gt> $boolean

If this argument is true, the CAS client will C<die()> when an error
occurs and C<$@> will contain the error message.  Otherwise an
C<Authen::CAS::Client::Response::Error> object will be returned.  See
L<Authen::CAS::Client::Response> for more detail on response objects.

=head2 login_url $service [, %args]

C<login_url()> returns the CAS server's login URL which can be used to
redirect users to start the authentication process.  C<$service> is the
service identifier that will be used during validation requests.
C<%args> may contain the following optional parameters:

=head3 renew =E<gt> $boolean

This causes the CAS server to force a user to re-authenticate even if
an SSO session is already present for that user.

=head3 gateway =E<gt> $boolean

This causes the CAS server to only rely on SSO sessions for authentication.
If an SSO session is not available for the current user, validation
will result in a failure.

=head2 logout_url [%args]

C<logout_url()> returns the CAS server's logout URL which can be used to
redirect users to end authenticated sessions.  C<%args> may contain
the following optional parameter:

=head3 url =E<gt> $url

If present, the CAS server will present the user with a link to the given
URL once the user has logged out.

=head2 validate $service, $ticket [, %args]

C<validate()> attempts to validate a service ticket using the CAS v1.0
protocol.  C<$service> is the service identifier that was passed to the
CAS server during the login process.  C<$ticket> is the service ticket
that was received after a successful authentication attempt.  Returns an
appropriate L<Authen::CAS::Client::Response> object.  C<%args> may
contain the following optional parameter:

=head3 renew =E<gt> $boolean

This will cause the CAS server to respond with a failure if authentication
validation was done via a CAS SSO session.

=head2 service_validate $service, $ticket [, %args]

C<service_validate()> attempts to validate a service ticket using the
CAS v2.0 protocol.  This is similar to C<validate()>, but allows for
greater flexibility when there is a need for proxying authentication
to back-end services.  The C<$service> and C<$ticket> parameters are
the same as above.  Returns an appropriate L<Authen::CAS::Client::Response>
object.  C<%args> may contain the following optional parameters:

=head3 renew =E<gt> $boolean

This will cause the CAS server to respond with a failure if authentication
validation was done via a CAS SSO session.

=head3 pgtUrl =E<gt> $url

This tells the CAS server that a proxy ticket needs to be issued for
proxying authentication to a back-end service.  C<$url> corresponds to
a callback URL that the CAS server will use to verify the service's
identity.  Per the CAS specification, this URL must be HTTPS.  If this
verification fails, normal validation will occur, but a proxy granting
ticket IOU will not be issued.

Also note that this call will block until the CAS server completes its
service verification attempt.  The returned proxy granting ticket IOU
can then be used to retrieve the proxy granting ticket that was passed
as a parameter to the given URL.

=head2 proxy_validate $service, $ticket [, %args]

C<proxy_validate()> is almost identical in operation to C<service_validate()>
except that both service tickets and proxy tickets can be used for
validation and a list of proxies will be provided if proxied authentication
has been used.  The C<$service> and C<$ticket> parameters are the same as
above.  Returns an appropriate L<Authen::CAS::Client::Response> object.
C<%args> may contain the following optional parameters:

=head3 renew =E<gt> $boolean

This is the same as described above.

=head3 pgtUrl =E<gt> $url

This is the same as described above.

=head2 proxy $pgt, $target

C<proxy()> is used to retrieve a proxy ticket that can be passed to
a back-end service for proxied authentication.  C<$pgt> is the proxy
granting ticket that was passed as a parameter to the C<pgtUrl>
specified in either C<service_validate()> or C<proxy_validate()>.
C<$target> is the service identifier for the back-end system that will
be using the returned proxy ticket for validation.  Returns an appropriate
L<Authen::CAS::Client::Response> object.

=head1 BUGS

None are known at this time, but if you find one, please feel free to
submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Authen::CAS::Client::Response>

=back

More information about CAS can be found at JA-SIG's CAS homepage:
L<http://www.ja-sig.org/products/cas/>

=head1 LICENSE

This software is information.
It is subject only to local laws of physics.

=cut
