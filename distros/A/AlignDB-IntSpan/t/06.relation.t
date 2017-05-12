use strict;
use warnings;

use Test::More;

use AlignDB::IntSpan;

# inf
{
    my $inf_set = AlignDB::IntSpan->new->complement;

    ok( !$inf_set->is_finite,  "is_finite" );
    ok( $inf_set->is_infinite, "is_infinite" );
    ok( $inf_set->is_neg_inf,  "is_neg_inf" );
    ok( $inf_set->is_pos_inf,  "is_pos_inf" );
}

my $sets = [ split( ' ', q{ - 1 5 1-5 3-7 1-3,8,10-23 } ) ];

# equal
{
    my $equal = [
        [qw( 1 0 0 0 0 0 )], [qw( 0 1 0 0 0 0 )], [qw( 0 0 1 0 0 0 )], [qw( 0 0 0 1 0 0 )],
        [qw( 0 0 0 0 1 0 )], [qw( 0 0 0 0 0 1 )]
    ];

    for my $i ( 0 .. @$sets - 1 ) {
        for my $j ( 0 .. @$sets - 1 ) {
            my $op1 = $sets->[$i];
            my $op2 = $sets->[$j];

            my $set1   = AlignDB::IntSpan->new($op1);
            my $set2   = AlignDB::IntSpan->new($op2);
            my $result = $set1->equal($set2);
            printf "#%-12s %-12s %-12s -> %d\n", "equal", $op1, $op2, $result;
            my $test_name = "equal|$i-$j";
            is( $result, $equal->[$i][$j], $test_name );
        }
    }

    print "\n";
}

# subset
{
    my $subset = [
        [qw( 1 1 1 1 1 1 )], [qw( 0 1 0 1 0 1 )], [qw( 0 0 1 1 1 0 )], [qw( 0 0 0 1 0 0 )],
        [qw( 0 0 0 0 1 0 )], [qw( 0 0 0 0 0 1 )]
    ];

    for my $i ( 0 .. @$sets - 1 ) {
        for my $j ( 0 .. @$sets - 1 ) {
            my $op1 = $sets->[$i];
            my $op2 = $sets->[$j];

            my $set1   = AlignDB::IntSpan->new($op1);
            my $set2   = AlignDB::IntSpan->new($op2);
            my $result = $set1->subset($set2);
            printf "#%-12s %-12s %-12s -> %d\n", "subset", $op1, $op2, $result;
            my $test_name = "subset|$i-$j";
            is( $result, $subset->[$i][$j], $test_name );
        }
    }

    print "\n";
}

# superset
{
    my $superset = [
        [qw( 1 0 0 0 0 0 )], [qw( 1 1 0 0 0 0 )], [qw( 1 0 1 0 0 0 )], [qw( 1 1 1 1 0 0 )],
        [qw( 1 0 1 0 1 0 )], [qw( 1 1 0 0 0 1 )]
    ];

    for my $i ( 0 .. @$sets - 1 ) {
        for my $j ( 0 .. @$sets - 1 ) {
            my $op1 = $sets->[$i];
            my $op2 = $sets->[$j];

            my $set1   = AlignDB::IntSpan->new($op1);
            my $set2   = AlignDB::IntSpan->new($op2);
            my $result = $set1->superset($set2);
            printf "#%-12s %-12s %-12s -> %d\n", "superset", $op1, $op2, $result;
            my $test_name = "superset|$i-$j";
            is( $result, $superset->[$i][$j], $test_name );
        }
    }

    print "\n";
}

# smaller_than
{
    my $smaller_than = [
        [qw( 0 1 1 1 1 1 )], [qw( 0 0 0 1 0 1 )], [qw( 0 0 0 1 1 0 )], [qw( 0 0 0 0 0 0 )],
        [qw( 0 0 0 0 0 0 )], [qw( 0 0 0 0 0 0 )]
    ];

    for my $i ( 0 .. @$sets - 1 ) {
        for my $j ( 0 .. @$sets - 1 ) {
            my $op1 = $sets->[$i];
            my $op2 = $sets->[$j];

            my $set1   = AlignDB::IntSpan->new($op1);
            my $set2   = AlignDB::IntSpan->new($op2);
            my $result = $set1->smaller_than($set2);
            printf "#%-12s %-12s %-12s -> %d\n", "smaller_than", $op1, $op2, $result;
            my $test_name = "smaller_than|$i-$j";
            is( $result, $smaller_than->[$i][$j], $test_name );
        }
    }

    print "\n";
}

# larger_than
{
    my $larger_than = [
        [qw( 0 0 0 0 0 0 )], [qw( 1 0 0 0 0 0 )], [qw( 1 0 0 0 0 0 )], [qw( 1 1 1 0 0 0 )],
        [qw( 1 0 1 0 0 0 )], [qw( 1 1 0 0 0 0 )]
    ];

    for my $i ( 0 .. @$sets - 1 ) {
        for my $j ( 0 .. @$sets - 1 ) {
            my $op1 = $sets->[$i];
            my $op2 = $sets->[$j];

            my $set1   = AlignDB::IntSpan->new($op1);
            my $set2   = AlignDB::IntSpan->new($op2);
            my $result = $set1->larger_than($set2);
            printf "#%-12s %-12s %-12s -> %d\n", "larger_than", $op1, $op2, $result;
            my $test_name = "larger_than|$i-$j";
            is( $result, $larger_than->[$i][$j], $test_name );
        }
    }

    print "\n";
}

done_testing(184);
