# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

SKIP: {
    eval { require RRDs };
    skip "RRDs not installed", 2 if $@;

    use_ok( 'Catalyst::View::RRDGraph' ); 
    use_ok( 'Catalyst::Helper::View::RRDGraph');
}
