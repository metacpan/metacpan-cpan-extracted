package Authen::Simple::POP3;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Net::POP3;
use Params::Validate qw[];

our $VERSION = 0.2;

__PACKAGE__->options({
    host => {
        type     => Params::Validate::SCALAR,
        default  => 'localhost',
        optional => 1
    },
    port => {
        type     => Params::Validate::SCALAR,
        default  => 110,
        optional => 1
    },
    timeout => {
        type     => Params::Validate::SCALAR,
        default  => 60,
        optional => 1
    },
    method => {
        type     => Params::Validate::SCALAR,
        default  => 'plain',
        optional => 1,
        callbacks => {
            'valid option' => sub {
                $_[0] =~ /^apop|plain|sasl$/;
            }
        }
    }    
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $connection = Net::POP3->new(
        Host    => $self->host,
        Port    => $self->port,
        Timeout => $self->timeout
    );

    unless ( defined $connection ) {

        my $host   = $self->host;
        my $reason = $@ || $! || 'Unknown reason';

        $self->log->error( qq/Failed to connect to '$host'. Reason: '$reason'/ )
          if $self->log;

        return 0;
    }
    
    my $success = 0;

    if ( $self->method eq 'plain' ) {
        $success++ if $connection->login( $username, $password );
    }

    if ( $self->method eq 'sasl' ) {
        $success++ if $connection->auth( $username, $password );
    }

    if ( $self->method eq 'apop' ) {
        $success++ if $connection->apop( $username, $password );
    }
    
    unless ( $success ) {

        chomp( my $message = $connection->message || 'Unknown reason' );

        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: '$message'/ )
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

Authen::Simple::POP3 - Simple POP3 authentication

=head1 SYNOPSIS

    use Authen::Simple::POP3;
    
    my $pop3 = Authen::Simple::POP3->new( 
        host => 'pop3.company.com'
    );
    
    if ( $pop3->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::POP3

    PerlSetVar AuthenSimplePOP3_host "pop3.company.com"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::POP3
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

Authenticate against a POP3 service.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * host

Connection host, can be a hostname or IP number. Defaults to C<localhost>.

    host => 'ftp.company.com'
    host => '10.0.0.1'

=item * port

Connection port, defaults to C<110>.

    port => 110

=item * timeout

Connection timeout, defaults to 60.

    timeout => 60

=item * method

Authentication method, defaults to C<plain>. Valid options are C<apop>, 
C<plain>, C<sasl>.

    method => 'plain'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::POP3')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Net::POP3>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
