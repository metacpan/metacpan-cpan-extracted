#	$Id: 90-pod.t 51 2014-05-21 19:14:11Z adam $

use strict;

my $run_tests;

BEGIN {
    $run_tests = eval { require Test::Pod; };
};

use Test::More;

if (! $run_tests ) {
    plan skip_all => 'Test::Pod not installed, skipping test.';
}
else {
    plan tests => 1;
}

Test::Pod::pod_file_ok("./lib/Config/Trivial.pm", "Valid POD file" );

