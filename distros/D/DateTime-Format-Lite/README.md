# NAME

DateTime::Format::Lite - Parse and format datetimes with strptime patterns, returning DateTime::Lite objects

# SYNOPSIS

    use DateTime::Format::Lite;

    my $fmt = DateTime::Format::Lite->new(
        pattern   => '%Y-%m-%dT%H:%M:%S',
        locale    => 'ja-JP',
        time_zone => 'Asia/Tokyo',
    ) || die( DateTime::Format::Lite->error );

    my $dt  = $fmt->parse_datetime( '2026-04-14T09:00:00' );
    my $str = $fmt->format_datetime( $dt );

    # Exportable convenience functions
    use DateTime::Format::Lite qw( strptime strftime );
    my $dt2  = strptime( '%Y-%m-%d', '2026-04-14' );
    my $str2 = strftime( '%Y-%m-%d', $dt2 );

# VERSION

    v0.1.2

# DESCRIPTION

[DateTime::Format::Lite](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite) parses and formats datetime strings using strptime-style patterns, returning [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) objects.

It is a replacement for [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime) designed for the [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) ecosystem, with the following key differences:

- No heavy dependencies

    No `Params::ValidationCompiler`, `Specio`, or `Try::Tiny`. Validation follows the same lightweight philosophy as [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) itself.

