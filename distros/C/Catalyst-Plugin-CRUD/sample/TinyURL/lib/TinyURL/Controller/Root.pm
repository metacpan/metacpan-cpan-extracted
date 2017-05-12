package TinyURL::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->languages( ['ja'] );
}

sub default : Private {
    my ( $self, $c ) = @_;

    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $id = $c->req->args->[0];
        my $model = $c->model('CDBI::TinyUrl')->retrieve($id);
        if (defined $model) {
            $c->res->redirect($model->long_url);
        } else {
            $c->forward( 'TinyUrl', 'create' );
        }
    } else {
        $c->forward( 'TinyUrl', 'create' );
    }
}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'template/tinyurl/list.tt'
      unless ( exists $c->stash->{template} );
    $c->forward( $c->view('TT') ) unless $c->response->body;
}

1;
