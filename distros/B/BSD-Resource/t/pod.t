BEGIN {
    eval "use Test::More";
    if ($@) { print "1..0 # SKIP Test::More required"; exit(0) } 
}
BEGIN {
    eval "use Test::Pod";
    plan(skip_all => "Test::Pod required for testing POD") if $@;
}
all_pod_files_ok();
