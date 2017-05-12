use Test::More;
eval "use Test::Pod::Coverage 1.00 tests => 1";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

# Acme::Pythonic exports no subroutines, so none is documented with POD.
$trustme = { trustme => [ qr/./ ] };
pod_coverage_ok('Acme::Pythonic', $trustme);