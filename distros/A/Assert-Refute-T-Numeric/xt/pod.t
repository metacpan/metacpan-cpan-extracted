#!perl -T

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

my $dir = dirname(__FILE__);
my $root = $dir eq '.' ? '..' : dirname($dir);

foreach (all_pod_files("$root/lib")) {
    pod_file_ok($_);
};

done_testing;
