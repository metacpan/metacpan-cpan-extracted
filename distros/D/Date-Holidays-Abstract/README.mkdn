[![CPAN version](https://badge.fury.io/pl/Date-Holidays-Abstract.svg)](http://badge.fury.io/pl/Date-Holidays-Abstract)
[![Build Status](https://travis-ci.org/jonasbn/Date-Holidays-Abstract.svg?branch=master)](https://travis-ci.org/jonasbn/Date-Holidays-Abstract)
[![Coverage Status](https://coveralls.io/repos/jonasbn/Date-Holidays-Abstract/badge.png?branch=master)](https://coveralls.io/r/jonasbn/Date-Holidays-Abstract?branch=master)

# NAME

Date::Holidays::Abstract - abstract class for Date::Holidays::\* packages

# SYNOPSIS

    package Date::Holidays::NN;
    use base qw(Date::Holidays::Abstract);

    sub holidays {
    ...
    }

    sub is_holiday {
    ...
    }

# VERSION

This POD describes version 0.07 of Date::Holidays::Abstract

# DESCRIPTION

This module is an abstract class intended for Date::Holidays::\*

The goal is to have all the existing and future modules implement the
same methods, so they will have a uniform usage and can be used in
polymorphic context or can be easily adapted into the Date::Holidays
class.

If you want to use Date::Holidays::Abstract and want to comply with my
suggestions to the methods that ought to be implemented, you should
implement:

- __is\_holiday__
- __holidays__

## is\_holiday

Should at least take 3 arguments:

- year, four digits
- month, between 1-12
- day, between 1-31

The return value from is holiday is either a 1 or 0 indicating true of
false, indicating whether the specified date is a holiday in the given
country's national calendar.

Additional arguments are at the courtesy of the author of the using
module/class.

## holidays

Should at least take one argument:

- year, four digits

Returns a reference to a hash, where the keys are date represented as
four digits. The two first representing month (01-12) and the last two
representing day (01-31).

The value for the key in question is the local name for the holiday
indicated by the day. The resultset will of course vary depending on
the given country's national holiday.

Additional arguments are at the courtesy of the author of the using
module/class.

\--

[Date::Holidays](https://metacpan.org/pod/Date::Holidays) uses the requirements defined by this module and this
module can therefor be used with success in conjunction with this.

This is an alternative to a SUPER class. I have given a lot of thought to
programming a SUPER class, but since creating a super class for a bunch
of modules implementing handling of national holidays, an abstract
class seemed a better choice.

A proposed SUPER class for Date::Holidays::\* is however implemented see:
[Date::Holidays::Super](https://metacpan.org/pod/Date::Holidays::Super) implement __is\_holiday__ and __holidays__ and expect
these to be overloaded.

Overloading would be necessary since nothing intelligent can be said
about holidays without specifying a nationality (a part from holidays
being nice but too few), and the implemented methods would be empty
bodies returning empty result sets.

So I am more for an abstract class and as stated I consider this class
an experiment and I have implemented [Date::Holidays::Super](https://metacpan.org/pod/Date::Holidays::Super) as an
alternative.

Suggestions for changes and extensions are more than welcome.

# SUBROUTINES/METHODS

This class does not implement any methods, it is a abstract class.

# DIAGNOSTICS

This class does not implement any exceptions or error, it is a abstract class.

# CONFIGURATION AND ENVIRONMENT

This class does not implement or require any special environment or
configuration apart from what is mentioned in DEPENDENCIES

# DEPENDENCIES

This class is subclassed from [Class::Virtually::Abstract](https://metacpan.org/pod/Class::Virtually::Abstract), but holds
no direct dependencies apart from that class/module.

# INCOMPATIBILITIES

None known to the author

# BUGS AND LIMITATIONS

None known to the author

# SEE ALSO

- [Date::Holidays](https://metacpan.org/pod/Date::Holidays)
- [Date::Holidays::Super](https://metacpan.org/pod/Date::Holidays::Super)
- [Date::Holidays::DE](https://metacpan.org/pod/Date::Holidays::DE)
- [Date::Holidays::DK](https://metacpan.org/pod/Date::Holidays::DK)
- [Date::Holidays::FR](https://metacpan.org/pod/Date::Holidays::FR)
- [Date::Holidays::UK](https://metacpan.org/pod/Date::Holidays::UK)
- [Date::Holiday::PT](https://metacpan.org/pod/Date::Holiday::PT)
- [Date::Japanese::Holiday](https://metacpan.org/pod/Date::Japanese::Holiday)
- [Class::Virtual](https://metacpan.org/pod/Class::Virtual)
- [Class::Virtually::Abstract](https://metacpan.org/pod/Class::Virtually::Abstract)

# BUGS

Please report issues via CPAN RT:

    L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-Abstract>

or by sending mail to

    L<bug-Date-Holidays-Abstract@rt.cpan.org>

# TEST/COVERAGE

This module is currently at 100% test coverage

# AUTHOR

Jonas B. Nielsen, (jonasbn) - `<jonasbn@cpan.org>`

# LICENSE AND COPYRIGHT

Date-Holidays-Abstract is (C) by Jonas B. Nielsen, (jonasbn) 2004-2014

Date-Holidays-Abstract is released under the Artistic License 2.0
