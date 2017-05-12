use strict;
use warnings;
use Test::More;
use Test::MockTime qw(:all);
use DateTimeX::Immutable;

# Make DateTime think today is Tue Jul 15 12:15:00 2014 America/New_York
our $time = 1405440900;
set_absolute_time($time);

# Several DateTime methods return durations. They mutate during the processing
# so we need to wrap them.
my $now = DateTimeX::Immutable->now;
my $five_days = $now->plus( days => 5 );
is( $now->delta_ms( $now->plus( minutes => 5 ) )->minutes, 5, 'delta_ms' );
is( $now->delta_md($five_days)->days,          5, 'delta_md' );
is( $now->delta_days($five_days)->days,        5, 'delta_days' );
is( $now->subtract_datetime($five_days)->days, 5, 'subtract_datetime' );
is(
    $now->subtract_datetime_absolute($five_days)->seconds,
    5 * 24 * 60 * 60,
    'subtract_datetime_absolute'
);

done_testing;

