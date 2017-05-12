# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp::Controller::Base;

use strict;
use base qw/Catalyst::Controller::FormBuilder::MultiForm/;

# setup is only necessary for running tests
# since the template system is not known

our @TEMPLATES = ( 'HTML::Template', 'Mason', 'TT' );

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
}

1;
