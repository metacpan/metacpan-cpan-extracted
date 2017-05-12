#!perl -T

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

# Skip if doing a regular install
unless ( $ENV{AUTOMATED_TESTING} ) {
        plan( skip_all => "Author tests not required for installation" );
}

all_pod_files_ok();
