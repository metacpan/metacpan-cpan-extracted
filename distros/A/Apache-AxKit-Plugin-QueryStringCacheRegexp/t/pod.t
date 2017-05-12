# $Id: pod.t,v 1.1 2006/01/02 10:04:06 c10232 Exp $ -*- perl -*- 
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
