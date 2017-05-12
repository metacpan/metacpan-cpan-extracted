#!perl -w

use strict;
use warnings;

package App::CamelPKI::Action::JSON;

=head1 NAME

I<App::CamelPKI::Action::JSON> - Adapting the Catalyst execution
environment for JSON requests.

=head1 SYNOPSIS

In the root controller (prefered method - else you must do it
everywhere):

    use App::CamelPKI::Action::JSON;
    sub end : ActionClass('RenderView') {
        my ($self, $c) = @_;
        App::CamelPKI::Action::JSON->finalize_errors($c);
    }

In a regular controller:

    sub my_json_controller : ActionClass("+App::CamelPKI::Action::JSON") {
        my ($self, $c, $request_structure) = @_;
        ...
    }


Note: the C<< MyAction("JSON") >> form documented in
L<Catalyst::Manual::Actions> is not implemented in the version of
Catalyst released with Ubuntu Edgy, so we don't use it for now (as
Edgy is the current development platform).

=head1 DESCRIPTION

The C<ActionClass("+App::CamelPKI::Action::JSON")> annotation states that
this Catalyst action process and returns JSON.  Affixing this
annotation changes the behavior of Catalyst in the following ways:

=over

=item *

The L<App::CamelPKI::View::JSON> view is selected;

=item *

If an error is raised, it is served in C<text/plain> instead of HTML
(see L<App::CamelPKI/end>);

=item *

The I<cross-site request forgery> attack
(<http://en.wikipedia.org/wiki/JSON#Security_issues>) is blocked.

=back

=head2 How to call a JSON view to do JSON-RPC

Set the C<Accept> header to a value containing the substring
C<application/json>, lest the request be rejected.  This is to thwart
the I<cross-site request forgery> attack, by ensuring that the deputy
is not confused (that is, that the browser actually was aware that it
was invoking a JSON resource).

=cut

use base 'Catalyst::Action';
use utf8;
use File::Slurp ();
use JSON 1.07 ();

=head1 METHODS

=over

=item I<execute($controller, $c)>

Performs half of this module's mojo. All the gory details are in
L<Catalyst::Manual::Actions>.

=cut

sub execute {
     my $self = shift;
     my ($controller, $c ) = @_;

     $c->stash->{current_view} = "JSON";
     unless ($c->request->header("Accept") =~ m|application/json|i) {
         utf8::decode(my $error = <<"MESSAGE");
To perform a JSON request, please set the "Accept" header to a value
containing "application/json".
MESSAGE
         die $error;
     }

     my @jsoninput;
     if ($c->request->method eq "POST" &&
         $c->request->content_type eq "application/json") {
         my $jsoninput = $self->_request_body($c);
         local $JSON::UTF8 = 1;
         push @jsoninput, scalar(JSON::from_json($jsoninput));
     }

     $self->NEXT::execute( @_ , @jsoninput );
};

=item I<finalize_errors($c)>

Performs the other half of this module's mojo: signaling errors in
text format if an error occurs, and if L</execute> has been called for
this request. To be called from the C<end> action of the root
controller, as indicated in L</SYNOPSIS>.

=cut

sub finalize_errors {
    my ($self, $c) = @_;
    if ( $c->stash->{current_view} &&
         ($c->stash->{current_view} eq "JSON") && @{$c->error} ) {
        my @folded_errors = map {
            # Wrap error messages at about 75 colums for legibility
            my @lines;
            while(s/^(.{75}\S*)\s//s) { push @lines, $1; }
            (@lines, $_);
        } (map { split m/\n/ } @{$c->error});
        $c->response->body(join("\n", @folded_errors));

        $c->response->status(500);
        $c->response->content_type("text/plain");
        $c->clear_errors;
    }
    return 1;
}

=begin internals

=head2 _request_body($c)

Returns the content of the POST request, if any.

Note that there seems to be plans in Catalyst to provide a hand-made
HTTP::Request to controller tests, but as of 5.7006 it is undocumented
and doesn't seem to accept POST requests with a body.  Therefore,
_request_body will shamelessy attempt to read global variable
$App::CamelPKI::Action::JSON::request_body_for_tests, and return its value
if defined; L<App::CamelPKI::Test> hooks into this band aid to pass the
JSON request body.

=end internals

=cut

sub _request_body {
    my ($self, $c) = @_;
    our $request_body_for_tests;
    # During tests (App::CamelPKI::Test is at work there):
    return $request_body_for_tests if defined $request_body_for_tests;
    # In a Catalyst server (strange we have to slurp, it doesn't seem
    # to reconcile with what the doc says):
    return scalar File::Slurp::read_file($c->request->body);
}

=back

=cut

1;

