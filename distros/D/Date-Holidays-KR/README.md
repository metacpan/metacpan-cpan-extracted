# NAME

Date::Holidays::KR - Determine Korean public holidays

# SYNOPSIS

    use Date::Holidays::KR;
    use DateTime;

    my $dt = DateTime->now( time_zone => 'local' );
    if (my $holiday_name = is_holiday($dt->year, $dt->month, $dt->day)) {
        print "오늘은 $holiday_name 입니다";
    }

# DESCRIPTION

Date::Holidays::KR determines public holidays for Korean. 

# FUNCTION

- is\_holiday

    takes year, month, date as parameters, and returns the name of the holiday
    if it's a holiday, or undef otherwise.

- holidays

    takes a year, and returns a hashref of all the holidays for the year

# CAVEATS

- Currently supported data range is from solar 1391-02-05 ( lunisolar 1391-01-01 ) to 2050-12-31 ( lunisolar 2050-11-18 )

# AUTHOR

Jeen Lee &lt;aiatejin {at} gmail.com>, Keedi Kim < keedi.kim {at} gmail.com>

# SEE ALSO

[Date::Korean](https://metacpan.org/pod/Date::Korean), [Date::Holidays::CN](https://metacpan.org/pod/Date::Holidays::CN)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
