
use Test::More;

# From MLEHMANN/Types-Serialiser-1.0/t/51_types.t

use Data::Bool;

plan tests => 16;

{
    my $dec = Data::Bool::false;
    ok( !$dec, 'false() is false' );

    ok( Data::Bool::is_bool($dec), 'false() is_bool()' );

    cmp_ok( $dec,     '==', 0, 'false() == 0' );
    cmp_ok( !$dec,    '==', 1, '!false() == 1' );
    cmp_ok( $dec,     'eq', 0, 'false() eq 0' );
    cmp_ok( $dec - 1, '<',  0, 'false()-1 < 0' );
    cmp_ok( $dec + 1, '>',  0, 'false()+1 > 0' );
    cmp_ok( $dec * 2, '==', 0, 'false()*2 == 0' );
}
{
    my $dec = Data::Bool::true;
    ok( $dec, 'true() is true' );

    ok( Data::Bool::is_bool($dec), 'true() is_bool()' );

    cmp_ok( $dec,     '==', 1, 'true() == 1' );
    cmp_ok( !$dec,    '==', 0, '!true() == 0' );
    cmp_ok( $dec,     'eq', 1, 'true() eq 1' );
    cmp_ok( $dec - 1, '<=', 0, 'true()-1 <= 0' );
    cmp_ok( $dec - 2, '<',  0, 'true()-2 < 0' );
    cmp_ok( $dec * 2, '==', 2, 'true()*2 == 2' );
}
