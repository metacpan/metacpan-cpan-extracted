package DateTime::Astro;
use strict;
use Math::BigFloat ('lib'     => 'GMP,Pari,FastCalc');
use Math::BigInt   ('upgrade' => 'Math::BigFloat');
use Math::Trig();
use POSIX ();
use DateTime;

use constant MEAN_SYNODIC_MONTH => 29.530588853;
use constant RD_GREGORIAN_EPOCH => 1;
use constant RD_MOMENT_1900_JAN_1 =>
    (DateTime->new(year => 1900, month => 1, day => 1)->utc_rd_values)[0];
use constant RD_MOMENT_1810_JAN_1 => Math::BigFloat->new('660724.5');
use constant RD_MOMENT_J2000      => Math::BigFloat->new('730120.5');
use constant MEAN_TROPICAL_YEAR   => Math::BigFloat->new('365.242189');

use constant LUNAR_LONGITUDE_ARGS => [
    # left side of table 12.5 , [1] p192
    #       V  W   X   Y   Z
    [ 6288774, 0,  0,  1,  0 ],
    [  658314, 2,  0,  0,  0 ],
    [ -185116, 0,  1,  0,  0 ],
    [   58793, 2,  0, -2,  0 ],
    [   53322, 2,  0,  1,  0 ],
    [  -40923, 0,  1, -1,  0 ],
    [  -30383, 0,  1,  1,  0 ],
    [  -12528, 0,  0,  1,  2 ],
    [   10675, 4,  0, -1,  0 ],
    [    8548, 4,  0, -2,  0 ],
    [   -6766, 2,  1,  0,  0 ],
    [    4987, 1,  1,  0,  0 ],
    [    3994, 2,  0,  2,  0 ],
    [    3665, 2,  0, -3,  0 ],
    [   -2602, 2,  0, -1,  2 ],
    [   -2348, 1,  0,  1,  0 ],
    [   -2120, 0,  1,  2,  0 ],
    [    2048, 2, -2, -1,  0 ],
    [   -1595, 2,  0,  0,  2 ],
    [   -1110, 0,  0,  2,  2 ],
    [    -810, 2,  1,  1,  0 ],
    [    -713, 0,  2, -1,  0 ],
    [     691, 2,  1, -2,  0 ],
    [     549, 4,  0,  1,  0 ],
    [     520, 4, -1,  0,  0 ],
    [    -399, 2,  1,  0, -2 ],
    [     351, 1,  1,  1,  0 ],
    [     330, 4,  0, -3,  0 ],
    [    -323, 0,  2,  1,  0 ],
    [     294, 2,  0,  3,  0 ],

    # right side of table 12.5 , [1] p192
    [ 1274027, 2,  0, -1,  0 ],
    [  213618, 0,  0,  2,  0 ],
    [ -114332, 0,  0,  0,  2 ],
    [   57066, 2, -1, -1,  0 ],
    [   45758, 2, -1,  0,  0 ],
    [  -34720, 1,  0,  0,  0 ],
    [   15327, 2,  0,  0, -2 ],
    [   10980, 0,  0,  1, -2 ],
    [   10034, 0,  0,  3,  0 ],
    [   -7888, 2,  1, -1,  0 ],
    [   -5163, 1,  0, -1,  0 ],
    [    4036, 2, -1,  1,  0 ],
    [    3861, 4,  0,  0,  0 ],
    [   -2689, 0,  1, -2,  0 ],
    [    2390, 2, -1, -2,  0 ],
    [    2236, 2, -2,  0,  0 ],
    [   -2069, 0,  2,  0,  0 ],
    [   -1773, 2,  0,  1, -2 ],
    [    1215, 4, -1, -1,  0 ],
    [    -892, 3,  0, -1,  0 ],
    [     759, 4, -1, -2,  0 ],
    [    -700, 2,  2, -1,  0 ],
    [     596, 2, -1,  0, -2 ],
    [     537, 0,  0,  4,  0 ],
    [    -487, 1,  0, -2,  0 ],
    [    -381, 0,  0,  2, -2 ],
    [    -340, 3,  0, -2,  0 ],
    [     327, 2, -1,  2,  0 ],
    [     299, 1,  1, -1,  0 ]
];

