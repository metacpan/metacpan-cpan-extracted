#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
## no critic
package DNS::NIOS;
$DNS::NIOS::VERSION = '0.005';

# ABSTRACT: Perl binding for NIOS
# VERSION
# AUTHORITY

## use critic
use strictures 2;

use Carp qw(croak);
use JSON qw(to_json);
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use URI;
use URI::QueryParam;
use DNS::NIOS::Response;
use Role::Tiny::With;

use Class::Tiny qw( password username wapi_addr traits ),
  {
  wapi_version => 'v2.7',
  scheme       => 'https',
  insecure     => 0,
  timeout      => 10,
  debug        => $ENV{NIOS_DEBUG}
  };

sub BUILD {
  my ( $self, $args ) = @_;

  defined( $self->$_ )
    or croak("$_ is required!")
    for qw(username password wapi_addr); ## no critic (ControlStructures::ProhibitPostfixControls)

  ( ( $self->scheme eq 'http' ) or ( $self->scheme eq 'https' ) )
    or croak( "scheme not supported: " . $self->scheme );

  $self->{base_url} =
      $self->scheme . "://"
    . $self->wapi_addr
    . "/wapi/"
    . $self->wapi_version . "/";

  $self->{ua} = LWP::UserAgent->new( timeout => $self->timeout );
  $self->{ua}->agent( 'NIOS-perl/' . $DNS::NIOS::VERSION );
  $self->{ua}->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0x00 )
    if $self->insecure and $self->scheme eq 'https'; ## no critic (ControlStructures::ProhibitPostfixControls)
  $self->{ua}->default_header( 'Accept'       => 'application/json' );
  $self->{ua}->default_header( 'Content-Type' => 'application/json' );
  $self->{ua}->default_header( 'Authorization' => 'Basic '
      . encode_base64( $self->username . ":" . $self->password ) );

  if ( $self->traits ) {
    foreach ( @{ $self->traits } ) {
      with $_;
    }
  }
}

sub create {
  my ( $self, %args ) = @_;

  defined( $args{$_} )
    or croak("$_ is required!")
    for qw(path payload);

  return $self->__request( 'POST', $args{path},
    ( payload => $args{payload}, params => $args{params} ) );
}

sub update {
  my ( $self, %args ) = @_;

  defined( $args{$_} )
    or croak("$_ is required!")
    for qw(path payload);

  return $self->__request( 'PUT', $args{path},
    ( payload => $args{payload}, params => $args{params} ) );
}

sub get {
  my ( $self, %args ) = @_;

  defined( $args{path} )
    or croak("path is required!");

  return $self->__request( 'GET', $args{path}, ( params => $args{params} ) );
}

sub delete {
  my ( $self, %args ) = @_;

  defined( $args{path} )
    or croak("path is required!");

  return $self->__request( 'DELETE', $args{path}, ( params => $args{params} ) );
}

sub __request {
  my ( $self, $op, $path, %args ) = @_;

  my $payload      = delete $args{payload};
  my $params       = delete $args{params};
  my $query_params = q{};

  grep( /(^\Q$op\E$)/, qw(GET POST PUT DELETE) )
    or die("invalid operation: $op");

  croak("invalid path") unless ( defined $path and length $path );

  if ( $op eq 'PUT' or $op eq 'POST' ) {
    croak("invalid payload") unless keys %{$payload};
  }

  if ( defined $params ) {
    my $u = URI->new( q{}, 'http' );
    $query_params = q{?};
    foreach ( keys %{$params} ) {
      $u->query_param( $_ => $params->{$_} );
    }
    $query_params .= $u->query;
  }

  my $request =
    HTTP::Request->new( $op, $self->{base_url} . $path . $query_params );

  if ( $op eq 'PUT' or $op eq 'POST' ) {
    $request->content( to_json($payload) );
  }

  return DNS::NIOS::Response->new(
    _http_response => $self->{ua}->request($request) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::NIOS - Perl binding for NIOS

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    # Read below for a list of options
    my $n = NIOS->new(
        username  => "username",
        password  => "password",
        wapi_addr => "10.0.0.1",
    );


    $x = $n->get(
        path => 'record:a',
        params => {
            _paging           => 1,
            _max_results      => 1,
            _return_as_object => 1
        }
    );
    say $x->content->{result}[0]->{_ref};

=head1 DESCRIPTION

Perl bindings for L<https://www.infoblox.com/company/why-infoblox/nios-platform/>

=head2 Normal usage

Normally, you will add some traits to the client, primarily L<DNS::NIOS::Traits::ApiMethods>
since it provides methods for some endpoints.

=head2 Minimal usage

Without any traits, DNS::NIOS provides access to all API endpoints using the methods described below.

=head1 CONSTRUCTOR

=for Pod::Coverage BUILD

=head2 new

The following attributes are required at construction time:

=over 4

=item * C<username>

Configures the username to use to authenticate the connection to the remote instance of NIOS.

=item * C<password>

Specifies the password to use to authenticate the connection to the remote instance of NIOS.

=item * C<wapi_addr>

DNS hostname or address for connecting to the remote instance of NIOS WAPI.

=back

    my $n = NIOS->new(
        username  => "username",
        password  => "password",
        wapi_addr => "10.0.0.1",
    );

Optional attributes:

=over 4

=item * C<insecure>

Enable or disable verifying SSL certificates when C<scheme> is C<https>. Default is C<false>.

=item * C<scheme>

Default is C<https>.

=item * C<timeout>

The amount of time before to wait before receiving a response. Default is C<10>.

=item * C<wapi_version>

Specifies the version of WAPI to use. Default is C<v2.7>.

=item * C<debug>

=item * C<traits>

List of traits to apply, see L<DNS::NIOS::Traits>.

=back

=head1 METHODS

=over

=item * All methods require a path parameter that can be either a resource type (eg: "record:a") or a WAPI Object reference.

=item * All methods return a L<DNS::NIOS::Response> object.

=back

=head2 create

    # Create a new A record:
    my $x = $n->create(
        path => "record:a",
        payload => {
            name     => "rhds.ext.home",
            ipv4addr => "10.0.0.1",
            extattrs => {
                "Tenant ID"       => { value => "home" },
                "CMP Type"        => { value => "OpenStack" },
                "Cloud API Owned" => { value => "True" }
            }
        }
    );

=head2 delete

    # Delete a WAPI Object Reference
    $x = $n->delete(path => $object_ref);

=head2 get

    # List all A records with:
    #   pagination
    #   limiting results to 1
    #   returning response as an object
    $x = $n->get(
        path   => 'record:a',
        params => {
            _paging           => 1,
            _max_results      => 1,
            _return_as_object => 1
        }
    );

=head2 update

    # Update a WAPI Object Reference
    $x = $n->update(
        path    => $object_ref,
        payload => {
          name => "updated_name"
        }
    );

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Christian Segundo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
