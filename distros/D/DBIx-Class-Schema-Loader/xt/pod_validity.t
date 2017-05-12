use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => 'test_pod';

use warnings;
use strict;

use Test::More;
use lib qw(t/lib);

# this has already been required but leave it here for CPANTS static analysis
require Test::Pod;

Test::Pod::all_pod_files_ok( 'lib', 'script' );
