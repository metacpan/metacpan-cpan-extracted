# DESCRIPTION

A [Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays) family member from Bonaire

# SYNOPSIS

    use Date::Holidays::BQ;

    if (my $thing = is_holiday(2020, 4, 30, lang => 'en')) {
        print "It is $thing!", $/; # prints 'It is Bonaire Flag day!'
    }

# METHODS

This module implements the `is_holiday` and `holiday` functions from
[Date::Holidays::Abstract](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AAbstract).

## is\_holiday(yyyy, mm, dd, %additional)

    is_holiday(
        '2020', '4', '30',
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to pap, alternatively nl/nld or en/eng can be used.
    );

## is\_holiday\_dt(dt, %additional)

    is_holiday_dt(
        DateTime->new(
            year      => 2020,
            month     => 4,
            day       => 30,
            time_zone => 'America/Curacao',
        ),
        gov  => 1,      # Important for government institutions
        lang => 'en'    # defaults to pap, alternatively nl/nld or en/eng can be used.
    );

## holidays(yyyy, gov => 1)

    holidays('2022', gov  => 1);

Similar API to the other functions, returns an hashref for the year.

# UTF-8

Be aware that we return UTF-8 when Papiamento is chosen. So make sure you set
your enconding to UTF-8, otherwise you may see weird things.

# SEE ALSO

- https://wetten.overheid.nl/BWBR0002448/2010-10-10
