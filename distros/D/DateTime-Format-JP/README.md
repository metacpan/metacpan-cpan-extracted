SYNOPSIS
========

        use DateTime::Format::JP;
        my $fmt = DateTime::Format::JP->new(
            hankaku      => 1,
            pattern      => '%c', # default
            traditional  => 0,
            kanji_number => 0,
            zenkaku      => 0,
            time_zone    => 'local',
        );
        my $dt = DateTime->now;
        $dt->set_formatter( $fmt );
        # set the encoding in and out to utf8
        use open ':std' => ':utf8';
        print "$dt\n"; # will print something like 令和3年7月12日午後2:30:20

        my $dt  = $fmt->parse_datetime( "令和３年７月１２日午後２時３０分" );
        
        my $str = $fmt->format_datetime( $dt );
        print "$str\n";

VERSION
=======

        v0.1.2

DESCRIPTION
===========

This module is used to parse and format Japanese date and time. It is
lightweight and yet versatile.

It implements 2 main methods:
[\"parse\_datetime\"](#parse_datetime){.perl-module} and
[\"format\_datetime\"](#format_datetime){.perl-module} both expect and
return decoded utf8 string.

You can use [Encode](https://metacpan.org/pod/Encode){.perl-module} to
decode and encode from perl internal utf8 representation to real utf8
and vice versa.

METHODS
=======

new
---

The constructor accepts the following parameters:

*hankaku* boolean

:   If true, the digits used will be \"half-size\" (半角), or roman
    numbers like 1, 2, 3, etc.

    The opposite is *zenkaku* (全角) or full-width. This will enable the
    use of double-byte Japanese numbers that still look like roman
    numbers, such as: １, ２, ３, etc.

    Defaults to true.

*pattern* string

:   The pattern to use to format the date and time. See below the
    available [\"PATTERN TOKENS\"](#pattern-tokens){.perl-module} and
    their meanings.

    Defaults to `%c`

*traditional* boolean

:   If true, then it will use a more traditional date/time
    representation. The effect of this parameter on the formatting is
    documented in [\"PATTERN TOKENS\"](#pattern-tokens){.perl-module}

*kanji\_number* boolean

:   If true, this will have
    [\"format\_datetime\"](#format_datetime){.perl-module} use numbers
    in kanji, such as: 一, 二, 三, 四, etc.

*zenkaku* boolean

:   If true, this will use full-width, ie double-byte Japanese numbers
    that still look like roman numbers, such as: １, ２, ３, etc.

*time\_zone* string

:   The time zone to use when creating a
    [DateTime](https://metacpan.org/pod/DateTime){.perl-module} object.
    Defaults to `local` if
    [DateTime::TimeZone](https://metacpan.org/pod/DateTime::TimeZone){.perl-module}
    supports it, otherwise it will fallback on `UTC`

error
-----

Returns the latest error set, if any.

All method in this module return `undef` upon error and set an error
that can be retrieved with this method.

format\_datetime
----------------

Takes a [DateTime](https://metacpan.org/pod/DateTime){.perl-module}
object and returns a formatted date and time based on the pattern
specified, which defaults to `%c`.

You can call this method directly, or you can set this formatter object
in [\"set\_formatter\" in
DateTime](https://metacpan.org/pod/DateTime#set_formatter){.perl-module}
so that ie will be used for stringification of the
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object.

See below [\"PATTERN TOKENS\"](#pattern-tokens){.perl-module} for the
available tokens and their meanings.

hankaku
-------

Sets or gets the boolean value for *hankaku*.

kanji\_number
-------------

Sets or gets the boolean value for *kanji\_number*.

parse\_datetime
---------------

Takes a string representing a Japanese date, parse it and return a new
[DateTime](https://metacpan.org/pod/DateTime){.perl-module}. If an error
occurred, it will return `undef` and you can get the error using
[\"error\"](#error){.perl-module}

time\_zone
----------

Sets or gets the string representing the time zone to use when creating
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object. This
is used by [\"parse\_datetime\"](#parse_datetime){.perl-module}

traditional
-----------

Sets or gets the boolean value for *traditional*.

zenkaku
-------

Sets or gets the boolean value for *zenkaku*.

SUPPORT METHODS
===============

kanji\_to\_romaji
-----------------

Takes a number in kanji and returns its equivalent value in roman
(regular) numbers.

lookup\_era
-----------

Takes an Japanese era in kanji and returns an
`DateTime::Format::JP::Era` object

lookup\_era\_by\_date
---------------------

Takes a [DateTime](https://metacpan.org/pod/DateTime){.perl-module}
object and returns a `DateTime::Format::JP::Era` object

make\_datetime
--------------

Returns a [DateTime](https://metacpan.org/pod/DateTime){.perl-module}
based on parameters provided.

romaji\_to\_kanji
-----------------

Takes a number and returns its equivalent representation in Japanese
kanji. Thus, for example, `1234` would be returned as `千二百三十四`

Please note that, since this is intended to be used only for dates, it
does not format number over 9 thousand. If you think there is such need,
please contact the author.

romaji\_to\_kanji\_simple
-------------------------

Replaces numbers with their Japanese kanji equivalent. It does not use
numerals.

romaji\_to\_zenkaku
-------------------

Takes a number and returns its equivalent representation in double-byte
Japanese numbers. Thus, for example, `1234` would be returned as
`１２３４`

zenkaku\_to\_romaji
-------------------

Takes a string representing a number in full width (全角), i.e.
double-byte and returns a regular equivalent number. Thus, for example,
`１２３４` would be returned as `1234`

PATTERN TOKENS
==============

Here are below the available tokens for formatting and the value they
represent.

In all respect, they are closely aligned with [\"strftime\" in
DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module} (see
[\"strftime Patterns\" in
DateTime](https://metacpan.org/pod/DateTime#strftime Patterns){.perl-module}),
except that the formatter object parameters provided upon instantiation
alter the values used.

-   %%

    The % character.

-   %a

    The weekday name in abbreviated form such as: 月, 火, 水, 木, 金,
    土, 日

-   %A

    The weekday name in its long form such as: 月曜日, 火曜日, 水曜日,
    木曜日, 金曜日, 土曜日, 日曜日

-   %b

    The month name, such as 1月, 2月, etc... 12月 using regular digits.

-   %B

    The month name using full width (全角) digits, such as １月, ２月,
    etc... １２月

-   %h

    The month name using kanjis for numbers, such as 一月, 二月, etc...
    十二月

-   %c

    The datetime format in the Japanese standard most usual form. For
    example for `12th July 2021 14:17:30` this would be:

            令和3年7月12日午後2:17:30

    However, if *traditional* is true, then it would rather be:

            令和3年7月12日午後2時17分30秒

    And if *zenkaku* is true, it will use double-byte numbers instead:

            令和３年７月１２日午後２時１７分３０秒

    And if *kanji\_number* is true, it will then be:

            令和三年七月十二日午後二時十七分三十秒

-   %C

    The century number (year/100) as a 2-digit integer. This is the same
    as [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %d or %e

    The day of month (1-31).

    However, if *zenkaku* is true, then it would rather be with full
    width (全角) numbers: １-３１

    And if *kanji\_number* is true, it will then be with numbers in
    kanji: 一, 二, etc.. 十, 十一, etc..

-   %D

    Equivalent to `%E%y年%m月%d日`

    This is the Japanese style date including with the leading era name.

    If *zenkaku* is true, \"full-width\" (double byte) digits will be
    used and if *kanji\_number* is true, numbers in kanji will be used
    instead.

    See %F for an equivalent date using the Gregorian years rather than
    the Japanese era.

-   %E

    This extension is the Japanese era, such as `令和` (i.e. \"reiwa\":
    the current era)

-   %F

    Equivalent to `%Y年%m月%d日`

    If *zenkaku* is true, \"full-width\" (double byte) digits will be
    used and if *kanji\_number* is true, numbers in kanji will be used
    instead.

    For the year only the conversion from regular digits to Japanese
    kanjis will be done simply by interpolating the digits and not using
    numerals. For example `2021` would become `二〇二一` and not
    `二千二十一`

-   %g

    The year corresponding to the ISO week number, but without the
    century (0-99). This uses regular digits and is the same as
    [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %G

    The ISO 8601 year with century as a decimal number. The 4-digit year
    corresponding to the ISO week number. This has the same format and
    value as %Y, except that if the ISO week number belongs to the
    previous or next year, that year is used instead. Also this returns
    regular digits.

    This uses regular digits and is the same as [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %H

    The hour: 0-23

    If *traditional* is enabled, this would rather be `0-23時`

    However, if *zenkaku* is true, then it would rather use full width
    (全角) numbers: `０-２３時`

    And if *kanji\_number* is true, it will then be something like
    `十時`

-   %I

    The hour on a 12-hour clock (1-12).

    If *zenkaku* is true, it will use full width numbers and if
    *kanji\_number* is true, it will use numbers in kanji instead.

-   %j

    The day number in the year (1-366). This uses regular digits and is
    the same as [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %m

    The month number (1-12).

    If *zenkaku* is true, it will use full width numbers and if
    *kanji\_number* is true, it will use numbers in kanji instead.

-   %M

    The minute: 0-59

    If *traditional* is enabled, this would rather be `0-59分`

    However, if *zenkaku* is true, then it would rather use full width
    (全角) numbers: `０-５９分`

    And if *kanji\_number* is true, it will then be something like
    `十分`

-   %n

    Arbitrary whitespace. Same as in [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %N

    Nanoseconds. For other sub-second values use `%[number]N`.

    This is a pass-through directly to [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %p or %P

    Either produces the same result.

    Either AM (午前) or PM (午後) according to the given time value.
    Noon is treated as pm \"午後\" and midnight as am \"午前\".

-   %r

    Equivalent to `%p%I:%M:%S`

    Note that if *zenkaku* is true, the semi-colon used will be
    double-byte: `：`

    Also if you use this, do not enable *kanji\_number*, because the
    result would be weird, something like:

            午後二：十四：三十 # 2:14:30 in this example

-   %R

    Equivalent to `%H:%M`

    Note that if *zenkaku* is true, the semi-colon used will be
    double-byte: `：`

    Juste like for `%r`, avoid enabling *kanji\_number* if you use this
    token.

-   %s

    Number of seconds since the Epoch.

    If *zenkaku* is enabled, this will return the value as double-byte
    number.

-   %S

    The second: `0-60`

    If *traditional* is enabled, this would rather be `0-60秒`

    However, if *zenkaku* is true, then it would rather use full width
    (全角) numbers: `０-６０秒`

    And if *kanji\_number* is true, it will then be something like
    `六十秒`

    (60 may occur for leap seconds. See
    [DateTime::LeapSecond](https://metacpan.org/pod/DateTime::LeapSecond){.perl-module}).

-   %t

    Arbitrary whitespace. Same as in [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

-   %T

    Equivalent to `%H:%M:%S`

    However, if *zenkaku* option is enabled, the numbers will be
    double-byte roman numbers and the separator will also be
    double-byte. For example:

            １４：２０：３０

-   %U

    The week number with Sunday (日曜日) the first day of the week
    (0-53). The first Sunday of January is the first day of week 1.

    If *zenkaku* is enabled, it will return a double-byte number
    instead.

-   %u

    The weekday number (1-7) with Monday (月曜日) = 1, 火曜日 = 2,
    水曜日 = 3, 木曜日 = 4, 金曜日 = 5, 土曜日 = 6, 日曜日 = 7

    If *zenkaku* is enabled, it will return a double-byte number
    instead.

    This is the `DateTime` standard.

-   %w

    The weekday number (0-6) with Sunday = 0.

    If *zenkaku* is enabled, it will return a double-byte number
    instead.

-   %W

    The week number with Monday (月曜日) the first day of the week
    (0-53). The first Monday of January is the first day of week 1.

    If *zenkaku* is enabled, it will return a double-byte number
    instead.

-   %x

    The date format in the standard most usual form. For example for
    12th July 2021 this would be:

            令和3年7月12日

    However, if *zenkaku* is true, then it would rather be:

            令和３年７月１２日

    And if *kanji\_number* is true, it will then be:

            令和三年七月十二日

-   %X

    The time format in the standard most usual form. For example for
    `14:17:30` this would be:

            午後2:17:30

    And if *zenkaku* is enabled, it would rather use a double-byte
    numbers and separator:

            午後２：１７：３０

    However, if *traditional* is true, then it would rather be:

            午後2時17分30秒

    And if *kanji\_number* is true, it will then be:

            午後二時十七分三十秒

-   %y

    The year of the era. For example `2021-07-12` would be
    `令和3年7月12日` and thus the year value would be `3`

    If *zenkaku* is true, it will use full width numbers and if
    *kanji\_number* is true, it will use numbers in kanji instead.

-   %Y

    A 4-digit year, including century (for example, 1991).

    If *zenkaku* is true, \"full-width\" (double byte) digits will be
    used and if *kanji\_number* is true, numbers in kanji will be used
    instead.

    Same as in `%F`, the conversion from regular digits to Japanese
    kanjis will be done simply by interpolating the digits and not using
    numerals. For example `2021` would become `二〇二一` and not
    `二千二十一`

-   %z

    An RFC-822/ISO 8601 standard time zone specification. (For example
    +1100)

    If *zenkaku* is true, \"full-width\" (double byte) digits and `+/-`
    signs will be used and if *kanji\_number* is true, numbers in kanji
    will be used instead. However, no numeral will be used. Thus a time
    zone offset such as `+0900` would be returned as `＋〇九〇〇`

-   %Z

    The timezone name. (For example EST \-- which is ambiguous). This is
    the same as [\"strftime\" in
    DateTime](https://metacpan.org/pod/DateTime#strftime){.perl-module}

HISTORICAL NOTE
===============

Japanese eras, also known as 元号 (gengo) or 年号 (nengo) form one of
the two parts of a Japanese year in any given date.

It was instituted by and under first Emperor Kōtoku in 645 AD. So be
warned that requiring an era-based Japanese date before will not yield
good results.

Era name were adopted for various reasons such as a to commemorate an
auspicious or ward off a malign event, and it is only recently that era
name changes are tied to a new Emperor.

More on this
[here](https://en.wikipedia.org/wiki/Japanese_era_name){.perl-module}

From 1334 until 1392, there were 2 competing regimes in Japan; the North
and South. This period was called \"Nanboku-chō\" (南北朝). This module
uses the official Northern branch.

Also there has been two times during the period \"Asuka\" (飛鳥時代)
with no era names, from 654/11/24 until 686/8/14 after Emperor Kōtoku
death and from 686/10/1 until 701/5/3 after Emperor Tenmu\'s death just
2 months after his enthronement.

Thus if you want a Japanese date using era during those two periods, you
will get and empty era.

More on this
[here](https://ja.wikipedia.org/wiki/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7_(%E6%97%A5%E6%9C%AC)){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55fc45a5a250)"}\>

SEE ALSO
========

[DateTime](https://metacpan.org/pod/DateTime){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright(c) 2021 DEGUEST Pte. Ltd. DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
