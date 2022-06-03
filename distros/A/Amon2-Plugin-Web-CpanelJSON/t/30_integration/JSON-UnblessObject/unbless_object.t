use strict;
use warnings;
use Test::More;
use Test::Requires 'JSON::UnblessObject';

use Cpanel::JSON::XS qw(decode_json);
use Cpanel::JSON::XS::Type;

use JSON::UnblessObject;

{
    package MyApp::Web;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            json => {
                canonical => 1,
            },
            unbless_object => \&JSON::UnblessObject::unbless_object,
        }
    );
    sub encoding { 'utf-8' }
}

{
    package Foo;
    sub new { bless {}, $_[0] }
    sub hello { 'HELLO!' }
    sub world { 'WORLD!' }
}


my $src = Foo->new;

my $c = MyApp::Web->new(request => Amon2::Web::Request->new({}));

subtest 'empty spec' => sub {
    my $spec = { };
    my $res = $c->render_json($src, $spec);
    is $res->content, '{}';
};

subtest '{ hello => JSON_TYPE_STRING }' => sub {
    my $spec = { hello => JSON_TYPE_STRING };
    my $res = $c->render_json($src, $spec);
    is $res->content, '{"hello":"HELLO!"}';
};

subtest '{ world => JSON_TYPE_STRING }' => sub {
    my $spec = { world => JSON_TYPE_STRING };
    my $res = $c->render_json($src, $spec);
    is $res->content, '{"world":"WORLD!"}';
};

subtest '{ world => JSON_TYPE_BOOL }' => sub {
    my $spec = { world => JSON_TYPE_BOOL };
    my $res = $c->render_json($src, $spec);
    is $res->content, '{"world":true}';
};

subtest '{ hello => JSON_TYPE_STRING, world => JSON_TYPE_STRING }' => sub {
    my $spec = { hello => JSON_TYPE_STRING, world => JSON_TYPE_STRING };
    my $res = $c->render_json($src, $spec);
    is $res->content, '{"hello":"HELLO!","world":"WORLD!"}';
};

done_testing;
