package Authen::Simple::RADIUS;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Authen::Radius;
use Params::Validate qw[];

our $VERSION = 0.1;

__PACKAGE__->options({
    host => {
        type     => Params::Validate::SCALAR,
        default  => 'localhost',
        optional => 1
    },
    port => {
        type     => Params::Validate::SCALAR,
        default  => 1812,
        optional => 1
    },
    timeout => {
        type     => Params::Validate::SCALAR,
        default  => 10,
        optional => 1
    },
    secret => {
        type     => Params::Validate::SCALAR,
        optional => 0
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $connection = Authen::Radius->new(
        Host    => sprintf( "%s:%d", $self->host, $self->port ),
        Secret  => $self->secret,
        Timeout => $self->timeout
    );

    unless ( defined $connection ) {

        my $host = $self->host;

        $self->log->error( qq/Failed to connect to '$host'. Reason: '$@'/ )
          if $self->log;

        return 0;
    }

    unless ( $connection->check_pwd( $username, $password ) ) {

        my $error = $connection->strerror;

        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::RADIUS - Simple RADIUS authentication

=head1 SYNOPSIS

    use Authen::Simple::RADIUS;
    
    my $radius = Authen::Simple::RADIUS->new(
        host   => 'radius.company.com',
        secret => 'secret'
    );
    
    if ( $radius->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::RADIUS

    PerlSetVar AuthenSimpleRADIUS_host "radius.company.com"
    PerlSetVar AuthenSimpleRADIUS_pdc  "secret"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::RADIUS
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>    

=head1 DESCRIPTION

RADIUS authentication.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * host

Connection host, can be a hostname or IP address. Defaults to C<localhost>.

    host => 'ldap.company.com'
    host => '10.0.0.1'

=item * port

Connection port, default to C<1812>.

    port => 1645

=item * timeout

Connection timeout, defaults to C<10>.

    timeout => 20

=item * secret

Shared secret. Required.

    secret => 'mysecret'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::RADIUS')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Radius>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
