#!perl -T

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

pod_file_ok( 'lib/App/Unix/RPasswd.pm', "Valid POD file" );
pod_file_ok( 'script/rpasswd', "Valid POD file" );
done_testing(2);