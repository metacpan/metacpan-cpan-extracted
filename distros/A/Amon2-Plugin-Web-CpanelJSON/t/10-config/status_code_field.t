use strict;
use warnings;
use Test::More;
use Cpanel::JSON::XS qw(decode_json);
use Cpanel::JSON::XS::Type;

{
    package MyApp::Web::Default;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON',
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::StatusCodeField;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            status_code_field => 'status_code',
        }
    );
    sub encoding { 'utf-8' }
}

subtest 'no status_code' => sub {
    my $src = {hello => 'world'};

    subtest 'Default' => sub {
        my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
        my $res = $c->render_json($src);
        is $res->code, 200;
        is $res->header('X-API-Status'), undef;
        is $res->content, '{"hello":"world"}';
    };

    subtest 'StatusCodeField' => sub {
        my $c = MyApp::Web::StatusCodeField->new(request => Amon2::Web::Request->new({}));
        my $res = $c->render_json($src);
        is $res->code, 200;
        is $res->header('X-API-Status'), undef;
        is $res->content, '{"hello":"world"}';
    };
};

subtest 'has status_code' => sub {
    my $src = {status_code => 201};

    subtest 'Default' => sub {
        my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
        my $res = $c->render_json($src);
        is $res->code, 200;
        is $res->header('X-API-Status'), undef;
        is $res->content, '{"status_code":201}';
    };

    subtest 'StatusCodeField' => sub {
        my $c = MyApp::Web::StatusCodeField->new(request => Amon2::Web::Request->new({}));
        my $res = $c->render_json($src);
        is $res->code, 200;
        is $res->header('X-API-Status'), 201, 'SET X-API-Status';
        is $res->content, '{"status_code":201}';
    };
};

done_testing;
