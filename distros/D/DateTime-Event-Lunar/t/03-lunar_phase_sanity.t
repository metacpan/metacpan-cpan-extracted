#!perl
use strict;
use Test::More qw(no_plan);
BEGIN
{
    use_ok("DateTime::Event::Lunar");
}
use constant MAX_DELTA_MINUTES => 60;

# taken from http://aa.usno.navy.mil/data/docs/MoonPhase.html
my @phases = (
    [ # new moons
        [ 2004,  1, 21, 21,  5 ],
        [ 2004,  2, 20,  9, 18 ],
        [ 2004,  3, 20, 22, 41 ],
        [ 2004,  4, 19, 13, 21 ],
        [ 2004,  5, 19,  4, 52 ],
        [ 2004,  6, 17, 20, 27 ],
        [ 2004,  7, 17, 11, 24 ],
        [ 2004,  8, 16,  1, 24 ],
        [ 2004,  9, 14, 14, 29 ],
        [ 2004, 10, 14,  2, 48 ],
        [ 2004, 11, 12, 14, 27 ],
        [ 2004, 12, 12,  1, 29 ],
    ],
    [ # first quarter
        [ 2004,  1, 29,  6,  3 ],
        [ 2004,  2, 28,  3, 24 ],
        [ 2004,  3, 28, 23, 48 ],
        [ 2004,  4, 27, 17, 32 ],
        [ 2004,  5, 27,  7, 57 ],
        [ 2004,  6, 25, 19,  8 ],
        [ 2004,  7, 25,  3, 37 ],
        [ 2004,  8, 23, 10, 12 ],
        [ 2004,  9, 21, 15, 54 ],
        [ 2004, 10, 20, 21, 59 ],
        [ 2004, 11, 19,  5, 50 ],
        [ 2004, 12, 18, 16, 40 ],
    ],
    [ # full moon
        [ 2004,  1,  7, 15, 40 ],
        [ 2004,  2,  6,  8, 47 ],
        [ 2004,  3,  6, 23, 14 ],
        [ 2004,  4,  5, 11,  3 ],
        [ 2004,  5,  4, 20, 33 ],
        [ 2004,  6,  3,  4, 20 ],
        [ 2004,  7,  2, 11,  9 ],
        [ 2004,  7, 31, 18,  5 ],
        [ 2004,  8, 30,  2, 22 ],
        [ 2004,  9, 28, 13,  9 ],
        [ 2004, 10, 28,  3,  7 ],
        [ 2004, 11, 26, 20,  7 ],
        [ 2004, 12, 26, 15,  6 ],
    ],
    [ # last quarter
        [ 2004,  1, 15,  4, 46 ],
        [ 2004,  2, 13, 13, 40 ],
        [ 2004,  3, 13, 21,  1 ],
        [ 2004,  4, 12,  3, 46 ],
        [ 2004,  5, 11, 11,  4 ],
        [ 2004,  6,  9, 20,  2 ],
        [ 2004,  7,  9,  7, 34 ],
        [ 2004,  8,  7, 22,  1 ],
        [ 2004,  9,  6, 15, 11 ],
        [ 2004, 10,  6, 10, 12 ],
        [ 2004, 11,  5,  5, 53 ],
        [ 2004, 12,  5,  0, 53 ]
    ]
);

diag("This test will take time... please be patient.");

# XXX - I'd like to test more, but this calculation takes way too long
# now, so we'll just test 3 dates
for(0..2) {
    my $phase_index = int(rand(4));
    my $phase       = $phase_index * 90;
    my $phase_dates = $phases[$phase_index];
    my $phase_size  = scalar(@$phase_dates);
    my $random_date = $phases[$phase_index][int(rand($phase_size))];

    my %args;
    @args{ qw(year month day hour minute time_zone) } = (@$random_date, 'UTC');
    my $dt = DateTime->new(%args);

    my $dt0 = $dt - DateTime::Duration->new(days => 15);
    
    my $rv = DateTime::Event::Lunar->lunar_phase_after(
        datetime => $dt0,
        phase    => $phase
    );

    check_deltas($rv, $dt);
}

sub check_deltas
{
	my($expected, $actual) = @_;

	my $diff = $expected - $actual;
	ok($diff);

	# make sure the deltas do not exceed 3 hours
	my %deltas = $diff->deltas;
	ok( $deltas{months} == 0 &&
		$deltas{days} == 0 &&
		abs($deltas{minutes}) < MAX_DELTA_MINUTES) or
	diag( "Expected new moon date was " . 
		$expected->strftime("%Y/%m/%d %T") . " but instead we got " .
		$actual->strftime("%Y/%m/%d %T") .
		" which is more than allowed delta of " .
		MAX_DELTA_MINUTES . " minutes" );
}
	

