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

## Name

CGI::Lingua - Create a multilingual web page

## Version

Version 0.87

## Synopsis

Your website tells CGI::Lingua which languages it can show.
CGI::Lingua looks at what the visitor's web browser asks for,
and tells your website which of its languages to use.

### Pick a Language for the Page

```perl
use CGI::Lingua;

# The site has pages in English and French
my $l = CGI::Lingua->new(supported => ['en', 'fr']);

my $language = $l->language();    # 'English', 'French' or 'Unknown'
if($language eq 'English') {
    print "<p>Hello</p>\n";
} elsif($language eq 'French') {
    print "<p>Bonjour</p>\n";
} else {
    # The visitor wants a language that the site does not have
    my $wanted = $l->requested_language();    # e.g. 'German'
    print "<p>Sorry, this page is not available in $wanted.</p>\n";
}
```

### Use the Short Code to Choose a File or Template

```perl
my $l = CGI::Lingua->new(supported => ['en-gb', 'en-us', 'fr']);

my $code    = $l->language_code_alpha2() // 'en';    # 'en' or 'fr'
my $variant = $l->sublanguage_code_alpha2();         # 'gb', 'us' or undef
my $template = defined($variant) ? "$code-$variant.tmpl" : "$code.tmpl";
```

### Show Different Content for Different Countries

```perl
my $l = CGI::Lingua->new(supported => ['en']);

my $country = $l->country() // '';    # e.g. 'us', 'ca', 'gb'
if($country eq 'us') {
    print "Call us on 1-800-555-0100\n";
} elsif($country eq 'ca') {
    print "Call us on 1-888-555-0100\n";
} else {
    print "Email us at help\@example.com\n";
}
```

### Make It Faster With a Cache

