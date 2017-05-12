#!perl -w

use strict;

package App::CamelPKI::Controller::Test;
use base 'Catalyst::Controller';
use strict;
use warnings;

=head1 NAME

App::CamelPKI::Controller::Test - Catalyst learning tests.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

App-PKI controller that serves the URIs starting with C</test>.  Those
tests are eXtreme-Programming style ``learning tests'', that is, tiny
pieces of controllers and views to play with Catalyst to learn how it
works.

Contrary to all other kind of tests, learning tests are neither
normative (success is not required) nor automated (success criteria
may are not be implemented, or even formulated).

=head2 json_helloworld

Accepts a JSON parameter which contains an associative table with keys
"nom" (meaning last name in French) and "prenom" (first name), and
returns a JSON parameter which contain an associative table with a
welcome message for the C<salutation> key.  (For the fame of it,
"Bonjour" means "Hello" in French.)

=cut

sub json_helloworld : Local : ActionClass("+App::CamelPKI::Action::JSON") {
    my ($self, $c, $input) = @_;
    $c->stash->{salutation} = sprintf("Hello, %s %s !",
                                      $input->{prenom}, $input->{nom});
}

=head2 ca_permission_level

Returns ref($c->model("CA")), which is an indicator of the privilege
level that the HTTP/S client is wielding (deduced from its client
certificate in L<App::CamelPKI>). A JSON request is not needed, allowing
the use of C<curl> in command-line mode for testing purposes.

=cut

sub ca_permission_level : Local {
    my ($self, $c) = @_;

    require Data::Dumper;

    local $Data::Dumper::Indent = $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = $Data::Dumper::Terse = 1;

    $c->response->content_type("text/plain");
    $c->response->body
        (sprintf(<<'TEMPLATE',
ref($c->model("CA")) = "%s"
$c->engine->apache->subprocess_env =
  %s
TEMPLATE
                 ref($c->model("CA")),
                 Data::Dumper::Dumper([$c->engine->apache
                                       ->subprocess_env])));
}

=head2 throw_exception

As the name implies, throws a structured exception.

=cut

use App::CamelPKI::Error;
sub throw_exception : Local {
    throw App::CamelPKI::Error::User("cockpit error");
}

1;
