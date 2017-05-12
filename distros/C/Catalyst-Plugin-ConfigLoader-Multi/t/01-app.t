use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More qw(no_plan);

use Catalyst::Test 'TestApp' ;
TestApp->setup;

is( get( '/test' ) , 'ok' , 'reading seting ok') ;