Finding the country of an IP address can be slow.
Give CGI::Lingua a [CHI](https://metacpan.org/pod/CHI) cache so that the work is only done once
for each visitor.

```perl
use CHI;
use CGI::Lingua;

my $cache = CHI->new(
    driver    => 'File',
    root_dir  => '/var/cache/myapp',
    namespace => 'CGI::Lingua',
);
my $l = CGI::Lingua->new(supported => ['en', 'fr'], cache => $cache);
```

### Let the Visitor Choose With a "Lang" Parameter

If you pass a [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object, a `lang=fr` parameter in the URL
is used before the browser's settings.

```perl
use CGI::Info;
use CGI::Lingua;

my $info = CGI::Info->new();
my $l = CGI::Lingua->new(supported => ['en', 'fr', 'de'], info => $info);
print $l->language();    # 'German' for https://example.com/page?lang=de
```

### Set the HTML "Lang" and "Dir" Attributes

```perl
my $l = CGI::Lingua->new(supported => ['en', 'ar', 'he']);
my $code = $l->language_code_alpha2() // 'en';
printf qq{<html lang="%s" dir="%s">\n}, $code, $l->text_direction();
# <html lang="ar" dir="rtl"> for an Arabic-speaking visitor
```

### Choose the Right Plural Form

```perl
my $l = CGI::Lingua->new(supported => ['en', 'ru']);
my %messages = (
    one  => '%d file',
    few  => '%d files (few)',
    many => '%d files (many)',
    other => '%d files',
);
my $n = 3;
printf $messages{$l->plural_category($n)} . "\n", $n;
```

### Load a Translation File

```perl
# Looks for /var/www/i18n/en-gb.json, then /var/www/i18n/en.json
my $l = CGI::Lingua->new(supported => ['en-gb', 'en', 'fr']);
if(my $file = $l->translation_file('/var/www/i18n')) {
    # read and use $file
}
```

### Guess the Visitor's Time Zone and Locale

```perl
my $l = CGI::Lingua->new(supported => ['en']);
my $tz = $l->time_zone() // 'UTC';     # e.g. 'America/New_York'
if(my $locale = $l->locale()) {         # a Locale::Object::Country
    print 'Currency: ', $locale->currency()->code(), "\n";
}
```

### Do Not Guess From the IP Address

```perl
# Only use what the browser asks for; never look up the IP address
my $l = CGI::Lingua->new(supported => ['en', 'fr'], dont_use_ip => 1);
```

## Description

This section explains, in simple steps, how CGI::Lingua finds the answer.

### Finding the Language

When you first call a language method (for example ["language"](#language)),
CGI::Lingua looks for the visitor's language in this order:

- 1. The `lang` parameter of the [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object, if you gave one
to ["new"](#new) with `info`.
- 2. The `HTTP_ACCEPT_LANGUAGE` environment variable.
The web server sets this from the browser's `Accept-Language` header,
for example `fr-CA,fr;q=0.9,en;q=0.8`.
Languages with a higher `q` value are tried first.
A language with `q=0` means "not acceptable" (RFC 7231) and is never chosen.
Some browsers still send the old tag `en-uk`; it is treated as `en-gb`
(the code for the United Kingdom is `gb`), with a warning.
- 3. The `LANG` environment variable.
This is used when you run the program on the command line,
for example `LANG=fr_FR.UTF-8`.
- 4. The visitor's country (see below).
CGI::Lingua uses the official language of that country.
This step is skipped when you give `dont_use_ip` to ["new"](#new).

It then compares the answer with your `supported` list.
If a visitor asks for `en-us` and you only support `en-gb`,
CGI::Lingua still chooses English, because the base language is the same.
If nothing matches, ["language"](#language) returns the string `'Unknown'`.

### Finding the Country

["country"](#country) tries these sources in order, and stops at the first answer:

- 1. `GEOIP_COUNTRY_CODE` (set by Apache's mod\_geoip).
- 2. `HTTP_CF_IPCOUNTRY` (set by Cloudflare).
- 3. A local database: [IP::Country](https://metacpan.org/pod/IP%3A%3ACountry), then [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP), then [Geo::IPfree](https://metacpan.org/pod/Geo%3A%3AIPfree),
if they are installed.
- 4. The geoplugin.net web service.
- 5. A Whois look-up ([Net::Whois::IP](https://metacpan.org/pod/Net%3A%3AWhois%3A%3AIP), then [Net::Whois::IANA](https://metacpan.org/pod/Net%3A%3AWhois%3A%3AIANA)).

Steps 3 to 5 use the visitor's IP address from `REMOTE_ADDR`.
Private addresses (such as `192.168.1.1`) and loopback addresses
(such as `127.0.0.1`) have no country, so the answer is `undef`.

### Remembering Answers

Each object remembers its answers, so a second call to the same method is fast.
If you give a `cache` to ["new"](#new), answers are also stored in the cache when the
object is destroyed. The next object created for the same IP address, the same
requested language and the same `supported` list starts with those answers.

## Subroutines/Methods

### New

Creates a CGI::Lingua object.

You must tell it which languages your website supports, with `supported`.
Each language is a short code, such as `'en'` (English),
`'fr'` (French) or `'en-gb'` (British English).

You can give the arguments as a list, as a hash reference,
as a single array reference (the supported list), or as a single string
(one supported language):

```perl
CGI::Lingua->new(supported => ['en', 'fr']);
CGI::Lingua->new({ supported => ['en', 'fr'] });
CGI::Lingua->new(['en', 'fr']);
CGI::Lingua->new('en');
```

The arguments are:

- `supported` (required)

    The languages your website supports: one short code (a string of 2 to 5
    characters) or a reference to an array of language tags.
    `supported_languages` is another name for the same argument.

    Each entry in the array must look like a language tag: two or three letters,
    optionally followed by subtags, such as `'en'`, `'en-gb'`, `'en_gb'`,
    `'es-419'` or `'zh-Hant'`. Other entries (`undef`, references, `''`, or
    words such as `'english'`) could never match, so they are dropped with the
    warning `"Ignoring '...' in the supported list: not a language code"`.
    An empty list is allowed; ["language"](#language) then always returns `'Unknown'`.

- `cache` (optional)

    An object with `get()`, `set()` and `remove()` methods, such as a [CHI](https://metacpan.org/pod/CHI) object.
    CGI::Lingua stores its answers here so that later requests are faster.
    If a call to the cache dies (for example a full disc, an unreachable server,
    or a [CHI](https://metacpan.org/pod/CHI) object created with `on_get_error => 'die'`), CGI::Lingua
    warns `"Cache get failed: ..."` (or `set` / `remove`) and carries on as if
    the value was not cached. Any method that uses the cache can give this warning.

    Everything read back from the cache is checked before it is used, because a
    cache can be shared with, or written by, other programs. A value that does not
    have the shape CGI::Lingua stores (for example `gb<script>` as a country, or
    a hash where a language name should be) is removed and warned about with
    `"Discarding malformed cache entry for ..."`, and the answer is worked out
    again.

- `config_file` (optional)

    The path to a configuration file. It is read by [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).
    Values in this file **replace** the arguments that you give to `new()`
    (see ["COMMON PITFALLS"](#common-pitfalls)).

- `logger` (optional)

    Where to send messages. This can be an object with `warn()`, `info()` and
    `error()` methods, or any value that [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) accepts
    (for example an array reference, which collects the messages).
    It is always changed into a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object.
    Without a logger, warnings go to [Carp](https://metacpan.org/pod/Carp).

- `info` (optional)

    A [CGI::Info](https://metacpan.org/pod/CGI%3A%3AInfo) object (or any object with a `lang()` method).
    A `lang` parameter in the request is then used before the browser's
    settings. The parameter comes from the visitor, so it is checked like the
    `Accept-Language` header (see ["ENCODING"](#encoding)); a value that fails is ignored with
    the warning `"lang parameter contains invalid characters; ignoring"`.

- `dont_use_ip` (optional, default false)

    When true, CGI::Lingua never guesses the language from the visitor's
    IP address.

- `syslog` (optional)

    Passed on to the logging configuration.

- `debug` (optional, default false)

    When true, [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage) prints debug information.

If you call `new()` on an existing object, you get a copy of that object.
The arguments you give replace the values in the copy.
The copy also keeps any answers that the original has already worked out
(see ["COMMON PITFALLS"](#common-pitfalls)).

#### Api Specification

##### Input

```perl
{
    supported           => { type => 'string|arrayref', optional => 0 },
    supported_languages => { type => 'string|arrayref', optional => 1 },
    cache               => { type => 'object', can => ['get', 'set'], optional => 1 },
    config_file         => { type => 'string', optional => 1 },
    logger              => { type => 'object|arrayref|hashref|string', optional => 1 },
    info                => { type => 'object', can => 'lang', optional => 1 },
    dont_use_ip         => { type => 'boolean', optional => 1 },
    syslog              => { type => 'boolean|hashref', optional => 1 },
    debug               => { type => 'boolean', optional => 1 },
}
```

You must give `supported` or its other name `supported_languages`.
A string must be 2 to 5 characters long.

##### Output

```perl
{
    type => 'object',
    isa  => 'CGI::Lingua',
}
```

#### Example

```perl
# The most common form: a list of supported codes
my $l = CGI::Lingua->new(supported => ['en', 'fr', 'de']);

# One supported language
my $l = CGI::Lingua->new(supported => 'en');

# With a cache, a logger and a CGI::Info object
use CHI;
use CGI::Info;
my $l = CGI::Lingua->new({
    supported => ['en', 'fr'],
    cache     => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
    logger    => \my @messages,
    info      => CGI::Info->new(),
});
```

#### Messages

`new()` dies (with ["croak" in Carp](https://metacpan.org/pod/Carp#croak)) with one of these messages:

```perl
"You must give a list of supported languages"
    - supported is missing, undef, 0 or the empty string
"List of supported languages must be an array ref"
    - supported is a reference, but not to an array
"Supported languages must be the short code"
    - supported is a string shorter than 2 or longer than 5 characters
"Logger must be a blessed object with warn/info/error methods"
    - logger is an object that is missing one of these methods
"CGI::Lingua use ->new() not ::new() to instantiate"
    - new() was called as a function, with arguments
"info must be an object with a lang() method"
    - info is not an object, or has neither lang() nor AUTOLOAD
```

It warns, and carries on, with:

```
"Ignoring '...' in the supported list: not a language code"
    - an entry of the supported list is not a language tag
"Cache get failed: ..."
    - the cache died while looking up saved answers
"Discarding malformed cache entry for ..."
    - the saved answers were not in the shape CGI::Lingua writes
```

#### Pseudocode

```
1. Read the arguments with Params::Get
2. If called on an object, return a copy with the new arguments on top
3. If logger is an object, check that it has warn, info and error
4. Merge in config_file and environment settings with Object::Configure
5. Check supported (required; string of 2-5 characters, or an arrayref)
6. If there is a cache and REMOTE_ADDR is set, try to load saved answers
   from the cache (JSON); if found, return them as an object
7. Otherwise return a new object with no answers yet
```

### Language

Returns the name of the language to show to the visitor, in English,
for example `'English'`, `'French'` or `'Japanese'`.
The language is always one of the languages in your `supported` list.

Variants are handled sensibly.
If a visitor asks for American English (`en-us`)
and your site only has British English (`en-gb`),
`language()` returns `'English'`.

If none of the languages that the visitor wants is in your `supported` list,
`language()` returns the string `'Unknown'`.
It never returns `undef`.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type => 'string',
    min  => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'fr,en;q=0.9';
my $l = CGI::Lingua->new(supported => ['en', 'fr']);
print $l->language();   # "French"

local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
my $l = CGI::Lingua->new(supported => ['en', 'fr']);
print $l->language();   # "Unknown"
```

#### Messages

The first call to ["language"](#language) (or any other language method) warns, and
ignores the value, when one of its inputs is not acceptable:

```
"lang parameter contains invalid characters; ignoring"
"HTTP_ACCEPT_LANGUAGE contains invalid characters; ignoring"
"LANG contains invalid characters; ignoring"
```

It also warns when it changes the deprecated tag `en-uk` into `en-gb`:

```
"Resetting country code to GB for ..."
```

### Preferred\_Language

Another name for ["language"](#language). It takes no arguments and returns the same value.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type => 'string',
    min  => 1,
}
```

### Name

Another name for ["language"](#language), so that a CGI::Lingua object can be used where a
[Locale::Object::Language](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ALanguage) object is expected.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type => 'string',
    min  => 1,
}
```

### Sublanguage

Returns the name of the variant (usually a country) of the chosen language,
for example `'United Kingdom'` when the chosen language is `en-gb`.

Returns `undef` when there is no variant, for example when the chosen
language is just `en`, or when no language was found.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    min      => 1,
    optional => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
my $l = CGI::Lingua->new(supported => ['en-gb']);
print $l->sublanguage();   # "United Kingdom"
```

### Language\_Code\_alpha2

Returns the two-letter code (ISO 639-1) of the chosen language,
for example `'en'` when the chosen language is `en-gb`.

Returns `undef` when none of the languages that the visitor wants is in your
`supported` list (that is, when ["language"](#language) returns `'Unknown'`).

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    min      => 2,
    max      => 2,
    optional => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
my $l = CGI::Lingua->new(supported => ['en-gb']);
print $l->language_code_alpha2();   # "en"
```

### Code\_alpha2

Another name for ["language\_code\_alpha2"](#language_code_alpha2), kept so that old programs still work.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    min      => 2,
    max      => 2,
    optional => 1,
}
```

### Sublanguage\_Code\_alpha2

Returns the two-letter code of the variant of the chosen language,
in lower case, for example `'gb'` when the chosen language is `en-gb`.

Returns `undef` when there is no variant.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    min      => 2,
    max      => 2,
    optional => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
my $l = CGI::Lingua->new(supported => ['en-gb']);
print $l->sublanguage_code_alpha2();   # "gb"
```

### Requested\_Language

Returns, in English, the language that the visitor asked for,
**whether or not your site supports it**.
Use it to tell the visitor that their language is not available.

If the visitor asked for a variant, it is shown in brackets,
for example `'English (United Kingdom)'`. A variant that is not a known
country code is shown as it was sent, for example `'English (Unknown: zz)'`.

Returns `'Unknown'` when the visitor's language cannot be found at all.
It never returns `undef`.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type => 'string',
    min  => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
my $l = CGI::Lingua->new(supported => ['en']);
print $l->language();             # "English"
print $l->requested_language();   # "English (United Kingdom)"

local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
my $l = CGI::Lingua->new(supported => ['en']);
print $l->language();             # "Unknown"
print $l->requested_language();   # "German"
```

### Country

Returns the two-letter country code (ISO 3166-1) of the visitor,
in lower case, for example `'us'`, `'gb'` or `'fr'`.

Returns `undef` when the country cannot be found, for example when
`REMOTE_ADDR` is not set, is not a valid IP address, or is a private
(`192.168.1.1`) or loopback (`127.0.0.1`) address.

In one special case it returns the string `'Unknown'`:
when a source says the address is in the European Union (`EU`),
which is not a country.

Two answers are corrected: `hk` (Hong Kong) is returned as `cn`, and a Whois
record that says `US` with the state `PR` is returned as `pr` (Puerto Rico
has its own country code; RT#131347).

See ["Finding the country"](#finding-the-country) for the order in which the sources are tried.
If you have none of [IP::Country](https://metacpan.org/pod/IP%3A%3ACountry), [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) or [Geo::IPfree](https://metacpan.org/pod/Geo%3A%3AIPfree) installed,
every look-up goes over the network, so please use a `cache` (see ["new"](#new)).

The answer is remembered, so a second call on the same object is fast.

Note that as of October 2026 geoplugin.net, one of the remote
fallbacks, no longer has a free tier: it answers with an HTTP 403 and
a "please upgrade to a paid plan" message, which contains no country
code, so the lookup falls through to Whois.
The geoplugin.net code is kept in case that changes.

Legacy MaxMind `GeoIP.dat` databases, as used by [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP), are no
longer updated (Debian's `geoip-database` package is frozen at
2019-12-24), so they can give the wrong country for addresses that
have been reallocated since then.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    matches  => qr/^(?:[a-z][a-z]|Unknown)$/,
    optional => 1,
}
```

#### Example

```perl
# Behind Apache mod_geoip: no IP look-up is needed
local $ENV{GEOIP_COUNTRY_CODE} = 'DE';
my $l = CGI::Lingua->new(supported => ['en']);
print $l->country();   # "de"

# From the IP address (the answer depends on your geo database)
local $ENV{REMOTE_ADDR} = '8.8.8.8';
my $l = CGI::Lingua->new(supported => ['en']);
print $l->country() // 'not known';   # "us"
```

#### Messages

These are warnings. `country()` does not die.

```
"GEOIP_COUNTRY_CODE contains an invalid country code; ignoring"
"HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring"
"X.X.X.X isn't a valid IP address"
"cache contains a numeric country: N"
"IP matches to a numeric country"
"geoplugin returned unparseable JSON: ..."
"Discarding malformed country code '...'"
"geoplugin lookup failed: ..."
"Cache get failed: ...", "Cache set failed: ...", "Cache remove failed: ..."
"Discarding malformed cache entry for ..."
```

These are debug messages, sent only to the logger:

```
"Can't determine country from LAN connection X"
"Can't determine country from loopback connection X"
```

#### Pseudocode

```
1. Return the remembered answer if there is one
2. Check GEOIP_COUNTRY_CODE env var (mod_geoip); validate /^[A-Z]{2}\z/
3. Check HTTP_CF_IPCOUNTRY (Cloudflare); skip 'XX'; validate /^[A-Z]{2}\z/
4. Untaint and validate REMOTE_ADDR; return undef if absent or invalid;
   change ::ffff:a.b.c.d into a.b.c.d
5. Skip private and loopback IPs (return undef)
6. Check CHI cache; return cached value if present
7. Try IP::Country::Fast (local DB, fastest)
8. Try Geo::IP (local DB)
9. Try Geo::IPfree (local DB, skip $BROKEN_GEOIPFREE)
10. Try geoplugin.net JSON API (LWP::Simple::WithCache;
    no free tier as of October 2026, so normally yields nothing)
11. Last resort: Net::Whois::IP then Net::Whois::IANA
12. Sanitise: discard numeric, normalise HK->CN, handle EU special case,
    discard anything that is not two lower-case letters
13. Store in CHI cache; return result
```

### Locale

Returns a [Locale::Object::Country](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ACountry) object for the visitor's country.
You can use it to find, for example, the currency or the country's name.

HTTP does not send a browser's local settings (such as the currency or the
date format), so this is a **best guess**. It is not always right.

It tries these, in order:

- 1. A language tag such as `en-GB` inside the `HTTP_USER_AGENT` string.
- 2. [HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect), if it is installed.
- 3. ["country"](#country).
- 4. `GEOIP_COUNTRY_CODE`.

Returns `undef` when nothing is found.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'object',
    isa      => 'Locale::Object::Country',
    optional => 1,
}
```

#### Example

```perl
local $ENV{REMOTE_ADDR} = '8.8.8.8';
my $l = CGI::Lingua->new(supported => ['en']);
if(my $locale = $l->locale()) {
    print $locale->name(), "\n";              # e.g. "United States"
    print $locale->currency()->code(), "\n";  # e.g. "USD"
}
```

#### Messages

```
"HTTP_USER_AGENT contains invalid characters or exceeds length limit; ignoring"
```

#### Pseudocode

```
1. Return the remembered answer if there is one
2. Parse HTTP_USER_AGENT parenthetical for xx-YY language tag
3. Try HTTP::BrowserDetect on the full User-Agent string
4. Fall back to country() IP lookup
5. Fall back to GEOIP_COUNTRY_CODE env var (ISO 3166-1 validated)
6. Return undef if all strategies fail
```

### Time\_Zone

Returns the visitor's time zone, as an IANA time zone name,
for example `'Europe/London'` or `'America/New_York'`.

When `REMOTE_ADDR` is set, it uses [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) if a database is installed,
and otherwise asks the ip-api.com web service (this needs
[LWP::Simple::WithCache](https://metacpan.org/pod/LWP%3A%3ASimple%3A%3AWithCache) or [LWP::Simple](https://metacpan.org/pod/LWP%3A%3ASimple), and [JSON::Parse](https://metacpan.org/pod/JSON%3A%3AParse)).

When `REMOTE_ADDR` is not set (for example on the command line),
it returns the time zone of the computer that runs the program.

Returns `undef` when the time zone cannot be found.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    matches  => qr/^[A-Za-z][A-Za-z0-9_+\-\/]*$/,
    optional => 1,
}
```

#### Example

```perl
local $ENV{REMOTE_ADDR} = '8.8.8.8';
my $l = CGI::Lingua->new(supported => ['en']);
print $l->time_zone() // 'unknown';   # e.g. "America/New_York"
```

#### Messages

These are warnings. `time_zone()` does not die.

```
"Couldn't determine the timezone"
"X.X.X.X isn't a valid IP address"
"LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com"
"JSON::Parse is absent; cannot read ip-api.com answers"
"ip-api.com returned unparseable JSON: ..."
"DateTime::TimeZone::Local failed: ..."
"Discarding malformed timezone '...'"
"ip-api.com lookup failed: ..."
```

#### Pseudocode

```
1. Return the remembered answer if there is one
2. If REMOTE_ADDR is set:
   a. Untaint and validate the IP
   b. Try Geo::IP->time_zone() (local DB)
   c. Try LWP::Simple::WithCache + JSON::Parse against ip-api.com
   d. Fall back to LWP::Simple + JSON::Parse against ip-api.com
   e. Warn and return undef if neither LWP variant, or JSON::Parse,
      is installed (the warning names the missing module)
3. If REMOTE_ADDR is absent (local/CLI mode):
   a. Read /etc/timezone if readable
   b. Fall back to DateTime::TimeZone::Local->TimeZone()->name()
4. Discard the answer if it does not look like an IANA name
5. Warn "Couldn't determine the timezone" and return undef if all fail
```

### Is\_Rtl

Returns `1` if the chosen language is written from right to left,
and `0` if it is not.

The right-to-left languages are Arabic (`ar`), Dhivehi (`dv`),
Persian (`fa`), Hebrew (`he`), Kurdish (`ku`), Pashto (`ps`),
Sindhi (`sd`), Uyghur (`ug`), Urdu (`ur`) and Yiddish (`yi`).

When no language was found, it returns `0`.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'boolean',
    memberof => [0, 1],
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ar';
my $l = CGI::Lingua->new(supported => ['ar', 'en']);
print $l->is_rtl();   # 1
```

### Text\_Direction

Returns `'rtl'` (right to left) or `'ltr'` (left to right) for the chosen
language. You can use the value directly in the HTML `dir` attribute.

When no language was found, it returns `'ltr'`.

#### Api Specification

##### Input

```
{}
```

##### Output

```perl
{
    type     => 'string',
    memberof => ['ltr', 'rtl'],
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'he';
my $l = CGI::Lingua->new(supported => ['he', 'en']);
print '<html dir="', $l->text_direction(), '">';   # <html dir="rtl">
```

### Plural\_Category($N)

Many languages use a different word form for different numbers.
English has two forms ("1 file", "2 files"); Russian has more;
Japanese has only one.

`plural_category($n)` tells you which form to use for the number `$n`
in the chosen language.
It returns one of `'zero'`, `'one'`, `'two'`, `'few'`, `'many'` or
`'other'`. These are the Unicode CLDR plural category names.

The rules for about 70 languages are built in, including Arabic (6 forms),
Slavic languages (3 or 4 forms), Celtic languages (up to 6 forms), Hebrew,
Maltese, Romanian, Latvian, Lithuanian and Slovenian.
Other languages use the English rule: `'one'` for 1, otherwise `'other'`.

When no language was found, it always returns `'other'`.

`$n` should be a whole number that is zero or more.
A number with a fractional part is cut down to a whole number first
(2.7 becomes 2).
For full CLDR rules, including fractions, use [Locale::CLDR](https://metacpan.org/pod/Locale%3A%3ACLDR).

#### Api Specification

##### Input

```perl
[
    { type => 'number', min => 0 },
]
```

##### Output

```perl
{
    type     => 'string',
    memberof => ['zero', 'one', 'two', 'few', 'many', 'other'],
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ru';
my $l = CGI::Lingua->new(supported => ['ru']);
print $l->plural_category(1);    # "one"
print $l->plural_category(3);    # "few"
print $l->plural_category(11);   # "many"
```

#### Messages

```
"plural_category: $n must be defined"
    - dies (croak) when $n is undef
```

### Translation\_File($Dir, $Ext)

Finds the translation file for the chosen language in the directory `$dir`,
and returns its path.

It tries these file names, in order, and returns the first one that is a
readable regular file:

- 1. `$dir/$lang-$sublang.$ext`  (for example `en-gb.json`)
- 2. `$dir/$lang.$ext`           (for example `en.json`)

`$ext` is the file extension. It is `'json'` if you do not give it.
You can write it with or without the dot (`'po'` or `'.po'`).

Returns `undef` when no such file exists, when no language was found,
when `$dir` is `undef`, or when `$dir` or `$ext` is unsafe (see below).
A directory, a device (such as `/dev/urandom`), a broken symbolic link or a
file you cannot read is never returned, even if it has the right name.

For safety, `$dir` must be a non-empty string (not a reference) without
`..` or a null byte, and `$ext` may only contain letters, digits and `-`.
Control characters in a rejected value are shown as `\xNN` in the warning.

#### Api Specification

##### Input

```perl
[
    { type => 'string', min => 1 },
    { type => 'string', min => 1, matches => qr/^\.?[A-Za-z0-9-]+$/, optional => 1 },
]
```

##### Output

```perl
{
    type     => 'string',
    optional => 1,
}
```

#### Example

```perl
local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
my $l = CGI::Lingua->new(supported => ['en-gb', 'en']);

my $path = $l->translation_file('/var/www/i18n');
# '/var/www/i18n/en-gb.json' if it exists,
# else '/var/www/i18n/en.json' if it exists,
# else undef

# A different extension
my $po = $l->translation_file('/var/www/i18n', 'po');
```

#### Messages

These are warnings. `translation_file()` does not die.

```
"translation_file: unsafe directory '...' rejected"
"translation_file: unsafe extension '...' rejected"
```

## Common Pitfalls

- **Configuration files and environment variables win over your arguments**

    ["new"](#new) passes its arguments to [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).
    If a configuration file (`config_file`) or an environment variable such as
    `CGI__Lingua__supported` sets a value, that value **replaces** the value you
    gave to `new()`.

    Values are replaced, not merged. If you pass `supported => ['en', 'fr']`
    and the configuration file says `supported: [de]`, the object supports only
    `de`, not `en`, `fr` and `de`.
    For nested values (hashes inside hashes) see the rules in [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

- **A copy made with `$object->new()` keeps old answers**

    When you call `new()` on an object, the copy starts with every answer that the
    original has already worked out. So if the original has already called
    ["language"](#language), the copy returns the same language,
    even if you give the copy a different `supported` list:

    ```perl
    my $l = CGI::Lingua->new(supported => ['en', 'fr']);
    print $l->language();             # "French"
    my $copy = $l->new(supported => ['en']);
    print $copy->language();          # still "French"
    ```

    Make the copy before you call any other method, or create a new object with
    `CGI::Lingua->new()`.

- **'Unknown' is not the same as undef**

    Some methods return the **string** `'Unknown'` and some return `undef`
    when they do not know the answer. `'Unknown'` is a true value in Perl,
    so `if($l->language())` is always true.

    ```
    Method                    When it does not know
    ------------------------  -----------------------------
    language()                'Unknown'  (never undef)
    requested_language()      'Unknown'  (never undef)
    sublanguage()             undef
    language_code_alpha2()    undef
    sublanguage_code_alpha2() undef
    country()                 undef  ('Unknown' for EU addresses)
    locale()                  undef
    time_zone()               undef
    translation_file()        undef
    is_rtl()                  0
    text_direction()          'ltr'
    plural_category()         'other'
    ```

    Always test with `eq 'Unknown'` or `defined()`, as the table shows.

    `undef` really is one value, even in list context, so it is safe to build a
    hash from the results:

    ```perl
    my %vars = (country => $l->country(), zone => $l->time_zone());
    # $vars{zone} is the time zone even when country() is undef
    ```

- **plural\_category() returns 'other' when there is no language**

    When no supported language was found, `plural_category(1)` returns
    `'other'`, not `'one'`. Have an `'other'` form for every message.
    `plural_category(undef)` dies.

- **`supported => 0` and `supported => ''` count as missing**

    A false value for `supported` is treated as if you did not give it,
    so `new()` dies with "You must give a list of supported languages".

- **Answers are worked out once, then remembered**

    The first call to a language method reads `%ENV` and remembers the answer.
    If you change `%ENV` afterwards, the object does not notice.
    Create a new object for each web request.

- **country() reads REMOTE\_ADDR when you call it**

    `country()` reads `$ENV{REMOTE_ADDR}` when you **call** it,
    not when you create the object. In tests, call `country()` while
    `REMOTE_ADDR` still has the value you want:

    ```perl
    {
        local $ENV{REMOTE_ADDR} = '8.8.8.8';
        my $l = CGI::Lingua->new(supported => ['en']);
        $country = $l->country();    # correct: inside the block
    }
    ```

- **A bad header is ignored completely**

    If `HTTP_ACCEPT_LANGUAGE` is longer than 256 characters, or contains a
    character that is not allowed (see ["ENCODING"](#encoding)), the whole header is ignored
    with a warning. CGI::Lingua then uses `LANG` or the IP address instead.

- **The supported list holds tags, not names**

    `supported => ['english', 'fr']` supports only French: `'english'` is not a
    language tag, so it is dropped (with a warning). Use `'en'`.

- **Language names are in English**

    ["language"](#language) returns `'French'`, not `'Francais'`, and `'German'`, not
    `'Deutsch'`. Use ["language\_code\_alpha2"](#language_code_alpha2) if you want to show the name in
    the language itself.

- **The logger you pass is replaced**

    [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) always changes `logger` into a new [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
    object, so `$l->{logger}` is not the object you passed.

- **Whole objects are only cached when REMOTE\_ADDR is set**

    The answers of an object are read from the cache in ["new"](#new), and written to it
    when the object is destroyed, only when `REMOTE_ADDR` is set.
    On the command line, only smaller look-ups (such as code-to-name) are cached.

- **Local geo databases can be out of date**

    Old `GeoIP.dat` files can give the wrong country for some addresses
    (see ["country"](#country)).

## Encoding

CGI::Lingua works with ASCII text. This table shows what each input accepts.

```
Input                   Accepted characters        Non-ASCII / UTF-8 / emoji
----------------------  -------------------------  -------------------------
supported               language tags (en, en-gb,   no: entry is ignored,
                        es-419); a plain string     with a warning
                        must be 2-5 chars
HTTP_ACCEPT_LANGUAGE    A-Z a-z 0-9 - , ; = . *     no: header is ignored
                        space and tab (never CR or
                        LF); max 256 chars
lang (CGI::Info)        as HTTP_ACCEPT_LANGUAGE     no: parameter is ignored
LANG                    A-Z a-z 0-9 _ . -           no: LANG is ignored
HTTP_USER_AGENT         printable ASCII             no: user agent ignored
                        (0x20-0x7E), max 512 chars
REMOTE_ADDR             IPv4 or IPv6 address        no: address is rejected
GEOIP_COUNTRY_CODE      exactly two of A-Z          no: value is ignored
HTTP_CF_IPCOUNTRY       exactly two of A-Z          no: value is ignored
translation_file $dir   any, except ".." and NUL    yes, if your file system
                                                    supports it (pass bytes
                                                    encoded as the file
                                                    system expects)
translation_file $ext   A-Z a-z 0-9 -               no: undef is returned
plural_category $n      a number                    not applicable
```

All values that CGI::Lingua returns are plain ASCII: language names
(`'French'`), country names (`'Reunion'`), codes and time zone names.
You do not need to decode them.

## Configuration Variables

Two package variables say where CGI::Lingua looks for files on the local
machine. You do not normally need to change them; tests and unusual
installations can, with `local`:

- `$CGI::Lingua::ZONE_FILE`

    The file that ["time\_zone"](#time_zone) reads when there is no `REMOTE_ADDR` (command-line
    use). The default is `/etc/timezone`. Only a readable regular file is used,
    and only its first 256 bytes are read; otherwise [DateTime::TimeZone](https://metacpan.org/pod/DateTime%3A%3ATimeZone) is used.

    ```
    local $CGI::Lingua::ZONE_FILE = '/srv/myapp/timezone';
    ```

- `@CGI::Lingua::GEOIP_DAT`

    The places where ["country"](#country) and ["time\_zone"](#time_zone) look for the legacy MaxMind
    `GeoIP.dat` used by [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP); the first readable regular file is used. The
    default is `/usr/share/GeoIP/GeoIP.dat` and `/usr/local/share/GeoIP/GeoIP.dat`
    (and `c:/GeoIP/GeoIP.dat` first, on Windows). A file that [Geo::IP](https://metacpan.org/pod/Geo%3A%3AIP) cannot
    open is skipped with the warning `"Can't open ... with Geo::IP; not using it"`.

    ```
    local @CGI::Lingua::GEOIP_DAT = ('/opt/geo/GeoIP.dat');
    ```

## Limitations

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

- **The logger is always a Log::Abstraction object**

    The `logger` argument can be an object with `warn()`, `info()` and
    `error()` methods, or any value that [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) accepts (such as an
    array reference or a hash reference of options).  In every case
    [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) replaces it with a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object.  An object
    that is missing one of the three methods is rejected by ["new"](#new).

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

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

If `HTTP_ACCEPT_LANGUAGE` contains a sub-tag with a 3-digit UN M.49 region
code (e.g. `es-419` for Latin American Spanish), `sublanguage()` returns
`undef` because ISO 3166-1 does not define numeric codes.

Uses [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage) to find the highest priority accepted language.
This means that if you support languages at a lower priority, it may be missed.

Please report any bugs or feature requests to `bug-cgi-lingua at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/CGI-Lingua/coverage/)
- VWF - Versatile Web Framework [https://github.com/nigelhorne/vwf](https://github.com/nigelhorne/vwf)
- [HTTP::BrowserDetect](https://metacpan.org/pod/HTTP%3A%3ABrowserDetect)
- [I18N::AcceptLanguage](https://metacpan.org/pod/I18N%3A%3AAcceptLanguage)
- [Locale::Country](https://metacpan.org/pod/Locale%3A%3ACountry)

## Support

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

```
perldoc CGI::Lingua
```

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

## Formal Specification

This section describes each method in the Z notation.
You do not need it to use the module.

### Types and State

```
[LANGTAG, LANGNAME, CNAME, IPADDR, PATH, ZONE, LOCALE]

CC2      == { s : seq CHAR | #s = 2 ∧ ran s ⊆ 'a'..'z' }
LC2      == CC2
PLURAL   ::= zero | one | two | few | many | other
GEO      ::= unknown | absent | present
DIR      ::= ltr | rtl
RTL_LANGS == { ar, dv, fa, he, ku, ps, sd, ug, ur, yi }

⊥ marks a value that has not been worked out yet (or is undef).

┌─ Lingua ──────────────────────────────────────────────────────
│ supported   : seq LANGTAG
│ slanguage   : LANGNAME ∪ {Unknown, ⊥}
│ rlanguage   : LANGNAME ∪ {Unknown, ⊥}
│ code2       : LC2 ∪ {⊥}
│ subcode2    : CC2 ∪ {⊥}
│ sublanguage : CNAME ∪ {⊥}
│ country     : CC2 ∪ {Unknown, ⊥}
│ locale      : LOCALE ∪ {⊥}
│ timezone    : ZONE ∪ {⊥}
│ ipc, gip, gipf : GEO
│ dont_use_ip : 𝔹
├───────────────────────────────────────────────────────────────
│ slanguage ∉ {Unknown, ⊥} ⇒
│     code2 ≠ ⊥ ∧ (∃ t : ran supported • base(t) = code2)
│ slanguage = Unknown ⇒ code2 = ⊥ ∧ subcode2 = ⊥
│ subcode2 ≠ ⊥ ⇒ code2 ≠ ⊥
│ sublanguage ≠ ⊥ ⇒ subcode2 ≠ ⊥
│ (slanguage = ⊥) ⇔ (rlanguage = ⊥)
└───────────────────────────────────────────────────────────────

request   : ENV ⇸ seq (LANGTAG × ℝ)   -- lang param, Accept-Language or LANG
negotiate : seq (LANGTAG × ℝ) × seq LANGTAG ⇸ LANGTAG
geo       : IPADDR ⇸ CC2              -- first answer of the geo sources
official  : CC2 ⇸ LANGTAG             -- official language of a country

┌─ Resolve ─────────────────────────────────────────────────────
│ ΔLingua
│ env? : ENV
├───────────────────────────────────────────────────────────────
│ slanguage = ⊥
│ let t == negotiate(request(env?), supported) •
│   t ≠ ⊥ ⇒ slanguage' = name(base(t)) ∧ code2' = base(t)
│          ∧ subcode2' = variety(t)
│   t = ⊥ ∧ ¬ dont_use_ip ∧ official(geo(env?.REMOTE_ADDR)) ∈ ran supported
│          ⇒ slanguage' = name(official(geo(env?.REMOTE_ADDR)))
│   otherwise slanguage' = Unknown
│ rlanguage' ≠ ⊥
└───────────────────────────────────────────────────────────────

EnsureResolved ≙ (Resolve ∨ (ΞLingua ∧ slanguage ≠ ⊥))
```

### New

```
┌─ New ─────────────────────────────────────────────────────────
│ Lingua'
│ supported? : LANGTAG ∪ seq LANGTAG
│ cache? : CACHE ∪ {⊥}
│ env? : ENV
├───────────────────────────────────────────────────────────────
│ supported? ∈ LANGTAG ⇒ 2 ≤ #supported? ≤ 5
│ supported' = (if supported? ∈ LANGTAG then ⟨supported?⟩ else supported?)
│                 ↾ SUPPORTED_TAGS        -- other entries dropped, with a warning
│ ipc' = gip' = gipf' = unknown
│ dont_use_ip' = dont_use_ip?             -- never taken from the cache
│ let ip == untaint_ip(env?.REMOTE_ADDR); saved == decode(cache?(key(ip))) •
│ (cache? ≠ ⊥ ∧ ip ≠ ⊥ ∧ key(ip) ∈ dom cache?
│      ∧ (∀ f : dom saved ∩ dom RESTORABLE • saved(f) ∈ RESTORABLE(f)))
│     ⇒ (∀ f : dom saved ∩ dom RESTORABLE • θLingua'.f = saved(f))
│ (cache? ≠ ⊥ ∧ ip ≠ ⊥ ∧ key(ip) ∈ dom cache?
│      ∧ (∃ f : dom saved ∩ dom RESTORABLE • saved(f) ∉ RESTORABLE(f)))
│     ⇒ key(ip) ∉ dom cache?'            -- poisoned entry removed, with a warning
│ otherwise
│     slanguage' = rlanguage' = country' = locale' = timezone' = ⊥
└───────────────────────────────────────────────────────────────

RESTORABLE : FIELD ⇸ ℙ seq CHAR
RESTORABLE ≙ { slanguage, rlanguage, sublanguage ↦ NAME,
               slanguage_code_alpha2, sublanguage_code_alpha2 ↦ LANGCODE,
               country ↦ CC2 ∪ {Unknown} }

NewError ≙ [ supported? = ⊥ ∨ supported? ∉ LANGTAG ∪ seq LANGTAG
             ∨ (info? ≠ ⊥ ∧ ¬ can(info?, lang) ∧ ¬ can(info?, AUTOLOAD)) ] ⇒ croak
```

### Language

```
┌─ Language ────────────────────────────────────────────────────
│ EnsureResolved
│ result! : LANGNAME ∪ {Unknown}
├───────────────────────────────────────────────────────────────
│ result! = slanguage'
└───────────────────────────────────────────────────────────────

PreferredLanguage ≙ Language
Name              ≙ Language
```

### Sublanguage

```
┌─ Sublanguage ─────────────────────────────────────────────────
│ EnsureResolved
│ result! : CNAME ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ result! = sublanguage'
└───────────────────────────────────────────────────────────────
```

### Language\_Code\_alpha2

```
┌─ LanguageCodeAlpha2 ──────────────────────────────────────────
│ EnsureResolved
│ result! : LC2 ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ result! = code2'
│ slanguage' = Unknown ⇒ result! = ⊥
└───────────────────────────────────────────────────────────────

CodeAlpha2 ≙ LanguageCodeAlpha2
```

### Sublanguage\_Code\_alpha2

```
┌─ SublanguageCodeAlpha2 ───────────────────────────────────────
│ EnsureResolved
│ result! : CC2 ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ result! = subcode2'
└───────────────────────────────────────────────────────────────
```

### Requested\_Language

```
┌─ RequestedLanguage ───────────────────────────────────────────
│ EnsureResolved
│ result! : seq CHAR
├───────────────────────────────────────────────────────────────
│ result! = rlanguage'
│ -- rlanguage' = name(b) ⁀ " (" ⁀ cname(v) ⁀ ")" when the visitor
│ -- asked for base b with variety v; name(b) when no variety;
│ -- Unknown when nothing was asked for.
└───────────────────────────────────────────────────────────────
```

### Country

```
┌─ Country ─────────────────────────────────────────────────────
│ ΔLingua
│ env? : ENV
│ result! : CC2 ∪ {Unknown, ⊥}
├───────────────────────────────────────────────────────────────
│ country ≠ ⊥ ⇒ result! = country ∧ θLingua' = θLingua
│ country = ⊥ ⇒
│   ( env?.GEOIP_COUNTRY_CODE ∈ CC2↑ ⇒ result! = lc(env?.GEOIP_COUNTRY_CODE) )
│   ( env?.HTTP_CF_IPCOUNTRY ∈ CC2↑ \ {XX} ⇒ result! = lc(env?.HTTP_CF_IPCOUNTRY) )
│   ( ip = canon(env?.REMOTE_ADDR) ∈ PUBLIC_IP ⇒ result! = norm(geo(ip)) )
│   ( ip ∉ PUBLIC_IP ⇒ result! = ⊥ )
│ country' = result!
│ ipc' ≠ unknown ∨ ipc' = ipc ;  gip' ≠ unknown ∨ gip' = gip
│ -- norm maps hk ↦ cn, eu ↦ Unknown (or cn for the Baidu subnet),
│ -- and anything ∉ CC2 ↦ ⊥
└───────────────────────────────────────────────────────────────

where CC2↑ is CC2 in upper case, and canon(::ffff:a.b.c.d) = a.b.c.d.
```

### Locale

```
┌─ Locale ──────────────────────────────────────────────────────
│ ΔLingua
│ env? : ENV
│ result! : LOCALE ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ locale ≠ ⊥ ⇒ result! = locale ∧ θLingua' = θLingua
│ locale = ⊥ ⇒ result! = first ⊥-free of
│     ⟨ uatag(env?.HTTP_USER_AGENT), browserdetect(env?.HTTP_USER_AGENT),
│       loc(Country.result!), loc(env?.GEOIP_COUNTRY_CODE) ⟩
│ result! ≠ ⊥ ⇒ locale' = result!
└───────────────────────────────────────────────────────────────
```

### Time\_Zone

```
┌─ TimeZone ────────────────────────────────────────────────────
│ ΔLingua
│ env? : ENV
│ result! : ZONE ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ timezone ≠ ⊥ ⇒ result! = timezone
│ timezone = ⊥ ∧ env?.REMOTE_ADDR ≠ ⊥ ⇒
│     result! = first ⊥-free of ⟨ geoip_tz(ip), ipapi_tz(ip) ⟩
│ timezone = ⊥ ∧ env?.REMOTE_ADDR = ⊥ ⇒
│     result! = first ⊥-free of ⟨ etc_timezone, local_tz ⟩
│ result! ∉ ZONE ⇒ result! = ⊥
│ timezone' = result!
└───────────────────────────────────────────────────────────────
```

### Is\_Rtl

```
┌─ IsRtl ───────────────────────────────────────────────────────
│ EnsureResolved
│ result! : {0, 1}
├───────────────────────────────────────────────────────────────
│ result! = 1 ⇔ code2' ∈ RTL_LANGS
└───────────────────────────────────────────────────────────────
```

### Text\_Direction

```
┌─ TextDirection ───────────────────────────────────────────────
│ IsRtl
│ dir! : DIR
├───────────────────────────────────────────────────────────────
│ dir! = (if result! = 1 then rtl else ltr)
└───────────────────────────────────────────────────────────────
```

### Plural\_Category

```
PLURAL_RULES : LC2 ⇸ (ℕ → PLURAL)
english == λ n : ℕ • (if n = 1 then one else other)

┌─ PluralCategory ──────────────────────────────────────────────
│ EnsureResolved
│ n? : ℝ
│ result! : PLURAL
├───────────────────────────────────────────────────────────────
│ n? ≠ ⊥
│ code2' = ⊥ ⇒ result! = other
│ code2' ∈ dom PLURAL_RULES ⇒ result! = PLURAL_RULES(code2')(trunc n?)
│ code2' ∉ dom PLURAL_RULES ∪ {⊥} ⇒ result! = english(trunc n?)
└───────────────────────────────────────────────────────────────

PluralError ≙ [ n? = ⊥ ] ⇒ croak
```

### Translation\_File

```
┌─ TranslationFile ─────────────────────────────────────────────
│ EnsureResolved
│ dir? : PATH ∪ {⊥}
│ ext? : seq CHAR ∪ {⊥}
│ files : ℙ PATH                       -- readable regular files
│ result! : PATH ∪ {⊥}
├───────────────────────────────────────────────────────────────
│ e == (if ext? = ⊥ then "json" else strip_dot(ext?))
│ (dir? = ⊥ ∨ dir? = ⟨⟩ ∨ ".." ⊆ dir? ∨ NUL ∈ ran dir?
│     ∨ ¬ (ran e ⊆ ALNUM ∪ {'-'})) ⇒ result! = ⊥
│ otherwise
│   cands == ⟨ code2' ⁀ "-" ⁀ subcode2' | subcode2' ≠ ⊥ ⟩ ⁀ ⟨ code2' | code2' ≠ ⊥ ⟩
│   result! = first p : ran cands • dir? ⁀ "/" ⁀ p ⁀ "." ⁀ e ∈ files
│             (⊥ if there is none)
└───────────────────────────────────────────────────────────────
```

## State Diagram

A CGI::Lingua object has several independent parts. Each part starts
empty and is filled in the first time a method needs it.
After that, the part does not change (it is remembered).

Part 1: the language (used by language(), sublanguage(),
language\_code\_alpha2(), sublanguage\_code\_alpha2(), requested\_language(),
is\_rtl(), text\_direction(), plural\_category(), translation\_file())

```
                              new()
                                |
                                v
                  +---------------------------+
                  |   LANGUAGE NOT CHECKED    |
                  |   _slanguage = undef      |
                  +---------------------------+
                                |
             first call to any language method:
             read the lang param, HTTP_ACCEPT_LANGUAGE or LANG,
             and compare it with the supported list
                                |
              +-----------------+------------------+
              |                                    |
         a match                               no match
              |                                    |
              |                      +-------------+-------------+
              |                      |                           |
              |               dont_use_ip is false         dont_use_ip
              |               side effect: country()       is true
              |               is called (Part 2), and           |
              |               the country's official            |
              |               language is tried                 |
              |                 |               |               |
              |            supported     not supported          |
              v                 v               v               v
       +----------------------------+   +------------------------------+
       |          MATCHED           |   |          UNMATCHED           |
       | language() = 'English' ... |   | language() = 'Unknown'       |
       | language_code_alpha2() set |   | language_code_alpha2() undef |
       +----------------------------+   +------------------------------+

    Both MATCHED and UNMATCHED are final: later calls return the same
    answers, even if %ENV changes.
```

Part 2: the country (used by country(), locale(), and the language IP path)

```
+----------------------+   country(): REMOTE_ADDR missing, invalid,
|  COUNTRY NOT KNOWN   |---------------------------------------------+
|  _country = undef    |   private or loopback, or no source answers |
+----------------------+<--------------------------------------------+
           |                (returns undef; NOT remembered, so the
           |                 next call tries again)
           | country(): a source gives a valid code
           | side effects: geo modules loaded, sentinels set,
           |               value stored in cache (if any)
           v
+----------------------+
|    COUNTRY KNOWN     |  later calls return the same value
|  _country = 'xx'     |  (or 'Unknown' for EU addresses)
+----------------------+
```

Part 3: each geo module (IP::Country, Geo::IP, Geo::IPfree)

```perl
+-----------+  first use: module loads   +-----------+
|  UNKNOWN  |--------------------------->|  PRESENT  |
|   (-1)    |                            |    (1)    |
+-----------+--------------------------->+-----------+
               first use: module or      +-----------+
               database is missing ----->|  ABSENT   |
                                         |    (0)    |
                                         +-----------+
```

Part 4: locale() and time\_zone()

```
+------------+  locale() / time_zone() finds a value  +------------+
| NOT KNOWN  |--------------------------------------->|   KNOWN    |
|  (undef)   |<-------+                               | remembered |
+------------+        | nothing found: returns undef, +------------+
      |               | stays NOT KNOWN (time_zone()
      +---------------+ also warns)
```

Part 5: the life of the object

```
new() ----------------------> ALIVE ----------------------> DESTROYED
  |   no cache entry, or        ^      object goes out of     side effect:
  |   no REMOTE_ADDR            |      scope (DESTROY)        if cache and
  |                             |                             REMOTE_ADDR are
  +---- valid cache entry ------+                             set and no entry
  |     found (the six answer   |                             exists yet, the
  |     fields restored, each   |                             answers are saved
  |     checked; geo sentinels  |                             to the cache as
  |     reset to UNKNOWN)       |                             JSON
  |                             |
  +---- malformed cache entry --+
  |     found (removed, warned;
  |     answers worked out again)
  |
  +---- REMOTE_ADDR not a valid address: the cache is not used
  |
  +---- bad arguments ---> croak (no object)

$obj->new(...) makes a copy in the ALIVE state that keeps all the
answers of $obj (all parts keep their current state).
```

## License and Copyright

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
