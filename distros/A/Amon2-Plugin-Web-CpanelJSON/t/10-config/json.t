use strict;
use warnings;
use utf8;
use Test::More;

use Cpanel::JSON::XS qw(decode_json);
use Cpanel::JSON::XS::Type;
use Encode qw(encode_utf8 decode_utf8);

{
    package MyApp::Web::Default;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON',
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::Canonical;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            json => {
                canonical => 1,
            },
        }
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::UTF8;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            json => {
                ascii => 0,
                utf8 => 1,
            },
        }
    );
    sub encoding { 'utf-8' }
}

{
    package MyApp::Web::None;
    use parent qw(Amon2 Amon2::Web);
    __PACKAGE__->load_plugins(
        'Web::CpanelJSON', {
            json => undef,
        }
    );
    sub encoding { 'utf-8' }
}


my $c_default = MyApp::Web::Default->new(request => Amon2::Web::Request->new({}));
my $c_canonical = MyApp::Web::Canonical->new(request => Amon2::Web::Request->new({}));
my $c_utf8 = MyApp::Web::UTF8->new(request => Amon2::Web::Request->new({}));
my $c_none = MyApp::Web::None->new(request => Amon2::Web::Request->new({}));

subtest 'ascii' => sub {
    my $src = { message => 'あ'};

    subtest 'ascii default is on' => sub {
        my $res = $c_default->render_json($src);
        is $res->content, '{"message":"\u3042"}';
        is_deeply decode_json($res->content), $src;
    };

    subtest 'If ascii is not set, it remains on' => sub {
        my $res = $c_canonical->render_json($src);
        is $res->content, '{"message":"\u3042"}';
        is_deeply decode_json($res->content), $src;
    };
};

subtest 'canonical' => sub {
    my $src = {a => 1, b => 2, c => 3, d => 4, e => 5, f => 6, g => 7, h => 8, i => 9};

    subtest 'canonical default is off' => sub {
        my $res = $c_default->render_json($src);
        note 'key sequence is random';
        note $res->content;
        is_deeply decode_json($res->content), $src;
    };

    subtest 'sort keys' => sub {
        my $res = $c_canonical->render_json($src);
        is $res->content, '{"a":1,"b":2,"c":3,"d":4,"e":5,"f":6,"g":7,"h":8,"i":9}';
        is_deeply decode_json($res->content), $src;
    };
};

subtest 'utf8' => sub {
    my $src = { message => 'あ'};

    subtest 'encode utf8' => sub {
        my $res = $c_utf8->render_json($src);
        is $res->content, encode_utf8('{"message":"あ"}');
        is_deeply decode_json($res->content), $src;
    };
};

subtest 'none' => sub {
    my $src = { message => 'あ'};

    subtest 'ascii is off' => sub {
        my $res = $c_none->render_json($src);
        is $res->content, '{"message":"あ"}';
        is utf8::is_utf8($res->content), !!1;
        my $json = Cpanel::JSON::XS->new->utf8(0);
        is_deeply $json->decode($res->content), $src;
    };
};

done_testing;
