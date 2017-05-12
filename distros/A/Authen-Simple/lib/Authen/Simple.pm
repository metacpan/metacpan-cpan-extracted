package Authen::Simple;

use strict;
use warnings;

use Params::Validate qw[];

our $VERSION = '0.5';

sub new {
    my $class = shift;

    my %adapter = (
        isa      => 'Authen::Simple::Adapter',
        type     => Params::Validate::OBJECT,
        optional => 1
    );

    my @spec     = ( { %adapter, optional => 0 }, ( \%adapter ) x @_ );
    my $adapters = Params::Validate::validate_pos( @_, @spec );

    return bless( $adapters, $class );
}

sub authenticate {
    my ( $self, $username, $password ) = @_;

    foreach ( $username, $password ) {
        return 0 unless defined($_) && !ref($_) && length($_);
    }

    foreach my $adapter ( @{$self} ) {
        return 1 if $adapter->authenticate( $username, $password );
    }

    return 0;
}

1;

__END__

=head1 NAME

Authen::Simple - Simple Authentication

=head1 SYNOPSIS

    use Authen::Simple;
    use Authen::Simple::Kerberos;
    use Authen::Simple::SMB;

    my $simple = Authen::Simple->new(
        Authen::Simple::Kerberos->new( realm => 'REALM.COMPANY.COM' ),
        Authen::Simple::SMB->new( domain => 'DOMAIN', pdc => 'PDC' )
    );
    
    if ( $simple->authenticate( $username, $password ) ) {
        # successfull authentication
    }

=head1 DESCRIPTION

Simple and consistent framework for authentication.

=head1 METHODS

=over 4

=item * new

This method takes an array of C<Authen::Simple> adapters. Required.

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple::ActiveDirectory>.

L<Authen::Simple::CDBI>.

L<Authen::Simple::DBI>.

L<Authen::Simple::FTP>.

L<Authen::Simple::HTTP>.

L<Authen::Simple::Kerberos>.

L<Authen::Simple::LDAP>.

L<Authen::Simple::NIS>.

L<Authen::Simple::PAM>.

L<Authen::Simple::Passwd>.

L<Authen::Simple::POP3>.

L<Authen::Simple::RADIUS>.

L<Authen::Simple::SMB>.

L<Authen::Simple::SMTP>.

L<Authen::Simple::SSH>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
