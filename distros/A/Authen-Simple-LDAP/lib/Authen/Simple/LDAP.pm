package Authen::Simple::LDAP;

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
    version => {
        type     => Params::Validate::SCALAR,
        default  => 3,
        optional => 1
    },
    binddn => {
        type     => Params::Validate::SCALAR,
        depends  => [ 'bindpw' ],
        optional => 1
    },
    bindpw => {
        type     => Params::Validate::SCALAR,
        depends  => [ 'binddn' ],
        optional => 1
    },
    basedn => {
        type     => Params::Validate::SCALAR,
        optional => 1
    },
    scope => {
        type     => Params::Validate::SCALAR,
        default  => 'sub',
        optional => 1
    },
    filter => {
        type     => Params::Validate::SCALAR,
        default  => '(uid=%s)',
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $connection = Net::LDAP->new( $self->host,
        port    => $self->port,
        timeout => $self->timeout,
        version => $self->version
    );

    unless ( defined $connection ) {

        my $host = $self->host;

        $self->log->error( qq/Failed to connect to '$host'. Reason: '$@'/ )
          if $self->log;

        return 0;
    }

    my ( @credentials, $message, $search, $entry, $filter, $dn );

    @credentials = $self->binddn ? ( $self->binddn, password => $self->bindpw ) : ();
    $message     = $connection->bind(@credentials);

    if ( $message->is_error ) {

        my $error  = $message->error;
        my $binddn = $self->binddn;
        my $bind   = $binddn ? qq/with dn '$binddn'/ : "Anonymously";

        $self->log->error( qq/Failed to bind $bind. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    $filter = sprintf( $self->filter, ($username) x 10 );
    $search = $connection->search(
        base   => $self->basedn,
        scope  => $self->scope,
        filter => $filter,
        attrs  => ['1.1']
    );

    if ( $search->is_error ) {

        my $error   = $search->error;
        my $basedn  = $self->basedn;
        my $options = qq/basedn '$basedn' with filter '$filter'/;

        $self->log->error( qq/Failed to search $options. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    if ( $search->count == 0 ) {

        $self->log->debug( qq/User '$username' was not found with filter '$filter'./ )
          if $self->log;

        return 0;
    }

    if ( $search->count > 1 ) {

        my $count = $search->count;

        $self->log->warn( qq/Found $count matching entries for '$username' with filter '$filter'./ )
          if $self->log;
    }

    $entry   = $search->entry(0);
    $message = $connection->bind( $entry->dn, password => $password );
    $dn      = $entry->dn;

    if ( $message->is_error ) {

        my $error = $message->error;
        my $level = $message->code == LDAP_INVALID_CREDENTIALS ? 'debug' : 'error';

        $self->log->$level( qq/Failed to authenticate user '$username' with dn '$dn'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username' with dn '$dn'./ )
      if $self->log;

    return $dn;
}

1;

__END__

=head1 NAME

Authen::Simple::LDAP - Simple LDAP authentication

=head1 SYNOPSIS

    use Authen::Simple::LDAP;
    
    my $ldap = Authen::Simple::LDAP->new( 
        host    => 'ldap.company.com',
        basedn  => 'ou=People,dc=company,dc=net'
    );
    
    if ( $ldap->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::LDAP

    PerlSetVar AuthenSimpleLDAP_host   "ldap.company.com"
    PerlSetVar AuthenSimpleLDAP_basedn "ou=People,dc=company,dc=net"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::LDAP
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

Authenticate against a LDAP service.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * host

Connection host, can be a hostname, IP number or a URI. Defaults to C<localhost>.

    host => ldap.company.com
    host => 10.0.0.1
    host => ldap://ldap.company.com:389
    host => ldaps://ldap.company.com

=item * port

Connection port, default to C<389>. May be overriden by host if host is a URI.

    port => 389

=item * timeout

Connection timeout, defaults to 60.

    timeout => 60

=item * version 

The LDAP version to use, defaults to 3.

    version => 3

=item * binddn 

The distinguished name to bind to the server with, defaults to bind
anonymously.

    binddn => 'uid=proxy,cn=users,dc=company,dc=com'

=item * bindpw 

The credentials to bind with.

    bindpw => 'secret'

=item * basedn

The distinguished name of the search base.

    basedn => 'cn=users,dc=company,dc=com'

=item * filter

LDAP filter to use in search, defaults to C<(uid=%s)>.

    filter => '(uid=%s)'

=item * scope 

The search scope, can be C<base>, C<one> or C<sub>, defaults to C<sub>.

    filter => 'sub'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::LDAP')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 EXAMPLE USAGE

=head2 Apple Open Directory

    my $ldap = Authen::Simple::LDAP->new(
        host    => 'od.company.com',
        basedn  => 'cn=users,dc=company,dc=com',
        filter  => '(&(objectClass=inetOrgPerson)(objectClass=posixAccount)(uid=%s))'
    );

=head2 Microsoft Active Directory

    my $ldap = Authen::Simple::LDAP->new(
        host    => 'ad.company.com',
        binddn  => 'proxyuser@company.com',
        bindpw  => 'secret',
        basedn  => 'cn=users,dc=company,dc=com',
        filter  => '(&(objectClass=organizationalPerson)(objectClass=user)(sAMAccountName=%s))'
    );

Active Directory by default does not allow anonymous binds. It's recommended
that a proxy user is used that has sufficient rights to search the desired
tree and attributes.

=head1 SEE ALSO

L<Authen::Simple::ActiveDirectory>.

L<Authen::Simple>.

L<Net::LDAP>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
