#!perl

use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

{
    no warnings 'once';
    $::use_path_class = 1;
}

use_ok('Catalyst::Test', 'TestApp');

ok(!ref TestApp::View::Mason::Pkgconfig->config->{comp_root}, 'comp_root got stringified');
ok(!ref TestApp::View::Mason::Pkgconfig->config->{data_dir}, 'data_dir got stringified');

my $response = request('/test?view=Pkgconfig');

ok($response->is_success, 'request ok');
