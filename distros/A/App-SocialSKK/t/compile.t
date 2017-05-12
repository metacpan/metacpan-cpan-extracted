use strict;
use Test::More qw(no_plan);
use FindBin;
use Module::Collect;

BEGIN {
    my $collect = Module::Collect->new(
        path => $FindBin::Bin . '/../lib',
        pattern => '*.pm',
    );
    for my $module (@{$collect->modules}) {
        use_ok $module->package;
    }
}
