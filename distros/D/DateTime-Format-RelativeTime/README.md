# NAME

DateTime::Format::RelativeTime - A Web Intl.RelativeTimeFormat Class Implementation

# SYNOPSIS

    use DateTime;
    use DateTime::Format::RelativeTime;
    my $fmt = DateTime::Format::RelativeTime->new(
        # You can use en-GB (Unicode / web-style) or en_GB (system-style), it does not matter.
        'en_GB', {
            localeMatcher => 'best fit',
            # see getNumberingSystems() in Locale::Intl for the supported number systems
            numberingSystem => 'latn',
            # Possible values are: long, short or narrow
            style => 'short',
            # Possible values are: always or auto
            numeric => 'always',
        },
    ) || die( DateTime::Format::RelativeTime->error );

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "1 day ago"

    # Format relative time using positive value (1).
    $fmt->format( 1, 'day' ); # "in 1 day"

You can also pass one or two [DateTime](https://metacpan.org/pod/DateTime) objects, and let this interface find out the greatest difference between the two objects. If you pass only one [DateTime](https://metacpan.org/pod/DateTime) object, this will instantiate another [DateTime](https://metacpan.org/pod/DateTime) object, using the method [now](https://metacpan.org/pod/DateTime#now) with the `time_zone` value from the first object.

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    $fmt->format( $dt );
    # Assuming today is 2024-12-31, this would return: "1 qtr. ago"

or, with 2 [DateTime](https://metacpan.org/pod/DateTime) objects:

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    my $dt2 = DateTime->new(
        year => 2022,
        month => 2,
        day => 22,
    );
    $fmt->format( $dt => $dt2 ); # "2 yr. ago"

Using the auto option

If `numeric` option is set to `auto`, it will produce the string `yesterday` or `tomorrow` instead of `1 day ago` or `in 1 day`. This allows to not always have to use numeric values in the output.

    # Create a relative time formatter in your locale with numeric option set to 'auto'.
    my $fmt = DateTime::Format::RelativeTime->new( 'en', { numeric => 'auto' });

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "yesterday"

    # Format relative time using positive day unit (1).
    $fmt->format( 1, 'day' ); # "tomorrow"

In basic use without specifying a locale, `DateTime::Format::RelativeTime` uses the default locale and default options.

A word about precision:

When formatting numbers for display, this module uses up to 15 significant digits. This decision balances between providing high precision for calculations and maintaining readability for the user. If numbers with more than 15 significant digits are provided, they will be formatted to this limit, which should suffice for most practical applications:

    my $num = 0.123456789123456789;
    my $formatted = sprintf("%.15g", $num);
    # $formatted would be "0.123456789123457"

For users requiring exact decimal representation beyond this precision, consider using modules like [Math::BigFloat](https://metacpan.org/pod/Math%3A%3ABigFloat).

# VERSION

    v0.1.0

# DESCRIPTION

This module provides the equivalent of the JavaScript implementation of [Intl.RelativeTimeFormat](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/RelativeTimeFormat)

It relies on [Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData), which provides access to all the [Unicode CLDR (Common Locale Data Repository)](https://cldr.unicode.org/), and [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) to achieve similar results. It requires perl v5.10.1 minimum to run.

The algorithm provides the same result you would get with a web browser.

Because, just like its JavaScript equivalent, `DateTime::Format::Intl` does quite a bit of look-ups and sensible guessing upon object instantiation, you want to create an object for a specific format, cache it and re-use it rather than creating a new one for each date formatting.

# CONSTRUCTOR

## new

    # Create a relative time formatter in your locale
    # with default values explicitly passed in.
    my $fmt = DateTime::Format::RelativeTime->new( 'en', {
        localeMatcher => 'best fit', # other values: 'lookup'
        numeric => 'always', # other values: 'auto'
        style => 'long', # other values: 'short' or 'narrow'
    }) || die( DateTime::Format::RelativeTime->error );

    # Format relative time using negative value (-1).
    $fmt->format( -1, 'day' ); # "1 day ago"

    # Format relative time using positive value (1).
    $fmt->format( 1, 'day' ); # "in 1 day"

This takes a `locale` (a.k.a. language `code` compliant with [ISO 15924](https://en.wikipedia.org/wiki/ISO_15924) as defined by [IETF](https://en.wikipedia.org/wiki/IETF_language_tag#Syntax_of_language_tags)) and an hash or hash reference of options and will return a new [DateTime::Format::RelativeTime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ARelativeTime) object, or upon failure `undef` in scalar context and an empty list in list context.

Each option can also be accessed or changed using their corresponding method of the same name.

See the [CLDR (Unicode Common Locale Data Repository) page](https://cldr.unicode.org/translation/date-time/date-time-patterns) for more on the format patterns used.

Supported options are:

### Locale options

- `localeMatcher`

    The locale matching algorithm to use. Possible values are `lookup` and `best fit`; the default is `best fit`. For information about this option, see [Locale identification and negotiation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl#locale_identification_and_negotiation).

    Whatever value you provide, does not actually have any influence on the algorithm used. `best fit` will always be the one used.

- `numberingSystem`

    The numbering system to use for number formatting, such as `fullwide`, `hant`, `mathsans`, and so on. For a list of supported numbering system types, see [getNumberingSystems()](https://metacpan.org/pod/Locale%3A%3AIntl#getNumberingSystems). This option can also be set through the [nu](https://metacpan.org/pod/Locale%3A%3AUnicode#nu) Unicode extension key; if both are provided, this options property takes precedence.

    For example, a Japanese locale with the `latn` number system extension set and with the `jptyo` time zone:

        my $fmt = DateTime::Format::RelativeTime->new( 'ja-u-nu-latn-tz-jptyo' );

    However, note that you can only provide a number system that is supported by the `locale`, and that is of type `numeric`, i.e. not `algorithmic`. For instance, you cannot specify a `locale` `ar-SA` (arab as spoken in Saudi Arabia) with a number system of Japan:

        my $fmt = DateTime::Format::RelativeTime->new( 'ar-SA', { numberingSystem => 'japn' } );
        say $fmt->resolvedOptions->{numberingSystem}; # arab

    It would reject it, and issue a warning, if warnings are enabled, and fallback to the `locale`'s default number system, which is, in this case, `arab`

    Additionally, even though the number system `jpanfin` is supported by the locale `ja`, it would not be acceptable, because it is not suitable for datetime formatting since it is not of type `numeric`, or at least this is how it is treated by web browsers (see [here the web browser engine implementation](https://github.com/v8/v8/blob/main/src/objects/intl-objects.cc) and [here for the Unicode ICU implementation](https://github.com/unicode-org/icu/blob/main/icu4c/source/i18n/numsys.cpp)). This API could easily make it acceptable, but it was designed to closely mimic the web browser implementation of the JavaScript API `Intl.DateTimeFormat`. Thus:

        my $fmt = DateTime::Format::RelativeTime->new( 'ja-u-nu-jpanfin-tz-jptyo' );
        say $fmt->resolvedOptions->{numberingSystem}; # latn

    See [Mozilla documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getNumberingSystems), and also the perl module [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl)

- `style`

    The style of the formatted relative time. Possible values are:

    - `long`

        This is the default. For example: `in 1 month`

    - `short`

        For example: `in 1 mo.`

    - `narrow`

        For example: `in 1 mo.`. The `narrow` style could be similar to the `short` style for some locales.

- `numeric`

    Whether to use numeric values in the output. Possible values are `always` and `auto`; the default is `always`. When set to `auto`, the output may use more idiomatic phrasing such as `yesterday` instead of `1 day ago`.

# METHODS

## format

    my $fmt = new DateTime::Format::RelativeTime( 'en', { style => 'short' });

    say $fmt->format( 3, 'quarter' );
    # Expected output: "in 3 qtrs."

    say $fmt->format( -1, 'day' );
    # Expected output: "1 day ago"

    say $fmt->format( 10, 'seconds' );
    # Expected output: "in 10 sec."

Alternatively, you can pass two [DateTime](https://metacpan.org/pod/DateTime) objects, and `format` will calculate the greatest time difference between the two. If you provide only one [DateTime](https://metacpan.org/pod/DateTime), `format` will instantiate a new [DateTime](https://metacpan.org/pod/DateTime) object using the `time_zone` value from the first [DateTime](https://metacpan.org/pod/DateTime) object.

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    $fmt->format( $dt );
    # Assuming today is 2024-12-31, this would return: "1 qtr. ago"

or, with 2 [DateTime](https://metacpan.org/pod/DateTime) objects:

    my $dt = DateTime->new(
        year => 2024,
        month => 8,
        day => 15,
    );
    my $dt2 = DateTime->new(
        year => 2022,
        month => 2,
        day => 22,
    );
    $fmt->format( $dt => $dt2 ); # "2 yr. ago"

The `format()` method of `DateTime::Format::RelativeTime` instances formats a value and unit according to the `locale` and formatting `options` of this `DateTime::Format::RelativeTime` object.

It returns a string representing the given value and unit formatted according to the locale and formatting options of this `DateTime::Format::RelativeTime` object.

Supported parameters are:

- `value`

    Numeric value to use in the internationalized relative time message.

    If the value is negative, the result will be formatted in the past.

- `unit`

    Unit to use in the relative time internationalized message.

    Possible values are: `year`, `quarter`, `month`, `week`, `day`, `hour`, `minute`, `second`.
    Plural forms are also permitted.

**Note**: Most of the time, the formatting returned by `format()` is consistent. However, the output may vary between implementations, even within the same `locale` — output variations are by design and allowed by the specification. It may also not be what you expect. For example, the string may use non-breaking spaces or be surrounded by bidirectional control characters. You should _not_ compare the results of `format()` to hardcoded constants.

## formatToParts

    my $fmt = new DateTime::Format::RelativeTime( 'en', { numeric => 'auto' });
    my $parts = $fmt->formatToParts( 10, 'seconds' );

    say $parts->[0]->{value};
    # Expected output: "in "

    say $parts->[1]->{value};
    # Expected output: "10"

    say $parts->[2]->{value};
    # Expected output: " seconds"

    my $fmt = new DateTime::Format::RelativeTime( 'en', { numeric => 'auto' });

    # Format relative time using the day unit
    $fmt->formatToParts( -1, 'day' );
    # [{ type: 'literal', value: 'yesterday' }]

    $fmt->formatToParts( 100, 'day' );
    # [
    #     { type => 'literal', value => 'in ' },
    #     { type => 'integer', value => 100, unit => 'day' },
    #     { type => 'literal', value => ' days' }
    # ]

Just like for [format](#format), you can alternatively provide one or two [DateTime](https://metacpan.org/pod/DateTime) objects.

The `formatToParts()` method of `DateTime::Format::RelativeTime` instances returns an array reference of hash reference representing the relative time format in parts that can be used for custom locale-aware formatting.

The `DateTime::Format::RelativeTime-`formatToParts> method is a version of the [format](#format) method that returns an array reference of hash reference which represents `parts` of the object, separating the formatted number into its constituent parts and separating it from other surrounding text. These hash reference have two or three properties:

- `type` a string
- `value`, a string representing the component of the output.
- `unit`

    The unit value for the number value, when the type is `integer`

Supported parameters are:

- `value`

    Numeric value to use in the internationalized relative time message.

    If the value is negative, the result will be formatted in the past.

- `unit`

    Unit to use in the relative time internationalized message.

    Possible values are: `year`, `quarter`, `month`, `week`, `day`, `hour`, `minute`, `second`.
    Plural forms are also permitted.

## resolvedOptions

    my $fmt = new DateTime::Format::RelativeTime('en', { style => 'narrow' });
    my $options1 = $fmt->resolvedOptions();
    
    my $fmt2 = new DateTime::Format::RelativeTime('es', { numeric => 'auto' });
    my $options2 = $fmt2->resolvedOptions();
    
    say "$options1->{locale}, $options1->{style}, $options1->{numeric}";
    # Expected output: "en, narrow, always"
    
    say "$options2->{locale}, $options2->{style}, $options2->{numeric}";
    # Expected output: "es, long, auto"

The `resolvedOptions()` method of `DateTime::Format::RelativeTime` instances returns a new hash reference with properties reflecting the options computed during initialisation of this `DateTime::Format::RelativeTime` object.

For the details of the properties retured, see the [new](#new) instantiation method.

# CLASS METHODS

## supportedLocalesOf

    my $locales1 = ['ban', 'id-u-co-pinyin', 'de-ID'];
    my $options1 = { localeMatcher: 'lookup' };

    say DateTime::Format::RelativeTime->supportedLocalesOf( $locales1, $options1 );
    # Expected output: ['id-u-co-pinyin', 'de-ID']

The `DateTime::Format::RelativeTime-`supportedLocalesOf> class method returns an array containing those of the provided locales that are supported in relative time formatting without having to fall back to the runtime's default locale.

Supported parameters are:

- `locale`

    A string with a BCP 47 language tag, or an array of such strings. For the general form and interpretation of the `locales` argument, see the parameter description on the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) documentation.

- `options`

    An hash reference that may have the following property:

    - `localeMatcher`

        The locale matching algorithm to use. Possible values are `lookup` and `best fit`; the default is `best fit`. For information about this option, see the [DateTime::Format::Intl](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl) documentation.

        In reality, it does not matter what value you set, because this module only support the `best fit` option.

# OTHER NON-CORE METHODS

## error

Sets or gets an [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl%3A%3AException)

When called with parameters, this will instantiate a new [DateTime::Format::Intl::Exception](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl%3A%3AException) object, passing it all the parameters received.

When called in accessor mode, this will return the latest [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl%3A%3AException) set, if any.

## fatal

    $fmt->fatal(1); # Enable fatal exceptions
    $fmt->fatal(0); # Disable fatal exceptions
    my $bool = $fmt->fatal;

Sets or get the boolean value, whether to die upon exception, or not. If set to true, then instead of setting an [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl%3A%3AException), this module will die with an [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl%3A%3AException). You can catch the exception object then after using `try`. For example:

    use v.5.34; # to be able to use try-catch blocks in perl
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $fmt = DateTime::Format::Intl->new( 'x', fatal => 1 );
    }
    catch( $e )
    {
        say "Error occurred: ", $e->message;
        # Error occurred: Invalid locale value "x" provided.
    }

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# COPYRIGHT & LICENSE

Copyright(c) 2024-2025 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
