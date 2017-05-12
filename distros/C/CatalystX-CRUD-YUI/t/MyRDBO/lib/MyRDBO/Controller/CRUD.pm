package MyRDBO::Controller::CRUD;
use strict;
use warnings;
use base qw( Catalyst::Controller );

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{current_view} = 'YUI';
    1;
}

sub default : Path {
    my ($self, $c) = @_;
    $c->stash->{template} = 'crud/default.tt';
}

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    if ( $c->req->param('as_xls') ) {
        $c->stash->{current_view} = 'Excel';
        $c->stash->{template}     = 'crud/list.xls.tt';
    }
}

1;

