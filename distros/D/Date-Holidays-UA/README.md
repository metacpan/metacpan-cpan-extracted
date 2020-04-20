## Name

Date::Holidays::UA - Holidays module for Ukraine

## Version

Version 0.01

## Synopsis

```perl
# procedural approach

use Date::Holidays::UA qw(:all);

my ($year, $month, $day) = (localtime)[5, 4, 3];
$year  += 1900;
$month += 1;

print 'Holiday!' if is_holiday($year, $month, $day);

my $calendar = holidays($year, {language => 'en'});
print $calendar->{'0824'};


# object-oriented approach

use DateTime;
use Date::Holidays::UA;

my $ua = Date::Holidays::UA->new({ language => 'en' });
print 'Holiday!' if $ua->is_holiday_dt(DateTime->today);

my $calendar = $ua->holidays(DateTime->today->year);
print join("\n", value(%$calendar)); # list of holiday names for Ukraine
```

## Subroutines/Methods

### new()

Create a new Date::Holidays::UA object. Parameters should be given as
a hashref of key-value pairs.

```perl
my $ua = Date::Holidays::UA->new();

my $ua = Date::Holidays::UA->new({
    language => 'en'
});
```

One parameters can be specified: **language**.

### is\_holiday()

For a given year, month (1-12) and day (1-31), return 1 if the given
day is a holiday; 0 if not.  When using procedural calling style, an
additional hashref of options can be specified.

```perl
$holiday_p = is_holiday($year, $month, $day);

$holiday_p = is_holiday($year, $month, $day, {
    language => 'en'
});

$holiday_p = $ua->is_holiday($year, $month, $day);
```

### is\_holiday\_dt()

As is\_holiday, but accepts a DateTime object in place of a numeric year,
month, and day.

```perl
$holiday_p = is_holiday_dt($dt, {language => 'en'});

$holiday_p = $ua->is_holiday_dt($dt);
```

### is\_ua\_holiday()

Similar to `is_holiday`. Return the name of the holiday occurring on
the specified date if there is one; `undef` if there isn't.

```
print $ua->is_ua_holiday(2020, 1, 1); # "New Year"
```

### holidays()

For the given year, return a hashref containing all the holidays for
that year.  The keys are the date of the holiday in `mmdd` format
(eg '1225' for December 25); the values are the holiday names.

```perl
my $calendar = holidays($year, {language => 'en'});
print $calendar->{'0824'}; # "Independence Day"

my $calendar = $ua->holidays($year);
print $calendar->{'0628'}; # "Constitution Day"
```

### ua\_holidays()

Same as `holidays()`.

### holidays\_dt()

Similar to `holidays()`, The keys are the date of the holiday in `mmdd` format
(eg '1225' for December 25); and DateTime objects as the values.

```perl
my $calendar = $ua->holidays_dt($year);
```

## Author

Denis Boyun, `<denisboyun at gmail.com>`

## Bugs

Please report any bugs or feature requests to `bug-date-holidays-ua at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Holidays-UA](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Holidays-UA).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## Support

You can find documentation for this module with the perldoc command.

```
perldoc Date::Holidays::UA
```

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-UA](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-UA)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Date-Holidays-UA](http://annocpan.org/dist/Date-Holidays-UA)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Date-Holidays-UA](https://cpanratings.perl.org/d/Date-Holidays-UA)

- Search CPAN

    [https://metacpan.org/release/Date-Holidays-UA](https://metacpan.org/release/Date-Holidays-UA)

## Acknowledgements

## License and Copyright

This software is copyright (c) 2020 by Denis Boyun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

