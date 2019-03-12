package main;

use 5.006002;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::More;
	Test::More->VERSION( 0.88 );	# Because of done_testing()
	Test::More->import();
	1;
    } or do {
	print "1..0 # skip Test::More 0.88 required\n";
	exit;
    }
}

use Astro::Coord::ECI;
use Astro::Coord::ECI::Utils qw{ deg2rad rad2deg };


plan tests => 3124;

my ( $grid, $lat, $lon );
my $sta = Astro::Coord::ECI->new();


# The following four tests were moved from t/eci.t, to have all the
# Maidenhead Locator Grid stuff together.

( $lat, $lon ) = map { sprintf '%.3f', rad2deg( $_ ) }
    $sta->maidenhead( 'FM18LV' )->geodetic();
cmp_ok $lat, '==', 38.896, 'White House latitude (from FM18lv)';
cmp_ok $lon, '==', -77.042, 'White House longitude (from FM18lv)';

( $lat, $lon ) = map { sprintf '%.1f', rad2deg( $_ ) }
    $sta->maidenhead( 'FM18' )->geodetic();
cmp_ok $lat, '==', 38.5, 'White House latitude (from FM18)';
cmp_ok $lon, '==', -77.0, 'White House longitude (from FM18)';


# Shanghai, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 31.2000 ), deg2rad( 121.500 ), 0 )
    ->maidenhead( 3 );
is $grid, 'PM01se', q{Shanghai, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM01se' ) );
cmp_ok $lat, '==', 31.1875, q{Shanghai, People's Republic of China latitude};
cmp_ok $lon, '==', 121.542, q{Shanghai, People's Republic of China longitude};


# Istanbul, Turkey
( $grid ) = $sta->geodetic( deg2rad( 41.0167 ), deg2rad( 28.9667 ), 0 )
    ->maidenhead( 3 );
is $grid, 'KN41la', q{Istanbul, Turkey Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KN41la' ) );
cmp_ok $lat, '==', 41.0208, q{Istanbul, Turkey latitude};
cmp_ok $lon, '==', 28.9583, q{Istanbul, Turkey longitude};


# Karachi, Pakistan
( $grid ) = $sta->geodetic( deg2rad( 24.8600 ), deg2rad( 67.0100 ), 0 )
    ->maidenhead( 3 );
is $grid, 'ML34mu', q{Karachi, Pakistan Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML34mu' ) );
cmp_ok $lat, '==', 24.8542, q{Karachi, Pakistan latitude};
cmp_ok $lon, '==', 67.0417, q{Karachi, Pakistan longitude};


# Delhi, India
( $grid ) = $sta->geodetic( deg2rad( 28.6100 ), deg2rad( 77.2300 ), 0 )
    ->maidenhead( 3 );
is $grid, 'ML88oo', q{Delhi, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML88oo' ) );
cmp_ok $lat, '==', 28.6042, q{Delhi, India latitude};
cmp_ok $lon, '==', 77.2083, q{Delhi, India longitude};


# Mumbai, India
( $grid ) = $sta->geodetic( deg2rad( 18.9750 ), deg2rad( 72.8258 ), 0 )
    ->maidenhead( 3 );
is $grid, 'MK68jx', q{Mumbai, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK68jx' ) );
cmp_ok $lat, '==', 18.9792, q{Mumbai, India latitude};
cmp_ok $lon, '==', 72.7917, q{Mumbai, India longitude};


# Moscow, Russia
( $grid ) = $sta->geodetic( deg2rad( 55.7517 ), deg2rad( 37.6178 ), 0 )
    ->maidenhead( 3 );
is $grid, 'KO85ts', q{Moscow, Russia Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO85ts' ) );
cmp_ok $lat, '==', 55.7708, q{Moscow, Russia latitude};
cmp_ok $lon, '==', 37.625, q{Moscow, Russia longitude};


# Sao Paulo, Brazil
( $grid ) = $sta->geodetic( deg2rad( -23.5500 ), deg2rad( -46.6333 ), 0 )
    ->maidenhead( 3 );
is $grid, 'GG66qk', q{Sao Paulo, Brazil Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG66qk' ) );
cmp_ok $lat, '==', -23.5625, q{Sao Paulo, Brazil latitude};
cmp_ok $lon, '==', -46.625, q{Sao Paulo, Brazil longitude};


# Seoul, South Korea
( $grid ) = $sta->geodetic( deg2rad( 37.5689 ), deg2rad( 126.977 ), 0 )
    ->maidenhead( 3 );
is $grid, 'PM37ln', q{Seoul, South Korea Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM37ln' ) );
cmp_ok $lat, '==', 37.5625, q{Seoul, South Korea latitude};
cmp_ok $lon, '==', 126.958, q{Seoul, South Korea longitude};


# Beijing, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 39.9139 ), deg2rad( 116.392 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OM89ev', q{Beijing, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OM89ev' ) );
cmp_ok $lat, '==', 39.8958, q{Beijing, People's Republic of China latitude};
cmp_ok $lon, '==', 116.375, q{Beijing, People's Republic of China longitude};


# Jakarta, Indonesia
( $grid ) = $sta->geodetic( deg2rad( -6.20000 ), deg2rad( 106.800 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OI33jt', q{Jakarta, Indonesia Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI33jt' ) );
cmp_ok $lat, '==', -6.1875, q{Jakarta, Indonesia latitude};
cmp_ok $lon, '==', 106.792, q{Jakarta, Indonesia longitude};


# Tokyo, Japan
( $grid ) = $sta->geodetic( deg2rad( 35.7006 ), deg2rad( 139.715 ), 0 )
    ->maidenhead( 3 );
is $grid, 'PM95uq', q{Tokyo, Japan Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM95uq' ) );
cmp_ok $lat, '==', 35.6875, q{Tokyo, Japan latitude};
cmp_ok $lon, '==', 139.708, q{Tokyo, Japan longitude};


# Mexico City, Mexico
( $grid ) = $sta->geodetic( deg2rad( 19.4333 ), deg2rad( -99.1333 ), 0 )
    ->maidenhead( 3 );
is $grid, 'EK09kk', q{Mexico City, Mexico Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK09kk' ) );
cmp_ok $lat, '==', 19.4375, q{Mexico City, Mexico latitude};
cmp_ok $lon, '==', -99.125, q{Mexico City, Mexico longitude};


# Kinshasa, Democratic Republic of the Congo
( $grid ) = $sta->geodetic( deg2rad( -4.32500 ), deg2rad( 15.3222 ), 0 )
    ->maidenhead( 3 );
is $grid, 'JI75pq', q{Kinshasa, Democratic Republic of the Congo Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JI75pq' ) );
cmp_ok $lat, '==', -4.3125, q{Kinshasa, Democratic Republic of the Congo latitude};
cmp_ok $lon, '==', 15.2917, q{Kinshasa, Democratic Republic of the Congo longitude};


# New York City, United States of America
( $grid ) = $sta->geodetic( deg2rad( 40.7167 ), deg2rad( -74.0000 ), 0 )
    ->maidenhead( 3 );
is $grid, 'FN30ar', q{New York City, United States of America Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FN30ar' ) );
cmp_ok $lat, '==', 40.7292, q{New York City, United States of America latitude};
cmp_ok $lon, '==', -73.9583, q{New York City, United States of America longitude};


# Lagos, Nigeria
( $grid ) = $sta->geodetic( deg2rad( 6.45306 ), deg2rad( 3.39583 ), 0 )
    ->maidenhead( 3 );
is $grid, 'JJ16qk', q{Lagos, Nigeria Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JJ16qk' ) );
cmp_ok $lat, '==', 6.4375, q{Lagos, Nigeria latitude};
cmp_ok $lon, '==', 3.375, q{Lagos, Nigeria longitude};


# London, England
( $grid ) = $sta->geodetic( deg2rad( 51.5072 ), deg2rad( -0.12750 ), 0 )
    ->maidenhead( 3 );
is $grid, 'IO91wm', q{London, England Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IO91wm' ) );
cmp_ok $lat, '==', 51.5208, q{London, England latitude};
cmp_ok $lon, '==', -0.125, q{London, England longitude};


# Lima, Peru
( $grid ) = $sta->geodetic( deg2rad( -12.0433 ), deg2rad( -77.0283 ), 0 )
    ->maidenhead( 3 );
is $grid, 'FH17lw', q{Lima, Peru Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FH17lw' ) );
cmp_ok $lat, '==', -12.0625, q{Lima, Peru latitude};
cmp_ok $lon, '==', -77.0417, q{Lima, Peru longitude};


# Bogota, Columbia
( $grid ) = $sta->geodetic( deg2rad( 4.59806 ), deg2rad( -74.0758 ), 0 )
    ->maidenhead( 3 );
is $grid, 'FJ24xo', q{Bogota, Columbia Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FJ24xo' ) );
cmp_ok $lat, '==', 4.60417, q{Bogota, Columbia latitude};
cmp_ok $lon, '==', -74.0417, q{Bogota, Columbia longitude};


# Tehran, Iran
( $grid ) = $sta->geodetic( deg2rad( 35.6961 ), deg2rad( 51.4231 ), 0 )
    ->maidenhead( 3 );
is $grid, 'LM55rq', q{Tehran, Iran Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM55rq' ) );
cmp_ok $lat, '==', 35.6875, q{Tehran, Iran latitude};
cmp_ok $lon, '==', 51.4583, q{Tehran, Iran longitude};


# Ho Chi Minh City, Vietnam
( $grid ) = $sta->geodetic( deg2rad( 10.7694 ), deg2rad( 106.682 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OK30is', q{Ho Chi Minh City, Vietnam Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OK30is' ) );
cmp_ok $lat, '==', 10.7708, q{Ho Chi Minh City, Vietnam latitude};
cmp_ok $lon, '==', 106.708, q{Ho Chi Minh City, Vietnam longitude};


# Hong Kong, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 22.2819 ), deg2rad( 114.158 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OL72bg', q{Hong Kong, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL72bg' ) );
cmp_ok $lat, '==', 22.2708, q{Hong Kong, People's Republic of China latitude};
cmp_ok $lon, '==', 114.125, q{Hong Kong, People's Republic of China longitude};


# Bangkok, Thailand
( $grid ) = $sta->geodetic( deg2rad( 13.7522 ), deg2rad( 100.494 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OK03fs', q{Bangkok, Thailand Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OK03fs' ) );
cmp_ok $lat, '==', 13.7708, q{Bangkok, Thailand latitude};
cmp_ok $lon, '==', 100.458, q{Bangkok, Thailand longitude};


# Dhaka, Bangladesh
( $grid ) = $sta->geodetic( deg2rad( 23.7000 ), deg2rad( 90.3750 ), 0 )
    ->maidenhead( 3 );
is $grid, 'NL53eq', q{Dhaka, Bangladesh Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL53eq' ) );
cmp_ok $lat, '==', 23.6875, q{Dhaka, Bangladesh latitude};
cmp_ok $lon, '==', 90.375, q{Dhaka, Bangladesh longitude};


# Cairo, Egypt
( $grid ) = $sta->geodetic( deg2rad( 30.0581 ), deg2rad( 31.2289 ), 0 )
    ->maidenhead( 3 );
is $grid, 'KM50ob', q{Cairo, Egypt Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM50ob' ) );
cmp_ok $lat, '==', 30.0625, q{Cairo, Egypt latitude};
cmp_ok $lon, '==', 31.2083, q{Cairo, Egypt longitude};


# Hanoi, Vietnam
( $grid ) = $sta->geodetic( deg2rad( 21.0333 ), deg2rad( 105.850 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OL21wa', q{Hanoi, Vietnam Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL21wa' ) );
cmp_ok $lat, '==', 21.0208, q{Hanoi, Vietnam latitude};
cmp_ok $lon, '==', 105.875, q{Hanoi, Vietnam longitude};


# Rio de Janiero, Brazil
( $grid ) = $sta->geodetic( deg2rad( -22.9083 ), deg2rad( -43.1964 ), 0 )
    ->maidenhead( 3 );
is $grid, 'GG87jc', q{Rio de Janiero, Brazil Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG87jc' ) );
cmp_ok $lat, '==', -22.8958, q{Rio de Janiero, Brazil latitude};
cmp_ok $lon, '==', -43.2083, q{Rio de Janiero, Brazil longitude};


# Lahore, Pakistan
( $grid ) = $sta->geodetic( deg2rad( 31.5497 ), deg2rad( 74.3436 ), 0 )
    ->maidenhead( 3 );
is $grid, 'MM71en', q{Lahore, Pakistan Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM71en' ) );
cmp_ok $lat, '==', 31.5625, q{Lahore, Pakistan latitude};
cmp_ok $lon, '==', 74.375, q{Lahore, Pakistan longitude};


# Chongqing, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 29.5583 ), deg2rad( 106.567 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OL39gn', q{Chongqing, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL39gn' ) );
cmp_ok $lat, '==', 29.5625, q{Chongqing, People's Republic of China latitude};
cmp_ok $lon, '==', 106.542, q{Chongqing, People's Republic of China longitude};


# Bangalore, India
( $grid ) = $sta->geodetic( deg2rad( 12.9667 ), deg2rad( 77.5667 ), 0 )
    ->maidenhead( 3 );
is $grid, 'MK82sx', q{Bangalore, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK82sx' ) );
cmp_ok $lat, '==', 12.9792, q{Bangalore, India latitude};
cmp_ok $lon, '==', 77.5417, q{Bangalore, India longitude};


# Tianjin, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 39.1333 ), deg2rad( 117.183 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OM89od', q{Tianjin, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OM89od' ) );
cmp_ok $lat, '==', 39.1458, q{Tianjin, People's Republic of China latitude};
cmp_ok $lon, '==', 117.208, q{Tianjin, People's Republic of China longitude};


# Baghdad, Iraq
( $grid ) = $sta->geodetic( deg2rad( 33.3333 ), deg2rad( 44.4667 ), 0 )
    ->maidenhead( 3 );
is $grid, 'LM23fh', q{Baghdad, Iraq Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM23fh' ) );
cmp_ok $lat, '==', 33.3125, q{Baghdad, Iraq latitude};
cmp_ok $lon, '==', 44.4583, q{Baghdad, Iraq longitude};


# Riyadh, Saudi Arabia
( $grid ) = $sta->geodetic( deg2rad( 24.6333 ), deg2rad( 46.7167 ), 0 )
    ->maidenhead( 3 );
is $grid, 'LL34ip', q{Riyadh, Saudi Arabia Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL34ip' ) );
cmp_ok $lat, '==', 24.6458, q{Riyadh, Saudi Arabia latitude};
cmp_ok $lon, '==', 46.7083, q{Riyadh, Saudi Arabia longitude};


# Singapore
( $grid ) = $sta->geodetic( deg2rad( 1.28333 ), deg2rad( 103.833 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OJ11vg', q{Singapore Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OJ11vg' ) );
cmp_ok $lat, '==', 1.27083, q{Singapore latitude};
cmp_ok $lon, '==', 103.792, q{Singapore longitude};


# Santiago, Chile
( $grid ) = $sta->geodetic( deg2rad( -33.4500 ), deg2rad( -70.6667 ), 0 )
    ->maidenhead( 3 );
is $grid, 'FF46pn', q{Santiago, Chile Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF46pn' ) );
cmp_ok $lat, '==', -33.4375, q{Santiago, Chile latitude};
cmp_ok $lon, '==', -70.7083, q{Santiago, Chile longitude};


# Saint Petersburg, Russia
( $grid ) = $sta->geodetic( deg2rad( 59.9500 ), deg2rad( 30.3167 ), 0 )
    ->maidenhead( 3 );
is $grid, 'KO59dw', q{Saint Petersburg, Russia Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO59dw' ) );
cmp_ok $lat, '==', 59.9375, q{Saint Petersburg, Russia latitude};
cmp_ok $lon, '==', 30.2917, q{Saint Petersburg, Russia longitude};


# Surat, India
( $grid ) = $sta->geodetic( deg2rad( 21.1667 ), deg2rad( 72.8333 ), 0 )
    ->maidenhead( 3 );
is $grid, 'ML61je', q{Surat, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML61je' ) );
cmp_ok $lat, '==', 21.1875, q{Surat, India latitude};
cmp_ok $lon, '==', 72.7917, q{Surat, India longitude};


# Chennai, India
( $grid ) = $sta->geodetic( deg2rad( 13.0839 ), deg2rad( 80.2700 ), 0 )
    ->maidenhead( 3 );
is $grid, 'NK03dc', q{Chennai, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NK03dc' ) );
cmp_ok $lat, '==', 13.1042, q{Chennai, India latitude};
cmp_ok $lon, '==', 80.2917, q{Chennai, India longitude};


# Kolkata, India
( $grid ) = $sta->geodetic( deg2rad( 22.5697 ), deg2rad( 88.3697 ), 0 )
    ->maidenhead( 3 );
is $grid, 'NL42en', q{Kolkata, India Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL42en' ) );
cmp_ok $lat, '==', 22.5625, q{Kolkata, India latitude};
cmp_ok $lon, '==', 88.375, q{Kolkata, India longitude};


# Yangon, Burma
( $grid ) = $sta->geodetic( deg2rad( 16.8000 ), deg2rad( 96.1500 ), 0 )
    ->maidenhead( 3 );
is $grid, 'NK86bt', q{Yangon, Burma Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NK86bt' ) );
cmp_ok $lat, '==', 16.8125, q{Yangon, Burma latitude};
cmp_ok $lon, '==', 96.125, q{Yangon, Burma longitude};


# Guangzhou, People's Republic of China
( $grid ) = $sta->geodetic( deg2rad( 23.1289 ), deg2rad( 113.259 ), 0 )
    ->maidenhead( 3 );
is $grid, 'OL63pd', q{Guangzhou, People's Republic of China Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL63pd' ) );
cmp_ok $lat, '==', 23.1458, q{Guangzhou, People's Republic of China latitude};
cmp_ok $lon, '==', 113.292, q{Guangzhou, People's Republic of China longitude};


( $grid ) = $sta->geodetic( -0.446315558011948, -2.67993523525116, 0 )
    ->maidenhead( 3 );
is $grid, 'BG34fk', q{Random location 1 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BG34fk' ) );
cmp_ok $lat, '==', -25.5625, q{Random location 1 latitude};
cmp_ok $lon, '==', -153.542, q{Random location 1 longitude};

( $grid ) = $sta->geodetic( -0.688212226305813, 2.17118326283465, 0 )
    ->maidenhead( 3 );
is $grid, 'PF20en', q{Random location 2 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PF20en' ) );
cmp_ok $lat, '==', -39.4375, q{Random location 2 latitude};
cmp_ok $lon, '==', 124.375, q{Random location 2 longitude};

( $grid ) = $sta->geodetic( -0.00540949832997217, -1.90880257626057, 0 )
    ->maidenhead( 3 );
is $grid, 'DI59hq', q{Random location 3 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DI59hq' ) );
cmp_ok $lat, '==', -0.3125, q{Random location 3 latitude};
cmp_ok $lon, '==', -109.375, q{Random location 3 longitude};

( $grid ) = $sta->geodetic( -0.0982933427404842, -2.68771289804708, 0 )
    ->maidenhead( 3 );
is $grid, 'BI34ai', q{Random location 4 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI34ai' ) );
cmp_ok $lat, '==', -5.64583, q{Random location 4 latitude};
cmp_ok $lon, '==', -153.958, q{Random location 4 longitude};

( $grid ) = $sta->geodetic( 0.490844906423977, 2.67234741804651, 0 )
    ->maidenhead( 3 );
is $grid, 'QL68nc', q{Random location 5 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QL68nc' ) );
cmp_ok $lat, '==', 28.1042, q{Random location 5 latitude};
cmp_ok $lon, '==', 153.125, q{Random location 5 longitude};

( $grid ) = $sta->geodetic( -0.057442588294992, -2.73723404025062, 0 )
    ->maidenhead( 3 );
is $grid, 'BI16or', q{Random location 6 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI16or' ) );
cmp_ok $lat, '==', -3.27083, q{Random location 6 latitude};
cmp_ok $lon, '==', -156.792, q{Random location 6 longitude};

( $grid ) = $sta->geodetic( 0.237938040888041, -1.44252402496285, 0 )
    ->maidenhead( 3 );
is $grid, 'EK83qp', q{Random location 7 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK83qp' ) );
cmp_ok $lat, '==', 13.6458, q{Random location 7 latitude};
cmp_ok $lon, '==', -82.625, q{Random location 7 longitude};

( $grid ) = $sta->geodetic( -0.930397445826229, 2.70401303491723, 0 )
    ->maidenhead( 3 );
is $grid, 'QD76lq', q{Random location 8 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QD76lq' ) );
cmp_ok $lat, '==', -53.3125, q{Random location 8 latitude};
cmp_ok $lon, '==', 154.958, q{Random location 8 longitude};

( $grid ) = $sta->geodetic( -0.106403763359879, 2.5313848367108, 0 )
    ->maidenhead( 3 );
is $grid, 'QI23mv', q{Random location 9 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI23mv' ) );
cmp_ok $lat, '==', -6.10417, q{Random location 9 latitude};
cmp_ok $lon, '==', 145.042, q{Random location 9 longitude};

( $grid ) = $sta->geodetic( 0.694994768911748, -0.168680555907891, 0 )
    ->maidenhead( 3 );
is $grid, 'IM59et', q{Random location 10 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IM59et' ) );
cmp_ok $lat, '==', 39.8125, q{Random location 10 latitude};
cmp_ok $lon, '==', -9.625, q{Random location 10 longitude};

( $grid ) = $sta->geodetic( 1.10993141107091, 2.74409832275853, 0 )
    ->maidenhead( 3 );
is $grid, 'QP83oo', q{Random location 11 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP83oo' ) );
cmp_ok $lat, '==', 63.6042, q{Random location 11 latitude};
cmp_ok $lon, '==', 157.208, q{Random location 11 longitude};

( $grid ) = $sta->geodetic( 0.887501383749607, -1.31679008463165, 0 )
    ->maidenhead( 3 );
is $grid, 'FO20gu', q{Random location 12 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FO20gu' ) );
cmp_ok $lat, '==', 50.8542, q{Random location 12 latitude};
cmp_ok $lon, '==', -75.4583, q{Random location 12 longitude};

( $grid ) = $sta->geodetic( 0.169610924266522, 2.99708932481363, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ59ur', q{Random location 13 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ59ur' ) );
cmp_ok $lat, '==', 9.72917, q{Random location 13 latitude};
cmp_ok $lon, '==', 171.708, q{Random location 13 longitude};

( $grid ) = $sta->geodetic( -1.16040928052681, -0.565349459991188, 0 )
    ->maidenhead( 3 );
is $grid, 'HC33tm', q{Random location 14 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HC33tm' ) );
cmp_ok $lat, '==', -66.4792, q{Random location 14 latitude};
cmp_ok $lon, '==', -32.375, q{Random location 14 longitude};

( $grid ) = $sta->geodetic( -1.03530771216139, 0.237222522003534, 0 )
    ->maidenhead( 3 );
is $grid, 'JD60tq', q{Random location 15 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JD60tq' ) );
cmp_ok $lat, '==', -59.3125, q{Random location 15 latitude};
cmp_ok $lon, '==', 13.625, q{Random location 15 longitude};

( $grid ) = $sta->geodetic( 1.05260333741713, -1.81543584409173, 0 )
    ->maidenhead( 3 );
is $grid, 'DP70xh', q{Random location 16 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DP70xh' ) );
cmp_ok $lat, '==', 60.3125, q{Random location 16 latitude};
cmp_ok $lon, '==', -104.042, q{Random location 16 longitude};

( $grid ) = $sta->geodetic( 0.109165360348549, 1.46081979336567, 0 )
    ->maidenhead( 3 );
is $grid, 'NJ16ug', q{Random location 17 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NJ16ug' ) );
cmp_ok $lat, '==', 6.27083, q{Random location 17 latitude};
cmp_ok $lon, '==', 83.7083, q{Random location 17 longitude};

( $grid ) = $sta->geodetic( 0.868143752006688, 1.00723214225063, 0 )
    ->maidenhead( 3 );
is $grid, 'LN89ur', q{Random location 18 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LN89ur' ) );
cmp_ok $lat, '==', 49.7292, q{Random location 18 latitude};
cmp_ok $lon, '==', 57.7083, q{Random location 18 longitude};

( $grid ) = $sta->geodetic( 0.418062540512063, -0.511942403695377, 0 )
    ->maidenhead( 3 );
is $grid, 'HL53iw', q{Random location 19 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HL53iw' ) );
cmp_ok $lat, '==', 23.9375, q{Random location 19 latitude};
cmp_ok $lon, '==', -29.2917, q{Random location 19 longitude};

( $grid ) = $sta->geodetic( -0.450273221724425, 0.496006242086396, 0 )
    ->maidenhead( 3 );
is $grid, 'KG44fe', q{Random location 20 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KG44fe' ) );
cmp_ok $lat, '==', -25.8125, q{Random location 20 latitude};
cmp_ok $lon, '==', 28.4583, q{Random location 20 longitude};

( $grid ) = $sta->geodetic( 1.04395403851742, -0.777624574042678, 0 )
    ->maidenhead( 3 );
is $grid, 'GO79rt', q{Random location 21 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GO79rt' ) );
cmp_ok $lat, '==', 59.8125, q{Random location 21 latitude};
cmp_ok $lon, '==', -44.5417, q{Random location 21 longitude};

( $grid ) = $sta->geodetic( 0.207652207684945, 0.727506794330136, 0 )
    ->maidenhead( 3 );
is $grid, 'LK01uv', q{Random location 22 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LK01uv' ) );
cmp_ok $lat, '==', 11.8958, q{Random location 22 latitude};
cmp_ok $lon, '==', 41.7083, q{Random location 22 longitude};

( $grid ) = $sta->geodetic( -0.402974987050051, -1.37612567657012, 0 )
    ->maidenhead( 3 );
is $grid, 'FG06nv', q{Random location 23 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FG06nv' ) );
cmp_ok $lat, '==', -23.1042, q{Random location 23 latitude};
cmp_ok $lon, '==', -78.875, q{Random location 23 longitude};

( $grid ) = $sta->geodetic( -1.28811645761034, -0.960567013218914, 0 )
    ->maidenhead( 3 );
is $grid, 'GB26le', q{Random location 24 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GB26le' ) );
cmp_ok $lat, '==', -73.8125, q{Random location 24 latitude};
cmp_ok $lon, '==', -55.0417, q{Random location 24 longitude};

( $grid ) = $sta->geodetic( -1.17736696355004, -2.50179814912257, 0 )
    ->maidenhead( 3 );
is $grid, 'BC82hn', q{Random location 25 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BC82hn' ) );
cmp_ok $lat, '==', -67.4375, q{Random location 25 latitude};
cmp_ok $lon, '==', -143.375, q{Random location 25 longitude};

( $grid ) = $sta->geodetic( 0.217359043323814, 2.20612095286218, 0 )
    ->maidenhead( 3 );
is $grid, 'PK32ek', q{Random location 26 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK32ek' ) );
cmp_ok $lat, '==', 12.4375, q{Random location 26 latitude};
cmp_ok $lon, '==', 126.375, q{Random location 26 longitude};

( $grid ) = $sta->geodetic( -0.499676245214756, 0.486468468219608, 0 )
    ->maidenhead( 3 );
is $grid, 'KG31wi', q{Random location 27 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KG31wi' ) );
cmp_ok $lat, '==', -28.6458, q{Random location 27 latitude};
cmp_ok $lon, '==', 27.875, q{Random location 27 longitude};

( $grid ) = $sta->geodetic( -1.20093013148333, 1.60539436144062, 0 )
    ->maidenhead( 3 );
is $grid, 'NC51xe', q{Random location 28 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NC51xe' ) );
cmp_ok $lat, '==', -68.8125, q{Random location 28 latitude};
cmp_ok $lon, '==', 91.9583, q{Random location 28 longitude};

( $grid ) = $sta->geodetic( -1.007570384683, 1.74358742808605, 0 )
    ->maidenhead( 3 );
is $grid, 'ND92wg', q{Random location 29 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ND92wg' ) );
cmp_ok $lat, '==', -57.7292, q{Random location 29 latitude};
cmp_ok $lon, '==', 99.875, q{Random location 29 longitude};

( $grid ) = $sta->geodetic( -0.368947618036229, -2.75268962010506, 0 )
    ->maidenhead( 3 );
is $grid, 'BG18du', q{Random location 30 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BG18du' ) );
cmp_ok $lat, '==', -21.1458, q{Random location 30 latitude};
cmp_ok $lon, '==', -157.708, q{Random location 30 longitude};

( $grid ) = $sta->geodetic( -0.120548251720736, 1.12806456095093, 0 )
    ->maidenhead( 3 );
is $grid, 'MI23hc', q{Random location 31 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MI23hc' ) );
cmp_ok $lat, '==', -6.89583, q{Random location 31 latitude};
cmp_ok $lon, '==', 64.625, q{Random location 31 longitude};

( $grid ) = $sta->geodetic( 1.07501792764867, 0.501539929684375, 0 )
    ->maidenhead( 3 );
is $grid, 'KP41io', q{Random location 32 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KP41io' ) );
cmp_ok $lat, '==', 61.6042, q{Random location 32 latitude};
cmp_ok $lon, '==', 28.7083, q{Random location 32 longitude};

( $grid ) = $sta->geodetic( 0.483028008209456, 1.00012432073361, 0 )
    ->maidenhead( 3 );
is $grid, 'LL87pq', q{Random location 33 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL87pq' ) );
cmp_ok $lat, '==', 27.6875, q{Random location 33 latitude};
cmp_ok $lon, '==', 57.2917, q{Random location 33 longitude};

( $grid ) = $sta->geodetic( 0.912602032075077, -3.01162223799918, 0 )
    ->maidenhead( 3 );
is $grid, 'AO32rg', q{Random location 34 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AO32rg' ) );
cmp_ok $lat, '==', 52.2708, q{Random location 34 latitude};
cmp_ok $lon, '==', -172.542, q{Random location 34 longitude};

( $grid ) = $sta->geodetic( 0.55592250124823, 1.95210140608331, 0 )
    ->maidenhead( 3 );
is $grid, 'OM51wu', q{Random location 35 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OM51wu' ) );
cmp_ok $lat, '==', 31.8542, q{Random location 35 latitude};
cmp_ok $lon, '==', 111.875, q{Random location 35 longitude};

( $grid ) = $sta->geodetic( 0.826010168525129, -1.20590119326887, 0 )
    ->maidenhead( 3 );
is $grid, 'FN57kh', q{Random location 36 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FN57kh' ) );
cmp_ok $lat, '==', 47.3125, q{Random location 36 latitude};
cmp_ok $lon, '==', -69.125, q{Random location 36 longitude};

( $grid ) = $sta->geodetic( 0.369834991635048, 2.18135524372737, 0 )
    ->maidenhead( 3 );
is $grid, 'PL21le', q{Random location 37 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL21le' ) );
cmp_ok $lat, '==', 21.1875, q{Random location 37 latitude};
cmp_ok $lon, '==', 124.958, q{Random location 37 longitude};

( $grid ) = $sta->geodetic( -1.27541791272279, -0.311881310115705, 0 )
    ->maidenhead( 3 );
is $grid, 'IB16bw', q{Random location 38 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IB16bw' ) );
cmp_ok $lat, '==', -73.0625, q{Random location 38 latitude};
cmp_ok $lon, '==', -17.875, q{Random location 38 longitude};

( $grid ) = $sta->geodetic( -0.0560767447900079, 1.64104636254524, 0 )
    ->maidenhead( 3 );
is $grid, 'NI76as', q{Random location 39 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NI76as' ) );
cmp_ok $lat, '==', -3.22917, q{Random location 39 latitude};
cmp_ok $lon, '==', 94.0417, q{Random location 39 longitude};

( $grid ) = $sta->geodetic( 0.578075449078338, -2.97043761665912, 0 )
    ->maidenhead( 3 );
is $grid, 'AM43vc', q{Random location 40 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AM43vc' ) );
cmp_ok $lat, '==', 33.1042, q{Random location 40 latitude};
cmp_ok $lon, '==', -170.208, q{Random location 40 longitude};

( $grid ) = $sta->geodetic( 0.341610681834024, 0.0190535133197729, 0 )
    ->maidenhead( 3 );
is $grid, 'JK09nn', q{Random location 41 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK09nn' ) );
cmp_ok $lat, '==', 19.5625, q{Random location 41 latitude};
cmp_ok $lon, '==', 1.125, q{Random location 41 longitude};

( $grid ) = $sta->geodetic( -0.971401217791641, -0.0708603644571331, 0 )
    ->maidenhead( 3 );
is $grid, 'ID74xi', q{Random location 42 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID74xi' ) );
cmp_ok $lat, '==', -55.6458, q{Random location 42 latitude};
cmp_ok $lon, '==', -4.04167, q{Random location 42 longitude};

( $grid ) = $sta->geodetic( 0.713112079055438, -1.76035219906757, 0 )
    ->maidenhead( 3 );
is $grid, 'DN90nu', q{Random location 43 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DN90nu' ) );
cmp_ok $lat, '==', 40.8542, q{Random location 43 latitude};
cmp_ok $lon, '==', -100.875, q{Random location 43 longitude};

( $grid ) = $sta->geodetic( 0.586481908061109, 1.36954641826211, 0 )
    ->maidenhead( 3 );
is $grid, 'MM93fo', q{Random location 44 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM93fo' ) );
cmp_ok $lat, '==', 33.6042, q{Random location 44 latitude};
cmp_ok $lon, '==', 78.4583, q{Random location 44 longitude};

( $grid ) = $sta->geodetic( 0.0561770242648514, -0.490957183797004, 0 )
    ->maidenhead( 3 );
is $grid, 'HJ53wf', q{Random location 45 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HJ53wf' ) );
cmp_ok $lat, '==', 3.22917, q{Random location 45 latitude};
cmp_ok $lon, '==', -28.125, q{Random location 45 longitude};

( $grid ) = $sta->geodetic( -0.191540601779486, 1.40629344531981, 0 )
    ->maidenhead( 3 );
is $grid, 'NH09ga', q{Random location 46 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NH09ga' ) );
cmp_ok $lat, '==', -10.9792, q{Random location 46 latitude};
cmp_ok $lon, '==', 80.5417, q{Random location 46 longitude};

( $grid ) = $sta->geodetic( -0.649546488007575, -2.20029950079984, 0 )
    ->maidenhead( 3 );
is $grid, 'CF62xs', q{Random location 47 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF62xs' ) );
cmp_ok $lat, '==', -37.2292, q{Random location 47 latitude};
cmp_ok $lon, '==', -126.042, q{Random location 47 longitude};

( $grid ) = $sta->geodetic( 0.41579772405124, 0.636997800609128, 0 )
    ->maidenhead( 3 );
is $grid, 'KL83ft', q{Random location 48 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KL83ft' ) );
cmp_ok $lat, '==', 23.8125, q{Random location 48 latitude};
cmp_ok $lon, '==', 36.4583, q{Random location 48 longitude};

( $grid ) = $sta->geodetic( 0.969189363753665, -0.527089031003291, 0 )
    ->maidenhead( 3 );
is $grid, 'HO45vm', q{Random location 49 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HO45vm' ) );
cmp_ok $lat, '==', 55.5208, q{Random location 49 latitude};
cmp_ok $lon, '==', -30.2083, q{Random location 49 longitude};

( $grid ) = $sta->geodetic( 0.833289579891756, 0.731944008059149, 0 )
    ->maidenhead( 3 );
is $grid, 'LN07xr', q{Random location 50 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LN07xr' ) );
cmp_ok $lat, '==', 47.7292, q{Random location 50 latitude};
cmp_ok $lon, '==', 41.9583, q{Random location 50 longitude};

( $grid ) = $sta->geodetic( 0.473038285916142, -3.06119738412207, 0 )
    ->maidenhead( 3 );
is $grid, 'AL27hc', q{Random location 51 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AL27hc' ) );
cmp_ok $lat, '==', 27.1042, q{Random location 51 latitude};
cmp_ok $lon, '==', -175.375, q{Random location 51 longitude};

( $grid ) = $sta->geodetic( 0.021910570748366, -2.13913819094075, 0 )
    ->maidenhead( 3 );
is $grid, 'CJ81rg', q{Random location 52 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CJ81rg' ) );
cmp_ok $lat, '==', 1.27083, q{Random location 52 latitude};
cmp_ok $lon, '==', -122.542, q{Random location 52 longitude};

( $grid ) = $sta->geodetic( -0.191658714999298, -2.46187183169994, 0 )
    ->maidenhead( 3 );
is $grid, 'BH99la', q{Random location 53 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BH99la' ) );
cmp_ok $lat, '==', -10.9792, q{Random location 53 latitude};
cmp_ok $lon, '==', -141.042, q{Random location 53 longitude};

( $grid ) = $sta->geodetic( 0.0312725555432805, -0.0333909137807207, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ91bt', q{Random location 54 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ91bt' ) );
cmp_ok $lat, '==', 1.8125, q{Random location 54 latitude};
cmp_ok $lon, '==', -1.875, q{Random location 54 longitude};

( $grid ) = $sta->geodetic( -0.698399841642818, 1.9012461149272, 0 )
    ->maidenhead( 3 );
is $grid, 'OE49lx', q{Random location 55 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OE49lx' ) );
cmp_ok $lat, '==', -40.0208, q{Random location 55 latitude};
cmp_ok $lon, '==', 108.958, q{Random location 55 longitude};

( $grid ) = $sta->geodetic( 0.388833423802926, -0.250824905084129, 0 )
    ->maidenhead( 3 );
is $grid, 'IL22tg', q{Random location 56 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL22tg' ) );
cmp_ok $lat, '==', 22.2708, q{Random location 56 latitude};
cmp_ok $lon, '==', -14.375, q{Random location 56 longitude};

( $grid ) = $sta->geodetic( -0.448691269417244, -2.1854740372379, 0 )
    ->maidenhead( 3 );
is $grid, 'CG74jh', q{Random location 57 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG74jh' ) );
cmp_ok $lat, '==', -25.6875, q{Random location 57 latitude};
cmp_ok $lon, '==', -125.208, q{Random location 57 longitude};

( $grid ) = $sta->geodetic( 0.713826011439928, -1.86262000886042, 0 )
    ->maidenhead( 3 );
is $grid, 'DN60pv', q{Random location 58 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DN60pv' ) );
cmp_ok $lat, '==', 40.8958, q{Random location 58 latitude};
cmp_ok $lon, '==', -106.708, q{Random location 58 longitude};

( $grid ) = $sta->geodetic( 1.30811776099635, 1.80935729268481, 0 )
    ->maidenhead( 3 );
is $grid, 'OQ14uw', q{Random location 59 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OQ14uw' ) );
cmp_ok $lat, '==', 74.9375, q{Random location 59 latitude};
cmp_ok $lon, '==', 103.708, q{Random location 59 longitude};

( $grid ) = $sta->geodetic( 0.764846409941859, -0.280986083932399, 0 )
    ->maidenhead( 3 );
is $grid, 'IN13wt', q{Random location 60 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IN13wt' ) );
cmp_ok $lat, '==', 43.8125, q{Random location 60 latitude};
cmp_ok $lon, '==', -16.125, q{Random location 60 longitude};

( $grid ) = $sta->geodetic( -0.441124920636187, 0.685908463707471, 0 )
    ->maidenhead( 3 );
is $grid, 'KG94pr', q{Random location 61 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KG94pr' ) );
cmp_ok $lat, '==', -25.2708, q{Random location 61 latitude};
cmp_ok $lon, '==', 39.2917, q{Random location 61 longitude};

( $grid ) = $sta->geodetic( -0.118917682846271, 2.67705319399905, 0 )
    ->maidenhead( 3 );
is $grid, 'QI63qe', q{Random location 62 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI63qe' ) );
cmp_ok $lat, '==', -6.8125, q{Random location 62 latitude};
cmp_ok $lon, '==', 153.375, q{Random location 62 longitude};

( $grid ) = $sta->geodetic( -0.860730408409126, 0.528153328230097, 0 )
    ->maidenhead( 3 );
is $grid, 'KE50dq', q{Random location 63 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KE50dq' ) );
cmp_ok $lat, '==', -49.3125, q{Random location 63 latitude};
cmp_ok $lon, '==', 30.2917, q{Random location 63 longitude};

( $grid ) = $sta->geodetic( 0.73621043211296, 3.12602015329582, 0 )
    ->maidenhead( 3 );
is $grid, 'RN92ne', q{Random location 64 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RN92ne' ) );
cmp_ok $lat, '==', 42.1875, q{Random location 64 latitude};
cmp_ok $lon, '==', 179.125, q{Random location 64 longitude};

( $grid ) = $sta->geodetic( 0.00349840304185323, -1.9741743861618, 0 )
    ->maidenhead( 3 );
is $grid, 'DJ30ke', q{Random location 65 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DJ30ke' ) );
cmp_ok $lat, '==', 0.1875, q{Random location 65 latitude};
cmp_ok $lon, '==', -113.125, q{Random location 65 longitude};

( $grid ) = $sta->geodetic( 1.0471013292698, 0.946643046222299, 0 )
    ->maidenhead( 3 );
is $grid, 'LO79cx', q{Random location 66 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LO79cx' ) );
cmp_ok $lat, '==', 59.9792, q{Random location 66 latitude};
cmp_ok $lon, '==', 54.2083, q{Random location 66 longitude};

( $grid ) = $sta->geodetic( -1.04742831596212, 1.08560891114859, 0 )
    ->maidenhead( 3 );
is $grid, 'MC19cx', q{Random location 67 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MC19cx' ) );
cmp_ok $lat, '==', -60.0208, q{Random location 67 latitude};
cmp_ok $lon, '==', 62.2083, q{Random location 67 longitude};

( $grid ) = $sta->geodetic( 0.228967197255778, -0.532762493835836, 0 )
    ->maidenhead( 3 );
is $grid, 'HK43rc', q{Random location 68 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK43rc' ) );
cmp_ok $lat, '==', 13.1042, q{Random location 68 latitude};
cmp_ok $lon, '==', -30.5417, q{Random location 68 longitude};

( $grid ) = $sta->geodetic( 0.625753354558778, -1.17835464609653, 0 )
    ->maidenhead( 3 );
is $grid, 'FM65fu', q{Random location 69 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FM65fu' ) );
cmp_ok $lat, '==', 35.8542, q{Random location 69 latitude};
cmp_ok $lon, '==', -67.5417, q{Random location 69 longitude};

( $grid ) = $sta->geodetic( 0.828105758712326, -1.53459603871344, 0 )
    ->maidenhead( 3 );
is $grid, 'EN67ak', q{Random location 70 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EN67ak' ) );
cmp_ok $lat, '==', 47.4375, q{Random location 70 latitude};
cmp_ok $lon, '==', -87.9583, q{Random location 70 longitude};

( $grid ) = $sta->geodetic( 0.669407181648828, 1.72692677813069, 0 )
    ->maidenhead( 3 );
is $grid, 'NM98li', q{Random location 71 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM98li' ) );
cmp_ok $lat, '==', 38.3542, q{Random location 71 latitude};
cmp_ok $lon, '==', 98.9583, q{Random location 71 longitude};

( $grid ) = $sta->geodetic( 0.552996193189682, 0.799912181590948, 0 )
    ->maidenhead( 3 );
is $grid, 'LM21vq', q{Random location 72 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM21vq' ) );
cmp_ok $lat, '==', 31.6875, q{Random location 72 latitude};
cmp_ok $lon, '==', 45.7917, q{Random location 72 longitude};

( $grid ) = $sta->geodetic( -0.863178990399335, 0.535978886012149, 0 )
    ->maidenhead( 3 );
is $grid, 'KE50in', q{Random location 73 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KE50in' ) );
cmp_ok $lat, '==', -49.4375, q{Random location 73 latitude};
cmp_ok $lon, '==', 30.7083, q{Random location 73 longitude};

( $grid ) = $sta->geodetic( -1.19735541261389, -1.8519678769728, 0 )
    ->maidenhead( 3 );
is $grid, 'DC61wj', q{Random location 74 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DC61wj' ) );
cmp_ok $lat, '==', -68.6042, q{Random location 74 latitude};
cmp_ok $lon, '==', -106.125, q{Random location 74 longitude};

( $grid ) = $sta->geodetic( 0.60909767138218, 0.248187922897745, 0 )
    ->maidenhead( 3 );
is $grid, 'JM74cv', q{Random location 75 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM74cv' ) );
cmp_ok $lat, '==', 34.8958, q{Random location 75 latitude};
cmp_ok $lon, '==', 14.2083, q{Random location 75 longitude};

( $grid ) = $sta->geodetic( -0.598364397677316, 2.76210049927345, 0 )
    ->maidenhead( 3 );
is $grid, 'QF95dr', q{Random location 76 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF95dr' ) );
cmp_ok $lat, '==', -34.2708, q{Random location 76 latitude};
cmp_ok $lon, '==', 158.292, q{Random location 76 longitude};

( $grid ) = $sta->geodetic( 0.207606272993155, 2.67310058895089, 0 )
    ->maidenhead( 3 );
is $grid, 'QK61nv', q{Random location 77 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QK61nv' ) );
cmp_ok $lat, '==', 11.8958, q{Random location 77 latitude};
cmp_ok $lon, '==', 153.125, q{Random location 77 longitude};

( $grid ) = $sta->geodetic( 1.07865387888841, -0.598013111486238, 0 )
    ->maidenhead( 3 );
is $grid, 'HP21ut', q{Random location 78 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HP21ut' ) );
cmp_ok $lat, '==', 61.8125, q{Random location 78 latitude};
cmp_ok $lon, '==', -34.2917, q{Random location 78 longitude};

( $grid ) = $sta->geodetic( -0.0214433850052291, 2.27914546285296, 0 )
    ->maidenhead( 3 );
is $grid, 'PI58hs', q{Random location 79 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PI58hs' ) );
cmp_ok $lat, '==', -1.22917, q{Random location 79 latitude};
cmp_ok $lon, '==', 130.625, q{Random location 79 longitude};

( $grid ) = $sta->geodetic( -0.810691320998661, 2.27439990749497, 0 )
    ->maidenhead( 3 );
is $grid, 'PE53dn', q{Random location 80 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PE53dn' ) );
cmp_ok $lat, '==', -46.4375, q{Random location 80 latitude};
cmp_ok $lon, '==', 130.292, q{Random location 80 longitude};

( $grid ) = $sta->geodetic( -0.435250461189334, 2.63173077750522, 0 )
    ->maidenhead( 3 );
is $grid, 'QG55jb', q{Random location 81 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG55jb' ) );
cmp_ok $lat, '==', -24.9375, q{Random location 81 latitude};
cmp_ok $lon, '==', 150.792, q{Random location 81 longitude};

( $grid ) = $sta->geodetic( -0.875670638694113, 2.23618960636193, 0 )
    ->maidenhead( 3 );
is $grid, 'PD49bt', q{Random location 82 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PD49bt' ) );
cmp_ok $lat, '==', -50.1875, q{Random location 82 latitude};
cmp_ok $lon, '==', 128.125, q{Random location 82 longitude};

( $grid ) = $sta->geodetic( 0.136151226885634, 1.70212635009528, 0 )
    ->maidenhead( 3 );
is $grid, 'NJ87st', q{Random location 83 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NJ87st' ) );
cmp_ok $lat, '==', 7.8125, q{Random location 83 latitude};
cmp_ok $lon, '==', 97.5417, q{Random location 83 longitude};

( $grid ) = $sta->geodetic( -0.829051592005111, 0.086674860228467, 0 )
    ->maidenhead( 3 );
is $grid, 'JE22ll', q{Random location 84 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JE22ll' ) );
cmp_ok $lat, '==', -47.5208, q{Random location 84 latitude};
cmp_ok $lon, '==', 4.95833, q{Random location 84 longitude};

( $grid ) = $sta->geodetic( -0.44638428599154, -1.93253632511567, 0 )
    ->maidenhead( 3 );
is $grid, 'DG44pk', q{Random location 85 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG44pk' ) );
cmp_ok $lat, '==', -25.5625, q{Random location 85 latitude};
cmp_ok $lon, '==', -110.708, q{Random location 85 longitude};

( $grid ) = $sta->geodetic( 0.127586724511993, -0.86678838090612, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ57eh', q{Random location 86 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ57eh' ) );
cmp_ok $lat, '==', 7.3125, q{Random location 86 latitude};
cmp_ok $lon, '==', -49.625, q{Random location 86 longitude};

( $grid ) = $sta->geodetic( -0.382524396355316, -1.79953532367859, 0 )
    ->maidenhead( 3 );
is $grid, 'DG88kb', q{Random location 87 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG88kb' ) );
cmp_ok $lat, '==', -21.9375, q{Random location 87 latitude};
cmp_ok $lon, '==', -103.125, q{Random location 87 longitude};

( $grid ) = $sta->geodetic( -0.671637707512163, -0.358922365055801, 0 )
    ->maidenhead( 3 );
is $grid, 'HF91rm', q{Random location 88 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF91rm' ) );
cmp_ok $lat, '==', -38.4792, q{Random location 88 latitude};
cmp_ok $lon, '==', -20.5417, q{Random location 88 longitude};

( $grid ) = $sta->geodetic( -0.652882936418145, -0.91696720995545, 0 )
    ->maidenhead( 3 );
is $grid, 'GF32ro', q{Random location 89 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GF32ro' ) );
cmp_ok $lat, '==', -37.3958, q{Random location 89 latitude};
cmp_ok $lon, '==', -52.5417, q{Random location 89 longitude};

( $grid ) = $sta->geodetic( 0.879349778582455, 1.20771253214108, 0 )
    ->maidenhead( 3 );
is $grid, 'MO40oj', q{Random location 90 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MO40oj' ) );
cmp_ok $lat, '==', 50.3958, q{Random location 90 latitude};
cmp_ok $lon, '==', 69.2083, q{Random location 90 longitude};

( $grid ) = $sta->geodetic( 0.368660752563545, -1.26639734702315, 0 )
    ->maidenhead( 3 );
is $grid, 'FL31rc', q{Random location 91 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL31rc' ) );
cmp_ok $lat, '==', 21.1042, q{Random location 91 latitude};
cmp_ok $lon, '==', -72.5417, q{Random location 91 longitude};

( $grid ) = $sta->geodetic( 0.160085609342876, 2.97866273217757, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ59he', q{Random location 92 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ59he' ) );
cmp_ok $lat, '==', 9.1875, q{Random location 92 latitude};
cmp_ok $lon, '==', 170.625, q{Random location 92 longitude};

( $grid ) = $sta->geodetic( 0.477403826707801, 3.01073504614769, 0 )
    ->maidenhead( 3 );
is $grid, 'RL67gi', q{Random location 93 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL67gi' ) );
cmp_ok $lat, '==', 27.3542, q{Random location 93 latitude};
cmp_ok $lon, '==', 172.542, q{Random location 93 longitude};

( $grid ) = $sta->geodetic( -0.950145127540305, -1.345819103601, 0 )
    ->maidenhead( 3 );
is $grid, 'FD15kn', q{Random location 94 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FD15kn' ) );
cmp_ok $lat, '==', -54.4375, q{Random location 94 latitude};
cmp_ok $lon, '==', -77.125, q{Random location 94 longitude};

( $grid ) = $sta->geodetic( -0.472203768618516, -0.188735812244416, 0 )
    ->maidenhead( 3 );
is $grid, 'IG42ow', q{Random location 95 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IG42ow' ) );
cmp_ok $lat, '==', -27.0625, q{Random location 95 latitude};
cmp_ok $lon, '==', -10.7917, q{Random location 95 longitude};

( $grid ) = $sta->geodetic( 0.690303421281309, 0.152426907591412, 0 )
    ->maidenhead( 3 );
is $grid, 'JM49in', q{Random location 96 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM49in' ) );
cmp_ok $lat, '==', 39.5625, q{Random location 96 latitude};
cmp_ok $lon, '==', 8.70833, q{Random location 96 longitude};

( $grid ) = $sta->geodetic( 0.507019575453983, -0.87257198485577, 0 )
    ->maidenhead( 3 );
is $grid, 'GL59ab', q{Random location 97 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GL59ab' ) );
cmp_ok $lat, '==', 29.0625, q{Random location 97 latitude};
cmp_ok $lon, '==', -49.9583, q{Random location 97 longitude};

( $grid ) = $sta->geodetic( 1.25761457224133, 1.86275175513148, 0 )
    ->maidenhead( 3 );
is $grid, 'OQ32ib', q{Random location 98 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OQ32ib' ) );
cmp_ok $lat, '==', 72.0625, q{Random location 98 latitude};
cmp_ok $lon, '==', 106.708, q{Random location 98 longitude};

( $grid ) = $sta->geodetic( -0.804174290509178, 2.42311333952094, 0 )
    ->maidenhead( 3 );
is $grid, 'PE93kw', q{Random location 99 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PE93kw' ) );
cmp_ok $lat, '==', -46.0625, q{Random location 99 latitude};
cmp_ok $lon, '==', 138.875, q{Random location 99 longitude};

( $grid ) = $sta->geodetic( -0.159005215035566, 1.09015760241042, 0 )
    ->maidenhead( 3 );
is $grid, 'MI10fv', q{Random location 100 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MI10fv' ) );
cmp_ok $lat, '==', -9.10417, q{Random location 100 latitude};
cmp_ok $lon, '==', 62.4583, q{Random location 100 longitude};

( $grid ) = $sta->geodetic( -0.749913254289548, -1.50980572551726, 0 )
    ->maidenhead( 3 );
is $grid, 'EE67ra', q{Random location 101 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EE67ra' ) );
cmp_ok $lat, '==', -42.9792, q{Random location 101 latitude};
cmp_ok $lon, '==', -86.5417, q{Random location 101 longitude};

( $grid ) = $sta->geodetic( -1.05070291235715, 0.0920476653674562, 0 )
    ->maidenhead( 3 );
is $grid, 'JC29pt', q{Random location 102 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JC29pt' ) );
cmp_ok $lat, '==', -60.1875, q{Random location 102 latitude};
cmp_ok $lon, '==', 5.29167, q{Random location 102 longitude};

( $grid ) = $sta->geodetic( 0.445321844544648, 1.72705252207843, 0 )
    ->maidenhead( 3 );
is $grid, 'NL95lm', q{Random location 103 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL95lm' ) );
cmp_ok $lat, '==', 25.5208, q{Random location 103 latitude};
cmp_ok $lon, '==', 98.9583, q{Random location 103 longitude};

( $grid ) = $sta->geodetic( 0.343954460035775, -2.10092765000745, 0 )
    ->maidenhead( 3 );
is $grid, 'CK99tq', q{Random location 104 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK99tq' ) );
cmp_ok $lat, '==', 19.6875, q{Random location 104 latitude};
cmp_ok $lon, '==', -120.375, q{Random location 104 longitude};

( $grid ) = $sta->geodetic( 0.616948490556898, 1.12922181624284, 0 )
    ->maidenhead( 3 );
is $grid, 'MM25ii', q{Random location 105 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM25ii' ) );
cmp_ok $lat, '==', 35.3542, q{Random location 105 latitude};
cmp_ok $lon, '==', 64.7083, q{Random location 105 longitude};

( $grid ) = $sta->geodetic( 0.668539021911492, 3.03782018285418, 0 )
    ->maidenhead( 3 );
is $grid, 'RM78ah', q{Random location 106 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM78ah' ) );
cmp_ok $lat, '==', 38.3125, q{Random location 106 latitude};
cmp_ok $lon, '==', 174.042, q{Random location 106 longitude};

( $grid ) = $sta->geodetic( 0.703385142440785, 2.38309688092946, 0 )
    ->maidenhead( 3 );
is $grid, 'PN80gh', q{Random location 107 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PN80gh' ) );
cmp_ok $lat, '==', 40.3125, q{Random location 107 latitude};
cmp_ok $lon, '==', 136.542, q{Random location 107 longitude};

( $grid ) = $sta->geodetic( 1.02843017624692, -0.460588637108932, 0 )
    ->maidenhead( 3 );
is $grid, 'HO68tw', q{Random location 108 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HO68tw' ) );
cmp_ok $lat, '==', 58.9375, q{Random location 108 latitude};
cmp_ok $lon, '==', -26.375, q{Random location 108 longitude};

( $grid ) = $sta->geodetic( -0.249953864658954, 1.82701842965143, 0 )
    ->maidenhead( 3 );
is $grid, 'OH25iq', q{Random location 109 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OH25iq' ) );
cmp_ok $lat, '==', -14.3125, q{Random location 109 latitude};
cmp_ok $lon, '==', 104.708, q{Random location 109 longitude};

( $grid ) = $sta->geodetic( -0.218142908497155, 2.68948411913626, 0 )
    ->maidenhead( 3 );
is $grid, 'QH77bm', q{Random location 110 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QH77bm' ) );
cmp_ok $lat, '==', -12.4792, q{Random location 110 latitude};
cmp_ok $lon, '==', 154.125, q{Random location 110 longitude};

( $grid ) = $sta->geodetic( -0.280727142797015, -2.08238971639833, 0 )
    ->maidenhead( 3 );
is $grid, 'DH03iv', q{Random location 111 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DH03iv' ) );
cmp_ok $lat, '==', -16.1042, q{Random location 111 latitude};
cmp_ok $lon, '==', -119.292, q{Random location 111 longitude};

( $grid ) = $sta->geodetic( -0.529045150133634, 0.854923561934678, 0 )
    ->maidenhead( 3 );
is $grid, 'LF49lq', q{Random location 112 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF49lq' ) );
cmp_ok $lat, '==', -30.3125, q{Random location 112 latitude};
cmp_ok $lon, '==', 48.9583, q{Random location 112 longitude};

( $grid ) = $sta->geodetic( -1.16723254943335, -0.252843137089584, 0 )
    ->maidenhead( 3 );
is $grid, 'IC23sc', q{Random location 113 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IC23sc' ) );
cmp_ok $lat, '==', -66.8958, q{Random location 113 latitude};
cmp_ok $lon, '==', -14.4583, q{Random location 113 longitude};

( $grid ) = $sta->geodetic( 0.973708266972098, 2.85961041841111, 0 )
    ->maidenhead( 3 );
is $grid, 'RO15ws', q{Random location 114 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RO15ws' ) );
cmp_ok $lat, '==', 55.7708, q{Random location 114 latitude};
cmp_ok $lon, '==', 163.875, q{Random location 114 longitude};

( $grid ) = $sta->geodetic( -1.162791550331, 2.51987349621628, 0 )
    ->maidenhead( 3 );
is $grid, 'QC23ej', q{Random location 115 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QC23ej' ) );
cmp_ok $lat, '==', -66.6042, q{Random location 115 latitude};
cmp_ok $lon, '==', 144.375, q{Random location 115 longitude};

( $grid ) = $sta->geodetic( 1.22321208076461, 2.27606501714079, 0 )
    ->maidenhead( 3 );
is $grid, 'PQ50ec', q{Random location 116 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PQ50ec' ) );
cmp_ok $lat, '==', 70.1042, q{Random location 116 latitude};
cmp_ok $lon, '==', 130.375, q{Random location 116 longitude};

( $grid ) = $sta->geodetic( 0.492617482827625, 0.0566050023662701, 0 )
    ->maidenhead( 3 );
is $grid, 'JL18of', q{Random location 117 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JL18of' ) );
cmp_ok $lat, '==', 28.2292, q{Random location 117 latitude};
cmp_ok $lon, '==', 3.20833, q{Random location 117 longitude};

( $grid ) = $sta->geodetic( -0.706408344098325, -0.950689025189009, 0 )
    ->maidenhead( 3 );
is $grid, 'GE29sm', q{Random location 118 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GE29sm' ) );
cmp_ok $lat, '==', -40.4792, q{Random location 118 latitude};
cmp_ok $lon, '==', -54.4583, q{Random location 118 longitude};

( $grid ) = $sta->geodetic( -0.119712238732322, 1.60776034147528, 0 )
    ->maidenhead( 3 );
is $grid, 'NI63bd', q{Random location 119 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NI63bd' ) );
cmp_ok $lat, '==', -6.85417, q{Random location 119 latitude};
cmp_ok $lon, '==', 92.125, q{Random location 119 longitude};

( $grid ) = $sta->geodetic( 1.21589768003416, -1.353385097516, 0 )
    ->maidenhead( 3 );
is $grid, 'FP19fp', q{Random location 120 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FP19fp' ) );
cmp_ok $lat, '==', 69.6458, q{Random location 120 latitude};
cmp_ok $lon, '==', -77.5417, q{Random location 120 longitude};

( $grid ) = $sta->geodetic( -0.215063958128206, 1.48414268525951, 0 )
    ->maidenhead( 3 );
is $grid, 'NH27mq', q{Random location 121 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NH27mq' ) );
cmp_ok $lat, '==', -12.3125, q{Random location 121 latitude};
cmp_ok $lon, '==', 85.0417, q{Random location 121 longitude};

( $grid ) = $sta->geodetic( -0.58189696901079, 1.16715641666894, 0 )
    ->maidenhead( 3 );
is $grid, 'MF36kp', q{Random location 122 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MF36kp' ) );
cmp_ok $lat, '==', -33.3542, q{Random location 122 latitude};
cmp_ok $lon, '==', 66.875, q{Random location 122 longitude};

( $grid ) = $sta->geodetic( 0.173497465831776, -1.86959281990576, 0 )
    ->maidenhead( 3 );
is $grid, 'DJ69kw', q{Random location 123 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DJ69kw' ) );
cmp_ok $lat, '==', 9.9375, q{Random location 123 latitude};
cmp_ok $lon, '==', -107.125, q{Random location 123 longitude};

( $grid ) = $sta->geodetic( 0.671406285216497, -2.75234367270434, 0 )
    ->maidenhead( 3 );
is $grid, 'BM18dl', q{Random location 124 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BM18dl' ) );
cmp_ok $lat, '==', 38.4792, q{Random location 124 latitude};
cmp_ok $lon, '==', -157.708, q{Random location 124 longitude};

( $grid ) = $sta->geodetic( -1.27373437565308, 2.73888654404212, 0 )
    ->maidenhead( 3 );
is $grid, 'QB87la', q{Random location 125 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QB87la' ) );
cmp_ok $lat, '==', -72.9792, q{Random location 125 latitude};
cmp_ok $lon, '==', 156.958, q{Random location 125 longitude};

( $grid ) = $sta->geodetic( -0.966928647703696, 2.68805812517861, 0 )
    ->maidenhead( 3 );
is $grid, 'QD74ao', q{Random location 126 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QD74ao' ) );
cmp_ok $lat, '==', -55.3958, q{Random location 126 latitude};
cmp_ok $lon, '==', 154.042, q{Random location 126 longitude};

( $grid ) = $sta->geodetic( -0.32191691346561, -0.0524775137150684, 0 )
    ->maidenhead( 3 );
is $grid, 'IH81ln', q{Random location 127 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH81ln' ) );
cmp_ok $lat, '==', -18.4375, q{Random location 127 latitude};
cmp_ok $lon, '==', -3.04167, q{Random location 127 longitude};

( $grid ) = $sta->geodetic( 0.433436876657763, 3.01867830713135, 0 )
    ->maidenhead( 3 );
is $grid, 'RL64lu', q{Random location 128 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL64lu' ) );
cmp_ok $lat, '==', 24.8542, q{Random location 128 latitude};
cmp_ok $lon, '==', 172.958, q{Random location 128 longitude};

( $grid ) = $sta->geodetic( -0.350962447120351, 0.930645014771637, 0 )
    ->maidenhead( 3 );
is $grid, 'LG69pv', q{Random location 129 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LG69pv' ) );
cmp_ok $lat, '==', -20.1042, q{Random location 129 latitude};
cmp_ok $lon, '==', 53.2917, q{Random location 129 longitude};

( $grid ) = $sta->geodetic( 0.401268660978904, -2.48041807189489, 0 )
    ->maidenhead( 3 );
is $grid, 'BL82wx', q{Random location 130 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL82wx' ) );
cmp_ok $lat, '==', 22.9792, q{Random location 130 latitude};
cmp_ok $lon, '==', -142.125, q{Random location 130 longitude};

( $grid ) = $sta->geodetic( -1.27004788702677, 0.976234347970445, 0 )
    ->maidenhead( 3 );
is $grid, 'LB77xf', q{Random location 131 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LB77xf' ) );
cmp_ok $lat, '==', -72.7708, q{Random location 131 latitude};
cmp_ok $lon, '==', 55.9583, q{Random location 131 longitude};

( $grid ) = $sta->geodetic( 0.0354991128731188, 0.726014021958658, 0 )
    ->maidenhead( 3 );
is $grid, 'LJ02ta', q{Random location 132 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LJ02ta' ) );
cmp_ok $lat, '==', 2.02083, q{Random location 132 latitude};
cmp_ok $lon, '==', 41.625, q{Random location 132 longitude};

( $grid ) = $sta->geodetic( -0.710188507950015, -2.35036284087074, 0 )
    ->maidenhead( 3 );
is $grid, 'CE29qh', q{Random location 133 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CE29qh' ) );
cmp_ok $lat, '==', -40.6875, q{Random location 133 latitude};
cmp_ok $lon, '==', -134.625, q{Random location 133 longitude};

( $grid ) = $sta->geodetic( 1.1426404693969, 1.28694738201258, 0 )
    ->maidenhead( 3 );
is $grid, 'MP65ul', q{Random location 134 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MP65ul' ) );
cmp_ok $lat, '==', 65.4792, q{Random location 134 latitude};
cmp_ok $lon, '==', 73.7083, q{Random location 134 longitude};

( $grid ) = $sta->geodetic( 0.984783165091945, 1.14487755244129, 0 )
    ->maidenhead( 3 );
is $grid, 'MO26tk', q{Random location 135 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MO26tk' ) );
cmp_ok $lat, '==', 56.4375, q{Random location 135 latitude};
cmp_ok $lon, '==', 65.625, q{Random location 135 longitude};

( $grid ) = $sta->geodetic( -0.528667556669949, -0.773028829232933, 0 )
    ->maidenhead( 3 );
is $grid, 'GF79ur', q{Random location 136 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GF79ur' ) );
cmp_ok $lat, '==', -30.2708, q{Random location 136 latitude};
cmp_ok $lon, '==', -44.2917, q{Random location 136 longitude};

( $grid ) = $sta->geodetic( 0.319016095704104, -2.75215735186328, 0 )
    ->maidenhead( 3 );
is $grid, 'BK18dg', q{Random location 137 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK18dg' ) );
cmp_ok $lat, '==', 18.2708, q{Random location 137 latitude};
cmp_ok $lon, '==', -157.708, q{Random location 137 longitude};

( $grid ) = $sta->geodetic( -0.606641822287371, -0.656154554225167, 0 )
    ->maidenhead( 3 );
is $grid, 'HF15ef', q{Random location 138 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF15ef' ) );
cmp_ok $lat, '==', -34.7708, q{Random location 138 latitude};
cmp_ok $lon, '==', -37.625, q{Random location 138 longitude};

( $grid ) = $sta->geodetic( 0.450119689495005, 0.636214047369044, 0 )
    ->maidenhead( 3 );
is $grid, 'KL85fs', q{Random location 139 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KL85fs' ) );
cmp_ok $lat, '==', 25.7708, q{Random location 139 latitude};
cmp_ok $lon, '==', 36.4583, q{Random location 139 longitude};

( $grid ) = $sta->geodetic( 0.408432582225723, -0.188541239024258, 0 )
    ->maidenhead( 3 );
is $grid, 'IL43oj', q{Random location 140 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL43oj' ) );
cmp_ok $lat, '==', 23.3958, q{Random location 140 latitude};
cmp_ok $lon, '==', -10.7917, q{Random location 140 longitude};

( $grid ) = $sta->geodetic( 0.16470108437991, 2.78161227925549, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ99qk', q{Random location 141 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ99qk' ) );
cmp_ok $lat, '==', 9.4375, q{Random location 141 latitude};
cmp_ok $lon, '==', 159.375, q{Random location 141 longitude};

( $grid ) = $sta->geodetic( 1.23615204429741, 1.77655256213678, 0 )
    ->maidenhead( 3 );
is $grid, 'OQ00vt', q{Random location 142 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OQ00vt' ) );
cmp_ok $lat, '==', 70.8125, q{Random location 142 latitude};
cmp_ok $lon, '==', 101.792, q{Random location 142 longitude};

( $grid ) = $sta->geodetic( -0.386578793467656, 0.316341047281972, 0 )
    ->maidenhead( 3 );
is $grid, 'JG97bu', q{Random location 143 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JG97bu' ) );
cmp_ok $lat, '==', -22.1458, q{Random location 143 latitude};
cmp_ok $lon, '==', 18.125, q{Random location 143 longitude};

( $grid ) = $sta->geodetic( 0.353194100308209, 0.0220548580686772, 0 )
    ->maidenhead( 3 );
is $grid, 'JL00pf', q{Random location 144 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JL00pf' ) );
cmp_ok $lat, '==', 20.2292, q{Random location 144 latitude};
cmp_ok $lon, '==', 1.29167, q{Random location 144 longitude};

( $grid ) = $sta->geodetic( 0.439781709425264, 0.0605644467271276, 0 )
    ->maidenhead( 3 );
is $grid, 'JL15re', q{Random location 145 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JL15re' ) );
cmp_ok $lat, '==', 25.1875, q{Random location 145 latitude};
cmp_ok $lon, '==', 3.45833, q{Random location 145 longitude};

( $grid ) = $sta->geodetic( 0.346692507405955, -0.200980066963245, 0 )
    ->maidenhead( 3 );
is $grid, 'IK49fu', q{Random location 146 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IK49fu' ) );
cmp_ok $lat, '==', 19.8542, q{Random location 146 latitude};
cmp_ok $lon, '==', -11.5417, q{Random location 146 longitude};

( $grid ) = $sta->geodetic( 0.89530195683255, -2.94522200810071, 0 )
    ->maidenhead( 3 );
is $grid, 'AO51ph', q{Random location 147 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AO51ph' ) );
cmp_ok $lat, '==', 51.3125, q{Random location 147 latitude};
cmp_ok $lon, '==', -168.708, q{Random location 147 longitude};

( $grid ) = $sta->geodetic( -1.08439712549068, -1.87172480352407, 0 )
    ->maidenhead( 3 );
is $grid, 'DC67ju', q{Random location 148 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DC67ju' ) );
cmp_ok $lat, '==', -62.1458, q{Random location 148 latitude};
cmp_ok $lon, '==', -107.208, q{Random location 148 longitude};

( $grid ) = $sta->geodetic( -0.248649399048885, 1.24811450852695, 0 )
    ->maidenhead( 3 );
is $grid, 'MH55ss', q{Random location 149 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MH55ss' ) );
cmp_ok $lat, '==', -14.2292, q{Random location 149 latitude};
cmp_ok $lon, '==', 71.5417, q{Random location 149 longitude};

( $grid ) = $sta->geodetic( 0.487022694723329, 1.95336721369138, 0 )
    ->maidenhead( 3 );
is $grid, 'OL57xv', q{Random location 150 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL57xv' ) );
cmp_ok $lat, '==', 27.8958, q{Random location 150 latitude};
cmp_ok $lon, '==', 111.958, q{Random location 150 longitude};

( $grid ) = $sta->geodetic( 1.27403916120846, -0.242577293598586, 0 )
    ->maidenhead( 3 );
is $grid, 'IQ32bx', q{Random location 151 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IQ32bx' ) );
cmp_ok $lat, '==', 72.9792, q{Random location 151 latitude};
cmp_ok $lon, '==', -13.875, q{Random location 151 longitude};

( $grid ) = $sta->geodetic( 0.286422130785926, -0.38565862263396, 0 )
    ->maidenhead( 3 );
is $grid, 'HK86wj', q{Random location 152 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK86wj' ) );
cmp_ok $lat, '==', 16.3958, q{Random location 152 latitude};
cmp_ok $lon, '==', -22.125, q{Random location 152 longitude};

( $grid ) = $sta->geodetic( 0.645193336824732, 0.633556639840836, 0 )
    ->maidenhead( 3 );
is $grid, 'KM86dx', q{Random location 153 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM86dx' ) );
cmp_ok $lat, '==', 36.9792, q{Random location 153 latitude};
cmp_ok $lon, '==', 36.2917, q{Random location 153 longitude};

( $grid ) = $sta->geodetic( 0.328532182855574, -0.398222534297651, 0 )
    ->maidenhead( 3 );
is $grid, 'HK88ot', q{Random location 154 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK88ot' ) );
cmp_ok $lat, '==', 18.8125, q{Random location 154 latitude};
cmp_ok $lon, '==', -22.7917, q{Random location 154 longitude};

( $grid ) = $sta->geodetic( 0.362469489458461, 2.01211332785752, 0 )
    ->maidenhead( 3 );
is $grid, 'OL70ps', q{Random location 155 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL70ps' ) );
cmp_ok $lat, '==', 20.7708, q{Random location 155 latitude};
cmp_ok $lon, '==', 115.292, q{Random location 155 longitude};

( $grid ) = $sta->geodetic( 1.44208464075542, 0.5877826727149, 0 )
    ->maidenhead( 3 );
is $grid, 'KR62up', q{Random location 156 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KR62up' ) );
cmp_ok $lat, '==', 82.6458, q{Random location 156 latitude};
cmp_ok $lon, '==', 33.7083, q{Random location 156 longitude};

( $grid ) = $sta->geodetic( 1.03930053601941, -0.358283226937731, 0 )
    ->maidenhead( 3 );
is $grid, 'HO99rn', q{Random location 157 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HO99rn' ) );
cmp_ok $lat, '==', 59.5625, q{Random location 157 latitude};
cmp_ok $lon, '==', -20.5417, q{Random location 157 longitude};

( $grid ) = $sta->geodetic( 1.23309213609442, 1.35746012274091, 0 )
    ->maidenhead( 3 );
is $grid, 'MQ80vp', q{Random location 158 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MQ80vp' ) );
cmp_ok $lat, '==', 70.6458, q{Random location 158 latitude};
cmp_ok $lon, '==', 77.7917, q{Random location 158 longitude};

( $grid ) = $sta->geodetic( -0.545773904573361, 0.994358970233534, 0 )
    ->maidenhead( 3 );
is $grid, 'LF88lr', q{Random location 159 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF88lr' ) );
cmp_ok $lat, '==', -31.2708, q{Random location 159 latitude};
cmp_ok $lon, '==', 56.9583, q{Random location 159 longitude};

( $grid ) = $sta->geodetic( -1.04892494314504, -2.70844479556115, 0 )
    ->maidenhead( 3 );
is $grid, 'BC29jv', q{Random location 160 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BC29jv' ) );
cmp_ok $lat, '==', -60.1042, q{Random location 160 latitude};
cmp_ok $lon, '==', -155.208, q{Random location 160 longitude};

( $grid ) = $sta->geodetic( -0.0378731342067944, -1.12723754412423, 0 )
    ->maidenhead( 3 );
is $grid, 'FI77qt', q{Random location 161 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FI77qt' ) );
cmp_ok $lat, '==', -2.1875, q{Random location 161 latitude};
cmp_ok $lon, '==', -64.625, q{Random location 161 longitude};

( $grid ) = $sta->geodetic( -0.676783772329729, -2.16790212324121, 0 )
    ->maidenhead( 3 );
is $grid, 'CF71vf', q{Random location 162 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF71vf' ) );
cmp_ok $lat, '==', -38.7708, q{Random location 162 latitude};
cmp_ok $lon, '==', -124.208, q{Random location 162 longitude};

( $grid ) = $sta->geodetic( 1.33005879362288, 3.06128697804026, 0 )
    ->maidenhead( 3 );
is $grid, 'RQ76qe', q{Random location 163 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RQ76qe' ) );
cmp_ok $lat, '==', 76.1875, q{Random location 163 latitude};
cmp_ok $lon, '==', 175.375, q{Random location 163 longitude};

( $grid ) = $sta->geodetic( -0.564245404882503, 0.860799492521665, 0 )
    ->maidenhead( 3 );
is $grid, 'LF47pq', q{Random location 164 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF47pq' ) );
cmp_ok $lat, '==', -32.3125, q{Random location 164 latitude};
cmp_ok $lon, '==', 49.2917, q{Random location 164 longitude};

( $grid ) = $sta->geodetic( 0.0203738457110547, -0.417671782300514, 0 )
    ->maidenhead( 3 );
is $grid, 'HJ81ae', q{Random location 165 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HJ81ae' ) );
cmp_ok $lat, '==', 1.1875, q{Random location 165 latitude};
cmp_ok $lon, '==', -23.9583, q{Random location 165 longitude};

( $grid ) = $sta->geodetic( 0.380831806214081, 2.34837708049, 0 )
    ->maidenhead( 3 );
is $grid, 'PL71gt', q{Random location 166 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL71gt' ) );
cmp_ok $lat, '==', 21.8125, q{Random location 166 latitude};
cmp_ok $lon, '==', 134.542, q{Random location 166 longitude};

( $grid ) = $sta->geodetic( 0.116800338033977, 0.646637232939239, 0 )
    ->maidenhead( 3 );
is $grid, 'KJ86mq', q{Random location 167 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KJ86mq' ) );
cmp_ok $lat, '==', 6.6875, q{Random location 167 latitude};
cmp_ok $lon, '==', 37.0417, q{Random location 167 longitude};

( $grid ) = $sta->geodetic( 0.222749024061525, -1.96392933204618, 0 )
    ->maidenhead( 3 );
is $grid, 'DK32rs', q{Random location 168 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DK32rs' ) );
cmp_ok $lat, '==', 12.7708, q{Random location 168 latitude};
cmp_ok $lon, '==', -112.542, q{Random location 168 longitude};

( $grid ) = $sta->geodetic( -1.31249150223536, 2.33490383136398, 0 )
    ->maidenhead( 3 );
is $grid, 'PB64vt', q{Random location 169 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PB64vt' ) );
cmp_ok $lat, '==', -75.1875, q{Random location 169 latitude};
cmp_ok $lon, '==', 133.792, q{Random location 169 longitude};

( $grid ) = $sta->geodetic( -0.358355739748, -2.31046234497774, 0 )
    ->maidenhead( 3 );
is $grid, 'CG39tl', q{Random location 170 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG39tl' ) );
cmp_ok $lat, '==', -20.5208, q{Random location 170 latitude};
cmp_ok $lon, '==', -132.375, q{Random location 170 longitude};

( $grid ) = $sta->geodetic( 0.281644846623072, -1.85454773662694, 0 )
    ->maidenhead( 3 );
is $grid, 'DK66ud', q{Random location 171 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DK66ud' ) );
cmp_ok $lat, '==', 16.1458, q{Random location 171 latitude};
cmp_ok $lon, '==', -106.292, q{Random location 171 longitude};

( $grid ) = $sta->geodetic( -0.668295659261683, -0.927019838134952, 0 )
    ->maidenhead( 3 );
is $grid, 'GF31kr', q{Random location 172 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GF31kr' ) );
cmp_ok $lat, '==', -38.2708, q{Random location 172 latitude};
cmp_ok $lon, '==', -53.125, q{Random location 172 longitude};

( $grid ) = $sta->geodetic( 0.595572061586258, 0.48522059294854, 0 )
    ->maidenhead( 3 );
is $grid, 'KM34vc', q{Random location 173 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM34vc' ) );
cmp_ok $lat, '==', 34.1042, q{Random location 173 latitude};
cmp_ok $lon, '==', 27.7917, q{Random location 173 longitude};

( $grid ) = $sta->geodetic( -0.992406113176798, -2.1304591315755, 0 )
    ->maidenhead( 3 );
is $grid, 'CD83xd', q{Random location 174 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CD83xd' ) );
cmp_ok $lat, '==', -56.8542, q{Random location 174 latitude};
cmp_ok $lon, '==', -122.042, q{Random location 174 longitude};

( $grid ) = $sta->geodetic( -0.25553839807655, -1.4321141872724, 0 )
    ->maidenhead( 3 );
is $grid, 'EH85xi', q{Random location 175 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EH85xi' ) );
cmp_ok $lat, '==', -14.6458, q{Random location 175 latitude};
cmp_ok $lon, '==', -82.0417, q{Random location 175 longitude};

( $grid ) = $sta->geodetic( -1.01686027727372, -0.408553450082922, 0 )
    ->maidenhead( 3 );
is $grid, 'HD81hr', q{Random location 176 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HD81hr' ) );
cmp_ok $lat, '==', -58.2708, q{Random location 176 latitude};
cmp_ok $lon, '==', -23.375, q{Random location 176 longitude};

( $grid ) = $sta->geodetic( -1.11593028331988, 2.96404557510328, 0 )
    ->maidenhead( 3 );
is $grid, 'RC46vb', q{Random location 177 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RC46vb' ) );
cmp_ok $lat, '==', -63.9375, q{Random location 177 latitude};
cmp_ok $lon, '==', 169.792, q{Random location 177 longitude};

( $grid ) = $sta->geodetic( 0.441258181468894, -0.65703201028152, 0 )
    ->maidenhead( 3 );
is $grid, 'HL15eg', q{Random location 178 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HL15eg' ) );
cmp_ok $lat, '==', 25.2708, q{Random location 178 latitude};
cmp_ok $lon, '==', -37.625, q{Random location 178 longitude};

( $grid ) = $sta->geodetic( -0.986177810896059, -2.94922561435127, 0 )
    ->maidenhead( 3 );
is $grid, 'AD53ml', q{Random location 179 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AD53ml' ) );
cmp_ok $lat, '==', -56.5208, q{Random location 179 latitude};
cmp_ok $lon, '==', -168.958, q{Random location 179 longitude};

( $grid ) = $sta->geodetic( 0.221021954686852, -2.87410764248279, 0 )
    ->maidenhead( 3 );
is $grid, 'AK72pp', q{Random location 180 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AK72pp' ) );
cmp_ok $lat, '==', 12.6458, q{Random location 180 latitude};
cmp_ok $lon, '==', -164.708, q{Random location 180 longitude};

( $grid ) = $sta->geodetic( 0.235483671348763, 2.35398182974687, 0 )
    ->maidenhead( 3 );
is $grid, 'PK73kl', q{Random location 181 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK73kl' ) );
cmp_ok $lat, '==', 13.4792, q{Random location 181 latitude};
cmp_ok $lon, '==', 134.875, q{Random location 181 longitude};

( $grid ) = $sta->geodetic( -0.0440033124219787, 0.510865510106785, 0 )
    ->maidenhead( 3 );
is $grid, 'KI47pl', q{Random location 182 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KI47pl' ) );
cmp_ok $lat, '==', -2.52083, q{Random location 182 latitude};
cmp_ok $lon, '==', 29.2917, q{Random location 182 longitude};

( $grid ) = $sta->geodetic( -0.703649126661624, -3.11242661636361, 0 )
    ->maidenhead( 3 );
is $grid, 'AE09uq', q{Random location 183 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE09uq' ) );
cmp_ok $lat, '==', -40.3125, q{Random location 183 latitude};
cmp_ok $lon, '==', -178.292, q{Random location 183 longitude};

( $grid ) = $sta->geodetic( 0.103918296917983, 2.13101711003058, 0 )
    ->maidenhead( 3 );
is $grid, 'PJ15bw', q{Random location 184 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PJ15bw' ) );
cmp_ok $lat, '==', 5.9375, q{Random location 184 latitude};
cmp_ok $lon, '==', 122.125, q{Random location 184 longitude};

( $grid ) = $sta->geodetic( -0.31280903324724, 1.67647176321475, 0 )
    ->maidenhead( 3 );
is $grid, 'NH82ab', q{Random location 185 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NH82ab' ) );
cmp_ok $lat, '==', -17.9375, q{Random location 185 latitude};
cmp_ok $lon, '==', 96.0417, q{Random location 185 longitude};

( $grid ) = $sta->geodetic( -0.258008025376688, -2.43021566996084, 0 )
    ->maidenhead( 3 );
is $grid, 'CH05jf', q{Random location 186 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CH05jf' ) );
cmp_ok $lat, '==', -14.7708, q{Random location 186 latitude};
cmp_ok $lon, '==', -139.208, q{Random location 186 longitude};

( $grid ) = $sta->geodetic( 0.322861520428625, 0.518843210696152, 0 )
    ->maidenhead( 3 );
is $grid, 'KK48ul', q{Random location 187 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK48ul' ) );
cmp_ok $lat, '==', 18.4792, q{Random location 187 latitude};
cmp_ok $lon, '==', 29.7083, q{Random location 187 longitude};

( $grid ) = $sta->geodetic( 0.274711027953672, 2.29890568292085, 0 )
    ->maidenhead( 3 );
is $grid, 'PK55ur', q{Random location 188 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK55ur' ) );
cmp_ok $lat, '==', 15.7292, q{Random location 188 latitude};
cmp_ok $lon, '==', 131.708, q{Random location 188 longitude};

( $grid ) = $sta->geodetic( -0.176300649083213, -2.17628425209057, 0 )
    ->maidenhead( 3 );
is $grid, 'CH79pv', q{Random location 189 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CH79pv' ) );
cmp_ok $lat, '==', -10.1042, q{Random location 189 latitude};
cmp_ok $lon, '==', -124.708, q{Random location 189 longitude};

( $grid ) = $sta->geodetic( -0.887769464262112, -0.595906128699805, 0 )
    ->maidenhead( 3 );
is $grid, 'HD29wd', q{Random location 190 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HD29wd' ) );
cmp_ok $lat, '==', -50.8542, q{Random location 190 latitude};
cmp_ok $lon, '==', -34.125, q{Random location 190 longitude};

( $grid ) = $sta->geodetic( -0.703112726247706, 1.56268447149044, 0 )
    ->maidenhead( 3 );
is $grid, 'NE49sr', q{Random location 191 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NE49sr' ) );
cmp_ok $lat, '==', -40.2708, q{Random location 191 latitude};
cmp_ok $lon, '==', 89.5417, q{Random location 191 longitude};

( $grid ) = $sta->geodetic( 1.06960190124006, 2.85397138348115, 0 )
    ->maidenhead( 3 );
is $grid, 'RP11sg', q{Random location 192 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RP11sg' ) );
cmp_ok $lat, '==', 61.2708, q{Random location 192 latitude};
cmp_ok $lon, '==', 163.542, q{Random location 192 longitude};

( $grid ) = $sta->geodetic( -0.765272212220845, 1.68955309543938, 0 )
    ->maidenhead( 3 );
is $grid, 'NE86jd', q{Random location 193 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NE86jd' ) );
cmp_ok $lat, '==', -43.8542, q{Random location 193 latitude};
cmp_ok $lon, '==', 96.7917, q{Random location 193 longitude};

( $grid ) = $sta->geodetic( -0.771599685201785, -2.83179915166155, 0 )
    ->maidenhead( 3 );
is $grid, 'AE85us', q{Random location 194 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE85us' ) );
cmp_ok $lat, '==', -44.2292, q{Random location 194 latitude};
cmp_ok $lon, '==', -162.292, q{Random location 194 longitude};

( $grid ) = $sta->geodetic( -0.628062595249159, 0.829064653993394, 0 )
    ->maidenhead( 3 );
is $grid, 'LF34sa', q{Random location 195 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF34sa' ) );
cmp_ok $lat, '==', -35.9792, q{Random location 195 latitude};
cmp_ok $lon, '==', 47.5417, q{Random location 195 longitude};

( $grid ) = $sta->geodetic( -0.307640245623717, 2.2427222251861, 0 )
    ->maidenhead( 3 );
is $grid, 'PH42fi', q{Random location 196 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PH42fi' ) );
cmp_ok $lat, '==', -17.6458, q{Random location 196 latitude};
cmp_ok $lon, '==', 128.458, q{Random location 196 longitude};

( $grid ) = $sta->geodetic( 0.75070877872571, 0.799270935575522, 0 )
    ->maidenhead( 3 );
is $grid, 'LN23va', q{Random location 197 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LN23va' ) );
cmp_ok $lat, '==', 43.0208, q{Random location 197 latitude};
cmp_ok $lon, '==', 45.7917, q{Random location 197 longitude};

( $grid ) = $sta->geodetic( -0.00380931934718487, -3.05005308156504, 0 )
    ->maidenhead( 3 );
is $grid, 'AI29os', q{Random location 198 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI29os' ) );
cmp_ok $lat, '==', -0.229167, q{Random location 198 latitude};
cmp_ok $lon, '==', -174.792, q{Random location 198 longitude};

( $grid ) = $sta->geodetic( 0.452363317126394, 1.92022210047388, 0 )
    ->maidenhead( 3 );
is $grid, 'OL55aw', q{Random location 199 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL55aw' ) );
cmp_ok $lat, '==', 25.9375, q{Random location 199 latitude};
cmp_ok $lon, '==', 110.042, q{Random location 199 longitude};

( $grid ) = $sta->geodetic( -0.724528739845903, 2.23700200028167, 0 )
    ->maidenhead( 3 );
is $grid, 'PE48cl', q{Random location 200 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PE48cl' ) );
cmp_ok $lat, '==', -41.5208, q{Random location 200 latitude};
cmp_ok $lon, '==', 128.208, q{Random location 200 longitude};

( $grid ) = $sta->geodetic( 0.0805582948229311, -0.124769508164935, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ64ko', q{Random location 201 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ64ko' ) );
cmp_ok $lat, '==', 4.60417, q{Random location 201 latitude};
cmp_ok $lon, '==', -7.125, q{Random location 201 longitude};

( $grid ) = $sta->geodetic( 0.797753983531852, -2.13481354936751, 0 )
    ->maidenhead( 3 );
is $grid, 'CN85uq', q{Random location 202 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CN85uq' ) );
cmp_ok $lat, '==', 45.6875, q{Random location 202 latitude};
cmp_ok $lon, '==', -122.292, q{Random location 202 longitude};

( $grid ) = $sta->geodetic( 0.0251427139712967, -1.03316415990259, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ01jk', q{Random location 203 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ01jk' ) );
cmp_ok $lat, '==', 1.4375, q{Random location 203 latitude};
cmp_ok $lon, '==', -59.2083, q{Random location 203 longitude};

( $grid ) = $sta->geodetic( -0.0512063744273503, 1.70988139653003, 0 )
    ->maidenhead( 3 );
is $grid, 'NI87xb', q{Random location 204 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NI87xb' ) );
cmp_ok $lat, '==', -2.9375, q{Random location 204 latitude};
cmp_ok $lon, '==', 97.9583, q{Random location 204 longitude};

( $grid ) = $sta->geodetic( 0.565290141383304, -2.75873982291945, 0 )
    ->maidenhead( 3 );
is $grid, 'BM02xj', q{Random location 205 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BM02xj' ) );
cmp_ok $lat, '==', 32.3958, q{Random location 205 latitude};
cmp_ok $lon, '==', -158.042, q{Random location 205 longitude};

( $grid ) = $sta->geodetic( 0.564022670200178, 2.48681575632118, 0 )
    ->maidenhead( 3 );
is $grid, 'QM12fh', q{Random location 206 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QM12fh' ) );
cmp_ok $lat, '==', 32.3125, q{Random location 206 latitude};
cmp_ok $lon, '==', 142.458, q{Random location 206 longitude};

( $grid ) = $sta->geodetic( -0.357212561105436, -0.510035388759301, 0 )
    ->maidenhead( 3 );
is $grid, 'HG59jm', q{Random location 207 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HG59jm' ) );
cmp_ok $lat, '==', -20.4792, q{Random location 207 latitude};
cmp_ok $lon, '==', -29.2083, q{Random location 207 longitude};

( $grid ) = $sta->geodetic( -0.47702476958552, -0.0250813563581396, 0 )
    ->maidenhead( 3 );
is $grid, 'IG92gq', q{Random location 208 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IG92gq' ) );
cmp_ok $lat, '==', -27.3125, q{Random location 208 latitude};
cmp_ok $lon, '==', -1.45833, q{Random location 208 longitude};

( $grid ) = $sta->geodetic( 0.515283665364756, 0.706351228650151, 0 )
    ->maidenhead( 3 );
is $grid, 'LL09fm', q{Random location 209 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL09fm' ) );
cmp_ok $lat, '==', 29.5208, q{Random location 209 latitude};
cmp_ok $lon, '==', 40.4583, q{Random location 209 longitude};

( $grid ) = $sta->geodetic( 0.778916429009078, 2.54436021973352, 0 )
    ->maidenhead( 3 );
is $grid, 'QN24vp', q{Random location 210 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QN24vp' ) );
cmp_ok $lat, '==', 44.6458, q{Random location 210 latitude};
cmp_ok $lon, '==', 145.792, q{Random location 210 longitude};

( $grid ) = $sta->geodetic( 0.809310750228409, -2.63500630902024, 0 )
    ->maidenhead( 3 );
is $grid, 'BN46mi', q{Random location 211 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BN46mi' ) );
cmp_ok $lat, '==', 46.3542, q{Random location 211 latitude};
cmp_ok $lon, '==', -150.958, q{Random location 211 longitude};

( $grid ) = $sta->geodetic( 0.530173671404543, -0.689932573839819, 0 )
    ->maidenhead( 3 );
is $grid, 'HM00fj', q{Random location 212 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM00fj' ) );
cmp_ok $lat, '==', 30.3958, q{Random location 212 latitude};
cmp_ok $lon, '==', -39.5417, q{Random location 212 longitude};

( $grid ) = $sta->geodetic( 0.544817582215199, 0.533137570916221, 0 )
    ->maidenhead( 3 );
is $grid, 'KM51gf', q{Random location 213 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM51gf' ) );
cmp_ok $lat, '==', 31.2292, q{Random location 213 latitude};
cmp_ok $lon, '==', 30.5417, q{Random location 213 longitude};

( $grid ) = $sta->geodetic( -0.765883827145854, -0.188399349239961, 0 )
    ->maidenhead( 3 );
is $grid, 'IE46oc', q{Random location 214 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE46oc' ) );
cmp_ok $lat, '==', -43.8958, q{Random location 214 latitude};
cmp_ok $lon, '==', -10.7917, q{Random location 214 longitude};

( $grid ) = $sta->geodetic( -1.37945785740297, 1.91806731879357, 0 )
    ->maidenhead( 3 );
is $grid, 'OB40wx', q{Random location 215 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OB40wx' ) );
cmp_ok $lat, '==', -79.0208, q{Random location 215 latitude};
cmp_ok $lon, '==', 109.875, q{Random location 215 longitude};

( $grid ) = $sta->geodetic( -0.915402048549212, -2.08647056528113, 0 )
    ->maidenhead( 3 );
is $grid, 'DD07fn', q{Random location 216 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DD07fn' ) );
cmp_ok $lat, '==', -52.4375, q{Random location 216 latitude};
cmp_ok $lon, '==', -119.542, q{Random location 216 longitude};

( $grid ) = $sta->geodetic( -0.203219686623627, -2.74651875438949, 0 )
    ->maidenhead( 3 );
is $grid, 'BH18hi', q{Random location 217 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BH18hi' ) );
cmp_ok $lat, '==', -11.6458, q{Random location 217 latitude};
cmp_ok $lon, '==', -157.375, q{Random location 217 longitude};

( $grid ) = $sta->geodetic( 0.299382342913986, -2.6251897189083, 0 )
    ->maidenhead( 3 );
is $grid, 'BK47td', q{Random location 218 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK47td' ) );
cmp_ok $lat, '==', 17.1458, q{Random location 218 latitude};
cmp_ok $lon, '==', -150.375, q{Random location 218 longitude};

( $grid ) = $sta->geodetic( 0.417331662595794, -2.10813869587186, 0 )
    ->maidenhead( 3 );
is $grid, 'CL93ov', q{Random location 219 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CL93ov' ) );
cmp_ok $lat, '==', 23.8958, q{Random location 219 latitude};
cmp_ok $lon, '==', -120.792, q{Random location 219 longitude};

( $grid ) = $sta->geodetic( -0.656897925629113, -2.22285536049511, 0 )
    ->maidenhead( 3 );
is $grid, 'CF62hi', q{Random location 220 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF62hi' ) );
cmp_ok $lat, '==', -37.6458, q{Random location 220 latitude};
cmp_ok $lon, '==', -127.375, q{Random location 220 longitude};

( $grid ) = $sta->geodetic( -0.217123052224277, -0.407277546076354, 0 )
    ->maidenhead( 3 );
is $grid, 'HH87hn', q{Random location 221 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HH87hn' ) );
cmp_ok $lat, '==', -12.4375, q{Random location 221 latitude};
cmp_ok $lon, '==', -23.375, q{Random location 221 longitude};

( $grid ) = $sta->geodetic( 0.0817238897227737, 1.28187717619352, 0 )
    ->maidenhead( 3 );
is $grid, 'MJ64rq', q{Random location 222 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MJ64rq' ) );
cmp_ok $lat, '==', 4.6875, q{Random location 222 latitude};
cmp_ok $lon, '==', 73.4583, q{Random location 222 longitude};

( $grid ) = $sta->geodetic( -0.556237573023337, -0.146139079970966, 0 )
    ->maidenhead( 3 );
is $grid, 'IF58td', q{Random location 223 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IF58td' ) );
cmp_ok $lat, '==', -31.8542, q{Random location 223 latitude};
cmp_ok $lon, '==', -8.375, q{Random location 223 longitude};

( $grid ) = $sta->geodetic( -0.239316761841041, -2.56703667800546, 0 )
    ->maidenhead( 3 );
is $grid, 'BH66lg', q{Random location 224 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BH66lg' ) );
cmp_ok $lat, '==', -13.7292, q{Random location 224 latitude};
cmp_ok $lon, '==', -147.042, q{Random location 224 longitude};

( $grid ) = $sta->geodetic( -0.763639958432644, -2.79249496557716, 0 )
    ->maidenhead( 3 );
is $grid, 'BE06af', q{Random location 225 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BE06af' ) );
cmp_ok $lat, '==', -43.7708, q{Random location 225 latitude};
cmp_ok $lon, '==', -159.958, q{Random location 225 longitude};

( $grid ) = $sta->geodetic( 0.716516558040389, -1.49414152665653, 0 )
    ->maidenhead( 3 );
is $grid, 'EN71eb', q{Random location 226 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EN71eb' ) );
cmp_ok $lat, '==', 41.0625, q{Random location 226 latitude};
cmp_ok $lon, '==', -85.625, q{Random location 226 longitude};

( $grid ) = $sta->geodetic( -0.663535744863837, -1.3690990350089, 0 )
    ->maidenhead( 3 );
is $grid, 'FF01sx', q{Random location 227 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF01sx' ) );
cmp_ok $lat, '==', -38.0208, q{Random location 227 latitude};
cmp_ok $lon, '==', -78.4583, q{Random location 227 longitude};

( $grid ) = $sta->geodetic( -0.623298011025447, -1.70762007664278, 0 )
    ->maidenhead( 3 );
is $grid, 'EF14bg', q{Random location 228 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EF14bg' ) );
cmp_ok $lat, '==', -35.7292, q{Random location 228 latitude};
cmp_ok $lon, '==', -97.875, q{Random location 228 longitude};

( $grid ) = $sta->geodetic( -0.385218572303493, -2.13059945866805, 0 )
    ->maidenhead( 3 );
is $grid, 'CG87xw', q{Random location 229 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG87xw' ) );
cmp_ok $lat, '==', -22.0625, q{Random location 229 latitude};
cmp_ok $lon, '==', -122.042, q{Random location 229 longitude};

( $grid ) = $sta->geodetic( 0.511636596728861, 1.20647121070702, 0 )
    ->maidenhead( 3 );
is $grid, 'ML49nh', q{Random location 230 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML49nh' ) );
cmp_ok $lat, '==', 29.3125, q{Random location 230 latitude};
cmp_ok $lon, '==', 69.125, q{Random location 230 longitude};

( $grid ) = $sta->geodetic( 0.363473590980814, 2.8216626522583, 0 )
    ->maidenhead( 3 );
is $grid, 'RL00ut', q{Random location 231 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL00ut' ) );
cmp_ok $lat, '==', 20.8125, q{Random location 231 latitude};
cmp_ok $lon, '==', 161.708, q{Random location 231 longitude};

( $grid ) = $sta->geodetic( -0.337575595357188, -0.840041198139936, 0 )
    ->maidenhead( 3 );
is $grid, 'GH50wp', q{Random location 232 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH50wp' ) );
cmp_ok $lat, '==', -19.3542, q{Random location 232 latitude};
cmp_ok $lon, '==', -48.125, q{Random location 232 longitude};

( $grid ) = $sta->geodetic( -0.952511134904981, -2.45506775593627, 0 )
    ->maidenhead( 3 );
is $grid, 'BD95qk', q{Random location 233 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BD95qk' ) );
cmp_ok $lat, '==', -54.5625, q{Random location 233 latitude};
cmp_ok $lon, '==', -140.625, q{Random location 233 longitude};

( $grid ) = $sta->geodetic( -0.416831001725079, -2.33019336918267, 0 )
    ->maidenhead( 3 );
is $grid, 'CG36fc', q{Random location 234 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG36fc' ) );
cmp_ok $lat, '==', -23.8958, q{Random location 234 latitude};
cmp_ok $lon, '==', -133.542, q{Random location 234 longitude};

( $grid ) = $sta->geodetic( -0.833376230147201, -2.865850420503, 0 )
    ->maidenhead( 3 );
is $grid, 'AE72vg', q{Random location 235 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE72vg' ) );
cmp_ok $lat, '==', -47.7292, q{Random location 235 latitude};
cmp_ok $lon, '==', -164.208, q{Random location 235 longitude};

( $grid ) = $sta->geodetic( -0.357006520631588, 0.0941464812696884, 0 )
    ->maidenhead( 3 );
is $grid, 'JG29qn', q{Random location 236 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JG29qn' ) );
cmp_ok $lat, '==', -20.4375, q{Random location 236 latitude};
cmp_ok $lon, '==', 5.375, q{Random location 236 longitude};

( $grid ) = $sta->geodetic( 0.488530258548324, -2.63616287582759, 0 )
    ->maidenhead( 3 );
is $grid, 'BL47lx', q{Random location 237 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL47lx' ) );
cmp_ok $lat, '==', 27.9792, q{Random location 237 latitude};
cmp_ok $lon, '==', -151.042, q{Random location 237 longitude};

( $grid ) = $sta->geodetic( 1.08179358869715, 0.943883336731285, 0 )
    ->maidenhead( 3 );
is $grid, 'LP71ax', q{Random location 238 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LP71ax' ) );
cmp_ok $lat, '==', 61.9792, q{Random location 238 latitude};
cmp_ok $lon, '==', 54.0417, q{Random location 238 longitude};

( $grid ) = $sta->geodetic( 0.2890729432241, -1.968087913298, 0 )
    ->maidenhead( 3 );
is $grid, 'DK36on', q{Random location 239 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DK36on' ) );
cmp_ok $lat, '==', 16.5625, q{Random location 239 latitude};
cmp_ok $lon, '==', -112.792, q{Random location 239 longitude};

( $grid ) = $sta->geodetic( -0.866168305399368, 1.89207000942437, 0 )
    ->maidenhead( 3 );
is $grid, 'OE40ei', q{Random location 240 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OE40ei' ) );
cmp_ok $lat, '==', -49.6458, q{Random location 240 latitude};
cmp_ok $lon, '==', 108.375, q{Random location 240 longitude};

( $grid ) = $sta->geodetic( 1.09099261269989, 1.51918568060629, 0 )
    ->maidenhead( 3 );
is $grid, 'NP32mm', q{Random location 241 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NP32mm' ) );
cmp_ok $lat, '==', 62.5208, q{Random location 241 latitude};
cmp_ok $lon, '==', 87.0417, q{Random location 241 longitude};

( $grid ) = $sta->geodetic( 0.359747576883916, -1.25294087872067, 0 )
    ->maidenhead( 3 );
is $grid, 'FL40co', q{Random location 242 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL40co' ) );
cmp_ok $lat, '==', 20.6042, q{Random location 242 latitude};
cmp_ok $lon, '==', -71.7917, q{Random location 242 longitude};

( $grid ) = $sta->geodetic( 0.0872875931097437, 3.1192233319941, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ95ia', q{Random location 243 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ95ia' ) );
cmp_ok $lat, '==', 5.02083, q{Random location 243 latitude};
cmp_ok $lon, '==', 178.708, q{Random location 243 longitude};

( $grid ) = $sta->geodetic( -1.38816010022364, 3.04245808161387, 0 )
    ->maidenhead( 3 );
is $grid, 'RB70dl', q{Random location 244 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RB70dl' ) );
cmp_ok $lat, '==', -79.5208, q{Random location 244 latitude};
cmp_ok $lon, '==', 174.292, q{Random location 244 longitude};

( $grid ) = $sta->geodetic( 0.767321077194255, -2.99386606350078, 0 )
    ->maidenhead( 3 );
is $grid, 'AN43fx', q{Random location 245 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AN43fx' ) );
cmp_ok $lat, '==', 43.9792, q{Random location 245 latitude};
cmp_ok $lon, '==', -171.542, q{Random location 245 longitude};

( $grid ) = $sta->geodetic( -0.171345050013266, -3.04453929049708, 0 )
    ->maidenhead( 3 );
is $grid, 'AI20se', q{Random location 246 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI20se' ) );
cmp_ok $lat, '==', -9.8125, q{Random location 246 latitude};
cmp_ok $lon, '==', -174.458, q{Random location 246 longitude};

( $grid ) = $sta->geodetic( 0.688225116251664, -0.750365487627938, 0 )
    ->maidenhead( 3 );
is $grid, 'GM89mk', q{Random location 247 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GM89mk' ) );
cmp_ok $lat, '==', 39.4375, q{Random location 247 latitude};
cmp_ok $lon, '==', -42.9583, q{Random location 247 longitude};

( $grid ) = $sta->geodetic( 0.72038521643464, -0.812462454642428, 0 )
    ->maidenhead( 3 );
is $grid, 'GN61rg', q{Random location 248 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GN61rg' ) );
cmp_ok $lat, '==', 41.2708, q{Random location 248 latitude};
cmp_ok $lon, '==', -46.5417, q{Random location 248 longitude};

( $grid ) = $sta->geodetic( 1.17364315823819, -2.69724689489735, 0 )
    ->maidenhead( 3 );
is $grid, 'BP27rf', q{Random location 249 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BP27rf' ) );
cmp_ok $lat, '==', 67.2292, q{Random location 249 latitude};
cmp_ok $lon, '==', -154.542, q{Random location 249 longitude};

( $grid ) = $sta->geodetic( -0.240977006322439, -0.373193978702134, 0 )
    ->maidenhead( 3 );
is $grid, 'HH96he', q{Random location 250 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HH96he' ) );
cmp_ok $lat, '==', -13.8125, q{Random location 250 latitude};
cmp_ok $lon, '==', -21.375, q{Random location 250 longitude};

( $grid ) = $sta->geodetic( 1.05820213006038, 2.31862162895713, 0 )
    ->maidenhead( 3 );
is $grid, 'PP60kp', q{Random location 251 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PP60kp' ) );
cmp_ok $lat, '==', 60.6458, q{Random location 251 latitude};
cmp_ok $lon, '==', 132.875, q{Random location 251 longitude};

( $grid ) = $sta->geodetic( 0.563590786979631, -0.188891286845869, 0 )
    ->maidenhead( 3 );
is $grid, 'IM42og', q{Random location 252 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IM42og' ) );
cmp_ok $lat, '==', 32.2708, q{Random location 252 latitude};
cmp_ok $lon, '==', -10.7917, q{Random location 252 longitude};

( $grid ) = $sta->geodetic( -0.40485036578302, 0.900933945487593, 0 )
    ->maidenhead( 3 );
is $grid, 'LG56tt', q{Random location 253 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LG56tt' ) );
cmp_ok $lat, '==', -23.1875, q{Random location 253 latitude};
cmp_ok $lon, '==', 51.625, q{Random location 253 longitude};

( $grid ) = $sta->geodetic( 0.0800495622447277, 0.560199383166691, 0 )
    ->maidenhead( 3 );
is $grid, 'KJ64bo', q{Random location 254 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KJ64bo' ) );
cmp_ok $lat, '==', 4.60417, q{Random location 254 latitude};
cmp_ok $lon, '==', 32.125, q{Random location 254 longitude};

( $grid ) = $sta->geodetic( 0.438265568054801, 2.55065399049224, 0 )
    ->maidenhead( 3 );
is $grid, 'QL35bc', q{Random location 255 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QL35bc' ) );
cmp_ok $lat, '==', 25.1042, q{Random location 255 latitude};
cmp_ok $lon, '==', 146.125, q{Random location 255 longitude};

( $grid ) = $sta->geodetic( 0.449070324348452, -1.22189103990605, 0 )
    ->maidenhead( 3 );
is $grid, 'FL45xr', q{Random location 256 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL45xr' ) );
cmp_ok $lat, '==', 25.7292, q{Random location 256 latitude};
cmp_ok $lon, '==', -70.0417, q{Random location 256 longitude};

( $grid ) = $sta->geodetic( -1.2489139262183, 1.38825546804382, 0 )
    ->maidenhead( 3 );
is $grid, 'MB98sk', q{Random location 257 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MB98sk' ) );
cmp_ok $lat, '==', -71.5625, q{Random location 257 latitude};
cmp_ok $lon, '==', 79.5417, q{Random location 257 longitude};

( $grid ) = $sta->geodetic( 0.365490402344837, 1.46191869686713, 0 )
    ->maidenhead( 3 );
is $grid, 'NL10vw', q{Random location 258 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL10vw' ) );
cmp_ok $lat, '==', 20.9375, q{Random location 258 latitude};
cmp_ok $lon, '==', 83.7917, q{Random location 258 longitude};

( $grid ) = $sta->geodetic( 1.15009101595231, -3.02676937619092, 0 )
    ->maidenhead( 3 );
is $grid, 'AP35gv', q{Random location 259 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AP35gv' ) );
cmp_ok $lat, '==', 65.8958, q{Random location 259 latitude};
cmp_ok $lon, '==', -173.458, q{Random location 259 longitude};

( $grid ) = $sta->geodetic( 0.135343730559047, 2.49965665439639, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ17os', q{Random location 260 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ17os' ) );
cmp_ok $lat, '==', 7.77083, q{Random location 260 latitude};
cmp_ok $lon, '==', 143.208, q{Random location 260 longitude};

( $grid ) = $sta->geodetic( 0.552728731077075, 2.1028481083772, 0 )
    ->maidenhead( 3 );
is $grid, 'PM01fq', q{Random location 261 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM01fq' ) );
cmp_ok $lat, '==', 31.6875, q{Random location 261 latitude};
cmp_ok $lon, '==', 120.458, q{Random location 261 longitude};

( $grid ) = $sta->geodetic( 0.346217907207337, 2.62922373170746, 0 )
    ->maidenhead( 3 );
is $grid, 'QK59hu', q{Random location 262 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QK59hu' ) );
cmp_ok $lat, '==', 19.8542, q{Random location 262 latitude};
cmp_ok $lon, '==', 150.625, q{Random location 262 longitude};

( $grid ) = $sta->geodetic( 1.06365768810565, 0.375595766921387, 0 )
    ->maidenhead( 3 );
is $grid, 'KP00sw', q{Random location 263 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KP00sw' ) );
cmp_ok $lat, '==', 60.9375, q{Random location 263 latitude};
cmp_ok $lon, '==', 21.5417, q{Random location 263 longitude};

( $grid ) = $sta->geodetic( 1.21266259573599, -2.71488946417997, 0 )
    ->maidenhead( 3 );
is $grid, 'BP29fl', q{Random location 264 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BP29fl' ) );
cmp_ok $lat, '==', 69.4792, q{Random location 264 latitude};
cmp_ok $lon, '==', -155.542, q{Random location 264 longitude};

( $grid ) = $sta->geodetic( -0.418158015393014, 1.25031233699051, 0 )
    ->maidenhead( 3 );
is $grid, 'MG56ta', q{Random location 265 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MG56ta' ) );
cmp_ok $lat, '==', -23.9792, q{Random location 265 latitude};
cmp_ok $lon, '==', 71.625, q{Random location 265 longitude};

( $grid ) = $sta->geodetic( 0.548098565361992, -2.95938556704752, 0 )
    ->maidenhead( 3 );
is $grid, 'AM51fj', q{Random location 266 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AM51fj' ) );
cmp_ok $lat, '==', 31.3958, q{Random location 266 latitude};
cmp_ok $lon, '==', -169.542, q{Random location 266 longitude};

( $grid ) = $sta->geodetic( -1.35601284996501, -1.29468934218188, 0 )
    ->maidenhead( 3 );
is $grid, 'FB22vh', q{Random location 267 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FB22vh' ) );
cmp_ok $lat, '==', -77.6875, q{Random location 267 latitude};
cmp_ok $lon, '==', -74.2083, q{Random location 267 longitude};

( $grid ) = $sta->geodetic( -0.497681676944029, -0.768159082542544, 0 )
    ->maidenhead( 3 );
is $grid, 'GG71xl', q{Random location 268 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG71xl' ) );
cmp_ok $lat, '==', -28.5208, q{Random location 268 latitude};
cmp_ok $lon, '==', -44.0417, q{Random location 268 longitude};

( $grid ) = $sta->geodetic( -0.70617544597329, -2.87903123246235, 0 )
    ->maidenhead( 3 );
is $grid, 'AE79mm', q{Random location 269 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE79mm' ) );
cmp_ok $lat, '==', -40.4792, q{Random location 269 latitude};
cmp_ok $lon, '==', -164.958, q{Random location 269 longitude};

( $grid ) = $sta->geodetic( -0.322194196856362, -0.909284241558219, 0 )
    ->maidenhead( 3 );
is $grid, 'GH31wm', q{Random location 270 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH31wm' ) );
cmp_ok $lat, '==', -18.4792, q{Random location 270 latitude};
cmp_ok $lon, '==', -52.125, q{Random location 270 longitude};

( $grid ) = $sta->geodetic( -0.625545123163254, -0.482601080087369, 0 )
    ->maidenhead( 3 );
is $grid, 'HF64ed', q{Random location 271 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF64ed' ) );
cmp_ok $lat, '==', -35.8542, q{Random location 271 latitude};
cmp_ok $lon, '==', -27.625, q{Random location 271 longitude};

( $grid ) = $sta->geodetic( -0.754871344118057, 1.36950101295812, 0 )
    ->maidenhead( 3 );
is $grid, 'ME96fr', q{Random location 272 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ME96fr' ) );
cmp_ok $lat, '==', -43.2708, q{Random location 272 latitude};
cmp_ok $lon, '==', 78.4583, q{Random location 272 longitude};

( $grid ) = $sta->geodetic( -0.0181069115544583, -2.23437058281993, 0 )
    ->maidenhead( 3 );
is $grid, 'CI58xx', q{Random location 273 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI58xx' ) );
cmp_ok $lat, '==', -1.02083, q{Random location 273 latitude};
cmp_ok $lon, '==', -128.042, q{Random location 273 longitude};

( $grid ) = $sta->geodetic( 0.251795900472658, -1.61760669553139, 0 )
    ->maidenhead( 3 );
is $grid, 'EK34pk', q{Random location 274 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK34pk' ) );
cmp_ok $lat, '==', 14.4375, q{Random location 274 latitude};
cmp_ok $lon, '==', -92.7083, q{Random location 274 longitude};

( $grid ) = $sta->geodetic( -1.0387190184769, 1.87349565113453, 0 )
    ->maidenhead( 3 );
is $grid, 'OD30ql', q{Random location 275 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OD30ql' ) );
cmp_ok $lat, '==', -59.5208, q{Random location 275 latitude};
cmp_ok $lon, '==', 107.375, q{Random location 275 longitude};

( $grid ) = $sta->geodetic( 0.0378955658463485, 1.77159725553792, 0 )
    ->maidenhead( 3 );
is $grid, 'OJ02se', q{Random location 276 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OJ02se' ) );
cmp_ok $lat, '==', 2.1875, q{Random location 276 latitude};
cmp_ok $lon, '==', 101.542, q{Random location 276 longitude};

( $grid ) = $sta->geodetic( -0.502560758070506, -0.042563618786283, 0 )
    ->maidenhead( 3 );
is $grid, 'IG81se', q{Random location 277 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IG81se' ) );
cmp_ok $lat, '==', -28.8125, q{Random location 277 latitude};
cmp_ok $lon, '==', -2.45833, q{Random location 277 longitude};

( $grid ) = $sta->geodetic( 1.26284671502358, -0.0918811079735118, 0 )
    ->maidenhead( 3 );
is $grid, 'IQ72ii', q{Random location 278 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IQ72ii' ) );
cmp_ok $lat, '==', 72.3542, q{Random location 278 latitude};
cmp_ok $lon, '==', -5.29167, q{Random location 278 longitude};

( $grid ) = $sta->geodetic( 0.421941261430386, 2.81522706169512, 0 )
    ->maidenhead( 3 );
is $grid, 'RL04pe', q{Random location 279 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL04pe' ) );
cmp_ok $lat, '==', 24.1875, q{Random location 279 latitude};
cmp_ok $lon, '==', 161.292, q{Random location 279 longitude};

( $grid ) = $sta->geodetic( -0.600047781439612, -0.478124980737498, 0 )
    ->maidenhead( 3 );
is $grid, 'HF65ho', q{Random location 280 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF65ho' ) );
cmp_ok $lat, '==', -34.3958, q{Random location 280 latitude};
cmp_ok $lon, '==', -27.375, q{Random location 280 longitude};

( $grid ) = $sta->geodetic( 0.214057526258294, -2.39884781034773, 0 )
    ->maidenhead( 3 );
is $grid, 'CK12gg', q{Random location 281 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK12gg' ) );
cmp_ok $lat, '==', 12.2708, q{Random location 281 latitude};
cmp_ok $lon, '==', -137.458, q{Random location 281 longitude};

( $grid ) = $sta->geodetic( -0.375517696469944, 1.87372882132714, 0 )
    ->maidenhead( 3 );
is $grid, 'OG38ql', q{Random location 282 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OG38ql' ) );
cmp_ok $lat, '==', -21.5208, q{Random location 282 latitude};
cmp_ok $lon, '==', 107.375, q{Random location 282 longitude};

( $grid ) = $sta->geodetic( 0.358939203952364, -1.50094465927444, 0 )
    ->maidenhead( 3 );
is $grid, 'EL70an', q{Random location 283 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EL70an' ) );
cmp_ok $lat, '==', 20.5625, q{Random location 283 latitude};
cmp_ok $lon, '==', -85.9583, q{Random location 283 longitude};

( $grid ) = $sta->geodetic( -0.0121222469625439, 1.18344535499941, 0 )
    ->maidenhead( 3 );
is $grid, 'MI39vh', q{Random location 284 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MI39vh' ) );
cmp_ok $lat, '==', -0.6875, q{Random location 284 latitude};
cmp_ok $lon, '==', 67.7917, q{Random location 284 longitude};

( $grid ) = $sta->geodetic( -0.270458815589979, 0.923081385584514, 0 )
    ->maidenhead( 3 );
is $grid, 'LH64km', q{Random location 285 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH64km' ) );
cmp_ok $lat, '==', -15.4792, q{Random location 285 latitude};
cmp_ok $lon, '==', 52.875, q{Random location 285 longitude};

( $grid ) = $sta->geodetic( 1.3010249575231, 2.31390495835311, 0 )
    ->maidenhead( 3 );
is $grid, 'PQ64gn', q{Random location 286 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PQ64gn' ) );
cmp_ok $lat, '==', 74.5625, q{Random location 286 latitude};
cmp_ok $lon, '==', 132.542, q{Random location 286 longitude};

( $grid ) = $sta->geodetic( -0.672617599782042, -2.42012976750497, 0 )
    ->maidenhead( 3 );
is $grid, 'CF01ql', q{Random location 287 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF01ql' ) );
cmp_ok $lat, '==', -38.5208, q{Random location 287 latitude};
cmp_ok $lon, '==', -138.625, q{Random location 287 longitude};

( $grid ) = $sta->geodetic( 0.0871492731896242, -2.38570457663273, 0 )
    ->maidenhead( 3 );
is $grid, 'CJ14px', q{Random location 288 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CJ14px' ) );
cmp_ok $lat, '==', 4.97917, q{Random location 288 latitude};
cmp_ok $lon, '==', -136.708, q{Random location 288 longitude};

( $grid ) = $sta->geodetic( 0.353719171283316, 2.129670540799, 0 )
    ->maidenhead( 3 );
is $grid, 'PL10ag', q{Random location 289 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL10ag' ) );
cmp_ok $lat, '==', 20.2708, q{Random location 289 latitude};
cmp_ok $lon, '==', 122.042, q{Random location 289 longitude};

( $grid ) = $sta->geodetic( 0.686529117038325, -1.8250946560885, 0 )
    ->maidenhead( 3 );
is $grid, 'DM79ri', q{Random location 290 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DM79ri' ) );
cmp_ok $lat, '==', 39.3542, q{Random location 290 latitude};
cmp_ok $lon, '==', -104.542, q{Random location 290 longitude};

( $grid ) = $sta->geodetic( 1.08857808104219, -3.10749732611264, 0 )
    ->maidenhead( 3 );
is $grid, 'AP02xi', q{Random location 291 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AP02xi' ) );
cmp_ok $lat, '==', 62.3542, q{Random location 291 latitude};
cmp_ok $lon, '==', -178.042, q{Random location 291 longitude};

( $grid ) = $sta->geodetic( -0.640905046879274, 1.99319236189856, 0 )
    ->maidenhead( 3 );
is $grid, 'OF73cg', q{Random location 292 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OF73cg' ) );
cmp_ok $lat, '==', -36.7292, q{Random location 292 latitude};
cmp_ok $lon, '==', 114.208, q{Random location 292 longitude};

( $grid ) = $sta->geodetic( 0.404726502567334, -0.743666781226446, 0 )
    ->maidenhead( 3 );
is $grid, 'GL83qe', q{Random location 293 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GL83qe' ) );
cmp_ok $lat, '==', 23.1875, q{Random location 293 latitude};
cmp_ok $lon, '==', -42.625, q{Random location 293 longitude};

( $grid ) = $sta->geodetic( 1.04829540212001, -1.38341635499422, 0 )
    ->maidenhead( 3 );
is $grid, 'FP00ib', q{Random location 294 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FP00ib' ) );
cmp_ok $lat, '==', 60.0625, q{Random location 294 latitude};
cmp_ok $lon, '==', -79.2917, q{Random location 294 longitude};

( $grid ) = $sta->geodetic( 1.34212790258173, 1.62971275958661, 0 )
    ->maidenhead( 3 );
is $grid, 'NQ66qv', q{Random location 295 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NQ66qv' ) );
cmp_ok $lat, '==', 76.8958, q{Random location 295 latitude};
cmp_ok $lon, '==', 93.375, q{Random location 295 longitude};

( $grid ) = $sta->geodetic( 0.155106300179713, 0.428773795774607, 0 )
    ->maidenhead( 3 );
is $grid, 'KJ28gv', q{Random location 296 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KJ28gv' ) );
cmp_ok $lat, '==', 8.89583, q{Random location 296 latitude};
cmp_ok $lon, '==', 24.5417, q{Random location 296 longitude};

( $grid ) = $sta->geodetic( 0.777742252900016, -2.97924156621945, 0 )
    ->maidenhead( 3 );
is $grid, 'AN44pn', q{Random location 297 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AN44pn' ) );
cmp_ok $lat, '==', 44.5625, q{Random location 297 latitude};
cmp_ok $lon, '==', -170.708, q{Random location 297 longitude};

( $grid ) = $sta->geodetic( 0.237904329926084, -2.52988516581898, 0 )
    ->maidenhead( 3 );
is $grid, 'BK73mp', q{Random location 298 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK73mp' ) );
cmp_ok $lat, '==', 13.6458, q{Random location 298 latitude};
cmp_ok $lon, '==', -144.958, q{Random location 298 longitude};

( $grid ) = $sta->geodetic( -1.29296624661924, 1.39723968562871, 0 )
    ->maidenhead( 3 );
is $grid, 'NB05aw', q{Random location 299 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NB05aw' ) );
cmp_ok $lat, '==', -74.0625, q{Random location 299 latitude};
cmp_ok $lon, '==', 80.0417, q{Random location 299 longitude};

( $grid ) = $sta->geodetic( -0.330669474151275, -1.00038583217452, 0 )
    ->maidenhead( 3 );
is $grid, 'GH11ib', q{Random location 300 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH11ib' ) );
cmp_ok $lat, '==', -18.9375, q{Random location 300 latitude};
cmp_ok $lon, '==', -57.2917, q{Random location 300 longitude};

( $grid ) = $sta->geodetic( 0.0962328017421266, 1.38134319141743, 0 )
    ->maidenhead( 3 );
is $grid, 'MJ95nm', q{Random location 301 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MJ95nm' ) );
cmp_ok $lat, '==', 5.52083, q{Random location 301 latitude};
cmp_ok $lon, '==', 79.125, q{Random location 301 longitude};

( $grid ) = $sta->geodetic( -0.530980438969407, 2.50483580124123, 0 )
    ->maidenhead( 3 );
is $grid, 'QF19sn', q{Random location 302 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF19sn' ) );
cmp_ok $lat, '==', -30.4375, q{Random location 302 latitude};
cmp_ok $lon, '==', 143.542, q{Random location 302 longitude};

( $grid ) = $sta->geodetic( 0.551475186740409, -0.524347570526262, 0 )
    ->maidenhead( 3 );
is $grid, 'HM41xo', q{Random location 303 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM41xo' ) );
cmp_ok $lat, '==', 31.6042, q{Random location 303 latitude};
cmp_ok $lon, '==', -30.0417, q{Random location 303 longitude};

( $grid ) = $sta->geodetic( 1.32876606226248, -1.1227969119043, 0 )
    ->maidenhead( 3 );
is $grid, 'FQ76ud', q{Random location 304 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FQ76ud' ) );
cmp_ok $lat, '==', 76.1458, q{Random location 304 latitude};
cmp_ok $lon, '==', -64.2917, q{Random location 304 longitude};

( $grid ) = $sta->geodetic( 1.09654027601457, -1.50878854351701, 0 )
    ->maidenhead( 3 );
is $grid, 'EP62st', q{Random location 305 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EP62st' ) );
cmp_ok $lat, '==', 62.8125, q{Random location 305 latitude};
cmp_ok $lon, '==', -86.4583, q{Random location 305 longitude};

( $grid ) = $sta->geodetic( 0.606580289165238, -1.77857531585625, 0 )
    ->maidenhead( 3 );
is $grid, 'DM94bs', q{Random location 306 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DM94bs' ) );
cmp_ok $lat, '==', 34.7708, q{Random location 306 latitude};
cmp_ok $lon, '==', -101.875, q{Random location 306 longitude};

( $grid ) = $sta->geodetic( -0.403679642500136, 0.202325815530101, 0 )
    ->maidenhead( 3 );
is $grid, 'JG56tu', q{Random location 307 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JG56tu' ) );
cmp_ok $lat, '==', -23.1458, q{Random location 307 latitude};
cmp_ok $lon, '==', 11.625, q{Random location 307 longitude};

( $grid ) = $sta->geodetic( -1.22623630505179, 1.21961387951327, 0 )
    ->maidenhead( 3 );
is $grid, 'MB49wr', q{Random location 308 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MB49wr' ) );
cmp_ok $lat, '==', -70.2708, q{Random location 308 latitude};
cmp_ok $lon, '==', 69.875, q{Random location 308 longitude};

( $grid ) = $sta->geodetic( -1.09109514193183, -2.40741494839217, 0 )
    ->maidenhead( 3 );
is $grid, 'CC17al', q{Random location 309 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CC17al' ) );
cmp_ok $lat, '==', -62.5208, q{Random location 309 latitude};
cmp_ok $lon, '==', -137.958, q{Random location 309 longitude};

( $grid ) = $sta->geodetic( 0.0288015474321253, -2.33796075009044, 0 )
    ->maidenhead( 3 );
is $grid, 'CJ31ap', q{Random location 310 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CJ31ap' ) );
cmp_ok $lat, '==', 1.64583, q{Random location 310 latitude};
cmp_ok $lon, '==', -133.958, q{Random location 310 longitude};

( $grid ) = $sta->geodetic( 0.364950945571499, -1.39517299958901, 0 )
    ->maidenhead( 3 );
is $grid, 'FL00av', q{Random location 311 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL00av' ) );
cmp_ok $lat, '==', 20.8958, q{Random location 311 latitude};
cmp_ok $lon, '==', -79.9583, q{Random location 311 longitude};

( $grid ) = $sta->geodetic( -0.453238380563467, -0.934398260566755, 0 )
    ->maidenhead( 3 );
is $grid, 'GG34fa', q{Random location 312 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG34fa' ) );
cmp_ok $lat, '==', -25.9792, q{Random location 312 latitude};
cmp_ok $lon, '==', -53.5417, q{Random location 312 longitude};

( $grid ) = $sta->geodetic( -0.716684964497325, 0.141640963379837, 0 )
    ->maidenhead( 3 );
is $grid, 'JE48bw', q{Random location 313 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JE48bw' ) );
cmp_ok $lat, '==', -41.0625, q{Random location 313 latitude};
cmp_ok $lon, '==', 8.125, q{Random location 313 longitude};

( $grid ) = $sta->geodetic( -1.14157843401578, -1.19597201591851, 0 )
    ->maidenhead( 3 );
is $grid, 'FC54ro', q{Random location 314 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FC54ro' ) );
cmp_ok $lat, '==', -65.3958, q{Random location 314 latitude};
cmp_ok $lon, '==', -68.5417, q{Random location 314 longitude};

( $grid ) = $sta->geodetic( -0.163054968252675, -2.81912166788217, 0 )
    ->maidenhead( 3 );
is $grid, 'AI90fp', q{Random location 315 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI90fp' ) );
cmp_ok $lat, '==', -9.35417, q{Random location 315 latitude};
cmp_ok $lon, '==', -161.542, q{Random location 315 longitude};

( $grid ) = $sta->geodetic( 0.477854356012331, 1.67503808655417, 0 )
    ->maidenhead( 3 );
is $grid, 'NL77xj', q{Random location 316 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL77xj' ) );
cmp_ok $lat, '==', 27.3958, q{Random location 316 latitude};
cmp_ok $lon, '==', 95.9583, q{Random location 316 longitude};

( $grid ) = $sta->geodetic( 0.258971265866425, 0.639031797791891, 0 )
    ->maidenhead( 3 );
is $grid, 'KK84hu', q{Random location 317 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK84hu' ) );
cmp_ok $lat, '==', 14.8542, q{Random location 317 latitude};
cmp_ok $lon, '==', 36.625, q{Random location 317 longitude};

( $grid ) = $sta->geodetic( -0.165322632572621, 3.10177624479034, 0 )
    ->maidenhead( 3 );
is $grid, 'RI80um', q{Random location 318 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RI80um' ) );
cmp_ok $lat, '==', -9.47917, q{Random location 318 latitude};
cmp_ok $lon, '==', 177.708, q{Random location 318 longitude};

( $grid ) = $sta->geodetic( -0.26593841400362, -2.43917109330262, 0 )
    ->maidenhead( 3 );
is $grid, 'CH04cs', q{Random location 319 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CH04cs' ) );
cmp_ok $lat, '==', -15.2292, q{Random location 319 latitude};
cmp_ok $lon, '==', -139.792, q{Random location 319 longitude};

( $grid ) = $sta->geodetic( -0.00692636722661066, -1.02056670518227, 0 )
    ->maidenhead( 3 );
is $grid, 'GI09so', q{Random location 320 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GI09so' ) );
cmp_ok $lat, '==', -0.395833, q{Random location 320 latitude};
cmp_ok $lon, '==', -58.4583, q{Random location 320 longitude};

( $grid ) = $sta->geodetic( 0.505758434610651, -1.11449886402564, 0 )
    ->maidenhead( 3 );
is $grid, 'FL88bx', q{Random location 321 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL88bx' ) );
cmp_ok $lat, '==', 28.9792, q{Random location 321 latitude};
cmp_ok $lon, '==', -63.875, q{Random location 321 longitude};

( $grid ) = $sta->geodetic( -0.658351659856398, 2.17453654739527, 0 )
    ->maidenhead( 3 );
is $grid, 'PF22hg', q{Random location 322 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PF22hg' ) );
cmp_ok $lat, '==', -37.7292, q{Random location 322 latitude};
cmp_ok $lon, '==', 124.625, q{Random location 322 longitude};

( $grid ) = $sta->geodetic( 0.413079016681926, -0.382295284004594, 0 )
    ->maidenhead( 3 );
is $grid, 'HL93bq', q{Random location 323 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HL93bq' ) );
cmp_ok $lat, '==', 23.6875, q{Random location 323 latitude};
cmp_ok $lon, '==', -21.875, q{Random location 323 longitude};

( $grid ) = $sta->geodetic( -0.509588259759954, 0.645243005278748, 0 )
    ->maidenhead( 3 );
is $grid, 'KG80lt', q{Random location 324 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KG80lt' ) );
cmp_ok $lat, '==', -29.1875, q{Random location 324 latitude};
cmp_ok $lon, '==', 36.9583, q{Random location 324 longitude};

( $grid ) = $sta->geodetic( -1.40297007268093, -1.22605274563383, 0 )
    ->maidenhead( 3 );
is $grid, 'FA49vo', q{Random location 325 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FA49vo' ) );
cmp_ok $lat, '==', -80.3958, q{Random location 325 latitude};
cmp_ok $lon, '==', -70.2083, q{Random location 325 longitude};

( $grid ) = $sta->geodetic( 0.893015681564605, -1.18363408331641, 0 )
    ->maidenhead( 3 );
is $grid, 'FO61cd', q{Random location 326 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FO61cd' ) );
cmp_ok $lat, '==', 51.1458, q{Random location 326 latitude};
cmp_ok $lon, '==', -67.7917, q{Random location 326 longitude};

( $grid ) = $sta->geodetic( 0.710061525787951, -1.61910807933179, 0 )
    ->maidenhead( 3 );
is $grid, 'EN30oq', q{Random location 327 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EN30oq' ) );
cmp_ok $lat, '==', 40.6875, q{Random location 327 latitude};
cmp_ok $lon, '==', -92.7917, q{Random location 327 longitude};

( $grid ) = $sta->geodetic( -0.493596970498616, 2.34993585561291, 0 )
    ->maidenhead( 3 );
is $grid, 'PG71hr', q{Random location 328 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PG71hr' ) );
cmp_ok $lat, '==', -28.2708, q{Random location 328 latitude};
cmp_ok $lon, '==', 134.625, q{Random location 328 longitude};

( $grid ) = $sta->geodetic( 0.183105765067406, -2.69571720978768, 0 )
    ->maidenhead( 3 );
is $grid, 'BK20sl', q{Random location 329 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK20sl' ) );
cmp_ok $lat, '==', 10.4792, q{Random location 329 latitude};
cmp_ok $lon, '==', -154.458, q{Random location 329 longitude};

( $grid ) = $sta->geodetic( 0.817712971410185, 2.99398517881175, 0 )
    ->maidenhead( 3 );
is $grid, 'RN56su', q{Random location 330 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RN56su' ) );
cmp_ok $lat, '==', 46.8542, q{Random location 330 latitude};
cmp_ok $lon, '==', 171.542, q{Random location 330 longitude};

( $grid ) = $sta->geodetic( 0.451982238661863, 0.924269323361801, 0 )
    ->maidenhead( 3 );
is $grid, 'LL65lv', q{Random location 331 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL65lv' ) );
cmp_ok $lat, '==', 25.8958, q{Random location 331 latitude};
cmp_ok $lon, '==', 52.9583, q{Random location 331 longitude};

( $grid ) = $sta->geodetic( 0.385540764167522, 3.08473968826215, 0 )
    ->maidenhead( 3 );
is $grid, 'RL82ic', q{Random location 332 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL82ic' ) );
cmp_ok $lat, '==', 22.1042, q{Random location 332 latitude};
cmp_ok $lon, '==', 176.708, q{Random location 332 longitude};

( $grid ) = $sta->geodetic( 0.372592430389324, -2.15042208234668, 0 )
    ->maidenhead( 3 );
is $grid, 'CL81ji', q{Random location 333 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CL81ji' ) );
cmp_ok $lat, '==', 21.3542, q{Random location 333 latitude};
cmp_ok $lon, '==', -123.208, q{Random location 333 longitude};

( $grid ) = $sta->geodetic( 1.07596443904571, -2.7448022041661, 0 )
    ->maidenhead( 3 );
is $grid, 'BP11ip', q{Random location 334 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BP11ip' ) );
cmp_ok $lat, '==', 61.6458, q{Random location 334 latitude};
cmp_ok $lon, '==', -157.292, q{Random location 334 longitude};

( $grid ) = $sta->geodetic( -0.873505679896495, 2.74258534253844, 0 )
    ->maidenhead( 3 );
is $grid, 'QD89nw', q{Random location 335 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QD89nw' ) );
cmp_ok $lat, '==', -50.0625, q{Random location 335 latitude};
cmp_ok $lon, '==', 157.125, q{Random location 335 longitude};

( $grid ) = $sta->geodetic( -0.196863745872987, -2.53062597806865, 0 )
    ->maidenhead( 3 );
is $grid, 'BH78mr', q{Random location 336 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BH78mr' ) );
cmp_ok $lat, '==', -11.2708, q{Random location 336 latitude};
cmp_ok $lon, '==', -144.958, q{Random location 336 longitude};

( $grid ) = $sta->geodetic( -0.364295133527045, 0.713924922462041, 0 )
    ->maidenhead( 3 );
is $grid, 'LG09kd', q{Random location 337 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LG09kd' ) );
cmp_ok $lat, '==', -20.8542, q{Random location 337 latitude};
cmp_ok $lon, '==', 40.875, q{Random location 337 longitude};

( $grid ) = $sta->geodetic( -0.0911082654507991, -1.53650554307714, 0 )
    ->maidenhead( 3 );
is $grid, 'EI54xs', q{Random location 338 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EI54xs' ) );
cmp_ok $lat, '==', -5.22917, q{Random location 338 latitude};
cmp_ok $lon, '==', -88.0417, q{Random location 338 longitude};

( $grid ) = $sta->geodetic( -0.975670495739232, -0.990107021659595, 0 )
    ->maidenhead( 3 );
is $grid, 'GD14pc', q{Random location 339 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GD14pc' ) );
cmp_ok $lat, '==', -55.8958, q{Random location 339 latitude};
cmp_ok $lon, '==', -56.7083, q{Random location 339 longitude};

( $grid ) = $sta->geodetic( 0.233235298388826, 0.440638116230283, 0 )
    ->maidenhead( 3 );
is $grid, 'KK23oi', q{Random location 340 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK23oi' ) );
cmp_ok $lat, '==', 13.3542, q{Random location 340 latitude};
cmp_ok $lon, '==', 25.2083, q{Random location 340 longitude};

( $grid ) = $sta->geodetic( -1.00004357899452, 1.88119093340687, 0 )
    ->maidenhead( 3 );
is $grid, 'OD32vq', q{Random location 341 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OD32vq' ) );
cmp_ok $lat, '==', -57.3125, q{Random location 341 latitude};
cmp_ok $lon, '==', 107.792, q{Random location 341 longitude};

( $grid ) = $sta->geodetic( -0.374754963984369, 1.08331710043757, 0 )
    ->maidenhead( 3 );
is $grid, 'MG18am', q{Random location 342 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MG18am' ) );
cmp_ok $lat, '==', -21.4792, q{Random location 342 latitude};
cmp_ok $lon, '==', 62.0417, q{Random location 342 longitude};

( $grid ) = $sta->geodetic( 0.0898468368236425, 1.85838599402113, 0 )
    ->maidenhead( 3 );
is $grid, 'OJ35fd', q{Random location 343 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OJ35fd' ) );
cmp_ok $lat, '==', 5.14583, q{Random location 343 latitude};
cmp_ok $lon, '==', 106.458, q{Random location 343 longitude};

( $grid ) = $sta->geodetic( 0.876367549767116, -0.0600743922553293, 0 )
    ->maidenhead( 3 );
is $grid, 'IO80gf', q{Random location 344 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IO80gf' ) );
cmp_ok $lat, '==', 50.2292, q{Random location 344 latitude};
cmp_ok $lon, '==', -3.45833, q{Random location 344 longitude};

( $grid ) = $sta->geodetic( -0.649521029602448, -2.61763522344453, 0 )
    ->maidenhead( 3 );
is $grid, 'BF52as', q{Random location 345 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BF52as' ) );
cmp_ok $lat, '==', -37.2292, q{Random location 345 latitude};
cmp_ok $lon, '==', -149.958, q{Random location 345 longitude};

( $grid ) = $sta->geodetic( 0.517832821056958, 2.86948255702995, 0 )
    ->maidenhead( 3 );
is $grid, 'RL29eq', q{Random location 346 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL29eq' ) );
cmp_ok $lat, '==', 29.6875, q{Random location 346 latitude};
cmp_ok $lon, '==', 164.375, q{Random location 346 longitude};

( $grid ) = $sta->geodetic( 0.156184249175846, -1.69889913835592, 0 )
    ->maidenhead( 3 );
is $grid, 'EJ18hw', q{Random location 347 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EJ18hw' ) );
cmp_ok $lat, '==', 8.9375, q{Random location 347 latitude};
cmp_ok $lon, '==', -97.375, q{Random location 347 longitude};

( $grid ) = $sta->geodetic( 1.1717054240861, -1.05911122662934, 0 )
    ->maidenhead( 3 );
is $grid, 'FP97pd', q{Random location 348 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FP97pd' ) );
cmp_ok $lat, '==', 67.1458, q{Random location 348 latitude};
cmp_ok $lon, '==', -60.7083, q{Random location 348 longitude};

( $grid ) = $sta->geodetic( 0.50457017994153, 2.98718614507001, 0 )
    ->maidenhead( 3 );
is $grid, 'RL58nv', q{Random location 349 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL58nv' ) );
cmp_ok $lat, '==', 28.8958, q{Random location 349 latitude};
cmp_ok $lon, '==', 171.125, q{Random location 349 longitude};

( $grid ) = $sta->geodetic( 0.983376286424975, -2.35144622554998, 0 )
    ->maidenhead( 3 );
is $grid, 'CO26pi', q{Random location 350 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CO26pi' ) );
cmp_ok $lat, '==', 56.3542, q{Random location 350 latitude};
cmp_ok $lon, '==', -134.708, q{Random location 350 longitude};

( $grid ) = $sta->geodetic( 0.320947069308156, -3.13996415284218, 0 )
    ->maidenhead( 3 );
is $grid, 'AK08bj', q{Random location 351 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AK08bj' ) );
cmp_ok $lat, '==', 18.3958, q{Random location 351 latitude};
cmp_ok $lon, '==', -179.875, q{Random location 351 longitude};

( $grid ) = $sta->geodetic( 0.546791163860161, 2.30111414180506, 0 )
    ->maidenhead( 3 );
is $grid, 'PM51wh', q{Random location 352 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM51wh' ) );
cmp_ok $lat, '==', 31.3125, q{Random location 352 latitude};
cmp_ok $lon, '==', 131.875, q{Random location 352 longitude};

( $grid ) = $sta->geodetic( 0.515477629917244, -0.126462158306679, 0 )
    ->maidenhead( 3 );
is $grid, 'IL69jm', q{Random location 353 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL69jm' ) );
cmp_ok $lat, '==', 29.5208, q{Random location 353 latitude};
cmp_ok $lon, '==', -7.20833, q{Random location 353 longitude};

( $grid ) = $sta->geodetic( 0.0606194650323628, -2.85936949037825, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ83cl', q{Random location 354 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ83cl' ) );
cmp_ok $lat, '==', 3.47917, q{Random location 354 latitude};
cmp_ok $lon, '==', -163.792, q{Random location 354 longitude};

( $grid ) = $sta->geodetic( -0.392992197430375, 1.52049815451261, 0 )
    ->maidenhead( 3 );
is $grid, 'NG37nl', q{Random location 355 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NG37nl' ) );
cmp_ok $lat, '==', -22.5208, q{Random location 355 latitude};
cmp_ok $lon, '==', 87.125, q{Random location 355 longitude};

( $grid ) = $sta->geodetic( -0.289855961680713, 0.915483954357571, 0 )
    ->maidenhead( 3 );
is $grid, 'LH63fj', q{Random location 356 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH63fj' ) );
cmp_ok $lat, '==', -16.6042, q{Random location 356 latitude};
cmp_ok $lon, '==', 52.4583, q{Random location 356 longitude};

( $grid ) = $sta->geodetic( -0.11322552013804, 2.9173240213725, 0 )
    ->maidenhead( 3 );
is $grid, 'RI33nm', q{Random location 357 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RI33nm' ) );
cmp_ok $lat, '==', -6.47917, q{Random location 357 latitude};
cmp_ok $lon, '==', 167.125, q{Random location 357 longitude};

( $grid ) = $sta->geodetic( 0.225321401026322, -2.35697848042453, 0 )
    ->maidenhead( 3 );
is $grid, 'CK22lv', q{Random location 358 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK22lv' ) );
cmp_ok $lat, '==', 12.8958, q{Random location 358 latitude};
cmp_ok $lon, '==', -135.042, q{Random location 358 longitude};

( $grid ) = $sta->geodetic( -0.573201244201762, 0.0207951460785361, 0 )
    ->maidenhead( 3 );
is $grid, 'JF07od', q{Random location 359 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JF07od' ) );
cmp_ok $lat, '==', -32.8542, q{Random location 359 latitude};
cmp_ok $lon, '==', 1.20833, q{Random location 359 longitude};

( $grid ) = $sta->geodetic( -0.159276100852375, 1.77713046762788, 0 )
    ->maidenhead( 3 );
is $grid, 'OI00vu', q{Random location 360 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI00vu' ) );
cmp_ok $lat, '==', -9.14583, q{Random location 360 latitude};
cmp_ok $lon, '==', 101.792, q{Random location 360 longitude};

( $grid ) = $sta->geodetic( -0.391293180786302, 0.869264459346913, 0 )
    ->maidenhead( 3 );
is $grid, 'LG47vn', q{Random location 361 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LG47vn' ) );
cmp_ok $lat, '==', -22.4375, q{Random location 361 latitude};
cmp_ok $lon, '==', 49.7917, q{Random location 361 longitude};

( $grid ) = $sta->geodetic( -0.544214303219015, -2.38298609620594, 0 )
    ->maidenhead( 3 );
is $grid, 'CF18rt', q{Random location 362 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF18rt' ) );
cmp_ok $lat, '==', -31.1875, q{Random location 362 latitude};
cmp_ok $lon, '==', -136.542, q{Random location 362 longitude};

( $grid ) = $sta->geodetic( -0.0191725641343325, -1.09265077634608, 0 )
    ->maidenhead( 3 );
is $grid, 'FI88qv', q{Random location 363 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FI88qv' ) );
cmp_ok $lat, '==', -1.10417, q{Random location 363 latitude};
cmp_ok $lon, '==', -62.625, q{Random location 363 longitude};

( $grid ) = $sta->geodetic( 0.685839330968477, -1.91997524949346, 0 )
    ->maidenhead( 3 );
is $grid, 'DM49xh', q{Random location 364 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DM49xh' ) );
cmp_ok $lat, '==', 39.3125, q{Random location 364 latitude};
cmp_ok $lon, '==', -110.042, q{Random location 364 longitude};

( $grid ) = $sta->geodetic( 1.07042363255816, 1.9873132981304, 0 )
    ->maidenhead( 3 );
is $grid, 'OP61wh', q{Random location 365 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OP61wh' ) );
cmp_ok $lat, '==', 61.3125, q{Random location 365 latitude};
cmp_ok $lon, '==', 113.875, q{Random location 365 longitude};

( $grid ) = $sta->geodetic( 1.00818037425368, 1.35190324952412, 0 )
    ->maidenhead( 3 );
is $grid, 'MO87rs', q{Random location 366 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MO87rs' ) );
cmp_ok $lat, '==', 57.7708, q{Random location 366 latitude};
cmp_ok $lon, '==', 77.4583, q{Random location 366 longitude};

( $grid ) = $sta->geodetic( -0.911842142834822, 0.150423742101663, 0 )
    ->maidenhead( 3 );
is $grid, 'JD47hs', q{Random location 367 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JD47hs' ) );
cmp_ok $lat, '==', -52.2292, q{Random location 367 latitude};
cmp_ok $lon, '==', 8.625, q{Random location 367 longitude};

( $grid ) = $sta->geodetic( -0.429974351045505, 2.49602956667845, 0 )
    ->maidenhead( 3 );
is $grid, 'QG15mi', q{Random location 368 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG15mi' ) );
cmp_ok $lat, '==', -24.6458, q{Random location 368 latitude};
cmp_ok $lon, '==', 143.042, q{Random location 368 longitude};

( $grid ) = $sta->geodetic( 0.205823282898647, -0.0158492112955892, 0 )
    ->maidenhead( 3 );
is $grid, 'IK91nt', q{Random location 369 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IK91nt' ) );
cmp_ok $lat, '==', 11.8125, q{Random location 369 latitude};
cmp_ok $lon, '==', -0.875, q{Random location 369 longitude};

( $grid ) = $sta->geodetic( -0.106736034670849, 2.54600948350197, 0 )
    ->maidenhead( 3 );
is $grid, 'QI23wv', q{Random location 370 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI23wv' ) );
cmp_ok $lat, '==', -6.10417, q{Random location 370 latitude};
cmp_ok $lon, '==', 145.875, q{Random location 370 longitude};

( $grid ) = $sta->geodetic( -1.22959845104259, 1.83194430279266, 0 )
    ->maidenhead( 3 );
is $grid, 'OB29ln', q{Random location 371 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OB29ln' ) );
cmp_ok $lat, '==', -70.4375, q{Random location 371 latitude};
cmp_ok $lon, '==', 104.958, q{Random location 371 longitude};

( $grid ) = $sta->geodetic( -0.736571594639508, -0.417255853809932, 0 )
    ->maidenhead( 3 );
is $grid, 'HE87bt', q{Random location 372 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HE87bt' ) );
cmp_ok $lat, '==', -42.1875, q{Random location 372 latitude};
cmp_ok $lon, '==', -23.875, q{Random location 372 longitude};

( $grid ) = $sta->geodetic( 0.628234821300016, -0.377051282038631, 0 )
    ->maidenhead( 3 );
is $grid, 'HM95ex', q{Random location 373 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM95ex' ) );
cmp_ok $lat, '==', 35.9792, q{Random location 373 latitude};
cmp_ok $lon, '==', -21.625, q{Random location 373 longitude};

( $grid ) = $sta->geodetic( 0.382748722919335, -2.63527852729784, 0 )
    ->maidenhead( 3 );
is $grid, 'BL41mw', q{Random location 374 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL41mw' ) );
cmp_ok $lat, '==', 21.9375, q{Random location 374 latitude};
cmp_ok $lon, '==', -150.958, q{Random location 374 longitude};

( $grid ) = $sta->geodetic( 0.104630656486266, 2.73222583297079, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ85gx', q{Random location 375 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ85gx' ) );
cmp_ok $lat, '==', 5.97917, q{Random location 375 latitude};
cmp_ok $lon, '==', 156.542, q{Random location 375 longitude};

( $grid ) = $sta->geodetic( 0.68074961873112, -3.08226472224622, 0 )
    ->maidenhead( 3 );
is $grid, 'AM19qa', q{Random location 376 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AM19qa' ) );
cmp_ok $lat, '==', 39.0208, q{Random location 376 latitude};
cmp_ok $lon, '==', -176.625, q{Random location 376 longitude};

( $grid ) = $sta->geodetic( -0.867424188052907, 2.04883061264115, 0 )
    ->maidenhead( 3 );
is $grid, 'OE80qh', q{Random location 377 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OE80qh' ) );
cmp_ok $lat, '==', -49.6875, q{Random location 377 latitude};
cmp_ok $lon, '==', 117.375, q{Random location 377 longitude};

( $grid ) = $sta->geodetic( 0.388484618492048, -2.63620300763741, 0 )
    ->maidenhead( 3 );
is $grid, 'BL42lg', q{Random location 378 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL42lg' ) );
cmp_ok $lat, '==', 22.2708, q{Random location 378 latitude};
cmp_ok $lon, '==', -151.042, q{Random location 378 longitude};

( $grid ) = $sta->geodetic( 1.21237818746595, -0.319369340623973, 0 )
    ->maidenhead( 3 );
is $grid, 'IP09ul', q{Random location 379 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IP09ul' ) );
cmp_ok $lat, '==', 69.4792, q{Random location 379 latitude};
cmp_ok $lon, '==', -18.2917, q{Random location 379 longitude};

( $grid ) = $sta->geodetic( -0.0607373759579322, -0.193647852970226, 0 )
    ->maidenhead( 3 );
is $grid, 'II46km', q{Random location 380 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'II46km' ) );
cmp_ok $lat, '==', -3.47917, q{Random location 380 latitude};
cmp_ok $lon, '==', -11.125, q{Random location 380 longitude};

( $grid ) = $sta->geodetic( 0.00690199255472179, 2.02230312098625, 0 )
    ->maidenhead( 3 );
is $grid, 'OJ70wj', q{Random location 381 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OJ70wj' ) );
cmp_ok $lat, '==', 0.395833, q{Random location 381 latitude};
cmp_ok $lon, '==', 115.875, q{Random location 381 longitude};

( $grid ) = $sta->geodetic( 0.310397973545317, -0.335876478578286, 0 )
    ->maidenhead( 3 );
is $grid, 'IK07js', q{Random location 382 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IK07js' ) );
cmp_ok $lat, '==', 17.7708, q{Random location 382 latitude};
cmp_ok $lon, '==', -19.2083, q{Random location 382 longitude};

( $grid ) = $sta->geodetic( -0.0126143856880021, -0.668307970542623, 0 )
    ->maidenhead( 3 );
is $grid, 'HI09ug', q{Random location 383 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HI09ug' ) );
cmp_ok $lat, '==', -0.729167, q{Random location 383 latitude};
cmp_ok $lon, '==', -38.2917, q{Random location 383 longitude};

( $grid ) = $sta->geodetic( -0.354154959840502, 1.89362029132054, 0 )
    ->maidenhead( 3 );
is $grid, 'OG49fr', q{Random location 384 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OG49fr' ) );
cmp_ok $lat, '==', -20.2708, q{Random location 384 latitude};
cmp_ok $lon, '==', 108.458, q{Random location 384 longitude};

( $grid ) = $sta->geodetic( 1.10052413602495, 2.00500632222105, 0 )
    ->maidenhead( 3 );
is $grid, 'OP73kb', q{Random location 385 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OP73kb' ) );
cmp_ok $lat, '==', 63.0625, q{Random location 385 latitude};
cmp_ok $lon, '==', 114.875, q{Random location 385 longitude};

( $grid ) = $sta->geodetic( 1.46657710840197, 0.330143119774361, 0 )
    ->maidenhead( 3 );
is $grid, 'JR94ka', q{Random location 386 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JR94ka' ) );
cmp_ok $lat, '==', 84.0208, q{Random location 386 latitude};
cmp_ok $lon, '==', 18.875, q{Random location 386 longitude};

( $grid ) = $sta->geodetic( 0.100466774833244, -3.08066492231675, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ15rs', q{Random location 387 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ15rs' ) );
cmp_ok $lat, '==', 5.77083, q{Random location 387 latitude};
cmp_ok $lon, '==', -176.542, q{Random location 387 longitude};

( $grid ) = $sta->geodetic( -0.079573968287963, -0.168019674899098, 0 )
    ->maidenhead( 3 );
is $grid, 'II55ek', q{Random location 388 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'II55ek' ) );
cmp_ok $lat, '==', -4.5625, q{Random location 388 latitude};
cmp_ok $lon, '==', -9.625, q{Random location 388 longitude};

( $grid ) = $sta->geodetic( 0.740689175113896, 2.59934793048484, 0 )
    ->maidenhead( 3 );
is $grid, 'QN42lk', q{Random location 389 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QN42lk' ) );
cmp_ok $lat, '==', 42.4375, q{Random location 389 latitude};
cmp_ok $lon, '==', 148.958, q{Random location 389 longitude};

( $grid ) = $sta->geodetic( 0.345640753286683, -1.3688835782586, 0 )
    ->maidenhead( 3 );
is $grid, 'FK09st', q{Random location 390 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FK09st' ) );
cmp_ok $lat, '==', 19.8125, q{Random location 390 latitude};
cmp_ok $lon, '==', -78.4583, q{Random location 390 longitude};

( $grid ) = $sta->geodetic( 0.560025913515584, -1.16277748474514, 0 )
    ->maidenhead( 3 );
is $grid, 'FM62qc', q{Random location 391 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FM62qc' ) );
cmp_ok $lat, '==', 32.1042, q{Random location 391 latitude};
cmp_ok $lon, '==', -66.625, q{Random location 391 longitude};

( $grid ) = $sta->geodetic( -0.678569389053125, 0.156554065900193, 0 )
    ->maidenhead( 3 );
is $grid, 'JF41lc', q{Random location 392 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JF41lc' ) );
cmp_ok $lat, '==', -38.8958, q{Random location 392 latitude};
cmp_ok $lon, '==', 8.95833, q{Random location 392 longitude};

( $grid ) = $sta->geodetic( -0.373270905405118, -1.74071502675061, 0 )
    ->maidenhead( 3 );
is $grid, 'EG08do', q{Random location 393 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EG08do' ) );
cmp_ok $lat, '==', -21.3958, q{Random location 393 latitude};
cmp_ok $lon, '==', -99.7083, q{Random location 393 longitude};

( $grid ) = $sta->geodetic( -0.923734760693711, -0.29194072285717, 0 )
    ->maidenhead( 3 );
is $grid, 'ID17pb', q{Random location 394 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID17pb' ) );
cmp_ok $lat, '==', -52.9375, q{Random location 394 latitude};
cmp_ok $lon, '==', -16.7083, q{Random location 394 longitude};

( $grid ) = $sta->geodetic( -0.211947974961832, -0.212323313880858, 0 )
    ->maidenhead( 3 );
is $grid, 'IH37wu', q{Random location 395 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH37wu' ) );
cmp_ok $lat, '==', -12.1458, q{Random location 395 latitude};
cmp_ok $lon, '==', -12.125, q{Random location 395 longitude};

( $grid ) = $sta->geodetic( 0.284533979510313, -3.01863033656631, 0 )
    ->maidenhead( 3 );
is $grid, 'AK36mh', q{Random location 396 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AK36mh' ) );
cmp_ok $lat, '==', 16.3125, q{Random location 396 latitude};
cmp_ok $lon, '==', -172.958, q{Random location 396 longitude};

( $grid ) = $sta->geodetic( -0.86349553977225, 2.97413731914189, 0 )
    ->maidenhead( 3 );
is $grid, 'RE50em', q{Random location 397 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RE50em' ) );
cmp_ok $lat, '==', -49.4792, q{Random location 397 latitude};
cmp_ok $lon, '==', 170.375, q{Random location 397 longitude};

( $grid ) = $sta->geodetic( 0.861494260539076, -1.61380803771651, 0 )
    ->maidenhead( 3 );
is $grid, 'EN39si', q{Random location 398 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EN39si' ) );
cmp_ok $lat, '==', 49.3542, q{Random location 398 latitude};
cmp_ok $lon, '==', -92.4583, q{Random location 398 longitude};

( $grid ) = $sta->geodetic( -0.436758810958976, -2.9463862014785, 0 )
    ->maidenhead( 3 );
is $grid, 'AG54ox', q{Random location 399 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AG54ox' ) );
cmp_ok $lat, '==', -25.0208, q{Random location 399 latitude};
cmp_ok $lon, '==', -168.792, q{Random location 399 longitude};

( $grid ) = $sta->geodetic( -0.505392418268016, -2.24732985037638, 0 )
    ->maidenhead( 3 );
is $grid, 'CG51ob', q{Random location 400 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG51ob' ) );
cmp_ok $lat, '==', -28.9375, q{Random location 400 latitude};
cmp_ok $lon, '==', -128.792, q{Random location 400 longitude};

( $grid ) = $sta->geodetic( 1.30382782047941, 2.51537794903717, 0 )
    ->maidenhead( 3 );
is $grid, 'QQ24bq', q{Random location 401 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QQ24bq' ) );
cmp_ok $lat, '==', 74.6875, q{Random location 401 latitude};
cmp_ok $lon, '==', 144.125, q{Random location 401 longitude};

( $grid ) = $sta->geodetic( -0.776348599225311, -0.324530923786639, 0 )
    ->maidenhead( 3 );
is $grid, 'IE05qm', q{Random location 402 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE05qm' ) );
cmp_ok $lat, '==', -44.4792, q{Random location 402 latitude};
cmp_ok $lon, '==', -18.625, q{Random location 402 longitude};

( $grid ) = $sta->geodetic( -1.04212936519896, -0.424245915704647, 0 )
    ->maidenhead( 3 );
is $grid, 'HD70ug', q{Random location 403 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HD70ug' ) );
cmp_ok $lat, '==', -59.7292, q{Random location 403 latitude};
cmp_ok $lon, '==', -24.2917, q{Random location 403 longitude};

( $grid ) = $sta->geodetic( 0.20535712149682, 2.93750397402116, 0 )
    ->maidenhead( 3 );
is $grid, 'RK41ds', q{Random location 404 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RK41ds' ) );
cmp_ok $lat, '==', 11.7708, q{Random location 404 latitude};
cmp_ok $lon, '==', 168.292, q{Random location 404 longitude};

( $grid ) = $sta->geodetic( 0.891682025802576, -0.667774396816154, 0 )
    ->maidenhead( 3 );
is $grid, 'HO01uc', q{Random location 405 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HO01uc' ) );
cmp_ok $lat, '==', 51.1042, q{Random location 405 latitude};
cmp_ok $lon, '==', -38.2917, q{Random location 405 longitude};

( $grid ) = $sta->geodetic( -0.955806767002433, 0.297313488189323, 0 )
    ->maidenhead( 3 );
is $grid, 'JD85mf', q{Random location 406 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JD85mf' ) );
cmp_ok $lat, '==', -54.7708, q{Random location 406 latitude};
cmp_ok $lon, '==', 17.0417, q{Random location 406 longitude};

( $grid ) = $sta->geodetic( 0.604790157484794, 1.50082955304873, 0 )
    ->maidenhead( 3 );
is $grid, 'NM24xp', q{Random location 407 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM24xp' ) );
cmp_ok $lat, '==', 34.6458, q{Random location 407 latitude};
cmp_ok $lon, '==', 85.9583, q{Random location 407 longitude};

( $grid ) = $sta->geodetic( 0.21511586099815, 1.08985575019939, 0 )
    ->maidenhead( 3 );
is $grid, 'MK12fh', q{Random location 408 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK12fh' ) );
cmp_ok $lat, '==', 12.3125, q{Random location 408 latitude};
cmp_ok $lon, '==', 62.4583, q{Random location 408 longitude};

( $grid ) = $sta->geodetic( -0.635117813079142, 3.10865847597285, 0 )
    ->maidenhead( 3 );
is $grid, 'RF93bo', q{Random location 409 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RF93bo' ) );
cmp_ok $lat, '==', -36.3958, q{Random location 409 latitude};
cmp_ok $lon, '==', 178.125, q{Random location 409 longitude};

( $grid ) = $sta->geodetic( -0.0636547955357079, -2.11385664400757, 0 )
    ->maidenhead( 3 );
is $grid, 'CI96ki', q{Random location 410 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI96ki' ) );
cmp_ok $lat, '==', -3.64583, q{Random location 410 latitude};
cmp_ok $lon, '==', -121.125, q{Random location 410 longitude};

( $grid ) = $sta->geodetic( -1.13584763544624, 1.00648705229808, 0 )
    ->maidenhead( 3 );
is $grid, 'LC84uw', q{Random location 411 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LC84uw' ) );
cmp_ok $lat, '==', -65.0625, q{Random location 411 latitude};
cmp_ok $lon, '==', 57.7083, q{Random location 411 longitude};

( $grid ) = $sta->geodetic( 0.535094195965948, 1.7182401180279, 0 )
    ->maidenhead( 3 );
is $grid, 'NM90fp', q{Random location 412 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM90fp' ) );
cmp_ok $lat, '==', 30.6458, q{Random location 412 latitude};
cmp_ok $lon, '==', 98.4583, q{Random location 412 longitude};

( $grid ) = $sta->geodetic( -0.816266779810745, -1.22313950354739, 0 )
    ->maidenhead( 3 );
is $grid, 'FE43xf', q{Random location 413 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FE43xf' ) );
cmp_ok $lat, '==', -46.7708, q{Random location 413 latitude};
cmp_ok $lon, '==', -70.0417, q{Random location 413 longitude};

( $grid ) = $sta->geodetic( -0.527889729641595, 1.40164741009593, 0 )
    ->maidenhead( 3 );
is $grid, 'NF09ds', q{Random location 414 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NF09ds' ) );
cmp_ok $lat, '==', -30.2292, q{Random location 414 latitude};
cmp_ok $lon, '==', 80.2917, q{Random location 414 longitude};

( $grid ) = $sta->geodetic( -0.144720183436432, -2.63648399181827, 0 )
    ->maidenhead( 3 );
is $grid, 'BI41lq', q{Random location 415 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI41lq' ) );
cmp_ok $lat, '==', -8.3125, q{Random location 415 latitude};
cmp_ok $lon, '==', -151.042, q{Random location 415 longitude};

( $grid ) = $sta->geodetic( -1.3824985246163, 1.59210154641598, 0 )
    ->maidenhead( 3 );
is $grid, 'NB50os', q{Random location 416 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NB50os' ) );
cmp_ok $lat, '==', -79.2292, q{Random location 416 latitude};
cmp_ok $lon, '==', 91.2083, q{Random location 416 longitude};

( $grid ) = $sta->geodetic( 1.24596022575534, -2.48249975521807, 0 )
    ->maidenhead( 3 );
is $grid, 'BQ81vj', q{Random location 417 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BQ81vj' ) );
cmp_ok $lat, '==', 71.3958, q{Random location 417 latitude};
cmp_ok $lon, '==', -142.208, q{Random location 417 longitude};

( $grid ) = $sta->geodetic( 0.307071102862653, 1.91129575461534, 0 )
    ->maidenhead( 3 );
is $grid, 'OK47so', q{Random location 418 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OK47so' ) );
cmp_ok $lat, '==', 17.6042, q{Random location 418 latitude};
cmp_ok $lon, '==', 109.542, q{Random location 418 longitude};

( $grid ) = $sta->geodetic( 0.744919405869722, 1.3039273862051, 0 )
    ->maidenhead( 3 );
is $grid, 'MN72iq', q{Random location 419 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MN72iq' ) );
cmp_ok $lat, '==', 42.6875, q{Random location 419 latitude};
cmp_ok $lon, '==', 74.7083, q{Random location 419 longitude};

( $grid ) = $sta->geodetic( -0.0840647615897951, -0.890675743486456, 0 )
    ->maidenhead( 3 );
is $grid, 'GI45le', q{Random location 420 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GI45le' ) );
cmp_ok $lat, '==', -4.8125, q{Random location 420 latitude};
cmp_ok $lon, '==', -51.0417, q{Random location 420 longitude};

( $grid ) = $sta->geodetic( -1.02776640184552, -0.0786002675137789, 0 )
    ->maidenhead( 3 );
is $grid, 'ID71rc', q{Random location 421 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID71rc' ) );
cmp_ok $lat, '==', -58.8958, q{Random location 421 latitude};
cmp_ok $lon, '==', -4.54167, q{Random location 421 longitude};

( $grid ) = $sta->geodetic( 0.313797171408896, 2.66049505865661, 0 )
    ->maidenhead( 3 );
is $grid, 'QK67fx', q{Random location 422 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QK67fx' ) );
cmp_ok $lat, '==', 17.9792, q{Random location 422 latitude};
cmp_ok $lon, '==', 152.458, q{Random location 422 longitude};

( $grid ) = $sta->geodetic( 0.139947171162888, -0.281883732223098, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ18wa', q{Random location 423 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ18wa' ) );
cmp_ok $lat, '==', 8.02083, q{Random location 423 latitude};
cmp_ok $lon, '==', -16.125, q{Random location 423 longitude};

( $grid ) = $sta->geodetic( 0.273684882299517, 0.97097829647699, 0 )
    ->maidenhead( 3 );
is $grid, 'LK75tq', q{Random location 424 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LK75tq' ) );
cmp_ok $lat, '==', 15.6875, q{Random location 424 latitude};
cmp_ok $lon, '==', 55.625, q{Random location 424 longitude};

( $grid ) = $sta->geodetic( 0.55599429251866, -2.33168372695621, 0 )
    ->maidenhead( 3 );
is $grid, 'CM31eu', q{Random location 425 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CM31eu' ) );
cmp_ok $lat, '==', 31.8542, q{Random location 425 latitude};
cmp_ok $lon, '==', -133.625, q{Random location 425 longitude};

( $grid ) = $sta->geodetic( -1.20274146429414, -1.41471637325401, 0 )
    ->maidenhead( 3 );
is $grid, 'EC91lc', q{Random location 426 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EC91lc' ) );
cmp_ok $lat, '==', -68.8958, q{Random location 426 latitude};
cmp_ok $lon, '==', -81.0417, q{Random location 426 longitude};

( $grid ) = $sta->geodetic( 0.598298452691623, 3.0279383317385, 0 )
    ->maidenhead( 3 );
is $grid, 'RM64rg', q{Random location 427 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM64rg' ) );
cmp_ok $lat, '==', 34.2708, q{Random location 427 latitude};
cmp_ok $lon, '==', 173.458, q{Random location 427 longitude};

( $grid ) = $sta->geodetic( -0.454594511240992, 2.57471432780012, 0 )
    ->maidenhead( 3 );
is $grid, 'QG33sw', q{Random location 428 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG33sw' ) );
cmp_ok $lat, '==', -26.0625, q{Random location 428 latitude};
cmp_ok $lon, '==', 147.542, q{Random location 428 longitude};

( $grid ) = $sta->geodetic( -0.8409994179523, -0.796098966937082, 0 )
    ->maidenhead( 3 );
is $grid, 'GE71et', q{Random location 429 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GE71et' ) );
cmp_ok $lat, '==', -48.1875, q{Random location 429 latitude};
cmp_ok $lon, '==', -45.625, q{Random location 429 longitude};

( $grid ) = $sta->geodetic( -0.222918610474373, -1.59506438679535, 0 )
    ->maidenhead( 3 );
is $grid, 'EH47hf', q{Random location 430 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EH47hf' ) );
cmp_ok $lat, '==', -12.7708, q{Random location 430 latitude};
cmp_ok $lon, '==', -91.375, q{Random location 430 longitude};

( $grid ) = $sta->geodetic( -0.168489063828354, -0.556772322421614, 0 )
    ->maidenhead( 3 );
is $grid, 'HI40bi', q{Random location 431 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HI40bi' ) );
cmp_ok $lat, '==', -9.64583, q{Random location 431 latitude};
cmp_ok $lon, '==', -31.875, q{Random location 431 longitude};

( $grid ) = $sta->geodetic( -1.35220076099868, -1.40103240396935, 0 )
    ->maidenhead( 3 );
is $grid, 'EB92um', q{Random location 432 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EB92um' ) );
cmp_ok $lat, '==', -77.4792, q{Random location 432 latitude};
cmp_ok $lon, '==', -80.2917, q{Random location 432 longitude};

( $grid ) = $sta->geodetic( 0.856914886082028, 1.18660777184431, 0 )
    ->maidenhead( 3 );
is $grid, 'MN39xc', q{Random location 433 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MN39xc' ) );
cmp_ok $lat, '==', 49.1042, q{Random location 433 latitude};
cmp_ok $lon, '==', 67.9583, q{Random location 433 longitude};

( $grid ) = $sta->geodetic( -0.340342761661417, -0.805229429184582, 0 )
    ->maidenhead( 3 );
is $grid, 'GH60wl', q{Random location 434 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH60wl' ) );
cmp_ok $lat, '==', -19.5208, q{Random location 434 latitude};
cmp_ok $lon, '==', -46.125, q{Random location 434 longitude};

( $grid ) = $sta->geodetic( 0.555352890114, 0.813176349603885, 0 )
    ->maidenhead( 3 );
is $grid, 'LM31ht', q{Random location 435 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM31ht' ) );
cmp_ok $lat, '==', 31.8125, q{Random location 435 latitude};
cmp_ok $lon, '==', 46.625, q{Random location 435 longitude};

( $grid ) = $sta->geodetic( 0.850123235460032, -1.5724036671273, 0 )
    ->maidenhead( 3 );
is $grid, 'EN48wr', q{Random location 436 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EN48wr' ) );
cmp_ok $lat, '==', 48.7292, q{Random location 436 latitude};
cmp_ok $lon, '==', -90.125, q{Random location 436 longitude};

( $grid ) = $sta->geodetic( 0.248425995579403, -1.98796257205419, 0 )
    ->maidenhead( 3 );
is $grid, 'DK34bf', q{Random location 437 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DK34bf' ) );
cmp_ok $lat, '==', 14.2292, q{Random location 437 latitude};
cmp_ok $lon, '==', -113.875, q{Random location 437 longitude};

( $grid ) = $sta->geodetic( -1.04986474459742, 1.58189615328923, 0 )
    ->maidenhead( 3 );
is $grid, 'NC59hu', q{Random location 438 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NC59hu' ) );
cmp_ok $lat, '==', -60.1458, q{Random location 438 latitude};
cmp_ok $lon, '==', 90.625, q{Random location 438 longitude};

( $grid ) = $sta->geodetic( -0.402877291973352, 1.34713173232471, 0 )
    ->maidenhead( 3 );
is $grid, 'MG86ow', q{Random location 439 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MG86ow' ) );
cmp_ok $lat, '==', -23.0625, q{Random location 439 latitude};
cmp_ok $lon, '==', 77.2083, q{Random location 439 longitude};

( $grid ) = $sta->geodetic( -0.88050689548493, 2.2702472235008, 0 )
    ->maidenhead( 3 );
is $grid, 'PD59an', q{Random location 440 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PD59an' ) );
cmp_ok $lat, '==', -50.4375, q{Random location 440 latitude};
cmp_ok $lon, '==', 130.042, q{Random location 440 longitude};

( $grid ) = $sta->geodetic( -0.535217048548488, -1.28464720760747, 0 )
    ->maidenhead( 3 );
is $grid, 'FF39ei', q{Random location 441 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF39ei' ) );
cmp_ok $lat, '==', -30.6458, q{Random location 441 latitude};
cmp_ok $lon, '==', -73.625, q{Random location 441 longitude};

( $grid ) = $sta->geodetic( -1.40328481399263, 2.27816433411961, 0 )
    ->maidenhead( 3 );
is $grid, 'PA59go', q{Random location 442 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PA59go' ) );
cmp_ok $lat, '==', -80.3958, q{Random location 442 latitude};
cmp_ok $lon, '==', 130.542, q{Random location 442 longitude};

( $grid ) = $sta->geodetic( 0.917477229918769, 3.10162610927378, 0 )
    ->maidenhead( 3 );
is $grid, 'RO82un', q{Random location 443 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RO82un' ) );
cmp_ok $lat, '==', 52.5625, q{Random location 443 latitude};
cmp_ok $lon, '==', 177.708, q{Random location 443 longitude};

( $grid ) = $sta->geodetic( 0.404158072603709, 0.899463644176991, 0 )
    ->maidenhead( 3 );
is $grid, 'LL53sd', q{Random location 444 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL53sd' ) );
cmp_ok $lat, '==', 23.1458, q{Random location 444 latitude};
cmp_ok $lon, '==', 51.5417, q{Random location 444 longitude};

( $grid ) = $sta->geodetic( -0.364970679276444, -0.156343128280625, 0 )
    ->maidenhead( 3 );
is $grid, 'IG59mc', q{Random location 445 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IG59mc' ) );
cmp_ok $lat, '==', -20.8958, q{Random location 445 latitude};
cmp_ok $lon, '==', -8.95833, q{Random location 445 longitude};

( $grid ) = $sta->geodetic( 0.796936894966503, -2.38165677806219, 0 )
    ->maidenhead( 3 );
is $grid, 'CN15sp', q{Random location 446 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CN15sp' ) );
cmp_ok $lat, '==', 45.6458, q{Random location 446 latitude};
cmp_ok $lon, '==', -136.458, q{Random location 446 longitude};

( $grid ) = $sta->geodetic( 1.15024681850777, 2.75884513863493, 0 )
    ->maidenhead( 3 );
is $grid, 'QP95av', q{Random location 447 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP95av' ) );
cmp_ok $lat, '==', 65.8958, q{Random location 447 latitude};
cmp_ok $lon, '==', 158.042, q{Random location 447 longitude};

( $grid ) = $sta->geodetic( -0.644749531053048, -0.458378306470325, 0 )
    ->maidenhead( 3 );
is $grid, 'HF63ub', q{Random location 448 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF63ub' ) );
cmp_ok $lat, '==', -36.9375, q{Random location 448 latitude};
cmp_ok $lon, '==', -26.2917, q{Random location 448 longitude};

( $grid ) = $sta->geodetic( -0.602296926669803, 1.02826645471074, 0 )
    ->maidenhead( 3 );
is $grid, 'LF95kl', q{Random location 449 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF95kl' ) );
cmp_ok $lat, '==', -34.5208, q{Random location 449 latitude};
cmp_ok $lon, '==', 58.875, q{Random location 449 longitude};

( $grid ) = $sta->geodetic( 0.231649020170927, 0.116279013673054, 0 )
    ->maidenhead( 3 );
is $grid, 'JK33hg', q{Random location 450 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK33hg' ) );
cmp_ok $lat, '==', 13.2708, q{Random location 450 latitude};
cmp_ok $lon, '==', 6.625, q{Random location 450 longitude};

( $grid ) = $sta->geodetic( 0.903444825102249, 0.732288562457875, 0 )
    ->maidenhead( 3 );
is $grid, 'LO01xs', q{Random location 451 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LO01xs' ) );
cmp_ok $lat, '==', 51.7708, q{Random location 451 latitude};
cmp_ok $lon, '==', 41.9583, q{Random location 451 longitude};

( $grid ) = $sta->geodetic( 0.0671322379890837, -2.01198740721095, 0 )
    ->maidenhead( 3 );
is $grid, 'DJ23iu', q{Random location 452 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DJ23iu' ) );
cmp_ok $lat, '==', 3.85417, q{Random location 452 latitude};
cmp_ok $lon, '==', -115.292, q{Random location 452 longitude};

( $grid ) = $sta->geodetic( 0.653965636478886, 0.865472044763159, 0 )
    ->maidenhead( 3 );
is $grid, 'LM47tl', q{Random location 453 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM47tl' ) );
cmp_ok $lat, '==', 37.4792, q{Random location 453 latitude};
cmp_ok $lon, '==', 49.625, q{Random location 453 longitude};

( $grid ) = $sta->geodetic( -0.0860661535209877, -2.24775986780378, 0 )
    ->maidenhead( 3 );
is $grid, 'CI55ob', q{Random location 454 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI55ob' ) );
cmp_ok $lat, '==', -4.9375, q{Random location 454 latitude};
cmp_ok $lon, '==', -128.792, q{Random location 454 longitude};

( $grid ) = $sta->geodetic( 0.794915913152673, 1.16087864934264, 0 )
    ->maidenhead( 3 );
is $grid, 'MN35gn', q{Random location 455 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MN35gn' ) );
cmp_ok $lat, '==', 45.5625, q{Random location 455 latitude};
cmp_ok $lon, '==', 66.5417, q{Random location 455 longitude};

( $grid ) = $sta->geodetic( 0.480386494266877, -1.9369117400136, 0 )
    ->maidenhead( 3 );
is $grid, 'DL47mm', q{Random location 456 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DL47mm' ) );
cmp_ok $lat, '==', 27.5208, q{Random location 456 latitude};
cmp_ok $lon, '==', -110.958, q{Random location 456 longitude};

( $grid ) = $sta->geodetic( 0.404805160515803, 2.12122250832632, 0 )
    ->maidenhead( 3 );
is $grid, 'PL03se', q{Random location 457 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL03se' ) );
cmp_ok $lat, '==', 23.1875, q{Random location 457 latitude};
cmp_ok $lon, '==', 121.542, q{Random location 457 longitude};

( $grid ) = $sta->geodetic( -0.565734818264431, -0.513665881980032, 0 )
    ->maidenhead( 3 );
is $grid, 'HF57go', q{Random location 458 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF57go' ) );
cmp_ok $lat, '==', -32.3958, q{Random location 458 latitude};
cmp_ok $lon, '==', -29.4583, q{Random location 458 longitude};

( $grid ) = $sta->geodetic( 0.312383979752098, -3.1156518959557, 0 )
    ->maidenhead( 3 );
is $grid, 'AK07rv', q{Random location 459 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AK07rv' ) );
cmp_ok $lat, '==', 17.8958, q{Random location 459 latitude};
cmp_ok $lon, '==', -178.542, q{Random location 459 longitude};

( $grid ) = $sta->geodetic( 0.211209202524081, -2.47347765349744, 0 )
    ->maidenhead( 3 );
is $grid, 'BK92dc', q{Random location 460 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK92dc' ) );
cmp_ok $lat, '==', 12.1042, q{Random location 460 latitude};
cmp_ok $lon, '==', -141.708, q{Random location 460 longitude};

( $grid ) = $sta->geodetic( -0.259955683252098, -2.34728152625841, 0 )
    ->maidenhead( 3 );
is $grid, 'CH25sc', q{Random location 461 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CH25sc' ) );
cmp_ok $lat, '==', -14.8958, q{Random location 461 latitude};
cmp_ok $lon, '==', -134.458, q{Random location 461 longitude};

( $grid ) = $sta->geodetic( -0.215475469145977, -0.175037241123452, 0 )
    ->maidenhead( 3 );
is $grid, 'IH47xp', q{Random location 462 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH47xp' ) );
cmp_ok $lat, '==', -12.3542, q{Random location 462 latitude};
cmp_ok $lon, '==', -10.0417, q{Random location 462 longitude};

( $grid ) = $sta->geodetic( 0.257051635009382, 1.63216577532921, 0 )
    ->maidenhead( 3 );
is $grid, 'NK64sr', q{Random location 463 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NK64sr' ) );
cmp_ok $lat, '==', 14.7292, q{Random location 463 latitude};
cmp_ok $lon, '==', 93.5417, q{Random location 463 longitude};

( $grid ) = $sta->geodetic( 0.0123297788568753, -0.16590204321356, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ50fq', q{Random location 464 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ50fq' ) );
cmp_ok $lat, '==', 0.6875, q{Random location 464 latitude};
cmp_ok $lon, '==', -9.54167, q{Random location 464 longitude};

( $grid ) = $sta->geodetic( 0.361905847368844, -2.90214786856428, 0 )
    ->maidenhead( 3 );
is $grid, 'AL60ur', q{Random location 465 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AL60ur' ) );
cmp_ok $lat, '==', 20.7292, q{Random location 465 latitude};
cmp_ok $lon, '==', -166.292, q{Random location 465 longitude};

( $grid ) = $sta->geodetic( 0.425317554352644, -2.59372715389796, 0 )
    ->maidenhead( 3 );
is $grid, 'BL54qi', q{Random location 466 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL54qi' ) );
cmp_ok $lat, '==', 24.3542, q{Random location 466 latitude};
cmp_ok $lon, '==', -148.625, q{Random location 466 longitude};

( $grid ) = $sta->geodetic( -0.3102879839464, 0.812640710985244, 0 )
    ->maidenhead( 3 );
is $grid, 'LH32gf', q{Random location 467 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH32gf' ) );
cmp_ok $lat, '==', -17.7708, q{Random location 467 latitude};
cmp_ok $lon, '==', 46.5417, q{Random location 467 longitude};

( $grid ) = $sta->geodetic( 0.370677497217971, 1.49706498739844, 0 )
    ->maidenhead( 3 );
is $grid, 'NL21vf', q{Random location 468 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL21vf' ) );
cmp_ok $lat, '==', 21.2292, q{Random location 468 latitude};
cmp_ok $lon, '==', 85.7917, q{Random location 468 longitude};

( $grid ) = $sta->geodetic( 0.995395015403794, -0.235696409293653, 0 )
    ->maidenhead( 3 );
is $grid, 'IO37fa', q{Random location 469 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IO37fa' ) );
cmp_ok $lat, '==', 57.0208, q{Random location 469 latitude};
cmp_ok $lon, '==', -13.5417, q{Random location 469 longitude};

( $grid ) = $sta->geodetic( 0.814651706216277, -0.890515835244118, 0 )
    ->maidenhead( 3 );
is $grid, 'GN46lq', q{Random location 470 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GN46lq' ) );
cmp_ok $lat, '==', 46.6875, q{Random location 470 latitude};
cmp_ok $lon, '==', -51.0417, q{Random location 470 longitude};

( $grid ) = $sta->geodetic( -1.13479536850021, 2.72360511488185, 0 )
    ->maidenhead( 3 );
is $grid, 'QC84ax', q{Random location 471 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QC84ax' ) );
cmp_ok $lat, '==', -65.0208, q{Random location 471 latitude};
cmp_ok $lon, '==', 156.042, q{Random location 471 longitude};

( $grid ) = $sta->geodetic( 0.734681159062991, 2.08703865002691, 0 )
    ->maidenhead( 3 );
is $grid, 'ON92sc', q{Random location 472 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ON92sc' ) );
cmp_ok $lat, '==', 42.1042, q{Random location 472 latitude};
cmp_ok $lon, '==', 119.542, q{Random location 472 longitude};

( $grid ) = $sta->geodetic( -1.48215473321678, -0.693056399222855, 0 )
    ->maidenhead( 3 );
is $grid, 'HA05db', q{Random location 473 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HA05db' ) );
cmp_ok $lat, '==', -84.9375, q{Random location 473 latitude};
cmp_ok $lon, '==', -39.7083, q{Random location 473 longitude};

( $grid ) = $sta->geodetic( -0.411604087046339, -1.31955966879318, 0 )
    ->maidenhead( 3 );
is $grid, 'FG26ek', q{Random location 474 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FG26ek' ) );
cmp_ok $lat, '==', -23.5625, q{Random location 474 latitude};
cmp_ok $lon, '==', -75.625, q{Random location 474 longitude};

( $grid ) = $sta->geodetic( 1.21775389557598, 2.48237680562753, 0 )
    ->maidenhead( 3 );
is $grid, 'QP19cs', q{Random location 475 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP19cs' ) );
cmp_ok $lat, '==', 69.7708, q{Random location 475 latitude};
cmp_ok $lon, '==', 142.208, q{Random location 475 longitude};

( $grid ) = $sta->geodetic( -0.0532360764185265, 2.0744709257995, 0 )
    ->maidenhead( 3 );
is $grid, 'OI96kw', q{Random location 476 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI96kw' ) );
cmp_ok $lat, '==', -3.0625, q{Random location 476 latitude};
cmp_ok $lon, '==', 118.875, q{Random location 476 longitude};

( $grid ) = $sta->geodetic( 1.35891941318557, -1.32034616637507, 0 )
    ->maidenhead( 3 );
is $grid, 'FQ27eu', q{Random location 477 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FQ27eu' ) );
cmp_ok $lat, '==', 77.8542, q{Random location 477 latitude};
cmp_ok $lon, '==', -75.625, q{Random location 477 longitude};

( $grid ) = $sta->geodetic( -1.3761633595043, -1.45930978530344, 0 )
    ->maidenhead( 3 );
is $grid, 'EB81ed', q{Random location 478 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EB81ed' ) );
cmp_ok $lat, '==', -78.8542, q{Random location 478 latitude};
cmp_ok $lon, '==', -83.625, q{Random location 478 longitude};

( $grid ) = $sta->geodetic( -0.923461487724174, -2.49187586798661, 0 )
    ->maidenhead( 3 );
is $grid, 'BD87oc', q{Random location 479 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BD87oc' ) );
cmp_ok $lat, '==', -52.8958, q{Random location 479 latitude};
cmp_ok $lon, '==', -142.792, q{Random location 479 longitude};

( $grid ) = $sta->geodetic( -0.237130081507389, -0.310257434674329, 0 )
    ->maidenhead( 3 );
is $grid, 'IH16cj', q{Random location 480 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH16cj' ) );
cmp_ok $lat, '==', -13.6042, q{Random location 480 latitude};
cmp_ok $lon, '==', -17.7917, q{Random location 480 longitude};

( $grid ) = $sta->geodetic( 1.07652338649246, 2.76006279124371, 0 )
    ->maidenhead( 3 );
is $grid, 'QP91bq', q{Random location 481 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP91bq' ) );
cmp_ok $lat, '==', 61.6875, q{Random location 481 latitude};
cmp_ok $lon, '==', 158.125, q{Random location 481 longitude};

( $grid ) = $sta->geodetic( -1.36313951961109, 0.265640938146734, 0 )
    ->maidenhead( 3 );
is $grid, 'JB71ov', q{Random location 482 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JB71ov' ) );
cmp_ok $lat, '==', -78.1042, q{Random location 482 latitude};
cmp_ok $lon, '==', 15.2083, q{Random location 482 longitude};

( $grid ) = $sta->geodetic( -0.751885908201615, -2.95364862577959, 0 )
    ->maidenhead( 3 );
is $grid, 'AE56jw', q{Random location 483 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE56jw' ) );
cmp_ok $lat, '==', -43.0625, q{Random location 483 latitude};
cmp_ok $lon, '==', -169.208, q{Random location 483 longitude};

( $grid ) = $sta->geodetic( -0.488832798742372, 0.210991506613642, 0 )
    ->maidenhead( 3 );
is $grid, 'JG61bx', q{Random location 484 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JG61bx' ) );
cmp_ok $lat, '==', -28.0208, q{Random location 484 latitude};
cmp_ok $lon, '==', 12.125, q{Random location 484 longitude};

( $grid ) = $sta->geodetic( 1.06225855835612, -3.00928940974578, 0 )
    ->maidenhead( 3 );
is $grid, 'AP30su', q{Random location 485 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AP30su' ) );
cmp_ok $lat, '==', 60.8542, q{Random location 485 latitude};
cmp_ok $lon, '==', -172.458, q{Random location 485 longitude};

( $grid ) = $sta->geodetic( -0.426764016464027, 0.700911193851624, 0 )
    ->maidenhead( 3 );
is $grid, 'LG05bn', q{Random location 486 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LG05bn' ) );
cmp_ok $lat, '==', -24.4375, q{Random location 486 latitude};
cmp_ok $lon, '==', 40.125, q{Random location 486 longitude};

( $grid ) = $sta->geodetic( -0.660093930339743, 2.98522731325725, 0 )
    ->maidenhead( 3 );
is $grid, 'RF52me', q{Random location 487 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RF52me' ) );
cmp_ok $lat, '==', -37.8125, q{Random location 487 latitude};
cmp_ok $lon, '==', 171.042, q{Random location 487 longitude};

( $grid ) = $sta->geodetic( -1.26396228913613, -3.05445638305513, 0 )
    ->maidenhead( 3 );
is $grid, 'AB27ln', q{Random location 488 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AB27ln' ) );
cmp_ok $lat, '==', -72.4375, q{Random location 488 latitude};
cmp_ok $lon, '==', -175.042, q{Random location 488 longitude};

( $grid ) = $sta->geodetic( 0.870345289623315, 0.791428777732635, 0 )
    ->maidenhead( 3 );
is $grid, 'LN29qu', q{Random location 489 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LN29qu' ) );
cmp_ok $lat, '==', 49.8542, q{Random location 489 latitude};
cmp_ok $lon, '==', 45.375, q{Random location 489 longitude};

( $grid ) = $sta->geodetic( 0.232149630716755, 0.994281479384613, 0 )
    ->maidenhead( 3 );
is $grid, 'LK83lh', q{Random location 490 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LK83lh' ) );
cmp_ok $lat, '==', 13.3125, q{Random location 490 latitude};
cmp_ok $lon, '==', 56.9583, q{Random location 490 longitude};

( $grid ) = $sta->geodetic( 0.591776776214297, -2.26822125264362, 0 )
    ->maidenhead( 3 );
is $grid, 'CM53av', q{Random location 491 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CM53av' ) );
cmp_ok $lat, '==', 33.8958, q{Random location 491 latitude};
cmp_ok $lon, '==', -129.958, q{Random location 491 longitude};

( $grid ) = $sta->geodetic( 0.0397355197520994, -1.12308546657251, 0 )
    ->maidenhead( 3 );
is $grid, 'FJ72tg', q{Random location 492 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FJ72tg' ) );
cmp_ok $lat, '==', 2.27083, q{Random location 492 latitude};
cmp_ok $lon, '==', -64.375, q{Random location 492 longitude};

( $grid ) = $sta->geodetic( 1.03939060849092, 2.25139228432588, 0 )
    ->maidenhead( 3 );
is $grid, 'PO49ln', q{Random location 493 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PO49ln' ) );
cmp_ok $lat, '==', 59.5625, q{Random location 493 latitude};
cmp_ok $lon, '==', 128.958, q{Random location 493 longitude};

( $grid ) = $sta->geodetic( -0.192847271148176, -3.0995226911882, 0 )
    ->maidenhead( 3 );
is $grid, 'AH18ew', q{Random location 494 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AH18ew' ) );
cmp_ok $lat, '==', -11.0625, q{Random location 494 latitude};
cmp_ok $lon, '==', -177.625, q{Random location 494 longitude};

( $grid ) = $sta->geodetic( -0.184319038873745, 0.643896508474564, 0 )
    ->maidenhead( 3 );
is $grid, 'KH89kk', q{Random location 495 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KH89kk' ) );
cmp_ok $lat, '==', -10.5625, q{Random location 495 latitude};
cmp_ok $lon, '==', 36.875, q{Random location 495 longitude};

( $grid ) = $sta->geodetic( 0.697490007584668, 0.54109434899685, 0 )
    ->maidenhead( 3 );
is $grid, 'KM59mx', q{Random location 496 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM59mx' ) );
cmp_ok $lat, '==', 39.9792, q{Random location 496 latitude};
cmp_ok $lon, '==', 31.0417, q{Random location 496 longitude};

( $grid ) = $sta->geodetic( -0.540449257832814, -2.43631346250717, 0 )
    ->maidenhead( 3 );
is $grid, 'CF09ea', q{Random location 497 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF09ea' ) );
cmp_ok $lat, '==', -30.9792, q{Random location 497 latitude};
cmp_ok $lon, '==', -139.625, q{Random location 497 longitude};

( $grid ) = $sta->geodetic( -0.580828899142696, 2.51432393492312, 0 )
    ->maidenhead( 3 );
is $grid, 'QF26ar', q{Random location 498 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF26ar' ) );
cmp_ok $lat, '==', -33.2708, q{Random location 498 latitude};
cmp_ok $lon, '==', 144.042, q{Random location 498 longitude};

( $grid ) = $sta->geodetic( 0.049425817105238, 2.40742700461427, 0 )
    ->maidenhead( 3 );
is $grid, 'PJ82xt', q{Random location 499 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PJ82xt' ) );
cmp_ok $lat, '==', 2.8125, q{Random location 499 latitude};
cmp_ok $lon, '==', 137.958, q{Random location 499 longitude};

( $grid ) = $sta->geodetic( 1.08790764717914, 0.0414084486621591, 0 )
    ->maidenhead( 3 );
is $grid, 'JP12eh', q{Random location 500 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JP12eh' ) );
cmp_ok $lat, '==', 62.3125, q{Random location 500 latitude};
cmp_ok $lon, '==', 2.375, q{Random location 500 longitude};

( $grid ) = $sta->geodetic( -0.605709276855156, -1.72821354814188, 0 )
    ->maidenhead( 3 );
is $grid, 'EF05lh', q{Random location 501 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EF05lh' ) );
cmp_ok $lat, '==', -34.6875, q{Random location 501 latitude};
cmp_ok $lon, '==', -99.0417, q{Random location 501 longitude};

( $grid ) = $sta->geodetic( 0.793096279401736, 1.67982881324333, 0 )
    ->maidenhead( 3 );
is $grid, 'NN85ck', q{Random location 502 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NN85ck' ) );
cmp_ok $lat, '==', 45.4375, q{Random location 502 latitude};
cmp_ok $lon, '==', 96.2083, q{Random location 502 longitude};

( $grid ) = $sta->geodetic( -0.0710990783400476, -0.715856438656104, 0 )
    ->maidenhead( 3 );
is $grid, 'GI95lw', q{Random location 503 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GI95lw' ) );
cmp_ok $lat, '==', -4.0625, q{Random location 503 latitude};
cmp_ok $lon, '==', -41.0417, q{Random location 503 longitude};

( $grid ) = $sta->geodetic( 1.30545013628283, -1.6211248382766, 0 )
    ->maidenhead( 3 );
is $grid, 'EQ34nt', q{Random location 504 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EQ34nt' ) );
cmp_ok $lat, '==', 74.8125, q{Random location 504 latitude};
cmp_ok $lon, '==', -92.875, q{Random location 504 longitude};

( $grid ) = $sta->geodetic( -0.225336163540344, 0.859497535464616, 0 )
    ->maidenhead( 3 );
is $grid, 'LH47oc', q{Random location 505 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH47oc' ) );
cmp_ok $lat, '==', -12.8958, q{Random location 505 latitude};
cmp_ok $lon, '==', 49.2083, q{Random location 505 longitude};

( $grid ) = $sta->geodetic( 0.952401317260956, 0.292494123467902, 0 )
    ->maidenhead( 3 );
is $grid, 'JO84jn', q{Random location 506 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JO84jn' ) );
cmp_ok $lat, '==', 54.5625, q{Random location 506 latitude};
cmp_ok $lon, '==', 16.7917, q{Random location 506 longitude};

( $grid ) = $sta->geodetic( 0.130264544334273, 0.0530441288804355, 0 )
    ->maidenhead( 3 );
is $grid, 'JJ17ml', q{Random location 507 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JJ17ml' ) );
cmp_ok $lat, '==', 7.47917, q{Random location 507 latitude};
cmp_ok $lon, '==', 3.04167, q{Random location 507 longitude};

( $grid ) = $sta->geodetic( -0.570891977021164, -1.65044460817967, 0 )
    ->maidenhead( 3 );
is $grid, 'EF27rg', q{Random location 508 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EF27rg' ) );
cmp_ok $lat, '==', -32.7292, q{Random location 508 latitude};
cmp_ok $lon, '==', -94.5417, q{Random location 508 longitude};

( $grid ) = $sta->geodetic( 0.759764923063804, 2.46291158989754, 0 )
    ->maidenhead( 3 );
is $grid, 'QN03nm', q{Random location 509 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QN03nm' ) );
cmp_ok $lat, '==', 43.5208, q{Random location 509 latitude};
cmp_ok $lon, '==', 141.125, q{Random location 509 longitude};

( $grid ) = $sta->geodetic( -0.658555478506653, 0.418133918152693, 0 )
    ->maidenhead( 3 );
is $grid, 'KF12xg', q{Random location 510 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KF12xg' ) );
cmp_ok $lat, '==', -37.7292, q{Random location 510 latitude};
cmp_ok $lon, '==', 23.9583, q{Random location 510 longitude};

( $grid ) = $sta->geodetic( 0.502220255870919, -0.771474533392638, 0 )
    ->maidenhead( 3 );
is $grid, 'GL78vs', q{Random location 511 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GL78vs' ) );
cmp_ok $lat, '==', 28.7708, q{Random location 511 latitude};
cmp_ok $lon, '==', -44.2083, q{Random location 511 longitude};

( $grid ) = $sta->geodetic( -0.214037878972731, -0.282836798390478, 0 )
    ->maidenhead( 3 );
is $grid, 'IH17vr', q{Random location 512 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH17vr' ) );
cmp_ok $lat, '==', -12.2708, q{Random location 512 latitude};
cmp_ok $lon, '==', -16.2083, q{Random location 512 longitude};

( $grid ) = $sta->geodetic( -0.726755148206766, -1.26396408374056, 0 )
    ->maidenhead( 3 );
is $grid, 'FE38si', q{Random location 513 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FE38si' ) );
cmp_ok $lat, '==', -41.6458, q{Random location 513 latitude};
cmp_ok $lon, '==', -72.4583, q{Random location 513 longitude};

( $grid ) = $sta->geodetic( 0.291318243208683, 2.79710094224695, 0 )
    ->maidenhead( 3 );
is $grid, 'RK06dq', q{Random location 514 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RK06dq' ) );
cmp_ok $lat, '==', 16.6875, q{Random location 514 latitude};
cmp_ok $lon, '==', 160.292, q{Random location 514 longitude};

( $grid ) = $sta->geodetic( 1.34478680415127, -1.89028585943356, 0 )
    ->maidenhead( 3 );
is $grid, 'DQ57ub', q{Random location 515 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DQ57ub' ) );
cmp_ok $lat, '==', 77.0625, q{Random location 515 latitude};
cmp_ok $lon, '==', -108.292, q{Random location 515 longitude};

( $grid ) = $sta->geodetic( -0.0378433934709843, -2.56174377945338, 0 )
    ->maidenhead( 3 );
is $grid, 'BI67ot', q{Random location 516 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI67ot' ) );
cmp_ok $lat, '==', -2.1875, q{Random location 516 latitude};
cmp_ok $lon, '==', -146.792, q{Random location 516 longitude};

( $grid ) = $sta->geodetic( 0.746159243298827, -1.03376577936986, 0 )
    ->maidenhead( 3 );
is $grid, 'GN02js', q{Random location 517 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GN02js' ) );
cmp_ok $lat, '==', 42.7708, q{Random location 517 latitude};
cmp_ok $lon, '==', -59.2083, q{Random location 517 longitude};

( $grid ) = $sta->geodetic( -0.0411663489844001, -0.253385360131734, 0 )
    ->maidenhead( 3 );
is $grid, 'II27rp', q{Random location 518 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'II27rp' ) );
cmp_ok $lat, '==', -2.35417, q{Random location 518 latitude};
cmp_ok $lon, '==', -14.5417, q{Random location 518 longitude};

( $grid ) = $sta->geodetic( 0.0296541263962666, 3.0504764343579, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ71jq', q{Random location 519 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ71jq' ) );
cmp_ok $lat, '==', 1.6875, q{Random location 519 latitude};
cmp_ok $lon, '==', 174.792, q{Random location 519 longitude};

( $grid ) = $sta->geodetic( -0.941771844499404, -0.0172758232181396, 0 )
    ->maidenhead( 3 );
is $grid, 'ID96ma', q{Random location 520 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID96ma' ) );
cmp_ok $lat, '==', -53.9792, q{Random location 520 latitude};
cmp_ok $lon, '==', -0.958333, q{Random location 520 longitude};

( $grid ) = $sta->geodetic( -0.268170433735327, -0.411501960622497, 0 )
    ->maidenhead( 3 );
is $grid, 'HH84fp', q{Random location 521 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HH84fp' ) );
cmp_ok $lat, '==', -15.3542, q{Random location 521 latitude};
cmp_ok $lon, '==', -23.5417, q{Random location 521 longitude};

( $grid ) = $sta->geodetic( 0.403027296099015, -0.832903716748669, 0 )
    ->maidenhead( 3 );
is $grid, 'GL63dc', q{Random location 522 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GL63dc' ) );
cmp_ok $lat, '==', 23.1042, q{Random location 522 latitude};
cmp_ok $lon, '==', -47.7083, q{Random location 522 longitude};

( $grid ) = $sta->geodetic( 0.105732971029067, 2.99509531129916, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ56tb', q{Random location 523 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ56tb' ) );
cmp_ok $lat, '==', 6.0625, q{Random location 523 latitude};
cmp_ok $lon, '==', 171.625, q{Random location 523 longitude};

( $grid ) = $sta->geodetic( -1.346823633949, 1.006263219863, 0 )
    ->maidenhead( 3 );
is $grid, 'LB82tt', q{Random location 524 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LB82tt' ) );
cmp_ok $lat, '==', -77.1875, q{Random location 524 latitude};
cmp_ok $lon, '==', 57.625, q{Random location 524 longitude};

( $grid ) = $sta->geodetic( -0.0759601579296931, -2.45454963529428, 0 )
    ->maidenhead( 3 );
is $grid, 'BI95qp', q{Random location 525 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI95qp' ) );
cmp_ok $lat, '==', -4.35417, q{Random location 525 latitude};
cmp_ok $lon, '==', -140.625, q{Random location 525 longitude};

( $grid ) = $sta->geodetic( -0.0514298464688898, 1.32764394202802, 0 )
    ->maidenhead( 3 );
is $grid, 'MI87ab', q{Random location 526 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MI87ab' ) );
cmp_ok $lat, '==', -2.9375, q{Random location 526 latitude};
cmp_ok $lon, '==', 76.0417, q{Random location 526 longitude};

( $grid ) = $sta->geodetic( -0.410553902183793, -0.394378182838151, 0 )
    ->maidenhead( 3 );
is $grid, 'HG86ql', q{Random location 527 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HG86ql' ) );
cmp_ok $lat, '==', -23.5208, q{Random location 527 latitude};
cmp_ok $lon, '==', -22.625, q{Random location 527 longitude};

( $grid ) = $sta->geodetic( 0.645435275051505, -0.913930412520514, 0 )
    ->maidenhead( 3 );
is $grid, 'GM36tx', q{Random location 528 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GM36tx' ) );
cmp_ok $lat, '==', 36.9792, q{Random location 528 latitude};
cmp_ok $lon, '==', -52.375, q{Random location 528 longitude};

( $grid ) = $sta->geodetic( -0.730927758560933, 3.11122897694989, 0 )
    ->maidenhead( 3 );
is $grid, 'RE98dc', q{Random location 529 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RE98dc' ) );
cmp_ok $lat, '==', -41.8958, q{Random location 529 latitude};
cmp_ok $lon, '==', 178.292, q{Random location 529 longitude};

( $grid ) = $sta->geodetic( -0.769383917391915, -1.69326810979585, 0 )
    ->maidenhead( 3 );
is $grid, 'EE15lw', q{Random location 530 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EE15lw' ) );
cmp_ok $lat, '==', -44.0625, q{Random location 530 latitude};
cmp_ok $lon, '==', -97.0417, q{Random location 530 longitude};

( $grid ) = $sta->geodetic( -1.26152291287064, 0.735624412687284, 0 )
    ->maidenhead( 3 );
is $grid, 'LB17br', q{Random location 531 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LB17br' ) );
cmp_ok $lat, '==', -72.2708, q{Random location 531 latitude};
cmp_ok $lon, '==', 42.125, q{Random location 531 longitude};

( $grid ) = $sta->geodetic( -1.15037720038916, 1.4394309307115, 0 )
    ->maidenhead( 3 );
is $grid, 'NC14fc', q{Random location 532 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NC14fc' ) );
cmp_ok $lat, '==', -65.8958, q{Random location 532 latitude};
cmp_ok $lon, '==', 82.4583, q{Random location 532 longitude};

( $grid ) = $sta->geodetic( -1.09134989758922, -1.45006109405426, 0 )
    ->maidenhead( 3 );
is $grid, 'EC87ll', q{Random location 533 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EC87ll' ) );
cmp_ok $lat, '==', -62.5208, q{Random location 533 latitude};
cmp_ok $lon, '==', -83.0417, q{Random location 533 longitude};

( $grid ) = $sta->geodetic( 0.383666987402762, -2.4083726294407, 0 )
    ->maidenhead( 3 );
is $grid, 'CL11ax', q{Random location 534 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CL11ax' ) );
cmp_ok $lat, '==', 21.9792, q{Random location 534 latitude};
cmp_ok $lon, '==', -137.958, q{Random location 534 longitude};

( $grid ) = $sta->geodetic( 0.992170221881359, 0.519482554915798, 0 )
    ->maidenhead( 3 );
is $grid, 'KO46vu', q{Random location 535 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO46vu' ) );
cmp_ok $lat, '==', 56.8542, q{Random location 535 latitude};
cmp_ok $lon, '==', 29.7917, q{Random location 535 longitude};

( $grid ) = $sta->geodetic( -0.390399167029003, 2.57798835843289, 0 )
    ->maidenhead( 3 );
is $grid, 'QG37up', q{Random location 536 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG37up' ) );
cmp_ok $lat, '==', -22.3542, q{Random location 536 latitude};
cmp_ok $lon, '==', 147.708, q{Random location 536 longitude};

( $grid ) = $sta->geodetic( -0.173014785195776, -2.58946302144781, 0 )
    ->maidenhead( 3 );
is $grid, 'BI50tc', q{Random location 537 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BI50tc' ) );
cmp_ok $lat, '==', -9.89583, q{Random location 537 latitude};
cmp_ok $lon, '==', -148.375, q{Random location 537 longitude};

( $grid ) = $sta->geodetic( -0.64112572322612, 0.0221828458167557, 0 )
    ->maidenhead( 3 );
is $grid, 'JF03pg', q{Random location 538 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JF03pg' ) );
cmp_ok $lat, '==', -36.7292, q{Random location 538 latitude};
cmp_ok $lon, '==', 1.29167, q{Random location 538 longitude};

( $grid ) = $sta->geodetic( -1.011334666133, -1.19506210307819, 0 )
    ->maidenhead( 3 );
is $grid, 'FD52sb', q{Random location 539 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FD52sb' ) );
cmp_ok $lat, '==', -57.9375, q{Random location 539 latitude};
cmp_ok $lon, '==', -68.4583, q{Random location 539 longitude};

( $grid ) = $sta->geodetic( -0.0136830233387044, 2.92944247009038, 0 )
    ->maidenhead( 3 );
is $grid, 'RI39wf', q{Random location 540 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RI39wf' ) );
cmp_ok $lat, '==', -0.770833, q{Random location 540 latitude};
cmp_ok $lon, '==', 167.875, q{Random location 540 longitude};

( $grid ) = $sta->geodetic( 0.321918842708021, -2.31153214154375, 0 )
    ->maidenhead( 3 );
is $grid, 'CK38sk', q{Random location 541 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK38sk' ) );
cmp_ok $lat, '==', 18.4375, q{Random location 541 latitude};
cmp_ok $lon, '==', -132.458, q{Random location 541 longitude};

( $grid ) = $sta->geodetic( -0.636982389144234, 1.62988440691726, 0 )
    ->maidenhead( 3 );
is $grid, 'NF63qm', q{Random location 542 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NF63qm' ) );
cmp_ok $lat, '==', -36.4792, q{Random location 542 latitude};
cmp_ok $lon, '==', 93.375, q{Random location 542 longitude};

( $grid ) = $sta->geodetic( 0.393067024454787, 2.51065998220554, 0 )
    ->maidenhead( 3 );
is $grid, 'QL12wm', q{Random location 543 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QL12wm' ) );
cmp_ok $lat, '==', 22.5208, q{Random location 543 latitude};
cmp_ok $lon, '==', 143.875, q{Random location 543 longitude};

( $grid ) = $sta->geodetic( -0.136999830437403, -0.61128874142228, 0 )
    ->maidenhead( 3 );
is $grid, 'HI22ld', q{Random location 544 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HI22ld' ) );
cmp_ok $lat, '==', -7.85417, q{Random location 544 latitude};
cmp_ok $lon, '==', -35.0417, q{Random location 544 longitude};

( $grid ) = $sta->geodetic( -0.391913286035333, -2.58734575890354, 0 )
    ->maidenhead( 3 );
is $grid, 'BG57vn', q{Random location 545 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BG57vn' ) );
cmp_ok $lat, '==', -22.4375, q{Random location 545 latitude};
cmp_ok $lon, '==', -148.208, q{Random location 545 longitude};

( $grid ) = $sta->geodetic( -0.134869392170901, -0.851654621489473, 0 )
    ->maidenhead( 3 );
is $grid, 'GI52og', q{Random location 546 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GI52og' ) );
cmp_ok $lat, '==', -7.72917, q{Random location 546 latitude};
cmp_ok $lon, '==', -48.7917, q{Random location 546 longitude};

( $grid ) = $sta->geodetic( 0.118272247059735, -2.95018728980391, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ56ls', q{Random location 547 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ56ls' ) );
cmp_ok $lat, '==', 6.77083, q{Random location 547 latitude};
cmp_ok $lon, '==', -169.042, q{Random location 547 longitude};

( $grid ) = $sta->geodetic( 0.813836059669888, -1.78545579454715, 0 )
    ->maidenhead( 3 );
is $grid, 'DN86up', q{Random location 548 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DN86up' ) );
cmp_ok $lat, '==', 46.6458, q{Random location 548 latitude};
cmp_ok $lon, '==', -102.292, q{Random location 548 longitude};

( $grid ) = $sta->geodetic( -0.366317314393635, 2.55971288729334, 0 )
    ->maidenhead( 3 );
is $grid, 'QG39ha', q{Random location 549 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG39ha' ) );
cmp_ok $lat, '==', -20.9792, q{Random location 549 latitude};
cmp_ok $lon, '==', 146.625, q{Random location 549 longitude};

( $grid ) = $sta->geodetic( 1.17339598395498, -0.651165051948263, 0 )
    ->maidenhead( 3 );
is $grid, 'HP17if', q{Random location 550 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HP17if' ) );
cmp_ok $lat, '==', 67.2292, q{Random location 550 latitude};
cmp_ok $lon, '==', -37.2917, q{Random location 550 longitude};

( $grid ) = $sta->geodetic( 0.909293822892485, 1.82679945691293, 0 )
    ->maidenhead( 3 );
is $grid, 'OO22ic', q{Random location 551 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OO22ic' ) );
cmp_ok $lat, '==', 52.1042, q{Random location 551 latitude};
cmp_ok $lon, '==', 104.708, q{Random location 551 longitude};

( $grid ) = $sta->geodetic( 0.556898357710057, -0.573542879160966, 0 )
    ->maidenhead( 3 );
is $grid, 'HM31nv', q{Random location 552 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM31nv' ) );
cmp_ok $lat, '==', 31.8958, q{Random location 552 latitude};
cmp_ok $lon, '==', -32.875, q{Random location 552 longitude};

( $grid ) = $sta->geodetic( 0.637637294628658, 3.05102189065272, 0 )
    ->maidenhead( 3 );
is $grid, 'RM76jm', q{Random location 553 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM76jm' ) );
cmp_ok $lat, '==', 36.5208, q{Random location 553 latitude};
cmp_ok $lon, '==', 174.792, q{Random location 553 longitude};

( $grid ) = $sta->geodetic( -0.634181193812152, -0.478893139014284, 0 )
    ->maidenhead( 3 );
is $grid, 'HF63gp', q{Random location 554 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF63gp' ) );
cmp_ok $lat, '==', -36.3542, q{Random location 554 latitude};
cmp_ok $lon, '==', -27.4583, q{Random location 554 longitude};

( $grid ) = $sta->geodetic( 0.222485191627644, 2.19995274672972, 0 )
    ->maidenhead( 3 );
is $grid, 'PK32ar', q{Random location 555 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK32ar' ) );
cmp_ok $lat, '==', 12.7292, q{Random location 555 latitude};
cmp_ok $lon, '==', 126.042, q{Random location 555 longitude};

( $grid ) = $sta->geodetic( 1.08487284391182, 1.85399188104016, 0 )
    ->maidenhead( 3 );
is $grid, 'OP32cd', q{Random location 556 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OP32cd' ) );
cmp_ok $lat, '==', 62.1458, q{Random location 556 latitude};
cmp_ok $lon, '==', 106.208, q{Random location 556 longitude};

( $grid ) = $sta->geodetic( 0.795225110882162, 3.04101722472555, 0 )
    ->maidenhead( 3 );
is $grid, 'RN75cn', q{Random location 557 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RN75cn' ) );
cmp_ok $lat, '==', 45.5625, q{Random location 557 latitude};
cmp_ok $lon, '==', 174.208, q{Random location 557 longitude};

( $grid ) = $sta->geodetic( 0.949839620401376, 2.58811677862822, 0 )
    ->maidenhead( 3 );
is $grid, 'QO44dk', q{Random location 558 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QO44dk' ) );
cmp_ok $lat, '==', 54.4375, q{Random location 558 latitude};
cmp_ok $lon, '==', 148.292, q{Random location 558 longitude};

( $grid ) = $sta->geodetic( -0.297303964342774, 0.145868380223985, 0 )
    ->maidenhead( 3 );
is $grid, 'JH42ex', q{Random location 559 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JH42ex' ) );
cmp_ok $lat, '==', -17.0208, q{Random location 559 latitude};
cmp_ok $lon, '==', 8.375, q{Random location 559 longitude};

( $grid ) = $sta->geodetic( -0.123901760942996, 2.2546057574106, 0 )
    ->maidenhead( 3 );
is $grid, 'PI42ov', q{Random location 560 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PI42ov' ) );
cmp_ok $lat, '==', -7.10417, q{Random location 560 latitude};
cmp_ok $lon, '==', 129.208, q{Random location 560 longitude};

( $grid ) = $sta->geodetic( 0.569588806760241, 2.33210038984975, 0 )
    ->maidenhead( 3 );
is $grid, 'PM62tp', q{Random location 561 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM62tp' ) );
cmp_ok $lat, '==', 32.6458, q{Random location 561 latitude};
cmp_ok $lon, '==', 133.625, q{Random location 561 longitude};

( $grid ) = $sta->geodetic( 0.801519674523729, -2.62837372172515, 0 )
    ->maidenhead( 3 );
is $grid, 'BN45qw', q{Random location 562 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BN45qw' ) );
cmp_ok $lat, '==', 45.9375, q{Random location 562 latitude};
cmp_ok $lon, '==', -150.625, q{Random location 562 longitude};

( $grid ) = $sta->geodetic( 0.910405615121395, 0.966813448228585, 0 )
    ->maidenhead( 3 );
is $grid, 'LO72qd', q{Random location 563 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LO72qd' ) );
cmp_ok $lat, '==', 52.1458, q{Random location 563 latitude};
cmp_ok $lon, '==', 55.375, q{Random location 563 longitude};

( $grid ) = $sta->geodetic( 0.65278327665096, -0.52551935938807, 0 )
    ->maidenhead( 3 );
is $grid, 'HM47wj', q{Random location 564 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM47wj' ) );
cmp_ok $lat, '==', 37.3958, q{Random location 564 latitude};
cmp_ok $lon, '==', -30.125, q{Random location 564 longitude};

( $grid ) = $sta->geodetic( -0.111192223617497, 2.57043643760154, 0 )
    ->maidenhead( 3 );
is $grid, 'QI33pp', q{Random location 565 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI33pp' ) );
cmp_ok $lat, '==', -6.35417, q{Random location 565 latitude};
cmp_ok $lon, '==', 147.292, q{Random location 565 longitude};

( $grid ) = $sta->geodetic( -0.715604306015198, 0.201752489868742, 0 )
    ->maidenhead( 3 );
is $grid, 'JE58sx', q{Random location 566 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JE58sx' ) );
cmp_ok $lat, '==', -41.0208, q{Random location 566 latitude};
cmp_ok $lon, '==', 11.5417, q{Random location 566 longitude};

( $grid ) = $sta->geodetic( 0.704983678558541, -0.585251730397199, 0 )
    ->maidenhead( 3 );
is $grid, 'HN30fj', q{Random location 567 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HN30fj' ) );
cmp_ok $lat, '==', 40.3958, q{Random location 567 latitude};
cmp_ok $lon, '==', -33.5417, q{Random location 567 longitude};

( $grid ) = $sta->geodetic( 0.374657791132662, 2.11539515839358, 0 )
    ->maidenhead( 3 );
is $grid, 'PL01ol', q{Random location 568 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL01ol' ) );
cmp_ok $lat, '==', 21.4792, q{Random location 568 latitude};
cmp_ok $lon, '==', 121.208, q{Random location 568 longitude};

( $grid ) = $sta->geodetic( 0.848913037544546, 1.4364408461693, 0 )
    ->maidenhead( 3 );
is $grid, 'NN18dp', q{Random location 569 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NN18dp' ) );
cmp_ok $lat, '==', 48.6458, q{Random location 569 latitude};
cmp_ok $lon, '==', 82.2917, q{Random location 569 longitude};

( $grid ) = $sta->geodetic( -0.286663053511078, 2.10410999176619, 0 )
    ->maidenhead( 3 );
is $grid, 'PH03gn', q{Random location 570 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PH03gn' ) );
cmp_ok $lat, '==', -16.4375, q{Random location 570 latitude};
cmp_ok $lon, '==', 120.542, q{Random location 570 longitude};

( $grid ) = $sta->geodetic( 1.23438688571338, 3.08619790297563, 0 )
    ->maidenhead( 3 );
is $grid, 'RQ80jr', q{Random location 571 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RQ80jr' ) );
cmp_ok $lat, '==', 70.7292, q{Random location 571 latitude};
cmp_ok $lon, '==', 176.792, q{Random location 571 longitude};

( $grid ) = $sta->geodetic( -0.324686826000243, 0.723263691170269, 0 )
    ->maidenhead( 3 );
is $grid, 'LH01rj', q{Random location 572 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH01rj' ) );
cmp_ok $lat, '==', -18.6042, q{Random location 572 latitude};
cmp_ok $lon, '==', 41.4583, q{Random location 572 longitude};

( $grid ) = $sta->geodetic( -0.416780786471696, -0.983577923158846, 0 )
    ->maidenhead( 3 );
is $grid, 'GG16tc', q{Random location 573 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG16tc' ) );
cmp_ok $lat, '==', -23.8958, q{Random location 573 latitude};
cmp_ok $lon, '==', -56.375, q{Random location 573 longitude};

( $grid ) = $sta->geodetic( -0.603306760743444, 1.51295497848722, 0 )
    ->maidenhead( 3 );
is $grid, 'NF35ik', q{Random location 574 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NF35ik' ) );
cmp_ok $lat, '==', -34.5625, q{Random location 574 latitude};
cmp_ok $lon, '==', 86.7083, q{Random location 574 longitude};

( $grid ) = $sta->geodetic( 0.0780992171976083, -2.76569251255036, 0 )
    ->maidenhead( 3 );
is $grid, 'BJ04sl', q{Random location 575 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BJ04sl' ) );
cmp_ok $lat, '==', 4.47917, q{Random location 575 latitude};
cmp_ok $lon, '==', -158.458, q{Random location 575 longitude};

( $grid ) = $sta->geodetic( 0.689597569610057, -2.09123986949715, 0 )
    ->maidenhead( 3 );
is $grid, 'DM09cm', q{Random location 576 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DM09cm' ) );
cmp_ok $lat, '==', 39.5208, q{Random location 576 latitude};
cmp_ok $lon, '==', -119.792, q{Random location 576 longitude};

( $grid ) = $sta->geodetic( 0.0741472809922807, 2.75069595144723, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ84tf', q{Random location 577 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ84tf' ) );
cmp_ok $lat, '==', 4.22917, q{Random location 577 latitude};
cmp_ok $lon, '==', 157.625, q{Random location 577 longitude};

( $grid ) = $sta->geodetic( 0.191126770222979, 0.626545965808345, 0 )
    ->maidenhead( 3 );
is $grid, 'KK70ww', q{Random location 578 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK70ww' ) );
cmp_ok $lat, '==', 10.9375, q{Random location 578 latitude};
cmp_ok $lon, '==', 35.875, q{Random location 578 longitude};

( $grid ) = $sta->geodetic( 0.114579771248583, -2.9468140831806, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ56nn', q{Random location 579 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ56nn' ) );
cmp_ok $lat, '==', 6.5625, q{Random location 579 latitude};
cmp_ok $lon, '==', -168.875, q{Random location 579 longitude};

( $grid ) = $sta->geodetic( -0.404294262467865, 1.95915694111382, 0 )
    ->maidenhead( 3 );
is $grid, 'OG66du', q{Random location 580 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OG66du' ) );
cmp_ok $lat, '==', -23.1458, q{Random location 580 latitude};
cmp_ok $lon, '==', 112.292, q{Random location 580 longitude};

( $grid ) = $sta->geodetic( -0.303685664569313, 0.179039089429578, 0 )
    ->maidenhead( 3 );
is $grid, 'JH52do', q{Random location 581 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JH52do' ) );
cmp_ok $lat, '==', -17.3958, q{Random location 581 latitude};
cmp_ok $lon, '==', 10.2917, q{Random location 581 longitude};

( $grid ) = $sta->geodetic( 0.174720403449182, -2.58397613760667, 0 )
    ->maidenhead( 3 );
is $grid, 'BK50xa', q{Random location 582 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK50xa' ) );
cmp_ok $lat, '==', 10.0208, q{Random location 582 latitude};
cmp_ok $lon, '==', -148.042, q{Random location 582 longitude};

( $grid ) = $sta->geodetic( -1.06643047080515, 2.25410286213634, 0 )
    ->maidenhead( 3 );
is $grid, 'PC48nv', q{Random location 583 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PC48nv' ) );
cmp_ok $lat, '==', -61.1042, q{Random location 583 latitude};
cmp_ok $lon, '==', 129.125, q{Random location 583 longitude};

( $grid ) = $sta->geodetic( -1.2468704168682, -2.8447182191173, 0 )
    ->maidenhead( 3 );
is $grid, 'AB88mn', q{Random location 584 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AB88mn' ) );
cmp_ok $lat, '==', -71.4375, q{Random location 584 latitude};
cmp_ok $lon, '==', -162.958, q{Random location 584 longitude};

( $grid ) = $sta->geodetic( -0.0388748834214556, -2.1896923251801, 0 )
    ->maidenhead( 3 );
is $grid, 'CI77gs', q{Random location 585 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI77gs' ) );
cmp_ok $lat, '==', -2.22917, q{Random location 585 latitude};
cmp_ok $lon, '==', -125.458, q{Random location 585 longitude};

( $grid ) = $sta->geodetic( -0.096702979676486, -0.830672991232855, 0 )
    ->maidenhead( 3 );
is $grid, 'GI64el', q{Random location 586 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GI64el' ) );
cmp_ok $lat, '==', -5.52083, q{Random location 586 latitude};
cmp_ok $lon, '==', -47.625, q{Random location 586 longitude};

( $grid ) = $sta->geodetic( -0.671956099594582, 2.16076044282009, 0 )
    ->maidenhead( 3 );
is $grid, 'PF11vl', q{Random location 587 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PF11vl' ) );
cmp_ok $lat, '==', -38.5208, q{Random location 587 latitude};
cmp_ok $lon, '==', 123.792, q{Random location 587 longitude};

( $grid ) = $sta->geodetic( 0.166136355487091, -0.707755446428645, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ99rm', q{Random location 588 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ99rm' ) );
cmp_ok $lat, '==', 9.52083, q{Random location 588 latitude};
cmp_ok $lon, '==', -40.5417, q{Random location 588 longitude};

( $grid ) = $sta->geodetic( 0.31327032394131, -2.82540978657961, 0 )
    ->maidenhead( 3 );
is $grid, 'AK97bw', q{Random location 589 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AK97bw' ) );
cmp_ok $lat, '==', 17.9375, q{Random location 589 latitude};
cmp_ok $lon, '==', -161.875, q{Random location 589 longitude};

( $grid ) = $sta->geodetic( 0.455440846057442, -1.02159724284839, 0 )
    ->maidenhead( 3 );
is $grid, 'GL06rc', q{Random location 590 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GL06rc' ) );
cmp_ok $lat, '==', 26.1042, q{Random location 590 latitude};
cmp_ok $lon, '==', -58.5417, q{Random location 590 longitude};

( $grid ) = $sta->geodetic( -0.339537375417421, 2.64606046439268, 0 )
    ->maidenhead( 3 );
is $grid, 'QH50tn', q{Random location 591 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QH50tn' ) );
cmp_ok $lat, '==', -19.4375, q{Random location 591 latitude};
cmp_ok $lon, '==', 151.625, q{Random location 591 longitude};

( $grid ) = $sta->geodetic( -1.35494239080886, -1.74017172931067, 0 )
    ->maidenhead( 3 );
is $grid, 'EB02di', q{Random location 592 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EB02di' ) );
cmp_ok $lat, '==', -77.6458, q{Random location 592 latitude};
cmp_ok $lon, '==', -99.7083, q{Random location 592 longitude};

( $grid ) = $sta->geodetic( 0.801244259153821, -0.278891992107525, 0 )
    ->maidenhead( 3 );
is $grid, 'IN25av', q{Random location 593 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IN25av' ) );
cmp_ok $lat, '==', 45.8958, q{Random location 593 latitude};
cmp_ok $lon, '==', -15.9583, q{Random location 593 longitude};

( $grid ) = $sta->geodetic( -0.22160821138796, 1.63733639129893, 0 )
    ->maidenhead( 3 );
is $grid, 'NH67vh', q{Random location 594 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NH67vh' ) );
cmp_ok $lat, '==', -12.6875, q{Random location 594 latitude};
cmp_ok $lon, '==', 93.7917, q{Random location 594 longitude};

( $grid ) = $sta->geodetic( 0.122190553808416, -0.0995675763857293, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ77da', q{Random location 595 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ77da' ) );
cmp_ok $lat, '==', 7.02083, q{Random location 595 latitude};
cmp_ok $lon, '==', -5.70833, q{Random location 595 longitude};

( $grid ) = $sta->geodetic( -0.616444187434618, -0.624847840107987, 0 )
    ->maidenhead( 3 );
is $grid, 'HF24cq', q{Random location 596 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF24cq' ) );
cmp_ok $lat, '==', -35.3125, q{Random location 596 latitude};
cmp_ok $lon, '==', -35.7917, q{Random location 596 longitude};

( $grid ) = $sta->geodetic( 1.05237560608833, 2.73869081145586, 0 )
    ->maidenhead( 3 );
is $grid, 'QP80kh', q{Random location 597 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP80kh' ) );
cmp_ok $lat, '==', 60.3125, q{Random location 597 latitude};
cmp_ok $lon, '==', 156.875, q{Random location 597 longitude};

( $grid ) = $sta->geodetic( 1.11893296786982, 0.807498324998467, 0 )
    ->maidenhead( 3 );
is $grid, 'LP34dc', q{Random location 598 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LP34dc' ) );
cmp_ok $lat, '==', 64.1042, q{Random location 598 latitude};
cmp_ok $lon, '==', 46.2917, q{Random location 598 longitude};

( $grid ) = $sta->geodetic( 0.0849506976641043, -1.77352927015922, 0 )
    ->maidenhead( 3 );
is $grid, 'DJ94eu', q{Random location 599 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DJ94eu' ) );
cmp_ok $lat, '==', 4.85417, q{Random location 599 latitude};
cmp_ok $lon, '==', -101.625, q{Random location 599 longitude};

( $grid ) = $sta->geodetic( -0.192146619281054, -0.204883338312039, 0 )
    ->maidenhead( 3 );
is $grid, 'IH48dx', q{Random location 600 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH48dx' ) );
cmp_ok $lat, '==', -11.0208, q{Random location 600 latitude};
cmp_ok $lon, '==', -11.7083, q{Random location 600 longitude};

( $grid ) = $sta->geodetic( 0.632549245683272, 2.96878862974947, 0 )
    ->maidenhead( 3 );
is $grid, 'RM56bf', q{Random location 601 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM56bf' ) );
cmp_ok $lat, '==', 36.2292, q{Random location 601 latitude};
cmp_ok $lon, '==', 170.125, q{Random location 601 longitude};

( $grid ) = $sta->geodetic( -0.894752233378625, -1.25983402449464, 0 )
    ->maidenhead( 3 );
is $grid, 'FD38vr', q{Random location 602 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FD38vr' ) );
cmp_ok $lat, '==', -51.2708, q{Random location 602 latitude};
cmp_ok $lon, '==', -72.2083, q{Random location 602 longitude};

( $grid ) = $sta->geodetic( 0.0712186128732553, 0.59285946582313, 0 )
    ->maidenhead( 3 );
is $grid, 'KJ64xb', q{Random location 603 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KJ64xb' ) );
cmp_ok $lat, '==', 4.0625, q{Random location 603 latitude};
cmp_ok $lon, '==', 33.9583, q{Random location 603 longitude};

( $grid ) = $sta->geodetic( -0.377694063487406, 2.05229203378248, 0 )
    ->maidenhead( 3 );
is $grid, 'OG88ti', q{Random location 604 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OG88ti' ) );
cmp_ok $lat, '==', -21.6458, q{Random location 604 latitude};
cmp_ok $lon, '==', 117.625, q{Random location 604 longitude};

( $grid ) = $sta->geodetic( 0.0227914028886806, -0.840148976434647, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ51wh', q{Random location 605 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ51wh' ) );
cmp_ok $lat, '==', 1.3125, q{Random location 605 latitude};
cmp_ok $lon, '==', -48.125, q{Random location 605 longitude};

( $grid ) = $sta->geodetic( 0.293888721421137, 0.760997158095714, 0 )
    ->maidenhead( 3 );
is $grid, 'LK16tu', q{Random location 606 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LK16tu' ) );
cmp_ok $lat, '==', 16.8542, q{Random location 606 latitude};
cmp_ok $lon, '==', 43.625, q{Random location 606 longitude};

( $grid ) = $sta->geodetic( -0.59796590155496, 1.02131430834299, 0 )
    ->maidenhead( 3 );
is $grid, 'LF95gr', q{Random location 607 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF95gr' ) );
cmp_ok $lat, '==', -34.2708, q{Random location 607 latitude};
cmp_ok $lon, '==', 58.5417, q{Random location 607 longitude};

( $grid ) = $sta->geodetic( 0.0178339425043588, -0.869372294606765, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ51ca', q{Random location 608 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ51ca' ) );
cmp_ok $lat, '==', 1.02083, q{Random location 608 latitude};
cmp_ok $lon, '==', -49.7917, q{Random location 608 longitude};

( $grid ) = $sta->geodetic( 0.984945645180436, -1.14296664095282, 0 )
    ->maidenhead( 3 );
is $grid, 'FO76gk', q{Random location 609 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FO76gk' ) );
cmp_ok $lat, '==', 56.4375, q{Random location 609 latitude};
cmp_ok $lon, '==', -65.4583, q{Random location 609 longitude};

( $grid ) = $sta->geodetic( 0.154602780877299, -0.266363834827478, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ28iu', q{Random location 610 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ28iu' ) );
cmp_ok $lat, '==', 8.85417, q{Random location 610 latitude};
cmp_ok $lon, '==', -15.2917, q{Random location 610 longitude};

( $grid ) = $sta->geodetic( 0.188639905383143, 0.0324255182571846, 0 )
    ->maidenhead( 3 );
is $grid, 'JK00wt', q{Random location 611 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK00wt' ) );
cmp_ok $lat, '==', 10.8125, q{Random location 611 latitude};
cmp_ok $lon, '==', 1.875, q{Random location 611 longitude};

( $grid ) = $sta->geodetic( -1.43224363407342, -0.340680767648085, 0 )
    ->maidenhead( 3 );
is $grid, 'IA07fw', q{Random location 612 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IA07fw' ) );
cmp_ok $lat, '==', -82.0625, q{Random location 612 latitude};
cmp_ok $lon, '==', -19.5417, q{Random location 612 longitude};

( $grid ) = $sta->geodetic( 0.0592796813945484, 0.267980956033897, 0 )
    ->maidenhead( 3 );
is $grid, 'JJ73qj', q{Random location 613 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JJ73qj' ) );
cmp_ok $lat, '==', 3.39583, q{Random location 613 latitude};
cmp_ok $lon, '==', 15.375, q{Random location 613 longitude};

( $grid ) = $sta->geodetic( -0.813469436124593, 1.80509774756797, 0 )
    ->maidenhead( 3 );
is $grid, 'OE13rj', q{Random location 614 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OE13rj' ) );
cmp_ok $lat, '==', -46.6042, q{Random location 614 latitude};
cmp_ok $lon, '==', 103.458, q{Random location 614 longitude};

( $grid ) = $sta->geodetic( 0.352516187973152, -1.3946743518619, 0 )
    ->maidenhead( 3 );
is $grid, 'FL00be', q{Random location 615 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FL00be' ) );
cmp_ok $lat, '==', 20.1875, q{Random location 615 latitude};
cmp_ok $lon, '==', -79.875, q{Random location 615 longitude};

( $grid ) = $sta->geodetic( 0.539302372435075, 0.851769515692778, 0 )
    ->maidenhead( 3 );
is $grid, 'LM40jv', q{Random location 616 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM40jv' ) );
cmp_ok $lat, '==', 30.8958, q{Random location 616 latitude};
cmp_ok $lon, '==', 48.7917, q{Random location 616 longitude};

( $grid ) = $sta->geodetic( -0.637325144409349, 0.456714986193993, 0 )
    ->maidenhead( 3 );
is $grid, 'KF33cl', q{Random location 617 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KF33cl' ) );
cmp_ok $lat, '==', -36.5208, q{Random location 617 latitude};
cmp_ok $lon, '==', 26.2083, q{Random location 617 longitude};

( $grid ) = $sta->geodetic( -0.0817748129060838, 1.9465065561412, 0 )
    ->maidenhead( 3 );
is $grid, 'OI55sh', q{Random location 618 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI55sh' ) );
cmp_ok $lat, '==', -4.6875, q{Random location 618 latitude};
cmp_ok $lon, '==', 111.542, q{Random location 618 longitude};

( $grid ) = $sta->geodetic( -0.548042026570544, -2.80922467368193, 0 )
    ->maidenhead( 3 );
is $grid, 'AF98mo', q{Random location 619 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AF98mo' ) );
cmp_ok $lat, '==', -31.3958, q{Random location 619 latitude};
cmp_ok $lon, '==', -160.958, q{Random location 619 longitude};

( $grid ) = $sta->geodetic( 0.977672931015606, 1.63672219404274, 0 )
    ->maidenhead( 3 );
is $grid, 'NO66va', q{Random location 620 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NO66va' ) );
cmp_ok $lat, '==', 56.0208, q{Random location 620 latitude};
cmp_ok $lon, '==', 93.7917, q{Random location 620 longitude};

( $grid ) = $sta->geodetic( -0.652761723225006, -0.0667552454635656, 0 )
    ->maidenhead( 3 );
is $grid, 'IF82co', q{Random location 621 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IF82co' ) );
cmp_ok $lat, '==', -37.3958, q{Random location 621 latitude};
cmp_ok $lon, '==', -3.79167, q{Random location 621 longitude};

( $grid ) = $sta->geodetic( 0.809860168530253, -1.20590519717877, 0 )
    ->maidenhead( 3 );
is $grid, 'FN56kj', q{Random location 622 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FN56kj' ) );
cmp_ok $lat, '==', 46.3958, q{Random location 622 latitude};
cmp_ok $lon, '==', -69.125, q{Random location 622 longitude};

( $grid ) = $sta->geodetic( 0.363698511378789, 1.77970379312699, 0 )
    ->maidenhead( 3 );
is $grid, 'OL00xu', q{Random location 623 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OL00xu' ) );
cmp_ok $lat, '==', 20.8542, q{Random location 623 latitude};
cmp_ok $lon, '==', 101.958, q{Random location 623 longitude};

( $grid ) = $sta->geodetic( 1.22168479714989, 0.436314628072326, 0 )
    ->maidenhead( 3 );
is $grid, 'KP29lx', q{Random location 624 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KP29lx' ) );
cmp_ok $lat, '==', 69.9792, q{Random location 624 latitude};
cmp_ok $lon, '==', 24.9583, q{Random location 624 longitude};

( $grid ) = $sta->geodetic( -0.576186357587535, 1.10342786952179, 0 )
    ->maidenhead( 3 );
is $grid, 'MF16ox', q{Random location 625 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MF16ox' ) );
cmp_ok $lat, '==', -33.0208, q{Random location 625 latitude};
cmp_ok $lon, '==', 63.2083, q{Random location 625 longitude};

( $grid ) = $sta->geodetic( 0.560214015907313, 2.1821776295763, 0 )
    ->maidenhead( 3 );
is $grid, 'PM22mc', q{Random location 626 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM22mc' ) );
cmp_ok $lat, '==', 32.1042, q{Random location 626 latitude};
cmp_ok $lon, '==', 125.042, q{Random location 626 longitude};

( $grid ) = $sta->geodetic( 0.235784364635587, 0.550866781788928, 0 )
    ->maidenhead( 3 );
is $grid, 'KK53sm', q{Random location 627 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK53sm' ) );
cmp_ok $lat, '==', 13.5208, q{Random location 627 latitude};
cmp_ok $lon, '==', 31.5417, q{Random location 627 longitude};

( $grid ) = $sta->geodetic( 0.925763567139025, 0.444488002526358, 0 )
    ->maidenhead( 3 );
is $grid, 'KO23rb', q{Random location 628 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO23rb' ) );
cmp_ok $lat, '==', 53.0625, q{Random location 628 latitude};
cmp_ok $lon, '==', 25.4583, q{Random location 628 longitude};

( $grid ) = $sta->geodetic( -0.0408090795140428, 2.07490131756048, 0 )
    ->maidenhead( 3 );
is $grid, 'OI97kp', q{Random location 629 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI97kp' ) );
cmp_ok $lat, '==', -2.35417, q{Random location 629 latitude};
cmp_ok $lon, '==', 118.875, q{Random location 629 longitude};

( $grid ) = $sta->geodetic( 0.878402691377532, -1.50215333730828, 0 )
    ->maidenhead( 3 );
is $grid, 'EO60xh', q{Random location 630 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EO60xh' ) );
cmp_ok $lat, '==', 50.3125, q{Random location 630 latitude};
cmp_ok $lon, '==', -86.0417, q{Random location 630 longitude};

( $grid ) = $sta->geodetic( -1.24678439125211, -1.86871854615608, 0 )
    ->maidenhead( 3 );
is $grid, 'DB68ln', q{Random location 631 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DB68ln' ) );
cmp_ok $lat, '==', -71.4375, q{Random location 631 latitude};
cmp_ok $lon, '==', -107.042, q{Random location 631 longitude};

( $grid ) = $sta->geodetic( -0.442414458317941, -1.80947442413001, 0 )
    ->maidenhead( 3 );
is $grid, 'DG84dp', q{Random location 632 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG84dp' ) );
cmp_ok $lat, '==', -25.3542, q{Random location 632 latitude};
cmp_ok $lon, '==', -103.708, q{Random location 632 longitude};

( $grid ) = $sta->geodetic( 0.232914509999576, -0.603460856927462, 0 )
    ->maidenhead( 3 );
is $grid, 'HK23ri', q{Random location 633 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK23ri' ) );
cmp_ok $lat, '==', 13.3542, q{Random location 633 latitude};
cmp_ok $lon, '==', -34.5417, q{Random location 633 longitude};

( $grid ) = $sta->geodetic( -0.567606571093005, -1.42365252179118, 0 )
    ->maidenhead( 3 );
is $grid, 'EF97fl', q{Random location 634 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EF97fl' ) );
cmp_ok $lat, '==', -32.5208, q{Random location 634 latitude};
cmp_ok $lon, '==', -81.5417, q{Random location 634 longitude};

( $grid ) = $sta->geodetic( -0.300109705097675, 2.47938307143649, 0 )
    ->maidenhead( 3 );
is $grid, 'QH12at', q{Random location 635 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QH12at' ) );
cmp_ok $lat, '==', -17.1875, q{Random location 635 latitude};
cmp_ok $lon, '==', 142.042, q{Random location 635 longitude};

( $grid ) = $sta->geodetic( -0.940595001831374, -2.60249131781512, 0 )
    ->maidenhead( 3 );
is $grid, 'BD56kc', q{Random location 636 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BD56kc' ) );
cmp_ok $lat, '==', -53.8958, q{Random location 636 latitude};
cmp_ok $lon, '==', -149.125, q{Random location 636 longitude};

( $grid ) = $sta->geodetic( -0.0718091045229903, 2.02492975959629, 0 )
    ->maidenhead( 3 );
is $grid, 'OI85av', q{Random location 637 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI85av' ) );
cmp_ok $lat, '==', -4.10417, q{Random location 637 latitude};
cmp_ok $lon, '==', 116.042, q{Random location 637 longitude};

( $grid ) = $sta->geodetic( 0.445418354673725, -2.88925327682238, 0 )
    ->maidenhead( 3 );
is $grid, 'AL75fm', q{Random location 638 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AL75fm' ) );
cmp_ok $lat, '==', 25.5208, q{Random location 638 latitude};
cmp_ok $lon, '==', -165.542, q{Random location 638 longitude};

( $grid ) = $sta->geodetic( -0.31227678398834, -0.98849244413971, 0 )
    ->maidenhead( 3 );
is $grid, 'GH12qc', q{Random location 639 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH12qc' ) );
cmp_ok $lat, '==', -17.8958, q{Random location 639 latitude};
cmp_ok $lon, '==', -56.625, q{Random location 639 longitude};

( $grid ) = $sta->geodetic( -0.294448531064472, -0.512784474091302, 0 )
    ->maidenhead( 3 );
is $grid, 'HH53hd', q{Random location 640 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HH53hd' ) );
cmp_ok $lat, '==', -16.8542, q{Random location 640 latitude};
cmp_ok $lon, '==', -29.375, q{Random location 640 longitude};

( $grid ) = $sta->geodetic( -0.450863335288565, -0.970933348045645, 0 )
    ->maidenhead( 3 );
is $grid, 'GG24ee', q{Random location 641 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GG24ee' ) );
cmp_ok $lat, '==', -25.8125, q{Random location 641 latitude};
cmp_ok $lon, '==', -55.625, q{Random location 641 longitude};

( $grid ) = $sta->geodetic( 0.496462818024856, 2.17742226139399, 0 )
    ->maidenhead( 3 );
is $grid, 'PL28jk', q{Random location 642 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL28jk' ) );
cmp_ok $lat, '==', 28.4375, q{Random location 642 latitude};
cmp_ok $lon, '==', 124.792, q{Random location 642 longitude};

( $grid ) = $sta->geodetic( -0.234091844324213, -3.13607753766317, 0 )
    ->maidenhead( 3 );
is $grid, 'AH06do', q{Random location 643 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AH06do' ) );
cmp_ok $lat, '==', -13.3958, q{Random location 643 latitude};
cmp_ok $lon, '==', -179.708, q{Random location 643 longitude};

( $grid ) = $sta->geodetic( -0.326316401801619, 1.26707608066803, 0 )
    ->maidenhead( 3 );
is $grid, 'MH61hh', q{Random location 644 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MH61hh' ) );
cmp_ok $lat, '==', -18.6875, q{Random location 644 latitude};
cmp_ok $lon, '==', 72.625, q{Random location 644 longitude};

( $grid ) = $sta->geodetic( -0.38167844553762, -1.99285080270505, 0 )
    ->maidenhead( 3 );
is $grid, 'DG28vd', q{Random location 645 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG28vd' ) );
cmp_ok $lat, '==', -21.8542, q{Random location 645 latitude};
cmp_ok $lon, '==', -114.208, q{Random location 645 longitude};

( $grid ) = $sta->geodetic( -0.9380726001459, -1.87375118720957, 0 )
    ->maidenhead( 3 );
is $grid, 'DD66hg', q{Random location 646 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DD66hg' ) );
cmp_ok $lat, '==', -53.7292, q{Random location 646 latitude};
cmp_ok $lon, '==', -107.375, q{Random location 646 longitude};

( $grid ) = $sta->geodetic( -0.360258846117077, -1.66353832743282, 0 )
    ->maidenhead( 3 );
is $grid, 'EG29ii', q{Random location 647 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EG29ii' ) );
cmp_ok $lat, '==', -20.6458, q{Random location 647 latitude};
cmp_ok $lon, '==', -95.2917, q{Random location 647 longitude};

( $grid ) = $sta->geodetic( -0.748614517883146, 2.90108399290794, 0 )
    ->maidenhead( 3 );
is $grid, 'RE37cc', q{Random location 648 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RE37cc' ) );
cmp_ok $lat, '==', -42.8958, q{Random location 648 latitude};
cmp_ok $lon, '==', 166.208, q{Random location 648 longitude};

( $grid ) = $sta->geodetic( 0.626913406581138, 0.162638280068787, 0 )
    ->maidenhead( 3 );
is $grid, 'JM45pw', q{Random location 649 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM45pw' ) );
cmp_ok $lat, '==', 35.9375, q{Random location 649 latitude};
cmp_ok $lon, '==', 9.29167, q{Random location 649 longitude};

( $grid ) = $sta->geodetic( 0.696065733369265, -2.59413358171053, 0 )
    ->maidenhead( 3 );
is $grid, 'BM59qv', q{Random location 650 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BM59qv' ) );
cmp_ok $lat, '==', 39.8958, q{Random location 650 latitude};
cmp_ok $lon, '==', -148.625, q{Random location 650 longitude};

( $grid ) = $sta->geodetic( -0.43189968451861, -2.56834094778071, 0 )
    ->maidenhead( 3 );
is $grid, 'BG65kg', q{Random location 651 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BG65kg' ) );
cmp_ok $lat, '==', -24.7292, q{Random location 651 latitude};
cmp_ok $lon, '==', -147.125, q{Random location 651 longitude};

( $grid ) = $sta->geodetic( 0.340042077371704, 2.02920352132397, 0 )
    ->maidenhead( 3 );
is $grid, 'OK89dl', q{Random location 652 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OK89dl' ) );
cmp_ok $lat, '==', 19.4792, q{Random location 652 latitude};
cmp_ok $lon, '==', 116.292, q{Random location 652 longitude};

( $grid ) = $sta->geodetic( 0.0815656307728154, -0.0339967706430286, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ94aq', q{Random location 653 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ94aq' ) );
cmp_ok $lat, '==', 4.6875, q{Random location 653 latitude};
cmp_ok $lon, '==', -1.95833, q{Random location 653 longitude};

( $grid ) = $sta->geodetic( -0.709284169158279, -2.0478399061317, 0 )
    ->maidenhead( 3 );
is $grid, 'DE19ii', q{Random location 654 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DE19ii' ) );
cmp_ok $lat, '==', -40.6458, q{Random location 654 latitude};
cmp_ok $lon, '==', -117.292, q{Random location 654 longitude};

( $grid ) = $sta->geodetic( -0.638312748313589, 2.47192166377552, 0 )
    ->maidenhead( 3 );
is $grid, 'QF03tk', q{Random location 655 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF03tk' ) );
cmp_ok $lat, '==', -36.5625, q{Random location 655 latitude};
cmp_ok $lon, '==', 141.625, q{Random location 655 longitude};

( $grid ) = $sta->geodetic( 0.136950562710261, -1.74298009959056, 0 )
    ->maidenhead( 3 );
is $grid, 'EJ07bu', q{Random location 656 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EJ07bu' ) );
cmp_ok $lat, '==', 7.85417, q{Random location 656 latitude};
cmp_ok $lon, '==', -99.875, q{Random location 656 longitude};

( $grid ) = $sta->geodetic( 0.953809645614771, 0.632583661806324, 0 )
    ->maidenhead( 3 );
is $grid, 'KO84cp', q{Random location 657 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO84cp' ) );
cmp_ok $lat, '==', 54.6458, q{Random location 657 latitude};
cmp_ok $lon, '==', 36.2083, q{Random location 657 longitude};

( $grid ) = $sta->geodetic( -1.15812539475833, -0.535409867821106, 0 )
    ->maidenhead( 3 );
is $grid, 'HC43pp', q{Random location 658 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HC43pp' ) );
cmp_ok $lat, '==', -66.3542, q{Random location 658 latitude};
cmp_ok $lon, '==', -30.7083, q{Random location 658 longitude};

( $grid ) = $sta->geodetic( -0.243934472657342, -3.11259178162073, 0 )
    ->maidenhead( 3 );
is $grid, 'AH06ta', q{Random location 659 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AH06ta' ) );
cmp_ok $lat, '==', -13.9792, q{Random location 659 latitude};
cmp_ok $lon, '==', -178.375, q{Random location 659 longitude};

( $grid ) = $sta->geodetic( -0.242361161172373, -0.890467578747702, 0 )
    ->maidenhead( 3 );
is $grid, 'GH46lc', q{Random location 660 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH46lc' ) );
cmp_ok $lat, '==', -13.8958, q{Random location 660 latitude};
cmp_ok $lon, '==', -51.0417, q{Random location 660 longitude};

( $grid ) = $sta->geodetic( -1.22082672554369, -1.73320949947045, 0 )
    ->maidenhead( 3 );
is $grid, 'EC00ib', q{Random location 661 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EC00ib' ) );
cmp_ok $lat, '==', -69.9375, q{Random location 661 latitude};
cmp_ok $lon, '==', -99.2917, q{Random location 661 longitude};

( $grid ) = $sta->geodetic( -0.600238053671263, 0.159602845759737, 0 )
    ->maidenhead( 3 );
is $grid, 'JF45no', q{Random location 662 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JF45no' ) );
cmp_ok $lat, '==', -34.3958, q{Random location 662 latitude};
cmp_ok $lon, '==', 9.125, q{Random location 662 longitude};

( $grid ) = $sta->geodetic( -0.616403330648515, 3.01177803810651, 0 )
    ->maidenhead( 3 );
is $grid, 'RF64gq', q{Random location 663 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RF64gq' ) );
cmp_ok $lat, '==', -35.3125, q{Random location 663 latitude};
cmp_ok $lon, '==', 172.542, q{Random location 663 longitude};

( $grid ) = $sta->geodetic( -0.0571653536867709, -1.82213941725353, 0 )
    ->maidenhead( 3 );
is $grid, 'DI76tr', q{Random location 664 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DI76tr' ) );
cmp_ok $lat, '==', -3.27083, q{Random location 664 latitude};
cmp_ok $lon, '==', -104.375, q{Random location 664 longitude};

( $grid ) = $sta->geodetic( -0.824398902113403, 1.70626436738344, 0 )
    ->maidenhead( 3 );
is $grid, 'NE82vs', q{Random location 665 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NE82vs' ) );
cmp_ok $lat, '==', -47.2292, q{Random location 665 latitude};
cmp_ok $lon, '==', 97.7917, q{Random location 665 longitude};

( $grid ) = $sta->geodetic( 0.619302585308431, 0.201705356524199, 0 )
    ->maidenhead( 3 );
is $grid, 'JM55sl', q{Random location 666 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM55sl' ) );
cmp_ok $lat, '==', 35.4792, q{Random location 666 latitude};
cmp_ok $lon, '==', 11.5417, q{Random location 666 longitude};

( $grid ) = $sta->geodetic( 0.0920912942027341, -2.92461395910668, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ65fg', q{Random location 667 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ65fg' ) );
cmp_ok $lat, '==', 5.27083, q{Random location 667 latitude};
cmp_ok $lon, '==', -167.542, q{Random location 667 longitude};

( $grid ) = $sta->geodetic( 0.961639377677633, 1.68256041085346, 0 )
    ->maidenhead( 3 );
is $grid, 'NO85ec', q{Random location 668 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NO85ec' ) );
cmp_ok $lat, '==', 55.1042, q{Random location 668 latitude};
cmp_ok $lon, '==', 96.375, q{Random location 668 longitude};

( $grid ) = $sta->geodetic( -1.28574477683082, 0.873181132015801, 0 )
    ->maidenhead( 3 );
is $grid, 'LB56ah', q{Random location 669 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LB56ah' ) );
cmp_ok $lat, '==', -73.6875, q{Random location 669 latitude};
cmp_ok $lon, '==', 50.0417, q{Random location 669 longitude};

( $grid ) = $sta->geodetic( 0.673017707499532, 1.44882197616882, 0 )
    ->maidenhead( 3 );
is $grid, 'NM18mn', q{Random location 670 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM18mn' ) );
cmp_ok $lat, '==', 38.5625, q{Random location 670 latitude};
cmp_ok $lon, '==', 83.0417, q{Random location 670 longitude};

( $grid ) = $sta->geodetic( -0.409272077052409, -1.69325875041523, 0 )
    ->maidenhead( 3 );
is $grid, 'EG16ln', q{Random location 671 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EG16ln' ) );
cmp_ok $lat, '==', -23.4375, q{Random location 671 latitude};
cmp_ok $lon, '==', -97.0417, q{Random location 671 longitude};

( $grid ) = $sta->geodetic( -0.887012317429557, 2.62518550578959, 0 )
    ->maidenhead( 3 );
is $grid, 'QD59ee', q{Random location 672 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QD59ee' ) );
cmp_ok $lat, '==', -50.8125, q{Random location 672 latitude};
cmp_ok $lon, '==', 150.375, q{Random location 672 longitude};

( $grid ) = $sta->geodetic( 0.819577162971123, 2.12217436393029, 0 )
    ->maidenhead( 3 );
is $grid, 'PN06tw', q{Random location 673 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PN06tw' ) );
cmp_ok $lat, '==', 46.9375, q{Random location 673 latitude};
cmp_ok $lon, '==', 121.625, q{Random location 673 longitude};

( $grid ) = $sta->geodetic( 0.601794058574931, -2.37836230038093, 0 )
    ->maidenhead( 3 );
is $grid, 'CM14ul', q{Random location 674 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CM14ul' ) );
cmp_ok $lat, '==', 34.4792, q{Random location 674 latitude};
cmp_ok $lon, '==', -136.292, q{Random location 674 longitude};

( $grid ) = $sta->geodetic( 0.349530786389841, -3.10447867733951, 0 )
    ->maidenhead( 3 );
is $grid, 'AL10ba', q{Random location 675 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AL10ba' ) );
cmp_ok $lat, '==', 20.0208, q{Random location 675 latitude};
cmp_ok $lon, '==', -177.875, q{Random location 675 longitude};

( $grid ) = $sta->geodetic( -0.0959420416405663, 1.83513281087811, 0 )
    ->maidenhead( 3 );
is $grid, 'OI24nm', q{Random location 676 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI24nm' ) );
cmp_ok $lat, '==', -5.47917, q{Random location 676 latitude};
cmp_ok $lon, '==', 105.125, q{Random location 676 longitude};

( $grid ) = $sta->geodetic( 1.31651797294882, -2.14875715978919, 0 )
    ->maidenhead( 3 );
is $grid, 'CQ85kk', q{Random location 677 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CQ85kk' ) );
cmp_ok $lat, '==', 75.4375, q{Random location 677 latitude};
cmp_ok $lon, '==', -123.125, q{Random location 677 longitude};

( $grid ) = $sta->geodetic( -0.676147647303337, 0.799961655800944, 0 )
    ->maidenhead( 3 );
is $grid, 'LF21wg', q{Random location 678 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF21wg' ) );
cmp_ok $lat, '==', -38.7292, q{Random location 678 latitude};
cmp_ok $lon, '==', 45.875, q{Random location 678 longitude};

( $grid ) = $sta->geodetic( -0.356064683597622, 1.52508117179243, 0 )
    ->maidenhead( 3 );
is $grid, 'NG39qo', q{Random location 679 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NG39qo' ) );
cmp_ok $lat, '==', -20.3958, q{Random location 679 latitude};
cmp_ok $lon, '==', 87.375, q{Random location 679 longitude};

( $grid ) = $sta->geodetic( 1.18546878037232, -1.44055035925688, 0 )
    ->maidenhead( 3 );
is $grid, 'EP87rw', q{Random location 680 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EP87rw' ) );
cmp_ok $lat, '==', 67.9375, q{Random location 680 latitude};
cmp_ok $lon, '==', -82.5417, q{Random location 680 longitude};

( $grid ) = $sta->geodetic( -0.115793461530111, -2.87593458286893, 0 )
    ->maidenhead( 3 );
is $grid, 'AI73oi', q{Random location 681 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI73oi' ) );
cmp_ok $lat, '==', -6.64583, q{Random location 681 latitude};
cmp_ok $lon, '==', -164.792, q{Random location 681 longitude};

( $grid ) = $sta->geodetic( -0.355051176077975, -2.06470226028947, 0 )
    ->maidenhead( 3 );
is $grid, 'DG09up', q{Random location 682 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG09up' ) );
cmp_ok $lat, '==', -20.3542, q{Random location 682 latitude};
cmp_ok $lon, '==', -118.292, q{Random location 682 longitude};

( $grid ) = $sta->geodetic( -1.07822533035904, 2.20516375661776, 0 )
    ->maidenhead( 3 );
is $grid, 'PC38ef', q{Random location 683 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PC38ef' ) );
cmp_ok $lat, '==', -61.7708, q{Random location 683 latitude};
cmp_ok $lon, '==', 126.375, q{Random location 683 longitude};

( $grid ) = $sta->geodetic( -0.899285004836457, -1.62684066406994, 0 )
    ->maidenhead( 3 );
is $grid, 'ED38jl', q{Random location 684 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ED38jl' ) );
cmp_ok $lat, '==', -51.5208, q{Random location 684 latitude};
cmp_ok $lon, '==', -93.2083, q{Random location 684 longitude};

( $grid ) = $sta->geodetic( -0.870601768669542, 2.64652102273527, 0 )
    ->maidenhead( 3 );
is $grid, 'QE50tc', q{Random location 685 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QE50tc' ) );
cmp_ok $lat, '==', -49.8958, q{Random location 685 latitude};
cmp_ok $lon, '==', 151.625, q{Random location 685 longitude};

( $grid ) = $sta->geodetic( -0.910910825601741, -3.11686350227116, 0 )
    ->maidenhead( 3 );
is $grid, 'AD07rt', q{Random location 686 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AD07rt' ) );
cmp_ok $lat, '==', -52.1875, q{Random location 686 latitude};
cmp_ok $lon, '==', -178.542, q{Random location 686 longitude};

( $grid ) = $sta->geodetic( 0.110888967992425, -0.269324451544003, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ26gi', q{Random location 687 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ26gi' ) );
cmp_ok $lat, '==', 6.35417, q{Random location 687 latitude};
cmp_ok $lon, '==', -15.4583, q{Random location 687 longitude};

( $grid ) = $sta->geodetic( -0.513396411823025, -2.11440716281148, 0 )
    ->maidenhead( 3 );
is $grid, 'CG90ko', q{Random location 688 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CG90ko' ) );
cmp_ok $lat, '==', -29.3958, q{Random location 688 latitude};
cmp_ok $lon, '==', -121.125, q{Random location 688 longitude};

( $grid ) = $sta->geodetic( -0.706898137860685, 0.77514842501381, 0 )
    ->maidenhead( 3 );
is $grid, 'LE29el', q{Random location 689 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LE29el' ) );
cmp_ok $lat, '==', -40.5208, q{Random location 689 latitude};
cmp_ok $lon, '==', 44.375, q{Random location 689 longitude};

( $grid ) = $sta->geodetic( -0.870197186260216, -0.00866749433695624, 0 )
    ->maidenhead( 3 );
is $grid, 'IE90sd', q{Random location 690 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE90sd' ) );
cmp_ok $lat, '==', -49.8542, q{Random location 690 latitude};
cmp_ok $lon, '==', -0.458333, q{Random location 690 longitude};

( $grid ) = $sta->geodetic( -0.677068786740225, -2.15587802631981, 0 )
    ->maidenhead( 3 );
is $grid, 'CF81fe', q{Random location 691 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF81fe' ) );
cmp_ok $lat, '==', -38.8125, q{Random location 691 latitude};
cmp_ok $lon, '==', -123.542, q{Random location 691 longitude};

( $grid ) = $sta->geodetic( -1.29823806806431, -0.175133152138978, 0 )
    ->maidenhead( 3 );
is $grid, 'IB45xo', q{Random location 692 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IB45xo' ) );
cmp_ok $lat, '==', -74.3958, q{Random location 692 latitude};
cmp_ok $lon, '==', -10.0417, q{Random location 692 longitude};

( $grid ) = $sta->geodetic( 0.860264509848863, 0.709062751373277, 0 )
    ->maidenhead( 3 );
is $grid, 'LN09hg', q{Random location 693 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LN09hg' ) );
cmp_ok $lat, '==', 49.2708, q{Random location 693 latitude};
cmp_ok $lon, '==', 40.625, q{Random location 693 longitude};

( $grid ) = $sta->geodetic( -0.0676717939806373, -3.07841320569018, 0 )
    ->maidenhead( 3 );
is $grid, 'AI16tc', q{Random location 694 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI16tc' ) );
cmp_ok $lat, '==', -3.89583, q{Random location 694 latitude};
cmp_ok $lon, '==', -176.375, q{Random location 694 longitude};

( $grid ) = $sta->geodetic( -0.745256609435002, -0.319556160018787, 0 )
    ->maidenhead( 3 );
is $grid, 'IE07uh', q{Random location 695 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE07uh' ) );
cmp_ok $lat, '==', -42.6875, q{Random location 695 latitude};
cmp_ok $lon, '==', -18.2917, q{Random location 695 longitude};

( $grid ) = $sta->geodetic( -1.36041872159579, -0.959462968046715, 0 )
    ->maidenhead( 3 );
is $grid, 'GB22mb', q{Random location 696 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GB22mb' ) );
cmp_ok $lat, '==', -77.9375, q{Random location 696 latitude};
cmp_ok $lon, '==', -54.9583, q{Random location 696 longitude};

( $grid ) = $sta->geodetic( -0.657223904953105, -1.68911752695121, 0 )
    ->maidenhead( 3 );
is $grid, 'EF12oi', q{Random location 697 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EF12oi' ) );
cmp_ok $lat, '==', -37.6458, q{Random location 697 latitude};
cmp_ok $lon, '==', -96.7917, q{Random location 697 longitude};

( $grid ) = $sta->geodetic( -0.798266721994794, -1.36598458624733, 0 )
    ->maidenhead( 3 );
is $grid, 'FE04ug', q{Random location 698 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FE04ug' ) );
cmp_ok $lat, '==', -45.7292, q{Random location 698 latitude};
cmp_ok $lon, '==', -78.2917, q{Random location 698 longitude};

( $grid ) = $sta->geodetic( 0.564482556758763, -0.579049867220239, 0 )
    ->maidenhead( 3 );
is $grid, 'HM32ji', q{Random location 699 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM32ji' ) );
cmp_ok $lat, '==', 32.3542, q{Random location 699 latitude};
cmp_ok $lon, '==', -33.2083, q{Random location 699 longitude};

( $grid ) = $sta->geodetic( 0.41952154639879, -0.403451618913496, 0 )
    ->maidenhead( 3 );
is $grid, 'HL84ka', q{Random location 700 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HL84ka' ) );
cmp_ok $lat, '==', 24.0208, q{Random location 700 latitude};
cmp_ok $lon, '==', -23.125, q{Random location 700 longitude};

( $grid ) = $sta->geodetic( 0.58953423827605, 2.03681875473209, 0 )
    ->maidenhead( 3 );
is $grid, 'OM83is', q{Random location 701 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OM83is' ) );
cmp_ok $lat, '==', 33.7708, q{Random location 701 latitude};
cmp_ok $lon, '==', 116.708, q{Random location 701 longitude};

( $grid ) = $sta->geodetic( 0.125284328735728, -1.05934942051598, 0 )
    ->maidenhead( 3 );
is $grid, 'FJ97pe', q{Random location 702 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FJ97pe' ) );
cmp_ok $lat, '==', 7.1875, q{Random location 702 latitude};
cmp_ok $lon, '==', -60.7083, q{Random location 702 longitude};

( $grid ) = $sta->geodetic( -1.10183580913264, 2.30432977480564, 0 )
    ->maidenhead( 3 );
is $grid, 'PC66au', q{Random location 703 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PC66au' ) );
cmp_ok $lat, '==', -63.1458, q{Random location 703 latitude};
cmp_ok $lon, '==', 132.042, q{Random location 703 longitude};

( $grid ) = $sta->geodetic( -0.633176547468532, -2.08917886999682, 0 )
    ->maidenhead( 3 );
is $grid, 'DF03dr', q{Random location 704 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DF03dr' ) );
cmp_ok $lat, '==', -36.2708, q{Random location 704 latitude};
cmp_ok $lon, '==', -119.708, q{Random location 704 longitude};

( $grid ) = $sta->geodetic( 0.355052627482715, 0.753442628052384, 0 )
    ->maidenhead( 3 );
is $grid, 'LL10oi', q{Random location 705 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LL10oi' ) );
cmp_ok $lat, '==', 20.3542, q{Random location 705 latitude};
cmp_ok $lon, '==', 43.2083, q{Random location 705 longitude};

( $grid ) = $sta->geodetic( 1.09352355621294, 1.12183212771645, 0 )
    ->maidenhead( 3 );
is $grid, 'MP22dp', q{Random location 706 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MP22dp' ) );
cmp_ok $lat, '==', 62.6458, q{Random location 706 latitude};
cmp_ok $lon, '==', 64.2917, q{Random location 706 longitude};

( $grid ) = $sta->geodetic( 0.932434413001898, 2.47630329655186, 0 )
    ->maidenhead( 3 );
is $grid, 'QO03wk', q{Random location 707 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QO03wk' ) );
cmp_ok $lat, '==', 53.4375, q{Random location 707 latitude};
cmp_ok $lon, '==', 141.875, q{Random location 707 longitude};

( $grid ) = $sta->geodetic( 0.227125136426731, -0.511026018018655, 0 )
    ->maidenhead( 3 );
is $grid, 'HK53ia', q{Random location 708 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK53ia' ) );
cmp_ok $lat, '==', 13.0208, q{Random location 708 latitude};
cmp_ok $lon, '==', -29.2917, q{Random location 708 longitude};

( $grid ) = $sta->geodetic( -0.266298563964509, -0.0620205520777959, 0 )
    ->maidenhead( 3 );
is $grid, 'IH84fr', q{Random location 709 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH84fr' ) );
cmp_ok $lat, '==', -15.2708, q{Random location 709 latitude};
cmp_ok $lon, '==', -3.54167, q{Random location 709 longitude};

( $grid ) = $sta->geodetic( 0.277679529429906, -1.12932408840713, 0 )
    ->maidenhead( 3 );
is $grid, 'FK75pv', q{Random location 710 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FK75pv' ) );
cmp_ok $lat, '==', 15.8958, q{Random location 710 latitude};
cmp_ok $lon, '==', -64.7083, q{Random location 710 longitude};

( $grid ) = $sta->geodetic( -0.596304968006721, 0.729204528417084, 0 )
    ->maidenhead( 3 );
is $grid, 'LF05vu', q{Random location 711 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF05vu' ) );
cmp_ok $lat, '==', -34.1458, q{Random location 711 latitude};
cmp_ok $lon, '==', 41.7917, q{Random location 711 longitude};

( $grid ) = $sta->geodetic( -0.263020736052918, -0.58976888067763, 0 )
    ->maidenhead( 3 );
is $grid, 'HH34cw', q{Random location 712 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HH34cw' ) );
cmp_ok $lat, '==', -15.0625, q{Random location 712 latitude};
cmp_ok $lon, '==', -33.7917, q{Random location 712 longitude};

( $grid ) = $sta->geodetic( 0.55371639660427, -1.4093646155874, 0 )
    ->maidenhead( 3 );
is $grid, 'EM91or', q{Random location 713 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EM91or' ) );
cmp_ok $lat, '==', 31.7292, q{Random location 713 latitude};
cmp_ok $lon, '==', -80.7917, q{Random location 713 longitude};

( $grid ) = $sta->geodetic( -0.343290096874763, 2.04613367854074, 0 )
    ->maidenhead( 3 );
is $grid, 'OH80oh', q{Random location 714 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OH80oh' ) );
cmp_ok $lat, '==', -19.6875, q{Random location 714 latitude};
cmp_ok $lon, '==', 117.208, q{Random location 714 longitude};

( $grid ) = $sta->geodetic( 0.679047157798008, 0.0683553650698809, 0 )
    ->maidenhead( 3 );
is $grid, 'JM18wv', q{Random location 715 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM18wv' ) );
cmp_ok $lat, '==', 38.8958, q{Random location 715 latitude};
cmp_ok $lon, '==', 3.875, q{Random location 715 longitude};

( $grid ) = $sta->geodetic( 0.184721417912897, 2.27379255181885, 0 )
    ->maidenhead( 3 );
is $grid, 'PK50do', q{Random location 716 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK50do' ) );
cmp_ok $lat, '==', 10.6042, q{Random location 716 latitude};
cmp_ok $lon, '==', 130.292, q{Random location 716 longitude};

( $grid ) = $sta->geodetic( -0.804724315317212, -1.97484009741224, 0 )
    ->maidenhead( 3 );
is $grid, 'DE33kv', q{Random location 717 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DE33kv' ) );
cmp_ok $lat, '==', -46.1042, q{Random location 717 latitude};
cmp_ok $lon, '==', -113.125, q{Random location 717 longitude};

( $grid ) = $sta->geodetic( -0.712505631377167, 0.144569412496542, 0 )
    ->maidenhead( 3 );
is $grid, 'JE49de', q{Random location 718 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JE49de' ) );
cmp_ok $lat, '==', -40.8125, q{Random location 718 latitude};
cmp_ok $lon, '==', 8.29167, q{Random location 718 longitude};

( $grid ) = $sta->geodetic( -0.147054786050386, -2.25210613519268, 0 )
    ->maidenhead( 3 );
is $grid, 'CI51ln', q{Random location 719 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI51ln' ) );
cmp_ok $lat, '==', -8.4375, q{Random location 719 latitude};
cmp_ok $lon, '==', -129.042, q{Random location 719 longitude};

( $grid ) = $sta->geodetic( 0.65318241011815, 1.46763523007931, 0 )
    ->maidenhead( 3 );
is $grid, 'NM27bk', q{Random location 720 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM27bk' ) );
cmp_ok $lat, '==', 37.4375, q{Random location 720 latitude};
cmp_ok $lon, '==', 84.125, q{Random location 720 longitude};

( $grid ) = $sta->geodetic( -0.409242349590209, 2.45031604808213, 0 )
    ->maidenhead( 3 );
is $grid, 'QG06en', q{Random location 721 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG06en' ) );
cmp_ok $lat, '==', -23.4375, q{Random location 721 latitude};
cmp_ok $lon, '==', 140.375, q{Random location 721 longitude};

( $grid ) = $sta->geodetic( -0.428419817997147, 1.99010126521761, 0 )
    ->maidenhead( 3 );
is $grid, 'OG75ak', q{Random location 722 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OG75ak' ) );
cmp_ok $lat, '==', -24.5625, q{Random location 722 latitude};
cmp_ok $lon, '==', 114.042, q{Random location 722 longitude};

( $grid ) = $sta->geodetic( -0.101519372244989, 2.63502799399904, 0 )
    ->maidenhead( 3 );
is $grid, 'QI54le', q{Random location 723 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI54le' ) );
cmp_ok $lat, '==', -5.8125, q{Random location 723 latitude};
cmp_ok $lon, '==', 150.958, q{Random location 723 longitude};

( $grid ) = $sta->geodetic( 0.561433197821769, 2.41420043156527, 0 )
    ->maidenhead( 3 );
is $grid, 'PM92de', q{Random location 724 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PM92de' ) );
cmp_ok $lat, '==', 32.1875, q{Random location 724 latitude};
cmp_ok $lon, '==', 138.292, q{Random location 724 longitude};

( $grid ) = $sta->geodetic( 0.541371057799816, -1.15182323131018, 0 )
    ->maidenhead( 3 );
is $grid, 'FM71aa', q{Random location 725 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FM71aa' ) );
cmp_ok $lat, '==', 31.0208, q{Random location 725 latitude};
cmp_ok $lon, '==', -65.9583, q{Random location 725 longitude};

( $grid ) = $sta->geodetic( -1.00474309365408, -1.28171188161539, 0 )
    ->maidenhead( 3 );
is $grid, 'FD32gk', q{Random location 726 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FD32gk' ) );
cmp_ok $lat, '==', -57.5625, q{Random location 726 latitude};
cmp_ok $lon, '==', -73.4583, q{Random location 726 longitude};

( $grid ) = $sta->geodetic( 1.17184753445453, 2.50621705884817, 0 )
    ->maidenhead( 3 );
is $grid, 'QP17td', q{Random location 727 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP17td' ) );
cmp_ok $lat, '==', 67.1458, q{Random location 727 latitude};
cmp_ok $lon, '==', 143.625, q{Random location 727 longitude};

( $grid ) = $sta->geodetic( -0.684614960227095, 0.144253961326466, 0 )
    ->maidenhead( 3 );
is $grid, 'JF40ds', q{Random location 728 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JF40ds' ) );
cmp_ok $lat, '==', -39.2292, q{Random location 728 latitude};
cmp_ok $lon, '==', 8.29167, q{Random location 728 longitude};

( $grid ) = $sta->geodetic( -0.81782127478146, 2.13059616134302, 0 )
    ->maidenhead( 3 );
is $grid, 'PE13ad', q{Random location 729 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PE13ad' ) );
cmp_ok $lat, '==', -46.8542, q{Random location 729 latitude};
cmp_ok $lon, '==', 122.042, q{Random location 729 longitude};

( $grid ) = $sta->geodetic( 0.353502388596901, -0.340569194996082, 0 )
    ->maidenhead( 3 );
is $grid, 'IL00fg', q{Random location 730 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL00fg' ) );
cmp_ok $lat, '==', 20.2708, q{Random location 730 latitude};
cmp_ok $lon, '==', -19.5417, q{Random location 730 longitude};

( $grid ) = $sta->geodetic( 1.03879759390553, 1.84176055751514, 0 )
    ->maidenhead( 3 );
is $grid, 'OO29sm', q{Random location 731 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OO29sm' ) );
cmp_ok $lat, '==', 59.5208, q{Random location 731 latitude};
cmp_ok $lon, '==', 105.542, q{Random location 731 longitude};

( $grid ) = $sta->geodetic( -1.08631227981775, -0.698236513543311, 0 )
    ->maidenhead( 3 );
is $grid, 'GC97xs', q{Random location 732 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GC97xs' ) );
cmp_ok $lat, '==', -62.2292, q{Random location 732 latitude};
cmp_ok $lon, '==', -40.0417, q{Random location 732 longitude};

( $grid ) = $sta->geodetic( 0.787314502293722, -0.0605961414500187, 0 )
    ->maidenhead( 3 );
is $grid, 'IN85gc', q{Random location 733 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IN85gc' ) );
cmp_ok $lat, '==', 45.1042, q{Random location 733 latitude};
cmp_ok $lon, '==', -3.45833, q{Random location 733 longitude};

( $grid ) = $sta->geodetic( 0.370023723236608, -0.305212982196296, 0 )
    ->maidenhead( 3 );
is $grid, 'IL11ge', q{Random location 734 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL11ge' ) );
cmp_ok $lat, '==', 21.1875, q{Random location 734 latitude};
cmp_ok $lon, '==', -17.4583, q{Random location 734 longitude};

( $grid ) = $sta->geodetic( 0.52579882898819, -0.832351719230355, 0 )
    ->maidenhead( 3 );
is $grid, 'GM60dd', q{Random location 735 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GM60dd' ) );
cmp_ok $lat, '==', 30.1458, q{Random location 735 latitude};
cmp_ok $lon, '==', -47.7083, q{Random location 735 longitude};

( $grid ) = $sta->geodetic( -0.570722347102839, -2.94464725369877, 0 )
    ->maidenhead( 3 );
is $grid, 'AF57ph', q{Random location 736 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AF57ph' ) );
cmp_ok $lat, '==', -32.6875, q{Random location 736 latitude};
cmp_ok $lon, '==', -168.708, q{Random location 736 longitude};

( $grid ) = $sta->geodetic( 0.238171911274973, -2.64062393569917, 0 )
    ->maidenhead( 3 );
is $grid, 'BK43ip', q{Random location 737 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK43ip' ) );
cmp_ok $lat, '==', 13.6458, q{Random location 737 latitude};
cmp_ok $lon, '==', -151.292, q{Random location 737 longitude};

( $grid ) = $sta->geodetic( 0.976383760255109, 1.88427715774519, 0 )
    ->maidenhead( 3 );
is $grid, 'OO35xw', q{Random location 738 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OO35xw' ) );
cmp_ok $lat, '==', 55.9375, q{Random location 738 latitude};
cmp_ok $lon, '==', 107.958, q{Random location 738 longitude};

( $grid ) = $sta->geodetic( 0.302094804588817, -2.37646385584287, 0 )
    ->maidenhead( 3 );
is $grid, 'CK17wh', q{Random location 739 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK17wh' ) );
cmp_ok $lat, '==', 17.3125, q{Random location 739 latitude};
cmp_ok $lon, '==', -136.125, q{Random location 739 longitude};

( $grid ) = $sta->geodetic( -0.361871000134315, 2.40340801046404, 0 )
    ->maidenhead( 3 );
is $grid, 'PG89ug', q{Random location 740 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PG89ug' ) );
cmp_ok $lat, '==', -20.7292, q{Random location 740 latitude};
cmp_ok $lon, '==', 137.708, q{Random location 740 longitude};

( $grid ) = $sta->geodetic( -0.380035529649534, 0.634192280199773, 0 )
    ->maidenhead( 3 );
is $grid, 'KG88ef', q{Random location 741 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KG88ef' ) );
cmp_ok $lat, '==', -21.7708, q{Random location 741 latitude};
cmp_ok $lon, '==', 36.375, q{Random location 741 longitude};

( $grid ) = $sta->geodetic( -0.613464284996834, -2.36097516437103, 0 )
    ->maidenhead( 3 );
is $grid, 'CF24iu', q{Random location 742 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF24iu' ) );
cmp_ok $lat, '==', -35.1458, q{Random location 742 latitude};
cmp_ok $lon, '==', -135.292, q{Random location 742 longitude};

( $grid ) = $sta->geodetic( -1.14788643088366, 1.26652828712697, 0 )
    ->maidenhead( 3 );
is $grid, 'MC64gf', q{Random location 743 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MC64gf' ) );
cmp_ok $lat, '==', -65.7708, q{Random location 743 latitude};
cmp_ok $lon, '==', 72.5417, q{Random location 743 longitude};

( $grid ) = $sta->geodetic( 0.532644706670261, -1.87467333863007, 0 )
    ->maidenhead( 3 );
is $grid, 'DM60hm', q{Random location 744 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DM60hm' ) );
cmp_ok $lat, '==', 30.5208, q{Random location 744 latitude};
cmp_ok $lon, '==', -107.375, q{Random location 744 longitude};

( $grid ) = $sta->geodetic( 0.220093412685716, -2.38306357850183, 0 )
    ->maidenhead( 3 );
is $grid, 'CK12ro', q{Random location 745 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CK12ro' ) );
cmp_ok $lat, '==', 12.6042, q{Random location 745 latitude};
cmp_ok $lon, '==', -136.542, q{Random location 745 longitude};

( $grid ) = $sta->geodetic( 0.859605387358486, -3.06817063925243, 0 )
    ->maidenhead( 3 );
is $grid, 'AN29cg', q{Random location 746 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AN29cg' ) );
cmp_ok $lat, '==', 49.2708, q{Random location 746 latitude};
cmp_ok $lon, '==', -175.792, q{Random location 746 longitude};

( $grid ) = $sta->geodetic( -0.0273361591760608, 1.85555976365104, 0 )
    ->maidenhead( 3 );
is $grid, 'OI38dk', q{Random location 747 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI38dk' ) );
cmp_ok $lat, '==', -1.5625, q{Random location 747 latitude};
cmp_ok $lon, '==', 106.292, q{Random location 747 longitude};

( $grid ) = $sta->geodetic( 0.755725382803608, -0.716607902453257, 0 )
    ->maidenhead( 3 );
is $grid, 'GN93lh', q{Random location 748 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GN93lh' ) );
cmp_ok $lat, '==', 43.3125, q{Random location 748 latitude};
cmp_ok $lon, '==', -41.0417, q{Random location 748 longitude};

( $grid ) = $sta->geodetic( 0.549389852162999, -0.533103894842406, 0 )
    ->maidenhead( 3 );
is $grid, 'HM41rl', q{Random location 749 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HM41rl' ) );
cmp_ok $lat, '==', 31.4792, q{Random location 749 latitude};
cmp_ok $lon, '==', -30.5417, q{Random location 749 longitude};

( $grid ) = $sta->geodetic( -0.687107633057276, -1.24431098636833, 0 )
    ->maidenhead( 3 );
is $grid, 'FF40ip', q{Random location 750 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF40ip' ) );
cmp_ok $lat, '==', -39.3542, q{Random location 750 latitude};
cmp_ok $lon, '==', -71.2917, q{Random location 750 longitude};

( $grid ) = $sta->geodetic( 0.00273445690773633, -0.844529462361522, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ50td', q{Random location 751 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ50td' ) );
cmp_ok $lat, '==', 0.145833, q{Random location 751 latitude};
cmp_ok $lon, '==', -48.375, q{Random location 751 longitude};

( $grid ) = $sta->geodetic( -0.629196736728999, 0.559128217631293, 0 )
    ->maidenhead( 3 );
is $grid, 'KF63aw', q{Random location 752 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KF63aw' ) );
cmp_ok $lat, '==', -36.0625, q{Random location 752 latitude};
cmp_ok $lon, '==', 32.0417, q{Random location 752 longitude};

( $grid ) = $sta->geodetic( -1.09800564909638, 3.02345439806493, 0 )
    ->maidenhead( 3 );
is $grid, 'RC67oc', q{Random location 753 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RC67oc' ) );
cmp_ok $lat, '==', -62.8958, q{Random location 753 latitude};
cmp_ok $lon, '==', 173.208, q{Random location 753 longitude};

( $grid ) = $sta->geodetic( 0.14597795991912, 1.50250252414572, 0 )
    ->maidenhead( 3 );
is $grid, 'NJ38bi', q{Random location 754 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NJ38bi' ) );
cmp_ok $lat, '==', 8.35417, q{Random location 754 latitude};
cmp_ok $lon, '==', 86.125, q{Random location 754 longitude};

( $grid ) = $sta->geodetic( -0.103556757475795, 2.77281964851311, 0 )
    ->maidenhead( 3 );
is $grid, 'QI94kb', q{Random location 755 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI94kb' ) );
cmp_ok $lat, '==', -5.9375, q{Random location 755 latitude};
cmp_ok $lon, '==', 158.875, q{Random location 755 longitude};

( $grid ) = $sta->geodetic( 0.282071088381743, -2.73405778865851, 0 )
    ->maidenhead( 3 );
is $grid, 'BK16qd', q{Random location 756 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK16qd' ) );
cmp_ok $lat, '==', 16.1458, q{Random location 756 latitude};
cmp_ok $lon, '==', -156.625, q{Random location 756 longitude};

( $grid ) = $sta->geodetic( 0.377422757834438, 1.21295272562756, 0 )
    ->maidenhead( 3 );
is $grid, 'ML41ro', q{Random location 757 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML41ro' ) );
cmp_ok $lat, '==', 21.6042, q{Random location 757 latitude};
cmp_ok $lon, '==', 69.4583, q{Random location 757 longitude};

( $grid ) = $sta->geodetic( 0.722763465692463, 1.30927917842083, 0 )
    ->maidenhead( 3 );
is $grid, 'MN71mj', q{Random location 758 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MN71mj' ) );
cmp_ok $lat, '==', 41.3958, q{Random location 758 latitude};
cmp_ok $lon, '==', 75.0417, q{Random location 758 longitude};

( $grid ) = $sta->geodetic( -0.284108103196452, -0.91910877079443, 0 )
    ->maidenhead( 3 );
is $grid, 'GH33qr', q{Random location 759 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH33qr' ) );
cmp_ok $lat, '==', -16.2708, q{Random location 759 latitude};
cmp_ok $lon, '==', -52.625, q{Random location 759 longitude};

( $grid ) = $sta->geodetic( 0.142922684893344, -2.10028786311133, 0 )
    ->maidenhead( 3 );
is $grid, 'CJ98te', q{Random location 760 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CJ98te' ) );
cmp_ok $lat, '==', 8.1875, q{Random location 760 latitude};
cmp_ok $lon, '==', -120.375, q{Random location 760 longitude};

( $grid ) = $sta->geodetic( 1.21542739075409, -1.28633758184406, 0 )
    ->maidenhead( 3 );
is $grid, 'FP39dp', q{Random location 761 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FP39dp' ) );
cmp_ok $lat, '==', 69.6458, q{Random location 761 latitude};
cmp_ok $lon, '==', -73.7083, q{Random location 761 longitude};

( $grid ) = $sta->geodetic( -0.416612724014314, -1.95618107393147, 0 )
    ->maidenhead( 3 );
is $grid, 'DG36xd', q{Random location 762 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DG36xd' ) );
cmp_ok $lat, '==', -23.8542, q{Random location 762 latitude};
cmp_ok $lon, '==', -112.042, q{Random location 762 longitude};

( $grid ) = $sta->geodetic( 0.414456050708731, 1.49326500462654, 0 )
    ->maidenhead( 3 );
is $grid, 'NL23sr', q{Random location 763 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL23sr' ) );
cmp_ok $lat, '==', 23.7292, q{Random location 763 latitude};
cmp_ok $lon, '==', 85.5417, q{Random location 763 longitude};

( $grid ) = $sta->geodetic( 0.787009643229278, -0.252376275456182, 0 )
    ->maidenhead( 3 );
is $grid, 'IN25sc', q{Random location 764 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IN25sc' ) );
cmp_ok $lat, '==', 45.1042, q{Random location 764 latitude};
cmp_ok $lon, '==', -14.4583, q{Random location 764 longitude};

( $grid ) = $sta->geodetic( -0.164766982673202, -2.33040438170688, 0 )
    ->maidenhead( 3 );
is $grid, 'CI30fn', q{Random location 765 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI30fn' ) );
cmp_ok $lat, '==', -9.4375, q{Random location 765 latitude};
cmp_ok $lon, '==', -133.542, q{Random location 765 longitude};

( $grid ) = $sta->geodetic( 0.105533653603962, 3.03343208664183, 0 )
    ->maidenhead( 3 );
is $grid, 'RJ66vb', q{Random location 766 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RJ66vb' ) );
cmp_ok $lat, '==', 6.0625, q{Random location 766 latitude};
cmp_ok $lon, '==', 173.792, q{Random location 766 longitude};

( $grid ) = $sta->geodetic( -1.15361020083358, 2.13301186316411, 0 )
    ->maidenhead( 3 );
is $grid, 'PC13cv', q{Random location 767 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PC13cv' ) );
cmp_ok $lat, '==', -66.1042, q{Random location 767 latitude};
cmp_ok $lon, '==', 122.208, q{Random location 767 longitude};

( $grid ) = $sta->geodetic( -0.577122670346371, -3.08714450258258, 0 )
    ->maidenhead( 3 );
is $grid, 'AF16nw', q{Random location 768 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AF16nw' ) );
cmp_ok $lat, '==', -33.0625, q{Random location 768 latitude};
cmp_ok $lon, '==', -176.875, q{Random location 768 longitude};

( $grid ) = $sta->geodetic( -0.222200181347922, 2.97484907240159, 0 )
    ->maidenhead( 3 );
is $grid, 'RH57fg', q{Random location 769 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RH57fg' ) );
cmp_ok $lat, '==', -12.7292, q{Random location 769 latitude};
cmp_ok $lon, '==', 170.458, q{Random location 769 longitude};

( $grid ) = $sta->geodetic( 0.0587646655417133, 1.56026275473188, 0 )
    ->maidenhead( 3 );
is $grid, 'NJ43qi', q{Random location 770 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NJ43qi' ) );
cmp_ok $lat, '==', 3.35417, q{Random location 770 latitude};
cmp_ok $lon, '==', 89.375, q{Random location 770 longitude};

( $grid ) = $sta->geodetic( 0.616736031685638, 1.09227352613656, 0 )
    ->maidenhead( 3 );
is $grid, 'MM15gi', q{Random location 771 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM15gi' ) );
cmp_ok $lat, '==', 35.3542, q{Random location 771 latitude};
cmp_ok $lon, '==', 62.5417, q{Random location 771 longitude};

( $grid ) = $sta->geodetic( -0.71882311276468, -0.349203722679087, 0 )
    ->maidenhead( 3 );
is $grid, 'HE98xt', q{Random location 772 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HE98xt' ) );
cmp_ok $lat, '==', -41.1875, q{Random location 772 latitude};
cmp_ok $lon, '==', -20.0417, q{Random location 772 longitude};

( $grid ) = $sta->geodetic( 0.961942155552999, 0.935909087905876, 0 )
    ->maidenhead( 3 );
is $grid, 'LO65tc', q{Random location 773 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LO65tc' ) );
cmp_ok $lat, '==', 55.1042, q{Random location 773 latitude};
cmp_ok $lon, '==', 53.625, q{Random location 773 longitude};

( $grid ) = $sta->geodetic( 1.37280767125045, -0.96698285794326, 0 )
    ->maidenhead( 3 );
is $grid, 'GQ28hp', q{Random location 774 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GQ28hp' ) );
cmp_ok $lat, '==', 78.6458, q{Random location 774 latitude};
cmp_ok $lon, '==', -55.375, q{Random location 774 longitude};

( $grid ) = $sta->geodetic( -0.288521739021503, -0.917849652923545, 0 )
    ->maidenhead( 3 );
is $grid, 'GH33ql', q{Random location 775 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH33ql' ) );
cmp_ok $lat, '==', -16.5208, q{Random location 775 latitude};
cmp_ok $lon, '==', -52.625, q{Random location 775 longitude};

( $grid ) = $sta->geodetic( -0.896344766629821, -2.37078918850801, 0 )
    ->maidenhead( 3 );
is $grid, 'CD28bp', q{Random location 776 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CD28bp' ) );
cmp_ok $lat, '==', -51.3542, q{Random location 776 latitude};
cmp_ok $lon, '==', -135.875, q{Random location 776 longitude};

( $grid ) = $sta->geodetic( 0.28411487268436, -2.63310237621424, 0 )
    ->maidenhead( 3 );
is $grid, 'BK46ng', q{Random location 777 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK46ng' ) );
cmp_ok $lat, '==', 16.2708, q{Random location 777 latitude};
cmp_ok $lon, '==', -150.875, q{Random location 777 longitude};

( $grid ) = $sta->geodetic( 0.130313175131225, 0.296550004195186, 0 )
    ->maidenhead( 3 );
is $grid, 'JJ87ll', q{Random location 778 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JJ87ll' ) );
cmp_ok $lat, '==', 7.47917, q{Random location 778 latitude};
cmp_ok $lon, '==', 16.9583, q{Random location 778 longitude};

( $grid ) = $sta->geodetic( 0.0682475384152659, -0.107118389347754, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ63wv', q{Random location 779 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ63wv' ) );
cmp_ok $lat, '==', 3.89583, q{Random location 779 latitude};
cmp_ok $lon, '==', -6.125, q{Random location 779 longitude};

( $grid ) = $sta->geodetic( -1.43590764390171, -1.31792255526645, 0 )
    ->maidenhead( 3 );
is $grid, 'FA27fr', q{Random location 780 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FA27fr' ) );
cmp_ok $lat, '==', -82.2708, q{Random location 780 latitude};
cmp_ok $lon, '==', -75.5417, q{Random location 780 longitude};

( $grid ) = $sta->geodetic( 1.34077904724601, 2.1786157537384, 0 )
    ->maidenhead( 3 );
is $grid, 'PQ26jt', q{Random location 781 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PQ26jt' ) );
cmp_ok $lat, '==', 76.8125, q{Random location 781 latitude};
cmp_ok $lon, '==', 124.792, q{Random location 781 longitude};

( $grid ) = $sta->geodetic( -0.676984527250965, -1.91481902227796, 0 )
    ->maidenhead( 3 );
is $grid, 'DF51df', q{Random location 782 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DF51df' ) );
cmp_ok $lat, '==', -38.7708, q{Random location 782 latitude};
cmp_ok $lon, '==', -109.708, q{Random location 782 longitude};

( $grid ) = $sta->geodetic( -0.73072116735344, 2.13524519455204, 0 )
    ->maidenhead( 3 );
is $grid, 'PE18ed', q{Random location 783 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PE18ed' ) );
cmp_ok $lat, '==', -41.8542, q{Random location 783 latitude};
cmp_ok $lon, '==', 122.375, q{Random location 783 longitude};

( $grid ) = $sta->geodetic( -0.414229584743153, 2.54158145266448, 0 )
    ->maidenhead( 3 );
is $grid, 'QG26tg', q{Random location 784 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG26tg' ) );
cmp_ok $lat, '==', -23.7292, q{Random location 784 latitude};
cmp_ok $lon, '==', 145.625, q{Random location 784 longitude};

( $grid ) = $sta->geodetic( 1.15738846376145, 2.15364008355167, 0 )
    ->maidenhead( 3 );
is $grid, 'PP16qh', q{Random location 785 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PP16qh' ) );
cmp_ok $lat, '==', 66.3125, q{Random location 785 latitude};
cmp_ok $lon, '==', 123.375, q{Random location 785 longitude};

( $grid ) = $sta->geodetic( 0.482443794651839, 0.0478200101414834, 0 )
    ->maidenhead( 3 );
is $grid, 'JL17ip', q{Random location 786 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JL17ip' ) );
cmp_ok $lat, '==', 27.6458, q{Random location 786 latitude};
cmp_ok $lon, '==', 2.70833, q{Random location 786 longitude};

( $grid ) = $sta->geodetic( 0.882467247545561, -1.7752506127188, 0 )
    ->maidenhead( 3 );
is $grid, 'DO90dn', q{Random location 787 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DO90dn' ) );
cmp_ok $lat, '==', 50.5625, q{Random location 787 latitude};
cmp_ok $lon, '==', -101.708, q{Random location 787 longitude};

( $grid ) = $sta->geodetic( 1.1082429121484, -0.201318541855565, 0 )
    ->maidenhead( 3 );
is $grid, 'IP43fl', q{Random location 788 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IP43fl' ) );
cmp_ok $lat, '==', 63.4792, q{Random location 788 latitude};
cmp_ok $lon, '==', -11.5417, q{Random location 788 longitude};

( $grid ) = $sta->geodetic( 0.119426586431205, 0.617752077487197, 0 )
    ->maidenhead( 3 );
is $grid, 'KJ76qu', q{Random location 789 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KJ76qu' ) );
cmp_ok $lat, '==', 6.85417, q{Random location 789 latitude};
cmp_ok $lon, '==', 35.375, q{Random location 789 longitude};

( $grid ) = $sta->geodetic( 1.31708874525804, -1.14827837724006, 0 )
    ->maidenhead( 3 );
is $grid, 'FQ75cl', q{Random location 790 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FQ75cl' ) );
cmp_ok $lat, '==', 75.4792, q{Random location 790 latitude};
cmp_ok $lon, '==', -65.7917, q{Random location 790 longitude};

( $grid ) = $sta->geodetic( -0.731713263048166, -2.01272304457145, 0 )
    ->maidenhead( 3 );
is $grid, 'DE28ib', q{Random location 791 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DE28ib' ) );
cmp_ok $lat, '==', -41.9375, q{Random location 791 latitude};
cmp_ok $lon, '==', -115.292, q{Random location 791 longitude};

( $grid ) = $sta->geodetic( 0.863993985808587, -3.13750096601034, 0 )
    ->maidenhead( 3 );
is $grid, 'AN09cm', q{Random location 792 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AN09cm' ) );
cmp_ok $lat, '==', 49.5208, q{Random location 792 latitude};
cmp_ok $lon, '==', -179.792, q{Random location 792 longitude};

( $grid ) = $sta->geodetic( -0.34976099837355, 2.74210881654824, 0 )
    ->maidenhead( 3 );
is $grid, 'QG89nx', q{Random location 793 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG89nx' ) );
cmp_ok $lat, '==', -20.0208, q{Random location 793 latitude};
cmp_ok $lon, '==', 157.125, q{Random location 793 longitude};

( $grid ) = $sta->geodetic( 0.415474323318198, 1.29719177934232, 0 )
    ->maidenhead( 3 );
is $grid, 'ML73dt', q{Random location 794 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML73dt' ) );
cmp_ok $lat, '==', 23.8125, q{Random location 794 latitude};
cmp_ok $lon, '==', 74.2917, q{Random location 794 longitude};

( $grid ) = $sta->geodetic( 0.483043823449625, -1.94029753907969, 0 )
    ->maidenhead( 3 );
is $grid, 'DL47jq', q{Random location 795 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DL47jq' ) );
cmp_ok $lat, '==', 27.6875, q{Random location 795 latitude};
cmp_ok $lon, '==', -111.208, q{Random location 795 longitude};

( $grid ) = $sta->geodetic( 0.399587008826065, -2.74548026146, 0 )
    ->maidenhead( 3 );
is $grid, 'BL12iv', q{Random location 796 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BL12iv' ) );
cmp_ok $lat, '==', 22.8958, q{Random location 796 latitude};
cmp_ok $lon, '==', -157.292, q{Random location 796 longitude};

( $grid ) = $sta->geodetic( 1.25281799783851, -2.29022872917683, 0 )
    ->maidenhead( 3 );
is $grid, 'CQ41js', q{Random location 797 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CQ41js' ) );
cmp_ok $lat, '==', 71.7708, q{Random location 797 latitude};
cmp_ok $lon, '==', -131.208, q{Random location 797 longitude};

( $grid ) = $sta->geodetic( 0.152297622326023, 1.03286055078583, 0 )
    ->maidenhead( 3 );
is $grid, 'LJ98or', q{Random location 798 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LJ98or' ) );
cmp_ok $lat, '==', 8.72917, q{Random location 798 latitude};
cmp_ok $lon, '==', 59.2083, q{Random location 798 longitude};

( $grid ) = $sta->geodetic( -0.72883194551488, -2.86042853429878, 0 )
    ->maidenhead( 3 );
is $grid, 'AE88bf', q{Random location 799 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE88bf' ) );
cmp_ok $lat, '==', -41.7708, q{Random location 799 latitude};
cmp_ok $lon, '==', -163.875, q{Random location 799 longitude};

( $grid ) = $sta->geodetic( 0.373044349608223, 0.397611344675936, 0 )
    ->maidenhead( 3 );
is $grid, 'KL11ji', q{Random location 800 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KL11ji' ) );
cmp_ok $lat, '==', 21.3542, q{Random location 800 latitude};
cmp_ok $lon, '==', 22.7917, q{Random location 800 longitude};

( $grid ) = $sta->geodetic( -0.959525537072294, -0.116258391613125, 0 )
    ->maidenhead( 3 );
is $grid, 'ID65qa', q{Random location 801 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID65qa' ) );
cmp_ok $lat, '==', -54.9792, q{Random location 801 latitude};
cmp_ok $lon, '==', -6.625, q{Random location 801 longitude};

( $grid ) = $sta->geodetic( -0.640592395464155, -2.43747781237358, 0 )
    ->maidenhead( 3 );
is $grid, 'CF03eh', q{Random location 802 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF03eh' ) );
cmp_ok $lat, '==', -36.6875, q{Random location 802 latitude};
cmp_ok $lon, '==', -139.625, q{Random location 802 longitude};

( $grid ) = $sta->geodetic( -0.147773195805647, 1.63522983173892, 0 )
    ->maidenhead( 3 );
is $grid, 'NI61um', q{Random location 803 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NI61um' ) );
cmp_ok $lat, '==', -8.47917, q{Random location 803 latitude};
cmp_ok $lon, '==', 93.7083, q{Random location 803 longitude};

( $grid ) = $sta->geodetic( -0.133469002631757, 2.73511694084672, 0 )
    ->maidenhead( 3 );
is $grid, 'QI82ii', q{Random location 804 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI82ii' ) );
cmp_ok $lat, '==', -7.64583, q{Random location 804 latitude};
cmp_ok $lon, '==', 156.708, q{Random location 804 longitude};

( $grid ) = $sta->geodetic( -0.0890309651688082, -2.41032868728751, 0 )
    ->maidenhead( 3 );
is $grid, 'CI04wv', q{Random location 805 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CI04wv' ) );
cmp_ok $lat, '==', -5.10417, q{Random location 805 latitude};
cmp_ok $lon, '==', -138.125, q{Random location 805 longitude};

( $grid ) = $sta->geodetic( 0.888113601934186, 2.39957109025743, 0 )
    ->maidenhead( 3 );
is $grid, 'PO80rv', q{Random location 806 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PO80rv' ) );
cmp_ok $lat, '==', 50.8958, q{Random location 806 latitude};
cmp_ok $lon, '==', 137.458, q{Random location 806 longitude};

( $grid ) = $sta->geodetic( -1.44458687608659, -2.11379667585318, 0 )
    ->maidenhead( 3 );
is $grid, 'CA97kf', q{Random location 807 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CA97kf' ) );
cmp_ok $lat, '==', -82.7708, q{Random location 807 latitude};
cmp_ok $lon, '==', -121.125, q{Random location 807 longitude};

( $grid ) = $sta->geodetic( -0.524620823392509, -2.14852365800366, 0 )
    ->maidenhead( 3 );
is $grid, 'CF89kw', q{Random location 808 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CF89kw' ) );
cmp_ok $lat, '==', -30.0625, q{Random location 808 latitude};
cmp_ok $lon, '==', -123.125, q{Random location 808 longitude};

( $grid ) = $sta->geodetic( 0.275504778799346, -0.710134970536045, 0 )
    ->maidenhead( 3 );
is $grid, 'GK95ps', q{Random location 809 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GK95ps' ) );
cmp_ok $lat, '==', 15.7708, q{Random location 809 latitude};
cmp_ok $lon, '==', -40.7083, q{Random location 809 longitude};

( $grid ) = $sta->geodetic( -0.737402830460715, -3.05959485254792, 0 )
    ->maidenhead( 3 );
is $grid, 'AE27ir', q{Random location 810 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE27ir' ) );
cmp_ok $lat, '==', -42.2708, q{Random location 810 latitude};
cmp_ok $lon, '==', -175.292, q{Random location 810 longitude};

( $grid ) = $sta->geodetic( 0.106633123743848, -2.10144214595296, 0 )
    ->maidenhead( 3 );
is $grid, 'CJ96tc', q{Random location 811 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CJ96tc' ) );
cmp_ok $lat, '==', 6.10417, q{Random location 811 latitude};
cmp_ok $lon, '==', -120.375, q{Random location 811 longitude};

( $grid ) = $sta->geodetic( -0.144603171676125, -3.13525483719202, 0 )
    ->maidenhead( 3 );
is $grid, 'AI01er', q{Random location 812 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI01er' ) );
cmp_ok $lat, '==', -8.27083, q{Random location 812 latitude};
cmp_ok $lon, '==', -179.625, q{Random location 812 longitude};

( $grid ) = $sta->geodetic( -0.34302135782607, -0.144125631190688, 0 )
    ->maidenhead( 3 );
is $grid, 'IH50ui', q{Random location 813 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH50ui' ) );
cmp_ok $lat, '==', -19.6458, q{Random location 813 latitude};
cmp_ok $lon, '==', -8.29167, q{Random location 813 longitude};

( $grid ) = $sta->geodetic( -0.643191580719776, -2.95572892439778, 0 )
    ->maidenhead( 3 );
is $grid, 'AF53hd', q{Random location 814 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AF53hd' ) );
cmp_ok $lat, '==', -36.8542, q{Random location 814 latitude};
cmp_ok $lon, '==', -169.375, q{Random location 814 longitude};

( $grid ) = $sta->geodetic( 1.20356948519953, -0.900220311637504, 0 )
    ->maidenhead( 3 );
is $grid, 'GP48fx', q{Random location 815 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GP48fx' ) );
cmp_ok $lat, '==', 68.9792, q{Random location 815 latitude};
cmp_ok $lon, '==', -51.5417, q{Random location 815 longitude};

( $grid ) = $sta->geodetic( -0.756802789477091, 2.05931083183877, 0 )
    ->maidenhead( 3 );
is $grid, 'OE86xp', q{Random location 816 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OE86xp' ) );
cmp_ok $lat, '==', -43.3542, q{Random location 816 latitude};
cmp_ok $lon, '==', 117.958, q{Random location 816 longitude};

( $grid ) = $sta->geodetic( -0.442801009945266, 2.92880423770298, 0 )
    ->maidenhead( 3 );
is $grid, 'RG34vp', q{Random location 817 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RG34vp' ) );
cmp_ok $lat, '==', -25.3542, q{Random location 817 latitude};
cmp_ok $lon, '==', 167.792, q{Random location 817 longitude};

( $grid ) = $sta->geodetic( -0.875323933703961, 1.29120879400232, 0 )
    ->maidenhead( 3 );
is $grid, 'MD69xu', q{Random location 818 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MD69xu' ) );
cmp_ok $lat, '==', -50.1458, q{Random location 818 latitude};
cmp_ok $lon, '==', 73.9583, q{Random location 818 longitude};

( $grid ) = $sta->geodetic( -0.678399982767447, 2.57294011169096, 0 )
    ->maidenhead( 3 );
is $grid, 'QF31rd', q{Random location 819 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF31rd' ) );
cmp_ok $lat, '==', -38.8542, q{Random location 819 latitude};
cmp_ok $lon, '==', 147.458, q{Random location 819 longitude};

( $grid ) = $sta->geodetic( -0.467280188862314, -1.46712995659755, 0 )
    ->maidenhead( 3 );
is $grid, 'EG73xf', q{Random location 820 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EG73xf' ) );
cmp_ok $lat, '==', -26.7708, q{Random location 820 latitude};
cmp_ok $lon, '==', -84.0417, q{Random location 820 longitude};

( $grid ) = $sta->geodetic( 0.0274749181437846, -2.51487853926493, 0 )
    ->maidenhead( 3 );
is $grid, 'BJ71wn', q{Random location 821 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BJ71wn' ) );
cmp_ok $lat, '==', 1.5625, q{Random location 821 latitude};
cmp_ok $lon, '==', -144.125, q{Random location 821 longitude};

( $grid ) = $sta->geodetic( -0.693068644084013, -1.95633074804617, 0 )
    ->maidenhead( 3 );
is $grid, 'DF30wg', q{Random location 822 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DF30wg' ) );
cmp_ok $lat, '==', -39.7292, q{Random location 822 latitude};
cmp_ok $lon, '==', -112.125, q{Random location 822 longitude};

( $grid ) = $sta->geodetic( -0.225102950131747, 2.73993628716787, 0 )
    ->maidenhead( 3 );
is $grid, 'QH87lc', q{Random location 823 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QH87lc' ) );
cmp_ok $lat, '==', -12.8958, q{Random location 823 latitude};
cmp_ok $lon, '==', 156.958, q{Random location 823 longitude};

( $grid ) = $sta->geodetic( 0.0332147289217215, -2.72897108347665, 0 )
    ->maidenhead( 3 );
is $grid, 'BJ11tv', q{Random location 824 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BJ11tv' ) );
cmp_ok $lat, '==', 1.89583, q{Random location 824 latitude};
cmp_ok $lon, '==', -156.375, q{Random location 824 longitude};

( $grid ) = $sta->geodetic( -0.752956377341271, 3.01091061686931, 0 )
    ->maidenhead( 3 );
is $grid, 'RE66gu', q{Random location 825 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RE66gu' ) );
cmp_ok $lat, '==', -43.1458, q{Random location 825 latitude};
cmp_ok $lon, '==', 172.542, q{Random location 825 longitude};

( $grid ) = $sta->geodetic( -0.327768927867537, -1.53973509807071, 0 )
    ->maidenhead( 3 );
is $grid, 'EH51vf', q{Random location 826 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EH51vf' ) );
cmp_ok $lat, '==', -18.7708, q{Random location 826 latitude};
cmp_ok $lon, '==', -88.2083, q{Random location 826 longitude};

( $grid ) = $sta->geodetic( 0.310032604062557, -0.692886337371864, 0 )
    ->maidenhead( 3 );
is $grid, 'HK07ds', q{Random location 827 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HK07ds' ) );
cmp_ok $lat, '==', 17.7708, q{Random location 827 latitude};
cmp_ok $lon, '==', -39.7083, q{Random location 827 longitude};

( $grid ) = $sta->geodetic( -1.05301662894792, -0.0483580071706835, 0 )
    ->maidenhead( 3 );
is $grid, 'IC89op', q{Random location 828 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IC89op' ) );
cmp_ok $lat, '==', -60.3542, q{Random location 828 latitude};
cmp_ok $lon, '==', -2.79167, q{Random location 828 longitude};

( $grid ) = $sta->geodetic( -0.198276847416979, 0.518627867033457, 0 )
    ->maidenhead( 3 );
is $grid, 'KH48up', q{Random location 829 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KH48up' ) );
cmp_ok $lat, '==', -11.3542, q{Random location 829 latitude};
cmp_ok $lon, '==', 29.7083, q{Random location 829 longitude};

( $grid ) = $sta->geodetic( -0.526090928164605, 2.48420105107035, 0 )
    ->maidenhead( 3 );
is $grid, 'QF19eu', q{Random location 830 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF19eu' ) );
cmp_ok $lat, '==', -30.1458, q{Random location 830 latitude};
cmp_ok $lon, '==', 142.375, q{Random location 830 longitude};

( $grid ) = $sta->geodetic( 0.589246492213152, -1.15584366944998, 0 )
    ->maidenhead( 3 );
is $grid, 'FM63vs', q{Random location 831 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FM63vs' ) );
cmp_ok $lat, '==', 33.7708, q{Random location 831 latitude};
cmp_ok $lon, '==', -66.2083, q{Random location 831 longitude};

( $grid ) = $sta->geodetic( -0.432511129256465, 1.27315557531749, 0 )
    ->maidenhead( 3 );
is $grid, 'MG65lf', q{Random location 832 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MG65lf' ) );
cmp_ok $lat, '==', -24.7708, q{Random location 832 latitude};
cmp_ok $lon, '==', 72.9583, q{Random location 832 longitude};

( $grid ) = $sta->geodetic( 0.218688077731752, 0.0881508956441688, 0 )
    ->maidenhead( 3 );
is $grid, 'JK22mm', q{Random location 833 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK22mm' ) );
cmp_ok $lat, '==', 12.5208, q{Random location 833 latitude};
cmp_ok $lon, '==', 5.04167, q{Random location 833 longitude};

( $grid ) = $sta->geodetic( -0.928601613436213, -0.631620157049403, 0 )
    ->maidenhead( 3 );
is $grid, 'HD16vt', q{Random location 834 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HD16vt' ) );
cmp_ok $lat, '==', -53.1875, q{Random location 834 latitude};
cmp_ok $lon, '==', -36.2083, q{Random location 834 longitude};

( $grid ) = $sta->geodetic( 0.132360030608686, 1.64760155572374, 0 )
    ->maidenhead( 3 );
is $grid, 'NJ77eo', q{Random location 835 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NJ77eo' ) );
cmp_ok $lat, '==', 7.60417, q{Random location 835 latitude};
cmp_ok $lon, '==', 94.375, q{Random location 835 longitude};

( $grid ) = $sta->geodetic( -0.133713748740317, 0.732230775708548, 0 )
    ->maidenhead( 3 );
is $grid, 'LI02xi', q{Random location 836 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LI02xi' ) );
cmp_ok $lat, '==', -7.64583, q{Random location 836 latitude};
cmp_ok $lon, '==', 41.9583, q{Random location 836 longitude};

( $grid ) = $sta->geodetic( -0.681713709257166, 0.917390842332332, 0 )
    ->maidenhead( 3 );
is $grid, 'LF60gw', q{Random location 837 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF60gw' ) );
cmp_ok $lat, '==', -39.0625, q{Random location 837 latitude};
cmp_ok $lon, '==', 52.5417, q{Random location 837 longitude};

( $grid ) = $sta->geodetic( 1.06348869867867, 0.583659591010301, 0 )
    ->maidenhead( 3 );
is $grid, 'KP60rw', q{Random location 838 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KP60rw' ) );
cmp_ok $lat, '==', 60.9375, q{Random location 838 latitude};
cmp_ok $lon, '==', 33.4583, q{Random location 838 longitude};

( $grid ) = $sta->geodetic( 0.26571940462176, 2.72954301128121, 0 )
    ->maidenhead( 3 );
is $grid, 'QK85ef', q{Random location 839 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QK85ef' ) );
cmp_ok $lat, '==', 15.2292, q{Random location 839 latitude};
cmp_ok $lon, '==', 156.375, q{Random location 839 longitude};

( $grid ) = $sta->geodetic( 0.532116475182982, 2.89972841704562, 0 )
    ->maidenhead( 3 );
is $grid, 'RM30bl', q{Random location 840 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM30bl' ) );
cmp_ok $lat, '==', 30.4792, q{Random location 840 latitude};
cmp_ok $lon, '==', 166.125, q{Random location 840 longitude};

( $grid ) = $sta->geodetic( 0.126695742064121, -0.849340659536036, 0 )
    ->maidenhead( 3 );
is $grid, 'GJ57qg', q{Random location 841 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GJ57qg' ) );
cmp_ok $lat, '==', 7.27083, q{Random location 841 latitude};
cmp_ok $lon, '==', -48.625, q{Random location 841 longitude};

( $grid ) = $sta->geodetic( 1.42994183572035, 2.57918534898529, 0 )
    ->maidenhead( 3 );
is $grid, 'QR31vw', q{Random location 842 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QR31vw' ) );
cmp_ok $lat, '==', 81.9375, q{Random location 842 latitude};
cmp_ok $lon, '==', 147.792, q{Random location 842 longitude};

( $grid ) = $sta->geodetic( 0.283911576707768, -1.5281895745038, 0 )
    ->maidenhead( 3 );
is $grid, 'EK66fg', q{Random location 843 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK66fg' ) );
cmp_ok $lat, '==', 16.2708, q{Random location 843 latitude};
cmp_ok $lon, '==', -87.5417, q{Random location 843 longitude};

( $grid ) = $sta->geodetic( -0.607028603654933, -1.15252043483566, 0 )
    ->maidenhead( 3 );
is $grid, 'FF65xf', q{Random location 844 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF65xf' ) );
cmp_ok $lat, '==', -34.7708, q{Random location 844 latitude};
cmp_ok $lon, '==', -66.0417, q{Random location 844 longitude};

( $grid ) = $sta->geodetic( -0.570181096703223, 2.90045270496481, 0 )
    ->maidenhead( 3 );
is $grid, 'RF37ch', q{Random location 845 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RF37ch' ) );
cmp_ok $lat, '==', -32.6875, q{Random location 845 latitude};
cmp_ok $lon, '==', 166.208, q{Random location 845 longitude};

( $grid ) = $sta->geodetic( 0.335229523440285, 0.266532628165452, 0 )
    ->maidenhead( 3 );
is $grid, 'JK79pe', q{Random location 846 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK79pe' ) );
cmp_ok $lat, '==', 19.1875, q{Random location 846 latitude};
cmp_ok $lon, '==', 15.2917, q{Random location 846 longitude};

( $grid ) = $sta->geodetic( 0.673139773232305, 2.07667217502782, 0 )
    ->maidenhead( 3 );
is $grid, 'OM98ln', q{Random location 847 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OM98ln' ) );
cmp_ok $lat, '==', 38.5625, q{Random location 847 latitude};
cmp_ok $lon, '==', 118.958, q{Random location 847 longitude};

( $grid ) = $sta->geodetic( -0.583978925364785, -1.99019029772474, 0 )
    ->maidenhead( 3 );
is $grid, 'DF26xm', q{Random location 848 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DF26xm' ) );
cmp_ok $lat, '==', -33.4792, q{Random location 848 latitude};
cmp_ok $lon, '==', -114.042, q{Random location 848 longitude};

( $grid ) = $sta->geodetic( 0.698425026877519, 2.00530401372181, 0 )
    ->maidenhead( 3 );
is $grid, 'ON70ka', q{Random location 849 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ON70ka' ) );
cmp_ok $lat, '==', 40.0208, q{Random location 849 latitude};
cmp_ok $lon, '==', 114.875, q{Random location 849 longitude};

( $grid ) = $sta->geodetic( -0.638088515449647, 2.99950003795669, 0 )
    ->maidenhead( 3 );
is $grid, 'RF53wk', q{Random location 850 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RF53wk' ) );
cmp_ok $lat, '==', -36.5625, q{Random location 850 latitude};
cmp_ok $lon, '==', 171.875, q{Random location 850 longitude};

( $grid ) = $sta->geodetic( 0.0853838804105305, -0.519989585735667, 0 )
    ->maidenhead( 3 );
is $grid, 'HJ54cv', q{Random location 851 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HJ54cv' ) );
cmp_ok $lat, '==', 4.89583, q{Random location 851 latitude};
cmp_ok $lon, '==', -29.7917, q{Random location 851 longitude};

( $grid ) = $sta->geodetic( -0.62377616420542, -1.01891925799859, 0 )
    ->maidenhead( 3 );
is $grid, 'GF04tg', q{Random location 852 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GF04tg' ) );
cmp_ok $lat, '==', -35.7292, q{Random location 852 latitude};
cmp_ok $lon, '==', -58.375, q{Random location 852 longitude};

( $grid ) = $sta->geodetic( -1.46116129260801, -0.393508309907042, 0 )
    ->maidenhead( 3 );
is $grid, 'HA86rg', q{Random location 853 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HA86rg' ) );
cmp_ok $lat, '==', -83.7292, q{Random location 853 latitude};
cmp_ok $lon, '==', -22.5417, q{Random location 853 longitude};

( $grid ) = $sta->geodetic( -0.934928377736355, 2.4222406739673, 0 )
    ->maidenhead( 3 );
is $grid, 'PD96jk', q{Random location 854 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PD96jk' ) );
cmp_ok $lat, '==', -53.5625, q{Random location 854 latitude};
cmp_ok $lon, '==', 138.792, q{Random location 854 longitude};

( $grid ) = $sta->geodetic( -0.827134809324958, -0.13691596409724, 0 )
    ->maidenhead( 3 );
is $grid, 'IE62bo', q{Random location 855 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE62bo' ) );
cmp_ok $lat, '==', -47.3958, q{Random location 855 latitude};
cmp_ok $lon, '==', -7.875, q{Random location 855 longitude};

( $grid ) = $sta->geodetic( 0.95513538512272, 3.00483516447854, 0 )
    ->maidenhead( 3 );
is $grid, 'RO64br', q{Random location 856 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RO64br' ) );
cmp_ok $lat, '==', 54.7292, q{Random location 856 latitude};
cmp_ok $lon, '==', 172.125, q{Random location 856 longitude};

( $grid ) = $sta->geodetic( -0.773793079076626, -3.05744150581582, 0 )
    ->maidenhead( 3 );
is $grid, 'AE25jp', q{Random location 857 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AE25jp' ) );
cmp_ok $lat, '==', -44.3542, q{Random location 857 latitude};
cmp_ok $lon, '==', -175.208, q{Random location 857 longitude};

( $grid ) = $sta->geodetic( -0.706783683407907, -0.42314900048502, 0 )
    ->maidenhead( 3 );
is $grid, 'HE79vm', q{Random location 858 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HE79vm' ) );
cmp_ok $lat, '==', -40.4792, q{Random location 858 latitude};
cmp_ok $lon, '==', -24.2083, q{Random location 858 longitude};

( $grid ) = $sta->geodetic( 0.653808598682579, 3.07440664562958, 0 )
    ->maidenhead( 3 );
is $grid, 'RM87bl', q{Random location 859 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RM87bl' ) );
cmp_ok $lat, '==', 37.4792, q{Random location 859 latitude};
cmp_ok $lon, '==', 176.125, q{Random location 859 longitude};

( $grid ) = $sta->geodetic( -0.508242018872816, -0.196692874894755, 0 )
    ->maidenhead( 3 );
is $grid, 'IG40iv', q{Random location 860 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IG40iv' ) );
cmp_ok $lat, '==', -29.1042, q{Random location 860 latitude};
cmp_ok $lon, '==', -11.2917, q{Random location 860 longitude};

( $grid ) = $sta->geodetic( 0.475980799767627, -1.59860495654202, 0 )
    ->maidenhead( 3 );
is $grid, 'EL47eg', q{Random location 861 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EL47eg' ) );
cmp_ok $lat, '==', 27.2708, q{Random location 861 latitude};
cmp_ok $lon, '==', -91.625, q{Random location 861 longitude};

( $grid ) = $sta->geodetic( -1.37044640122372, 1.8763445733296, 0 )
    ->maidenhead( 3 );
is $grid, 'OB31sl', q{Random location 862 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OB31sl' ) );
cmp_ok $lat, '==', -78.5208, q{Random location 862 latitude};
cmp_ok $lon, '==', 107.542, q{Random location 862 longitude};

( $grid ) = $sta->geodetic( 0.0569154506902212, 1.3927625535105, 0 )
    ->maidenhead( 3 );
is $grid, 'MJ93vg', q{Random location 863 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MJ93vg' ) );
cmp_ok $lat, '==', 3.27083, q{Random location 863 latitude};
cmp_ok $lon, '==', 79.7917, q{Random location 863 longitude};

( $grid ) = $sta->geodetic( -0.0655005381599032, 1.92804617251811, 0 )
    ->maidenhead( 3 );
is $grid, 'OI56ff', q{Random location 864 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI56ff' ) );
cmp_ok $lat, '==', -3.77083, q{Random location 864 latitude};
cmp_ok $lon, '==', 110.458, q{Random location 864 longitude};

( $grid ) = $sta->geodetic( 0.516734052536569, -1.46575075929269, 0 )
    ->maidenhead( 3 );
is $grid, 'EL89ao', q{Random location 865 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EL89ao' ) );
cmp_ok $lat, '==', 29.6042, q{Random location 865 latitude};
cmp_ok $lon, '==', -83.9583, q{Random location 865 longitude};

( $grid ) = $sta->geodetic( -0.976968681491225, 2.41139821498447, 0 )
    ->maidenhead( 3 );
is $grid, 'PD94ba', q{Random location 866 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PD94ba' ) );
cmp_ok $lat, '==', -55.9792, q{Random location 866 latitude};
cmp_ok $lon, '==', 138.125, q{Random location 866 longitude};

( $grid ) = $sta->geodetic( 0.0811524475180492, -0.449168069717397, 0 )
    ->maidenhead( 3 );
is $grid, 'HJ74dp', q{Random location 867 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HJ74dp' ) );
cmp_ok $lat, '==', 4.64583, q{Random location 867 latitude};
cmp_ok $lon, '==', -25.7083, q{Random location 867 longitude};

( $grid ) = $sta->geodetic( 0.287383028579639, -1.31764766785236, 0 )
    ->maidenhead( 3 );
is $grid, 'FK26gl', q{Random location 868 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FK26gl' ) );
cmp_ok $lat, '==', 16.4792, q{Random location 868 latitude};
cmp_ok $lon, '==', -75.4583, q{Random location 868 longitude};

( $grid ) = $sta->geodetic( 0.496685389836838, -2.33666467207131, 0 )
    ->maidenhead( 3 );
is $grid, 'CL38bk', q{Random location 869 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CL38bk' ) );
cmp_ok $lat, '==', 28.4375, q{Random location 869 latitude};
cmp_ok $lon, '==', -133.875, q{Random location 869 longitude};

( $grid ) = $sta->geodetic( -0.388211209986419, 2.71099286817021, 0 )
    ->maidenhead( 3 );
is $grid, 'QG77ps', q{Random location 870 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG77ps' ) );
cmp_ok $lat, '==', -22.2292, q{Random location 870 latitude};
cmp_ok $lon, '==', 155.292, q{Random location 870 longitude};

( $grid ) = $sta->geodetic( 1.17616476800594, 2.5838625512553, 0 )
    ->maidenhead( 3 );
is $grid, 'QP47aj', q{Random location 871 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QP47aj' ) );
cmp_ok $lat, '==', 67.3958, q{Random location 871 latitude};
cmp_ok $lon, '==', 148.042, q{Random location 871 longitude};

( $grid ) = $sta->geodetic( 0.339020203861452, -1.61265145229249, 0 )
    ->maidenhead( 3 );
is $grid, 'EK39tk', q{Random location 872 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK39tk' ) );
cmp_ok $lat, '==', 19.4375, q{Random location 872 latitude};
cmp_ok $lon, '==', -92.375, q{Random location 872 longitude};

( $grid ) = $sta->geodetic( -0.222178651171905, -2.8031994154344, 0 )
    ->maidenhead( 3 );
is $grid, 'AH97qg', q{Random location 873 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AH97qg' ) );
cmp_ok $lat, '==', -12.7292, q{Random location 873 latitude};
cmp_ok $lon, '==', -160.625, q{Random location 873 longitude};

( $grid ) = $sta->geodetic( -1.14490799074887, -2.71199623762181, 0 )
    ->maidenhead( 3 );
is $grid, 'BC24hj', q{Random location 874 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BC24hj' ) );
cmp_ok $lat, '==', -65.6042, q{Random location 874 latitude};
cmp_ok $lon, '==', -155.375, q{Random location 874 longitude};

( $grid ) = $sta->geodetic( 0.0075230212423707, -1.56431943167309, 0 )
    ->maidenhead( 3 );
is $grid, 'EJ50ek', q{Random location 875 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EJ50ek' ) );
cmp_ok $lat, '==', 0.4375, q{Random location 875 latitude};
cmp_ok $lon, '==', -89.625, q{Random location 875 longitude};

( $grid ) = $sta->geodetic( 0.0182615612117691, -2.63753746814296, 0 )
    ->maidenhead( 3 );
is $grid, 'BJ41kb', q{Random location 876 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BJ41kb' ) );
cmp_ok $lat, '==', 1.0625, q{Random location 876 latitude};
cmp_ok $lon, '==', -151.125, q{Random location 876 longitude};

( $grid ) = $sta->geodetic( -0.658679726388894, 1.66004115002322, 0 )
    ->maidenhead( 3 );
is $grid, 'NF72ng', q{Random location 877 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NF72ng' ) );
cmp_ok $lat, '==', -37.7292, q{Random location 877 latitude};
cmp_ok $lon, '==', 95.125, q{Random location 877 longitude};

( $grid ) = $sta->geodetic( 0.329447594387191, 0.442563753072662, 0 )
    ->maidenhead( 3 );
is $grid, 'KK28qv', q{Random location 878 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK28qv' ) );
cmp_ok $lat, '==', 18.8958, q{Random location 878 latitude};
cmp_ok $lon, '==', 25.375, q{Random location 878 longitude};

( $grid ) = $sta->geodetic( 1.03880198927061, 0.548629139400534, 0 )
    ->maidenhead( 3 );
is $grid, 'KO59rm', q{Random location 879 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KO59rm' ) );
cmp_ok $lat, '==', 59.5208, q{Random location 879 latitude};
cmp_ok $lon, '==', 31.4583, q{Random location 879 longitude};

( $grid ) = $sta->geodetic( -0.635902071678646, -0.461454219386587, 0 )
    ->maidenhead( 3 );
is $grid, 'HF63sn', q{Random location 880 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HF63sn' ) );
cmp_ok $lat, '==', -36.4375, q{Random location 880 latitude};
cmp_ok $lon, '==', -26.4583, q{Random location 880 longitude};

( $grid ) = $sta->geodetic( -0.287126717200243, 0.16784632865813, 0 )
    ->maidenhead( 3 );
is $grid, 'JH43tn', q{Random location 881 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JH43tn' ) );
cmp_ok $lat, '==', -16.4375, q{Random location 881 latitude};
cmp_ok $lon, '==', 9.625, q{Random location 881 longitude};

( $grid ) = $sta->geodetic( 0.946132301241324, 3.13417268514587, 0 )
    ->maidenhead( 3 );
is $grid, 'RO94sf', q{Random location 882 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RO94sf' ) );
cmp_ok $lat, '==', 54.2292, q{Random location 882 latitude};
cmp_ok $lon, '==', 179.542, q{Random location 882 longitude};

( $grid ) = $sta->geodetic( 0.455699219855579, 1.25646106013138, 0 )
    ->maidenhead( 3 );
is $grid, 'ML56xc', q{Random location 883 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ML56xc' ) );
cmp_ok $lat, '==', 26.1042, q{Random location 883 latitude};
cmp_ok $lon, '==', 71.9583, q{Random location 883 longitude};

( $grid ) = $sta->geodetic( 0.685283118397668, -0.00597651691185597, 0 )
    ->maidenhead( 3 );
is $grid, 'IM99tg', q{Random location 884 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IM99tg' ) );
cmp_ok $lat, '==', 39.2708, q{Random location 884 latitude};
cmp_ok $lon, '==', -0.375, q{Random location 884 longitude};

( $grid ) = $sta->geodetic( 0.318113736547851, -1.65906814629549, 0 )
    ->maidenhead( 3 );
is $grid, 'EK28lf', q{Random location 885 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK28lf' ) );
cmp_ok $lat, '==', 18.2292, q{Random location 885 latitude};
cmp_ok $lon, '==', -95.0417, q{Random location 885 longitude};

( $grid ) = $sta->geodetic( 0.771933867083046, -1.76741171382438, 0 )
    ->maidenhead( 3 );
is $grid, 'DN94if', q{Random location 886 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DN94if' ) );
cmp_ok $lat, '==', 44.2292, q{Random location 886 latitude};
cmp_ok $lon, '==', -101.292, q{Random location 886 longitude};

( $grid ) = $sta->geodetic( -0.54600046590682, -1.19523212427472, 0 )
    ->maidenhead( 3 );
is $grid, 'FF58sr', q{Random location 887 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF58sr' ) );
cmp_ok $lat, '==', -31.2708, q{Random location 887 latitude};
cmp_ok $lon, '==', -68.4583, q{Random location 887 longitude};

( $grid ) = $sta->geodetic( 0.156865930002983, -0.302267607613461, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ18ix', q{Random location 888 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ18ix' ) );
cmp_ok $lat, '==', 8.97917, q{Random location 888 latitude};
cmp_ok $lon, '==', -17.2917, q{Random location 888 longitude};

( $grid ) = $sta->geodetic( 1.07712805566991, 1.53968136377697, 0 )
    ->maidenhead( 3 );
is $grid, 'NP41cr', q{Random location 889 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NP41cr' ) );
cmp_ok $lat, '==', 61.7292, q{Random location 889 latitude};
cmp_ok $lon, '==', 88.2083, q{Random location 889 longitude};

( $grid ) = $sta->geodetic( -0.683686480044575, 1.33882622087964, 0 )
    ->maidenhead( 3 );
is $grid, 'MF80it', q{Random location 890 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MF80it' ) );
cmp_ok $lat, '==', -39.1875, q{Random location 890 latitude};
cmp_ok $lon, '==', 76.7083, q{Random location 890 longitude};

( $grid ) = $sta->geodetic( 0.475615489590528, -0.315225455991688, 0 )
    ->maidenhead( 3 );
is $grid, 'IL07xg', q{Random location 891 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IL07xg' ) );
cmp_ok $lat, '==', 27.2708, q{Random location 891 latitude};
cmp_ok $lon, '==', -18.0417, q{Random location 891 longitude};

( $grid ) = $sta->geodetic( -1.24000938953873, 2.7547483898993, 0 )
    ->maidenhead( 3 );
is $grid, 'QB88ww', q{Random location 892 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QB88ww' ) );
cmp_ok $lat, '==', -71.0625, q{Random location 892 latitude};
cmp_ok $lon, '==', 157.875, q{Random location 892 longitude};

( $grid ) = $sta->geodetic( 0.364498848678682, 2.3667706565732, 0 )
    ->maidenhead( 3 );
is $grid, 'PL70tv', q{Random location 893 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL70tv' ) );
cmp_ok $lat, '==', 20.8958, q{Random location 893 latitude};
cmp_ok $lon, '==', 135.625, q{Random location 893 longitude};

( $grid ) = $sta->geodetic( 0.709375834860068, 0.215131701581255, 0 )
    ->maidenhead( 3 );
is $grid, 'JN60dp', q{Random location 894 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JN60dp' ) );
cmp_ok $lat, '==', 40.6458, q{Random location 894 latitude};
cmp_ok $lon, '==', 12.2917, q{Random location 894 longitude};

( $grid ) = $sta->geodetic( -0.199046301743689, -0.122123655042122, 0 )
    ->maidenhead( 3 );
is $grid, 'IH68mo', q{Random location 895 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IH68mo' ) );
cmp_ok $lat, '==', -11.3958, q{Random location 895 latitude};
cmp_ok $lon, '==', -6.95833, q{Random location 895 longitude};

( $grid ) = $sta->geodetic( 0.219858171895814, 1.30650297630488, 0 )
    ->maidenhead( 3 );
is $grid, 'MK72ko', q{Random location 896 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK72ko' ) );
cmp_ok $lat, '==', 12.6042, q{Random location 896 latitude};
cmp_ok $lon, '==', 74.875, q{Random location 896 longitude};

( $grid ) = $sta->geodetic( -0.918680619848588, -2.97602344518215, 0 )
    ->maidenhead( 3 );
is $grid, 'AD47ri', q{Random location 897 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AD47ri' ) );
cmp_ok $lat, '==', -52.6458, q{Random location 897 latitude};
cmp_ok $lon, '==', -170.542, q{Random location 897 longitude};

( $grid ) = $sta->geodetic( -0.214481542542541, 1.24293306582518, 0 )
    ->maidenhead( 3 );
is $grid, 'MH57or', q{Random location 898 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MH57or' ) );
cmp_ok $lat, '==', -12.2708, q{Random location 898 latitude};
cmp_ok $lon, '==', 71.2083, q{Random location 898 longitude};

( $grid ) = $sta->geodetic( -0.683524151466959, -1.12008688752631, 0 )
    ->maidenhead( 3 );
is $grid, 'FF70vu', q{Random location 899 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF70vu' ) );
cmp_ok $lat, '==', -39.1458, q{Random location 899 latitude};
cmp_ok $lon, '==', -64.2083, q{Random location 899 longitude};

( $grid ) = $sta->geodetic( 0.0671506896687686, 1.00464965735986, 0 )
    ->maidenhead( 3 );
is $grid, 'LJ83su', q{Random location 900 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LJ83su' ) );
cmp_ok $lat, '==', 3.85417, q{Random location 900 latitude};
cmp_ok $lon, '==', 57.5417, q{Random location 900 longitude};

( $grid ) = $sta->geodetic( -0.236633013027284, -2.90668117834537, 0 )
    ->maidenhead( 3 );
is $grid, 'AH66rk', q{Random location 901 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AH66rk' ) );
cmp_ok $lat, '==', -13.5625, q{Random location 901 latitude};
cmp_ok $lon, '==', -166.542, q{Random location 901 longitude};

( $grid ) = $sta->geodetic( -0.92676758353527, 1.99282968252375, 0 )
    ->maidenhead( 3 );
is $grid, 'OD76cv', q{Random location 902 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OD76cv' ) );
cmp_ok $lat, '==', -53.1042, q{Random location 902 latitude};
cmp_ok $lon, '==', 114.208, q{Random location 902 longitude};

( $grid ) = $sta->geodetic( 0.665029920556027, -1.52509991350006, 0 )
    ->maidenhead( 3 );
is $grid, 'EM68hc', q{Random location 903 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EM68hc' ) );
cmp_ok $lat, '==', 38.1042, q{Random location 903 latitude};
cmp_ok $lon, '==', -87.375, q{Random location 903 longitude};

( $grid ) = $sta->geodetic( 1.09719155840088, -0.552906747224668, 0 )
    ->maidenhead( 3 );
is $grid, 'HP42du', q{Random location 904 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'HP42du' ) );
cmp_ok $lat, '==', 62.8542, q{Random location 904 latitude};
cmp_ok $lon, '==', -31.7083, q{Random location 904 longitude};

( $grid ) = $sta->geodetic( 0.307441235345141, -2.66984151006092, 0 )
    ->maidenhead( 3 );
is $grid, 'BK37mo', q{Random location 905 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BK37mo' ) );
cmp_ok $lat, '==', 17.6042, q{Random location 905 latitude};
cmp_ok $lon, '==', -152.958, q{Random location 905 longitude};

( $grid ) = $sta->geodetic( 0.734336124305233, -1.25418920370592, 0 )
    ->maidenhead( 3 );
is $grid, 'FN42bb', q{Random location 906 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FN42bb' ) );
cmp_ok $lat, '==', 42.0625, q{Random location 906 latitude};
cmp_ok $lon, '==', -71.875, q{Random location 906 longitude};

( $grid ) = $sta->geodetic( -0.349999752054934, -1.68296989333393, 0 )
    ->maidenhead( 3 );
is $grid, 'EG19sw', q{Random location 907 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EG19sw' ) );
cmp_ok $lat, '==', -20.0625, q{Random location 907 latitude};
cmp_ok $lon, '==', -96.4583, q{Random location 907 longitude};

( $grid ) = $sta->geodetic( 0.0790645676573536, -2.49402319065296, 0 )
    ->maidenhead( 3 );
is $grid, 'BJ84nm', q{Random location 908 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BJ84nm' ) );
cmp_ok $lat, '==', 4.52083, q{Random location 908 latitude};
cmp_ok $lon, '==', -142.875, q{Random location 908 longitude};

( $grid ) = $sta->geodetic( 0.462685562605092, 0.353758829905577, 0 )
    ->maidenhead( 3 );
is $grid, 'KL06dm', q{Random location 909 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KL06dm' ) );
cmp_ok $lat, '==', 26.5208, q{Random location 909 latitude};
cmp_ok $lon, '==', 20.2917, q{Random location 909 longitude};

( $grid ) = $sta->geodetic( 0.856992345912629, -0.0754272186661922, 0 )
    ->maidenhead( 3 );
is $grid, 'IN79uc', q{Random location 910 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IN79uc' ) );
cmp_ok $lat, '==', 49.1042, q{Random location 910 latitude};
cmp_ok $lon, '==', -4.29167, q{Random location 910 longitude};

( $grid ) = $sta->geodetic( 0.160376805305352, 2.54574274110827, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ29we', q{Random location 911 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ29we' ) );
cmp_ok $lat, '==', 9.1875, q{Random location 911 latitude};
cmp_ok $lon, '==', 145.875, q{Random location 911 longitude};

( $grid ) = $sta->geodetic( 0.382637654779237, 2.18862786296504, 0 )
    ->maidenhead( 3 );
is $grid, 'PL21qw', q{Random location 912 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PL21qw' ) );
cmp_ok $lat, '==', 21.9375, q{Random location 912 latitude};
cmp_ok $lon, '==', 125.375, q{Random location 912 longitude};

( $grid ) = $sta->geodetic( 1.13359766287614, 1.89383731964944, 0 )
    ->maidenhead( 3 );
is $grid, 'OP44gw', q{Random location 913 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OP44gw' ) );
cmp_ok $lat, '==', 64.9375, q{Random location 913 latitude};
cmp_ok $lon, '==', 108.542, q{Random location 913 longitude};

( $grid ) = $sta->geodetic( 0.279490653119316, 1.23193616872099, 0 )
    ->maidenhead( 3 );
is $grid, 'MK56ha', q{Random location 914 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK56ha' ) );
cmp_ok $lat, '==', 16.0208, q{Random location 914 latitude};
cmp_ok $lon, '==', 70.625, q{Random location 914 longitude};

( $grid ) = $sta->geodetic( 0.208368264763734, 2.18470757324598, 0 )
    ->maidenhead( 3 );
is $grid, 'PK21ow', q{Random location 915 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PK21ow' ) );
cmp_ok $lat, '==', 11.9375, q{Random location 915 latitude};
cmp_ok $lon, '==', 125.208, q{Random location 915 longitude};

( $grid ) = $sta->geodetic( 0.868959243913303, 3.09328446356669, 0 )
    ->maidenhead( 3 );
is $grid, 'RN89os', q{Random location 916 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RN89os' ) );
cmp_ok $lat, '==', 49.7708, q{Random location 916 latitude};
cmp_ok $lon, '==', 177.208, q{Random location 916 longitude};

( $grid ) = $sta->geodetic( 0.840120868708917, 2.93336749971277, 0 )
    ->maidenhead( 3 );
is $grid, 'RN48ad', q{Random location 917 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RN48ad' ) );
cmp_ok $lat, '==', 48.1458, q{Random location 917 latitude};
cmp_ok $lon, '==', 168.042, q{Random location 917 longitude};

( $grid ) = $sta->geodetic( -0.820636787097066, -1.58366865122687, 0 )
    ->maidenhead( 3 );
is $grid, 'EE42px', q{Random location 918 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EE42px' ) );
cmp_ok $lat, '==', -47.0208, q{Random location 918 latitude};
cmp_ok $lon, '==', -90.7083, q{Random location 918 longitude};

( $grid ) = $sta->geodetic( 0.388766939986114, -1.97637891523544, 0 )
    ->maidenhead( 3 );
is $grid, 'DL32jg', q{Random location 919 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DL32jg' ) );
cmp_ok $lat, '==', 22.2708, q{Random location 919 latitude};
cmp_ok $lon, '==', -113.208, q{Random location 919 longitude};

( $grid ) = $sta->geodetic( 1.21106982655085, -2.74637203364035, 0 )
    ->maidenhead( 3 );
is $grid, 'BP19hj', q{Random location 920 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BP19hj' ) );
cmp_ok $lat, '==', 69.3958, q{Random location 920 latitude};
cmp_ok $lon, '==', -157.375, q{Random location 920 longitude};

( $grid ) = $sta->geodetic( -1.15478821964991, 3.07661246165344, 0 )
    ->maidenhead( 3 );
is $grid, 'RC83du', q{Random location 921 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RC83du' ) );
cmp_ok $lat, '==', -66.1458, q{Random location 921 latitude};
cmp_ok $lon, '==', 176.292, q{Random location 921 longitude};

( $grid ) = $sta->geodetic( 0.18482093646164, -1.71581009053661, 0 )
    ->maidenhead( 3 );
is $grid, 'EK00uo', q{Random location 922 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK00uo' ) );
cmp_ok $lat, '==', 10.6042, q{Random location 922 latitude};
cmp_ok $lon, '==', -98.2917, q{Random location 922 longitude};

( $grid ) = $sta->geodetic( -0.188002823410574, 1.06065094412159, 0 )
    ->maidenhead( 3 );
is $grid, 'MH09jf', q{Random location 923 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MH09jf' ) );
cmp_ok $lat, '==', -10.7708, q{Random location 923 latitude};
cmp_ok $lon, '==', 60.7917, q{Random location 923 longitude};

( $grid ) = $sta->geodetic( -1.2685676661995, -2.38315064289131, 0 )
    ->maidenhead( 3 );
is $grid, 'CB17rh', q{Random location 924 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CB17rh' ) );
cmp_ok $lat, '==', -72.6875, q{Random location 924 latitude};
cmp_ok $lon, '==', -136.542, q{Random location 924 longitude};

( $grid ) = $sta->geodetic( 1.08754436508067, 1.43961436491927, 0 )
    ->maidenhead( 3 );
is $grid, 'NP12fh', q{Random location 925 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NP12fh' ) );
cmp_ok $lat, '==', 62.3125, q{Random location 925 latitude};
cmp_ok $lon, '==', 82.4583, q{Random location 925 longitude};

( $grid ) = $sta->geodetic( 0.0597643858068007, 2.28059496928693, 0 )
    ->maidenhead( 3 );
is $grid, 'PJ53ik', q{Random location 926 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PJ53ik' ) );
cmp_ok $lat, '==', 3.4375, q{Random location 926 latitude};
cmp_ok $lon, '==', 130.708, q{Random location 926 longitude};

( $grid ) = $sta->geodetic( 0.615905599000047, 0.800223003222693, 0 )
    ->maidenhead( 3 );
is $grid, 'LM25wg', q{Random location 927 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LM25wg' ) );
cmp_ok $lat, '==', 35.2708, q{Random location 927 latitude};
cmp_ok $lon, '==', 45.875, q{Random location 927 longitude};

( $grid ) = $sta->geodetic( -0.915582928394743, -3.02378621437414, 0 )
    ->maidenhead( 3 );
is $grid, 'AD37im', q{Random location 928 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AD37im' ) );
cmp_ok $lat, '==', -52.4792, q{Random location 928 latitude};
cmp_ok $lon, '==', -173.292, q{Random location 928 longitude};

( $grid ) = $sta->geodetic( 0.395349516084679, -1.71839733361661, 0 )
    ->maidenhead( 3 );
is $grid, 'EL02sp', q{Random location 929 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EL02sp' ) );
cmp_ok $lat, '==', 22.6458, q{Random location 929 latitude};
cmp_ok $lon, '==', -98.4583, q{Random location 929 longitude};

( $grid ) = $sta->geodetic( -1.05859507958194, -2.01870039493892, 0 )
    ->maidenhead( 3 );
is $grid, 'DC29ei', q{Random location 930 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DC29ei' ) );
cmp_ok $lat, '==', -60.6458, q{Random location 930 latitude};
cmp_ok $lon, '==', -115.625, q{Random location 930 longitude};

( $grid ) = $sta->geodetic( 0.541734297612186, 0.0919287769124626, 0 )
    ->maidenhead( 3 );
is $grid, 'JM21pa', q{Random location 931 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM21pa' ) );
cmp_ok $lat, '==', 31.0208, q{Random location 931 latitude};
cmp_ok $lon, '==', 5.29167, q{Random location 931 longitude};

( $grid ) = $sta->geodetic( -0.663960096536466, 2.76582565085061, 0 )
    ->maidenhead( 3 );
is $grid, 'QF91fw', q{Random location 932 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF91fw' ) );
cmp_ok $lat, '==', -38.0625, q{Random location 932 latitude};
cmp_ok $lon, '==', 158.458, q{Random location 932 longitude};

( $grid ) = $sta->geodetic( 1.3239556787869, -3.01672025234734, 0 )
    ->maidenhead( 3 );
is $grid, 'AQ35nu', q{Random location 933 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AQ35nu' ) );
cmp_ok $lat, '==', 75.8542, q{Random location 933 latitude};
cmp_ok $lon, '==', -172.875, q{Random location 933 longitude};

( $grid ) = $sta->geodetic( 0.74947861365363, 1.65025264705657, 0 )
    ->maidenhead( 3 );
is $grid, 'NN72gw', q{Random location 934 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NN72gw' ) );
cmp_ok $lat, '==', 42.9375, q{Random location 934 latitude};
cmp_ok $lon, '==', 94.5417, q{Random location 934 longitude};

( $grid ) = $sta->geodetic( 0.76546208681799, 1.77051619982078, 0 )
    ->maidenhead( 3 );
is $grid, 'ON03ru', q{Random location 935 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ON03ru' ) );
cmp_ok $lat, '==', 43.8542, q{Random location 935 latitude};
cmp_ok $lon, '==', 101.458, q{Random location 935 longitude};

( $grid ) = $sta->geodetic( 0.323049495320995, -0.215475868489867, 0 )
    ->maidenhead( 3 );
is $grid, 'IK38tm', q{Random location 936 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IK38tm' ) );
cmp_ok $lat, '==', 18.5208, q{Random location 936 latitude};
cmp_ok $lon, '==', -12.375, q{Random location 936 longitude};

( $grid ) = $sta->geodetic( 0.56005290359491, 1.56621387930203, 0 )
    ->maidenhead( 3 );
is $grid, 'NM42uc', q{Random location 937 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NM42uc' ) );
cmp_ok $lat, '==', 32.1042, q{Random location 937 latitude};
cmp_ok $lon, '==', 89.7083, q{Random location 937 longitude};

( $grid ) = $sta->geodetic( -1.14286186056574, -1.1793716567162, 0 )
    ->maidenhead( 3 );
is $grid, 'FC64fm', q{Random location 938 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FC64fm' ) );
cmp_ok $lat, '==', -65.4792, q{Random location 938 latitude};
cmp_ok $lon, '==', -67.5417, q{Random location 938 longitude};

( $grid ) = $sta->geodetic( -0.229963053296712, 0.830968427009253, 0 )
    ->maidenhead( 3 );
is $grid, 'LH36tt', q{Random location 939 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LH36tt' ) );
cmp_ok $lat, '==', -13.1875, q{Random location 939 latitude};
cmp_ok $lon, '==', 47.625, q{Random location 939 longitude};

( $grid ) = $sta->geodetic( -0.179382367687992, -1.02509151321387, 0 )
    ->maidenhead( 3 );
is $grid, 'GH09pr', q{Random location 940 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GH09pr' ) );
cmp_ok $lat, '==', -10.2708, q{Random location 940 latitude};
cmp_ok $lon, '==', -58.7083, q{Random location 940 longitude};

( $grid ) = $sta->geodetic( 1.18993353353103, 2.30298658287265, 0 )
    ->maidenhead( 3 );
is $grid, 'PP58xe', q{Random location 941 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PP58xe' ) );
cmp_ok $lat, '==', 68.1875, q{Random location 941 latitude};
cmp_ok $lon, '==', 131.958, q{Random location 941 longitude};

( $grid ) = $sta->geodetic( -0.374610087192814, 2.48583346478622, 0 )
    ->maidenhead( 3 );
is $grid, 'QG18fm', q{Random location 942 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG18fm' ) );
cmp_ok $lat, '==', -21.4792, q{Random location 942 latitude};
cmp_ok $lon, '==', 142.458, q{Random location 942 longitude};

( $grid ) = $sta->geodetic( -0.00701154990657082, 1.91034080107417, 0 )
    ->maidenhead( 3 );
is $grid, 'OI49ro', q{Random location 943 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OI49ro' ) );
cmp_ok $lat, '==', -0.395833, q{Random location 943 latitude};
cmp_ok $lon, '==', 109.458, q{Random location 943 longitude};

( $grid ) = $sta->geodetic( 0.0945430319111924, -2.9628046024388, 0 )
    ->maidenhead( 3 );
is $grid, 'AJ55ck', q{Random location 944 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AJ55ck' ) );
cmp_ok $lat, '==', 5.4375, q{Random location 944 latitude};
cmp_ok $lon, '==', -169.792, q{Random location 944 longitude};

( $grid ) = $sta->geodetic( 1.02706311171183, -2.36102779458262, 0 )
    ->maidenhead( 3 );
is $grid, 'CO28iu', q{Random location 945 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CO28iu' ) );
cmp_ok $lat, '==', 58.8542, q{Random location 945 latitude};
cmp_ok $lon, '==', -135.292, q{Random location 945 longitude};

( $grid ) = $sta->geodetic( -0.880319273541772, 1.35610944773505, 0 )
    ->maidenhead( 3 );
is $grid, 'MD89un', q{Random location 946 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MD89un' ) );
cmp_ok $lat, '==', -50.4375, q{Random location 946 latitude};
cmp_ok $lon, '==', 77.7083, q{Random location 946 longitude};

( $grid ) = $sta->geodetic( -0.00412414094191438, 2.52894752837185, 0 )
    ->maidenhead( 3 );
is $grid, 'QI29ks', q{Random location 947 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI29ks' ) );
cmp_ok $lat, '==', -0.229167, q{Random location 947 latitude};
cmp_ok $lon, '==', 144.875, q{Random location 947 longitude};

( $grid ) = $sta->geodetic( 0.854922643795238, -1.75787964032892, 0 )
    ->maidenhead( 3 );
is $grid, 'DN98px', q{Random location 948 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DN98px' ) );
cmp_ok $lat, '==', 48.9792, q{Random location 948 latitude};
cmp_ok $lon, '==', -100.708, q{Random location 948 longitude};

( $grid ) = $sta->geodetic( -0.732797968642988, 1.00537146347763, 0 )
    ->maidenhead( 3 );
is $grid, 'LE88ta', q{Random location 949 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LE88ta' ) );
cmp_ok $lat, '==', -41.9792, q{Random location 949 latitude};
cmp_ok $lon, '==', 57.625, q{Random location 949 longitude};

( $grid ) = $sta->geodetic( -0.794426157484508, 0.206191084462594, 0 )
    ->maidenhead( 3 );
is $grid, 'JE54vl', q{Random location 950 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JE54vl' ) );
cmp_ok $lat, '==', -45.5208, q{Random location 950 latitude};
cmp_ok $lon, '==', 11.7917, q{Random location 950 longitude};

( $grid ) = $sta->geodetic( 0.481402245433348, 2.91189407084264, 0 )
    ->maidenhead( 3 );
is $grid, 'RL37kn', q{Random location 951 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RL37kn' ) );
cmp_ok $lat, '==', 27.5625, q{Random location 951 latitude};
cmp_ok $lon, '==', 166.875, q{Random location 951 longitude};

( $grid ) = $sta->geodetic( -1.35810003853805, -1.46509383823058, 0 )
    ->maidenhead( 3 );
is $grid, 'EB82ae', q{Random location 952 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EB82ae' ) );
cmp_ok $lat, '==', -77.8125, q{Random location 952 latitude};
cmp_ok $lon, '==', -83.9583, q{Random location 952 longitude};

( $grid ) = $sta->geodetic( 0.0892134423567987, 2.60953135953214, 0 )
    ->maidenhead( 3 );
is $grid, 'QJ45sc', q{Random location 953 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QJ45sc' ) );
cmp_ok $lat, '==', 5.10417, q{Random location 953 latitude};
cmp_ok $lon, '==', 149.542, q{Random location 953 longitude};

( $grid ) = $sta->geodetic( 0.840547436053924, 1.84910598890591, 0 )
    ->maidenhead( 3 );
is $grid, 'ON28xd', q{Random location 954 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ON28xd' ) );
cmp_ok $lat, '==', 48.1458, q{Random location 954 latitude};
cmp_ok $lon, '==', 105.958, q{Random location 954 longitude};

( $grid ) = $sta->geodetic( -0.544003813704675, 2.29442318648915, 0 )
    ->maidenhead( 3 );
is $grid, 'PF58rt', q{Random location 955 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PF58rt' ) );
cmp_ok $lat, '==', -31.1875, q{Random location 955 latitude};
cmp_ok $lon, '==', 131.458, q{Random location 955 longitude};

( $grid ) = $sta->geodetic( 1.08798743984253, 1.91989762347387, 0 )
    ->maidenhead( 3 );
is $grid, 'OP52ai', q{Random location 956 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'OP52ai' ) );
cmp_ok $lat, '==', 62.3542, q{Random location 956 latitude};
cmp_ok $lon, '==', 110.042, q{Random location 956 longitude};

( $grid ) = $sta->geodetic( -0.58492154389155, -1.05733877582871, 0 )
    ->maidenhead( 3 );
is $grid, 'FF96rl', q{Random location 957 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FF96rl' ) );
cmp_ok $lat, '==', -33.5208, q{Random location 957 latitude};
cmp_ok $lon, '==', -60.5417, q{Random location 957 longitude};

( $grid ) = $sta->geodetic( 0.970730731180608, 2.88862692304839, 0 )
    ->maidenhead( 3 );
is $grid, 'RO25so', q{Random location 958 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RO25so' ) );
cmp_ok $lat, '==', 55.6042, q{Random location 958 latitude};
cmp_ok $lon, '==', 165.542, q{Random location 958 longitude};

( $grid ) = $sta->geodetic( -0.355309499309892, 2.68538567886786, 0 )
    ->maidenhead( 3 );
is $grid, 'QG69wp', q{Random location 959 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QG69wp' ) );
cmp_ok $lat, '==', -20.3542, q{Random location 959 latitude};
cmp_ok $lon, '==', 153.875, q{Random location 959 longitude};

( $grid ) = $sta->geodetic( -0.958520717684621, 1.33330740157393, 0 )
    ->maidenhead( 3 );
is $grid, 'MD85eb', q{Random location 960 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MD85eb' ) );
cmp_ok $lat, '==', -54.9375, q{Random location 960 latitude};
cmp_ok $lon, '==', 76.375, q{Random location 960 longitude};

( $grid ) = $sta->geodetic( -0.340229242112589, 1.59108596023082, 0 )
    ->maidenhead( 3 );
is $grid, 'NH50nm', q{Random location 961 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NH50nm' ) );
cmp_ok $lat, '==', -19.4792, q{Random location 961 latitude};
cmp_ok $lon, '==', 91.125, q{Random location 961 longitude};

( $grid ) = $sta->geodetic( -0.842787806183325, -0.23463561811847, 0 )
    ->maidenhead( 3 );
is $grid, 'IE31gr', q{Random location 962 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IE31gr' ) );
cmp_ok $lat, '==', -48.2708, q{Random location 962 latitude};
cmp_ok $lon, '==', -13.4583, q{Random location 962 longitude};

( $grid ) = $sta->geodetic( 0.249114231869851, 0.228578342436794, 0 )
    ->maidenhead( 3 );
is $grid, 'JK64ng', q{Random location 963 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JK64ng' ) );
cmp_ok $lat, '==', 14.2708, q{Random location 963 latitude};
cmp_ok $lon, '==', 13.125, q{Random location 963 longitude};

( $grid ) = $sta->geodetic( 0.330715998357623, 1.36905166812343, 0 )
    ->maidenhead( 3 );
is $grid, 'MK98fw', q{Random location 964 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MK98fw' ) );
cmp_ok $lat, '==', 18.9375, q{Random location 964 latitude};
cmp_ok $lon, '==', 78.4583, q{Random location 964 longitude};

( $grid ) = $sta->geodetic( 0.481336177124096, 1.44413765728577, 0 )
    ->maidenhead( 3 );
is $grid, 'NL17in', q{Random location 965 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL17in' ) );
cmp_ok $lat, '==', 27.5625, q{Random location 965 latitude};
cmp_ok $lon, '==', 82.7083, q{Random location 965 longitude};

( $grid ) = $sta->geodetic( 0.613979235430208, -1.57305728124143, 0 )
    ->maidenhead( 3 );
is $grid, 'EM45we', q{Random location 966 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EM45we' ) );
cmp_ok $lat, '==', 35.1875, q{Random location 966 latitude};
cmp_ok $lon, '==', -90.125, q{Random location 966 longitude};

( $grid ) = $sta->geodetic( -0.837611669815022, 2.62364114601487, 0 )
    ->maidenhead( 3 );
is $grid, 'QE52da', q{Random location 967 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QE52da' ) );
cmp_ok $lat, '==', -47.9792, q{Random location 967 latitude};
cmp_ok $lon, '==', 150.292, q{Random location 967 longitude};

( $grid ) = $sta->geodetic( 1.06017209518346, -2.29954205066731, 0 )
    ->maidenhead( 3 );
is $grid, 'CP40cr', q{Random location 968 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CP40cr' ) );
cmp_ok $lat, '==', 60.7292, q{Random location 968 latitude};
cmp_ok $lon, '==', -131.792, q{Random location 968 longitude};

( $grid ) = $sta->geodetic( -0.931471859249061, -0.219068916308079, 0 )
    ->maidenhead( 3 );
is $grid, 'ID36rp', q{Random location 969 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'ID36rp' ) );
cmp_ok $lat, '==', -53.3542, q{Random location 969 latitude};
cmp_ok $lon, '==', -12.5417, q{Random location 969 longitude};

( $grid ) = $sta->geodetic( 0.86422777642511, 2.25654525026156, 0 )
    ->maidenhead( 3 );
is $grid, 'PN49pm', q{Random location 970 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PN49pm' ) );
cmp_ok $lat, '==', 49.5208, q{Random location 970 latitude};
cmp_ok $lon, '==', 129.292, q{Random location 970 longitude};

( $grid ) = $sta->geodetic( -0.20649006862226, -1.63029482777459, 0 )
    ->maidenhead( 3 );
is $grid, 'EH38he', q{Random location 971 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EH38he' ) );
cmp_ok $lat, '==', -11.8125, q{Random location 971 latitude};
cmp_ok $lon, '==', -93.375, q{Random location 971 longitude};

( $grid ) = $sta->geodetic( 0.297055191898861, -1.27639827936512, 0 )
    ->maidenhead( 3 );
is $grid, 'FK37ka', q{Random location 972 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FK37ka' ) );
cmp_ok $lat, '==', 17.0208, q{Random location 972 latitude};
cmp_ok $lon, '==', -73.125, q{Random location 972 longitude};

( $grid ) = $sta->geodetic( -0.865767628403757, 3.01618156773646, 0 )
    ->maidenhead( 3 );
is $grid, 'RE60jj', q{Random location 973 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RE60jj' ) );
cmp_ok $lat, '==', -49.6042, q{Random location 973 latitude};
cmp_ok $lon, '==', 172.792, q{Random location 973 longitude};

( $grid ) = $sta->geodetic( 0.558529170651672, 0.36775120318824, 0 )
    ->maidenhead( 3 );
is $grid, 'KM02ma', q{Random location 974 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KM02ma' ) );
cmp_ok $lat, '==', 32.0208, q{Random location 974 latitude};
cmp_ok $lon, '==', 21.0417, q{Random location 974 longitude};

( $grid ) = $sta->geodetic( -0.903942638636638, -2.60188442773112, 0 )
    ->maidenhead( 3 );
is $grid, 'BD58le', q{Random location 975 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BD58le' ) );
cmp_ok $lat, '==', -51.8125, q{Random location 975 latitude};
cmp_ok $lon, '==', -149.042, q{Random location 975 longitude};

( $grid ) = $sta->geodetic( -1.03348429988551, 0.252160305732765, 0 )
    ->maidenhead( 3 );
is $grid, 'JD70fs', q{Random location 976 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JD70fs' ) );
cmp_ok $lat, '==', -59.2292, q{Random location 976 latitude};
cmp_ok $lon, '==', 14.4583, q{Random location 976 longitude};

( $grid ) = $sta->geodetic( 0.25252746000245, -2.04089606800409, 0 )
    ->maidenhead( 3 );
is $grid, 'DK14ml', q{Random location 977 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DK14ml' ) );
cmp_ok $lat, '==', 14.4792, q{Random location 977 latitude};
cmp_ok $lon, '==', -116.958, q{Random location 977 longitude};

( $grid ) = $sta->geodetic( 0.968458330437157, -2.23075955170899, 0 )
    ->maidenhead( 3 );
is $grid, 'CO65cl', q{Random location 978 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'CO65cl' ) );
cmp_ok $lat, '==', 55.4792, q{Random location 978 latitude};
cmp_ok $lon, '==', -127.792, q{Random location 978 longitude};

( $grid ) = $sta->geodetic( -0.698010407408746, 2.69989763396564, 0 )
    ->maidenhead( 3 );
is $grid, 'QF70ia', q{Random location 979 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QF70ia' ) );
cmp_ok $lat, '==', -39.9792, q{Random location 979 latitude};
cmp_ok $lon, '==', 154.708, q{Random location 979 longitude};

( $grid ) = $sta->geodetic( 0.404974568565502, 1.45253132276969, 0 )
    ->maidenhead( 3 );
is $grid, 'NL13oe', q{Random location 980 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'NL13oe' ) );
cmp_ok $lat, '==', 23.1875, q{Random location 980 latitude};
cmp_ok $lon, '==', 83.2083, q{Random location 980 longitude};

( $grid ) = $sta->geodetic( -0.493182608367482, 2.29816001492279, 0 )
    ->maidenhead( 3 );
is $grid, 'PG51ur', q{Random location 981 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'PG51ur' ) );
cmp_ok $lat, '==', -28.2708, q{Random location 981 latitude};
cmp_ok $lon, '==', 131.708, q{Random location 981 longitude};

( $grid ) = $sta->geodetic( -0.630647732951714, 0.840089869555689, 0 )
    ->maidenhead( 3 );
is $grid, 'LF43bu', q{Random location 982 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LF43bu' ) );
cmp_ok $lat, '==', -36.1458, q{Random location 982 latitude};
cmp_ok $lon, '==', 48.125, q{Random location 982 longitude};

( $grid ) = $sta->geodetic( 0.613556032137989, 1.30698507366809, 0 )
    ->maidenhead( 3 );
is $grid, 'MM75kd', q{Random location 983 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM75kd' ) );
cmp_ok $lat, '==', 35.1458, q{Random location 983 latitude};
cmp_ok $lon, '==', 74.875, q{Random location 983 longitude};

( $grid ) = $sta->geodetic( -0.0874018207571752, 1.03753518361778, 0 )
    ->maidenhead( 3 );
is $grid, 'LI94rx', q{Random location 984 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'LI94rx' ) );
cmp_ok $lat, '==', -5.02083, q{Random location 984 latitude};
cmp_ok $lon, '==', 59.4583, q{Random location 984 longitude};

( $grid ) = $sta->geodetic( 0.0900237088295224, 0.225549234834714, 0 )
    ->maidenhead( 3 );
is $grid, 'JJ65ld', q{Random location 985 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JJ65ld' ) );
cmp_ok $lat, '==', 5.14583, q{Random location 985 latitude};
cmp_ok $lon, '==', 12.9583, q{Random location 985 longitude};

( $grid ) = $sta->geodetic( -0.0139569828267203, -1.84111239641489, 0 )
    ->maidenhead( 3 );
is $grid, 'DI79ge', q{Random location 986 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'DI79ge' ) );
cmp_ok $lat, '==', -0.8125, q{Random location 986 latitude};
cmp_ok $lon, '==', -105.458, q{Random location 986 longitude};

( $grid ) = $sta->geodetic( 0.641788841335638, 1.33860975909336, 0 )
    ->maidenhead( 3 );
is $grid, 'MM86is', q{Random location 987 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'MM86is' ) );
cmp_ok $lat, '==', 36.7708, q{Random location 987 latitude};
cmp_ok $lon, '==', 76.7083, q{Random location 987 longitude};

( $grid ) = $sta->geodetic( -0.084468938636945, 2.5239846287981, 0 )
    ->maidenhead( 3 );
is $grid, 'QI25hd', q{Random location 988 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QI25hd' ) );
cmp_ok $lat, '==', -4.85417, q{Random location 988 latitude};
cmp_ok $lon, '==', 144.625, q{Random location 988 longitude};

( $grid ) = $sta->geodetic( -1.3269532120159, 0.0835491515685929, 0 )
    ->maidenhead( 3 );
is $grid, 'JB23jx', q{Random location 989 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JB23jx' ) );
cmp_ok $lat, '==', -76.0208, q{Random location 989 latitude};
cmp_ok $lon, '==', 4.79167, q{Random location 989 longitude};

( $grid ) = $sta->geodetic( 0.11864857699473, -0.14381425818303, 0 )
    ->maidenhead( 3 );
is $grid, 'IJ56vt', q{Random location 990 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'IJ56vt' ) );
cmp_ok $lat, '==', 6.8125, q{Random location 990 latitude};
cmp_ok $lon, '==', -8.20833, q{Random location 990 longitude};

( $grid ) = $sta->geodetic( -0.0603439566250561, -2.87922361270067, 0 )
    ->maidenhead( 3 );
is $grid, 'AI76mn', q{Random location 991 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'AI76mn' ) );
cmp_ok $lat, '==', -3.4375, q{Random location 991 latitude};
cmp_ok $lon, '==', -164.958, q{Random location 991 longitude};

( $grid ) = $sta->geodetic( 1.24683170158775, 2.82945523278935, 0 )
    ->maidenhead( 3 );
is $grid, 'RQ11bk', q{Random location 992 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RQ11bk' ) );
cmp_ok $lat, '==', 71.4375, q{Random location 992 latitude};
cmp_ok $lon, '==', 162.125, q{Random location 992 longitude};

( $grid ) = $sta->geodetic( 0.564214717113892, 0.00422834365444968, 0 )
    ->maidenhead( 3 );
is $grid, 'JM02ch', q{Random location 993 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'JM02ch' ) );
cmp_ok $lat, '==', 32.3125, q{Random location 993 latitude};
cmp_ok $lon, '==', 0.208333, q{Random location 993 longitude};

( $grid ) = $sta->geodetic( 0.0642849702101984, -1.0706224175571, 0 )
    ->maidenhead( 3 );
is $grid, 'FJ93hq', q{Random location 994 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'FJ93hq' ) );
cmp_ok $lat, '==', 3.6875, q{Random location 994 latitude};
cmp_ok $lon, '==', -61.375, q{Random location 994 longitude};

( $grid ) = $sta->geodetic( 0.344231155900684, 0.432682832746643, 0 )
    ->maidenhead( 3 );
is $grid, 'KK29jr', q{Random location 995 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'KK29jr' ) );
cmp_ok $lat, '==', 19.7292, q{Random location 995 latitude};
cmp_ok $lon, '==', 24.7917, q{Random location 995 longitude};

( $grid ) = $sta->geodetic( -1.08550763162701, -2.75267316319573, 0 )
    ->maidenhead( 3 );
is $grid, 'BC17dt', q{Random location 996 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'BC17dt' ) );
cmp_ok $lat, '==', -62.1875, q{Random location 996 latitude};
cmp_ok $lon, '==', -157.708, q{Random location 996 longitude};

( $grid ) = $sta->geodetic( 0.205732122047679, 2.61833446808606, 0 )
    ->maidenhead( 3 );
is $grid, 'QK51as', q{Random location 997 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'QK51as' ) );
cmp_ok $lat, '==', 11.7708, q{Random location 997 latitude};
cmp_ok $lon, '==', 150.042, q{Random location 997 longitude};

( $grid ) = $sta->geodetic( 1.09882635437209, -0.911323446878234, 0 )
    ->maidenhead( 3 );
is $grid, 'GP32vw', q{Random location 998 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'GP32vw' ) );
cmp_ok $lat, '==', 62.9375, q{Random location 998 latitude};
cmp_ok $lon, '==', -52.2083, q{Random location 998 longitude};

( $grid ) = $sta->geodetic( -0.293274861691199, 2.81787148207799, 0 )
    ->maidenhead( 3 );
is $grid, 'RH03re', q{Random location 999 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'RH03re' ) );
cmp_ok $lat, '==', -16.8125, q{Random location 999 latitude};
cmp_ok $lon, '==', 161.458, q{Random location 999 longitude};

( $grid ) = $sta->geodetic( 0.334107594735464, -1.44852817840793, 0 )
    ->maidenhead( 3 );
is $grid, 'EK89md', q{Random location 1000 Maidenhead grid};
( $lat, $lon ) = latlon( $sta->maidenhead( 'EK89md' ) );
cmp_ok $lat, '==', 19.1458, q{Random location 1000 latitude};
cmp_ok $lon, '==', -82.9583, q{Random location 1000 longitude};


sub latlon {
    my ( $sta ) = @_;
    my ( $lat, $lon ) = $sta->geodetic();
    foreach ( $lat, $lon ) {
	$_ = rad2deg( $_ );
	my ( $left ) = m/ \A [+-]? ( \d+ ) /smx;
	$left
	    or $left = '';
	my $places = 6 - length $left;
	$_ = sprintf "%.${places}f", $_;
    }
    return ( $lat, $lon );
}


1;

# ex: set textwidth=72 :
