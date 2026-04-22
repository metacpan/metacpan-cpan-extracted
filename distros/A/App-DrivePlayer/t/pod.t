use strict;
use warnings;

use FindBin;
use Test::More;

plan skip_all => 'Author test.  Set AUTHOR_TESTING=1 to run.'
    unless $ENV{AUTHOR_TESTING};

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok( "$FindBin::RealBin/../lib" );
