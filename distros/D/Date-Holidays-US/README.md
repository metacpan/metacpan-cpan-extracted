# NAME

Date::Holidays::US - Date::Holidays Adapter for US Federal holidays

# SYNOPSIS

    use Date::Holidays::US qw{is_holiday};
    my $holiday_name = is_holiday($year, $month, $day);

# DESCRIPTION

Date::Holidays Adapter for US Federal holidays back to 1880 with updates up to 2025.

# METHODS

## is\_holiday

Returns a holiday name or undef given three arguments (year, month, day).

    my ($year, $month, $day) = (2022, 6, 19);
    use Date::Holidays::US qw{is_holiday};
    my $holiday_name = is_holiday($year, $month, $day);
    if (defined $holiday_name) {
      print "Holiday: $holiday_name\n";
    } else {
      print "Not a US Holiday\n";
    }

## is\_us\_holiday

Wrapper around is\_holiday function per the API specification. See ["is\_holiday1" in Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays#is_holiday1)

## holidays

Returns a hash reference containing all of the holidays in the specified year.  The keys for the returned hash reference are the dates where 2-digit month and 2-digit day are concatenated.

    use Date::Holidays::US qw{holidays};
    my $year          = 2022;
    my $holidays_href = holidays($year);
    foreach my $key (sort keys %$holidays_href) { #e.g. "0101", "0619","0704"
      my ($month, $day) = $key =~ m/\A([0-9]{2})([0-9]{2})\Z/;
      my $name          = $holidays_href->{$key};
      print "Year: $year, Month: $month, Day: $day, Name: $name\n";
    }

## us\_holidays

Wrapper around holidays function per the API specification. See ["holidays1" in Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays#holidays1)

# TODO

# SEE ALSO

[Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays) (wrapper), [Date::Holidays::USFederal](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AUSFederal) (defunct), [Date::Holidays::USExtended](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AUSExtended) (e.g., Valentine's Day, Mother's Day, etc.)

# AUTHOR

Michael R. Davis, MRDVT

# COPYRIGHT AND LICENSE

Copyright (C) 2025 by Michael R. Davis

MIT License
