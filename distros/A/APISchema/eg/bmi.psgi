use strict;
use warnings;
use lib '../lib';
use lib glob '../modules/*/lib/';

use Plack::Builder;
use Plack::Request;
use APISchema::DSL;
use APISchema::Generator::Router::Simple;
use Plack::App::APISchema::Document;

use JSON qw(decode_json encode_json);

my $schema = APISchema::DSL::process {
    include '../t/fixtures/bmi.def';
};

my $router = do {
    my $generator = APISchema::Generator::Router::Simple->new;
    $generator->generate_router($schema);
};

my $app = sub {
    my $env = shift;

    my $match = $router->match($env);

    return [404, [], ['not found']] unless $match;

    my $req = Plack::Request->new($env);

    my $payload = decode_json($req->content);

    my $bmi = $payload->{weight} / ($payload->{height} * $payload->{height});

    return [200, ['Content-Type' => 'application/json'], [encode_json({value => $bmi})]];
};

builder {
    enable "APISchema::ResponseValidator", schema => $schema;
    enable "APISchema::RequestValidator",  schema => $schema;
    mount '/doc/' => Plack::App::APISchema::Document->new(
        schema => $schema,
    )->to_app;

    mount '/' => $app;
}

__END__

=encoding utf-8

=head1 NAME

BMI Calculator

=head1 NAME

Sample Application

=head1 HOW TO USE

Start the appliction.

    carton exec -- plackup bmi.psgi

Then,

    % curl -X POST -H "Content-type: application/json" -d '{"weight": 60, "height": '1.7'}' http://localhost:5000/bmi
    {"value":20.7612456747405}

Requests and Reponses to the API are validated by Middlewares.

    % curl -X POST -H "Content-type: application/json" -d 'hello' http://localhost:5000/bmi
    {"attribute":"Valiemon::Attributes::Required","position":"/required"}

    % curl -X POST -H "Content-type: application/json" -d '{"weight": 60, "height": 'a'}' http://localhost:5000/bmi
    {"attribute":"Valiemon::Attributes::Required","position":"/required"}

    % curl -X POST -H "Content-type: application/json" -d '{"weight": 60, "height": 'a'}' http://localhost:5000/bmi
    {"attribute":"Valiemon::Attributes::Required","position":"/required"}

    % curl -X POST -H "Content-type: application/json" -d '{"weight": 60}' http://localhost:5000/bmi
    {"attribute":"Valiemon::Attributes::Required","position":"/required"}

You can read the document of API at L<http://localhost:5000/doc/>
