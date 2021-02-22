use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
pod_coverage_ok($_) foreach(grep { $_ !~ /^Class::Mock::Common$/ } all_modules());
done_testing();
