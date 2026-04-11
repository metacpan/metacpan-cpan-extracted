use strict;
use warnings;
use Test::More;

plan skip_all => 'Test::Pod::Coverage required'
    unless eval { require Test::Pod::Coverage; 1 };

# Server — all public methods should be documented
Test::Pod::Coverage::pod_coverage_ok('Data::ReqRep::Shared', {
    trustme => [qr/^(DESTROY|AUTOLOAD|import|BEGIN)$/],
});

# Client — XS-only, documented in Server POD
Test::Pod::Coverage::pod_coverage_ok('Data::ReqRep::Shared::Client', {
    trustme => [qr/./],  # all methods documented in parent POD
});

done_testing;
