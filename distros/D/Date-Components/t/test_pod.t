# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Date-Components.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
eval {use Test::Pod 1.26};
plan skip_all => "Test::Pod 1.26 required for testing POD" if $@;
all_pod_files_ok( 'lib/Date/Components.pm' );
