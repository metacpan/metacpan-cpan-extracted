use strict;
use warnings;

use Test::More tests => 1;

subtest 'pod_coverage' => sub {
    eval "use Test::Pod::Coverage";
    plan skip_all => "Test::Pod::Coverage required for testing coverage" if $@;

    all_pod_coverage_ok(
        { also_private => [ qr/^BUILD/ ], },
    );
};

done_testing();

exit;

__END__
