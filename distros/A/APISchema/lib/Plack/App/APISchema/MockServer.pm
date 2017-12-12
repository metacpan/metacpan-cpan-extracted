package Plack::App::APISchema::MockServer;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(schema);
use Plack::Request;
use Encode qw(encode_utf8);

use APISchema::JSON;

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

    my $root = $self->schema->get_resource_root;

    my $route = $self->schema->get_route_by_name($router_simple_route->name);

    my $default_code = $route->default_responsible_code;
    my $response_resource = $route->canonical_response_resource($root, [
        $default_code
    ]);

    my $resolver = APISchema::Generator::Markdown::ResourceResolver->new(schema => $root);

    my $formatter = APISchema::Generator::Markdown::ExampleFormatter->new(
        resolver => $resolver,
        spec     => $response_resource,
    );

    # TODO: serve all headers defined in example
    # TODO: format body with encoding
    return [200, ['Content-Type' => 'application/json; charset=utf-8'], [encode_utf8($formatter->body)]];
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
