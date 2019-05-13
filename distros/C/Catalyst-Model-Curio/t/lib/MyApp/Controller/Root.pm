package MyApp::Controller::Root;

use Moose;
use strictures 2;
use namespace::clean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Hello World!' );
}

sub single_set :Path('/single_set') :Args(2) {
    my ($self, $c, $key, $value) = @_;

    $c->model('SingleCache')->chi->set( $key, $value );

    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Cache value set' );
}

sub single_get :Path('/single_get') :Args(1) {
    my ($self, $c, $key) = @_;

    my $value = $c->model('SingleCache')->chi->get( $key );

    $c->res->content_type( 'text/plain' );
    $c->res->body( defined($value) ? $value : '' );
}

sub keyed_set :Path('/keyed_set') :Args(2) {
    my ($self, $c, $key, $value) = @_;

    $c->model('KeyedCache')->chi->set( $key, $value );

    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Cache value set' );
}

sub keyed_get :Path('/keyed_get') :Args(1) {
    my ($self, $c, $key) = @_;

    my $value = $c->model('KeyedCache')->chi->get( $key );

    $c->res->content_type( 'text/plain' );
    $c->res->body( defined($value) ? $value : '' );
}

sub multi_set :Path('/multi_set') :Args(3) {
    my ($self, $c, $curio_key, $key, $value) = @_;

    $c->model("MultiCache::$curio_key")->chi->set( $key, $value );

    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Cache value set' );
}

sub multi_get :Path('/multi_get') :Args(2) {
    my ($self, $c, $curio_key, $key) = @_;

    my $value = $c->model("MultiCache::$curio_key")->chi->get( $key );

    $c->res->content_type( 'text/plain' );
    $c->res->body( defined($value) ? $value : '' );
}

sub default_set :Path('/default_set') :Args(2) {
    my ($self, $c, $key, $value) = @_;

    $c->model("MultiCache")->chi->set( $key, $value );

    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Cache value set' );
}

sub default_get :Path('/default_get') :Args(1) {
    my ($self, $c, $key) = @_;

    my $value = $c->model("MultiCache")->chi->get( $key );

    $c->res->content_type( 'text/plain' );
    $c->res->body( defined($value) ? $value : '' );
}

sub default :Path {
    my ($self, $c) = @_;

    $c->res->status(404);
    $c->res->content_type( 'text/plain' );
    $c->res->body( 'Page not found' );
}

1;
