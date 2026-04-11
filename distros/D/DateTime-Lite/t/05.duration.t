#!perl
##----------------------------------------------------------------------------
## Lightweight DateTime Alternative - t/05.duration.t
##----------------------------------------------------------------------------
use strict;
use warnings;
use lib './lib';
use Test::More;
use Scalar::Util ();

use_ok( 'DateTime::Lite::Duration' ) or BAIL_OUT( 'Cannot load DateTime::Lite::Duration' );

# NOTE: Basic constructor and accessors
subtest 'Basic constructor and accessors' => sub
{
    my $dur = DateTime::Lite::Duration->new(
        years       => 2,
        months      => 3,
        weeks       => 1,
        days        => 4,
        hours       => 5,
        minutes     => 10,
        seconds     => 30,
        nanoseconds => 500_000_000,
    );
    ok( defined( $dur ), 'Duration->new() works' );
    isa_ok( $dur, 'DateTime::Lite::Duration' );

    is( $dur->years,    2,  'years' );
    is( $dur->months,   3,  'months (within year)' );
    is( $dur->weeks,    1,  'weeks' );
    is( $dur->days,     4,  'days (within week)' );
    is( $dur->hours,    5,  'hours' );
    is( $dur->minutes,  10, 'minutes (within hour)' );
    is( $dur->seconds,  30, 'seconds' );
    is( $dur->nanoseconds, 500_000_000, 'nanoseconds' );
};

# NOTE: weeks -> days conversion
subtest 'weeks -> days conversion' => sub
{
    my $dur = DateTime::Lite::Duration->new( weeks => 2 );
    is( $dur->delta_days, 14, '2 weeks = 14 days in delta_days' );
};

# NOTE: hours -> minutes conversion
subtest 'hours -> minutes conversion' => sub
{
    my $dur = DateTime::Lite::Duration->new( hours => 2 );
    is( $dur->delta_minutes, 120, '2 hours = 120 minutes in delta_minutes' );
};

# NOTE: nanosecond normalisation across seconds
subtest 'nanosecond normalisation across seconds' => sub
{
    my $dur = DateTime::Lite::Duration->new( nanoseconds => 1_500_000_000 );
    is( $dur->delta_seconds,     1,           'overflow ns: extra second' );
    is( $dur->delta_nanoseconds, 500_000_000, 'overflow ns: remaining nanoseconds' );
};

# NOTE: Predicates
subtest 'Predicates' => sub
{
    my $pos = DateTime::Lite::Duration->new( days => 1 );
    ok( $pos->is_positive,  'positive duration' );
    ok( !$pos->is_negative, 'not negative' );
    ok( !$pos->is_zero,     'not zero' );

    my $neg = DateTime::Lite::Duration->new( days => -1 );
    ok( $neg->is_negative,  'negative duration' );
    ok( !$neg->is_positive, 'not positive' );

    my $zero = DateTime::Lite::Duration->new;
    ok( $zero->is_zero, 'zero duration' );
};

# NOTE: inverse
subtest 'inverse' => sub
{
    my $dur = DateTime::Lite::Duration->new( days => 5, hours => 3 );
    my $inv = $dur->inverse;
    is( $inv->delta_days,    -5,   'inverse days' );
    is( $inv->delta_minutes, -180, 'inverse minutes (3h = 180m)' );
};

# NOTE: clone
subtest 'clone' => sub
{
    my $dur  = DateTime::Lite::Duration->new( months => 6 );
    my $dup  = $dur->clone;
    is( $dup->delta_months, 6, 'clone: months' );
    isnt( Scalar::Util::refaddr( $dur ), Scalar::Util::refaddr( $dup ), 'clone is a different reference' );
};

# NOTE: deltas() hash
subtest 'deltas() hash' => sub
{
    my $dur = DateTime::Lite::Duration->new( days => 3, seconds => 10 );
    my %d   = $dur->deltas;
    is( $d{days},    3,  'deltas: days' );
    is( $d{seconds}, 10, 'deltas: seconds' );
    is( $d{months},  0,  'deltas: months defaults to 0' );
};

