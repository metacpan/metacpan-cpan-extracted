package Authen::Simple::ActiveDirectory;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Net::LDAP           qw[]; 
use Net::LDAP::Constant qw[LDAP_INVALID_CREDENTIALS];
use Params::Validate    qw[];

our $VERSION = 0.3;

__PACKAGE__->options({
    host => {
        type     => Params::Validate::SCALAR | Params::Validate::ARRAYREF,
        default  => 'localhost',
        optional => 1
    },
    port => {
        type     => Params::Validate::SCALAR,
        default  => 389,
        optional => 1
    },
    timeout => {
        type     => Params::Validate::SCALAR,
        default  => 60,
        optional => 1
    },
    principal => {
        type     => Params::Validate::SCALAR,
        optional => 0
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $connection = Net::LDAP->new( $self->host,
        port    => $self->port,
        timeout => $self->timeout
    );

    unless ( defined $connection ) {

        my $host = $self->host;

        $self->log->error( qq/Failed to connect to '$host'. Reason: '$@'/ )
          if $self->log;

        return 0;
    }

    my $user    = sprintf( '%s@%s', $username, $self->principal );
    my $message = $connection->bind( $user, password => $password );

    if ( $message->is_error ) {

        my $error = $message->error;
        my $level = $message->code == LDAP_INVALID_CREDENTIALS ? 'debug' : 'error';

        $self->log->$level( qq/Failed to authenticate user '$user'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$user'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::ActiveDirectory - Simple ActiveDirectory authentication

=head1 SYNOPSIS

    use Authen::Simple::ActiveDirectory;
    
    my $ad = Authen::Simple::ActiveDirectory->new( 
        host      => 'ad.company.com',
        principal => 'company.com'
    );
    
    if ( $ad->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::ActiveDirectory

    PerlSetVar AuthenSimpleActiveDirectory_host      "ad.company.com"
    PerlSetVar AuthenSimpleActiveDirectory_principal "company.com"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::ActiveDirectory
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

Authenticate against Active Directory.

This implementation differs from L<Authen::Simple::LDAP> in way that it will 
try to bind directly as the users principial.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters.  The following options are
valid:

=over 8

=item * host

Connection host, can be a hostname, IP number or a URI. Defaults to C<localhost>.

    host => ldap.company.com
    host => 10.0.0.1
    host => ldap://ldap.company.com:389
    host => ldaps://ldap.company.com

=item * port

Connection port, default to 389. May be overriden by host if host is a URI.

    port => 389

=item * timeout

Connection timeout, defaults to 60.

    timeout => 60

=item * principal

The suffix in users principal, usally the domain or forrest. Required.

    principal => 'company.com'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::ActiveDirectory')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple::LDAP>.

L<Authen::Simple>.

L<Net::LDAP>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
