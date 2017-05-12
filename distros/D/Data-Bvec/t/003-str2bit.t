use Test::More;

use Data::Bvec qw( bit2str str2bit );

POD: {

    my $vec = str2bit '00001000';

is( bit2str( $vec ), '00001000', 'str2bit() POD' );

}

{
    my $vec;

    $vec = str2bit 1;
    is( bit2str( $vec ), '10000000', 'str2bit( 1 )' );
    $vec = str2bit 11;
    is( bit2str( $vec ), '11000000', 'str2bit( 11 )' );
    $vec = str2bit 111;
    is( bit2str( $vec ), '11100000', 'str2bit( 111 )' );
    $vec = str2bit 1111;
    is( bit2str( $vec ), '11110000', 'str2bit( 1111 )' );
    $vec = str2bit 11111;
    is( bit2str( $vec ), '11111000', 'str2bit( 11111 )' );
    $vec = str2bit 111111;
    is( bit2str( $vec ), '11111100', 'str2bit( 111111 )' );
    $vec = str2bit 1111111;
    is( bit2str( $vec ), '11111110', 'str2bit( 1111111 )' );
    $vec = str2bit 11111111;
    is( bit2str( $vec ), '11111111', 'str2bit( 11111111 )' );
    $vec = str2bit 111111111;
    is( bit2str( $vec ), '1111111110000000', 'str2bit( 111111111 )' );

}

use Test::More tests => 10;
