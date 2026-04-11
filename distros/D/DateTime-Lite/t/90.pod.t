#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/90.pod.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use Test::More;

eval { require Test::Pod; Test::Pod->import };
if( $@ )
{
    plan( skip_all => 'Test::Pod not available' );
}
else
{
    all_pod_files_ok();
}