# [1] p.189
use constant NTH_NEW_MOON_CORRECTION_ARGS => [
    #        V  W   X  Y   Z
    [ -0.40720, 0,  0, 1,  0 ],
    [  0.01608, 0,  0, 2,  0 ],
    [  0.00739, 1, -1, 1,  0 ],
    [  0.00208, 2,  2, 0,  0 ],
    [ -0.00057, 0,  0, 1,  2 ],
    [ -0.00042, 0,  0, 3,  0 ],
    [  0.00038, 1,  1, 0, -2 ],
    [ -0.00007, 0,  2, 1,  0 ],
    [  0.00004, 0,  3, 0,  0 ],
    [  0.00003, 0,  0, 2,  2 ],
    [  0.00003, 0, -1, 1,  2 ],
    [ -0.00002, 0,  1, 3,  0 ],

    [  0.17241, 1,  1, 0,  0 ],
    [  0.01039, 0,  0, 0,  2 ],
    [ -0.00514, 1,  1, 1,  0 ],
    [ -0.00111, 0,  0, 1, -2 ],
    [  0.00056, 1,  1, 2,  0 ],
    [  0.00042, 1,  1, 0,  2 ],
    [ -0.00024, 1, -1, 2,  0 ],
    [  0.00004, 0,  0, 2, -2 ],
    [  0.00003, 0,  1, 1, -2 ],
    [ -0.00003, 0,  1, 1,  2 ],
    [ -0.00002, 0, -1, 1, -2 ],
    [  0.00002, 0,  0, 4,  0 ]
];

# [1] p.189
use constant NTH_NEW_MOON_ADDITIONAL_ARGS => [
    #      I          J         L
    [ 251.88,  0.016321, 0.000165 ],
    [ 349.42, 36.412478, 0.000126 ],
    [ 141.74, 53.303771, 0.000062 ],
    [ 154.84,  7.306860, 0.000056 ],
    [ 207.19,  0.121824, 0.000042 ],
    [ 161.72, 24.198154, 0.000037 ],
    [ 331.55,  3.592518, 0.000023 ],

    [ 251.83, 26.641886, 0.000164 ],
    [  84.66, 18.206239, 0.000110 ],
    [ 207.14,  2.453732, 0.000060 ],
    [  34.52, 27.261239, 0.000047 ],
    [ 291.34,  1.844379, 0.000040 ],
    [ 239.56, 25.513099, 0.000035 ]
];

