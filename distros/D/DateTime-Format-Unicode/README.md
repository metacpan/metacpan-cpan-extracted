# NAME

DateTime::Format::Unicode - Unicode CLDR Formatter for DateTime

# SYNOPSIS

    use DateTime::Format::Unicode;
    my $fmt = DateTime::Format::Unicode->new(
        locale      => 'ja-Kana-JP',
        # optional, defaults to the locale medium size date formatting
        # See: DateTime::Locale::FromCLDR for more information
        pattern     => 'HH:mm:ss',
        # optional
        time_zone   => 'Asia/Tokyo',
        # will make error become fatal and have this API die instead of setting an exception object
        on_error    => 'fatal',
    ) || die( DateTime::Format::Unicode->error );

or, maybe, just:

    my $fmt = DateTime::Format::Unicode->new;

which, will default to `locale` `en` with date medium-size format pattern `MMM d, y`

# VERSION

    v0.1.0

# DESCRIPTION

This is a Unicode [CLDR](https://cldr.unicode.org/) (Common Locale Data Repository) formatter for [DateTime](https://metacpan.org/pod/DateTime)

It differs from the default formatter used in [DateTime](https://metacpan.org/pod/DateTime) with its method [format\_cldr](https://metacpan.org/pod/DateTime#format_cldr) in several aspects:

- 1. It uses [DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR)

    A much more comprehensive and accurate API to dynamically access the Unicode `CLDR` data whereas the module [DateTime](https://metacpan.org/pod/DateTime) relies on, [DateTime::Locale](https://metacpan.org/pod/DateTime%3A%3ALocale), which uses static data from over 1,000 pre-generated modules.

- 2. It allows for any `locale`

    Since, it uses dynamic data, you can use any `locale`, from the simple `en` to more complex `es-001-valencia`, or even `ja-t-de-t0-und-x0-medical`

- 3. It allows formatting of datetime intervals

    Datetime intervals are very important, and unfortunately unsupported by [DateTime](https://metacpan.org/pod/DateTime) as of July 2024.

- 4. It supports more pattern tokens

    [DateTime](https://metacpan.org/pod/DateTime) [format\_cldr](https://metacpan.org/pod/DateTime#format_cldr) does not support all of the [CLDR pattern tokens](https://unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns), but [DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode) does.

    Known pattern tokens unsupported by [DateTime](https://metacpan.org/pod/DateTime) are:

    - `b`

        Period of the day, such as `am`, `pm`, `noon`, `midnight`

        See ["calendar\_term" in Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData#calendar_term) and its corollary ["day\_period" in Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData#day_period)

    - `B`

        Flexible day periods, such as `at night`

        See ["calendar\_term" in Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData#calendar_term) and its corollary ["day\_period" in Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData#day_period)

    - `O`

        Zone, such as `O` to get the short localized GMT format `GMT-8`, or `OOOO` to get the long localized GMT format `GMT-08:00`

    - `r`

        Related Gregorian year (numeric).

        The documentation states that "For the Gregorian calendar, the ‘r’ year is the same as the ‘u’ year."

    - `U`

        Cyclic year name. However, since this is for non gregorian calendars, like Chinese or Hindu calendars, and since [DateTime](https://metacpan.org/pod/DateTime) only supports gregorian calendar, we do not support it either.

    - `x`

        Timezone, such as `x` would be `-08`, `xx` `-0800` or `+0800`, `xxx` would be `-08:00` or `+08:00`, `xxxx` would be `-0800` or `+0000` and `xxxxx` would be `-08:00`, or `-07:52:58` or `+00:00`

    - `X`

        Timezone, such as `X` (`-08` or `+0530` or `Z`), `XX` (`-0800` or `Z`), `XXX` (`-08:00`), `XXXX` (`-0800` or `-075258` or `Z`), `XXXXX` (`-08:00` or `-07:52:58` or `Z`)

[DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode) only formats `CLDR` datetime patterns, and does not parse them back into a [DateTime](https://metacpan.org/pod/DateTime) object. If you want to achieve that, there is already the module [DateTime::Format::CLDR](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ACLDR) that does this. [DateTime::Format::CLDR](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ACLDR) relies on ["format\_cldr" in DateTime](https://metacpan.org/pod/DateTime#format_cldr) for `CLDR` formatting by the way.

# CONSTRUCTOR

## new

This takes some hash or hash reference of options, instantiates a new [DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode) object, and returns it.

Supported options are as follows. Each option can be later accessed or modified by their associated method.

- `locale`

    A [locale](https://metacpan.org/pod/Locale%3A%3AUnicode), which may be very simple like `en` or much more complex like `ja-t-de-t0-und-x0-medical` or maybe `es-039-valencia` (valencian variant of Spanish as spoken in South Europe)

    If not provided, this will default to `en`

- `on_error`

    Specifies what to do upon error. Possible values are: `undef` (default behaviour), `fatal` (will die), or a `CODE` reference that will be called with the [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode%3A%3AException) as its sole argument, before `undef` is returned in scalar context, or an empty list in list context.

- `pattern`

    A `CLDR` pattern. If none is provided, this will default to the medium-size date pattern for the given `locale`. For example, as per the `CLDR`, for English, this would be `MMM d, y` whereas for the `locale` `ja`, this would be `y/MM/dd`

- `time_zone`

    Set the timezone by providing either a [DateTime::TimeZone](https://metacpan.org/pod/DateTime%3A%3ATimeZone) object, or a string representing a timezone.

    It defaults to the special [DateTime](https://metacpan.org/pod/DateTime) timezone [floating](https://metacpan.org/pod/DateTime%3A%3ATimeZone%3A%3AFloating)

# METHODS

## format\_datetime

This takes a [DateTime](https://metacpan.org/pod/DateTime) object, or if none is provided, it will instantiate one using ["now" in DateTime](https://metacpan.org/pod/DateTime#now), and formats the [pattern](#pattern) that was set and return the resulting formatted string.

# Errors

This module does not die upon errors unless requested to. Instead it sets an [error object](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData%3A%3AException) that can be retrieved.

When an error occurred, an [error object](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData%3A%3AException) will be set and the method will return `undef` in scalar context and an empty list in list context.

The only occasions when this module will die is when there is an internal design error, which would be my fault, or if the value set with [on\_error](#on_error) is `fatal` or also if the `CODE` reference set with [on\_error](#on_error) would, itself, die.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[DateTime](https://metacpan.org/pod/DateTime), [DateTime::Format::FromCLDR](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AFromCLDR), [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode), [Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData), [DateTime::Locale](https://metacpan.org/pod/DateTime%3A%3ALocale)

# COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
