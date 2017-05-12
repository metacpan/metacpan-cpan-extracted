use strict;
use warnings;
use Test::More tests => 1;
use Test::Pod::Coverage;

pod_coverage_ok(
    'B::Hooks::OP::Check::EntersubForCV',
    { also_private => [qw/dl_load_flags/] },
);
