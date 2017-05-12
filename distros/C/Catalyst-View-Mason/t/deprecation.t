#!perl

use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp::FakeLog;

my @warnings;

my $mock_log = TestApp::FakeLog->new(\@warnings);

{
    no warnings 'once';
    $::fake_log = $mock_log;
    $::setup_match = 1;
}

use_ok('Catalyst::Test', 'TestApp');

ok(scalar @warnings, 'loading component which sets use_match to something true causes a warning');
like($warnings[0], qr/^DEPRECATION WARNING/, 'the warning is a deprecation warning');
like($warnings[0], qr/TestApp::View::Mason::Match/, 'the warning contains the name of the component causing it');
