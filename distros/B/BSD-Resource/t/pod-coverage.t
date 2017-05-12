BEGIN {
    eval "use Test::More";
    if ($@) { print "1..0 # SKIP Test::More required\n"; exit(0) }
}
BEGIN {
    eval "use Test::Pod::Coverage";
    plan(skip_all => "Test::Pod::Coverage required for testing POD coverage")
	if $@;
}
all_pod_coverage_ok({ also_private => [ qr/^constant$/ ] });



