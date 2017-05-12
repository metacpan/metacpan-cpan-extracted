package TestApp::Controller::NotCacheableWithActionRoles;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole' }

__PACKAGE__->config(
    action_roles => [qw( NotCacheableHeaders )]
);

sub dont_cache_me  : Local NotCacheable {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name ) );
}

sub no_notcacheable  : Local {
    my ($self, $c) = @_;
    $c->res->body( join(":", $c->action->name) );
}

sub own_headers  : Local NotCacheable {
    my ($self, $c) = @_;

    $c->response->header(
        'Expires' =>  'Wed, 26 May 2010 14:14:53 GMT',
        'Cache-Control' => 'public',
        'Last-Modified' => 'Wed, 26 May 2010 14:14:53 GMT',
    );

    $c->res->body( join(":", $c->action->name) );
}

1;
