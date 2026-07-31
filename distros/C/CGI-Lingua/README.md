CGI-Lingua
==========

[![Appveyor Status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/cgi-lingua)
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/CGI-Lingua/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/CGI-Lingua?branch=master)
[![CPAN](https://img.shields.io/cpan/v/CGI-Lingua.svg)](http://search.cpan.org/~nhorne/CGI-Lingua/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/cgi-lingua/test.yml?branch=master)
![Perl Version](https://img.shields.io/badge/perl-5.10+-blue)
[![Travis Status](https://travis-ci.org/nigelhorne/CGI-Lingua.svg?branch=master)](https://travis-ci.org/nigelhorne/CGI-Lingua)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://x.com/intent/tweet?text=Information+about+the+CGI+Environment+#perl+#CGI&url=https://github.com/nigelhorne/cgi-lingua&via=nigelhorne)

# NAME

CGI::Lingua - Create a multilingual web page

# VERSION

Version 0.84

# SYNOPSIS

CGI::Lingua is a powerful module for multilingual web applications
offering extensive language/country detection strategies.

No longer does your website need to be in English only.
CGI::Lingua provides a simple basis to determine which language to display a website.
The website tells CGI::Lingua which languages it supports.
Based on that list CGI::Lingua tells the application which language the user would like to use.

    use CGI::Lingua;
    # ...
    my $l = CGI::Lingua->new(['en', 'fr', 'en-gb', 'en-us']);
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

### API SPECIFICATION

    Input:
      supported  => ArrayRef[Str] | Str   # required; RFC-1766 language codes
      cache      => Object                # optional; CHI-compatible (get/set)
      config_file => Str                  # optional; YAML/XML/INI config path
      logger     => Object                # optional; must implement warn/info/error
      info       => Object                # optional; CGI::Info-compatible
      data       => Any                   # optional; forwarded to I18N::AcceptLanguage
      dont_use_ip => Bool                 # optional; disable IP-based fallback
      syslog     => Bool | HashRef        # optional; Sys::Syslog integration
      debug      => Bool                  # optional; enable debug logging

    Returns: CGI::Lingua blessed hashref, or a clone when called on an object.

### EXAMPLE

    # Array-ref of supported codes (most common form)
    my $l = CGI::Lingua->new({ supported => ['en', 'fr', 'de'] });

    # Single scalar code
    my $l = CGI::Lingua->new(supported => 'en');

    # With cache, logger, and CGI::Info object
    use CHI;
    my $cache = CHI->new(driver => 'File', root_dir => '/tmp/lingua-cache');
    my $l = CGI::Lingua->new({
        supported => ['en', 'fr'],
        cache     => $cache,
        logger    => $my_log_object,
    });

    # Clone an existing object with different supported list
    my $clone = $l->new(supported => ['de']);

### MESSAGES

    "You must give a list of supported languages"  - no 'supported' key provided
    "List of supported languages must be an array ref" - supported is wrong ref type
    "Supported languages must be the short code"  - string too short or too long
    "Logger must be a blessed object with warn/info/error methods" - bad logger arg

### PSEUDOCODE

    1. Normalise args via Params::Get and Object::Configure
    2. Validate logger (must be blessed with warn/info/error) if provided
    3. Validate supported (required, string or arrayref)
    4. If cache and REMOTE_ADDR set, attempt to thaw a previously stored state
    5. Bless and return fresh object with sentinel flags set to GEO_UNKNOWN

## language

Tells the CGI application in what language to display its messages.
The language is the natural name e.g. 'English' or 'Japanese'.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, language() will return 'English'.

If none of the requested languages is included within the supported lists,
language() returns 'Unknown'.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'fr,en;q=0.9';
    my $l = CGI::Lingua->new(supported => ['en', 'fr']);
    print $l->language();   # "French"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str - human-readable language name, or 'Unknown'

## preferred\_language

Same as language().

## name

Synonym for language, for compatibility with Locale::Object::Language.

## sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom', or undef if
it can't be determined.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->sublanguage();   # "United Kingdom"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str | undef

## language\_code\_alpha2

Gives the two-character representation of the supported language, e.g. 'en'
when you've asked for en-gb.

If none of the requested languages is included within the supported lists,
language\_code\_alpha2() returns undef.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->language_code_alpha2();   # "en"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 chars) | undef

## code\_alpha2

Synonym for language\_code\_alpha2, kept for historical reasons.

## sublanguage\_code\_alpha2

Gives the two-character representation of the supported language, e.g. 'gb'
when you've asked for en-gb, or undef.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->sublanguage_code_alpha2();   # "gb"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 chars) | undef

## requested\_language

Gives a human-readable rendition of what language the user asked for whether
or not it is supported.

Returns the sublanguage (if appropriate) in parentheses,
e.g. "English (United Kingdom)"

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->requested_language();   # "English (United Kingdom)"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str - e.g. "English (United Kingdom)" or "Unknown"

## country

Returns the two-character country code of the remote end in lowercase.

If [IP::Country](https://metacpan.org/pod/IP%3A%3ACountry), [Geo::IPfree](https://metacpan.org/pod/Geo%3A%3AIPfree) or [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) is installed,
CGI::Lingua will make use of that, otherwise, it will do a Whois lookup.
If you do not have any of those installed I recommend you use the
caching capability of CGI::Lingua.

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 lowercase chars) | undef
      'Unknown' is only returned in the Baidu-EU special case via _handle_eu_country.

### EXAMPLE

    # With mod_geoip (fastest - no IP lookup at all):
    local $ENV{GEOIP_COUNTRY_CODE} = 'DE';
    print $l->country();   # "de"

    # With REMOTE_ADDR and IP::Country installed:
    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    print $l->country();   # "us" (depends on geo database)

### MESSAGES

    "GEOIP_COUNTRY_CODE contains an invalid country code; ignoring"
    "HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring"
    "X.X.X.X isn't a valid IP address"
    "Can't determine country from LAN connection X"
    "Can't determine country from loopback connection X"
    "cache contains a numeric country: N"
    "IP matches to a numeric country"

### PSEUDOCODE

    1. Return cached _country if set
    2. Check GEOIP_COUNTRY_CODE env var (mod_geoip); validate /^[A-Z]{2}$/
    3. Check HTTP_CF_IPCOUNTRY (Cloudflare); skip 'XX'; validate /^[A-Z]{2}$/
    4. Untaint and validate REMOTE_ADDR; return undef if absent or invalid
    5. Skip private and loopback IPs (return undef)
    6. Check CHI cache; return cached value if present
    7. Try IP::Country::Fast (local DB, fastest)
    8. Try Geo::IP (local DB)
    9. Try Geo::IPfree (local DB, skip $BROKEN_GEOIPFREE)
    10. Try geoplugin.net JSON API (LWP::Simple::WithCache or LWP::Simple)
    11. Last resort: Net::Whois::IP then Net::Whois::IANA
    12. Sanitise: discard numeric, normalise HK->CN, handle EU special case
    13. Store in CHI cache; return result

## locale

HTTP doesn't have a way of transmitting a browser's localisation information
which would be useful for default currency, date formatting, etc.

This method attempts to detect the information, but it is a best guess
and is not 100% reliable.  But it's better than nothing ;-)

Returns a [Locale::Object::Country](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ACountry) object.

### EXAMPLE

    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    my $locale = $l->locale();
    if (defined $locale) {
        print $locale->name();          # e.g. "United States"
        print $locale->currency_code(); # e.g. "USD"
    }

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Locale::Object::Country | undef

### PSEUDOCODE

    1. Return cached _locale immediately if already computed
    2. Parse HTTP_USER_AGENT parenthetical for xx-YY language tag
    3. Try HTTP::BrowserDetect on the full User-Agent string
    4. Fall back to country() IP lookup
    5. Fall back to GEOIP_COUNTRY_CODE env var (ISO 3166-1 validated)
    6. Return undef if all strategies fail

## time\_zone

Returns the timezone of the web client.

If [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) is installed,
CGI::Lingua will make use of that, otherwise it will use [ip-api.com](https://metacpan.org/pod/ip-api.com)

### API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (IANA timezone name) | undef

### EXAMPLE

    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    my $tz = $l->time_zone();
    print $tz // 'unknown';   # e.g. "America/New_York"

### MESSAGES

    "Couldn't determine the timezone"
    "LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com"
      Returns undef rather than croaking; install either LWP variant to enable ip-api lookups.

### PSEUDOCODE

    1. Return cached _timezone immediately if already computed
    2. If REMOTE_ADDR is set:
       a. Untaint and validate the IP
       b. Try Geo::IP->time_zone() (local DB)
       c. Try LWP::Simple::WithCache + JSON::Parse against ip-api.com
       d. Fall back to LWP::Simple + JSON::Parse against ip-api.com
       e. Warn and return undef if neither LWP variant is installed
    3. If REMOTE_ADDR is absent (local/CLI mode):
       a. Read /etc/timezone if readable
       b. Fall back to DateTime::TimeZone::Local->TimeZone()->name()
    4. Warn "Couldn't determine the timezone" and return undef if all fail

## is\_rtl

Returns true (1) if the negotiated language is written right-to-left, false (0)
otherwise.  Covers Arabic, Hebrew, Persian, Urdu, Yiddish, Dhivehi, Pashto,
Sindhi, Uyghur, and Kurdish.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ar';
    my $l = CGI::Lingua->new(supported => ['ar', 'en']);
    print $l->is_rtl();   # 1

### API SPECIFICATION

    Input:  none beyond $self
    Returns: 1 | 0

## text\_direction

Returns `'rtl'` or `'ltr'` for the negotiated language, suitable for direct
use as an HTML `dir` attribute value.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'he';
    my $l = CGI::Lingua->new(supported => ['he', 'en']);
    print qq(<html dir="} . $l->text_direction() . qq(">);   # dir="rtl"

### API SPECIFICATION

    Input:  none beyond $self
    Returns: 'rtl' | 'ltr'

## plural\_category

Returns the CLDR plural category for the integer `$n` in the negotiated
language.  The returned string is one of `'zero'`, `'one'`, `'two'`,
`'few'`, `'many'`, or `'other'`.

Rules are embedded for ~70 languages including Arabic (6 forms), Slavic
languages (3-4 forms), Celtic languages (up to 6 forms), and Hebrew, Maltese,
Romanian, Latvian, Lithuanian, and Slovenian.  Languages not in the table fall
back to the English rule (n == 1 => `'one'`, else `'other'`).

For fractional numbers or full CLDR v42+ accuracy, use `Locale::CLDR`.

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ru';
    my $l = CGI::Lingua->new(supported => ['ru']);
    print $l->plural_category(1);    # "one"
    print $l->plural_category(3);    # "few"
    print $l->plural_category(11);   # "many"

### API SPECIFICATION

    Input:  $n - non-negative integer (fractional values are truncated)
    Returns: Str - one of zero/one/two/few/many/other

## translation\_file

Returns the filesystem path to the best matching translation file for the
negotiated language in the given directory.

The lookup tries (in order):

- 1. `$dir/$lang-$sublang.$ext`  (e.g. `en-gb.json`)
- 2. `$dir/$lang.$ext`           (e.g. `en.json`)

Returns `undef` if no matching file exists.

### API SPECIFICATION

    Input:
      $dir - Str   path to the directory containing translation files
      $ext - Str   file extension without leading dot (default: 'json')
    Returns: Str (absolute or relative path) | undef

### EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb', 'en']);
    my $path = $l->translation_file('/var/www/i18n');
    # Returns '/var/www/i18n/en-gb.json' if it exists,
    # then '/var/www/i18n/en.json', or undef.

    # Custom extension:
    my $path = $l->translation_file('/var/www/i18n', 'po');

### MESSAGES

    (none - returns undef silently when no file is found)

# LIMITATIONS

- **is\_rtl() covers primary-script RTL languages only**

    `is_rtl()` returns true for the 10 ISO 639-1 codes whose overwhelmingly
    dominant script is right-to-left.  Languages with script variants (e.g.
    Azerbaijani `az`, which uses Latin in modern Azerbaijan but Arabic in Iran)
    are treated as LTR.  If you serve content in multiple scripts of the same
    language, inspect the sublanguage or Accept-Language header directly.

- **plural\_category() uses embedded CLDR rules, not Locale::CLDR**

    The embedded rules cover ~70 languages and truncate fractional `$n` to an
    integer.  For full CLDR v42 accuracy (including fractional forms and
    languages not in the table) install and use `Locale::CLDR` directly.

- **Logger must be a blessed object**

    The `logger` parameter is documented as accepting a code ref, array ref, or
    filename, but the current implementation calls `$logger->$level()` and will
    die on non-blessed values.  Wrap alternative logger types in a
    `Log::Abstraction` instance before passing them to `new()`.

- **es-419 sublanguage returns undef**

    Three-part regional codes such as `es-419` (Latin American Spanish) do not
    resolve to a `sublanguage()` value because ISO 3166-1 does not define '419'.
    This is a known limitation of the Locale::Object layer.

- **Whois lookups are slow and unreliable**

    Without `IP::Country`, `Geo::IP`, or `Geo::IPfree` installed, `country()`
    falls back to Whois queries against live RIPE/ARIN/IANA servers.  These can
    time out under load.  Install at least one local geo-database module and enable
    the CHI cache to avoid this.

- **Private methods are accessible from outside the package**

    The `_*` methods use the naming convention for privacy but Perl does not enforce
    it.  `Sub::Private` or `Sub::Protected` should be added once all white-box
    tests (`t/function.t`, `t/extended_tests.t`) are updated to use the public API
    exclusively.

- **IPv4-mapped IPv6 addresses are normalised to IPv4**

    `REMOTE_ADDR` values in the form `::ffff:a.b.c.d` (RFC 4291 section 2.5.5)
    are silently rewritten to the embedded `a.b.c.d` IPv4 address before any
    geo-lookup.  This is correct for country detection purposes but means the raw
    address string is not preserved in cache keys or log messages.

- **EU country code is irresolvable (with one exception)**

    IP addresses that Whois reports as country `EU` are mapped to `'Unknown'`
    unless they fall within Baidu's known subnet (RT-86809).  There is no ISO
    3166-1 country code for the European Union.

- **country() does not cache undef results**

    When `country()` cannot determine a country (private IPs, loopback,
    unresolvable addresses), it returns `undef` without storing the result.  A
    second call on the same object repeats the full validation pipeline.  This is
    intentional: `country()` reads `REMOTE_ADDR` at call time rather than at
    construction time, so caching `undef` would return a wrong answer if
    `REMOTE_ADDR` changes between calls.  In practice this is rarely a problem
    because `country()` is called once per request and CGI applications typically
    create a fresh object per request.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to the author.

If `HTTP_ACCEPT_LANGUAGE` contains a sub-tag with a 3-digit UN M.49 region
code (e.g. `es-419` for Latin American Spanish), `sublanguage()` returns
`undef` because ISO 3166-1 does not define numeric codes.

Please report any bugs or feature requests to `bug-cgi-lingua at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Uses [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage) to find the highest priority accepted language.
This means that if you support languages at a lower priority, it may be missed.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/CGI-Lingua/coverage/)
- VWF - Versatile Web Framework [https://github.com/nigelhorne/vwf](https://github.com/nigelhorne/vwf)
- [HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect)
- [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage)
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

# FORMAL SPECIFICATION

## new

    new : Class × Params → CGI::Lingua
    ∀ p : Params • p.supported ≠ ∅ ⟹ result.language ∈ (p.supported ∪ {'Unknown'})

## language

    language : CGI::Lingua → Str
    result ∈ {name(l) | l ∈ supported} ∪ {'Unknown'}

## sublanguage

    sublanguage : CGI::Lingua -> Str | undef
    result = country_name(sublanguage_code_alpha2(self))
             when sublanguage_code_alpha2(self) is defined,
             undef otherwise

## language\_code\_alpha2

    language_code_alpha2 : CGI::Lingua -> Str(2) | undef
    result = base_code(matched_supported_entry)
             when a supported language was matched, undef otherwise

## sublanguage\_code\_alpha2

    sublanguage_code_alpha2 : CGI::Lingua -> Str(2) | undef
    result = variety_code(matched_supported_entry) | undef

## requested\_language

    requested_language : CGI::Lingua -> Str
    result = name(base) + " (" + name(variety) + ")"
             when variety is known,
           = name(base)   when no variety,
           = 'Unknown'    when no language detected

## country

    country : CGI::Lingua -> Str(2,lowercase) | undef
    -- 'Unknown' returned only in the EU/Baidu special case
    result = lc(code) where code satisfies ISO 3166-1 alpha-2
             | undef when IP is private, loopback, or unresolvable

## locale

    locale : CGI::Lingua -> Locale::Object::Country | undef
    -- Best-guess detection; not guaranteed accurate.
    result = first defined value from:
        1. UA parenthetical language tag
        2. HTTP::BrowserDetect country
        3. country() IP lookup
        4. GEOIP_COUNTRY_CODE env var

## time\_zone

    time_zone : CGI::Lingua -> Str | undef
    result is an IANA timezone name (e.g. 'Europe/London') or undef

## is\_rtl

    is_rtl : CGI::Lingua → Bool
    is_rtl(s) ≙ language_code_alpha2(s) ∈ RTL_LANGS

## text\_direction

    text_direction : CGI::Lingua → {'rtl', 'ltr'}
    text_direction(s) ≙ is_rtl(s) ? 'rtl' : 'ltr'

## plural\_category

    plural_category : CGI::Lingua x N -> PluralCategory
    plural_category(s, n) = PLURAL_RULES[language_code_alpha2(s)](trunc(n))
    -- Falls back to English rule (n=1 -> 'one'; else 'other')
    -- when language_code_alpha2(s) is undef or not in the rules table.

## translation\_file

    translation_file : CGI::Lingua × Path × Ext → Path | undef
    translation_file(s, d, e) ≙
      first p ∈ candidates(s) • ∃ file d/p.e
      where candidates(s) = [lang(s)-sublang(s), lang(s)] \ {undef}

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
