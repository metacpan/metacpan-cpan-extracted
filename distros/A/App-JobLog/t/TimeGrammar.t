#!/usr/bin/perl

# tests App::JobLog::TimeGrammar

use Modern::Perl;

use App::JobLog::Config qw(
  DIRECTORY
  log
  pay_period_length
  start_pay_period
);
use App::JobLog::Time qw(tz);
use App::JobLog::TimeGrammar;
use DateTime;
use File::Temp;

use Test::More;
use Test::Fatal;

# create working directory
my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;

# fix current moment
my $now = DateTime->new( year => 2011, month => 2, day => 18, time_zone => tz );
$App::JobLog::Time::now = $now;

subtest 'regressions' => sub {
    my %dates = (
        'jan 1 - 10'    => [ [qw(2011 1 1 0 0 0)],  [qw(2011 1 10 23 59 59)] ],
        'jan 1'         => [ [qw(2011 1 1 0 0 0)],  [qw(2011 1 1 23 59 59)] ],
        'december 2010' => [ [qw(2010 12 1 0 0 0)], [qw(2010 12 31 23 59 59)] ],
        '2010.12'       => [ [qw(2010 12 1 0 0 0)], [qw(2010 12 31 23 59 59)] ],
        '2011'          => [ [qw(2011 1 1 0 0 0)],  [qw(2011 12 31 23 59 59)] ],
        'jan 1 - 28'    => [ [qw(2011 1 1 0 0 0)],  [qw(2011 1 28 23 59 59)] ],
    );
    plan tests => 2 * keys %dates;
    for my $date ( sort keys %dates ) {
        my ( $s,  $e )  = parse($date);
        my ( $st, $et ) = @{ $dates{$date} };
        ok( time_test( $s, $st ), "correct start time for '$date'" );
        ok( time_test( $e, $et ), "correct end time for '$date'" );
    }
};

subtest 'single dates with times' => sub {
    my %dates = (
        'Thursday'    => [ [ 8, 30 ], [ 2011, 2, 17 ] ],
        'last Friday' => [ [ 8, 30 ], [ 2011, 2, 11 ] ],
        '2/1'         => [ [ 8, 30 ], [ 2011, 2, 1 ] ],
        '2010/2/1'    => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        '2010.2.1'    => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        '2/1/2010'    => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        '2.1.2010'    => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        'Feb 1, 2010' => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        '1 Feb, 2010' => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
        '1 Feb 2010'  => [ [ 8, 30 ], [ 2010, 2, 1 ] ],
    );
    my @variants;
    while ( my ( $expression, $times ) = each %dates ) {
        my @time = @{ $times->[0] };
        push @variants, [ $_, [ @{ $times->[1] }, @{ $times->[0] } ] ]
          for time_variants( $expression, @time );
    }
    plan tests => 3 * @variants;
    for my $variant (@variants) {
        my $expression = $variant->[0];
        my ( $s, $e, $is_interval ) = parse($expression);
        ok( time_test( $s, $variant->[1] ), "right time for '$expression' " );
        ok( !$is_interval, " determined '$expression' is not an interval " );
        ok(
            $e->hour == 23 && $e->minute == 59 && $e->second == 59,
            "inferred end time for '$expression' correctly "
        );
    }
};

subtest 'intervals' => sub {
    my @intervals = (
        [ 'yesterday - today' => [qw(2011 2 17)], [qw(2011 2 18)] ],
        [ '2011 - oct'        => [qw(2011 1 1)],  [qw(2011 10 31)] ],
        [ 'last week - today' => [qw(2011 2 6)],  [qw(2011 2 18)] ],
        [ '2011/1/1 - Mon'    => [qw(2011 1 1)],  [qw(2011 1 3)] ],
    );
    plan tests => 3 * @intervals;
    for my $interval (@intervals) {
        my ( $expression, $start, $end )         = @$interval;
        my ( $s,          $e,     $is_interval ) = parse($expression);
        ok( time_test( $s, $start ), "found start date of '$expression'" );
        ok( time_test( $e, $end ),   "found end date of '$expression'" );
        ok( $is_interval, "determined that '$expression' defines an interval" );
    }
};

