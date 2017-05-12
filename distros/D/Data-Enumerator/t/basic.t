use strict;
use Test::More;

use Data::Enumerator qw/
    pattern
    range
    /;
{
    my $b = pattern( 1, 2, 3, 4, 5 );
    is_deeply(  $b->to_array, [ 1, 2, 3, 4, 5 ], 'same value' );
}
{
    my $r = range( 1, 10, 2 );
    is_deeply( $r->to_array,
        [pattern( 1 .. 10 )->where( sub { $_[0] % 2 } )->list] );
}
{
    my $b = pattern( 1, [1], 3, 4, 5 );
    is_deeply( [ $b->list ], [ 1, [1], 3, 4, 5 ], 'same value' );
}

{
    my $a = pattern( 1, 2, 3, 4, 5 );
    my $b = pattern( 5, 4, 3, 2, 1 );
    is_deeply( [ $a->add($b)->list ], [ 1, 2, 3, 4, 5, 5, 4, 3, 2, 1 ] );
}
{
    my $a = pattern( 1, 2, 3, 4, 5 );
    my $b = pattern( 5, 4, 3, 2, 1 );
    is_deeply(
        [ $a->product($b)->list ],
        [   [ 1, 5 ], [ 1, 4 ], [ 1, 3 ], [ 1, 2 ], [ 1, 1 ], [ 2, 5 ],
            [ 2, 4 ], [ 2, 3 ], [ 2, 2 ], [ 2, 1 ], [ 3, 5 ], [ 3, 4 ],
            [ 3, 3 ], [ 3, 2 ], [ 3, 1 ], [ 4, 5 ], [ 4, 4 ], [ 4, 3 ],
            [ 4, 2 ], [ 4, 1 ], [ 5, 5 ], [ 5, 4 ], [ 5, 3 ], [ 5, 2 ],
            [ 5, 1 ],
        ],
    );
}
{
    my $a   = pattern(qw/1 /);
    my $b   = pattern(qw/a c/);
    my $c   = pattern(qw/x y z/);
    my $ab  = $a->product($b);
    my $abc = $ab->product($c);

    is_deeply(
        [ $abc->product($abc)->list ],
        [   [ 1, "a", "x", 1, "a", "x" ],
            [ 1, "a", "x", 1, "a", "y" ],
            [ 1, "a", "x", 1, "a", "z" ],
            [ 1, "a", "x", 1, "c", "x" ],
            [ 1, "a", "x", 1, "c", "y" ],
            [ 1, "a", "x", 1, "c", "z" ],
            [ 1, "a", "y", 1, "a", "x" ],
            [ 1, "a", "y", 1, "a", "y" ],
            [ 1, "a", "y", 1, "a", "z" ],
            [ 1, "a", "y", 1, "c", "x" ],
            [ 1, "a", "y", 1, "c", "y" ],
            [ 1, "a", "y", 1, "c", "z" ],
            [ 1, "a", "z", 1, "a", "x" ],
            [ 1, "a", "z", 1, "a", "y" ],
            [ 1, "a", "z", 1, "a", "z" ],
            [ 1, "a", "z", 1, "c", "x" ],
            [ 1, "a", "z", 1, "c", "y" ],
            [ 1, "a", "z", 1, "c", "z" ],
            [ 1, "c", "x", 1, "a", "x" ],
            [ 1, "c", "x", 1, "a", "y" ],
            [ 1, "c", "x", 1, "a", "z" ],
            [ 1, "c", "x", 1, "c", "x" ],
            [ 1, "c", "x", 1, "c", "y" ],
            [ 1, "c", "x", 1, "c", "z" ],
            [ 1, "c", "y", 1, "a", "x" ],
            [ 1, "c", "y", 1, "a", "y" ],
            [ 1, "c", "y", 1, "a", "z" ],
            [ 1, "c", "y", 1, "c", "x" ],
            [ 1, "c", "y", 1, "c", "y" ],
            [ 1, "c", "y", 1, "c", "z" ],
            [ 1, "c", "z", 1, "a", "x" ],
            [ 1, "c", "z", 1, "a", "y" ],
            [ 1, "c", "z", 1, "a", "z" ],
            [ 1, "c", "z", 1, "c", "x" ],
            [ 1, "c", "z", 1, "c", "y" ],
            [ 1, "c", "z", 1, "c", "z" ],
        ],
    );
}
::done_testing;
