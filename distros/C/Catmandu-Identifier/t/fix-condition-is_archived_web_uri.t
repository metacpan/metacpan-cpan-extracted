#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;
use Test::LWP::UserAgent;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_archived_web_uri';
    use_ok $pkg;
}

user_agent();

my $cond = $pkg->new('uri','2013');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({uri => "http://lib.ugent.be"}),
    {uri => "http://lib.ugent.be", test => 'pass'},
    "is valid";

is_deeply
    $cond->fix({uri => "ftp://foo.bar/file.txt"}),
    {uri => "ftp://foo.bar/file.txt" , test => 'fail' },
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

    my $example =<<EOF;
{
    "original_uri":"http://lib.ugent.be",
    "mementos":{
        "last":{
            "datetime":"2015-06-02T07:47:06Z",
            "uri":[
               "http://wayback.archive-it.org/all/20150602074706/http://lib.ugent.be/"
            ]
        },
        "next":{
            "datetime":"2013-01-06T10:51:03Z",
            "uri":[
                "http://web.archive.org/web/20130106105103/http://lib.ugent.be/",
                "http://wayback.archive-it.org/all/20130106105103/http://lib.ugent.be/"
            ]
        },
        "closest":{
            "datetime":"2013-01-01T12:16:43Z",
            "uri":[
                "http://web.archive.org/web/20130101121643/http://lib.ugent.be/",
                "http://wayback.archive-it.org/all/20130101121643/http://lib.ugent.be/"
            ]
        },
        "first":{
            "datetime":"2003-04-08T13:31:25Z",
            "uri":[
                "http://web.archive.org/web/20030408133125/http://www.lib.ugent.be/"
            ]
        },
        "prev":{
            "datetime":"2012-12-31T07:28:20Z",
            "uri":[
                "http://archive.is/20121231072820/http://lib.ugent.be/"
            ]
        }
    },
    "timegate_uri":"http://timetravel.mementoweb.org/timegate/http://lib.ugent.be",
    "timemap_uri":{
        "json_format":"http://timetravel.mementoweb.org/timemap/json/http://lib.ugent.be",
        "link_format":"http://timetravel.mementoweb.org/timemap/link/http://lib.ugent.be"
    }
}
EOF

    add_response(
        $ua,
        '200',
        'OK',
        'http://timetravel.mementoweb.org/api/json/2013/http://lib.ugent.be',
        'application/json',
        $example
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