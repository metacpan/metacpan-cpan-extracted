#!/usr/bin/perl

use strict;
use warnings;

use Test::More;


plan skip_all => 'set TEST_APACHE2_MOJO to run tests against http://localhost/mojo'
    unless $ENV{TEST_APACHE2_MOJO};

eval "use Mojo";
my $test_addr = 0;
if (not $@ and $Mojo::VERSION >= 0.9002) {
    $test_addr = 1;
    # this needs a patched Mojo::HelloWorld
    plan tests => 5;
} else {
    plan tests => 2;
}


require LWP::Simple;


my $base = 'http://localhost/mojo';

# simple request
my $html = LWP::Simple::get($base);
like($html, qr/Congratulations, your Mojo is working!/, 'simple get request');

# get request with params
$html = LWP::Simple::get("$base/diag/dump_params?id=123&id=456&abc=");
like($html, qr/'id' => \[\s+'123',\s+'456'\s+\]/s, 'get request with params');

if ($test_addr) {
    # test local and remote address
    $html = LWP::Simple::get("$base/diag/dump_tx");
    like($html, qr/'local_address' => '127\.0\.0\.1',/, 'local address');
    like($html, qr/'local_port' => 80,/, 'local port');
    like($html, qr/'remote_address' => '127\.0\.0\.1',/, 'remote address');
}
