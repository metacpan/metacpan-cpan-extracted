# Test the module methods
#
# copyright (C) 2005 David Landgren

use strict;

eval qq{use Test::More tests => 87};
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Data::PowerSet 'powerset';

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

{
    my $powerset = powerset( [ 11, 22, 33 ] );
    is_deeply( $powerset, [
        [11, 22, 33,],
        [    22, 33,],
        [11 ,    33,],
        [        33,],
        [11, 22,    ],
        [    22,    ],
        [11,        ],
        [           ],
    ], "powerset()" );
}

{
    my $powerset = powerset( {join => ''}, qw(a b c) );
    is_deeply( $powerset, [
        qw( abc bc ac c ab b a ), '',
    ], "powerset() join" );
}

{
    my $powerset = powerset( {join => '-', min => -4, max => 41}, qw(a b) );
    cmp_ok( join( ':', @$powerset), 'eq', 'a-b:b:a:',
        "powerset() min+max clip and join" );
}

{
    my $powerset = powerset( {join => '-', min => 3, max => 2}, qw(a b c) );
    cmp_ok( join( ':', @$powerset), 'eq', 'a-b-c:b-c:a-c:a-b',
        "powerset() min+max flip and join" );
}

{
    my $powerset = powerset( {join => '-', min => 2}, qw(a b c) );
    cmp_ok( join( ':', @$powerset), 'eq', 'a-b-c:b-c:a-c:a-b',
        "powerset() min+join" );
}

{
    my $powerset = powerset( {join => '', max => 3}, qw(a b c d) );
    my %expected = map {($_,$_)} '', qw(
        abc abd acd ab ac ad a
        bcd bc bd b
        cd c
        d
    );
    for my $p (@$powerset) {
        my $actual = delete $expected{ $p };
        cmp_ok( $p, 'eq', $actual, "saw $p in [abcd]{0,3}" );
    }
    cmp_ok( scalar keys(%expected), '==', 0, 'and nothing left over' );
}

{
    my $t = Data::PowerSet->new(
        {
            min  => 2,
            max  => 1,
        },
        [ 2, 4, 5 ],
    );
    cmp_ok( $t->{min}, '==', 1, 'min max swapped (min)' );
    cmp_ok( $t->{max}, '==', 2, 'min max swapped (min)' );
}

{
    my $t = Data::PowerSet->new(
        {
            min  => -1,
            max  => 12,
        },
        2, 4, 5, 0,
    );
    cmp_ok( $t->{min}, '==', 0, 'min clipped' );
    cmp_ok( $t->{max}, '==', 4, 'max clipped' );
}

{
    my @set = (11, 7, 5);
    my $t = Data::PowerSet->new( @set );
    is_deeply( $t->next, [11, 7, 5,], "set of 3 (@set) - 1", );
    is_deeply( $t->next, [    7, 5,], "set of 3 (@set) - 2", );
    is_deeply( $t->next, [11,    5,], "set of 3 (@set) - 3", );
    is_deeply( $t->next, [       5,], "set of 3 (@set) - 4", );
    is_deeply( $t->next, [11, 7,   ], "set of 3 (@set) - 5", );
    is_deeply( $t->next, [    7,   ], "set of 3 (@set) - 6", );
    is_deeply( $t->next, [11,      ], "set of 3 (@set) - 7", );
    is_deeply( $t->next, [         ], "set of 3 (@set) - 8", );

    ok( !defined($t->next), 'exhausted' );

    $t->data(qw( a b 0 ));
    is_deeply( $t->next, ['a', 'b', 0,], "another set of 3 (@set) - 1", );
    is_deeply( $t->next, [     'b', 0,], "another set of 3 (@set) - 2", );
    is_deeply( $t->next, ['a',      0,], "another set of 3 (@set) - 3", );
    is_deeply( $t->next, [          0,], "another set of 3 (@set) - 4", );
    is_deeply( $t->next, ['a', 'b',   ], "another set of 3 (@set) - 5", );
    is_deeply( $t->next, [     'b',   ], "another set of 3 (@set) - 6", );
    is_deeply( $t->next, ['a',        ], "another set of 3 (@set) - 7", );
    is_deeply( $t->next, [            ], "another set of 3 (@set) - 8", );

    ok( !defined($t->next), 'exhausted again' );

    $t->reset;
    is_deeply( $t->next, ['a', 'b', 0,], "another set of 3 (@set) - 1", );
    is_deeply( $t->next, [     'b', 0,], "another set of 3 (@set) - 2", );
    is_deeply( $t->next, ['a',      0,], "another set of 3 (@set) - 3", );
    is_deeply( $t->next, [          0,], "another set of 3 (@set) - 4", );
    is_deeply( $t->next, ['a', 'b',   ], "another set of 3 (@set) - 5", );
    is_deeply( $t->next, [     'b',   ], "another set of 3 (@set) - 6", );
    is_deeply( $t->next, ['a',        ], "another set of 3 (@set) - 7", );
    is_deeply( $t->next, [            ], "another set of 3 (@set) - 8", );

    ok( !defined($t->next), 'exhausted yet again' );
}

{
    my @set = 'a' .. 'e';
    my $t = Data::PowerSet->new(
        {
            min  => 3,
            max  => 4,
        },
        \@set
    );

    my %expected = map{($_,$_)} qw(
        abc abcd abce abd abde abe
        acd acde ace
        ade
        bcd bcde bce
        bde
        cde
    );

    while( my $r = $t->next ) {
        my $str = join( '', @$r );
        my $actual = delete $expected{ $str };
        cmp_ok( $str, 'eq', $actual, "saw $str in [abcde]{3,4}" );
    }
    cmp_ok( scalar keys(%expected), '==', 0, 'and nothing left over' );

    $t->data( 10, 20 );
    cmp_ok( $t->{min}, '==', 2, 'min clamped on new data' );
    cmp_ok( $t->{max}, '==', 2, 'max clamped on new data' );
}

{
    my $t = Data::PowerSet->new({
        min  => 3,
        max  => 4,
        join => '',
    }, 'A' .. 'E' );

    my %expected = map{($_,$_)} qw(
        ABC ABCD ABCE ABD ABDE ABE
        ACD ACDE ACE
        ADE
        BCD BCDE BCE
        BDE
        CDE
    );

    while( my $r = $t->next ) {
        my $actual = delete $expected{ $r };
        cmp_ok( $r, 'eq', $actual, "saw $r in [abcde]{3,4}" );
    }
    cmp_ok( scalar keys(%expected), '==', 0, 'and nothing left over' );
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );
