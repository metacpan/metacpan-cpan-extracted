# $Id: Util.pm 27589 2008-12-29 23:51:35Z daisuke $

package DateTimeX::Lite::Util;
use strict;
use warnings;

my (@MonthLengths, @LeapYearMonthLengths);
my (@EndOfLastMonthDayOfYear, @EndOfLastMonthDayOfLeapYear);
BEGIN {
    @MonthLengths = qw(31 28 31 30 31 30 31 31 30 31 30 31);
    @LeapYearMonthLengths = @MonthLengths;
    $LeapYearMonthLengths[1]++;

    {
        my $x = 0;
        foreach my $length (@MonthLengths)
        {
            push @EndOfLastMonthDayOfYear, $x;
            $x += $length;
        }
    }

    @EndOfLastMonthDayOfLeapYear = @EndOfLastMonthDayOfYear;
    $EndOfLastMonthDayOfLeapYear[$_]++ for 2..11;
}


sub month_length {
    my ($year, $month) = @_;
    return is_leap_year($year) ? 
        $LeapYearMonthLengths[$month - 1] :
        $MonthLengths[$month - 1]
    ;
}

sub is_leap_year {
    my $year = shift;

    # According to Bjorn Tackmann, this line prevents an infinite loop
    # when running the tests under Qemu. I cannot reproduce this on
    # Ubuntu or with Strawberry Perl on Win2K.
    return 0 if $year == DateTimeX::Lite::INFINITY() || $year == DateTimeX::Lite::NEG_INFINITY();
    return 0 if $year % 4;
    return 1 if $year % 100;
    return 0 if $year % 400;

    return 1;
}

sub ymd2rd {
    use integer;
    my ( $y, $m, $d ) = @_;
    my $adj;

    # make month in range 3..14 (treat Jan & Feb as months 13..14 of
    # prev year)
    if ( $m <= 2 ) {
        $y -= ( $adj = ( 14 - $m ) / 12 );
        $m += 12 * $adj;
    } elsif ( $m > 14 ) {
        $y += ( $adj = ( $m - 3 ) / 12 );
        $m -= 12 * $adj;
    }

    # make year positive (oh, for a use integer 'sane_div'!)
    if ( $y < 0 ) {
        $d -= 146097 * ( $adj = ( 399 - $y ) / 400 );
        $y += 400 * $adj;
    }

    # add: day of month, days of previous 0-11 month period that began
    # w/March, days of previous 0-399 year period that began w/March
    # of a 400-multiple year), days of any 400-year periods before
    # that, and finally subtract 306 days to adjust from Mar 1, year
    # 0-relative to Jan 1, year 1-relative (whew)

    $d += ( $m * 367 - 1094 ) / 12 + $y % 100 * 1461 / 4 +
          ( $y / 100 * 36524 + $y / 400 ) - 306;
    return $d;
}

sub time_as_seconds {
    my ( $hour, $min, $sec ) = @_;

    $hour ||= 0;
    $min ||= 0;
    $sec ||= 0;

    my $secs = $hour * 3600 + $min * 60 + $sec;
    return $secs;
}

sub normalize_nanoseconds {
    use integer;

    # seconds, nanoseconds
    if ( $_[1] < 0 )
    {
        my $overflow = 1 + $_[1] / DateTimeX::Lite::MAX_NANOSECONDS();
        $_[1] += $overflow * DateTimeX::Lite::MAX_NANOSECONDS();
        $_[0] -= $overflow;
    }
    elsif ( $_[1] >= DateTimeX::Lite::MAX_NANOSECONDS() )
    {
        my $overflow = $_[1] / DateTimeX::Lite::MAX_NANOSECONDS();
        $_[1] -= $overflow * DateTimeX::Lite::MAX_NANOSECONDS();
        $_[0] += $overflow;
    }
}

