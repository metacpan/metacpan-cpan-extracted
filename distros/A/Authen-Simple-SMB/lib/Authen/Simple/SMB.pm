package Authen::Simple::SMB;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Authen::Smb;
use Params::Validate qw[];

our $VERSION = 0.1;

__PACKAGE__->options({
    domain => {
        type     => Params::Validate::SCALAR,
        optional => 0
    },
    pdc => {
        type     => Params::Validate::SCALAR,
        optional => 0
    },
    bdc => {
        type     => Params::Validate::SCALAR,
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $domain = $self->domain;
    my $status = Authen::Smb::authen( $username, $password, $self->pdc, $self->bdc, $domain );

    if ( $status == 0 ) { # NTV_NO_ERROR

        $self->log->debug( qq/Successfully authenticated user '$username' using domain '$domain'./ )
          if $self->log;

        return 1;
    }

    if ( $status == 1 ) { # NTV_SERVER_ERROR
        $self->log->error( qq/Failed to authenticate user '$username' using domain '$domain'. Reason: 'Received a Server Error'/ )
          if $self->log;
    }

    if ( $status == 2 ) { # NTV_PROTOCOL_ERROR
        $self->log->error( qq/Failed to authenticate user '$username' using domain '$domain'. Reason: 'Received a Protocol Error'/ )
          if $self->log;
    }

    if ( $status == 3 ) { # NTV_LOGON_ERROR
        $self->log->debug( qq/Failed to authenticate user '$username' using domain '$domain'. Reason: 'Invalid credentials'/ )
          if $self->log;
    }

    return 0;
}

1;

__END__

=head1 NAME

Authen::Simple::SMB - Simple SMB authentication

=head1 SYNOPSIS

    use Authen::Simple::SMB;
    
    my $smb = Authen::Simple::SMB->new( 
        domain => 'DOMAIN', 
        pdc    => 'PDC'
    );
    
    if ( $smb->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::SMB

    PerlSetVar AuthenSimpleSMB_domain "DOMAIN"
    PerlSetVar AuthenSimpleSMB_pdc    "PDC"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::SMB
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

Authenticate against an SMB server.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * domain

Domain to authenticate against. Required.

    domain => 'NTDOMAIN'

=item * pdc

Primary Domain Controller. Required.

    pdc => 'PDC'

=item * bdc

Backup Domain Controller.

    bdc => 'BDC'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::SMB')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Authen::Smb>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
