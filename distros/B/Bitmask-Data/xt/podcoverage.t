use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};
plan tests => 1;

pod_coverage_ok( "Bitmask::Data",{  trustme => [qr/^(hasany|hasexact|hasall|mask|sqlfilter)$/] }  );
#all_pod_coverage_ok();