sub normalize_seconds
{
    my $dt = shift;

    return if $dt->{utc_rd_secs} >= 0 && $dt->{utc_rd_secs} <= 86399;

    if ( $dt->{tz}->is_floating )
    {
        normalize_tai_seconds( $dt->{utc_rd_days}, $dt->{utc_rd_secs} );
    }
    else
    {
        normalize_leap_seconds( $dt->{utc_rd_days}, $dt->{utc_rd_secs} );
    }
}


sub normalize_tai_seconds {
    return if grep { $_ == DateTimeX::Lite::INFINITY() || $_ == DateTimeX::Lite::NEG_INFINITY() } @_[0,1];
            
    # This must be after checking for infinity, because it breaks in
    # presence of use integer !
    use integer;
    
    my $adj;
    
    if ( $_[1] < 0 )
    {   
        $adj = ( $_[1] - 86399 ) / 86400;
    }
    else
    {
        $adj = $_[1] / 86400;
    }       
    
    $_[0] += $adj;
    
    $_[1] -= $adj * 86400;
}

sub rd2ymd
{
    use integer;
    my $d = shift;
    my $rd = $d;

    my $yadj = 0;
    my ( $c, $y, $m );

    # add 306 days to make relative to Mar 1, 0; also adjust $d to be
    # within a range (1..2**28-1) where our calculations will work
    # with 32bit ints
    if ( $d > 2**28 - 307 )
    {
        # avoid overflow if $d close to maxint        $yadj = ( $d - 146097 + 306 ) / 146097 + 1;
        $d -= $yadj * 146097 - 306;
    }
    elsif ( ( $d += 306 ) <= 0 )
    {        $yadj =
          -( -$d / 146097 + 1 );    # avoid ambiguity in C division of negatives
        $d -= $yadj * 146097;
    }

    $c = ( $d * 4 - 1 ) / 146097;   # calc # of centuries $d is after 29 Feb of yr 0
    $d -= $c * 146097 / 4;          # (4 centuries = 146097 days)
    $y = ( $d * 4 - 1 ) / 1461;     # calc number of years into the century,
    $d -= $y * 1461 / 4;            # again March-based (4 yrs =~ 146[01] days)
    $m = ( $d * 12 + 1093 ) / 367;  # get the month (3..14 represent March through
    $d -= ( $m * 367 - 1094 ) / 12; # February of following year)
    $y += $c * 100 + $yadj * 400;   # get the real year, which is off by
    ++$y, $m -= 12 if $m > 12;      # one if month is January or February

    if ( $_[0] )
    {
        my $dow;

        if ( $rd < -6 )
        {
            $dow = ( $rd + 6 ) % 7;
            $dow += $dow ? 8 : 1;
        }
        else
        {
            $dow = ( ( $rd + 6 ) % 7 ) + 1;
        }

        my $doy = end_of_last_month_day_of_year( $y, $m );

        $doy += $d;

        my $quarter;
        {
            no integer;
            $quarter = int( ( 1 / 3.1 ) * $m ) + 1;
        }

        my $qm = ( 3 * $quarter ) - 2;

        my $doq = $doy - end_of_last_month_day_of_year( $y, $qm );

        return ( $y, $m, $d, $dow, $doy, $quarter, $doq );
    }

    return ( $y, $m, $d );
}

sub end_of_last_month_day_of_year
{
    my ($y, $m) = @_;
    $m--;
    return
        ( is_leap_year($y) ?
          $EndOfLastMonthDayOfLeapYear[$m] :
          $EndOfLastMonthDayOfYear[$m]
        );
}

sub _seconds_as_components
{
    shift;
    my $secs = shift;
    my $utc_secs = shift;
    my $modifier = shift || 0;

    use integer;

    $secs -= $modifier;

    my $hour = $secs / 3600;
    $secs -= $hour * 3600;

    my $minute = $secs / 60;

    my $second = $secs - ( $minute * 60 );

    if ( $utc_secs && $utc_secs >= 86400 )
    {
        # there is no such thing as +3 or more leap seconds!
        die "Invalid UTC RD seconds value: $utc_secs"
            if $utc_secs > 86401;

        $second += $utc_secs - 86400 + 60;

        $minute  = 59;

        $hour--;
        $hour = 23 if $hour < 0;
    }

    return ( $hour, $minute, $second );
}

