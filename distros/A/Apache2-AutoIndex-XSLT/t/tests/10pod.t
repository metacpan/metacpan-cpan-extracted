# $Id: 10pod.t 816 2006-11-26 19:09:52Z nicolaw $

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

1;

