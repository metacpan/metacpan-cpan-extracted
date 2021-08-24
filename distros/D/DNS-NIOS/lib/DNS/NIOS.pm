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
$DNS::NIOS::VERSION = '0.001';
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

use Class::Tiny qw( password username wapi_addr ),
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

  return $self->{ua}->request($request);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::NIOS - Perl binding for NIOS

=head1 VERSION

version 0.001

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
    say from_json( $x->decoded_content )->{result}[0]->{_ref};

=head1 DESCRIPTION

Perl bindings for L<https://www.infoblox.com/company/why-infoblox/nios-platform/>

=head1 NAME

NIOS - Perl binding for NIOS

=for html <a href="https://github.com/someone-stole-my-name/perl-nios/actions/workflows/CI.yml"><img src="https://github.com/someone-stole-my-name/perl-nios/actions/workflows/CI.yml/badge.svg?branch=master"></a>

=head1 CONSTRUCTOR

=for Pod::Coverage BUILD

=head2 new

The following attributes are required at construction time:

=over

=item * username

=item * password

=item * wapi_addr

=back

    my $n = NIOS->new(
        username  => "username",
        password  => "password",
        wapi_addr => "10.0.0.1",
    );

=head3 C<< insecure >>

Enable or disable verifying SSL certificates when C<< scheme >> is C<< https >>.

B<Default>: false

=head3 C<< password >>

Specifies the password to use to authenticate the connection to the remote instance of NIOS.

=head3 C<< scheme >>

B<Default>: https

=head3 C<< timeout >>

The amount of time before to wait before receiving a response.

B<Default>: 10

=head3 C<< username >>

Configures the username to use to authenticate the connection to the remote instance of NIOS.

=head3 C<< wapi_addr >>

DNS hostname or address for connecting to the remote instance of NIOS WAPI.

=head3 C<< wapi_version >>

Specifies the version of WAPI to use.

B<Default>: v2.7

=head3 C<< debug >>

=head1 Methods

=over

=item * All methods require a path parameter that can be either a resource type (eg: "record:a") or a WAPI Object reference.

=item * All methods return an L<HTTP::Response> object.

=back

=head3 C<< create >>

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

=head3 C<< delete >>

    # Delete a WAPI Object Reference
    $x = $n->delete(path => $object_ref);

=head3 C<< get >>

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

=head3 C<< update >>

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
