#!perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use Catalyst::Test 'TestApp';
use HTTP::Request;

my @tests = (
    ['/test_self',                  'TestApp::Controller::Vars',    '$self contains correct object'],
    ['/test_ctx',                   'TestApp',                      '$ctx contains correct object'],
    ['/test_args/1/2/3',            '1, 2, 3',                      '@args contains correct arguments'],
    ['/test_stash',                 '23',                           'modifying stash works'],
    ['/test_array',                 '23, 42',                       'modifying array works'],
    ['/test_hash',                  '23',                           'modifying hash works'],
    ['/a/b/test_args_phases/1/2',   'a, b; 1, 2; x, y, z',          '@args in various stages'],
    ['/test_passed_args/1/2/3',     '1, 2, 3',                      'passed @args to other action'],
);

plan tests => ( scalar(@tests) * 2 );

for (@tests) {
    my ($path, $content, $title) = @$_;
    ok( my $response = request( "http://localhost/vars$path" ), "$path request ok" );
    is( $response->content, $content, $title );
}
