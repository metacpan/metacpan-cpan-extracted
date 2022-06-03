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
    package MyApp::Web::UnblessObject;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            unbless_object => sub {
                my ($object, $spec) = @_;
                {
                    hello => $object->hello,
                }
            },
        }
    );
    sub encoding { 'utf-8' }
}

{
    package Foo;
    sub new { bless {}, $_[0] }
    sub hello { 'HELLO!' }
}

subtest 'unblessed hashref' => sub {
    my $src = {hello => 'world'};
    my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src);
    is $res->code, 200;
    is $res->content, '{"hello":"world"}';
    is_deeply decode_json($res->content), $src;
};

subtest 'blessed object and no spec' => sub {
    my $src = Foo->new;

    my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
    eval { $c->render_json($src) };
    like $@, qr/encountered object/;
};

subtest 'blessed object and spec' => sub {
    my $src = Foo->new;
    my $spec = { hello => JSON_TYPE_STRING };

    my $c = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
    eval { $c->render_json($src, $spec) };
    like $@, qr/encountered object/;
};

subtest 'with unbless_object' => sub {
    my $src = Foo->new;
    my $spec = { hello => JSON_TYPE_STRING };

    my $c = MyApp::Web::UnblessObject->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src, $spec);
    is $res->code, 200;
    is $res->content, '{"hello":"HELLO!"}';
    is_deeply decode_json($res->content), { hello => 'HELLO!' };
};

subtest 'unblessed hashref and spec' => sub {
    my $src = {hello => 'world'};
    my $spec = { hello => JSON_TYPE_STRING };

    my $c = MyApp::Web::UnblessObject->new(request => Amon2::Web::Request->new({}));
    my $res = $c->render_json($src, $spec);
    is $res->code, 200;
    is $res->content, '{"hello":"world"}';
    is_deeply decode_json($res->content), $src;
};


done_testing;
