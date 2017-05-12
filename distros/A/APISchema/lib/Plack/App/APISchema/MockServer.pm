package Plack::App::APISchema::MockServer;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(schema);
use Plack::Request;

use JSON::XS qw(encode_json);

use APISchema::Generator::Router::Simple;
use APISchema::Generator::Markdown::ResourceResolver;
use APISchema::Generator::Markdown::ExampleFormatter;

sub call {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);

    my ($matched, $router_simple_route) = $self->router->routematch($env);

    unless ($matched) {
        return [404, ['Content-Type' => 'text/plain; charset=utf-8'], ['not found']];
    }

    my $resource_root = $self->schema->get_resource_root;

    my $route = $self->schema->get_route_by_name($router_simple_route->name);
    my $response_resource = $self->schema->get_resource_by_name($route->response_resource);

    my $resolver = APISchema::Generator::Markdown::ResourceResolver->new(schema => $resource_root);
    my $example = $resolver->example($response_resource->definition);

    my $response_body;
    if (ref $example) {
        $response_body = encode_json($example);
    } else {
        $response_body = $example;
    }

    return [200, ['Content-Type' => 'application/json; charset=utf-8'], [$response_body]];
}

sub router {
    my ($self) = @_;

    return $self->{router} if $self->{router};

    my $generator = APISchema::Generator::Router::Simple->new;
    $self->{router} = $generator->generate_router($self->schema);
}

1;
__END__

=head1 NAME

Plack::App::APISchema::MockServer - Mock Server for APISchema

=head1 SYNOPSIS

  use Plack::App::APISchema::MockServer;
  my $app = Plack::App::APISchema::MockServer->new($schema)->to_app;

=head1 DESCRIPTION

Plack::App::APISchema::MockServer mocks response with example of resource definitions.
