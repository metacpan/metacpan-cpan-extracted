# NAME

DateTime::Locale - Localization support for DateTime.pm

# VERSION

version 1.22

# SYNOPSIS

    use DateTime::Locale;

    my $loc = DateTime::Locale->load('en-GB');

    print $loc->native_name, "\n", $loc->datetime_format_long, "\n";

    # but mostly just things like ...

    my $dt = DateTime->now( locale => 'fr' );
    print "Aujourd'hui le mois est " . $dt->month_name, "\n";

# DESCRIPTION

DateTime::Locale is primarily a factory for the various locale subclasses. It
also provides some functions for getting information on all the available
locales.

If you want to know what methods are available for locale objects, then please
read the `DateTime::Locale::FromData` documentation.

# USAGE

This module provides the following class methods:

## DateTime::Locale->load( $locale\_code | $locale\_name )

Returns the locale object for the specified locale code or name - see the
`DateTime::Locale::Catalog` documentation for the list of available codes and
names. The name provided may be either the English or native name.

If the requested locale is not found, a fallback search takes place to
find a suitable replacement.

The fallback search order is:

    {language}-{script}-{territory}
    {language}-{script}
    {language}-{territory}-{variant}
    {language}-{territory}
    {language}

Eg. For the locale code `es-XX-UNKNOWN` the fallback search would be:

    es-XX-UNKNOWN   # Fails - no such locale
    es-XX           # Fails - no such locale
    es              # Found - the es locale is returned as the
                    # closest match to the requested id

Eg. For the locale code `es-Latn-XX` the fallback search would be:

    es-Latn-XX      # Fails - no such locale
    es-Latn         # Fails - no such locale
    es-XX           # Fails - no such locale
    es              # Found - the es locale is returned as the
                    # closest match to the requested id

If no suitable replacement is found, then an exception is thrown.

The loaded locale is cached, so that **locale objects may be
singletons**. Calling `DateTime::Locale->register_from_data`, `DateTime::Locale->add_aliases`, or `DateTime::Locale->remove_alias`
clears the cache.

## DateTime::Locale->codes

    my @codes = DateTime::Locale->codes;
    my $codes = DateTime::Locale->codes;

Returns an unsorted list of the available locale codes, or an array reference if
called in a scalar context. This list does not include aliases.

## DateTime::Locale->names

    my @names = DateTime::Locale->names;
    my $names = DateTime::Locale->names;

Returns an unsorted list of the available locale names in English, or an array
reference if called in a scalar context.

## DateTime::Locale->native\_names

    my @names = DateTime::Locale->native_names;
    my $names = DateTime::Locale->native_names;

Returns an unsorted list of the available locale names in their native
language, or an array reference if called in a scalar context. All native
names use UTF-8 as appropriate.

## DateTime::Locale->register\_from\_data( $locale\_data )

This method allows you to register a custom locale. The data for the locale is
specified as a hash (or hashref) where the keys match the method names given
in `DateTime::Locale::FromData`.

If you just want to make some small changes on top of an existing locale you
can get that locale's data by calling `$locale->locale_data`.

Here is an example of making a custom locale based off of `en-US`:

    my $locale = DateTime::Locale->load('en-US');
    my %data   = $locale->locale_data;
    $data{code}               = 'en-US-CUSTOM';
    $data{time_format_medium} = 'HH:mm:ss';

    DateTime::Locale->register_from_data(%data);

    # Prints 18:24:38
    say DateTime->now( locale => 'en-US-CUSTOM' )->strftime('%X');

    # Prints 6:24:38 PM
    say DateTime->now( locale => 'en-US' )->strftime('%X');

The keys that should be present in the hash are the same as the accessor
methods provided by [DateTime::Locale::FromData](https://metacpan.org/pod/DateTime::Locale::FromData), except for the following:

- The `*_code` methods

    While you should provide a `code` key, the other methods like
    `language_code` and `script_code` are determined by parsing the code.

- All `id` returning methods

    These are aliases for the corresponding `*code` methods.

- `prefers_24_hour_time`

    This is determined by looking at the short time format to see how it formats
    hours,

- `date_format_default` and `time_format_default`

    These are the corresponding medium formats.

- `datetime_format` and `datetime_format_default`

    This is the same as the medium format.

- `date_formats` and `time_formats`

    These are calculated as needed.

- `available_formats`

    This should be provided as a hashref where the keys are things like `Gy` or
    `MMMEd` and the values are an actual format like `"y G"` or `"E, MMM d"`.

- `locale_data`

    This is everything you pass in.

# LOADING LOCALES IN A PRE-FORKING SYSTEM

If you are running an application that does pre-forking (for example with
Starman), then you should try to load all the locales that you'll need in the
parent process. Locales are loaded on-demand, so loading them once in each
child will waste memory that could otherwise be shared.

# CLDR DATA BUGS

Please be aware that all locale data has been generated from the CLDR (Common
Locale Data Repository) project locales data). The data is incomplete, and may
contain errors in some locales.

When reporting errors in data, please check the primary data sources first,
then where necessary report errors directly to the primary source via the CLDR
bug report system. See http://unicode.org/cldr/filing\_bug\_reports.html for
details.

Once these errors have been confirmed, please forward the error report and
corrections to the DateTime mailing list, datetime@perl.org.

# AUTHOR EMERITUS

Richard Evans wrote the first version of DateTime::Locale, including the tools
to extract the CLDR data.

# SEE ALSO

[DateTime::Locale::Base](https://metacpan.org/pod/DateTime::Locale::Base)

datetime@perl.org mailing list

http://datetime.perl.org/

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/DateTime-Locale/issues](https://github.com/houseabsolute/DateTime-Locale/issues).

There is a mailing list available for users of this distribution,
[mailto:datetime@perl.org](mailto:datetime@perl.org).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for DateTime-Locale can be found at [https://github.com/houseabsolute/DateTime-Locale](https://github.com/houseabsolute/DateTime-Locale).

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

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Karen Etheridge <ether@cpan.org>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>
- Ryley Breiddal <rbreiddal@presinet.com>
- Sergey Leschenko <Sergey.Leschenko@portaone.com>
- yasu47b <nakayamayasuhiro1986@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2003 - 2018 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
