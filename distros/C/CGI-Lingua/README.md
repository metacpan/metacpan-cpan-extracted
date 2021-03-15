# NAME

CGI::Lingua - Create a multilingual web page

# VERSION

Version 0.63

# SYNOPSIS

No longer does your website need to be in English only.
CGI::Lingua provides a simple basis to determine which language to display a
website. The website tells CGI::Lingua which languages it supports. Based on
that list CGI::Lingua tells the application which language the user would like
to use.

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
    my $l = CGI::Lingua->new({ supported => ['en', 'fr'], cache => $cache });

# SUBROUTINES/METHODS

## new

Creates a CGI::Lingua object.

Takes one mandatory parameter: a list of languages, in RFC-1766 format,
that the website supports.
Language codes are of the form primary-code \[ - country-code \] e.g.
'en', 'en-gb' for English and British English respectively.

For a list of primary-codes refer to ISO-639 (e.g. 'en' for English).
For a list of country-codes refer to ISO-3166 (e.g. 'gb' for United Kingdom).

    # We support English, French, British and American English, in that order
    my $l = CGI::Lingua(supported => ['en', 'fr', 'en-gb', 'en-us']);

Takes optional parameter cache, an object which is used to cache country
lookups.
This cache object is an object that understands get() and set() messages,
such as a [CHI](https://metacpan.org/pod/CHI) object.

Takes an optional parameter syslog, to log messages to
[Sys::Syslog](https://metacpan.org/pod/Sys%3A%3ASyslog).
It can be a boolean to enable/disable logging to syslog, or a reference
to a hash to be given to Sys::Syslog::setlogsock.

Takes optional parameter logger, an object which is used for warnings
and traces.
This logger object is an object that understands warn() and trace()
messages, such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) object.

Takes optional parameter info, an object which can be used to see if a CGI
parameter is set, for example an [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object.

Since emitting warnings from a CGI class can result in messages being lost (you
may forget to look in your server's log), or appearing to the client in
amongst HTML causing invalid HTML, it is recommended either either syslog
or logger (or both) are set.
If neither is given, [Carp](https://metacpan.org/pod/Carp) will be used.

Takes an optional parameter dont\_use\_ip.  By default, if none of the
requested languages is supported, CGI::Lingua->language() looks in the IP
address for the language to use.  This may be not what you want, so use this
option to disable the feature.

The optional parameter debug is passed on to [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage).

## language

Tells the CGI application what language to display its messages in.
The language is the natural name e.g. 'English' or 'Japanese'.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, language() will return 'English'.

If none of the requested languages is included within the supported lists,
language() returns 'Unknown'.

    use CGI::Lingua;
    # Site supports English and British English
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'en-gb']);

    # If the browser requests 'en-us' , then language will be 'English' and
    # sublanguage will be undefined because we weren't able to satisfy the
    # request

    # Site supports British English only
    my $l = CGI::Lingua->new({supported => ['fr', 'en-gb']});

    # If the browser requests 'en-us' , then language will be 'English' and
    # sublanguage will also be undefined, which may seem strange, but it
    # ensures that sites behave sensibly.

If the script is not being run in a CGI environment, perhaps to debug it, the
locale is used via the LANG environment variable.

## name

Synonym for language, for compatibility with Local::Object::Language

## sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom', or 'Unknown' if
it can't be determined.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, sublanguage() will return undef.

## language\_code\_alpha2

Gives the two character representation of the supported language, e.g. 'en'
when you've asked for en-gb.

If none of the requested languages is included within the supported lists,
language\_code\_alpha2() returns undef.

## code\_alpha2

Synonym for language\_code\_alpha2, kept for historical reasons.

## sublanguage\_code\_alpha2

Gives the two character representation of the supported language, e.g. 'gb'
when you've asked for en-gb, or undef.

## requested\_language

Gives a human readable rendition of what language the user asked for whether
or not it is supported.

## country

Returns the two character country code of the remote end in lower case.

If [IP::Country](https://metacpan.org/pod/IP%3A%3ACountry), [Geo::IPfree](https://metacpan.org/pod/Geo%3A%3AIPfree) or [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) is installed,
CGI::Lingua will make use of that, otherwise it will do a Whois lookup.
If you do not have any of those installed I recommend you make use of the
caching capability of CGI::Lingua.

## locale

HTTP doesn't have a way of transmitting a browser's localisation information
which would be useful for default currency, date formatting etc.

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

If HTTP\_ACCEPT\_LANGUAGE is 3 characters, e.g., es-419,
sublanguage() returns undef.

Please report any bugs or feature requests to `bug-cgi-lingua at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[Locale::Country](https://metacpan.org/pod/Locale%3A%3ACountry)
[HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Lingua

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua](http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua)

- CPAN Ratings

    [http://cpanratings.perl.org/d/CGI-Lingua](http://cpanratings.perl.org/d/CGI-Lingua)

- Search CPAN

    [http://search.cpan.org/dist/CGI-Lingua/](http://search.cpan.org/dist/CGI-Lingua/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2010-2021 Nigel Horne.

This program is released under the following licence: GPL2
