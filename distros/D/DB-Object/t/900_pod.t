#!perl
##----------------------------------------------------------------------------
## SQL API Abstraction - t/900_pod.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;

eval{ require Test::Pod; Test::Pod->import };
if( $@ )
{
    plan( skip_all => 'Test::Pod not available' );
}
else
{
    all_pod_files_ok();
}
