package App::CamelPKI::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

App::CamelPKI::Controller::Root - Root controller for App::CamelPKI.

=head1 DESCRIPTION


=head1 METHODS

=over

=item I<default>

The page served for unkowns URIs.

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->status(404);
	$c->stash->{template} = "welcome.tt2";
}

=item I<end>

Transfer the control to the view, after having dealt with JSON errors in
collaboration with L<App::CamelPKI::Action::JSON>.

=cut

use App::CamelPKI::Action::JSON;
sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
    if (@{$c->error}) {
        my $statuscode; $statuscode = 403 if
            eval { $c->error->[0]
                       ->isa("App::CamelPKI::Error::Privilege") };
        App::CamelPKI::Action::JSON->finalize_errors($c);
        $c->response->status($statuscode) if $statuscode;
        if ($c->response->content_type =~ m|^text/plain|) {
            # Make a text error, not an HTML one.  REFACTORME: code
            # copied over from App::CamelPKI::Action::JSON
            my @folded_errors = map {
                # Wrap error messages at about 75 colums for legibility
                my @lines;
                while(s/^(.{75}\S*)\s//s) { push @lines, $1; }
                (@lines, $_);
            } (map { split m/\n/ } @{$c->error});
            $c->response->body(join("\n", @folded_errors));
            $c->clear_errors;
        } elsif ($c->error->[0]
                       ->isa("App::CamelPKI::Error::Privilege")) {
        	$c->stash->{message} = "Insufficient privilege to execute this operation. Please contact the administrator if you think you should.";
        	$c->stash->{template} = 'message.tt2';                     	
        } else {
        	#Not known errors
        	$c->stash->{error} = $c->error->[0];
        	$c->stash->{template} = 'error.tt2';
        }
        $c->clear_errors;
    }
    
}

=back

=cut

1;
