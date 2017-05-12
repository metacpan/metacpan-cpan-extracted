package TestApp::Controller::Root;

use Moose;

BEGIN { extends 'Catalyst::Controller' }


__PACKAGE__->config( namespace => '' );


sub default : Private {
    my ( $self, $c ) = @_;

    $c->res->body('not found');
    $c->res->status(404);
}

sub index : Path Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body('ok');
}

sub revision : Local Args(0) {
	my ( $self, $c ) = @_;

	$c->res->body( $c->config->{ version } );
}


__PACKAGE__->meta->make_immutable;

1;

