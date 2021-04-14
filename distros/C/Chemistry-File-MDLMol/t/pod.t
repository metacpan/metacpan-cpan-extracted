use Test::More;

eval 'use Test::Pod';
if ($@) {
    plan skip_all => "You don't have Test::Pod installed";
} else {
    all_pod_files_ok();
}
