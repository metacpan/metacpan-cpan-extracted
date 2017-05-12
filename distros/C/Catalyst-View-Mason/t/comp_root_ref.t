#!perl

use strict;
use warnings;
use Scalar::Util qw/blessed/;
use Test::More;

eval 'use Test::Exception';
plan skip_all => 'Test::Exception required' if $@;

plan tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp::FakeCtx;
use TestApp::View::Mason::CompRootRef;

my @comp_roots = (
        { a => 1, },
        \do { my $o = 1 },
        sub { },
        \*STDIN,
);

my $c = TestApp::FakeCtx->new;

for my $comp_root (@comp_roots) {
    my $str = $comp_root . q//;

    throws_ok(sub {
            TestApp::View::Mason::CompRootRef->new($c, {comp_root => $comp_root});
    }, qr/comp_root path '\Q$str\E'/, 'exception when passing '. ref($comp_root) .' reference as comp_root');
}

lives_ok(sub {
        TestApp::View::Mason::CompRootRef->new($c, {
                comp_root => [ [MAIN => $FindBin::Bin] ],
        });
}, "array root as comp_root doesn't get stringified");
