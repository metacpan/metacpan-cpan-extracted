package App::CamelPKI;

use warnings;
use strict;

=head1 NAME

App::CamelPKI - A multi-purpose PKI.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    script/camel_pki_server.pl

=head1 DESCRIPTION

Camel-PKI is an X509v3 Certification Authority (CA) programmed in Perl
and Catalyst. It relies on L<Crypt::OpenSSL::CA> for the low-level
cryptographic operations.

=cut

use Catalyst::Runtime '5.70';

use Catalyst qw/ConfigLoader Static::Simple/;

=head1 CONFIGURATION

The configuration file is camel_pki.yml. It must be placed at the
application root directory.  See the bundled file
C<camel_pki.yml.sample> for syntax details.

=cut

# When using ConfigLoader (as we do), this is how to set an
# overridable default value:
__PACKAGE__->config( name => 'App::CamelPKI' );

use App::CamelPKI::RestrictedClassMethod;
use App::CamelPKI::Error;
use App::CamelPKI::SysV::Apache;

__PACKAGE__->setup;

=head2 METHODS

=head2 model($modelname)

Returns an instance of one of the Catalyst generated object model (as
in L<Catalyst/model>), or an object with the same API but lesser
privilege, depending on the connected user rigths. If user has no
rights on $modelname, trigger an exception.

The overloading of this method is key to applying capability
discipline, because it forces the Principle of Least Authority (POLA)
onto Camel-PKI HTTP/S clients.

=cut

sub model {
    my ($self, $shortclass) = @_;

    my $full_model = $self->SUPER::model($shortclass);
    # Privileges are unconstrained except under Apache.
    return $full_model if (! App::CamelPKI::SysV::Apache->is_running_under);

    my $r = $self->engine->apache;
    my $client_dn = $r->subprocess_env("SSL_CLIENT_S_DN");

    my $admin_dn = '/O=CamelPKI.fr/OU=CamelPKI/OU=role/CN=administrator';

    # FIXME: privileges are immutable, and that makes the switch-case
    # below quite messy. In a future version, capabilities will be
    # fully movable and persisted next to the users that have them,
    # and this code will morph into a database.

    if ($shortclass eq "CA") {
        if (! defined $client_dn) {
            return $full_model->facet_crl_only;
        } elsif ($client_dn eq $admin_dn) {
            return $full_model->facet_operational;
        } else {
	warn "User $client_dn unknown";
            throw App::CamelPKI::Error::Privilege
                ("User unknown",
                 -dn => $client_dn);
        }
    } else {
        throw App::CamelPKI::Error::Privilege
            ("Only CA privileges are available to the controller for now.");
    }
}

=head2 setup_components

Overloaded from the parent class in order to lock down restricted
class methods in the Camel-PKI model after the respective classes are
loaded (see L<App::CamelPKI::RestrictedClassMethod>).  This only occurs in
production (that is, when running under Apache, as determined by
L<App::CamelPKI::SysV::Apache/is_running_under>), so that tests can still
call restricted methods freely.

=cut

sub setup_components {
    my $self = shift;
    $self->SUPER::setup_components(@_);
    return unless App::CamelPKI::SysV::Apache->is_running_under;
    my %brands = App::CamelPKI::RestrictedClassMethod->grab_all;
    # FIXME: this is just clumsy.  We should use one directory
    # capability for the CA instead (even though
    # ::RestrictedClassMethod is still useful to some extent eg to
    # disable debug methods).
    $brands{"App::CamelPKI::Model::CA"}->invoke
        ("set_brands",
         $brands{"App::CamelPKI::CA"}, $brands{"App::CamelPKI::CADB"});
}

=head1 SEE ALSO

L<App::CamelPKI::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Dominique QUATRAVAUX, C<< <domq at cpan.org> >>
Jeremie KLEIN, C<<grm at cpan.org>>

=head1 COPYRIGHT & LICENCE

Copyright 2007 Siemens Business Services S.A.S., all rights reserved.

This program is free software; you can redistribute it following the
same terms as Perl itself.

=cut

1;
