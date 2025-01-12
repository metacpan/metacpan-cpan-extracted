use Test2::V0;
use Astro::Constants qw( SPEED_LIGHT );

is( SPEED_LIGHT, 2.99792458e8, 'SPEED_LIGHT in MKS' );

eval 'SPEED_LIGHT = 2'; # Exception can not be caught by Test2 or Test::Fatal
like( $@,
    qr/Can't modify constant item in scalar assignment/,
    "Can't change a constant"
);

done_testing();