# [1] Table 12.1 p.183 (zero-padded to align veritcally)
use constant SOLAR_LONGITUDE_ARGS => [
    #      X          Y             Z
    # left side of table 12.1
    [ '403406', '270.54861',      '0.9287892' ],
    [ '119433',  '63.91854',  '35999.4089666' ],
    [   '3891', '317.84300',  '71998.2026100' ],
    [   '1721', '240.05200',  '36000.3572600' ],
    [    '350', '247.23000',  '32964.4678000' ],
    [    '314', '297.82000', '445267.1117000' ],
    [    '242', '166.79000',      '3.1008000' ],
    [    '158',   '3.50000',    '-19.9739000' ],
    [    '129', '182.95000',   '9038.0293000' ],
    [     '99',  '29.80000',  '33718.1480000' ],
    [     '86', '249.20000',  '-2280.7730000' ],
    [     '72', '257.80000',  '31556.4930000' ],
    [     '64',  '69.90000',   '9037.7500000' ],
    [     '38', '197.10000',  '-4444.1760000' ],
    [     '32',  '65.30000',  '67555.3160000' ],
    [     '28', '341.50000',  '-4561.5400000' ],
    [     '27',  '98.50000',   '1221.6550000' ],
    [     '24', '110.00000',  '31437.3690000' ],
    [     '21', '342.60000', '-31931.7570000' ],
    [     '18', '256.10000',   '1221.9990000' ],
    [     '14', '242.90000',  '-4442.0390000' ],
    [     '13', '151.80000',    '119.0660000' ],
    [     '12',  '53.30000',     '-4.5780000' ],
    [     '10', '205.70000',    '-39.1270000' ],
    [     '10', '146.10000',  '90073.7780000' ],

    # right side of table 12.1
    [ '195207', '340.19128',  '35999.1376958' ],
    [ '112392', '331.26220',  '35998.7287385' ],
    [   '2819',  '86.63100',  '71998.4403000' ],
    [    '660', '310.26000',  '71997.4812000' ],
    [    '334', '260.87000',    '-19.4410000' ],
    [    '268', '343.14000',  '45036.8840000' ],
    [    '234',  '81.53000',  '22518.4434000' ],
    [    '132', '132.75000',  '65928.9345000' ],
    [    '114', '162.03000',   '3034.7684000' ],
    [     '93', '266.40000',   '3034.4480000' ],
    [     '78', '157.60000',  '29929.9920000' ],
    [     '68', '185.10000',    '149.5880000' ],
    [     '46',   '8.00000', '107997.4050000' ],
    [     '37', '250.40000',    '151.7710000' ],
    [     '29', '162.70000',  '31556.0800000' ],
    [     '27', '291.60000', '107996.7060000' ],
    [     '25', '146.70000',  '62894.1670000' ],
    [     '21',   '5.20000',  '14578.2980000' ],
    [     '20', '230.90000',  '34777.2430000' ],
    [     '17',  '45.30000',  '62894.5110000' ],
    [     '13', '115.20000', '107997.9090000' ],
    [     '13', '285.30000',  '16859.0710000' ],
    [     '10', '126.60000',  '26895.2920000' ],
    [     '10',  '85.90000',  '12297.5360000' ]
];


sub DateTime::Astro::MemoryCache::set { shift->{$_[0]} = $_[1] }
sub DateTime::Astro::MemoryCache::get { shift->{$_[0]} }
our $CACHE = (bless {}, 'DateTime::Astro::MemoryCache');

sub __bigfloat { Math::BigFloat->new($_[0]) }
sub __mod { return $_[0] - POSIX::floor( $_[0] / $_[1] ) * $_[1] }

sub deg2rad {
    my $deg = ref($_[0]) ? $_[0]->bstr() : $_[0];
    return Math::Trig::deg2rad($deg > 360 ? $deg % 360 : $deg);
}

sub sin_deg  { CORE::sin(deg2rad($_[0])) }
sub cos_deg  { CORE::cos(deg2rad($_[0])) }

sub is_leap_year {
    return 0 if ($_[0] % 4);
    return 1 if ($_[0] % 100);
    return 0 if ($_[0] % 400);
    return 1;
}

sub fixed_from_ymd {
    my ($y, $m, $d) = @_;
    return
        365 * ($y -1) +
        POSIX::floor( ($y - 1) / 4 ) -
        POSIX::floor( ($y - 1) / 100 ) +
        POSIX::floor( ($y - 1) / 400 ) +
        POSIX::floor( (367 * $m - 362) / 12 ) +
        ( $m <= 2 ? 0 :
          $m  > 2 && is_leap_year($y) ? -1 :
          -2 
        ) + $d
    ;
}


sub gregorian_year_from_rd {
    my $rd = ref $_[0] ? int( $_[0]->bstr() ) : $_[0];
    my $approx = POSIX::floor( ($rd - RD_GREGORIAN_EPOCH + 2) * 400 / 146097 );
    my $start = RD_GREGORIAN_EPOCH + 365 * $approx + POSIX::floor($approx/4) - POSIX::floor($approx/100) + POSIX::floor($approx/400);

    if ($_[0] < $start) {
        return int( $approx );
    } else {
        return int( $approx + 1 );
    }
}

