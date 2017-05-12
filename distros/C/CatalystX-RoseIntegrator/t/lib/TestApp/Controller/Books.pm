package TestApp::Controller::Books;

use strict;
use base qw/TestApp::Controller::Base/;

sub edit : Local Form('/books/basic') {
    my ( $self, $c, @args ) = @_;

    my $form = $self->form;
    $form->add_field('email', { type  => 'email'} );

    if ($form->was_submitted) {
        if ($self->has_error) {
            $c->stash->{ERROR} = "INVALID FORM";
            $form->add_field('_invalid_fields',
			     { type  => 'hidden',
			       value => join( "|", map { $_->name } grep { $_->error } $form->fields ),
			   });
        } else {
            return $c->response->body("VALID FORM");
        }
    }
    
    $form->method('GET');
    $c->stash->{template} = "books/form.tt";
}

sub edit_item : Local Form('/books/edit') {
    my ( $self, $c ) = @_;
    $c->stash->{template} = "books/form.tt";
}

sub basic : Local Form {
    my ( $self, $c ) = @_;

    $c->stash->{template} = "books/form.tt";
    my $form = $self->form;
    $form->add_field('email', { type => 'email' });
}

1;