subtest 'periods' => sub {
    my @intervals = (
        [ 'last week'    => [qw(2011 2 6)],  [qw(2011 2 12)] ],
        [ 'this week'    => [qw(2011 2 13)], [qw(2011 2 19)] ],
        [ 'last year'    => [qw(2010 1 1)],  [qw(2010 12 31)] ],
        [ 'october'      => [qw(2010 10 1)], [qw(2010 10 31)] ],
        [ 'last october' => [qw(2010 10 1)], [qw(2010 10 31)] ],
        [ 'this october' => [qw(2011 10 1)], [qw(2011 10 31)] ],
        [ 'this month'   => [qw(2011 2 1)],  [qw(2011 2 28)] ],
        [ 'month'        => [qw(2011 2 1)],  [qw(2011 2 28)] ],
        [ 'year'         => [qw(2011 1 1)],  [qw(2011 12 31)] ],
    );
    plan tests => 2 * @intervals;
    for my $interval (@intervals) {
        my ( $expression, $start, $end )         = @$interval;
        my ( $s,          $e,     $is_interval ) = parse($expression);
        ok( time_test( $s, $start ), "found start date of '$expression'" );
        ok( time_test( $e, $end ),   "found end date of '$expression'" );
    }
};

subtest 'pay period' => sub {
    my $start_pay_period =
      DateTime->new( year => 2011, month => 2, day => 13, time_zone => tz );
    start_pay_period($start_pay_period);
    pay_period_length(14);

    my $expression = '2011/1/4 - pp';
    my ( undef, $e ) = parse($expression);
    ok(
        $e->year == 2011 && $e->month == 1 && $e->day == 15,
        "correctly determined end of '$expression'"
    );
    $expression = 'pp - 2011/1/4';
    my ( $s, undef ) = parse($expression);
    ok(
        $s->year == 2011 && $s->month == 1 && $s->day == 2,
        "correctly determined start of '$expression'"
    );
    $expression = 'pp';
    ( $s, $e ) = parse($expression);
    ok(
        $s->year == 2011 && $s->month == 2 && $s->day == 13,
        "correctly determined start of '$expression'"
    );
    ok(
        $e->year == 2011 && $e->month == 2 && $e->day == 26,
        "correctly determined end of '$expression'"
    );
};

subtest 'tomorrow' => sub {
    my $tomorrow = $now->clone->add( days => 1 );
    my ( undef, $e ) = parse('tomorrow');
    ok(
        $e->year == $tomorrow->year
          && $e->month == $tomorrow->month
          && $e->day == $tomorrow->day,
        'correctly parsed \'tomorrow\''
    );
    my $yesterday = $now->clone->subtract( days => 1 );
    my $s;
    ( $s, $e ) = parse('yesterday - tomorrow');
    ok(
        $e->year == $tomorrow->year
          && $e->month == $tomorrow->month
          && $e->day == $tomorrow->day
          && $s->year == $yesterday->year
          && $s->month == $yesterday->month
          && $s->day == $yesterday->day,
        'correctly parsed \'yesterday - tomorrow\''
    );
};

done_testing();

sub time_test {
    my ( $date, $ar ) = @_;
    my $i = 0;
    for my $key (qw(year month day hour minute)) {
        last if $i == @$ar;
        return 0 if $date->$key != $ar->[ $i++ ];
    }
    return 1;
}

# add time to date expression in various ways
sub time_variants {
    my ( $expression, @time ) = @_;
    my @variants = map {
        (
            "at $_ on $expression",
            "$_ on $expression",
            "$expression at $_",
            "${expression}at$_",
            "$expression $_",
          )
    } clock_time_variants(@time);
    @variants = map {
        if (/at/) { ( my $v = $_ ) =~ s/at/@/; $_, $v }
        else      { $_ }
    } @variants;
    return @variants;
}

# produces a fairly thorough subset of the ways one can express a particular
# clock time
sub clock_time_variants {
    my ( $hour, $minute ) = @_;
    my $h = $hour == 0 ? 12 : $hour;
    my @base = ( sprintf '%d:%02d', $h, $minute );
    push @base, $h unless $minute;
    my @variants = $hour ? @base : ();
    my @suffixes =
      map { $_ . 'm', "$_.m.", "${_}m", "$_.m." } ( $hour < 12 ? 'a' : 'p' );
    my @hours = $hour < 13 ? ($h) : ( $h, $h - 12 );
    @hours =
      map { sprintf( '%d:%02d', $_, $minute ), $minute ? () : $_ } @hours;

    for my $base (@hours) {
        for my $suffix (@suffixes) {
            push @variants, $base . $suffix;
        }
    }

    return @variants;
}
