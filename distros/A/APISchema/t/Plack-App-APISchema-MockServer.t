package t::Plack::App::APISchema::MockServer;
use lib '.';
use t::test;
use t::test::fixtures;
use Plack::Test;
use HTTP::Request::Common;

sub _require : Test(startup => 1) {
    my ($self) = @_;

    use_ok 'Plack::App::APISchema::MockServer';
}

sub instantiate : Tests {
    my $schema = APISchema::Schema->new;
    my $app = Plack::App::APISchema::MockServer->new(schema => $schema);

    isa_ok $app, 'Plack::App::APISchema::MockServer';
    is $app->schema, $schema;
    isa_ok $app->router, 'Router::Simple';
}

sub serve_document_bmi : Tests {
     my $schema = t::test::fixtures::prepare_bmi;
     my $app = Plack::App::APISchema::MockServer->new(schema => $schema)->to_app;

     subtest 'when valid request' => sub {
         test_psgi $app => sub {
             my $server = shift;
             my $res = $server->(POST '/bmi');
             is $res->code, 200;
             is $res->header('content-type'), 'application/json; charset=utf-8';
             is $res->content, q!{"value":19.5}!;
         }
     };

     subtest 'when invalid request' => sub {
         test_psgi $app => sub {
             my $server = shift;
             my $res = $server->(POST '/notfound');
             is $res->code, 404;
             is $res->header('content-type'), 'text/plain; charset=utf-8';
             is $res->content, q!not found!;
         }
     };
}

sub when_encoding_is_specified : Tests {
    my $schema = t::test::fixtures::prepare_bmi;
    $schema->register_route(
        method => 'POST',
        route => '/bmi_force_json',
        request_resource => {
            encoding => 'json',
            body => 'figure',
        },
        response_resource => {
            encoding => 'json',
            body => 'bmi',
        },
    );
    my $app = Plack::App::APISchema::MockServer->new(schema => $schema)->to_app;
    test_psgi $app => sub {
        my $server = shift;
        my $res = $server->(POST '/bmi_force_json');
        is $res->code, 200;
        is $res->header('content-type'), 'application/json; charset=utf-8';
        is $res->content, q!{"value":19.5}!;
    }
}
