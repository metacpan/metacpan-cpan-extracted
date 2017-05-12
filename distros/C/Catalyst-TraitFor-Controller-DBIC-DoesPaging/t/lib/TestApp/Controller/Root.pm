package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller' };
 with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';

__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{js} = { foo => 1 };
}

sub test_paginate :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map +{ id => $_->id }, $self->paginate($c, $c->model('DB::Stations'))->all ];
}

sub test_page_and_sort :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map $_->TO_JSON, $self->paginate($c, $c->model('DB::Stations'))->all ];
}

sub test_search :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map $_->TO_JSON, $self->search($c, $c->model('DB::Stations'))->all ];
}

sub test_sort :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map $_->TO_JSON, $self->sort($c, $c->model('DB::Stations'))->all ];
}

sub test_simple_search :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map $_->TO_JSON, $self->simple_search($c, $c->model('DB::Stations'))->all ];
}

sub test_simple_sort :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [ map $_->TO_JSON, $self->simple_sort($c, $c->model('DB::Stations'))->all ];
}

sub test_simple_deletion :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->simple_deletion($c, $c->model('DB::Stations'));
}

sub test_simple_deletion_multipk :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->simple_deletion($c, $c->model('DB::MultiPk'));
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : Private {
   my ( $self, $c ) = @_;
   $c->forward( 'TestApp::View::JSON' );
}

1;
