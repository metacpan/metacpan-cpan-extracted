#!perl -w

package App::CamelPKI::Controller::CA::Template::CA;

use strict;
use warnings;

=head1 NAME

App::CamelPKI::Controller::CA::Template::CA - Controller for
certification and revocation of CA processing nodes.

=head1 DESCRIPTION

This class inherits from L<App::CamelPKI::Controller::CA::Template::Base>,
which contains all relevant documentation.

=cut

use base 'App::CamelPKI::Controller::CA::Template::Base';
use App::CamelPKI::CertTemplate::CA;

=head1 METHODS

=head2 _list_template_shortnames

Returns the list of the short names of the templates this controller
deals with.

=cut

sub _list_template_shortnames { qw(CA2) }

1;
