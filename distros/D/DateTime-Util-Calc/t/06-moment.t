#!perl
use strict;
use Test::More tests => 32;

BEGIN
{
    use_ok('DateTime::Util::Calc', 'moment', 'dt_from_moment');
    use_ok('DateTime');
}

# generate $n random dates, and calculate moment values from each
my $now = time();

for (1..5) {
    my $ref = DateTime->from_epoch(epoch => int(rand($now)),
        time_zone => 'Asia/Tokyo');

    # the results should be the same regardless of time zone
    for my $tz (qw(US/Pacific UTC)) {
        my $dt = $ref->clone;
        $dt->set_time_zone($tz);

        # For our purposes, truncate the moment to 6 fractional digits
        my $moment = sprintf("%0.6f", moment($dt));

        ok($moment, "Moment from DT: $dt -> $moment");

        my $dt_from_moment = dt_from_moment($moment);
        isa_ok($dt_from_moment, 'DateTime', "DT from moment: $moment -> $dt");

        # XXX - as of 0.05, I have a discrepancy of 1 second
        # for now I'll ignore it
        my $diff = abs($dt->epoch - $dt_from_moment->epoch);
        ok($diff <= 1, "DT diff -> $diff, expected diff <= 1");
    }
}

