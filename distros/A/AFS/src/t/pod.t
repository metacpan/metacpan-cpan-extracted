use strict;

use lib qw(../../inc ../inc ./inc);

use Test::More;

plan skip_all => "This test is only run for the module author"
  unless -d '.svn' || $ENV{IS_MAINTAINER};

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @poddirs = qw(../blib);
all_pod_files_ok(Test::Pod::all_pod_files(@poddirs));

