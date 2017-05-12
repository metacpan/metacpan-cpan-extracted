use strict;
$^W = 1;

eval "use Test::Pod 1.00";
if($@) {
    print "1..0 # SKIP Test::Pod 1.00 required for testing POD";
} else {
    all_pod_files_ok();
}
