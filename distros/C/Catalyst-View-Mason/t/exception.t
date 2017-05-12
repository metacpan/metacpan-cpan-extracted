#!perl

use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

{
    my $response = request('/exception');
    ok(!$response->is_success, 'request fails');
}

SKIP: {
    eval 'use Test::MockModule';
    skip 'Test::MockModule required', 2 if $@;

    my $mock = Test::MockModule->new('HTML::Mason::Interp');
    $mock->mock(exec => sub { die bless \do { my $o }, 'FakeException' });

    my $response = request('/exception');
    ok($response->is_success, 'request succeeds');
    like($response->content, qr/^FakeException=/, 'request content contains stringified exception');
}
