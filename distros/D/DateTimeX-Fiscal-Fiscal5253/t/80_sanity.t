use strict;
use warnings;

use Test::More;
plan( tests => 785 );

require DateTimeX::Fiscal::Fiscal5253;
my $class = 'DateTimeX::Fiscal::Fiscal5253';

# This script tests the basic calculations to be sure the proper relations
# between various values are present in both normal and 53 week years.

# Loop through 5 years worth of combinations.
# test only one param at a time, an exhaustive test of every combination
# is over 1000 tests/year. This is 175 tests/year on average.

for my $yr ( 2011 .. 2015 ) {
    for my $endm ( 1 .. 12 ) {
        my $params = { year => $yr, end_month => $endm };
        test_oneyear( $class, $params );    # test end_month values
    }
    for my $dow ( 1 .. 7 ) {
        my $params = { year => $yr, end_dow => $dow };
        test_oneyear( $class, $params );    # test end_dow values
    }
    for my $type (qw( last closest )) {
        my $params = { year => $yr, end_type => $type };
        test_oneyear( $class, $params );    # test end_type values
    }
    for my $leap_p (qw( first last )) {
        my $params = { year => $yr, leap_period => $leap_p };
        test_oneyear( $class, $params );    # test leap_period values
    }
}

done_testing();

exit;

sub test_oneyear {
    my $class  = shift;
    my $params = shift;

    my $fc       = $class->new( %{$params} );
    my $real_dow = $fc->{_end}->dow;
    ok( $real_dow == $fc->end_dow, 'correct end_dow' );
    ok( $fc->contains( date => $fc->{_start_ymd} ) == 1,
        'contains start date in period 1' );
    ok( $fc->contains( date => $fc->{_end_ymd} ) == $fc->weeks,
        'contains end date in period 12' );
    ok( !$fc->contains( date => $fc->{_start}->clone->subtract( days => 1 ) ),
        'does not contain day before start date' );
    ok( !$fc->contains( date => $fc->{_end}->clone->add( days => 1 ) ),
        'does not contain day after end date' );

    if ( $fc->has_leap_week ) {
        my $dt = $fc->{_start}->clone->add( days => 6 );
        ok(
            !$fc->contains( date => $dt, style => 'Restated' ),
            'Restated calendar does not have first week'
        );
        $dt->add( days => 1 );
        ok(
            $dt->ymd eq $fc->{_restated}->{summary}->{start},
            'Restated start date is one week after base start'
        );
        ok(
            $fc->contains( date => $dt, style => 'Restated' ),
            'Restated calendar contains own start'
        );
        ok(
            $fc->{_restated}->{summary}->{style} eq 'restated',
            'Restated has correct name in calendar summary record'
        );
        $dt = $fc->{_end}->clone->subtract( days => 6 );
        ok(
            !$fc->contains( date => $dt, style => 'Truncated' ),
            'Truncated calendar does not have last week'
        );
        $dt->subtract( days => 1 );
        ok(
            $dt->ymd eq $fc->{_truncated}->{summary}->{end},
            'Truncated start date is one week before base end'
        );
        ok( $fc->contains( date => $dt, style => 'Truncated' ),
            'Truncated calendar contains own end' );
        ok(
            $fc->{_truncated}->{summary}->{style} eq 'truncated',
            'Truncated has correct name in calendar summary record'
        );

        if ( $fc->leap_period eq 'first' ) {
            cmp_ok(
                $fc->period_weeks( period => 1 ),
                '==',
                $fc->period_weeks( period => 4 ) + 1,
                'period 1 has an extra week'
            );
            cmp_ok(
                $fc->period_weeks( period => 12 ),
                '==',
                $fc->period_weeks( period => 9 ),
                'period 12 does not have an extra week'
            );
        }
        elsif ( $fc->leap_period eq 'last' ) {
            cmp_ok(
                $fc->period_weeks( period => 1 ),
                '==',
                $fc->period_weeks( period => 4 ),
                'period 1 does not have an extra week'
            );
            cmp_ok(
                $fc->period_weeks( period => 12 ),
                '==',
                $fc->period_weeks( period => 9 ) + 1,
                'period 12 has an extra week'
            );
        }
        else {
            fail('How the hell did we get here?');
        }
    }
}

__END__
