use Test2::V0;

use Astro::Coord::Precession qw/precess precess_rad read_coordinates/;
use Math::Trig;

subtest 'read_coordinates' => sub {
    my @tests = (
        ['06 30 3.6', '+15 45 36'],
        ['06:30:3.6', "+15\t45\t36"],
        ['6h30m3.6s',q{ +15d 45'36"}],
        ['6h30′3.6″','15°45′36″'],
        ['6.501','15.76']
    );

    is(read_coordinates($_), [6.501,15.76], 'Converted coords')
        for @tests;
    is(read_coordinates(['-1h0m','-0 45 36']), [-1,-0.76], 'Converted negative coord');
    is(read_coordinates([]), [undef, undef], 'No input / undef out');
};

my @tests = (
    [[ '12:00:00', '-20 00 0' ], [ '12:01:04.60', '-20 07 0.9' ], 2000, 2021],
    [[ '12:34:56', '12 34 56' ], [ '12:41:14.23', '11 53 44.4' ], 1875, 2000],
    [[ '00:00:00', '0 0 0' ], [ '23:57:26.27', '-0 16 42.3' ], 2000, 1950],
    [[ '00:00:00', '0 0 0' ], [ '00:02:33.73', '+0 16 42.3' ], 1950, 2000],
);

subtest 'precess' => sub {
    ok(
        comp_coord(
            precess(read_coordinates($_->[0]),$_->[2], $_->[3]),
            read_coordinates($_->[1])
        ),
        "Precess $_->[2] to $_->[3]"
    ) foreach @tests;
};

subtest 'precess_rad' => sub {
    foreach my $test (@tests) {
        my $in  = read_coordinates($test->[0]);
        my $out = read_coordinates($test->[1]);
        ok(
            comp_coord(
                precess_rad([deg2rad($in->[0]*15), deg2rad($in->[1])],$test->[2], $test->[3]),
                [deg2rad($out->[0])*15,deg2rad($out->[1])],
                deg2rad(1/60)
            ),
            "Precess $test->[2] to $test->[3]"
        );

    }
};

sub comp_coord {
    my ($a, $b, $diff) = @_;
    $diff = 1/120 unless $diff;
    return abs($a->[0]-$b->[0]) < $diff && abs($a->[1]-$b->[1]) < $diff;
}

done_testing;