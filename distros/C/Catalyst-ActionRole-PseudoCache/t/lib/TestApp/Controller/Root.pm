package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller::ActionRole' };

__PACKAGE__->config->{namespace} = '';

has run_once => (
   is      => 'rw',
   isa     => 'Bool',
   default => undef,
);

sub test :Local :Does(PseudoCache) PCUrl(/foo.txt) {
    my ( $self, $c ) = @_;

    # this is so that we can be sure the output is cached
    unless ($self->run_once) {
       $c->response->body('big fat output');
    } else {
       $c->response->body('something else');
    }

    $self->run_once(1);
}

sub test2 :Local :Does(PseudoCache) PCUrl(/static/foo.txt) PCPath(bar.txt) {
    my ( $self, $c ) = @_;

    $c->response->body('something else');
}

sub end : Private :ActionClass(RenderView) {}

1;
