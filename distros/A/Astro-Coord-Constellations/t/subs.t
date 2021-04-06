use Test2::V0;

use Astro::Coord::Precession qw/precess precess_rad read_coordinates/;
use Astro::Coord::Constellations qw/constellation_for_eq constellations_table/;

subtest 'constellation_for_eq' => sub {
    my @test = (
        [['1h27m12.35s', '-57 30 19.2', 2021.35], 'Eri'],
        [['1h25m26.53s', '-57 27 14.9', 2021.35], 'Phe'],
        [['1h23m35.41s', '-57 55 44.8', 2021.35], 'Tuc'],
        [['1h26m10.31s', '-58 05 42.5', 2021.35], 'Hyi'],
        [['6h25m29.08s', '+12 14 31.0', 2000], 'Ori'],
        [['6h26m09.24s', '+12 01 03.0', 2000], 'Gem'],
        [['6h27m56.55s', '+11 55 15.8', 2000], 'Mon']
    );
    is(constellation_for_eq(@{$_->[0]}), $_->[1], 'Correctly identified '.$_->[1])
        for @test;
};

subtest 'constellations_table' => sub {
    my %con = constellations_table();
    is(scalar(keys %con), 88, 'All 88 IAU constellations');
    is($con{UMa}, ['Ursa Major', 'Ursae Majoris'], 'UMa entry correct');    
};

subtest '_convert_coordinates' => sub {
    my @test = (
        ['06 30 3.6', '+15 45 36'],
        ['6h30m3.6s', q{ +15d 45'36"}],
        ['6h30′3.6″', '15°45′36″'],
        ['6.501','15.76']
    );

    is(
        [Astro::Coord::Constellations::_convert_coordinates(@$_)],
        [[6.501, 15.76], undef],
        'Converted coords'
    ) for @test;
    my @test = (
        [],
        [1],
        [undef, 1],
        [undef, undef, 2000]
    );

    is(
        warnings {[Astro::Coord::Constellations::_convert_coordinates(@$_)]},
        [],
        'No warnings for undef input cases'
    ) for @test;
};

done_testing();