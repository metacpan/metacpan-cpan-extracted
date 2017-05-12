#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;
use Test::LWP::UserAgent;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_live_web_uri';
    use_ok $pkg;
}

my $cond = $pkg->new('uri');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({uri => "http://librecat.org"}),
    {uri =>  "http://librecat.org", test => 'pass'},
    "is valid";

is_deeply
    $cond->fix({uri => "ftp://foo.bar/file.txt"}),
    {uri => "ftp://foo.bar/file.txt" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({uri => "http://librecat.dadada"}),
    {uri =>  "http://librecat.dadada", test => 'fail'},
    "is invalid";

is_deeply
    $cond->fix({uri => "This is an http address: http://foo.bar/file.txt"}),
    {uri => "This is an http address: http://foo.bar/file.txt" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({uri => ""}),
    {uri => "" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({}),
    {test => 'fail' },
    "is invalid";

done_testing;


sub user_agent {
    my $ua = Test::LWP::UserAgent->new;

    add_response(
        $ua,
        '200',
        'OK',
        'http://librecat.org',
        'text/plain',
        'ok'
    );

    $LWP::Simple::ua = $ua;
}

sub add_response {
    my $ua           = shift;
    my $code         = shift;
    my $msg          = shift;
    my $url          = shift;
    my $content_type = shift;
    my $content      = shift;

    $ua->map_response(
        qr{^\Q$url\E$},
        HTTP::Response->new(
            $code,
            $msg,
            ['Content-Type' => $content_type ],
            Encode::encode_utf8($content)
        )
    );
}
