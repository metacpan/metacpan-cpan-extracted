# t/pod.t $Id: pod.t,v 1.1 2004/03/27 13:38:46 cwg Exp $

use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();
