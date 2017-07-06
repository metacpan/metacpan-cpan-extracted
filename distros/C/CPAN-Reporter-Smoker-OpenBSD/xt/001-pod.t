use strict;
use Test::More;

eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;

my @poddirs = qw( blib );
all_pod_files_ok( all_pod_files( @poddirs ) );
