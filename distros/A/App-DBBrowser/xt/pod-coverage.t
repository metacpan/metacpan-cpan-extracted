use 5.016;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage;
use Pod::Coverage;

plan skip_all => "skipp all"; ##########

pod_coverage_ok( "App::DBBrowser" );



done_testing();
