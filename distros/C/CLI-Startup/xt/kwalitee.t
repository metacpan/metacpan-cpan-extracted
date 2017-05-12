use strict;
use warnings;

BEGIN: { $ENV{AUTHOR_TESTING} = 1 }

use Test::More;

eval { require Test::Kwalitee; };
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

# Test::Kwalitee has a bug: the following two tests fail even for the
# distribution of Test::Kwality itself!
Test::Kwalitee->import( tests => [ qw/ -has_test_pod -has_test_pod_coverage /] );
