#!perl -T

use strict;
use warnings;
use Test::More;

# Are we an author test?
plan skip_all => 'Skipping author tests'
 unless $ENV{RUN_AUTHOR_TESTS};

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
