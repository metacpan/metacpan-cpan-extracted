use Test::More tests => 12;
use strict;
use B::Utils;

ok( B::Utils->can('import'), "Can import()" );

is( scalar(@B::Utils::EXPORTS), 0, "Nothing is exported without asking" );

is( scalar( @{ $B::Utils::EXPORT_TAGS{all} } ),
    scalar(@B::Utils::EXPORT_OK),
    "All optional exports are exported via :all"
);

# Test for function exports
for my $function (
    qw( all_starts all_roots anon_subs recalc_sub_cache
    walkoptree_simple walkoptree_filtered
    walkallops_simple walkallops_filtered )
    )
{
    ok( eval { B::Utils->import($function); 1 },
        "B::Utils exports $function" );
}

cmp_ok( B::Utils->VERSION, '>=', 0.01, "B::Utils->VERSION is specified" );
