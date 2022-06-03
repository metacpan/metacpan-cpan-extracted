use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Cpanel::JSON::XS::Type;

{
    package MyApp::Web;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins('Web::CpanelJSON');
    sub encoding { 'utf-8' }
}

my $app = MyApp::Web->to_app;

test_psgi $app, sub {
    my $cb  = shift;

    no warnings qw(once);

    subtest 'no arguments' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json()
        };

        my $res = $cb->(GET "/");
        is $res->code, 500;
    };

    subtest 'empty data' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({})
        };

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, '{}';
    };

    subtest 'simple data' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'})
        };

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, '{"foo":"123"}';
    };

    subtest 'with JSON_TYPE_INT' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'}, {foo => JSON_TYPE_INT})
        };

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, '{"foo":123}';
    };

    subtest 'with JSON_TYPE_BOOL' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'}, {foo => JSON_TYPE_BOOL})
        };

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, '{"foo":true}';
    };

    subtest 'with JSON_TYPE_STRING' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'}, {foo => JSON_TYPE_STRING})
        };

        my $res = $cb->(GET "/");
        is $res->code, 200;
        is $res->content, '{"foo":"123"}';
    };

    subtest 'invalid JSON spec' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'}, {})
        };

        my $res = $cb->(GET "/");
        is $res->code, 500;
        like $res->content, qr/no type was specified for hash key 'foo'/;
    };

    subtest 'with status code' => sub {
        local *MyApp::Web::dispatch = sub {
            my $c = shift;
            $c->render_json({foo => '123'}, {foo => JSON_TYPE_INT}, 201)
        };

        my $res = $cb->(GET "/");
        is $res->code, 201;
        is $res->content, '{"foo":123}';
    };
};

done_testing;
