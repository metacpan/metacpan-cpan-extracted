package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller/ }

with 'Catalyst::TraitFor::Controller::RenderView';

sub test_view : Global {
    my( $self, $c ) = @_;
    $c->config->{ view } = 'TestApp::View::TestView';
    return 1;
}

sub test_firstview : Global {
    my( $self, $c ) = @_;
    delete $c->config->{ view };
    return 1;
}

sub test_skipview : Global {
    my( $self, $c ) = @_;
    $c->res->body( 'Skipped View' );
}

1;
