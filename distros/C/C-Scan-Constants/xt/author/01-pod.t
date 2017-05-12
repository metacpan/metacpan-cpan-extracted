# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 05-pod.t'

#########################


use Test::More;
eval "use Test::Pod 1.00";
if ($@) {
    plan skip_all => "Test::Pod 1.00 required for testing POD";
}
else {
    plan tests => 1;
}
my $dir_to_test = "lib/C/Scan";
if (! -d $dir_to_test) {
    $dir_to_test = "../$dir_to_test";
} 
pod_file_ok("$dir_to_test/Constants.pm", "No POD issues");  # 1
