use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

my $trustme = { trustme => [qr/^new$/] };
all_pod_coverage_ok( $trustme );
