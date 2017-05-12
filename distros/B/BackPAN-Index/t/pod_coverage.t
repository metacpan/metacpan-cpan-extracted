#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Author test" unless $ENV{AUTHOR_TESTING};
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok(
    # BackPAN::Index::File/Release::prefix() is for backwards compat with PBP
    { trustme => [qr/^prefix$/, qr/^data_methods$/] }
);
