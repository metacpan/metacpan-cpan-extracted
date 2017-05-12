package Test::App::Controller::Root;

use Moose;
use namespace::autoclean;
use Catalyst::Action::RenderView;    # do autopreq picks it up

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body('index page');
}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

sub page_with_no_caching : Path('page_with_no_caching') {
    my ( $self, $c ) = @_;

    # Should have no effect as we are setting never_cache
    $c->cdn_max_age('1d');
    $c->browser_max_age('1w');

    $c->browser_never_cache(1);
    $c->cdn_never_cache(1);

    $c->response->body('No caching here');
}

sub some_caching : Path('some_caching') {
    my ( $self, $c ) = @_;

    $c->cdn_max_age('10m');
    $c->cdn_stale_if_error('2d');
    $c->cdn_stale_while_revalidate('1d');

    $c->browser_max_age('10s');
    $c->browser_stale_if_error('3d');
    $c->browser_stale_while_revalidate('2d');

    $c->response->body('Browser and CDN cacheing different max ages');
}

sub no_cdn_some_browser : Path('cdn_no_cache_browser_cache') {
    my ( $self, $c ) = @_;

    $c->cdn_never_cache(1);

    $c->browser_max_age('10s');

    $c->response->body('Browser cacheing, CDN no cache');
}

sub no_cdn_browser_not_set : Path('cdn_no_browser_cache_not_set') {
    my ( $self, $c ) = @_;

    $c->cdn_never_cache(1);

    $c->response->body('Browser cacheing not set, CDN no cache');
}

sub some_keys : Path('some_surrogate_keys') {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key( 'f%oo', 'W1-BBL3!' );

    $c->response->body('surrogate keys');
}

sub end : ActionClass('RenderView') { }

__PACKAGE__->meta->make_immutable;

1;
