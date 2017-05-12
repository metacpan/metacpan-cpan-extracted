package Auth::Kokolores::Request;

use Moose;

# ABSTRACT: saslauthd protocol request object
our $VERSION = '1.01'; # VERSION


use Digest::MD5 qw(md5_base64);

has 'username' => ( is => 'rw', isa => 'Str', required => 1 );
has 'password' => ( is => 'rw', isa => 'Str', required => 1 );

has 'fingerprint' => (
  is => 'ro', isa => 'Str', lazy => 1,
  default => sub {
    my $self = shift;
    return md5_base64( $self->username.':'.$self->password );
  },
);

has 'parameters' => (
  is => 'ro', isa => 'HashRef',
  default => sub { {} },
  traits => [ 'Hash' ],
  handles => {
    set_param => 'set',
    get_param => 'get',
  },
);


has 'server' => (
  is => 'ro',
  isa => 'Net::Server',
  required => 1,
  handles => {
    log => 'log',
  },
);


has 'userinfo' => (
  is => 'ro', isa => 'HashRef', lazy => 1,
  default => sub { {} },
  traits => [ 'Hash' ],
  handles => {
    get_info => 'get',
    set_info => 'set',
  },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Request - saslauthd protocol request object

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This class holds all information associated with an authentication request.
It is passed to all authentication plugins.

=head1 ATTRIBUTES

=head2 username

The username passed within the request.

=head2 password

The password passed within the request.

=head2 parameters

Additional request parameters.

Other than the required parameters username and password.

=head2 fingerprint

A fingerprint for the authentication based on username + password.

=head2 server

A reference to the L<Auth::Kokolores> server object.

=head2 userinfo

A hashref holding additional information to be passed between plugins.

Use get_info and set_info methods to access fields.

=head1 METHODS

=head2 get_param( $key )

Retrieve field $key from parameters.

=head2 set_param( $key, $value )

Set field $key to $value in parameters.

=head2 get_info( $key )

Retrieve field $key from userinfo.

=head2 set_info( $key, $value )

Set field $key to $value in userinfo.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
