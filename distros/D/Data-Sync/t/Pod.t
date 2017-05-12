use strict;
use warnings;
use Test::More;

my @poddirs = qw (blib);

eval "use Test::Pod";
plan skip_all=>"Test::Pod required for testing POD" if $@;
all_pod_files_ok(all_pod_files(@poddirs));
