use strict;
use Test::More;

use Data::Enumerator qw/
    range pattern
    /;

{
    my $p = pattern(qw/x y z/);
    ::is_deeply( $p->repeat->take(10)->to_array,
        [ "x", "y", "z", "x", "y", "z", "x", "y", "z", "x" ] );
}
{
    my $p = pattern(qw/x y z/);
    ::is_deeply(
        $p->product($p)->repeat->take(10)->to_array,
        [   [ "x", "x" ],
            [ "x", "y" ],
            [ "x", "z" ],
            [ "y", "x" ],
            [ "y", "y" ],
            [ "y", "z" ],
            [ "z", "x" ],
            [ "z", "y" ],
            [ "z", "z" ],
            [ "x", "x" ],
        ],
    );
}

::done_testing;
