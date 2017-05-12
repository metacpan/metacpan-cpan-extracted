use Test::More tests => 12;
use strict;
use B::Utils1;

ok( B::Utils1->can('import'), "Can import()" );

is( scalar(@B::Utils1::EXPORTS), 0, "Nothing is exported without asking" );

is( scalar( @{ $B::Utils1::EXPORT_TAGS{all} } ),
    scalar(@B::Utils1::EXPORT_OK),
    "All optional exports are exported via :all"
);

# Test for function exports
for my $function (
    qw( all_starts all_roots anon_subs recalc_sub_cache
    walkoptree_simple walkoptree_filtered
    walkallops_simple walkallops_filtered )
    )
{
    ok( eval { B::Utils1->import($function); 1 },
        "B::Utils1 exports $function" );
}

cmp_ok( B::Utils1->VERSION, '>=', 0.01, "B::Utils->VERSION is specified" );
