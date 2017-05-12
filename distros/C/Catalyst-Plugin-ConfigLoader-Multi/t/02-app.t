use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More qw(no_plan);

$ENV{TESTAPP_CONFIG_MULTI} = "$FindBin::Bin/lib/local.yml";
use Catalyst::Test 'TestApp' ;
TestApp->setup;

is( get( '/env_test' ) , 'OK' , 'reading ENV seting ok') ;