sub gregorian_components_from_rd {
    my $y = gregorian_year_from_rd( RD_GREGORIAN_EPOCH - 1 + $_[0] + 306);
    my $prior_days = $_[0] - fixed_from_ymd( $y - 1, 3, 1 );
    my $m = int( int( POSIX::floor((5 * $prior_days + 155) / 153) + 2) % 12 );
    if ($m == 0) { $m = 12 }
    $y = int ($y - POSIX::floor( ($m + 9) / 12 ));
    my $d = int( $_[0] - fixed_from_ymd($y, $m, 1) + 1);
    return ($y, $m, $d);
}

sub ymd_seconds_from_moment {
    my $rd = int( $_[0] );
    my ($y, $m, $d) = gregorian_components_from_rd( $rd );
    my $s = ( $_[0] - $rd ) * 86400;
    return ($y, $m, $d, $s);
}

sub polynomial {
    # XXX - There seems to be a bug in adding BigInt and BigFloat
    # Math::BigFloat->bzero must be used
    my $x   = __bigfloat(shift @_);
    my $v   = Math::BigFloat->bzero();
    my $ret = __bigfloat(shift @_);

    # reuse $v for sake of efficiency. we just want to check if $x
    # is zero or not
    if ($x == $v) {
        return $ret;
    }

    while (@_) {
        $v = $x * ($v + pop @_);
    }
    return $ret + $v;
}

sub dt_from_moment {
    my ($y, $m, $d, $seconds) = ymd_seconds_from_moment($_[0]);

    $y = $y->bstr() if ref $y;
    $m = $m->bstr() if ref $m;
    $d = $d->bstr() if ref $d;
    $seconds = $seconds->bstr() if ref $seconds;

    DateTime->new(
        time_zone => 'UTC',
        year => $y,
        month => $m,
        day => $d,
    )->add(seconds => $seconds);
}

# [1] p190
sub lunar_longitude_from_moment {
    my $moment = shift;

    my $c = julian_centuries($moment);
    my $mean_moon = polynomial($c,
        218.3164591, 481267.88134236, -0.0013268,
        __bigfloat(1) / 538841, __bigfloat(-1) / 65194000);
    my $elongation = polynomial($c,
        297.8502042, 445267.1115168, -0.00163,
        __bigfloat(1) / 545868, __bigfloat(-1) / 113065000);
    my $solar_anomaly = polynomial($c,
        357.5291092, 35999.0502909, -0.0001536, __bigfloat(1) / 24490000);
    my $lunar_anomaly = polynomial($c,
        134.9634114, 477198.8676313, 0.0008997,
        __bigfloat(1) / 69699, __bigfloat(-1) / 14712000);
    my $moon_node = polynomial($c,
        93.2720993, 483202.0175273, -0.0034029,
        __bigfloat(-1) / 3526000, __bigfloat(1) / 863310000);
    my $E = polynomial($c, 1, -0.002516, -0.0000074);

    my $big_ugly_number;
    my($v, $w, $x, $y, $z);
    foreach my $data (@{ LUNAR_LONGITUDE_ARGS() }) {
        ($v, $w, $x, $y, $z) = @$data;
        $big_ugly_number +=
            $v * (__bigfloat($E) ** $x) * sin_deg(
                $w * $elongation + $x * $solar_anomaly +
                $y * $lunar_anomaly + $z * $moon_node);
    }

    my $correction = __bigfloat(1 / 1000000) * $big_ugly_number;
    my $venus = __bigfloat(3958 / 1000000) * sin_deg(119.75 + $c * 131.849);
    my $jupiter = __bigfloat(318 / 1000000) * sin_deg(53.09 + $c * 479264.29);
    my $flat_earth = __bigfloat(1962 / 1000000) *
        sin_deg($mean_moon - $moon_node);
    my $base = $mean_moon + $correction + $venus +
        $jupiter + $flat_earth + nutation($moment);
# warn "mean_moon = $mean_moon\ncorrection = $correction\nvenus = $venus\njupiter = $jupiter\nflat_eartch = $flat_earth\nbase = $base";
    return __mod( $base, 360 );
}

