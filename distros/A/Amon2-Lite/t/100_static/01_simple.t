use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use Test::Requires qw/HTTP::Request::Common/, 'Data::Section::Simple';

my $app = do {
    use Amon2::Lite;

    get '/' => sub { shift->create_response(200, ['Content-Length' => 2], ['OK']) };

    __PACKAGE__->to_app(
        handle_static => 1,
    );
};

test_psgi($app, sub {
    my $cb = shift;

    {
        my $res = $cb->(GET '/');
        is $res->code, 200;
        is $res->content, 'OK';
        is $res->content_length, 2;
    }

    subtest '/static/foo' => sub {
        my $res = $cb->(GET '/static/foo');
        is $res->code, 200;
        is $res->content, "bar\n";
        is $res->content_length, 4;
    };

    {
        my $res = $cb->(GET '/robots.txt');
        is $res->code, 200;
        is $res->content, "DENY *\n";
        is $res->content_length, 7;
    }
    {
        my $res = $cb->(GET '/static/foo.js');
        like $res->content, qr/function/;
        is $res->content_length, 20;
        is $res->content_type, 'application/javascript';
    }
});

done_testing;
__DATA__

@@ /static/foo.js
$(function () { });
