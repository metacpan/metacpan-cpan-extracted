use strict;
use warnings;
use utf8;

use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Set $ENV{AUTHOR_TESTING} to run author tests.';
    plan( skip_all => $msg );
}

if ( !eval { require Test::Pod; 1 } ) {
    plan skip_all => "Test::Pod required for testing POD";
}
Test::Pod::all_pod_files_ok();
