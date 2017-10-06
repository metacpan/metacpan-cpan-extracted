eval "use Test::Pod::Coverage";
if ($@) {
    use Test;
    plan(tests => 1);
    skip("Test::Pod::Coverage required for testing");
}
else {
    use Test;
    all_pod_coverage_ok();
}
