#!perl -w

# $Id: pod.t 1168 2005-01-28 00:04:16Z david $

use strict;
use Test::More;
eval "use Test::Pod 1.20";
plan skip_all => "Test::Pod 1.20 required for testing POD" if $@;
all_pod_files_ok();
