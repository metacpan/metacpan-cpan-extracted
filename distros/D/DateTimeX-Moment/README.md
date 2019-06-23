[![Build Status](https://travis-ci.org/karupanerura/DateTimeX-Moment.svg?branch=master)](https://travis-ci.org/karupanerura/DateTimeX-Moment)
# NAME

DateTimeX::Moment - EXPERIMENTAL DateTime like interface for Time::Moment

# SYNOPSIS

    use DateTimeX::Moment;

    $dt = DateTimeX::Moment->new(
        year       => 1964,
        month      => 10,
        day        => 16,
        hour       => 16,
        minute     => 12,
        second     => 47,
        nanosecond => 500000000,
        time_zone  => 'Asia/Taipei',
    );

    $dt = DateTimeX::Moment->from_epoch( epoch => $epoch );
    $dt = DateTimeX::Moment->now; # same as ( epoch => time() )

    $year   = $dt->year;
    $month  = $dt->month;          # 1-12

    $day    = $dt->day;            # 1-31

    $dow    = $dt->day_of_week;    # 1-7 (Monday is 1)

    $hour   = $dt->hour;           # 0-23
    $minute = $dt->minute;         # 0-59

    $second = $dt->second;         # 0-61 (leap seconds!)

    $doy    = $dt->day_of_year;    # 1-366 (leap years)

    $doq    = $dt->day_of_quarter; # 1..

    $qtr    = $dt->quarter;        # 1-4

    # all of the start-at-1 methods above have corresponding start-at-0
    # methods, such as $dt->day_of_month_0, $dt->month_0 and so on

    $ymd    = $dt->ymd;           # 2002-12-06
    $ymd    = $dt->ymd('/');      # 2002/12/06

    $mdy    = $dt->mdy;           # 12-06-2002
    $mdy    = $dt->mdy('/');      # 12/06/2002

    $dmy    = $dt->dmy;           # 06-12-2002
    $dmy    = $dt->dmy('/');      # 06/12/2002

    $hms    = $dt->hms;           # 14:02:29
    $hms    = $dt->hms('!');      # 14!02!29

    $is_leap  = $dt->is_leap_year;

    # these are localizable, see Locales section
    $month_name  = $dt->month_name; # January, February, ...
    $month_abbr  = $dt->month_abbr; # Jan, Feb, ...
    $day_name    = $dt->day_name;   # Monday, Tuesday, ...
    $day_abbr    = $dt->day_abbr;   # Mon, Tue, ...

    # May not work for all possible datetime, see the docs on this
    # method for more details.
    $epoch_time  = $dt->epoch;

    $rhs = $dt + $duration_object;

    $dt3 = $dt - $duration_object;

    $duration_object = $dt - $rhs;

    $dt->set( year => 1882 );

    $dt->set_time_zone( 'America/Chicago' );

    $dt->set_formatter( $formatter );

# BENCHMARK

`author/benchmark.pl`:

    new()
    Benchmark: timing 100000 iterations of datetime, moment...
      datetime:  4 wallclock secs ( 4.06 usr +  0.01 sys =  4.07 CPU) @ 24570.02/s (n=100000)
        moment:  1 wallclock secs ( 0.62 usr +  0.01 sys =  0.63 CPU) @ 158730.16/s (n=100000)
                 Rate datetime   moment
    datetime  24570/s       --     -85%
    moment   158730/s     546%       --
    ----------------------------------------
    now()
    Benchmark: timing 100000 iterations of datetime, moment...
      datetime:  4 wallclock secs ( 4.38 usr +  0.01 sys =  4.39 CPU) @ 22779.04/s (n=100000)
        moment:  1 wallclock secs ( 0.59 usr +  0.00 sys =  0.59 CPU) @ 169491.53/s (n=100000)
                 Rate datetime   moment
    datetime  22779/s       --     -87%
    moment   169492/s     644%       --
    ----------------------------------------
    from_epoch()
    Benchmark: timing 100000 iterations of datetime, moment...
      datetime:  4 wallclock secs ( 4.27 usr +  0.01 sys =  4.28 CPU) @ 23364.49/s (n=100000)
        moment:  1 wallclock secs ( 0.63 usr +  0.00 sys =  0.63 CPU) @ 158730.16/s (n=100000)
                 Rate datetime   moment
    datetime  23364/s       --     -85%
    moment   158730/s     579%       --
    ----------------------------------------
    calculate()
    Benchmark: timing 100000 iterations of datetime, moment...
      datetime: 20 wallclock secs (20.30 usr +  0.04 sys = 20.34 CPU) @ 4916.42/s (n=100000)
        moment:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 93457.94/s (n=100000)
                Rate datetime   moment
    datetime  4916/s       --     -95%
    moment   93458/s    1801%       --
    ----------------------------------------

# DESCRIPTION

TODO: write it

# METHODS

TODO: write it

# LICENSE

Copyright (C) karupanerura.

This is free software, licensed under:
  The Artistic License 2.0 (GPL Compatible)

# AUTHOR

karupanerura <karupa@cpan.org>
