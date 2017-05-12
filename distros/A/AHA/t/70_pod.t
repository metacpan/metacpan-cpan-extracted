use Test::More;

unless(eval "use Test::Pod; 1") {
    plan skip_all => "Test::Pod required for testing POD";
}

all_pod_files_ok(qw(blib example));
