package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub expect_any :Local :Args(0) ExpectUploads {
    my ($self, $c) = @_;
    $c->response->body("Hit expect_any");
}
sub expect_image :Local :Args(0) ExpectUploads(image/png) {
    my ($self, $c) = @_;
    $c->response->body("Hit expect_image");
}


__PACKAGE__->meta->make_immutable;

1;
