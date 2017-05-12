use strict;
use Test::More (tests => 12);

BEGIN
{
    use_ok("DateTime::Util::Astro::Moon", "nth_new_moon");
}
use constant LUNATION => 0;
use constant YEAR     => 1;
use constant MONTH    => 2;
use constant DAY      => 3;
use constant HOUR     => 4;
use constant MINUTE   => 5;

my $allowed = 900;
my @dataset = (
    [ 22248, 1799, 10, 28, 17, 20 ],
    [ 22249, 1799, 11, 27,  3, 38 ],
    [ 22250, 1799, 12, 26, 14, 56 ],
    [ 22251, 1800,  1, 25,  3, 21 ],
    [ 22252, 1800,  2, 23, 17,  8 ],
    [ 22253, 1800,  3, 25,  8, 21 ],
    [ 24573, 1987, 10, 22, 17, 27 ],
    [ 24574, 1987, 11, 21,  6, 33 ],
    [ 24575, 1987, 12, 20, 18, 25 ],
    [ 24576, 1988,  1, 19,  5, 26 ],
    [ 24577, 1988,  2, 17, 15, 54 ],
);

foreach my $set (@dataset) {
    my $dt_got  = nth_new_moon($set->[ LUNATION ]);
    my $dt_want = DateTime->new(
        year   => $set->[ YEAR ],
        month  => $set->[ MONTH ],
        day    => $set->[ DAY ],
        hour   => $set->[ HOUR ],
        minute => $set->[ MINUTE ]
    );

    my $duration = abs($dt_got->epoch - $dt_want->epoch);
    ok( $duration < $allowed, "want $dt_want, got $dt_got (delta = $duration)" );
}
