# DESCRIPTION

A [Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays) family member from the Netherlands

# SYNOPSIS

    use Date::Holidays::NL;

    if (my $thing = is_holiday(2020, 5, 5, lang => 'en')) {
        print "It is $thing!", $/; # prints 'It is Liberation day!'
    }

# METHODS

This module implements the `is_holiday`, `is_holiday_dt` and `holiday`
functions from [Date::Holidays::Abstract](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AAbstract).

All methods accept additional parameters. The most important is a flag called
`gov`, when supplied you will get days that the government considers special
in regards to service terms. It essentially says that if a company or
government needs to contact you before or on that day it can be expedited to
the following work day. See the [relevant
law](https://wetten.overheid.nl/BWBR0002448/2010-10-10) for more information.

## is\_holiday(yyyy, mm, dd, %additional)

    is_holiday(
        '2022', '05', '05',
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to nl/nld, alternatively en/eng can be used.
    );

## is\_holiday\_dt(dt, %additional)

    is_holiday_dt(
        DateTime->new(
            year      => 2022,
            month     => 5,
            day       => 5,
            time_zone => 'Europe/Amsterdam',
        ),
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to nl/nld, alternatively en/eng can be used.
    );

## holidays(yyyy, gov => 1)

    holidays('2022', gov  => 1);

Similar API to the other functions, returns an hashref for the year.

# SEE ALSO

- https://wetten.overheid.nl/BWBR0002448/2010-10-10
