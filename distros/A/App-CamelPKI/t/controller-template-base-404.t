#!perl -w

use strict;

=head1 NAME

B<controller-template-base-404.t> - Tests that the URLs of the form
B<>, despite being declared C<: Local> in
L<App::CamelPKI::Controller::CA::Template::Base>, are not mapped into the
application's URI namespace.  A request to same should therefore go
404.

=cut

use Test::More tests => 2;
use Catalyst::Test "App::CamelPKI";
is(request("/ca/template/base/no_such_page__really")->code, 404,
  "witness experiment");
is(request("/ca/template/base/certifyJSON")->code, 404, "404-compliant");
