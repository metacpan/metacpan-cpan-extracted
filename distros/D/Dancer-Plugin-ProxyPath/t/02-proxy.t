#/usr/bin/perl

use strict;
use warnings;
use Scalar::Util qw/refaddr/;
use Test::MockObject;

use Test::More tests => 11;

BEGIN {
    my %headers = (
        "request-base" => '/foo',
        "x-forwarded-host" => 'client_side'
    );
    my $mock_request = Test::MockObject->new;
    $mock_request->mock(path => sub {'/quux'})
                ->mock(header => sub {
                    shift;
                    my $header = shift;
                    return $headers{$header};
                })
                ->mock(env => sub { {'psgi.url_scheme' => 'http'} })
                ->mock(uri_for => sub {'server_side/foo'});

    my $mock_dancer = Test::MockObject->new;
    $mock_dancer->fake_module("Dancer",
        request => sub {$mock_request}
    );
}
    
use Dancer::Plugin::ProxyPath::Proxy;

isa_ok(Dancer::Plugin::ProxyPath::Proxy->instance, 
    "Dancer::Plugin::ProxyPath::Proxy", "Instance");

is(
    refaddr(Dancer::Plugin::ProxyPath::Proxy->instance),
    refaddr(Dancer::Plugin::ProxyPath::Proxy->instance),
    "Always returns the same instance"
);

my $proxy = Dancer::Plugin::ProxyPath::Proxy->instance;

can_ok($proxy, qw/uri_for/);

is($proxy->uri_for("/bar"), "http://client_side/foo/bar", "Constructs abs destination");

is($proxy->uri_for("/bar", {zap => 'zop'}), "http://client_side/foo/bar?zap=zop", "Handles query parameters");

is($proxy->uri_for("bar"), "http://client_side/foo/quux/bar", "Constructs rel destination");

is($proxy->uri_for(Dancer::request->path), "http://client_side/foo/quux", "Constructs own path explicitly");

is($proxy->uri_for(), "http://client_side/foo/quux", "Constructs own path implicitly");

is($proxy->secure_uri_for("/bar"), "https://client_side/foo/bar", "Constructs secure abs destination");

is($proxy->secure_uri_for("bar"), "https://client_side/foo/quux/bar", "Constructs secure rel destination");

is($proxy->secure_uri_for(), "https://client_side/foo/quux", "Constructs own path implicitly, and securely");