# [1] p.187
sub nth_new_moon {
    my $n = shift;

    my $p = $CACHE->get($n);
    if ($p) {
        return $p;
    }

    my $k = $n - 24724;
    my $c = $k / 1236.85;
    my $approx = polynomial($c,
        730125.59765,
        MEAN_SYNODIC_MONTH * 1236.85,
        0.0001337,
        -0.000000150,
        0.00000000073);
    my $E = polynomial($c, 1, -0.002516, -0.0000074);
    my $solar_anomaly = polynomial($c,
        2.5534, 1236.85 * 29.10535669, -0.0000218, -0.00000011);
    my $lunar_anomaly = polynomial($c,
        201.5643, 385.81693528 * 1236.85,
        0.0107438,
        0.00001239,
        -0.000000058);
    my $moon_argument = polynomial($c,
        160.7108, 390.67050274 * 1236.85,
        -0.0016431, -0.00000227, 0.000000011);
    my $omega = polynomial($c,
        124.7746, -1.56375580 * 1236.85,
        0.0020691, 0.00000215);
    my $extra = 0.000325 * sin_deg(
        polynomial($c, 299.77, 132.8475848, -0.009173));
    my $correction = -0.00017 * sin_deg($omega);
    my $additional = 0;

    my($v, $w, $x, $y, $z);
    foreach my $data (@{ NTH_NEW_MOON_CORRECTION_ARGS() }) {
        ($v, $w, $x, $y, $z) = @$data;

        $correction += __bigfloat($v) * ($E ** $w) * sin_deg(
            $x * $solar_anomaly +
            $y * $lunar_anomaly +
            $z * $moon_argument);
    }

    my($i, $j, $l);
    foreach my $data (@{ NTH_NEW_MOON_ADDITIONAL_ARGS() }) {
        ($i, $j, $l) = @$data;
        $additional += __bigfloat($l) * sin_deg($i + $j * $k);
    }

    $p = $approx + $correction + $extra + $additional;
    $CACHE->set($n, $p);
    return $p;
}

sub lunar_phase_from_moment {
    return __mod( lunar_longitude_from_moment($_[0]) - DateTime::Astro::Sun::solar_longitude_from_moment($_[0]), 360);
}

sub dynamical_moment {
    my $correction = ephemeris_correction($_[0]);
    return $_[0] + $correction;
}

sub dt_from_dynamical {
    my $t = shift;
    return dt_from_moment( $t - ephemeris_correction($t) );
}

sub solar_longitude_from_moment {
    my $moment = shift;
    my $c = julian_centuries($moment);
# warn "julian_centuries = $c";
    my $big_ugly_number = __bigfloat(0);

    foreach my $numbers (@{ SOLAR_LONGITUDE_ARGS() }) {
        $big_ugly_number += $numbers->[0] *
            sin_deg($numbers->[1] + $numbers->[2] * $c)
    }

    my $longitude =
        __bigfloat("282.7771834") +
        __bigfloat("36000.76953744") * $c +
        __bigfloat("0.000005729577951308232") * $big_ugly_number;

    my $aberration = aberration($moment);
    my $nutation   = nutation($moment);
    my $sum        = $longitude + $aberration + $nutation;
# warn "longitude = $longitude\naberration = $aberration\nnutation = $nutation";

    return __mod($sum, 360);
}

