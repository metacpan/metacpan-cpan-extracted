package # hide from PAUSE
    TestApp::Controller::Base;

use strict;
use base qw/Catalyst::Controller::Validation::DFV/;

# setup is only necessary for running tests
# since the template system is not known

our @TEMPLATES = ( 'TT', 'HTML::Template', 'Mason' );

sub _get_view : Local {
    my ( $self, $c ) = @_;

    # default to 'Rendered' view when no template plugin is available
    # Rendered simply prints FormBuilder->render
    my $type = $c->config->{template_type};

    my $my_view = "TestApp::Component::$type";
    if ( $c->component($my_view) ) {
        return $my_view;
    }
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( !$c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }
    return 1 if $c->req->method eq 'HEAD';
    return 1 if length( $c->response->body );
    return 1 if scalar @{ $c->error } && !$c->stash->{template};
    return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;

    my $my_view = $c->forward('_get_view')
      or die "Could not find a view to forward to.\n";

    $c->forward($my_view);

    # fill in any forms
    $c->forward('/base/refill_form');
}

1;
