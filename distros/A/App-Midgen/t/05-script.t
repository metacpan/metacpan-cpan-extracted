#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More;
use Test::Requires { 'Test::Script' => 1.07 };

script_compiles( 'script/midgen', 'midgen script compiles' );

# comment out - takes to long to run :(
# script_runs( 'script/midgen', 'midgen script runs' );

done_testing();

__END__