sub normalize_leap_seconds {
    # args: 0 => days, 1 => seconds
    my $delta_days;

    use integer;

    # rough adjust - can adjust many days
    if ( $_[1] < 0 )
    {
        $delta_days = ($_[1] - 86399) / 86400;
    }
    else
    {
        $delta_days = $_[1] / 86400;
    }

    my $new_day = $_[0] + $delta_days;
    my $delta_seconds = ( 86400 * $delta_days ) +
                        DateTimeX::Lite::LeapSecond::leap_seconds( $new_day ) -
                        DateTimeX::Lite::LeapSecond::leap_seconds( $_[0] );

    $_[1] -= $delta_seconds;
    $_[0] = $new_day;

    # fine adjust - up to 1 day
    my $day_length = DateTimeX::Lite::LeapSecond::day_length( $new_day );
    if ( $_[1] >= $day_length )
    {
        $_[1] -= $day_length;
        $_[0]++;
    }
    elsif ( $_[1] < 0 )
    {
        $day_length = DateTimeX::Lite::LeapSecond::day_length( $new_day - 1 );
        $_[1] += $day_length;
        $_[0]--;
    }
}


sub seconds_as_components
{
    my $secs = shift;
    my $utc_secs = shift;
    my $modifier = shift || 0;

    use integer;

    $secs -= $modifier;

    my $hour = $secs / 3600;
    $secs -= $hour * 3600;

    my $minute = $secs / 60;

    my $second = $secs - ( $minute * 60 );

    if ( $utc_secs && $utc_secs >= 86400 )
    {
        # there is no such thing as +3 or more leap seconds!
        die "Invalid UTC RD seconds value: $utc_secs"
            if $utc_secs > 86401;

        $second += $utc_secs - 86400 + 60;

        $minute  = 59;

        $hour--;
        $hour = 23 if $hour < 0;
    }

    return ( $hour, $minute, $second );
}

sub offset_as_seconds {
    my $offset = shift;

    return undef unless defined $offset;

    return 0 if $offset eq '0';

    my ( $sign, $hours, $minutes, $seconds );
    if ( $offset =~ /^([\+\-])?(\d\d?):(\d\d)(?::(\d\d))?$/ )
    {
        ( $sign, $hours, $minutes, $seconds ) = ( $1, $2, $3, $4 );
    }
    elsif ( $offset =~ /^([\+\-])?(\d\d)(\d\d)(\d\d)?$/ )
    {
        ( $sign, $hours, $minutes, $seconds ) = ( $1, $2, $3, $4 );
    }
    else
    {
        return undef;
    }

    $sign = '+' unless defined $sign;
    return undef unless $hours >= 0 && $hours <= 99;
    return undef unless $minutes >= 0 && $minutes <= 59;
    return undef unless ! defined( $seconds ) || ( $seconds >= 0 && $seconds <= 59 );

    my $total =  $hours * 3600 + $minutes * 60;
    $total += $seconds if $seconds;
    $total *= -1 if $sign eq '-';

    return $total;
}

sub offset_as_string {
    my $offset = shift;

    return undef unless defined $offset;
    return undef unless $offset >= -359999 && $offset <= 359999;

    my $sign = $offset < 0 ? '-' : '+';

    $offset = abs($offset);

    my $hours = int( $offset / 3600 );
    $offset %= 3600;
    my $mins = int( $offset / 60 );
    $offset %= 60;
    my $secs = int( $offset );

    return ( $secs ?
             sprintf( '%s%02d%02d%02d', $sign, $hours, $mins, $secs ) :
             sprintf( '%s%02d%02d', $sign, $hours, $mins )
           );
}
 
1;
