# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/001_load.t - check module loading

use Apache::Test qw( :withtestmore );
use Test::More;

BEGIN {
    use_ok('Apache2::WebApp::Plugin::JSON');
}

my $obj = new Apache2::WebApp::Plugin::JSON;

isa_ok ( $obj, 'Apache2::WebApp::Plugin::JSON' );

done_testing();
