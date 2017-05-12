package Authen::Simple::NIS;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';

use Net::NIS         qw[YPERR_KEY YPERR_SUCCESS];
use Net::NIS::Table  qw[];
use Params::Validate qw[];

our $VERSION = 0.3;

__PACKAGE__->options({
    domain => {
        type     => Params::Validate::SCALAR,
        optional => 1
    },
    map => {
        type     => Params::Validate::SCALAR,
        default  => 'passwd.byname',
        optional => 1
    }
});

sub check {
    my ( $self, $username, $password ) = @_;

    my $domain = $self->domain;

    unless ( $domain ||= Net::NIS::yp_get_default_domain() ) {

        $self->log->error( qq/Failed to obtain default NIS domain./ )
          if $self->log;

        return 0;
    }

    my $nis   = Net::NIS::Table->new( $self->map, $domain );
    my $entry = $nis->match($username);

    unless ( $nis->status == YPERR_SUCCESS ) {

        my $map = $self->map;

        if ( $nis->status == YPERR_KEY ) {

            $self->log->debug( qq/User '$username' was not found in map '$map' from domain '$domain'./ )
              if $self->log;
        }
        else {

            my $error = Net::NIS::yperr_string( $nis->status );

            $self->log->error( qq/Failed to lookup key '$username' in map '$map' from domain '$domain'. Reason: '$error'/ )
              if $self->log;
        }

        return 0;
    }

    my $encrypted = ( split( /:/, $entry ) )[1];

    unless ( $self->check_password( $password, $encrypted ) ) {

        $self->log->debug( qq/Failed to authenticate user '$username'. Reason: 'Invalid credentials'/ )
          if $self->log;

        return 0;
    }

    $self->log->debug( qq/Successfully authenticated user '$username' using domain '$domain'./ )
      if $self->log;

    return 1;
}

1;

__END__

=head1 NAME

Authen::Simple::NIS - Simple NIS authentication

=head1 SYNOPSIS

    use Authen::Simple::NIS;
    
    my $nis = Authen::Simple::NIS->new;
    
    if ( $nis->authenticate( $username, $password ) ) {
        # successfull authentication
    }
    
    # or as a mod_perl Authen handler

    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::NIS

    PerlSetVar AuthenSimpleNIS_domain "domain"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::NIS
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

NIS authentication.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters. The following options are
valid:

=over 8

=item * domain

NIS domain. Required unless it can be obtained from C<yp_get_default_domain()>.

    domain => 'domain'

=item * map

NIS map. Defaults to C<passwd.byname>.

    map => 'passwd.byname'

=item * log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::NIS')

=back

=item * authenticate( $username, $password )

Returns true on success and false on failure.

=back

=head1 SEE ALSO

L<Authen::Simple>.

L<Net::NIS>.

L<Net::NIS::Table>.

C<ypclnt(3)>.

=head1 AUTHOR

Christian Hansen C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
