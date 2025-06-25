CGI-Lingua
==========

[![Appveyor Status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-lingua)
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/CGI-Lingua/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Lingua?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-Lingua.svg)](http://search.cpan.org/~nhorne/CGI-Lingua/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/cgi-lingua/test.yml?branch=master)
![Perl Version](https://img.shields.io/badge/perl-5.8+-blue)
[![Travis Status](https://travis-ci.org/nigelhorne/CGI-Lingua.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Lingua)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://x.com/intent/tweet?text=Information+about+the+CGI+Environment+#perl+#CGI&url=https://github.com/nigelhorne/cgi-lingua&via=nigelhorne)

# NAME

CGI::Lingua - Create a multilingual web page

# VERSION

Version 0.74

# SYNOPSIS

CGI::Lingua is a powerful module for multilingual web applications
offering extensive language/country detection strategies.

No longer does your website need to be in English only.
CGI::Lingua provides a simple basis to determine which language to display a website.
The website tells CGI::Lingua which languages it supports.
Based on that list CGI::Lingua tells the application which language the user would like to use.

    use CGI::Lingua;
    # ...
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb', 'en-us']);
    my $language = $l->language();
    if ($language eq 'English') {
        print '<P>Hello</P>';
    } elsif($language eq 'French') {
        print '<P>Bonjour</P>';
    } else {    # $language eq 'Unknown'
        my $rl = $l->requested_language();
        print "<P>Sorry for now this page is not available in $rl.</P>";
    }
    my $c = $l->country();
    if ($c eq 'us') {
      # print contact details in the US
    } elsif ($c eq 'ca') {
      # print contact details in Canada
    } else {
      # print worldwide contact details
    }

    # ...

    use CHI;
    use CGI::Lingua;
    # ...
    my $cache = CHI->new(driver => 'File', root_dir => '/tmp/cache', namespace => 'CGI::Lingua-countries');
    $l = CGI::Lingua->new({ supported => ['en', 'fr'], cache => $cache });

# SUBROUTINES/METHODS

## new

Creates a CGI::Lingua object.

Takes one mandatory parameter: a list of languages, in RFC-1766 format,
that the website supports.
Language codes are of the form primary-code \[ - country-code \] e.g.
'en', 'en-gb' for English and British English respectively.

For a list of primary codes refer to ISO-639 (e.g. 'en' for English).
For a list of country codes refer to ISO-3166 (e.g. 'gb' for United Kingdom).

    # Sample web page
    use CGI::Lingua;
    use CHI;
    use Log::Log4perl;

    my $cache = CHI->new(driver => 'File', root_dir => '/tmp/cache');
    Log::Log4perl->easy_init({ level => $Log::Log4perl::DEBUG });

    # We support English, French, British and American English, in that order
    my $lingua = CGI::Lingua->new(
        supported => ['en', 'fr', 'en-gb', 'en-us'],
        cache     => $cache,
        logger    => Log::Log4perl->get_logger(),
    );

    print "Content-Type: text/plain\n\n";
    print 'Language: ', $lingua->language(), "\n";
    print 'Country: ', $lingua->country(), "\n";
    print 'Time Zone: ', $lingua->time_zone(), "\n";

Supported\_languages is the same as supported.

It takes several optional parameters:

- `cache`

    An object which is used to cache country lookups.
    This cache object is an object that understands get() and set() messages,
    such as a [CHI](https://metacpan.org/pod/CHI) object.

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format,
    including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

- `logger`

    Used for warnings and traces.
    It can be an object that understands warn() and trace() messages,
    such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) or [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) object,
    a reference to code,
    a reference to an array,
    or a filename.
    See [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) for further details.

- `info`

    Takes an optional parameter info, an object which can be used to see if a CGI
    parameter is set, for example, an [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object.

- `data`

    Passed on to [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage).

- `dont_use_ip`

    By default, if none of the
    requested languages is supported, CGI::Lingua->language() looks in the IP
    address for the language to use.
    This may not be what you want,
    so use this option to disable the feature.

- `syslog`

    Takes an optional parameter syslog, to log messages to
    [Sys::Syslog](https://metacpan.org/pod/Sys%3A%3ASyslog).
    It can be a boolean to enable/disable logging to syslog, or a reference
    to a hash to be given to Sys::Syslog::setlogsock.

Since emitting warnings from a CGI class can result in messages being lost (you
may forget to look in your server's log), or appear to the client in
amongst HTML causing invalid HTML, it is recommended either syslog
or logger (or both) are set.
If neither is given, [Carp](https://metacpan.org/pod/Carp) will be used.

## language

Tells the CGI application in what language to display its messages.
The language is the natural name e.g. 'English' or 'Japanese'.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, language() will return 'English'.

If none of the requested languages is included within the supported lists,
language() returns 'Unknown'.

    use CGI::Lingua;
    # Site supports English and British English
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb']);

If the browser requests 'en-us', then language will be 'English' and
sublanguage will also be undefined, which may seem strange, but it
ensures that sites behave sensibly.

    # Site supports British English only
    my $l = CGI::Lingua->new({ supported => ['fr', 'en-gb']} );

If the script is not being run in a CGI environment, perhaps to debug it, the
locale is used via the LANG environment variable.

## preferred\_language

Same as language().

## name

Synonym for language, for compatibility with Local::Object::Language

## sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom', or 'Unknown' if
it can't be determined.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, sublanguage() will return undef.

## language\_code\_alpha2

Gives the two-character representation of the supported language, e.g. 'en'
when you've asked for en-gb.

If none of the requested languages is included within the supported lists,
language\_code\_alpha2() returns undef.

## code\_alpha2

Synonym for language\_code\_alpha2, kept for historical reasons.

## sublanguage\_code\_alpha2

Gives the two-character representation of the supported language, e.g. 'gb'
when you've asked for en-gb, or undef.

## requested\_language

Gives a human-readable rendition of what language the user asked for whether
or not it is supported.

Returns the sublanguage (if appropriate) in parentheses,
e.g. "English (United Kingdom)"

## country

Returns the two-character country code of the remote end in lowercase.

If [IP::Country](https://metacpan.org/pod/IP%3A%3ACountry), [Geo::IPfree](https://metacpan.org/pod/Geo%3A%3AIPfree) or [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) is installed,
CGI::Lingua will make use of that, otherwise, it will do a Whois lookup.
If you do not have any of those installed I recommend you use the
caching capability of CGI::Lingua.

## locale

HTTP doesn't have a way of transmitting a browser's localisation information
which would be useful for default currency, date formatting, etc.

This method attempts to detect the information, but it is a best guess
and is not 100% reliable.  But it's better than nothing ;-)

Returns a [Locale::Object::Country](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ACountry) object.

To be clear, if you're in the US and request the language in Spanish,
and the site supports it, language() will return 'Spanish', and locale() will
try to return the Locale::Object::Country for the US.

## time\_zone

Returns the timezone of the web client.

If [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) is installed,
CGI::Lingua will make use of that, otherwise it will use ip-api.com

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to the author.
This module is provided as-is without any warranty.

If HTTP\_ACCEPT\_LANGUAGE is 3 characters, e.g., es-419,
sublanguage() returns undef.

Please report any bugs or feature requests to `bug-cgi-lingua at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Uses [I18N::Acceptlanguage](https://metacpan.org/pod/I18N%3A%3AAcceptlanguage) to find the highest priority accepted language.
This means that if you support languages at a lower priority, it may be missed.

# SEE ALSO

- [HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect)
- [I18N::AcceptLangauge](https://metacpan.org/pod/I18N%3A%3AAcceptLangauge)
- [Locale::Country](https://metacpan.org/pod/Locale%3A%3ACountry)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc CGI::Lingua

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/CGI-Lingua](https://metacpan.org/release/CGI-Lingua)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua](https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua)

- CPANTS

    [http://cpants.cpanauthors.org/dist/CGI-Lingua](http://cpants.cpanauthors.org/dist/CGI-Lingua)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=CGI-Lingua](http://matrix.cpantesters.org/?dist=CGI-Lingua)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=CGI::Lingua](http://deps.cpantesters.org/?module=CGI::Lingua)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2010-2025 Nigel Horne.

This program is released under the following licence: GPL2
