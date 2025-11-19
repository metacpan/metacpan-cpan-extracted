[![CPAN version](https://badge.fury.io/pl/Date-Age.svg)](https://metacpan.org/pod/Date::Age)

# NAME

Date::Age - Return an age or age range from date(s)

# VERSION

Version 0.04

# SYNOPSIS

    use Date::Age qw(describe details);

    say describe('1943', '2016-01-01');    # '72-73'

    my $data = details('1943-05-01', '2016-01-01');
    # { min_age => 72, max_age => 72, range => '72', precise => 72 }

# DESCRIPTION

This module calculates the age or possible age range between a date of birth
and another date (typically now or a death date).
It works even with partial dates.

# REPOSITORY

[https://github.com/nigelhorne/Date-Age](https://github.com/nigelhorne/Date-Age)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-date-age at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Age](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Age).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Date::Age

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Date-Age](https://metacpan.org/dist/Date-Age)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Age](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Age)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Date-Age](http://matrix.cpantesters.org/?dist=Date-Age)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Date::Age](http://deps.cpantesters.org/?module=Date::Age)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
