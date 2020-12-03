use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
foreach my $module (grep {
    $_ !~ /^Data::CompactReadonly::(V0::)?((Tied)?Array|(Negative)?Scalar|(Tied)?Dictionary|Text|Collection|Node)/
} all_modules()) {
    diag("Checking $module");
    pod_coverage_ok($module);
}
done_testing();
