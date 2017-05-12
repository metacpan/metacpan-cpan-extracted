package FormFu::Controller::Author;

use strict;
use warnings;

use parent 'Catalyst::Controller';

sub create :Local {
    my ( $self, $c ) = @_;

    my $form = $c->model('FormFu')->form('author');

    if ( $form->submitted_and_valid ) {
        my $new_author = $c->model('Books::Author')->new_result({});
        $form->model->update($new_author);
        $c->response->redirect( $c->uri_for( $self->action_for('list')) );
    }
}

sub edit :Local :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $form = $c->model('FormFu')->form('author');
    my $author = $c->model('Books::Author')->find({ id => $id });

    $c->detach('/default') unless $author;

    if ( $form->submitted_and_valid ) {
        $form->model->update($author);
        $c->response->redirect( $c->uri_for( $self->action_for('list')) );
    } else {
        $form->model->default_values($author);
    }
}

sub list :Local {
    my ( $self, $c ) = @_;

    my @authors = $c->model('Books::Author')->all;
    $c->stash->{authors} = \@authors;
}

1;

