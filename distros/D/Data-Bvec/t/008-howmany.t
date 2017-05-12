use Test::More;

use Data::Bvec qw( howmany str2bit );

POD: {

    my $vec = str2bit '01010010';
    my $ones_count  = howmany $vec;     # 3
    my $zeros_count = howmany $vec, 0;  # 5

is( $ones_count,  3, 'howmany( 1 ) POD' );
is( $zeros_count, 5, 'howmany( 0 ) POD' );

}

use Test::More tests => 2;
