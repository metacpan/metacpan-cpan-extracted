#!/usr/bin/perl
# live.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use FindBin qw($Bin);
use lib "$Bin/lib";
use Catalyst::Test qw(TestApp);
use Test::More tests => 6;

my $test = request('this is handled by default I hope');
ok($test->content, 'content');
like($test->content, qr/Test:\s+\(.+\)/, 'got expected result');
$test = request('/foo');
ok($test->content, 'foo content');
is($test->content, 'foo', 'got expected result');
$test = request('/bar');
ok($test->content, 'bar content');
is($test->content, 'this is bar', 'got expected result');