# [1] p180
sub obliquity
{
    my $dt = shift;
    my $c  = julian_centuries($dt);
    return polynomial($c,
        angle(23, 26, 21.448),
        -1 * angle(0, 0, 46.8150),
        -1 * angle(0, 0, 0.00059),
        angle(0, 0, 0.001813)
    );
}

# [1] p171 + errata 158
my %EC;
sub ephemeris_correction {
    my $year = gregorian_year_from_rd($_[0]);
    my $correction = $EC{ $year };
    if (! $correction) {
        if (1988 <= $year && $year <= 2019) {
            $correction = EC1($year - 1933);
        } elsif (1900 <= $year && $year <= 1987) {
            $correction = EC2( EC_C($year) );
        } elsif (1800 <= $year && $year <= 1899) {
            $correction = EC3( EC_C($year) );
        } elsif (1700 <= $year && $year <= 1799) {
            $correction = EC4($year - 1700);
        } elsif (1620 <= $year && $year <= 1699) {
            $correction = EC5($year - 1600);
        } else {
            $correction = EC6( EC_X($year) );
        }
        $EC{ $year } = $correction;
    }

    return $correction;
}

my %EC_C;
sub EC_C
{
    # This value is constant for a given year
    my $value = $EC_C{ $_[0] };
    if (! defined $value) {
        my $top = (
            fixed_from_ymd( $_[0], 7, 1 )
            -
            RD_MOMENT_1900_JAN_1
        );
        $value = $top / 36525;
        $EC_C{ $_[0] } = $value;
    }
    return $value;
}

my %EC_X;
sub EC_X
{
    my $value = $EC_X{ $_[0] };
    if (! defined $value) {
        $value = (
            fixed_from_ymd( $_[0], 1, 1 ) - RD_MOMENT_1810_JAN_1
        );
        $EC_X{ $_[0] } = $value;
    }
    return $value;
}
sub EC1 { Math::BigFloat->new($_[0]) / (24 * 3600) }
sub EC2 {
    polynomial($_[0], -0.00002, 0.000297, 0.025184,
        -0.181133, 0.553040, -0.861938, 0.677066, -0.212591);
}
sub EC3 {
    polynomial($_[0], qw(
        -0.000009
         0.003844
         0.083563
         0.865736
         4.867575
        15.845535
        31.332267
        38.291999
        28.316289
        11.636204
         2.043794
    ));
}
sub EC4 {
    polynomial($_[0], 8.118780842, -0.005092142,
        0.003336121, -0.0000266484) / (24 * 3600);
}
sub EC5
{
    polynomial($_[0], 
        Math::BigFloat->new('196.58333'), Math::BigFloat->new('-4.0675'), Math::BigFloat->new('0.0219167')) / ( 24 * 3600 )
}
sub EC6
{
    ((Math::BigFloat->new($_[0]) ** 2 / Math::BigFloat->new(41048480) ) - 15) / ( 24 * 3600 )
}

# [1] p.183
sub aberration
{
    my $dt = shift;
    my $c = julian_centuries($dt);
    return Math::BigFloat->new('0.0000974') * cos_deg(Math::BigFloat->new('177.63') + Math::BigFloat->new('35999.01848') * $c) - Math::BigFloat->new('0.0005575');
}

sub julian_centuries {
    my $moment = shift;
    my $dynamical = dynamical_moment($moment);
    return ($dynamical - RD_MOMENT_J2000) / 36525;
}

# [1] p.182
sub nutation
{
    my $dt = shift;

    my $c = julian_centuries($dt);
    my $A = polynomial($c, 
        Math::BigFloat->new('124.90'), Math::BigFloat->new('-1934.134'), Math::BigFloat->new('0.002063'));
    my $B = polynomial($c, 
        Math::BigFloat->new('201.11'), Math::BigFloat->new('72001.5377'), Math::BigFloat->new('0.00057'));

    return Math::BigFloat->new('-0.004778') * sin_deg($A) + 
        Math::BigFloat->new('-0.0003667') * sin_deg($B);
}


1;
