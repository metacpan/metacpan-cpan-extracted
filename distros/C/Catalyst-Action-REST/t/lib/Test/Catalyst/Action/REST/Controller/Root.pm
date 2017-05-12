package Test::Catalyst::Action::REST::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends qw/Catalyst::Controller::REST/ }

__PACKAGE__->config( namespace => '' );

sub begin {}  # Don't need serialization..

sub test : Local : ActionClass('REST') {
    my ( $self, $c ) = @_;
    $c->stash->{'entity'} = 'something';
}

sub test_GET {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} .= " GET";
    $c->forward('ok');
}

sub test_POST {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} .= " POST";
    $c->forward('ok');
}

sub test_PUT {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} .= " PUT";
    $c->forward('ok');
}

sub test_DELETE {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} .= " DELETE";
    $c->forward('ok');
}

sub test_OPTIONS {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} .= " OPTIONS";
    $c->forward('ok');
}

sub notreally : Local : ActionClass('REST') {
}

sub notreally_GET {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} = "notreally GET";
    $c->forward('ok');
}

sub not_implemented : Local : ActionClass('REST') {
}

sub not_implemented_GET {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} = "not_implemented GET";
    $c->forward('ok');
}

sub not_implemented_not_implemented {
    my ( $self, $c ) = @_;

    $c->stash->{'entity'} = "Not Implemented Handler";
    $c->forward('ok');
}

sub not_modified : Local : ActionClass('REST') { }

sub not_modified_GET {
    my ( $self, $c ) = @_;
    $c->res->status(304);
    return 1;
}

sub ok : Private {
    my ( $self, $c ) = @_;

    $c->res->content_type('text/plain');
    $c->res->body( $c->stash->{'entity'} );
}

sub end : Private {} # Don't need serialization..

1;

