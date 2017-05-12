package Authen::Simple::SSH;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Net::SSH::Perl;
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
        default  => 22,
        optional => 1
    },
    protocol => {
        type     => Params::Validate::SCALAR,
        default  => 2,
        optional => 1
    },
    cipher => {
        type     => Params::Validate::SCALAR,
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $host   = $self->host;
    my %params = (
        port     => $self->port,
        protocol => $self->protocol,
        cipher   => $self->cipher
    );

    my $connection;

    eval { $connection = Net::SSH::Perl->new( $host, %params ) };

    if ( my $error = $@ ) {

        chomp $error;

        $self->log->error( qq/Failed to connect to '$host'. Reason: '$@'/ )
          if $self->log;

        return 0;
    }

    eval { $connection->login( $username, $password ) };

    if ( my $error = $@ ) {

        chomp $error;

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

Authen::Simple::SSH - Simple SSH authentication

=head1 SYNOPSIS

    use Authen::Simple::SSH;
    
    my $ssh = Authen::Simple::SSH->new(
        host => 'host.company.com'
    );
    
    if ( $ssh->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::SSH

    PerlSetVar AuthenSimpleSSH_host "host.company.com"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::SSH
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>    

=head1 DESCRIPTION

SSH authentication.

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

Connection port, default to C<22>.

    port => 22

=item * protocol

Connection protocol, defaults to C<2>.

    protocol => 1

=item * cipher

Connection cipher.

    cipher => 'Blowfish'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::SSH')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Net::SSH::Perl>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
