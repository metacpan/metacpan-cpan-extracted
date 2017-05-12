#!perl -w

package App::CamelPKI::Controller::CA::Template::SSL;

use strict;
use warnings;

=head1 NAME

App::CamelPKI::Controller::CA::Template::SSL - Controller for certification
and revocation of SSL clients and servers.

=head1 DESCRIPTION

This class inherits from L<App::CamelPKI::Controller::CA::Template::Base>,
which contains all relevant documentation.

=cut

use base 'App::CamelPKI::Controller::CA::Template::Base';
use App::CamelPKI::CertTemplate::SSL;

=head1 METHODS

=head2 _list_template_shortnames

Returns the list of the short names of the templates this controller
deals with.

=cut

sub _list_template_shortnames { qw(SSLServer SSLClient) }

sub _revocation_keys { ("dns", "role") }

sub _form_certify_template { "certificate/SSL_form_certify.tt2" }

sub _form_revoke_template { "certificate/SSL_form_revoke.tt2" }

sub _operations_available { "src/ssl/ssl_welcome.tt2" }

1;
