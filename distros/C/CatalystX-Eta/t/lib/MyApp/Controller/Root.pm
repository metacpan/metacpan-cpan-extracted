package MyApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }
__PACKAGE__->config( default => 'application/json', );
use utf8;
use JSON::MaybeXS;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{rest} = { Perl => 'awesome!' };

    $c->response->status(200);
}

sub root : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub default : Path {
    my ( $self, $c ) = @_;

    $self->status_bad_request( $c, message => 'Endpoint not found!' );
    $c->response->status(404);
}

sub error_404 : Private {
    my ( $self, $c, $foo ) = @_;
    my $x = $c->req->uri;

    $self->status_bad_request( $c,
        message => 'You requested something that does not exists or you do not have permissions for so.' );

    $c->response->status(404);
}

sub error_500 : Private {
    my ( $self, $c, $arg ) = @_;

    $self->status_bad_request( $c, $arg || 'error' );

    $c->response->status(500);

}

__PACKAGE__->meta->make_immutable;

1;
