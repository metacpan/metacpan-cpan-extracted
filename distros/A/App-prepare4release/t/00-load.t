#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);

ok( eval { require App::prepare4release; 1 }, 'require App::prepare4release' );
ok( App::prepare4release->can('run'), 'run' );

done_testing;
