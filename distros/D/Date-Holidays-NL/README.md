# DESCRIPTION

A [Date::Holidays](https://metacpan.org/pod/Date%3A%3AHolidays) family member from the Netherlands

# SYNOPSIS

    use Date::Holidays::NL;

    if (is_holiday(2020, 5, 5)) {
        print "It is Liberation day!", $/;
    }

# METHODS

This module implements the `is_holiday` and `holiday` functions from
[Date::Holidays::Abstract](https://metacpan.org/pod/Date%3A%3AHolidays%3A%3AAbstract).
