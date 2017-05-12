use Test::More;

use Data::Bvec qw( num2bit bit2str );

POD1: {

    my $vec = num2bit [1,2,3];  # 01110000

is( bit2str( $vec ), '01110000', 'num2bit() POD' );

}

POD2: {

    my $vec = num2bit [3,2,1];  # 01110000

is( bit2str( $vec ), '01110000', 'num2bit() POD' );

}

use Test::More tests => 2;
