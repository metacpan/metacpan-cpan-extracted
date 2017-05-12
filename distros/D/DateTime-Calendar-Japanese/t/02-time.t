#!perl
use Test::More (tests => 10);
BEGIN
{
    use_ok("DateTime::Calendar::Japanese");
}

my $dt = DateTime->new(year => 2004, month => 1, day => 1, hour => 12, time_zone => 'Asia/Tokyo');
my $jc = DateTime::Calendar::Japanese->from_object(object => $dt);

is($jc->hour, 4);
is($jc->canonical_hour, 9);
is($jc->hour_quarter, 1);

# since the hours are not precise, it's very hard to compare.
# we're going to fall back here and make sure that it's about
# the expected hour
# XXX - bad bad for exposing internals. just for testing. don't do this
# at home, boys

# save this data to make sure we haven't changed dates
my($previous_dt) = $jc->{gregorian}->clone->truncate(to => 'day');

$jc->set(hour => 9);
is($jc->hour, 9);
# on this date, the hour should be somewhere around 21h
is($jc->{gregorian}->hour, 21);
is($jc->{gregorian}->clone->truncate(to => 'day')->compare($previous_dt), 0);

$jc->set(hour => 12);
is($jc->hour, 12);
is($jc->{gregorian}->hour, 4);
is($jc->{gregorian}->clone->truncate(to => 'day')->compare($previous_dt), 0);