- Returns [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) objects

    `parse_datetime` returns [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) objects rather than [DateTime](https://metacpan.org/pod/DateTime) objects.

- Dynamic timezone abbreviation resolution

    Rather than a static hardcoded table of ~300 entries, timezone abbreviations are resolved live against the [IANA data](https://ftp.iana.org/tz/releases/) in the SQLite database bundled with [DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone), via ["resolve\_abbreviation" in DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone#resolve_abbreviation). The resolution is automatically up to date with each tzdata release.

- XS-accelerated hot paths

    When a C compiler is available at install time, `_match_and_extract` and `format_datetime` are implemented in XS for reduced per-call overhead. A pure-Perl fallback is used automatically otherwise.

- Error handling via `error()`

    Errors set an error object accessible via `$fmt->error` and return `undef` in scalar context, or an empty list in list context, or a `DateTime::Format::Lite::NullObject` object in object chaining context detected with [Wanted](https://metacpan.org/pod/Wanted), consistent with [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite). Fatal mode is available when the instantiation option `on_error` is set to `croak` or `die`.

# CONSTRUCTORS

## new

    my $fmt = DateTime::Format::Lite->new(
        pattern   => '%Y-%m-%d %H:%M:%S',
        locale    => 'fr-FR',
        time_zone => 'Europe/Paris',
        on_error  => 'undef',
        strict    => 0,
        zone_map  => { BST => 'Europe/London' },
    ) || die( DateTime::Format::Lite->error );

The `pattern` parameter is required. All others are optional.

- `pattern`

    A strptime-style format string. See ["TOKENS"](#tokens).

- `locale`

    A [BCP47 locale](https://cldr.unicode.org/index/bcp47-extension) string (such as `fr-FR` or `ja-JP` or even more complex ones like `ja-Kana-t-it` or `es-Latn-001-valencia`), a [DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR) object, or a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object. Defaults to `en`.

- `time_zone`

    An IANA timezone name string (such as `Asia/Tokyo`) or a [DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone) object. When provided, it is applied to the parsed object after construction. If omitted, the parsed object uses the floating timezone unless the pattern itself contains `%z`, `%Z`, or `%O`.

- `on_error`

    Error handling mode: `undef` (by default, it returns `undef` on error), `croak` or `die` (dies with the error message), or a code reference invoked as `$coderef->( $fmt_object, $message )`.

- `strict`

    If true, wraps the compiled regex with word-boundary anchors, requiring the input datetime to be delimited from surrounding text.

- `zone_map`

    A hash reference of abbreviation overrides. Keys are abbreviation strings; values are IANA timezone names or numeric offset strings. Set a key to `undef` to mark an abbreviation as explicitly ambiguous (always errors if encountered during parsing).

# METHODS

## format\_datetime

    my $string = $fmt->format_datetime( $dt );

Formats a [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) object using the configured pattern. Delegates directly to [DateTime::Lite-](https://metacpan.org/pod/DateTime%3A%3ALite-)strftime|DateTime::Lite/strftime> without cloning.

Returns a string, or `undef` on error.

## format\_duration

    my $string = $fmt->format_duration( $duration );

Formats a [DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration) object as an ISO 8601 duration string such as `P1Y2M3DT4H5M6S`. A zero duration returns `PT0S`.

## parse\_datetime

    my $dt = $fmt->parse_datetime( '2026-04-14 09:00:00' );

Parses `$string` against the configured pattern and returns a [DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite) object on success, or `undef` on failure (with the error accessible via `$fmt->error`).

## parse\_duration

    my $dur = $fmt->parse_duration( 'P1Y2M3DT4H5M6S' );

Parses an ISO 8601 duration string and returns a [DateTime::Lite::Duration](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ADuration) object.

# ACCESSORS

## debug

Boolean. When set to a true value, emits diagnostic warnings during pattern compilation and timezone resolution.

## error

    my $err = DateTime::Format::Lite->error;   # class-level last error
    my $err = $fmt->error;                     # instance-level last error

Returns the last [DateTime::Format::Lite::Exception](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite%3A%3AException) object set by a failed operation, or `undef` if no error has occurred. When called as a class method it returns the last error set by any instance or constructor call. When called as an instance method it returns the last error set on that specific object.

## fatal

Boolean. When true, any error calls `die()` immediately instead of returning `undef`. Equivalent to setting the instantiation option `on_error` to `die`, but applies globally when set as a class method.

## locale

A [BCP47 locale](https://cldr.unicode.org/index/bcp47-extension) string (such as `fr-FR` or `ja-JP` or even more complex ones like `ja-Kana-t-it` or `es-Latn-001-valencia`), a [DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR) object, or a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object. Defaults to `en`.

Controls the locale used for parsing and formatting locale-sensitive tokens such as `%a`, `%A`, `%b`, `%B`, and `%p`.

## on\_error

Error handling mode. One of:

- `undef` (default)

    Returns `undef` on error and stores the exception in `$fmt->error`.

- `croak` or `die`

    Calls `die()` with the exception object.

- `coderef`

    Calls `$coderef->( $fmt, $message )`. The coderef receives the formatter object and the error message string.

## pass\_error

    return( $self->pass_error );
    return( $self->pass_error( $other_object ) );

Propagates the last error from `$self` (or from `$other_object` if provided) up the call stack. Returns `undef` in scalar context or an empty list in list context. Used internally to chain error propagation between methods.

## pattern

The strptime pattern string, such as `%Y-%m-%dT%H:%M:%S`. Required at construction time; may be updated after construction.

## strict

Boolean. When true, the generated regex is anchored with word boundaries (`\b`) at both ends. This prevents matching a date pattern embedded in a longer string such as `2016-03-31.log` from matching if the surrounding characters would cause a word-boundary failure.

## time\_zone

A timezone name (`Asia/Tokyo`, `UTC`, `floating`) or a [DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone) object. When set, this timezone is applied to every parsed object, overriding any timezone parsed from `%z`, `%Z`, or `%O`.

## zone\_map

A hash reference mapping timezone abbreviations to IANA names or numeric offset strings. Useful for resolving ambiguous abbreviations such as `IST` (which maps to India, Ireland, and Israel):

    zone_map => { IST => 'Asia/Kolkata' }

Setting a key to `undef` marks the abbreviation as explicitly ambiguous (always an error if encountered during parsing).

# TOKENS

    %Y  Four-digit year
    %y  Two-digit year (69-99 -> 19xx, 00-68 -> 20xx)
    %C  Century (combined with %y)
    %m  Month (01-12)
    %d  Day of month (01-31)
    %e  Day of month, space-padded
    %H  Hour 24h (00-23)
    %k  Hour 24h, space-padded
    %I  Hour 12h (01-12)
    %l  Hour 12h, space-padded
    %M  Minute (00-59)
    %S  Second (00-60)
    %N  Nanoseconds (scaled to 9 digits; %3N -> milliseconds, etc.)
    %p  AM/PM (locale-aware, case-insensitive)
    %P  am/pm (alias for %p)
    %a  Abbreviated weekday name (locale-aware)
    %A  Full weekday name (locale-aware)
    %b  Abbreviated month name (locale-aware)
    %B  Full month name (locale-aware)
    %h  Alias for %b
    %j  Day of year (001-366)
    %s  Unix epoch timestamp (positive or negative; pre-1970 dates use negative values)
    %u  Day of week (1=Mon .. 7=Sun, ISO)
    %w  Day of week (0=Sun .. 6=Sat)
    %U  Week number, Sunday as first day (00-53)
    %W  Week number, Monday as first day (00-53)
    %G  ISO week year (4 digits)
    %g  ISO week year (2 digits)
    %z  Timezone offset: Z, +HH:MM, +HHMM, +HH
    %Z  Timezone abbreviation such as JST or EDT
    %O  Olson/IANA timezone name such as Asia/Tokyo
    %D  Equivalent to %m/%d/%y
    %F  Equivalent to %Y-%m-%d
    %T  Equivalent to %H:%M:%S
    %R  Equivalent to %H:%M
    %r  Equivalent to %I:%M:%S %p
    %c  Locale datetime format (fixed C-locale fallback: "%a %b %e %T %Y")
    %x  Locale date format (fixed C-locale fallback: "%m/%d/%y")
    %X  Locale time format (fixed C-locale fallback: "%T")
    %n  Whitespace
    %t  Whitespace
    %%  Literal percent sign

# EXPORTABLE FUNCTIONS

    use DateTime::Format::Lite qw( strptime strftime );

    my $dt  = strptime( '%Y-%m-%d', '2026-04-14' );
    my $str = strftime( '%Y-%m-%d', $dt );

Both functions dies on error.

## strptime

    my $dt = strptime( $pattern, $string );

Convenience wrapper. Constructs a one-shot [DateTime::Format::Lite](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite) with `$pattern` and calls `parse_datetime( $string )`. Dies on error (constructor or parse failure).

## strftime

    my $str = strftime( $pattern, $dt );

Convenience wrapper. Constructs a one-shot [DateTime::Format::Lite](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite) with `$pattern` and calls `format_datetime( $dt )`. Dies on error.

# ERROR HANDLING

On error, this class methods set an [exception object](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite%3A%3AException), and return `undef` in scalar context, or an empty list in list context. The exception object is accessible via:

    my $err = DateTime::Format::Lite->error;  # class method
    my $err = $dt->error;                     # instance method

The exception object stringifies to a human-readable message including file and line number.

`error` detects the context is chaining, or object, and thus instead of returning `undef`, it will return a dummy instance of `DateTime::Format::Lite::NullObject` to avoid the typical perl error `Can't call method '%s' on an undefined value`.

So for example:

    $fmt->parse_datetime( %bad_arguments )->iso8601;

If there was an error in `parse_datetime`, the chain will execute, but the last one, `iso8601` in this example, will return `undef`, so you can and even should check the return value:

    $fmt->parse_datetime( %bad_arguments )->iso8601 ||
        die( $fmt->error );

# SERIALISATION

[DateTime::Format::Lite](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite) supports serialisation via [Storable](https://metacpan.org/pod/Storable), [Sereal](https://metacpan.org/pod/Sereal), [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS), and JSON serialisers.

The following methods are implemented:

- `FREEZE` / `THAW`

    Used by [Sereal](https://metacpan.org/pod/Sereal) (v4+) and [CBOR::XS](https://metacpan.org/pod/CBOR%3A%3AXS). The object is reduced to its public configuration state (`pattern`, `locale`, `time_zone`, `on_error`, `strict`, `debug`, `zone_map`). Internal caches are not serialised and are rebuilt on demand after thawing.

- `STORABLE_freeze` / `STORABLE_thaw`

    Used by [Storable](https://metacpan.org/pod/Storable). The state is encoded as a compact pipe-delimited string. The `zone_map` is JSON-encoded when non-empty.

- `TO_JSON`

    Returns the public configuration state as a plain hash reference, suitable for serialisation by [JSON::XS](https://metacpan.org/pod/JSON%3A%3AXS), [Cpanel::JSON::XS](https://metacpan.org/pod/Cpanel%3A%3AJSON%3A%3AXS), or similar. The returned hash reference contains: `pattern`, `locale` (BCP47 string), `time_zone` (IANA name string or `undef`), `on_error`, `strict`, `debug`, and `zone_map`.

    Note that if `on_error` was set to a code reference, it cannot be serialised. `undef` is stored as a fallback and a warning is issued if the [DateTime::Format::Lite](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3ALite) warning category is enabled.

# SEE ALSO

[DateTime::Lite](https://metacpan.org/pod/DateTime%3A%3ALite), [DateTime::Lite::TimeZone](https://metacpan.org/pod/DateTime%3A%3ALite%3A%3ATimeZone), [DateTime::Format::Strptime](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AStrptime), [DateTime::Format::Unicode](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AUnicode), [DateTime::Locale::FromCLDR](https://metacpan.org/pod/DateTime%3A%3ALocale%3A%3AFromCLDR), [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode), [Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
