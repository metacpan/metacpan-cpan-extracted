#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings;
    use warnings FATAL => 'all';
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} )
    {
        plan( skip_all => "Author tests not required for installation" );
    }
};

use strict;
use warnings;

my $min_tcm = 0.9;

eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if( $@ );

ok_manifest();

done_testing;
