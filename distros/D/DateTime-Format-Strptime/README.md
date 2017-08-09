# NAME

DateTime::Format::Strptime - Parse and format strp and strf time patterns

# VERSION

version 1.74

# SYNOPSIS

    use DateTime::Format::Strptime;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
    );

    my $dt = $strp->parse_datetime('23:16:42');

    $strp->format_datetime($dt);

    # 23:16:42

    # Croak when things go wrong:
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
        on_error  => 'croak',
    );

    # Do something else when things go wrong:
    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%T',
        locale    => 'en_AU',
        time_zone => 'Australia/Melbourne',
        on_error  => \&phone_police,
    );

# DESCRIPTION

This module implements most of `strptime(3)`, the POSIX function that is the
reverse of `strftime(3)`, for `DateTime`. While `strftime` takes a
`DateTime` and a pattern and returns a string, `strptime` takes a string and
a pattern and returns the `DateTime` object associated.

# METHODS

This class offers the following methods.

## DateTime::Format::Strptime->new(%args)

This methods creates a new object. It accepts the following arguments:

- pattern

    This is the pattern to use for parsing. This is required.

- strict

    This is a boolean which disables or enables strict matching mode.

    By default, this module turns your pattern into a regex that will match
    anywhere in a string. So given the pattern `%Y%m%d%H%M%S` it will match a
    string like `20161214233712Z`. However, this also means that a this pattern
    will match **any** string that contains 14 or more numbers! This behavior can
    be very surprising.

    If you enable strict mode, then the generated regex is wrapped in boundary
    checks of the form `/(?:\A|\b)...(?:\b|\z_/)`. These checks ensure that the
    pattern will only match when at the beginning or end of a string, or when it
    is separated by other text with a word boundary (`\w` versus `\W`).

    By default, strict mode is off. This is done for backwards
    compatibility. Future releases may turn it on by default, as it produces less
    surprising behavior in many cases.

    Because the default may change in the future, **you are strongly encouraged
    to explicitly set this when constructing all `DateTime::Format::Strptime`
    objects**.

- time\_zone

    The default time zone to use for objects returned from parsing.

- zone\_map

    Some time zone abbreviations are ambiguous (e.g. PST, EST, EDT). By default,
    the parser will die when it parses an ambiguous abbreviation. You may specify
    a `zone_map` parameter as a hashref to map zone abbreviations however you like:

        zone_map => { PST => '-0800', EST => '-0600' }

    Note that you can also override non-ambiguous mappings if you want to as well.

- locale

    The locale to use for objects returned from parsing.

- on\_error

    This can be one of `'undef'` (the string, not an `undef`), 'croak', or a
    subroutine reference.

    - 'undef'

        This is the default behavior. The module will return `undef` on errors. The
        error can be accessed using the `$object->errmsg` method. This is the
        ideal behaviour for interactive use where a user might provide an illegal
        pattern or a date that doesn't match the pattern.

    - 'croak'

        The module will croak with an error message on errors.

    - sub{...} or \\&subname

        When given a code ref, the module will call that sub on errors. The sub
        receives two parameters: the object and the error message.

        If your sub does not die, then the formatter will continue on as if
        `on_error` was `'undef'`.

## $strptime->parse\_datetime($string)

Given a string in the pattern specified in the constructor, this method
will return a new `DateTime` object.

If given a string that doesn't match the pattern, the formatter will croak or
return undef, depending on the setting of `on_error` in the constructor.

## $strptime->format\_datetime($datetime)

Given a `DateTime` object, this methods returns a string formatted in the
object's format. This method is synonymous with `DateTime`'s strftime method.

## $strptime->locale

This method returns the locale passed to the object's constructor.

## $strptime->pattern

This method returns the pattern passed to the object's constructor.

## $strptime->time\_zone

This method returns the time zone passed to the object's constructor.

## $strptime->errmsg

If the on\_error behavior of the object is 'undef', you can retrieve error
messages with this method so you can work out why things went wrong.

# EXPORTS

These subs are available as optional exports.

## strptime( $strptime\_pattern, $string )

Given a pattern and a string this function will return a new `DateTime`
object.

## strftime( $strftime\_pattern, $datetime )

Given a pattern and a `DateTime` object this function will return a
formatted string.

# STRPTIME PATTERN TOKENS

The following tokens are allowed in the pattern string for strptime
(parse\_datetime):

- %%

    The % character.

- %a or %A

    The weekday name according to the given locale, in abbreviated form or
    the full name.

- %b or %B or %h

    The month name according to the given locale, in abbreviated form or
    the full name.

- %c

    The datetime format according to the given locale.

- %C

    The century number (0-99).

- %d or %e

    The day of month (01-31). This will parse single digit numbers as well.

- %D

    Equivalent to %m/%d/%y. (This is the American style date, very confusing
    to non-Americans, especially since %d/%m/%y is widely used in Europe.
    The ISO 8601 standard pattern is %F.)

- %F

    Equivalent to %Y-%m-%d. (This is the ISO style date)

- %g

    The year corresponding to the ISO week number, but without the century
    (0-99).

- %G

    The 4-digit year corresponding to the ISO week number.

- %H

    The hour (00-23). This will parse single digit numbers as well.

- %I

    The hour on a 12-hour clock (1-12).

- %j

    The day number in the year (1-366).

- %m

    The month number (01-12). This will parse single digit numbers as well.

- %M

    The minute (00-59). This will parse single digit numbers as well.

- %n

    Arbitrary whitespace.

- %N

    Nanoseconds. For other sub-second values use `%[number]N`.

- %p or %P

    The equivalent of AM or PM according to the locale in use. See
    [DateTime::Locale](https://metacpan.org/pod/DateTime::Locale).

- %r

    Equivalent to %I:%M:%S %p.

- %R

    Equivalent to %H:%M.

- %s

    Number of seconds since the Epoch.

- %S

    The second (0-60; 60 may occur for leap seconds. See
    [DateTime::LeapSecond](https://metacpan.org/pod/DateTime::LeapSecond)).

- %t

    Arbitrary whitespace.

- %T

    Equivalent to %H:%M:%S.

- %U

    The week number with Sunday the first day of the week (0-53). The first
    Sunday of January is the first day of week 1.

- %u

    The weekday number (1-7) with Monday = 1. This is the `DateTime` standard.

- %w

    The weekday number (0-6) with Sunday = 0.

- %W

    The week number with Monday the first day of the week (0-53). The first
    Monday of January is the first day of week 1.

- %x

    The date format according to the given locale.

- %X

    The time format according to the given locale.

- %y

    The year within century (0-99). When a century is not otherwise specified
    (with a value for %C), values in the range 69-99 refer to years in the
    twentieth century (1969-1999); values in the range 00-68 refer to years in the
    twenty-first century (2000-2068).

- %Y

    A 4-digit year, including century (for example, 1991).

- %z

    An RFC-822/ISO 8601 standard time zone specification. (For example
    \+1100) \[See note below\]

- %Z

    The timezone name. (For example EST -- which is ambiguous) \[See note
    below\]

- %O

    This extended token allows the use of Olson Time Zone names to appear
    in parsed strings. **NOTE**: This pattern cannot be passed to `DateTime`'s
    `strftime()` method, but can be passed to `format_datetime()`.

# AUTHOR EMERITUS

This module was created by Rick Measham.

# SEE ALSO

`datetime@perl.org` mailing list.

http://datetime.perl.org/

[perl](https://metacpan.org/pod/perl), [DateTime](https://metacpan.org/pod/DateTime), [DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone), [DateTime::Locale](https://metacpan.org/pod/DateTime::Locale)

# BUGS

Please report any bugs or feature requests to
`bug-datetime-format-strptime@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org](http://rt.cpan.org). I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

Bugs may be submitted at [https://github.com/houseabsolute/DateTime-Format-Strptime/issues](https://github.com/houseabsolute/DateTime-Format-Strptime/issues).

There is a mailing list available for users of this distribution,
[mailto:datetime@perl.org](mailto:datetime@perl.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for DateTime-Format-Strptime can be found at [https://github.com/houseabsolute/DateTime-Format-Strptime](https://github.com/houseabsolute/DateTime-Format-Strptime).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHORS

- Dave Rolsky <autarch@urth.org>
- Rick Measham <rickm@cpan.org>

# CONTRIBUTORS

- Christian Hansen <chansen@cpan.org>
- D. Ilmari Mannsåker <ilmari.mannsaker@net-a-porter.com>
- key-amb <yasutake.kiyoshi@gmail.com>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 - 2017 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
