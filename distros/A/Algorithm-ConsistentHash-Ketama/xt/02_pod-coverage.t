use Test::More;
use Test::Requires 'Test::Pod::Coverage';

all_pod_coverage_ok({ also_private => [ qr/^xs_/ ] });
