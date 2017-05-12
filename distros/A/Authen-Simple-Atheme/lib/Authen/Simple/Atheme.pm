use strict;
use warnings;
package Authen::Simple::Atheme;

use base 'Authen::Simple::Adapter';

use Atheme;
use Params::Validate qw[];

our $VERSION = 0.3;

__PACKAGE__->options({
    host => {
        type     => Params::Validate::SCALAR,
        default  => 'localhost',
        optional => 1
    },
    port => {
        type     => Params::Validate::SCALAR,
        default  => 8080,
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $atheme = Atheme->new( url => 'http://'.$self->host.':'.$self->port.'/xmlrpc');
    my $result = $atheme->login({
            nick => $username,
            pass => $password,
            address => '0.0.0.0'
        });
    unless ($result->{type} eq 'success') {
        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: '$result->string'/ )
            if $self->log;
        return 0;
    }
    $self->log->debug( qq/Successfully authenticated user '$username'./ ) if $self->log;
    return 1;
}

sub register {
    my ( $self, $username, $password, $email ) = @_;
    my $atheme = Atheme->new( url => 'http://'.$self->host.':'.$self->port.'/xmlrpc');
    my $result = $atheme->call_svs({
            authcookie => '',
            nick => '',
            address => '0.0.0.0',
            svs => 'NickServ',
            cmd => 'REGISTER',
            params => [ $username, $password, $email ]
        });
    return $result;
}
1;

__END__

=head1 NAME

Authen::Simple::Atheme - Simple authentication to Atheme IRC services

=head1 SYNOPSIS

    use Authen::Simple::Atheme;

    my $auth = Authen::Simple::Atheme->new(
        host => 'services.network.tld',
        port => 8080
    );

    if ( $auth->authenticate( $username, $password ) ) {
        # successful authentication
    }

=head1 DESCRIPTION

Atheme authentication

=head1 METHODS

=over 4

=item new

This method takes a hash of parameters. The following options are valid:

=over 8

=item host

Connection host, can be a hostname or IP address. Defaults to C<localhost>.

=item port

Connection port, defaults to C<8080>.

=item log

Any object that supports C<debug>, C<info>, C<error>, and C<warn>.

    log => Log::Log4perl->ge_logger('Authen::Simple::Atheme')

=back

=item authenticate

This method takes two parameters, a username and a password (In that order).
Returns true on success and false on failure.

=back

=item register

This method takes three parameters, a username, a password, and an email address (In that order).
Returns the XMLRPC hash given to it by Atheme.

=head1 SEE ALSO

L<Authen::Simple>

L<Atheme>

=head1 AUTHOR

Alexandria M. Wolcott C<alyx@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
