package Catalyst::Authentication::Credential::CAS;


use namespace::autoclean;
use Authen::CAS::Client;
use Moose;

our $VERSION = '0.05';


has uri            => ( is => 'ro', isa => 'Str', required => 1 );
has username_field => ( is => 'ro', isa => 'Str', default => 'username' );
has version        => ( is => 'ro', isa => 'Str', default => '2.0' );

has _cas           => ( is => 'rw', isa => 'Authen::CAS::Client', lazy_build => 1 );


my %_version_map = (
  '1.0' => '_authenticate_v10',
  '2.0' => '_authenticate_v20',
);


sub BUILDARGS { $_[1] }

sub _build__cas { Authen::CAS::Client->new( $_[0]->uri, fatal => 0 ) }

sub authenticate {
  my ( $self, $c, $realm, $authinfo ) = @_;

  # verify a supported version has been defined
  my $_authenticate = $_version_map{ $self->version };
  unless( defined $_authenticate ) {
    $c->log->error( 'Unsupported CAS version v'. $self->version );
    return;
  }

  # derive a service URI if one is not provided
  my $service = defined $authinfo->{service}
              ? $authinfo->{service} : $c->uri_for( $c->action, $c->req->captures );

  # look for ticket in authinfo and then request parameters
  my $ticket  = defined $authinfo->{ticket}
              ? $authinfo->{ticket} : $c->req->params->{ticket};

  # if no ticket was provided redirect to the CAS
  unless( defined $ticket ) {
    $c->log->debug( 'Redirecting to CAS for service "'. $service. '"' )
      if $c->debug;

    $c->res->redirect( $self->_login_uri( $service, $authinfo ) );
    die $Catalyst::DETACH;
  }

  # validate ticket using authentication method defined in version map
  $c->log->debug( 'Validating ticket "'. $ticket . '" for service "'. $service. '" using version v'. $self->version )
    if $c->debug;
  my $response = $self->$_authenticate( $service, $ticket, $authinfo );

  if( $response->is_error ) {
    $c->log->error( 'CAS authentcation error: '. $response->error );
    return;
  }

  if( $response->is_failure ) {
    $c->log->warn( 'CAS authentication failure: '. $response->code. ': '. $response->message );
    return;
  }

  $c->log->debug( 'Ticket validated for user "'. $response->user. '"' )
    if $c->debug;

  $realm->find_user( { $self->username_field => $response->user }, $c )
}

sub _login_uri {
  my ( $self, $service, $params ) = @_;

  $self->_cas->login_url( $service,
    map { exists $params->{$_} ? ( $_ => $params->{$_} ) : () }
      qw( gateway renew ) )
}

sub _authenticate_v10 {
  my ( $self, $service, $ticket ) = @_;

  $self->_cas->validate( $service, $ticket )
}

sub _authenticate_v20 {
  my ( $self, $service, $ticket, $params ) = @_;

  $self->_cas->service_validate( $service, $ticket,
    map { exists $params->{$_} ? ( $_ => $params->{$_} ) : () }
      qw( pgtUrl renew ) )
}


__PACKAGE__->meta->make_immutable;

1
__END__

=head1 NAME

Catalyst::Authentication::Credential::CAS - Catalyst support for JA-SIG's Central Authentication Service.

=head1 SYNOPSIS

  # in MyApp.pm
  __PACKAGE__->config->{'Plugin::Authentication'} = {
    default_realm => 'default',
    default => {
      credential => {
        class          => 'CAS',
        uri            => 'https://cas.example.com/cas',
        username_field => 'username', # optional
        version        => '2.0',      # optional
      },
      store => {
        ...
      },
    },
  };

  # in a controller
  sub auto :Private {
    unless( $c->user_exists || $c->authenticate ) {
      $c->res->status( 401 );
      $c->res->body( 'Access Denied' );
      return 0;
    }
  }


=head1 DESCRIPTION

This module allows you to CAS-ify your Catalyst applications.  It
integrates L<Authen::CAS::Client|Authen::CAS::Client> into Catalyst's
authentication framework.

=head1 CONFIGURATION

The following properties may be configured:

=over 2

=item B<uri>

This specifies the base URI for the CAS instance and is passed to
the C<new()> method of the CAS client.  See the documentation for
L<Authen::CAS::Client|Authen::CAS::Client> for more information.

=item B<username_field>

This specifies the name of the key in the C<$authinfo> hash that
is passed to C<$realm-E<gt>find_user()> for mapping the user name
returned from the CAS upon successful authentication and ticket
validation.  Its value will depend on what the configured user
store expects.  It defaults to C<'username'> if not specified in
the application's configuration.

=item B<version>

This specifies the verion of the CAS protocol to use.  Currently
only C<'1.0'> and C<'2.0'> are supported.  If not specified in
the application's configuration, the default of C<'2.0'> is used.
Its value will depend on if you can use the current version of
the CAS protocol or if you need to fall back to the older version
for compatibility.

=back

=head1 METHODS

=over 2

=item B<authenticate( $authinfo, $realm, $c )>

This is called during the normal Catalyst authentication process
and should never be called directly.

Since CAS is a service that verifies credentials outside of your
application, the login process for your application will have
two phases.  In the first phase, an unauthenticated user will
attempt to access your application and be redirected to the CAS
for credential verification.  A service URI must be provided to
the CAS so that once the user has been identified, they can be
redirected from the CAS back to your application for the second
phase of authentication.  During this second phase the (supposedly)
authenticated user will be given a ticket that your application must
validate with the CAS.  If the ticket is valid, the user is
considered authenticated.  The C<authenticate()> method handles
both phases of authentication.

Unless specified otherwise, this method will do its best to guess
the appropriate behavior for the service URI and ticket handling.
The service URI will be derived as the URI for the currently
executing action unless specified in the C<'service'> key of the
C<$authinfo> hash.  The ticket returned from the CAS will be
retrieved from the request parameters unless specifed in the
C<'ticket'> key of the C<$authinfo> hash.  If no ticket is
defined (phase one authentication) the response will be set to
redirect to the CAS and the current action will be detached.

You may also pass other parameters in the C<$authinfo> hash that
will affect the way the CAS verifies credentials.  See the
documentation for L<Authen::CAS::Client|Authen::CAS::Client> for
more on the C<'renew'>, C<'gateway'> and C<'pgtUrl'> parameters.

=back

=head1 BUGS

None are known at this time, but if you find one, please feel
free to submit a report to the author.

=head1 SEE ALSO

=over 2

=item L<Authen::CAS::Client|Authen::CAS::Client>

=item L<Catalyst::Plugin::Authentication|Catalyst::Plugin::Authentication>

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

with contributions from:

Kevin L. Kane E<lt>kkane@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2010, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
