package Authen::Simple::Kerberos;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Authen::Krb5::Simple;
use Params::Validate qw[];

our $VERSION = 0.1;

__PACKAGE__->options({
    realm => {
        type     => Params::Validate::SCALAR,
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my @arguments = $self->realm ? ( realm => $self->realm ) : ();
    my $kerberos  = Authen::Krb5::Simple->new(@arguments);
    my $realm     = $kerberos->realm;

    unless ( $kerberos->authenticate( $username, $password ) ) {

        my $error = $kerberos->errstr;

        $self->log->debug( qq/Failed to authenticate user '$username' using realm '$realm'. Reason: '$error'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username' using realm '$realm'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::Kerberos - Simple Kerberos authentication

=head1 SYNOPSIS

    use Authen::Simple::Kerberos;
    
    my $kerberos = Authen::Simple::Kerberos->new(
        realm => 'REALM.COMPANY.COM'
    );
    
    if ( $kerberos->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::Kerberos

    PerlSetVar AuthenSimpleKerberos_realm "REALM.COMPANY.COM"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::Kerberos
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>    
    
=head1 DESCRIPTION

Kerberos authentication.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * realm

Kerberos realm.

    realm => 'REALM.COMPANY.COM'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::Kerberos')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Krb5::Simple>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
