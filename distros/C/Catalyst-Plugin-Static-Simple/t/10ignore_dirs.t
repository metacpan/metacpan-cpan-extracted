#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

# test ignoring directories
TestApp->config->{'Plugin::Static::Simple'}->{ignore_dirs} = [ qw/ignored o-ignored files/ ];

# test altenate root dirs
TestApp->config->{'Plugin::Static::Simple'}->{include_path} = [
    TestApp->config->{root} . '/overlay',
    TestApp->config->{root},
];

ok( my $res = request('http://localhost/ignored/bad.gif'), 'request ok' );
is( $res->content, 'default', 'ignored directory `ignored` ok' );

ok( $res = request('http://localhost/files/static.css'), 'request ok' );
is( $res->content, 'default', 'ignored directory `files` ok' );

ok( $res = request('http://localhost/o-ignored/bad.gif'), 'request ok' );
is( $res->content, 'default', 'ignored overlay directory ok' );
