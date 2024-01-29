# NAME

Date::Holidays::NYSE - Date::Holidays Adapter for New York Stock Exchange (NYSE) holidays

# SYNOPSIS

    use Date::Holidays::NYSE qw{is_holiday};
    my $holiday_name = is_holiday($year, $month, $day);

# DESCRIPTION

Date::Holidays Adapter for New York Stock Exchange (NYSE) holidays

Per https://www.nyse.com/markets/hours-calendars these are the NYSE holidays.

    New Years Day (not observed on 12/31)
    Martin Luther King, Jr. Day
    Washington's Birthday
    Good Friday (falls between March 20 and April 23)
    Memorial Day
    Juneteenth National Independence Day (first observed in 2022)
    Independence Day
    Labor Day
    Thanksgiving Day
    Christmas Day

It is unclear if Juneteenth were to fall on a weekend that it would be observed. Juneteenth was not observed on Friday June 18th, 2021 but the Law was enacted on June 17th, 2021.

# METHODS

## is\_holiday

Returns a holiday name or undef given three arguments (year, month, day).

    my ($year, $month, $day) = (2023, 4, 7);
    use Date::Holidays::NYSE qw{is_holiday};
    my $holiday_name = is_holiday($year, $month, $day);
    if (defined $holiday_name) {
      print "Holiday: $holiday_name\n"; #Good Friday
    } else {
      print "Not a NYSE Holiday\n";
    }

## is\_nyse\_holiday

Wrapper around is\_holiday function per the API specification. See ["is\_holiday1" in Date::Holidays](https://metacpan.org/pod/Date::Holidays#is_holiday1)

## holidays

Returns a hash reference containing all of the holidays in the specified year. The keys for the returned hash reference are the dates where 2-digit month and 2-digit day are concatenated.

    use Date::Holidays::US qw{holidays};
    my $year          = 2023;
    my $holidays_href = holidays($year);
    foreach my $key (sort keys %$holidays_href) { #e.g. "0101", "0619","0704"
      my ($month, $day) = $key =~ m/\A([0-9]{2})([0-9]{2})\Z/;
      my $name          = $holidays_href->{$key};
      print "Year: $year, Month: $month, Day: $day, Name: $name\n";
    }

## nyse\_holidays

Wrapper around holidays function per the API specification. See ["holidays1" in Date::Holidays](https://metacpan.org/pod/Date::Holidays#holidays1)

# TODO

This package assumes that Juneteenth will be observed when it falls on a weekend. However, in 2021 Juneteenth was not observed on Friday June 18th, 2021. The next weekend Juneteenth will be in June 2027.

# SEE ALSO

[Date::Holidays](https://metacpan.org/pod/Date::Holidays), [Date::Holidays::US](https://metacpan.org/pod/Date::Holidays::US)

# AUTHOR

Michael R. Davis, MRDVT

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Michael R. Davis

MIT License
