#!perl
# $Id: 98-pod.t,v 1.1 2008/05/02 14:30:33 pauldoom Exp $

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
