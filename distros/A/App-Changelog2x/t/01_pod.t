#!/usr/bin/perl
# $Id: 01_pod.t 17 2009-01-24 10:38:38Z rjray $

use Test::More;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();

exit;
