use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Response;
use File::Basename;

use App::BlurFill::Web;
my $app = App::BlurFill::Web->to_app;

my $image = "t/test.jpg";
plan skip_all => "Test image $image not found" unless -e $image;

open my $fh, '<', $image or die "Can't read image: $!";
binmode $fh;
my $content = do { local $/; <$fh> };

my $req = POST '/blur',
    Content_Type => 'form-data',
    Content => [
        image => [ undef, basename($image), Content => $content, 'Content-Type' => 'image/jpeg' ],
        width => 800,
        height => 450,
    ];

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->($req);
        is($res->code, 200, 'Got 200 OK from /blur');
        like($res->header('Content-Disposition'), qr/filename=".*?_blur\.jpg"/, 'Content-Disposition header looks good');
        like($res->content, qr/.{100,}/s, 'Response has image content');
    };

done_testing;

