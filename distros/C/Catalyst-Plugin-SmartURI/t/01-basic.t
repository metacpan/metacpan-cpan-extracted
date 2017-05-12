#!perl

use strict;
use warnings;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Catalyst::Test 'TestApp';
use HTTP::Request;

is(request('/test_uri_for_redirect')->header('location'),
    '/test_uri_for_redirect', 'redirect location');

is(get('/per_request'), 'dummy', 'per-request disposition');

is(get('/test_req_uri_with'),
    '/test_req_uri_with?the_word_that_must_be_heard=mtfnpy',
    '$c->req->uri_with test, and disposition reset');

is(get('/test_uri_object'), '/test_uri_object',
    'URI objects are functional');

my $req = HTTP::Request->new(GET => '/host_header');
$req->header(Host => 'www.dongs.com');
is(request($req)->content, 'http://www.dongs.com/dummy',
    'host-header disposition');

$req = HTTP::Request->new(GET => '/host_header_with_port');
$req->header(Host => 'www.hlagh.com:8080');
is(request($req)->content, 'http://www.hlagh.com:8080/dummy',
    'host-header disposition with port');

my %try_referers = (
    foo     => 'foo',
    blank   => '',
    'undef' => undef
);

while (my ($referer_val_name, $referer_val) = each %try_referers) {
    $req = HTTP::Request->new(GET => '/say_referer');
    $req->header(Referer => $referer_val);

    my $content = request($req)->content;

    is($content, $referer_val_name,
        "Referer: $referer_val_name gives \$c->req->referer of '$content'");
}

is(get('/req_uri_class'), 'MyURI::http http://localhost/req_uri_class',
    'overridden $c->req->uri');

$req = HTTP::Request->new(GET => '/req_referer_class');
$req->header(Referer => 'dummy');
like(get($req), qr/^MyURI::/,
    'overridden $c->req->referer');

done_testing;

# vim: expandtab shiftwidth=4:
