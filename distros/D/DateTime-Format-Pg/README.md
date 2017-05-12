# NAME

DateTime::Format::Pg - Parse and format PostgreSQL dates and times

# SYNOPSIS

    use DateTime::Format::Pg;

    my $dt = DateTime::Format::Pg->parse_datetime( '2003-01-16 23:12:01' );

    # 2003-01-16 23:12:01
    DateTime::Format::Pg->format_datetime($dt);

# DESCRIPTION

This module understands the formats used by PostgreSQL for its DATE, TIME,
TIMESTAMP, and INTERVAL data types.  It can be used to parse these formats in
order to create `DateTime` or `DateTime::Duration` objects, and it can take a
`DateTime` or `DateTime::Duration` object and produce a string representing
it in a format accepted by PostgreSQL.

# CONSTRUCTORS

The following methods can be used to create `DateTime::Format::Pg` objects.

- new( name => value, ... )

    Creates a new `DateTime::Format::Pg` instance. This is generally not
    required for simple operations. If you wish to use a different parsing
    style from the default then it is more comfortable to create an object.

        my $parser = DateTime::Format::Pg->new()
        my $copy = $parser->new( 'european' => 1 );

    This method accepts the following options:

    - european

        If european is set to non-zero, dates are assumed to be in european
        dd/mm/yyyy format. The default is to assume US mm/dd/yyyy format
        (because this is the default for PostgreSQL).

        This option only has an effect if PostgreSQL is set to output dates in
        the 'PostgreSQL' (DATE only) and 'SQL' (DATE and TIMESTAMP) styles.

        Note that you don't have to set this option if the PostgreSQL server has
        been set to use the 'ISO' format, which is the default.

    - server\_tz

        This option can be set to a `DateTime::TimeZone` object or a string
        that contains a time zone name.

        This value must be set to the same value as the PostgreSQL server's time
        zone in order to parse TIMESTAMP WITH TIMEZONE values in the
        'PostgreSQL', 'SQL', and 'German' formats correctly.

        Note that you don't have to set this option if the PostgreSQL server has
        been set to use the 'ISO' format, which is the default.

- clone()

    This method is provided for those who prefer to explicitly clone via a
    method called `clone()`.

        my $clone = $original->clone();

    If called as a class method it will die.

# METHODS

This class provides the following methods. The parse\_datetime, parse\_duration,
format\_datetime, and format\_duration methods are general-purpose methods
provided for compatibility with other `DateTime::Format` modules.

The other methods are specific to the corresponding PostgreSQL date/time data
types. The names of these methods are derived from the name of the PostgreSQL
data type.  (Note: Prior to PostgreSQL 7.3, the TIMESTAMP type was equivalent
to the TIMESTAMP WITH TIME ZONE type. This data type corresponds to the
format/parse\_timestamp\_with\_time\_zone method but not to the
format/parse\_timestamp method.)

## PARSING METHODS

This class provides the following parsing methods.

As a general rule, the parsing methods accept input in any format that the
PostgreSQL server can produce. However, if PostgreSQL's DateStyle is set to
'SQL' or 'PostgreSQL', dates can only be parsed correctly if the 'european'
option is set correctly (i.e. same as the PostgreSQL server).  The same is true
for time zones and the 'australian\_timezones' option in all modes but 'ISO'.

The default DateStyle, 'ISO', will always produce unambiguous results
and is also parsed most efficiently by this parser class. I strongly
recommend using this setting unless you have a good reason not to.

- parse\_datetime($string,...)

    Given a string containing a date and/or time representation, this method
    will return a new `DateTime` object.

    If the input string does not contain a date, it is set to 1970-01-01.
    If the input string does not contain a time, it is set to 00:00:00. 
    If the input string does not contain a time zone, it is set to the
    floating time zone.

    If given an improperly formatted string, this method may die.

- parse\_timestamptz($string,...)
- parse\_timestamp\_with\_time\_zone($string,...)

    Given a string containing a timestamp (date and time) representation,
    this method will return a new `DateTime` object. This method is
    suitable for the TIMESTAMPTZ (or TIMESTAMP WITH TIME ZONE) type.

    If the input string does not contain a time zone, it is set to the
    floating time zone.

    Please note that PostgreSQL does not actually store a time zone along
    with the TIMESTAMP WITH TIME ZONE (or TIMESTAMPTZ) type but will just
    return a time stamp converted for the server's local time zone.

    If given an improperly formatted string, this method may die.

- parse\_timestamp($string,...)
- parse\_timestamp\_without\_time\_zone($string,...)

    Similar to the functions above, but always returns a `DateTime` object
    with a floating time zone. This method is suitable for the TIMESTAMP (or
    TIMESTAMP WITHOUT TIME ZONE) type.

    If the server does return a time zone, it is ignored.

    If given an improperly formatted string, this method may die.

- parse\_timetz($string,...)
- parse\_time\_with\_time\_zone($string,...)

    Given a string containing a time representation, this method will return
    a new `DateTime` object. The date is set to 1970-01-01. This method is
    suitable for the TIMETZ (or TIME WITH TIME ZONE) type.

    If the input string does not contain a time zone, it is set to the
    floating time zone.

    Please note that PostgreSQL stores a numerical offset with its TIME WITH
    TIME ZONE (or TIMETZ) type. It does not store a time zone name (such as
    'Europe/Rome').

    If given an improperly formatted string, this method may die.

- parse\_time($string,...)
- parse\_time\_without\_time\_zone($string,...)

    Similar to the functions above, but always returns an `DateTime` object
    with a floating time zone. If the server returns a time zone, it is
    ignored. This method is suitable for use with the TIME (or TIME WITHOUT
    TIME ZONE) type.

    This ensures that the resulting `DateTime` object will always have the
    time zone expected by your application.

    If given an improperly formatted string, this method may die.

- parse\_date($string,...)

    Given a string containing a date representation, this method will return
    a new `DateTime` object. The time is set to 00:00:00 (floating time
    zone). This method is suitable for the DATE type.

    If given an improperly formatted string, this method may die.

- parse\_duration($string)
- parse\_interval($string)

    Given a string containing a duration (SQL type INTERVAL) representation,
    this method will return a new `DateTime::Duration` object.

    If given an improperly formatted string, this method may die.

## FORMATTING METHODS

This class provides the following formatting methods.

The output is always in the format mandated by the SQL standard (derived
from ISO 8601), which is parsed by PostgreSQL unambiguously in all
DateStyle modes.

- format\_datetime($datetime,...)

    Given a `DateTime` object, this method returns a string appropriate as
    input for all date and date/time types of PostgreSQL. It will contain
    date and time.

    If the time zone of the `DateTime` part is floating, the resulting
    string will contain no time zone, which will result in the server's time
    zone being used. Otherwise, the numerical offset of the time zone is
    used.

- format\_time($datetime,...)
- format\_time\_without\_time\_zone($datetime,...)

    Given a `DateTime` object, this method returns a string appropriate as
    input for the TIME type (also known as TIME WITHOUT TIME ZONE), which
    will contain the local time of the `DateTime` object and no time zone.

- format\_timetz($datetime)
- format\_time\_with\_time\_zone($datetime)

    Given a `DateTime` object, this method returns a string appropriate as
    input for the TIME WITH TIME ZONE type (also known as TIMETZ), which
    will contain the local part of the `DateTime` object and a numerical
    time zone.

    You should not use the TIME WITH TIME ZONE type to store dates with
    floating time zones.  If the time zone of the `DateTime` part is
    floating, the resulting string will contain no time zone, which will
    result in the server's time zone being used.

- format\_date($datetime)

    Given a `DateTime` object, this method returns a string appropriate as
    input for the DATE type, which will contain the date part of the
    `DateTime` object.

- format\_timestamp($datetime)
- format\_timestamp\_without\_time\_zone($datetime)

    Given a `DateTime` object, this method returns a string appropriate as
    input for the TIMESTAMP type (also known as TIMESTAMP WITHOUT TIME
    ZONE), which will contain the local time of the `DateTime` object and
    no time zone.

- format\_timestamptz($datetime)
- format\_timestamp\_with\_time\_zone($datetime)

    Given a `DateTime` object, this method returns a string appropriate as
    input for the TIMESTAMP WITH TIME ZONE type, which will contain the
    local part of the `DateTime` object and a numerical time zone.

    You should not use the TIMESTAMP WITH TIME ZONE type to store dates with
    floating time zones.  If the time zone of the `DateTime` part is
    floating, the resulting string will contain no time zone, which will
    result in the server's time zone being used.

- format\_duration($du)
- format\_interval($du)

    Given a `DateTime::Duration` object, this method returns a string appropriate
    as input for the INTERVAL type.

# LIMITATIONS

Some output formats of PostgreSQL have limitations that can only be passed on
by this class.

As a general rules, none of these limitations apply to the 'ISO' output
format.  It is strongly recommended to use this format (and to use
PostgreSQL's to\_char function when another output format that's not
supposed to be handled by a parser of this class is desired). 'ISO' is
the default but you are advised to explicitly set it at the beginning of
the session by issuing a SET DATESTYLE TO 'ISO'; command in case the
server administrator changes that setting.

When formatting DateTime objects, this class always uses a format that's
handled unambiguously by PostgreSQL.

## TIME ZONES

If DateStyle is set to 'PostgreSQL', 'SQL', or 'German', PostgreSQL does
not send numerical time zones for the TIMESTAMPTZ (or TIMESTAMP WITH
TIME ZONE) type. Unfortunately, the time zone names used instead can be
ambiguous: For example, 'EST' can mean -0500, +1000, or +1100.

You must set the 'server\_tz' variable to a time zone that is identical to that
of the PostgreSQL server. If the server is set to a different time zone (or the
underlying operating system interprets the time zone differently), the parser
will return wrong times.

You can avoid such problems by setting the server's time zone to UTC
using the SET TIME ZONE 'UTC' command and setting 'server\_tz' parameter
to 'UTC' (or by using the ISO output format, of course).

## EUROPEAN DATES

For the SQL (for DATE and TIMSTAMP\[TZ\]) and the PostgreSQL (for DATE)
output format, the server can send dates in both European-style
'dd/mm/yyyy' and in US-style 'mm/dd/yyyy' format. In order to parse
these dates correctly, you have to pass the 'european' option to the
constructor or to the `parse_xxx` routines.

This problem does not occur when using the ISO or German output format
(and for PostgreSQL with TIMESTAMP\[TZ\] as month names are used then).

## INTERVAL ELEMENTS

`DateTime::Duration` stores months, days, minutes and seconds
separately. PostgreSQL only stores months and seconds and disregards the
irregular length of days due to DST switching and the irregular length
of minutes due to leap seconds. Therefore, it is not possible to store
`DateTime::Duration` objects as SQL INTERVALs without the loss of some
information.

## NEGATIVE INTERVALS

In the SQL and German output formats, the server does not send an
indication of the sign with intervals. This means that '1 month ago' and
'1 month' are both returned as '1 mon'.

This problem can only be avoided by using the 'ISO' or 'PostgreSQL'
output format.

# SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

# AUTHOR

Daisuke Maki <daisuke@endeworks.jp>

# AUTHOR EMERITUS 

Claus A. Faerber <perl@faerber.muc.de>

# COPYRIGHT

Copyright (c) 2003 Claus A. Faerber. Copyright (c) 2005-2007 Daisuke Maki

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

# SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/
