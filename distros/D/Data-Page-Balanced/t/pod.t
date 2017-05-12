#!perl -T
# $Id: pod.t 2 2007-10-27 22:08:58Z kim $

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
