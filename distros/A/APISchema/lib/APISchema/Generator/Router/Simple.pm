package APISchema::Generator::Router::Simple;
use strict;
use warnings;

use Hash::Merge::Simple qw(merge);
use Class::Load qw(load_class);
use Class::Accessor::Lite (
    new => 1,
    ro  => [qw(router_class)],
);

use constant ROUTER_CLASS => 'Router::Simple';

sub generate_router {
    my ($self, $schema) = @_;

    my $router_class = $self->router_class // ROUTER_CLASS;
    my $router = load_class($router_class)->new;

    $self->inject_routes($schema, $router);
}

sub inject_routes {
    my ($self, $schema, $router) = @_;

    my $router_class = ref $router;

    for my $route (@{$schema->get_routes}) {
        my $option = $route->option // {};
        $option = merge $option, $option->{$router_class} // {};
        $router->connect($route->title, $route->route => $route->destination, {
            method => $route->method,
            map { $_ => $option->{$_} } qw(host on_match),
        });
    }

    $router;
}

1;
