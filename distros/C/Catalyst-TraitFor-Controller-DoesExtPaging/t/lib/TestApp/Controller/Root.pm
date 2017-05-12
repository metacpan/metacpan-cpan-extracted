package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller' };
 with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';
 with 'Catalyst::TraitFor::Controller::DoesExtPaging';

__PACKAGE__->config->{namespace} = '';

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{js} = { foo => 1 };
}

sub test_parcel :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->ext_parcel( [ map +{ id => $_->id }, $self->paginate($c, $c->model('DB::Stations'))->all ] );
}

sub test_parcel2 :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->ext_parcel( [ map +{ id => $_->id }, $self->paginate($c, $c->model('DB::Stations'))->all ], 1_000_000 );
}

sub test_paginate :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->ext_paginate( $self->paginate($c, $c->model('DB::Stations')));
}

sub test_paginate2 :Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = $self->ext_paginate( $self->paginate($c, $c->model('DB::Stations')), sub { { id => $_[0]->id } } );
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