# NOTE: calendar_duration / clock_duration
subtest 'calendar_duration / clock_duration' => sub
{
    my $dur = DateTime::Lite::Duration->new(
        months => 2, days => 5, hours => 3, seconds => 10
    );

    my $cal = $dur->calendar_duration;
    is( $cal->delta_months,  2, 'calendar_duration: months' );
    is( $cal->delta_days,    5, 'calendar_duration: days' );
    is( $cal->delta_minutes, 0, 'calendar_duration: no minutes' );

    my $clk = $dur->clock_duration;
    is( $clk->delta_minutes, 180, 'clock_duration: minutes (3h)' );
    is( $clk->delta_seconds, 10,  'clock_duration: seconds' );
    is( $clk->delta_months,  0,   'clock_duration: no months' );
};

# NOTE: end_of_month modes
subtest 'end_of_month modes' => sub
{
    my $dur = DateTime::Lite::Duration->new( months => 1, end_of_month => 'limit' );
    ok( $dur->is_limit_mode,     'limit mode' );
    ok( !$dur->is_wrap_mode,     'not wrap mode' );
    ok( !$dur->is_preserve_mode, 'not preserve mode' );
    is( $dur->end_of_month_mode, 'limit', 'end_of_month_mode()' );
};

# NOTE: Overloaded multiplication
subtest 'Overloaded multiplication' => sub
{
    my $dur  = DateTime::Lite::Duration->new( days => 3 );
    my $dur2 = $dur * 2;
    is( $dur2->delta_days, 6, 'overloaded *: days doubled' );
};

# NOTE: compare()
subtest 'compare()' => sub
{
    my $d1 = DateTime::Lite::Duration->new( days => 1 );
    my $d2 = DateTime::Lite::Duration->new( days => 2 );
    is( DateTime::Lite::Duration->compare( $d1, $d2 ), -1, 'compare: d1 < d2' );
    is( DateTime::Lite::Duration->compare( $d2, $d1 ),  1, 'compare: d2 > d1' );
    is( DateTime::Lite::Duration->compare( $d1, $d1 ),  0, 'compare: equal' );
};

# NOTE: in_units()
subtest 'in_units()' => sub
{
    # 14 months = 1 year + 2 months
    my $dur = DateTime::Lite::Duration->new( months => 14, days => 9, minutes => 125 );

    is( $dur->in_units( 'months' ),   14, 'in_units(months): total months' );
    is( $dur->in_units( 'days' ),      9, 'in_units(days): total days' );
    is( $dur->in_units( 'minutes' ), 125, 'in_units(minutes): total minutes' );

    # years + remaining months
    my( $years, $months ) = $dur->in_units( 'years', 'months' );
    is( $years,  1, 'in_units(years,months): years' );
    is( $months, 2, 'in_units(years,months): remainder months' );

    # weeks + remaining days
    my $dur2 = DateTime::Lite::Duration->new( days => 16 );
    my( $weeks, $days ) = $dur2->in_units( 'weeks', 'days' );
    is( $weeks, 2, 'in_units(weeks,days): weeks' );
    is( $days,  2, 'in_units(weeks,days): remainder days' );

    # hours + remaining minutes
    my $dur3 = DateTime::Lite::Duration->new( minutes => 135 );
    my( $hours, $mins ) = $dur3->in_units( 'hours', 'minutes' );
    is( $hours,  2, 'in_units(hours,minutes): hours' );
    is( $mins,  15, 'in_units(hours,minutes): remainder minutes' );

    # single unit returns scalar, not list
    my $m = $dur->in_units( 'months' );
    is( ref( \$m ), 'SCALAR', 'in_units() single unit returns scalar' );
};

done_testing;

__END__
