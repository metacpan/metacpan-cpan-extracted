use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage"
    if $@;

plan tests => 4;
pod_coverage_ok("Catalyst::Plugin::Authentication::Store::HTTP");
pod_coverage_ok("Catalyst::Plugin::Authentication::Store::HTTP::Backend");
pod_coverage_ok("Catalyst::Plugin::Authentication::Store::HTTP::User");
pod_coverage_ok("Catalyst::Plugin::Authentication::Store::HTTP::UserAgent");
