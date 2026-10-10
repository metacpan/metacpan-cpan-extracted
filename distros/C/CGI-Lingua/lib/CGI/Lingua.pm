package CGI::Lingua;

use warnings;
use strict;
use autodie qw(:all);

use Carp ();	# fully qualified calls: nothing imported into this package
use Object::Configure 0.23;
use Params::Get 0.15;	# 0.15 fast-path: unblessed hashref returned directly
use Readonly;
use Scalar::Util ();	# fully qualified, so $obj->blessed() is not a method
use JSON::PP ();
use Class::Autouse qw{
	Locale::Language
	Locale::Object::Country
	Locale::Object::DB
	I18N::AcceptLanguage
};

our $VERSION = '0.87';

# Post-release roadmap (from the 0.87 gap analysis).
#
# Upstream services
# TODO: geoplugin.net has no free tier any more, so that look-up is dead code
#	for nearly everyone.  Make the web providers configurable
#	(geo_providers => [...]) with a built-in client for a free HTTPS
#	service, or drop geoplugin.
# TODO: ip-api.com is plain HTTP and limited to 45 requests a minute; answers
#	are validated but can be read and altered in transit.  Allow an API key
#	/ HTTPS provider and add rate limiting or back-off.
# TODO: Support MaxMind GeoLite2 (GeoIP2::Database::Reader or
#	IP::Geolocation::MMDB); GeoIP.dat (frozen 2019) and Geo::IPfree (known
#	wrong entries) are the only local databases today.
# TODO: Add a timeout option: a slow upstream holds the request for LWP's
#	default of 180 seconds.
#
# Features
# TODO: native_name() ("Francais" for French, in that language's script),
#	plus bcp47() / lang_attribute() for the HTML lang attribute.
# TODO: Number, currency and date formatting helpers from the negotiated
#	locale (CLDR via Locale::CLDR, optional).
# TODO: Script detection (zh-Hant / zh-Hans, sr-Latn) and RTL by script
#	rather than by language.
# TODO: Proper 3-letter and UN M.49 regions (es-419, en-029); these are the
#	remaining TODO tests (t/es_419.t, t/en_029.t).
# TODO: A Content-Language / Vary: Accept-Language header helper, and RFC
#	4647 "lookup" fallback chains.
# TODO: PSGI / Plack: middleware or a from_env(\%env) constructor that does
#	not depend on %ENV, removing the "country() reads REMOTE_ADDR when
#	called" pitfall.
#
# Technical debt
# TODO: Split this file into ::Negotiate, ::Geo (one class per provider) and
#	::Cache; most of the mocking pitfalls in the tests come from the
#	coupling.
# TODO: Replace the three geo sentinels and the two package sentinels
#	($_locale_object_db_ok, $_have_dvip) with one capability probe, cached
#	per process.
# TODO: Enforce privacy with Sub::Private once t/function.t and
#	t/extended_tests.t stop calling _-methods directly.
# TODO: Structured log events (a code plus fields) instead of English
#	strings, so applications can translate and filter them.
# TODO: t/integration.t takes about 15 seconds because of its ~45 child
#	processes; run them in parallel or reuse one child per combination.

# Gathering magic strings here makes behavioural changes one-edit operations.

Readonly my $CACHE_TTL_LONG      => '1 month';
Readonly my $CACHE_TTL_SHORT     => '1 hour';
Readonly my $CACHE_NS            => 'CGI::Lingua:';    # namespace prefix for every key
Readonly my $BROKEN_GEOIPFREE    => '45.128.139.41';  # https://github.com/bricas/geo-ipfree/issues/10
Readonly my $BAIDU_SUBNET        => '185.10.104.0/22';# RT-86809: Baidu misreports as EU
Readonly my $DEPRECATED_EN_UK    => 'en-uk';          # some browsers still send this
Readonly my $CANONICAL_EN_GB     => 'en-gb';
Readonly my $ACCEPT_LANG_MAX     => 256;              # max bytes we accept from the header
Readonly my $UA_MAX              => 512;              # max bytes we accept from HTTP_USER_AGENT
Readonly my $GEO_UNKNOWN         => -1;               # geo-module sentinel: not yet probed
Readonly my $GEO_ABSENT          =>  0;               # geo-module sentinel: unavailable
Readonly my $GEO_PRESENT         =>  1;               # geo-module sentinel: loaded OK

# Shapes of the values CGI::Lingua keeps in the cache.  Anything read back
# that does not match is treated as poisoned and discarded.  Language and
# country names from Locale::Language, Locale::Codes and Locale::Object use
# only these characters (e.g. "Cote D'Ivoire", "Modern Greek (1453-)",
# "Falkland Islands (The) [Malvinas]"); none of them use < > " & ; / =.
Readonly my $NAME_RE      => qr/^[A-Za-z][A-Za-z0-9 ,.:'()\[\]\-]{0,99}\z/a;	# ":" for "English (Unknown: zz)"
Readonly my $NAME_CODE_RE => qr/^[A-Za-z][A-Za-z0-9 ,.'()\[\]\-]{0,99}=[a-z]{2,3}\z/a;
Readonly my $LANG_CODE_RE => qr/^[a-z]{2,3}\z/a;
Readonly my $COUNTRY_RE   => qr/^(?:[a-z]{2}|Unknown)\z/a;

# A language list from HTTP_ACCEPT_LANGUAGE or a lang= parameter: the RFC 7231
# characters plus "*", spaces and tabs (never CR or LF), at most
# $ACCEPT_LANG_MAX bytes.  Captures the untainted value.
Readonly my $ACCEPT_LANG_RE => qr/^([A-Za-z0-9\-,;=.* \t]{1,$ACCEPT_LANG_MAX})\z/a;

# A supported-list entry: a language tag such as "en", "en-gb", "es-419" or
# "zh-Hant" (an underscore is accepted for "en_gb").  "english" is not one.
Readonly my $SUPPORTED_RE => qr/^[A-Za-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*\z/a;

# An IP address as accepted from REMOTE_ADDR, before Data::Validate::IP checks
# it properly: dotted quad, or IPv6 including ::ffff:a.b.c.d.  Captures it.
Readonly my $IP_SHAPE_RE => qr/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|[0-9a-fA-F:]{2,39}|[0-9a-fA-F:]{2,30}:(?:\d{1,3}\.){3}\d{1,3})\z/a;

# Fields that DESTROY saves and new() restores, with the shape each must have
# time_zone(): IANA zone names (e.g. "America/New_York", "Etc/GMT+8", "UTC")
Readonly my $ZONE_RE       => qr/^[A-Za-z][A-Za-z0-9_+\-\/]{0,50}\z/a;
Readonly my $ZONE_FILE_MAX => 256;	# bytes read from $ZONE_FILE; a zone name is far shorter

# File holding the system time zone, read by time_zone() when there is no
# REMOTE_ADDR.  A package variable (not Readonly) so tests can point it at a
# hostile file with "local $CGI::Lingua::ZONE_FILE = ...".
our $ZONE_FILE = '/etc/timezone';

# Where _load_geoip() looks for the legacy MaxMind GeoIP.dat used by Geo::IP;
# the first readable regular file wins.  A package variable so a test or a
# site can point it elsewhere ("local @CGI::Lingua::GEOIP_DAT = ...").
our @GEOIP_DAT = (
	(($^O eq 'MSWin32') ? ('c:/GeoIP/GeoIP.dat') : ()),
	'/usr/share/GeoIP/GeoIP.dat',
	'/usr/local/share/GeoIP/GeoIP.dat',
);

Readonly my %RESTORABLE => (
	_slanguage               => $NAME_RE,
	_rlanguage               => $NAME_RE,
	_sublanguage             => $NAME_RE,
	_slanguage_code_alpha2   => $LANG_CODE_RE,
	_sublanguage_code_alpha2 => $LANG_CODE_RE,
	_country                 => $COUNTRY_RE,
);

# Package-level sentinel for Locale::Object's SQLite database.  undef = not yet
# probed; 0 = database absent (Windows installers often omit it); 1 = available.
# Package-level (not per-object) because the database either exists on the
# filesystem or it doesn't — there is no per-request variability.
my $_locale_object_db_ok;

# Package-level sentinel for Data::Validate::IP / NetAddr::IP availability.
# NetAddr::IP::UtilPP fails to build on Windows (mask4to6 bad-argument error),
# which cascades to Data::Validate::IP.  undef = not yet probed; 0 = broken;
# 1 = available.  On first country() call we try to load the module and, if it
# fails, install pure-Perl aliases for the four functions we use.
my $_have_dvip;

# Short-name overrides used when Locale::Object's database is absent and we
# fall back to Locale::Codes::Country.  Locale::Codes carries full ISO official
# names (e.g. "United Kingdom of Great Britain and Northern Ireland") while
# Locale::Object returns the common short form ("United Kingdom").  Only
# entries that differ are listed; everything else comes from Locale::Codes.
my %COUNTRY_SHORT_NAMES = (
	bo => 'Bolivia',
	cd => 'Democratic Republic of the Congo',
	fk => 'Falkland Islands',
	fm => 'Micronesia',
	gb => 'United Kingdom',
	ir => 'Iran',
	kp => 'North Korea',
	kr => 'South Korea',
	md => 'Moldova',
	nl => 'Netherlands',
	ps => 'Palestine',
	tw => 'Taiwan',
	tz => 'Tanzania',
	us => 'United States',
	ve => 'Venezuela',
);

Readonly my %RTL_LANGS           => (map { $_ => 1 }  # ISO 639-1 codes whose primary script is RTL
	qw(ar dv fa he ku ps sd ug ur yi));

=head1 NAME

CGI::Lingua - Create a multilingual web page

=head1 VERSION

Version 0.87

=cut

=head1 SYNOPSIS

Your website tells CGI::Lingua which languages it can show.
CGI::Lingua looks at what the visitor's web browser asks for,
and tells your website which of its languages to use.

=head2 Pick a language for the page

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

=head2 Use the short code to choose a file or template

    my $l = CGI::Lingua->new(supported => ['en-gb', 'en-us', 'fr']);

    my $code    = $l->language_code_alpha2() // 'en';    # 'en' or 'fr'
    my $variant = $l->sublanguage_code_alpha2();         # 'gb', 'us' or undef
    my $template = defined($variant) ? "$code-$variant.tmpl" : "$code.tmpl";

=head2 Show different content for different countries

    my $l = CGI::Lingua->new(supported => ['en']);

    my $country = $l->country() // '';    # e.g. 'us', 'ca', 'gb'
    if($country eq 'us') {
        print "Call us on 1-800-555-0100\n";
    } elsif($country eq 'ca') {
        print "Call us on 1-888-555-0100\n";
    } else {
        print "Email us at help\@example.com\n";
    }

=head2 Make it faster with a cache

Finding the country of an IP address can be slow.
Give CGI::Lingua a L<CHI> cache so that the work is only done once
for each visitor.

    use CHI;
    use CGI::Lingua;

    my $cache = CHI->new(
        driver    => 'File',
        root_dir  => '/var/cache/myapp',
        namespace => 'CGI::Lingua',
    );
    my $l = CGI::Lingua->new(supported => ['en', 'fr'], cache => $cache);

=head2 Let the visitor choose with a "lang" parameter

If you pass a L<CGI::Info> object, a C<lang=fr> parameter in the URL
is used before the browser's settings.

    use CGI::Info;
    use CGI::Lingua;

    my $info = CGI::Info->new();
    my $l = CGI::Lingua->new(supported => ['en', 'fr', 'de'], info => $info);
    print $l->language();    # 'German' for https://example.com/page?lang=de

=head2 Set the HTML "lang" and "dir" attributes

    my $l = CGI::Lingua->new(supported => ['en', 'ar', 'he']);
    my $code = $l->language_code_alpha2() // 'en';
    printf qq{<html lang="%s" dir="%s">\n}, $code, $l->text_direction();
    # <html lang="ar" dir="rtl"> for an Arabic-speaking visitor

=head2 Choose the right plural form

    my $l = CGI::Lingua->new(supported => ['en', 'ru']);
    my %messages = (
        one  => '%d file',
        few  => '%d files (few)',
        many => '%d files (many)',
        other => '%d files',
    );
    my $n = 3;
    printf $messages{$l->plural_category($n)} . "\n", $n;

=head2 Load a translation file

    # Looks for /var/www/i18n/en-gb.json, then /var/www/i18n/en.json
    my $l = CGI::Lingua->new(supported => ['en-gb', 'en', 'fr']);
    if(my $file = $l->translation_file('/var/www/i18n')) {
        # read and use $file
    }

=head2 Guess the visitor's time zone and locale

    my $l = CGI::Lingua->new(supported => ['en']);
    my $tz = $l->time_zone() // 'UTC';     # e.g. 'America/New_York'
    if(my $locale = $l->locale()) {         # a Locale::Object::Country
        print 'Currency: ', $locale->currency()->code(), "\n";
    }

=head2 Do not guess from the IP address

    # Only use what the browser asks for; never look up the IP address
    my $l = CGI::Lingua->new(supported => ['en', 'fr'], dont_use_ip => 1);

=head1 DESCRIPTION

This section explains, in simple steps, how CGI::Lingua finds the answer.

=head2 Finding the language

When you first call a language method (for example L</language>),
CGI::Lingua looks for the visitor's language in this order:

=over 4

=item 1. The C<lang> parameter of the L<CGI::Info> object, if you gave one
to L</new> with C<info>.

=item 2. The C<HTTP_ACCEPT_LANGUAGE> environment variable.
The web server sets this from the browser's C<Accept-Language> header,
for example C<fr-CA,fr;q=0.9,en;q=0.8>.
Languages with a higher C<q> value are tried first.
A language with C<q=0> means "not acceptable" (RFC 7231) and is never chosen.
Some browsers still send the old tag C<en-uk>; it is treated as C<en-gb>
(the code for the United Kingdom is C<gb>), with a warning.

=item 3. The C<LANG> environment variable.
This is used when you run the program on the command line,
for example C<LANG=fr_FR.UTF-8>.

=item 4. The visitor's country (see below).
CGI::Lingua uses the official language of that country.
This step is skipped when you give C<dont_use_ip> to L</new>.

=back

It then compares the answer with your C<supported> list.
If a visitor asks for C<en-us> and you only support C<en-gb>,
CGI::Lingua still chooses English, because the base language is the same.
If nothing matches, L</language> returns the string C<'Unknown'>.

=head2 Finding the country

L</country> tries these sources in order, and stops at the first answer:

=over 4

=item 1. C<GEOIP_COUNTRY_CODE> (set by Apache's mod_geoip).

=item 2. C<HTTP_CF_IPCOUNTRY> (set by Cloudflare).

=item 3. A local database: L<IP::Country>, then L<Geo::IP>, then L<Geo::IPfree>,
if they are installed.

=item 4. The geoplugin.net web service.

=item 5. A Whois look-up (L<Net::Whois::IP>, then L<Net::Whois::IANA>).

=back

Steps 3 to 5 use the visitor's IP address from C<REMOTE_ADDR>.
Private addresses (such as C<192.168.1.1>) and loopback addresses
(such as C<127.0.0.1>) have no country, so the answer is C<undef>.

=head2 Remembering answers

Each object remembers its answers, so a second call to the same method is fast.
If you give a C<cache> to L</new>, answers are also stored in the cache when the
object is destroyed. The next object created for the same IP address, the same
requested language and the same C<supported> list starts with those answers.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Lingua object.

You must tell it which languages your website supports, with C<supported>.
Each language is a short code, such as C<'en'> (English),
C<'fr'> (French) or C<'en-gb'> (British English).

You can give the arguments as a list, as a hash reference,
as a single array reference (the supported list), or as a single string
(one supported language):

    CGI::Lingua->new(supported => ['en', 'fr']);
    CGI::Lingua->new({ supported => ['en', 'fr'] });
    CGI::Lingua->new(['en', 'fr']);
    CGI::Lingua->new('en');

The arguments are:

=over 4

=item * C<supported> (required)

The languages your website supports: one short code (a string of 2 to 5
characters) or a reference to an array of language tags.
C<supported_languages> is another name for the same argument.

Each entry in the array must look like a language tag: two or three letters,
optionally followed by subtags, such as C<'en'>, C<'en-gb'>, C<'en_gb'>,
C<'es-419'> or C<'zh-Hant'>. Other entries (C<undef>, references, C<''>, or
words such as C<'english'>) could never match, so they are dropped with the
warning C<"Ignoring '...' in the supported list: not a language code">.
An empty list is allowed; L</language> then always returns C<'Unknown'>.

=item * C<cache> (optional)

An object with C<get()>, C<set()> and C<remove()> methods, such as a L<CHI> object.
CGI::Lingua stores its answers here so that later requests are faster.
If a call to the cache dies (for example a full disc, an unreachable server,
or a L<CHI> object created with C<< on_get_error =E<gt> 'die' >>), CGI::Lingua
warns C<"Cache get failed: ..."> (or C<set> / C<remove>) and carries on as if
the value was not cached. Any method that uses the cache can give this warning.

Everything read back from the cache is checked before it is used, because a
cache can be shared with, or written by, other programs. A value that does not
have the shape CGI::Lingua stores (for example C<< gb<script> >> as a country, or
a hash where a language name should be) is removed and warned about with
C<"Discarding malformed cache entry for ...">, and the answer is worked out
again.

=item * C<config_file> (optional)

The path to a configuration file. It is read by L<Object::Configure>.
Values in this file B<replace> the arguments that you give to C<new()>
(see L</COMMON PITFALLS>).

=item * C<logger> (optional)

Where to send messages. This can be an object with C<warn()>, C<info()> and
C<error()> methods, or any value that L<Object::Configure> accepts
(for example an array reference, which collects the messages).
It is always changed into a L<Log::Abstraction> object.
Without a logger, warnings go to L<Carp>.

=item * C<info> (optional)

A L<CGI::Info> object (or any object with a C<lang()> method).
A C<lang> parameter in the request is then used before the browser's
settings. The parameter comes from the visitor, so it is checked like the
C<Accept-Language> header (see L</ENCODING>); a value that fails is ignored with
the warning C<"lang parameter contains invalid characters; ignoring">.

=item * C<dont_use_ip> (optional, default false)

When true, CGI::Lingua never guesses the language from the visitor's
IP address.

=item * C<syslog> (optional)

Passed on to the logging configuration.

=item * C<debug> (optional, default false)

When true, L<I18N::AcceptLanguage> prints debug information.

=back

If you call C<new()> on an existing object, you get a copy of that object.
The arguments you give replace the values in the copy.
The copy also keeps any answers that the original has already worked out
(see L</COMMON PITFALLS>).

=head3 API SPECIFICATION

=head4 Input

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

You must give C<supported> or its other name C<supported_languages>.
A string must be 2 to 5 characters long.

=head4 Output

    {
        type => 'object',
        isa  => 'CGI::Lingua',
    }

=head3 EXAMPLE

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

=head3 MESSAGES

C<new()> dies (with L<Carp/croak>) with one of these messages:

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

It warns, and carries on, with:

    "Ignoring '...' in the supported list: not a language code"
        - an entry of the supported list is not a language tag
    "Cache get failed: ..."
        - the cache died while looking up saved answers
    "Discarding malformed cache entry for ..."
        - the saved answers were not in the shape CGI::Lingua writes

=head3 PSEUDOCODE

    1. Read the arguments with Params::Get
    2. If called on an object, return a copy with the new arguments on top
    3. If logger is an object, check that it has warn, info and error
    4. Merge in config_file and environment settings with Object::Configure
    5. Check supported (required; string of 2-5 characters, or an arrayref)
    6. If there is a cache and REMOTE_ADDR is set, try to load saved answers
       from the cache (JSON); if found, return them as an object
    7. Otherwise return a new object with no answers yet

=cut

sub new
{
	my $class = shift;
	my $params = Params::Get::get_params('supported', @_);

	# Handle ::new() misuse
	if(!defined($class)) {
		if($params) {
			# Object::Configure has not run yet, so the logger may still be in
			# one of its raw forms (arrayref, hashref, file name)
			my $logger = $params->{'logger'};
			if(Scalar::Util::blessed($logger) && $logger->can('error')) {
				$logger->error(__PACKAGE__ . ' use ->new() not ::new() to instantiate');
			}
			Carp::croak(__PACKAGE__ . ' use ->new() not ::new() to instantiate');
		}
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# Clone: overlay new params onto existing object state
		$params->{_supported} ||= $params->{supported} if defined $params->{'supported'};
		return bless { %{$class}, %{$params} }, ref($class);
	}

	# Validate blessed logger objects before Object::Configure runs.
	# Non-blessed values (arrayrefs, hashrefs) are valid config forms that
	# Object::Configure knows how to convert into a Log::Abstraction instance.
	if(defined $params->{'logger'} && Scalar::Util::blessed($params->{'logger'})) {
		unless(
			$params->{'logger'}->can('warn')
			&& $params->{'logger'}->can('info')
			&& $params->{'logger'}->can('error')
		) {
			Carp::croak('Logger must be a blessed object with warn/info/error methods');
		}
	}

	# Object::Configure runs evals and file tests; keep them off the caller's $@ and $!
	$params = do { local ($@, $!); Object::Configure::configure($class, $params) };

	# Normalise supported / supported_languages alias
	$params->{'supported'} ||= $params->{'supported_languages'};
	if(defined($params->{supported})) {
		# Validate supported type/length
		if(ref($params->{supported})) {
			if(ref($params->{supported}) ne 'ARRAY') {
				Carp::croak('List of supported languages must be an array ref');
			}
		} elsif((length($params->{supported}) < 2) || (length($params->{supported}) > 5)) {
			Carp::croak('Supported languages must be the short code');
		}
	} else {
		if(my $logger = $params->{'logger'}) {
			$logger->error('You must give a list of supported languages');
		}
		Carp::croak('You must give a list of supported languages');
	}

	my $cache = $params->{cache};
	my $info  = $params->{info};

	# info is asked for lang() on every request.  CGI::Info provides lang()
	# through AUTOLOAD, so can('lang') alone is not enough of a test.
	if(defined($info) && !(Scalar::Util::blessed($info) && ($info->can('lang') || $info->can('AUTOLOAD')))) {
		Carp::croak('info must be an object with a lang() method');
	}

	# Keep only entries that are language tags ("en", "en-gb", "es-419").
	# undef, references (including a list that contains itself), '' and words
	# such as "english" could never match and would make I18N::AcceptLanguage
	# warn; say so rather than drop them silently.
	my @supported;
	for my $item (ref($params->{supported}) ? @{$params->{supported}} : ($params->{'supported'})) {
		my $entry = $item;	# a copy: the loop variable aliases the caller's array
		if(defined($entry) && !ref($entry) && ($entry =~ $SUPPORTED_RE)) {
			if(lc($entry) eq $DEPRECATED_EN_UK) {
				# Same rule as the header: en-uk is en-gb
				my $msg = "Resetting country code to GB for $entry";
				if(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('warn')) {
					$params->{'logger'}->warn($msg);
				} else {
					Carp::carp($msg);
				}
				$entry = $CANONICAL_EN_GB;
			}
			push @supported, $entry;
			next;
		}
		my $msg = q{Ignoring '} . _printable($entry) . q{' in the supported list: not a language code};
		if(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('warn')) {
			$params->{'logger'}->warn($msg);
		} else {
			Carp::carp($msg);
		}
	}

	my $self = bless {
		%{$params},
		_supported       => \@supported,
		_cache           => $cache,
		_info            => $info,
		_syslog          => $params->{syslog},
		_dont_use_ip     => $params->{dont_use_ip} || 0,
		_have_ipcountry  => $GEO_UNKNOWN,
		_have_geoip      => $GEO_UNKNOWN,
		_have_geoipfree  => $GEO_UNKNOWN,
		_debug           => $params->{debug} || 0,
	}, $class;

	# Try to restore the answers saved by DESTROY for this visitor.  Only the
	# fields in %RESTORABLE are taken from the cache, each checked against
	# its pattern: the cache can be written by others (world-writable /tmp,
	# unauthenticated Redis), so a hostile entry must not set the logger,
	# the supported list, dont_use_ip, or an HTML/path payload as a language.
	if($cache && $ENV{'REMOTE_ADDR'}) {
		my $key = _build_cache_key($ENV{'REMOTE_ADDR'}, $params, $class, $info);
		# No key means REMOTE_ADDR is not a valid address: do not cache
		if(defined($key) && (my $frozen = _cache_call($params, $cache, 'get', $key))) {
			# JSON::PP rather than Storable::thaw: Storable can run code via
			# STORABLE_thaw hooks in a crafted blob; JSON cannot.  A blob that
			# is not JSON (e.g. a legacy Storable entry) is quietly rebuilt.
			my $rc = do { local $@; eval { local $SIG{__DIE__}; JSON::PP::decode_json($frozen) } };
			if(ref($rc) eq 'HASH') {
				my @bad = grep {
					defined($rc->{$_}) && (ref($rc->{$_}) || ($rc->{$_} !~ $RESTORABLE{$_}))
				} sort keys %RESTORABLE;
				if(@bad) {
					my $msg = "Discarding malformed cache entry for $key";
					if(Scalar::Util::blessed($params->{'logger'}) && $params->{'logger'}->can('warn')) {
						$params->{'logger'}->warn($msg);
					} else {
						Carp::carp($msg);
					}
					_cache_call($params, $cache, 'remove', $key);
				} else {
					$self->{$_} = $rc->{$_} for grep { defined $rc->{$_} } keys %RESTORABLE;

					# A lang= CGI parameter overrides the browser, so the
					# cached language choice may be stale: work it out again
					if(_info_lang($info)) {
						delete @{$self}{qw(_slanguage _rlanguage _sublanguage
							_slanguage_code_alpha2 _sublanguage_code_alpha2)};
					}
				}
			}
		}
	}

	return $self;
}
# ── _build_cache_key ──────────────────────────────────────────────────────────
# Purpose:      Produce a deterministic string key for the per-request cache
#               entry stored in new() and DESTROY().
# Entry:        $addr  — IP string (not yet taint-checked; used read-only here)
#               $params — constructor params hashref
#               $class  — package name
#               $info   — optional CGI::Info object
# Exit:         A plain string key of the form "ip/lang/lang1/lang2/..."
sub _build_cache_key
{
	my ($addr, $params, $class, $info) = @_;

	# Every part of the key comes from the visitor or the caller, and cache
	# backends such as Memcached treat CR, LF and spaces in a key as protocol.
	# So the key is built only from checked values, and there is no key (and
	# so no caching) when the address is not a valid one.
	my $ip = _untaint_ip($addr);
	return undef unless defined($ip);
	my $key = "$ip/";

	# Include the requested language (if determinable) so different
	# Accept-Language values get distinct cache slots for the same IP.
	# Both sources are validated; spaces are not significant in the header.
	my $l;
	if(defined($l = _info_lang($info)) || defined($l = $class->_what_language())) {
		$l =~ s/[ \t]+//g;
		$key .= "$l/" if length($l);
	}

	# Fix: was ref($params->{'supported'} eq 'ARRAY') — eq was inside ref(),
	# so ref() always received a boolean (1 or ''), never the arrayref itself.
	# Only entries that new() would keep are used.
	my @supported = ref($params->{'supported'}) eq 'ARRAY' ? @{$params->{supported}} : ($params->{'supported'});
	$key .= join('/', grep { defined($_) && !ref($_) && ($_ =~ $SUPPORTED_RE) } @supported);

	return $key;
}

# ── _untaint_ip ──────────────────────────────────────────────────────────
# Purpose:      Check that a value has the shape of an IP address and return
#               an untainted copy.  The single place REMOTE_ADDR is checked,
#               so country(), time_zone() and the cache key always agree.
# Entry:        $raw — any scalar.
# Exit:         The address, or undef.  \z, not $, so "1.2.3.4\n" is refused.
# Notes:        Shape only: country() then range-checks with is_ipv4/is_ipv6.
sub _untaint_ip
{
	my $raw = shift;
	return undef unless defined($raw) && !ref($raw);
	return $raw =~ $IP_SHAPE_RE ? $1 : undef;
}

# ── _cache_call ──────────────────────────────────────────────────────────
# Purpose:      Call get/set/remove on the caller-supplied cache without
#               letting a cache failure take down the request.  The cache only
#               saves time, so a broken backend (full disc, unreachable Redis,
#               CHI with on_get_error => 'die') must degrade to "not cached".
# Entry:        $self   — a CGI::Lingua object, or new()'s params hashref
#                         (used only to find a logger);
#               $cache  — the cache object; $method — 'get', 'set' or 'remove';
#               @args   — passed to the method unchanged.
# Exit:         The method's scalar result, or undef if it died.
# Side Effects: Warns "Cache <method> failed: <error>" on failure.
sub _cache_call
{
	my ($self, $cache, $method, @args) = @_;

	local $@;
	my $rc;
	return $rc if eval { local $SIG{__DIE__}; $rc = $cache->$method(@args); 1 };

	my $err = $@ || 'unknown error';
	$err =~ s/\s+\z//;
	my $msg = "Cache $method failed: $err";
	if(Scalar::Util::blessed($self)) {
		$self->_warn({ warning => $msg });
	} elsif((ref($self) eq 'HASH') && Scalar::Util::blessed($self->{'logger'}) && $self->{'logger'}->can('warn')) {
		$self->{'logger'}->warn($msg);
	} else {
		Carp::carp($msg);
	}
	return;
}

# ── _info_lang ───────────────────────────────────────────────────────────
# Purpose:      Ask the CGI::Info-style object for the lang= parameter without
#               letting a broken object (an AUTOLOAD that dies) end the request.
# Entry:        $info — the info object, or undef;
#               $self — optional object to warn through when the value is bad.
# Exit:         The validated, untainted lang value, or undef if there is none,
#               the call died, or the value is not a plausible language list.
sub _info_lang
{
	my ($info, $self) = @_;

	return undef unless $info;
	local $@;
	my $lang;
	return undef unless eval { local $SIG{__DIE__}; $lang = $info->lang(); 1 };
	return undef unless defined($lang) && length($lang);

	# lang= comes from the query string, so it is as hostile as any header:
	# same character set and length cap as HTTP_ACCEPT_LANGUAGE
	return $1 if !ref($lang) && ($lang =~ $ACCEPT_LANG_RE);
	$self->_warn({ warning => 'lang parameter contains invalid characters; ignoring' }) if ref($self);
	return undef;
}

# ── _cache_get_valid ─────────────────────────────────────────────────────
# Purpose:      Read a value from the cache and use it only if it has the
#               shape CGI::Lingua itself stores.  The cache may be shared or
#               writable by others; a poisoned entry ("<script>", a hashref,
#               "../../etc") must never become a language or country.
# Entry:        $key — full cache key; $re — the pattern the value must match.
# Exit:         The value, or undef on a miss or a malformed value.
# Side Effects: A malformed value is removed and "Discarding malformed cache
#               entry for <key>" is warned (the value itself is not logged:
#               it is attacker-controlled).
sub _cache_get_valid
{
	my ($self, $key, $re) = @_;

	my $value = $self->_cache_call($self->{_cache}, 'get', $key);
	return $value if !defined($value) || (!ref($value) && ($value =~ $re));

	$self->_warn({ warning => "Discarding malformed cache entry for $key" });
	$self->_cache_call($self->{_cache}, 'remove', $key);
	return;
}

# Some of the information takes a long time to work out, so cache what we can
sub DESTROY {
	# Destructors run at arbitrary points, e.g. while the caller is examining $@
	local ($@, $!);
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
	}
	return unless $ENV{'REMOTE_ADDR'};

	my $self = shift;
	return unless ref($self);

	my $cache = $self->{_cache};
	return unless $cache;

	my $key = _build_cache_key(
		$ENV{'REMOTE_ADDR'},
		{ supported => $self->{_supported} },
		ref($self),
		$self->{_info},
	);
	return unless defined($key);	# REMOTE_ADDR is not a valid address
	return if $self->_cache_call($cache, 'get', $key);

	$self->_debug("Storing self in cache as $key");

	# Serialise only the computed state — not loggers, file handles, or
	# geo-module objects (they are re-initialised on next construction).
	# JSON::PP is used instead of Storable so that a compromised cache backend
	# cannot deliver a blob that executes code via STORABLE_thaw hooks.
	# Only the fields new() will accept back (see %RESTORABLE).  _sublanguage
	# used to be left out, so sublanguage() was undef after a restore.
	my %state = map { $_ => $self->{$_} } keys %RESTORABLE;

	$self->_cache_call($cache, 'set', $key, JSON::PP::encode_json(\%state), $CACHE_TTL_LONG);
}

=head2 language

Returns the name of the language to show to the visitor, in English,
for example C<'English'>, C<'French'> or C<'Japanese'>.
The language is always one of the languages in your C<supported> list.

Variants are handled sensibly.
If a visitor asks for American English (C<en-us>)
and your site only has British English (C<en-gb>),
C<language()> returns C<'English'>.

If none of the languages that the visitor wants is in your C<supported> list,
C<language()> returns the string C<'Unknown'>.
It never returns C<undef>.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type => 'string',
        min  => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'fr,en;q=0.9';
    my $l = CGI::Lingua->new(supported => ['en', 'fr']);
    print $l->language();   # "French"

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
    my $l = CGI::Lingua->new(supported => ['en', 'fr']);
    print $l->language();   # "Unknown"

=head3 MESSAGES

The first call to L</language> (or any other language method) warns, and
ignores the value, when one of its inputs is not acceptable:

    "lang parameter contains invalid characters; ignoring"
    "HTTP_ACCEPT_LANGUAGE contains invalid characters; ignoring"
    "LANG contains invalid characters; ignoring"

It also warns when it changes the deprecated tag C<en-uk> into C<en-gb>:

    "Resetting country code to GB for ..."

=cut

sub language {
	my $self = $_[0];

	$self->_find_language() unless $self->{_slanguage};
	return $self->{_slanguage};
}

=head2 preferred_language

Another name for L</language>. It takes no arguments and returns the same value.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type => 'string',
        min  => 1,
    }

=cut

sub preferred_language
{
	my $self = shift;
	return $self->language(@_);
}

=head2 name

Another name for L</language>, so that a CGI::Lingua object can be used where a
L<Locale::Object::Language> object is expected.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type => 'string',
        min  => 1,
    }

=cut

sub name {
	my $self = $_[0];
	return $self->language();
}

=head2 sublanguage

Returns the name of the variant (usually a country) of the chosen language,
for example C<'United Kingdom'> when the chosen language is C<en-gb>.

Returns C<undef> when there is no variant, for example when the chosen
language is just C<en>, or when no language was found.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        min      => 1,
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->sublanguage();   # "United Kingdom"

=cut

sub sublanguage {
	my $self = $_[0];

	$self->_trace('Entered sublanguage');
	$self->_find_language() unless $self->{_slanguage};
	$self->_trace('Leaving sublanguage ', ($self->{_sublanguage} || 'undef'));
	return $self->{_sublanguage};
}

=head2 language_code_alpha2

Returns the two-letter code (ISO 639-1) of the chosen language,
for example C<'en'> when the chosen language is C<en-gb>.

Returns C<undef> when none of the languages that the visitor wants is in your
C<supported> list (that is, when L</language> returns C<'Unknown'>).

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        min      => 2,
        max      => 2,
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->language_code_alpha2();   # "en"

=cut

sub language_code_alpha2 {
	my $self = $_[0];

	$self->_trace('Entered language_code_alpha2');
	$self->_find_language() unless $self->{_slanguage};
	$self->_trace('language_code_alpha2 returns ', $self->{_slanguage_code_alpha2});
	return $self->{_slanguage_code_alpha2};
}

=head2 code_alpha2

Another name for L</language_code_alpha2>, kept so that old programs still work.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        min      => 2,
        max      => 2,
        optional => 1,
    }

=cut

sub code_alpha2 {
	my $self = $_[0];
	return $self->language_code_alpha2();
}

=head2 sublanguage_code_alpha2

Returns the two-letter code of the variant of the chosen language,
in lower case, for example C<'gb'> when the chosen language is C<en-gb>.

Returns C<undef> when there is no variant.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        min      => 2,
        max      => 2,
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb']);
    print $l->sublanguage_code_alpha2();   # "gb"

=cut

sub sublanguage_code_alpha2 {
	my $self = $_[0];

	$self->_find_language() unless $self->{_slanguage};
	return $self->{_sublanguage_code_alpha2};
}

=head2 requested_language

Returns, in English, the language that the visitor asked for,
B<whether or not your site supports it>.
Use it to tell the visitor that their language is not available.

If the visitor asked for a variant, it is shown in brackets,
for example C<'English (United Kingdom)'>. A variant that is not a known
country code is shown as it was sent, for example C<'English (Unknown: zz)'>.

Returns C<'Unknown'> when the visitor's language cannot be found at all.
It never returns C<undef>.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type => 'string',
        min  => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->language();             # "English"
    print $l->requested_language();   # "English (United Kingdom)"

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'de';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->language();             # "Unknown"
    print $l->requested_language();   # "German"

=cut

sub requested_language {
	my $self = $_[0];

	$self->_find_language() unless $self->{_rlanguage};
	# _find_language() can leave it undef; the API promises a string
	$self->{_rlanguage} //= 'Unknown';
	return $self->{_rlanguage};
}

# ── _find_language ─────────────────────────────────────────────────────────
# Purpose:      Populate _slanguage, _rlanguage, _sublanguage, and the
#               various code fields by working through the detection pipeline:
#               Accept-Language header → I18N::AcceptLanguage → IP country.
# Entry:        $self->{_slanguage} must be undef (guards repeated calls).
# Exit:         $self->{_slanguage} is set to a language name or 'Unknown'.
# Side Effects: Populates _rlanguage, _sublanguage, *_code_alpha2 fields.
sub _find_language
{
	my $self = shift;
	# Called by every language accessor; the evals and file tests below must
	# not change the caller's $@ or $!
	local ($@, $!);

	$self->_trace('Entered _find_language');

	$self->{_rlanguage} = 'Unknown';
	$self->{_slanguage} = 'Unknown';

	my $http_accept_language = $self->_what_language();

	# RFC 7231 section 5.3.1: q=0 means "not acceptable", so drop those tags
	# before matching, or "fr;q=0, en;q=0.5" would choose French.  A q value
	# outside the RFC grammar (0 to 1, at most three decimals: "q=abc",
	# "q=1e309", "q=-1") makes the tag malformed, so drop it too, rather than
	# let I18N::AcceptLanguage guess and warn.
	if(defined($http_accept_language) && ($http_accept_language =~ /;\s*q\s*=/i)) {
		my @acceptable;
		for my $tag (split(/\s*,\s*/, $http_accept_language)) {
			if($tag =~ /;\s*q\s*=\s*(\S*?)\s*\z/i) {
				my $q = $1;
				next unless $q =~ /^(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)\z/;
				next if $q == 0;
			}
			push @acceptable, $tag;
		}
		$http_accept_language = @acceptable ? join(',', @acceptable) : undef;
		$self->_debug('Accept-Language after dropping unacceptable tags: ', $http_accept_language // '(none)');
	}

	if(defined($http_accept_language)) {
		$self->_debug(
			"language wanted: $http_accept_language, "
			. 'languages supported: '
			. join(', ', @{$self->{_supported}} // '')
		);

		# Normalise the deprecated en-uk tag that some browsers send, wherever
		# it is in the list (not only when it is the whole header)
		my $sent = $http_accept_language;
		if($http_accept_language =~ s/(?<![A-Za-z0-9-])\Q$DEPRECATED_EN_UK\E(?![A-Za-z0-9-])/$CANONICAL_EN_GB/gi) {
			$self->_warn({ warning => "Resetting country code to GB for $sent" });
		}

		# Run the header through the Accept-Language resolver
		my ($l, $requested_sublanguage) =
			$self->_accept_language_match($http_accept_language);

		# Resolve the matched code to a full language/sublanguage
		if($l) {
			return if $self->_resolve_match($l, $requested_sublanguage, $http_accept_language);
		} elsif($http_accept_language =~ /;/) {
			# e.g. de-DE,de;q=0.9,en-US;q=0.8 and we support none of those
			$self->_notice(
				__PACKAGE__, ': ', __LINE__,
				": couldn't honour HTTP_ACCEPT_LANGUAGE=$http_accept_language,"
				. ' supported languages are: '
				. join(',', @{$self->{_supported}})
			);
		}

		# Last-chance: 2-char or xx-xx header where we have no match
		if(
			((!$self->{_rlanguage}) || ($self->{_rlanguage} eq 'Unknown'))
			&& ((length($http_accept_language) == 2) || ($http_accept_language =~ /^..-..$/))
		) {
			$self->{_rlanguage} = $self->_code2language($http_accept_language) || 'Unknown';
		}
		$self->{_slanguage} = 'Unknown';
	}

	return if $self->{_dont_use_ip};

	# Fall back to the official language of the visitor's country
	$self->_find_language_from_ip($http_accept_language);
}

# ── _accept_language_match ────────────────────────────────────────────────
# Purpose:      Run I18N::AcceptLanguage strict matching plus two fallback
#               left-to-right scan passes against $self->{_supported}.
# Entry:        $http_accept_language — validated, untainted Accept-Language value.
# Exit:         Returns ($matched_code, $requested_sublanguage) or (undef, undef).
# Side Effects: Logs debug messages.
sub _accept_language_match
{
	my ($self, $http_accept_language) = @_;

	my $i18n = I18N::AcceptLanguage->new(debug => $self->{_debug}, strict => 1);
	my $l;
	{
		# Suppress I18N::AcceptLanguage's uninitialized-value warnings (RT 74338)
		local $SIG{__WARN__} = _warn_filter(qr/^Use of uninitialized value/);
		$l = $i18n->accepts($http_accept_language, $self->{_supported});
	}

	# I18N-AcceptLanguage strict mode can return a sublanguage variant when
	# the request contains a sublanguage we don't support; force a retry.
	if($l && ($http_accept_language =~ /-/) && ($http_accept_language !~ qr/$l/i)) {
		$self->_debug('Forcing fallback');
		undef $l;
	}

	my $requested_sublanguage;
	if(!$l) {
		# Sort tokens by q-value once; both scan passes share the ordered list
		my $sorted = $self->_sorted_tokens($http_accept_language);
		# First fallback: scan for xx-yy pairs, try base language xx
		($l, $requested_sublanguage) =
			$self->_scan_sublanguage_pairs($i18n, $sorted);
		if(!$l) {
			# Second fallback: scan plain tokens without sublanguages
			$l = $self->_scan_plain_tokens($i18n, $sorted);
			undef $requested_sublanguage if $l;
		}
	}

	return ($l, $requested_sublanguage);
}

# ── _sorted_tokens ────────────────────────────────────────────────────────
# Purpose:      Parse an Accept-Language header into tokens sorted by
#               descending quality value so fallback scans honour q= priority.
# Entry:        $header — validated Accept-Language string.
# Exit:         Arrayref of [$language_tag, $quality] pairs, highest q first.
sub _sorted_tokens
{
	my ($self, $header) = @_;
	my @tokens;
	for my $token (split /,/, $header) {
		$token =~ s/^\s+|\s+$//g;
		my $q = 1.0;
		if($token =~ s/;\s*q\s*=\s*(\d+(?:\.\d+)?)//) {
			$q = $1 + 0;
		}
		$token =~ s/^\s+|\s+$//g;
		push @tokens, [$token, $q] if length $token;
	}
	return [sort { $b->[1] <=> $a->[1] } @tokens];
}

# ── _scan_sublanguage_pairs ───────────────────────────────────────────────
# Purpose:      Walk q-sorted tokens looking for xx-yy pairs; try accepting
#               the base language xx from the supported list.
# Entry:        $i18n — I18N::AcceptLanguage instance;
#               $sorted — arrayref from _sorted_tokens.
# Exit:         ($matched_code, $sublanguage_code) or (undef, undef).
# Side Effects: Debug logging.
sub _scan_sublanguage_pairs
{
	my ($self, $i18n, $sorted) = @_;

	$self->_debug(__PACKAGE__, ': ', __LINE__, ': scan q-sorted tokens for xx-yy pairs');
	for my $entry (@{$sorted}) {
		my ($tag) = @{$entry};
		next unless $tag =~ /^(..)-(..)$/;
		my ($base, $sub) = ($1, $2);
		$self->_debug(__PACKAGE__, ': ', __LINE__, ": see if $base is supported");
		if($i18n->accepts($base, $self->{_supported})) {
			$self->_debug("Fallback to $base as sublanguage $sub is not supported");
			return ($base, $sub);
		}
	}
	return (undef, undef);
}

# ── _scan_plain_tokens ────────────────────────────────────────────────────
# Purpose:      Walk q-sorted tokens that have no sublanguage suffix and try
#               accepting each against the supported list.
# Entry:        $i18n — I18N::AcceptLanguage instance;
#               $sorted — arrayref from _sorted_tokens.
# Exit:         Matched code string, or undef.
# Side Effects: Debug logging.
sub _scan_plain_tokens
{
	my ($self, $i18n, $sorted) = @_;

	$self->_debug(__PACKAGE__, ': ', __LINE__, ': scan q-sorted tokens for plain alternatives');
	for my $entry (@{$sorted}) {
		my ($tag) = @{$entry};
		next if $tag =~ /^..-../;    # already tried in the pair scan
		$self->_debug(__PACKAGE__, ': ', __LINE__, ": see if $tag is supported");
		if($i18n->accepts($tag, $self->{_supported})) {
			$self->_debug("Fallback to $tag as best alternative");
			return $tag;
		}
	}
	return;
}

# ── _resolve_match ────────────────────────────────────────────────────────
# Purpose:      Given a matched code $l (possibly xx or xx-yy), populate all
#               of _slanguage, _rlanguage, _sublanguage and their code fields.
# Entry:        $l — 2-char or xx-yy language code; $requested_sublanguage —
#               2-char variety code or undef; $http_accept_language — full header.
# Exit:         Returns true (1) if the caller should return immediately.
# Side Effects: Mutates $self->{_slanguage}, _rlanguage, _sublanguage, etc.
sub _resolve_match
{
	my ($self, $l, $requested_sublanguage, $http_accept_language) = @_;

	$self->_debug("l: $l");

	if($l !~ /^..-../) {
		# Base-language match (e.g. 'en') — no sublanguage component
		return $self->_resolve_base_match($l, $requested_sublanguage, $http_accept_language);
	} elsif($l =~ /(.+)-(..)$/) {
		# Sublanguage match (e.g. 'en-gb') — resolve both language and variant
		return $self->_resolve_sublanguage_match($l, $1, $2, $http_accept_language);
	}
	return 0;
}

# ── _resolve_base_match ───────────────────────────────────────────────────
# Purpose:      Handle the case where a base-language code matched (no hyphen).
#               Sets _slanguage, _rlanguage; appends sublanguage name to rlanguage
#               when the client requested one we don't support.
# Entry:        $l — 2-char code; $requested_sublanguage — optional; $header.
# Exit:         1 to signal caller should return, 0 otherwise.
# Side Effects: Mutates slanguage, rlanguage, slanguage_code_alpha2.
sub _resolve_base_match
{
	my ($self, $l, $requested_sublanguage, $header) = @_;

	$self->{_slanguage} = $self->_code2language($l);
	return 0 unless $self->{_slanguage};

	$self->_debug("_slanguage: $self->{_slanguage}");
	$self->{_slanguage_code_alpha2} = $l;
	$self->{_rlanguage}             = $self->{_slanguage};

	# Attempt to name the sublanguage the client actually asked for
	my $sl;
	if($header =~ /..-(..)$/) {
		$self->_debug($1);
		$sl = $self->_code2country($1);
		$requested_sublanguage //= $1;
	} elsif($header =~ /..-([a-z]{2,3})$/i) {
		if($_locale_object_db_ok // 1) {
			eval { $sl = Locale::Object::Country->new(code_alpha3 => $1) };
			if($@) {
				$_locale_object_db_ok = 0 if $@ =~ /database was not in/;
				$self->_info($@);
			} else {
				$_locale_object_db_ok = 1;
			}
		}
	}

	if($sl) {
		$self->{_rlanguage} .= ' (' . $sl->name() . ')';
	} elsif($requested_sublanguage) {
		if(my $c = $self->_code2countryname($requested_sublanguage)) {
			$self->{_rlanguage} .= " ($c)";
		} else {
			$self->{_rlanguage} .= " (Unknown: $requested_sublanguage)";
		}
	}
	return 1;
}

# ── _resolve_sublanguage_match ────────────────────────────────────────────
# Purpose:      Handle the case where the full xx-yy code matched in the
#               supported list.  Resolves the variety name and caches results.
# Entry:        $l — full code e.g. 'en-gb'; $alpha2 — 'en'; $variety — 'gb';
#               $header — full Accept-Language value.
# Exit:         1 to signal caller should return, 0 otherwise.
# Side Effects: Mutates _slanguage, _rlanguage, _sublanguage and code fields;
#               writes to cache.
sub _resolve_sublanguage_match
{
	my ($self, $l, $alpha2, $variety, $header) = @_;

	my $i18n    = I18N::AcceptLanguage->new(strict => 1);
	my $accepts = $i18n->accepts($l, $self->{_supported});
	$self->_debug('accepts = ', $accepts // 'undef');

	# $l is an entry of the supported list with a hyphen (e.g. 'en-gb'), so a
	# strict match always gives back that same hyphenated entry.  (An earlier
	# branch for a hyphen-less answer could never run, and was removed.)
	delete $self->{_slanguage} if $accepts;

	# Accepts returned something but we couldn't resolve a language name —
	# try harder using the variety code directly
	$self->{_rlanguage} = $self->_code2language($alpha2);
	$self->_debug("_rlanguage: $self->{_rlanguage}");

	return 0 unless $accepts;

	$self->_debug("http_accept_language = $header");
	$l =~ /(..)-(..)/;
	$variety = lc($2);

	# Skip numeric/region codes like en-029
	if(($variety =~ /[a-z]{2,3}/) && !defined($self->{_sublanguage})) {
		$self->_get_closest($alpha2, $alpha2);
		$self->_debug("Find the country code for $variety");

		my ($from_cache, $language_name, $db_error);
		if($self->{_cache}) {
			$from_cache = $self->_cache_get_valid($CACHE_NS . "variety:$variety", $NAME_CODE_RE);
		}

		if(defined($from_cache)) {
			$self->_debug("$variety is in cache as $from_cache");
			# Cache stores "countryname=langcode" (e.g. "United Kingdom=en").
			# Splitting on = gives the country name as the first field.
			($language_name) = split(/=/, $from_cache);
			# A poisoned entry such as "=en" has an empty name; treat it as a miss
			undef $language_name unless defined($language_name) && length($language_name);
		} elsif($_locale_object_db_ok // 1) {
			# Locale::Object's SQLite database is absent on some Windows
			# installations; the sentinel avoids repeated failed new() calls.
			# Keep the error in a lexical: $@ itself may still hold an
			# unrelated error from the caller when this branch is skipped.
			eval {
				my $db = Locale::Object::DB->new();
				my @results = @{$db->lookup(
					table         => 'country',
					result_column => 'name',
					search_column => 'code_alpha2',
					value         => $variety
				)};
				$_locale_object_db_ok = 1;
				if(defined($results[0])) {
					$language_name = $self->_code2countryname($variety);
				} else {
					$self->_debug("Can't find the country code for $variety in Locale::Object::DB");
				}
				1;
			} or $db_error = ($@ || 'unknown error');
			if($db_error) {
				$_locale_object_db_ok = 0
					if $db_error =~ /database was not in/;
				# fall through: $language_name stays undef, caught below
			}
		}

		if($db_error || !defined($language_name)) {
			$self->_warn({ warning => $db_error }) if $db_error;
			# Locale::Object DB may be absent (common on Windows CI); fall back to
			# the short-name table / Locale::Codes before giving up.
			$language_name = $self->_country_short_name($variety);
		}
		if(!defined($language_name)) {
			$self->_debug(__PACKAGE__, ': ', __LINE__, ': setting sublanguage to Unknown');
			$self->{_sublanguage} = 'Unknown';
			$self->_warn({ warning => "Can't determine values for $header" });
		} else {
			$self->{_sublanguage} = $language_name;
			$self->_debug('variety name ', $self->{_sublanguage});
			if($self->{_cache} && !defined($from_cache)) {
				# Store "countryname=langcode" so future cache hits return the country
				# name in the first field.  Previously this stored the language name
				# ("English=en" for en-gb) which was wrong — the cache-hit branch
				# split on = and used the first field as the sublanguage (country) name.
				$self->_debug("Set variety:$variety to $language_name=$self->{_slanguage_code_alpha2}");
				$self->_cache_call($self->{_cache}, 'set',
					$CACHE_NS . "variety:$variety",
					"$language_name=$self->{_slanguage_code_alpha2}",
					$CACHE_TTL_LONG
				);
			}
		}
	}

	if(defined($self->{_sublanguage})) {
		$self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
		$self->{_sublanguage_code_alpha2} = $variety;
		return 1;
	}
	return 0;
}

# ── _find_language_from_ip ────────────────────────────────────────────────
# Purpose:      Fall back to the visitor's IP country when the Accept-Language
#               header produced no usable match.  Looks up the official language
#               of the country and checks it against the supported list.
# Entry:        $http_accept_language — may be undef if no header was present.
# Exit:         Mutates _slanguage, _rlanguage via _get_closest if a match found.
# Side Effects: Calls country(); may write to cache.
sub _find_language_from_ip
{
	my ($self, $http_accept_language) = @_;

	my $country = $self->country();

	# If country() returned nothing, try to derive from the LANG env var
	if(!defined($country) && (my $c = $self->_what_language())) {
		if($c =~ /^(..)_(..)/) {
			$country = $2;
		} elsif($c =~ /^(..)$/) {
			$country = $1;
		}
	}
	return unless defined $country;

	$self->_debug("country: $country");

	my ($language_name, $language_code2, $from_cache);
	if($self->{_cache}) {
		$from_cache = $self->_cache_get_valid($CACHE_NS . 'language_name:' . $country, $NAME_CODE_RE);
	}

	if($from_cache) {
		$self->_debug("$country is in cache as $from_cache");
		($language_name, $language_code2) = split(/=/, $from_cache);
	} else {
		my $l = $self->_code2country(uc($country));
		if($l) {
			$l = ($l->languages_official)[0];
			if(defined $l) {
				$language_name  = $l->name;
				$language_code2 = $l->code_alpha2;
				$self->_debug("Official language: $language_name") if $language_name;
			}
		}
	}

	# REMOTE_ADDR is absent when the country came from LANG (command-line use)
	my $ip = $ENV{'REMOTE_ADDR'} // '(none)';
	return unless $language_name;

	if((!defined($self->{_rlanguage})) || ($self->{_rlanguage} eq 'Unknown')) {
		$self->{_rlanguage} = $language_name;
	}

	unless((exists $self->{_slanguage}) && ($self->{_slanguage} ne 'Unknown')) {
		my $code;

		if($language_name && $language_code2 && !defined($http_accept_language)) {
			# Fast-path for search engines that hit with no Accept-Language
			$self->_debug("Fast assign to $language_code2");
			$code = $language_code2;
		} else {
			$self->_debug("Call language2code on $self->{_rlanguage}");
			$code = Locale::Language::language2code($self->{_rlanguage});

			unless($code) {
				if($http_accept_language && ($http_accept_language ne $self->{_rlanguage})) {
					$self->_debug("Call language2code on $http_accept_language");
					$code = Locale::Language::language2code($http_accept_language);
				}
				unless($code) {
					# Norwegian (Nynorsk) — strip the parenthetical qualifier
					if($self->{_rlanguage} =~ /(.+)\s\(.+/) {
						if((!defined($http_accept_language)) || ($1 ne $self->{_rlanguage})) {
							$self->_debug("Call language2code on $1");
							$code = Locale::Language::language2code($1);
						}
					}
					unless($code) {
						$self->_warn({
							warning => "Can't determine code from IP $ip for requested language $self->{_rlanguage}"
						});
					}
				}
			}
		}

		if($code) {
			$self->_get_closest($code, $language_code2);
			unless($self->{_slanguage}) {
				$self->_warn({
					warning => "Couldn't determine closest language for $language_name in "
						. join(', ', @{$self->{_supported}})
				});
			} else {
				$self->_debug("language set to $self->{_slanguage}, code set to $code");
			}
		}
	}

	if(!defined($self->{_slanguage_code_alpha2})) {
		$self->_debug("Can't determine slanguage_code_alpha2");
	} elsif(!defined($from_cache) && $self->{_cache} && defined($self->{_slanguage_code_alpha2})) {
		$self->_debug("Set $country to $language_name=$self->{_slanguage_code_alpha2}");
		$self->_cache_call($self->{_cache}, 'set',
			$CACHE_NS . 'language_name:' . $country,
			"$language_name=$self->{_slanguage_code_alpha2}",
			$CACHE_TTL_LONG
		);
	}
}

# ── _get_closest ─────────────────────────────────────────────────────────
# Purpose:      If $language_string matches the base language of any supported
#               entry, set _slanguage and _slanguage_code_alpha2.
# Entry:        $language_string — base code e.g. 'en'; $alpha2 — same or variant.
# Exit:         Mutates _slanguage and _slanguage_code_alpha2 on match.
sub _get_closest
{
	my ($self, $language_string, $alpha2) = @_;

	# Map each supported entry to its base language code
	my %base_languages =
		map { /^(.+)-/ ? ($1 => $_) : ($_ => $_) } @{$self->{_supported}};

	if(exists $base_languages{$language_string}) {
		$self->{_slanguage}             = $self->{_rlanguage};
		$self->{_slanguage_code_alpha2} = $alpha2;
	}
}

# ── _what_language ────────────────────────────────────────────────────────
# Purpose:      Return the raw (validated, untainted) Accept-Language string,
#               consulting in priority order: cached value, CGI lang= param,
#               HTTP_ACCEPT_LANGUAGE env var, LANG env var (local/debug mode).
# Entry:        May be called as a class method (no $self->{...} access) or
#               as an object method.
# Exit:         A validated language string, or undef if nothing available.
# Side Effects: Caches result in $self->{_what_language} on object calls.
sub _what_language {
	my $self = $_[0];

	if(ref($self)) {
		$self->_trace('Entered _what_language');
		if(defined($self->{_what_language})) {
			$self->_trace('_what_language: returning cached value: ', $self->{_what_language});
			return $self->{_what_language};
		}
		if(my $info = $self->{_info}) {
			if(my $rc = _info_lang($info, $self)) {
				$self->_trace("_what_language set language to $rc from the lang argument");
				return $self->{_what_language} = $rc;
			}
		}
	}

	if(my $raw_lang = $ENV{'HTTP_ACCEPT_LANGUAGE'}) {
		# Validate and untaint — RFC 7231 §5.3.5 character set plus * wildcard.
		# Spaces and tabs only, not \s: CR and LF would carry header, log-line
		# and Memcached-command injection into the cache key and messages.
		if($raw_lang =~ $ACCEPT_LANG_RE) {
			my $rc = $1;    # untainted
			if(ref($self)) {
				return $self->{_what_language} = $rc;
			}
			return $rc;
		} elsif(ref($self)) {
			$self->_warn({ warning => 'HTTP_ACCEPT_LANGUAGE contains invalid characters; ignoring' });
		}
	}

	if(defined($ENV{'LANG'})) {
		# Running locally (debug mode) — derive from system locale.
		# Apply the same untainting discipline as HTTP_ACCEPT_LANGUAGE: only
		# alphanumeric, hyphen, underscore, and dot are legitimate in a POSIX
		# locale name (e.g. "en_US.UTF-8", "de_DE", "ja").  Anything else is
		# either malformed or an injection attempt; discard it silently.
		if($ENV{'LANG'} =~ /^([A-Za-z0-9_.\-]{1,$ACCEPT_LANG_MAX})$/a) {
			my $rc = $1;    # untainted
			if(ref($self)) {
				return $self->{_what_language} = $rc;
			}
			return $rc;
		} elsif(ref($self)) {
			$self->_warn({ warning => 'LANG contains invalid characters; ignoring' });
		}
	}
	return;
}

=head2 country

Returns the two-letter country code (ISO 3166-1) of the visitor,
in lower case, for example C<'us'>, C<'gb'> or C<'fr'>.

Returns C<undef> when the country cannot be found, for example when
C<REMOTE_ADDR> is not set, is not a valid IP address, or is a private
(C<192.168.1.1>) or loopback (C<127.0.0.1>) address.

In one special case it returns the string C<'Unknown'>:
when a source says the address is in the European Union (C<EU>),
which is not a country.

Two answers are corrected: C<hk> (Hong Kong) is returned as C<cn>, and a Whois
record that says C<US> with the state C<PR> is returned as C<pr> (Puerto Rico
has its own country code; RT#131347).

See L</Finding the country> for the order in which the sources are tried.
If you have none of L<IP::Country>, L<Geo::IP> or L<Geo::IPfree> installed,
every look-up goes over the network, so please use a C<cache> (see L</new>).

The answer is remembered, so a second call on the same object is fast.

Note that as of October 2026 geoplugin.net, one of the remote
fallbacks, no longer has a free tier: it answers with an HTTP 403 and
a "please upgrade to a paid plan" message, which contains no country
code, so the lookup falls through to Whois.
The geoplugin.net code is kept in case that changes.

Legacy MaxMind F<GeoIP.dat> databases, as used by L<Geo::IP>, are no
longer updated (Debian's C<geoip-database> package is frozen at
2019-12-24), so they can give the wrong country for addresses that
have been reallocated since then.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        matches  => qr/^(?:[a-z][a-z]|Unknown)$/,
        optional => 1,
    }

=head3 EXAMPLE

    # Behind Apache mod_geoip: no IP look-up is needed
    local $ENV{GEOIP_COUNTRY_CODE} = 'DE';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->country();   # "de"

    # From the IP address (the answer depends on your geo database)
    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->country() // 'not known';   # "us"

=head3 MESSAGES

These are warnings. C<country()> does not die.

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

These are debug messages, sent only to the logger:

    "Can't determine country from LAN connection X"
    "Can't determine country from loopback connection X"

=head3 PSEUDOCODE

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

=cut

sub country {
	my $self = shift;
	local ($@, $!);	# evals and lazy requires below must not leak to the caller

	$self->_trace(__PACKAGE__, ': Entered country()');

	# Return cached result immediately if a previous call already resolved it.
	# Note: undef results (private/loopback IPs) are NOT cached here because
	# country() reads REMOTE_ADDR at call time, not construction time; caching
	# undef would give wrong answers if REMOTE_ADDR changes between calls on
	# the same object (the documented lazy-read design).  See LIMITATIONS.
	if($self->{_country}) {
		$self->_trace('quick return: ', $self->{_country});
		return $self->{_country};
	}

	# mod_geoip: validate against ISO 3166-1 alpha-2 before trusting
	if(defined($ENV{'GEOIP_COUNTRY_CODE'})) {
		if($ENV{'GEOIP_COUNTRY_CODE'} =~ /^([A-Z]{2})\z/a) {
			$self->{_country} = lc($1);
			return $self->{_country};
		} else {
			$self->_warn({ warning => 'GEOIP_COUNTRY_CODE contains an invalid country code; ignoring' });
		}
	}

	# Cloudflare: 'XX' means Cloudflare couldn't determine country — skip it
	if(($ENV{'HTTP_CF_IPCOUNTRY'}) && ($ENV{'HTTP_CF_IPCOUNTRY'} ne 'XX')) {
		if($ENV{'HTTP_CF_IPCOUNTRY'} =~ /^([A-Z]{2})\z/a) {
			$self->{_country} = lc($1);
			return $self->{_country};
		} else {
			$self->_warn({ warning => 'HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring' });
		}
	}

	my $raw_ip = $ENV{'REMOTE_ADDR'};
	return undef unless defined $raw_ip;

	# Validate and untaint the IP address before passing to any geo module
	my $ip = _untaint_ip($raw_ip);
	unless(defined($ip)) {
		$self->_warn({ warning => "$raw_ip isn't a valid IP address" });
		return undef;
	}

	# Data::Validate::IP depends on NetAddr::IP, which fails to build on Windows
	# (NetAddr::IP::UtilPP::mask4to6 bad-argument error).  Try to load it once;
	# on failure install pure-Perl aliases for the four bare function names used
	# below so the rest of the function is unchanged on both platforms.
	# Import only those four: a plain import() installs all 29 of the module's
	# exports here, where they would become methods of every object.
	if(!defined($_have_dvip)) {
		local $SIG{__DIE__};
		if(eval { require Data::Validate::IP; Data::Validate::IP->import(qw(is_ipv4 is_ipv6 is_private_ip is_loopback_ip)); 1 }) {
			$_have_dvip = 1;
		} else {
			$_have_dvip = 0;
			no warnings 'redefine';
			*CGI::Lingua::is_ipv4       = \&_is_ipv4;
			*CGI::Lingua::is_ipv6       = \&_is_ipv6;
			*CGI::Lingua::is_private_ip  = \&_is_private_ip;
			*CGI::Lingua::is_loopback_ip = \&_is_loopback_ip;
		}
	}

	if(!is_ipv4($ip)) {
		$self->_debug("$ip isn't IPv4. Is it IPv6?");
		if($ip eq '::1') {
			$ip = '127.0.0.1';    # normalise loopback
		} elsif($ip =~ /^::ffff:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/i) {
			$ip = $1;             # normalise IPv4-mapped IPv6 (::ffff:a.b.c.d) to plain IPv4
			# \d{1,3} matches 0-999; validate range before geo lookups because
			# some inet_aton implementations wrap out-of-range octets modulo 256,
			# turning 999.999.999.999 into a real routable address.
			unless(is_ipv4($ip)) {
				$self->_warn({ warning => "$ip isn't a valid IP address" });
				return undef;
			}
		} elsif(!is_ipv6($ip)) {
			$self->_warn({ warning => "$ip isn't a valid IP address" });
			return undef;
		}
	}
	if(is_private_ip($ip)) {
		$self->_debug("Can't determine country from LAN connection $ip");
		return undef;
	}
	if(is_loopback_ip($ip)) {
		$self->_debug("Can't determine country from loopback connection $ip");
		return undef;
	}

	# Cache look-up — skip for LAN/loopback (already returned above)
	if($self->{_cache}) {
		$self->{_country} = $self->_cache_call($self->{_cache}, 'get', $CACHE_NS . "country:$ip");
		if(defined($self->{_country})) {
			if(!ref($self->{_country}) && ($self->{_country} !~ /\D/)) {
				$self->_warn({ warning => 'cache contains a numeric country: ' . $self->{_country} });
				$self->_cache_call($self->{_cache}, 'remove', $CACHE_NS . "country:$ip");
				delete $self->{_country};
			} elsif(ref($self->{_country}) || ($self->{_country} !~ $COUNTRY_RE)) {
				# Poisoned entry ("gb<script>", a hashref): same checks as a
				# fresh look-up, or the cache would bypass them
				$self->_warn({ warning => "Discarding malformed cache entry for ${CACHE_NS}country:$ip" });
				$self->_cache_call($self->{_cache}, 'remove', $CACHE_NS . "country:$ip");
				delete $self->{_country};
			} else {
				$self->_debug("Get $ip from cache = $self->{_country}");
				return $self->{_country};
			}
		}
		$self->_debug("$ip isn't in the cache");
	}

	# Try IP::Country first (fastest, local database)
	if($self->{_have_ipcountry} == $GEO_UNKNOWN) {
		if(eval { require IP::Country::Fast }) {
			# Require the concrete class directly; IP::Country->import() is not needed
			# because IP::Country::Fast->new() is a fully-qualified class method call.
			$self->{_have_ipcountry} = $GEO_PRESENT;
			$self->{_ipcountry}      = IP::Country::Fast->new();
		} else {
			$self->{_have_ipcountry} = $GEO_ABSENT;
		}
	}
	$self->_debug("have_ipcountry $self->{_have_ipcountry}");

	if($self->{_have_ipcountry}) {
		$self->{_country} = $self->{_ipcountry}->inet_atocc($ip);
		if($self->{_country}) {
			$self->{_country} = lc($self->{_country});
		} elsif(is_ipv4($ip)) {
			$self->_debug("$ip is not known by IP::Country");
		}
	}

	# Try Geo::IP if IP::Country gave nothing
	unless(defined($self->{_country})) {
		if($self->{_have_geoip} == $GEO_UNKNOWN) {
			$self->_load_geoip();
		}
		if($self->{_have_geoip} == $GEO_PRESENT) {
			$self->{_country} = $self->{_geoip}->country_code_by_addr($ip);
		}

		# Geo::IPfree has a known-broken entry for $BROKEN_GEOIPFREE
		if(!defined($self->{_country}) && ($ip ne $BROKEN_GEOIPFREE)) {
			if($self->{_have_geoipfree} == $GEO_UNKNOWN) {
				eval { require Geo::IPfree };
				unless($@) {
					# No ->import(): Geo::IPfree uses only OO (->LookUp); the old
					# Geo::IPfree::IP->import() call was a wrong package and could
					# clobber Test::Mockingbird mocks on some versions.
					$self->{_have_geoipfree} = $GEO_PRESENT;
					$self->{_geoipfree}      = Geo::IPfree->new();
				} else {
					$self->{_have_geoipfree} = $GEO_ABSENT;
				}
			}
			if($self->{_have_geoipfree} == $GEO_PRESENT) {
				if(my $country = ($self->{_geoipfree}->LookUp($ip))[0]) {
					$self->{_country} = lc($country);
				}
			}
		}
	}

	# 'eu' is not a real country — discard
	if($self->{_country} && ($self->{_country} eq 'eu')) {
		delete $self->{_country};
	}

	# Remote JSON lookup via geoplugin
	if((!$self->{_country}) &&
	   (eval { require LWP::Simple::WithCache; require JSON::Parse })) {
		$self->_debug("Look up $ip on geoplugin");

		# A timeout or connection error must not take down the request;
		# fall through to Whois instead
		my $data = eval { local $SIG{__DIE__}; LWP::Simple::WithCache::get("https://www.geoplugin.net/json.gp?ip=$ip") };
		$self->_warn({ warning => "geoplugin lookup failed: $@" }) if $@;
		if($data) {
			eval { $self->{_country} = JSON::Parse::parse_json($data)->{'geoplugin_countryCode'} };
			$self->_warn({ warning => "geoplugin returned unparseable JSON: $@" }) if $@;
		}

		# Check the answer now rather than at the end: a junk value (an object,
		# "GB<script>") is true, so it would stop the Whois fallback below and
		# then be thrown away, leaving no country at all
		my $v = $self->{_country};
		if(defined($v) && (ref($v) || $v !~ /^[A-Za-z]{2}\z/)) {
			if(!ref($v) && length($v) && ($v !~ /\D/)) {
				$self->_warn({ warning => 'IP matches to a numeric country' });
			} elsif(ref($v) || length($v)) {
				$self->_warn({ warning => q{Discarding malformed country code '} . lc($v) . q{'} });
			}
			delete $self->{_country};
		}
	}

	# Last resort: Whois
	unless($self->{_country}) {
		$self->_resolve_country_via_whois($ip);
	}

	# Sanitise and normalise whatever we found
	if($self->{_country}) {
		if($self->{_country} !~ /\D/) {
			$self->_warn({ warning => 'IP matches to a numeric country' });
			delete $self->{_country};
		} else {
			$self->{_country} = lc($self->{_country});

			# Legacy mappings
			if($self->{_country} eq 'hk') {
				$self->{_country} = 'cn';    # HK is no longer a separate country in Whois
			} elsif($self->{_country} eq 'eu') {
				$self->_handle_eu_country($ip);
			}

			if($self->{_country} && ($self->{_country} !~ /\D/)) {
				$self->_warn({ warning => "cache contains a numeric country: $self->{_country}" });
				delete $self->{_country};
			} elsif($self->{_country} &&
				$self->{_country} ne 'Unknown' &&
				($self->{_country} !~ /^[a-z]{2}$/)) {
				# Reject anything that is not exactly 2 lowercase ASCII letters,
				# unless it is the 'Unknown' sentinel written by _handle_eu_country
				# for EU addresses that do not map to a specific country.
				# Guards against Whois CRLF injection leftovers ("gbx-header: evil")
				# and XSS payloads in JSON API responses ("gb<script>...</script>").
				$self->_warn({ warning => "Discarding malformed country code '$self->{_country}'" });
				delete $self->{_country};
			} elsif($self->{_country} && $self->{_cache}) {
				$self->_debug("Set $ip to $self->{_country}");
				$self->_cache_call($self->{_cache}, 'set',
					$CACHE_NS . "country:$ip",
					$self->{_country},
					$CACHE_TTL_SHORT
				);
			}
		}
	}

	return $self->{_country};
}

# ── _resolve_country_via_whois ─────────────────────────────────────────────
# Purpose:      Attempt Net::Whois::IP then Net::Whois::IANA as a last resort.
# Entry:        $ip — validated, untainted IP string.
# Exit:         Sets $self->{_country} if a result was found.
# Side Effects: Network I/O; logs debug messages.
sub _resolve_country_via_whois
{
	my ($self, $ip) = @_;

	$self->_debug("Look up $ip on Whois");

	require Net::Whois::IP;
	# No ->import(): whoisip_query is called fully-qualified, so import is unneeded
	# and on some versions reinstalls the real function, clobbering Test::Mockingbird mocks.

	my $whois;
	eval {
		# Catch connection timeouts by converting Carp::carp into a die
		local $SIG{__WARN__} = sub { die $_[0] };
		$whois = Net::Whois::IP::whoisip_query($ip);
	};

	unless($@ || !defined($whois) || (ref($whois) ne 'HASH')) {
		if(defined($whois->{Country})) {
			$self->{_country} = $whois->{Country};
		} elsif(defined($whois->{country})) {
			$self->{_country} = $whois->{country};
		}
		if($self->{_country}) {
			if($self->{_country} eq 'EU') {
				delete $self->{_country};
			} elsif(($self->{_country} eq 'US') && defined($whois->{'StateProv'}) && ($whois->{'StateProv'} eq 'PR')) {
				# RT#131347: Puerto Rico is not the US
				$self->{_country} = 'pr';
			}
		}
	}

	if($self->{_country}) {
		$self->_debug("Found $ip on Net::Whois::IP as ", $self->{_country});
		$self->{_country} = _clean_country_code($self->{_country});
		# _clean_country_code returns undef for malformed values (e.g. CRLF
		# injection leftovers); if so, fall through to the IANA look-up.
		return if defined $self->{_country};
		delete $self->{_country};
	}

	$self->_debug("Look up $ip on IANA");

	require Net::Whois::IANA;
	# No ->import(): Net::Whois::IANA->new() is a class method; import not needed.

	# The whole IANA exchange is in one eval: new(), the query and the parse
	# of the answer can all die on a network or protocol error, and this is
	# the last resort, so a failure simply means "no country"
	my $country;
	if(eval {
		local $SIG{__DIE__};
		my $iana = Net::Whois::IANA->new();
		$iana->whois_query(-ip => $ip);
		$country = $iana->country();
		1;
	}) {
		$self->{_country} = $country;
		$self->_debug("IANA reports $ip as ", $self->{_country});
	} else {
		$self->_debug("IANA look-up of $ip failed: $@");
	}

	if($self->{_country}) {
		$self->{_country} = _clean_country_code($self->{_country});
		delete $self->{_country} unless defined $self->{_country};
	}
}

# ── _clean_country_code ───────────────────────────────────────────────────
# Purpose:      Strip carriage returns and trailing "#…" comments that some
#               Whois servers append to their country field
#               (e.g. "US\r", "GB # United Kingdom").
# Entry:        $raw — raw country string from a Whois response.
# Exit:         Cleaned 2-char country code string.
sub _clean_country_code
{
	my ($raw) = @_;
	return unless defined($raw);
	$raw =~ s/[\r\n]//g;
	# Accept exactly 2 alpha chars, optionally followed by whitespace and a
	# comment (e.g. "GB # United Kingdom").  Anything else (CRLF injection
	# leftovers, embedded headers) returns undef so the caller can discard it
	# rather than propagating a malformed string through the geo pipeline.
	if($raw =~ /^([A-Za-z]{2})\s*(?:#.*)?$/) {
		return $1;
	}
	return;
}

# ── _in_baidu_subnet ──────────────────────────────────────────────────────
# Purpose:      Pure-Perl fallback check for the Baidu IPv4 subnet
#               185.10.104.0/22.  Used when Net::Subnet is absent (e.g. on
#               Windows where its Socket6 dependency fails to build).
# Entry:        $ip — untainted IPv4 string.
# Exit:         Returns true if $ip is within the /22 block, false otherwise.
sub _in_baidu_subnet
{
	my $ip = shift;
	return 0 unless defined($ip) && $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/a;
	# pack('C') wraps octets above 255 (300 becomes 44), which would put a
	# malformed address such as 185.10.104.300 inside the subnet
	return 0 if grep { $_ > 255 } ($1, $2, $3, $4);
	# pack/unpack avoids signed-integer overflow on 32-bit Perl
	my $n   = unpack('N', pack('C4', $1, $2, $3, $4));
	my $net = unpack('N', pack('C4', 185, 10, 104, 0));
	return (($n & 0xFFFFFC00) == ($net & 0xFFFFFC00));
}

# ── _handle_eu_country ────────────────────────────────────────────────────
# Purpose:      Resolve the ambiguous 'eu' country code.  RT-86809 shows that
#               Baidu reports itself as EU when it is actually in CN.  All
#               other 'eu' addresses are logged as Unknown.
# Entry:        $ip — validated, untainted IP string.
# Exit:         Sets $self->{_country} to 'cn' or 'Unknown'.
# Side Effects: Optionally loads Net::Subnet; writes info log entry.
sub _handle_eu_country
{
	my ($self, $ip) = @_;

	# Prefer Net::Subnet for correctness; fall back to the pure-Perl helper
	# when it is absent (Socket6, its indirect dep, fails to build on Windows).
	my $in_baidu;
	if(eval { require Net::Subnet; Net::Subnet->import(); 1 }) {
		$in_baidu = subnet_matcher($BAIDU_SUBNET)->($ip);
	} else {
		$in_baidu = _in_baidu_subnet($ip);
	}

	if($in_baidu) {
		$self->{_country} = 'cn';
	} else {
		$self->_info("$ip has country of eu");
		$self->{_country} = 'Unknown';
	}
}

# ── _load_geoip ───────────────────────────────────────────────────────────
# Purpose:      Probe for the Geo::IP database file and the Geo::IP module;
#               set _have_geoip and initialise _geoip on success.
# Entry:        _have_geoip must be GEO_UNKNOWN.
# Exit:         _have_geoip set to GEO_PRESENT or GEO_ABSENT.
# Side Effects: Requires Geo::IP; opens GeoIP.dat.
sub _load_geoip
{
	my $self = shift;

	# Check for the database file before even trying to load the module
	# (avoids noisy errors on Windows — CPANTESTERS report 54117bd0)
	my ($dat) = grep { -f $_ && -r _ } @GEOIP_DAT;
	unless(defined($dat)) {
		$self->{_have_geoip} = $GEO_ABSENT;
		return;
	}

	unless(eval { local $SIG{__DIE__}; require Geo::IP; 1 }) {
		$self->{_have_geoip} = $GEO_ABSENT;
		return;
	}

	# No ->import(): Geo::IP->open() is a class method.  GEOIP_STANDARD = 0
	# (the constant cannot be used by name).  A corrupt or truncated file makes
	# open() die or return undef; treat that as no database, rather than let
	# country() call a method on undef later.
	my $geoip = eval { local $SIG{__DIE__}; Geo::IP->open($dat, 0) };
	if(Scalar::Util::blessed($geoip)) {
		$self->{_have_geoip} = $GEO_PRESENT;
		$self->{_geoip}      = $geoip;
	} else {
		$self->_warn({ warning => "Can't open $dat with Geo::IP; not using it" });
		$self->{_have_geoip} = $GEO_ABSENT;
	}
}

=head2 locale

Returns a L<Locale::Object::Country> object for the visitor's country.
You can use it to find, for example, the currency or the country's name.

HTTP does not send a browser's local settings (such as the currency or the
date format), so this is a B<best guess>. It is not always right.

It tries these, in order:

=over 4

=item 1. A language tag such as C<en-GB> inside the C<HTTP_USER_AGENT> string.

=item 2. L<HTTP::BrowserDetect>, if it is installed.

=item 3. L</country>.

=item 4. C<GEOIP_COUNTRY_CODE>.

=back

Returns C<undef> when nothing is found.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'object',
        isa      => 'Locale::Object::Country',
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    my $l = CGI::Lingua->new(supported => ['en']);
    if(my $locale = $l->locale()) {
        print $locale->name(), "\n";              # e.g. "United States"
        print $locale->currency()->code(), "\n";  # e.g. "USD"
    }

=head3 MESSAGES

    "HTTP_USER_AGENT contains invalid characters or exceeds length limit; ignoring"

=head3 PSEUDOCODE

    1. Return the remembered answer if there is one
    2. Parse HTTP_USER_AGENT parenthetical for xx-YY language tag
    3. Try HTTP::BrowserDetect on the full User-Agent string
    4. Fall back to country() IP lookup
    5. Fall back to GEOIP_COUNTRY_CODE env var (ISO 3166-1 validated)
    6. Return undef if all strategies fail

=cut

sub locale {
	my $self = shift;
	local ($@, $!);	# evals below must not leak to the caller

	return $self->{_locale} if $self->{_locale};

	# Validate and untaint HTTP_USER_AGENT before passing to any parser.
	# The User-Agent header is attacker-controlled; apply the same discipline
	# as HTTP_ACCEPT_LANGUAGE.  Printable ASCII (0x20-0x7e), bounded length.
	my $agent;
	if(defined(my $raw_agent = $ENV{'HTTP_USER_AGENT'})) {
		if($raw_agent =~ /^([\x20-\x7e]{1,$UA_MAX})$/a) {
			$agent = $1;    # untainted
		} else {
			$self->_warn({ warning => 'HTTP_USER_AGENT contains invalid characters or exceeds length limit; ignoring' });
		}
	}

	# First try: parse the language tag from the User-Agent parenthetical
	if(defined($agent) && ($agent =~ /\((.+)\)/)) {
		foreach(split(/;/, $1)) {
			my $candidate = $_;
			$candidate =~ s/^\s+|\s+$//g;    # trim both ends

			if($candidate =~ /^[a-zA-Z]{2}-([a-zA-Z]{2})$/) {
				local $SIG{__WARN__} = undef;
				if(my $c = $self->_code2country($1)) {
					$self->{_locale} = $c;
					return $c;
				}
			}
		}

		# Second try: HTTP::BrowserDetect (works for more User-Agents)
		if(eval { require HTTP::BrowserDetect }) {
			HTTP::BrowserDetect->import();
			my $browser = HTTP::BrowserDetect->new($agent);
			# Validate country() result before use — the return value comes from
			# the third-party module and is not yet untainted or range-checked.
			if($browser) {
				my $bc = $browser->country() // '';
				if($bc =~ /^([A-Za-z]{2})$/a) {
					if(my $c = $self->_code2country($1)) {
						$self->{_locale} = $c;
						return $c;
					}
				}
			}
		}
	}

	# Third try: IP address
	my $country = $self->country();
	if($country) {
		$country =~ s/[\r\n]//g;
		my $c;
		eval {
			local $SIG{__WARN__} = sub { die $_[0] };
			$c = $self->_code2country($country);
		};
		unless($@) {
			if($c) {
				$self->{_locale} = $c;
				return $c;
			}
		}
	}

	# Fourth try: mod_geoip env var — apply the same ISO 3166-1 validation
	# used in country() to guard against spoofed or malformed values
	if(defined($ENV{'GEOIP_COUNTRY_CODE'})) {
		if($ENV{'GEOIP_COUNTRY_CODE'} =~ /^([A-Z]{2})\z/a) {
			if(my $c = $self->_code2country(lc($1))) {
				$self->{_locale} = $c;
				return $c;
			}
		}
	}
	return undef;
}

=head2 time_zone

Returns the visitor's time zone, as an IANA time zone name,
for example C<'Europe/London'> or C<'America/New_York'>.

When C<REMOTE_ADDR> is set, it uses L<Geo::IP> if a database is installed,
and otherwise asks the ip-api.com web service (this needs
L<LWP::Simple::WithCache> or L<LWP::Simple>, and L<JSON::Parse>).

When C<REMOTE_ADDR> is not set (for example on the command line),
it returns the time zone of the computer that runs the program.

Returns C<undef> when the time zone cannot be found.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        matches  => qr/^[A-Za-z][A-Za-z0-9_+\-\/]*$/,
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{REMOTE_ADDR} = '8.8.8.8';
    my $l = CGI::Lingua->new(supported => ['en']);
    print $l->time_zone() // 'unknown';   # e.g. "America/New_York"

=head3 MESSAGES

These are warnings. C<time_zone()> does not die.

    "Couldn't determine the timezone"
    "X.X.X.X isn't a valid IP address"
    "LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com"
    "JSON::Parse is absent; cannot read ip-api.com answers"
    "ip-api.com returned unparseable JSON: ..."
    "DateTime::TimeZone::Local failed: ..."
    "Discarding malformed timezone '...'"
    "ip-api.com lookup failed: ..."

=head3 PSEUDOCODE

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

=cut

sub time_zone {
	my $self = shift;
	local ($@, $!);	# evals, open() and HTTP calls must not leak to the caller

	$self->_trace('Entered time_zone');

	if($self->{_timezone}) {
		$self->_trace('quick return: ', $self->{_timezone});
		return $self->{_timezone};
	}

	my $raw_ip = $ENV{'REMOTE_ADDR'};

	if(defined $raw_ip) {
		# Untaint before any external use — kept in sync with country()'s pattern,
		# including the mixed-notation branch for ::ffff:a.b.c.d addresses.
		my $ip = _untaint_ip($raw_ip);
		unless(defined($ip)) {
			$self->_warn({ warning => "$raw_ip isn't a valid IP address" });
			return undef;
		}

		if($self->{_have_geoip} == $GEO_UNKNOWN) {
			$self->_load_geoip();
		}
		if($self->{_have_geoip} == $GEO_PRESENT) {
			eval { $self->{_timezone} = $self->{_geoip}->time_zone($ip) };
		}

		unless($self->{_timezone}) {
			if(eval { require LWP::Simple::WithCache; require JSON::Parse }) {
				$self->_debug("Look up $ip on ip-api.com");

				my $data = eval { local $SIG{__DIE__}; LWP::Simple::WithCache::get("http://ip-api.com/json/$ip") };
				$self->_warn({ warning => "ip-api.com lookup failed: $@" }) if $@;
				if($data) {
					eval { $self->{_timezone} = JSON::Parse::parse_json($data)->{'timezone'} };
					$self->_warn({ warning => "ip-api.com returned unparseable JSON: $@" }) if $@;
				}
			} elsif(eval { require LWP::Simple; require JSON::Parse }) {
				$self->_debug("Look up $ip on ip-api.com");

				my $data = eval { local $SIG{__DIE__}; LWP::Simple::get("http://ip-api.com/json/$ip") };
				$self->_warn({ warning => "ip-api.com lookup failed: $@" }) if $@;
				if($data) {
					eval { $self->{_timezone} = JSON::Parse::parse_json($data)->{'timezone'} };
					$self->_warn({ warning => "ip-api.com returned unparseable JSON: $@" }) if $@;
				}
			} else {
				# A module is missing — degrade gracefully rather than killing the
				# entire request with a croak; caller can check for undef.  Name the
				# module that is really missing: an LWP may be present without JSON::Parse.
				if(eval { require LWP::Simple::WithCache; 1 } || eval { require LWP::Simple; 1 }) {
					$self->_warn({ warning => 'JSON::Parse is absent; cannot read ip-api.com answers' });
				} else {
					$self->_warn({ warning => 'LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com' });
				}
			}
		}
	} else {
		# Local connection — read from /etc/timezone or DateTime::TimeZone
		if(defined(my $tz = $self->_read_zone_file())) {
			$self->{_timezone} = $tz;
		} else {
			# DateTime::TimeZone::Local::TimeZone() is not available on all
			# platforms/versions (absent on some Windows Perl builds); guard
			# so time_zone() degrades to undef rather than dying.
			eval {
				local $SIG{__DIE__};
				require DateTime::TimeZone::Local;
				$self->{_timezone} = DateTime::TimeZone::Local->TimeZone()->name();
			};
			$self->_warn({ warning => "DateTime::TimeZone::Local failed: $@" }) if $@;
		}
	}

	# Validate the timezone string against a permissive but bounded IANA pattern.
	# Rejects XSS payloads (e.g. "Europe/London<script>...") from hostile JSON
	# responses while accepting all real IANA zone names (e.g. "America/New_York",
	# "Etc/GMT+8", "UTC").
	if(defined($self->{_timezone}) &&
	   (ref($self->{_timezone}) || ($self->{_timezone} !~ $ZONE_RE))) {
		$self->_warn({ warning => "Discarding malformed timezone '" . _printable($self->{_timezone}) . "'" });
		delete $self->{_timezone};
	}

	unless(defined($self->{_timezone})) {
		$self->_warn({ warning => "Couldn't determine the timezone" });
	}
	return $self->{_timezone};
}

# ── _read_zone_file ──────────────────────────────────────────────────────
# Purpose:      Read the system time zone name from $ZONE_FILE (normally
#               /etc/timezone) for command-line use.
# Entry:        none.
# Exit:         The zone name, or undef if the file is missing, unreadable,
#               not a regular file, empty, or does not hold a zone name.
# Notes:        Only a regular file is opened, and at most $ZONE_FILE_MAX bytes
#               are read: a symlink to /dev/zero or /dev/urandom, or a huge
#               file, must not hang the request or exhaust memory.  CORE::
#               calls bypass autodie, so a failure returns undef, not a die.
sub _read_zone_file
{
	my $self = shift;

	return undef unless -f $ZONE_FILE && -r _;
	CORE::open(my $fin, '<', $ZONE_FILE) or return undef;
	my $got = CORE::read($fin, my $buf, $ZONE_FILE_MAX);
	CORE::close($fin);
	return undef unless $got;

	# First word of the file; surrounding spaces and newlines are not part of it
	my ($zone) = $buf =~ /\A\s*(\S+)/;
	unless(defined($zone) && ($zone =~ $ZONE_RE)) {
		$self->_debug("$ZONE_FILE does not hold a time zone name");
		return undef;
	}
	return $zone;
}

=head2 is_rtl

Returns C<1> if the chosen language is written from right to left,
and C<0> if it is not.

The right-to-left languages are Arabic (C<ar>), Dhivehi (C<dv>),
Persian (C<fa>), Hebrew (C<he>), Kurdish (C<ku>), Pashto (C<ps>),
Sindhi (C<sd>), Uyghur (C<ug>), Urdu (C<ur>) and Yiddish (C<yi>).

When no language was found, it returns C<0>.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'boolean',
        memberof => [0, 1],
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ar';
    my $l = CGI::Lingua->new(supported => ['ar', 'en']);
    print $l->is_rtl();   # 1

=cut

sub is_rtl
{
	my $self = shift;
	return $RTL_LANGS{$self->language_code_alpha2() // ''} ? 1 : 0;
}

=head2 text_direction

Returns C<'rtl'> (right to left) or C<'ltr'> (left to right) for the chosen
language. You can use the value directly in the HTML C<dir> attribute.

When no language was found, it returns C<'ltr'>.

=head3 API SPECIFICATION

=head4 Input

    {}

=head4 Output

    {
        type     => 'string',
        memberof => ['ltr', 'rtl'],
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'he';
    my $l = CGI::Lingua->new(supported => ['he', 'en']);
    print '<html dir="', $l->text_direction(), '">';   # <html dir="rtl">

=cut

sub text_direction
{
	my $self = shift;
	return $self->is_rtl() ? 'rtl' : 'ltr';
}

=head2 plural_category($n)

Many languages use a different word form for different numbers.
English has two forms ("1 file", "2 files"); Russian has more;
Japanese has only one.

C<plural_category($n)> tells you which form to use for the number C<$n>
in the chosen language.
It returns one of C<'zero'>, C<'one'>, C<'two'>, C<'few'>, C<'many'> or
C<'other'>. These are the Unicode CLDR plural category names.

The rules for about 70 languages are built in, including Arabic (6 forms),
Slavic languages (3 or 4 forms), Celtic languages (up to 6 forms), Hebrew,
Maltese, Romanian, Latvian, Lithuanian and Slovenian.
Other languages use the English rule: C<'one'> for 1, otherwise C<'other'>.

When no language was found, it always returns C<'other'>.

C<$n> should be a whole number that is zero or more.
A number with a fractional part is cut down to a whole number first
(2.7 becomes 2).
For full CLDR rules, including fractions, use L<Locale::CLDR>.

=head3 API SPECIFICATION

=head4 Input

    [
        { type => 'number', min => 0 },
    ]

=head4 Output

    {
        type     => 'string',
        memberof => ['zero', 'one', 'two', 'few', 'many', 'other'],
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'ru';
    my $l = CGI::Lingua->new(supported => ['ru']);
    print $l->plural_category(1);    # "one"
    print $l->plural_category(3);    # "few"
    print $l->plural_category(11);   # "many"

=head3 MESSAGES

    "plural_category: $n must be defined"
        - dies (croak) when $n is undef

=cut

# CLDR plural category rules (https://unicode.org/cldr/charts/42/supplemental/language_plural_rules.html).
# Values are coderefs: ($n) → category string.  Languages absent from this
# table fall back to the standard one/other rule inside plural_category().
my %PLURAL_RULES = (

	# ── No plural distinction (always 'other') ────────────────────────────
	(map { $_ => sub { 'other' } }
		qw(az bm bo dz id ig ii in ja jbo jv jw kde kea km ko lkt lo ms
		   my nqo root sah ses sg th to vi wo yo zh)),

	# ── Standard: n == 1 → 'one', else 'other' ───────────────────────────
	(map { $_ => sub { int($_[0]) == 1 ? 'one' : 'other' } }
		qw(af an ast bg bn brx ca cgg da de el en eo es et eu fi
		   gl gsw gu ha haw hu ia it kcg kk kl lb lg mas ml mn mr
		   nb nd ne nl nn nyn om or pa pap rm rof rwk saq seh sn so
		   sq ss ssy st sv sw ta te teo tig tk tl tn ts ur wae xh xog)),

	# ── French / Portuguese-BR: n ≤ 1 → 'one' ────────────────────────────
	(map { $_ => sub { int($_[0]) <= 1 ? 'one' : 'other' } } qw(fr pt_BR)),

	# ── Arabic: zero/one/two/few/many/other ───────────────────────────────
	ar => sub {
		my $n    = int($_[0]);
		my $m100 = $n % 100;
		return 'zero'  if $n == 0;
		return 'one'   if $n == 1;
		return 'two'   if $n == 2;
		return 'few'   if $m100 >= 3  && $m100 <= 10;
		return 'many'  if $m100 >= 11 && $m100 <= 99;
		return 'other';
	},

	# ── Hebrew: one/two/many/other ────────────────────────────────────────
	he => sub {
		my $n = int($_[0]);
		return 'one'  if $n == 1;
		return 'two'  if $n == 2;
		return 'many' if $n != 0 && $n % 10 == 0;
		return 'other';
	},

	# ── Russian / Ukrainian / Belarusian: one/few/many ────────────────────
	(map { $_ => sub {
		my $n    = int($_[0]);
		my $m10  = $n % 10;
		my $m100 = $n % 100;
		return 'one' if $m10 == 1 && $m100 != 11;
		return 'few' if $m10 >= 2 && $m10 <= 4 && ($m100 < 10 || $m100 >= 20);
		return 'many';
	} } qw(ru uk be)),

	# ── Polish: one/few/many ──────────────────────────────────────────────
	pl => sub {
		my $n    = int($_[0]);
		my $m10  = $n % 10;
		my $m100 = $n % 100;
		return 'one' if $n == 1;
		return 'few' if $m10 >= 2 && $m10 <= 4 && ($m100 < 10 || $m100 >= 20);
		return 'many';
	},

	# ── Czech / Slovak: one/few/other ────────────────────────────────────
	(map { $_ => sub {
		my $n = int($_[0]);
		return 'one' if $n == 1;
		return 'few' if $n >= 2 && $n <= 4;
		return 'other';
	} } qw(cs sk)),

	# ── Romanian: one/few/other ───────────────────────────────────────────
	ro => sub {
		my $n    = int($_[0]);
		my $m100 = $n % 100;
		return 'one' if $n == 1;
		return 'few' if $n == 0 || ($m100 >= 1 && $m100 <= 19);
		return 'other';
	},

	# ── Latvian: zero/one/other ───────────────────────────────────────────
	lv => sub {
		my $n    = int($_[0]);
		my $m10  = $n % 10;
		my $m100 = $n % 100;
		return 'zero'  if $m10 == 0 || ($m100 >= 11 && $m100 <= 19);
		return 'one'   if $m10 == 1 && $m100 != 11;
		return 'other';
	},

	# ── Lithuanian: one/few/other ─────────────────────────────────────────
	lt => sub {
		my $n    = int($_[0]);
		my $m10  = $n % 10;
		my $m100 = $n % 100;
		return 'one' if $m10 == 1 && ($m100 < 10 || $m100 >= 20);
		return 'few' if $m10 >= 2 && ($m100 < 10 || $m100 >= 20);
		return 'other';
	},

	# ── Slovenian: one/two/few/other ──────────────────────────────────────
	sl => sub {
		my $m100 = int($_[0]) % 100;
		return 'one'   if $m100 == 1;
		return 'two'   if $m100 == 2;
		return 'few'   if $m100 == 3 || $m100 == 4;
		return 'other';
	},

	# ── Welsh: zero/one/two/few/many/other ───────────────────────────────
	cy => sub {
		my $n = int($_[0]);
		return 'zero'  if $n == 0;
		return 'one'   if $n == 1;
		return 'two'   if $n == 2;
		return 'few'   if $n == 3;
		return 'many'  if $n == 6;
		return 'other';
	},

	# ── Irish: one/two/few/many/other ────────────────────────────────────
	ga => sub {
		my $n = int($_[0]);
		return 'one'  if $n == 1;
		return 'two'  if $n == 2;
		return 'few'  if $n >= 3 && $n <= 6;
		return 'many' if $n >= 7 && $n <= 10;
		return 'other';
	},

	# ── Maltese: one/two/few/many/other ──────────────────────────────────
	mt => sub {
		my $n    = int($_[0]);
		my $m100 = $n % 100;
		return 'one'  if $n == 1;
		return 'two'  if $n == 2;
		return 'few'  if $n == 0 || ($m100 >= 3  && $m100 <= 10);
		return 'many' if $m100 >= 11 && $m100 <= 19;
		return 'other';
	},
);

sub plural_category
{
	my ($self, $n) = @_;
	Carp::croak('plural_category: $n must be defined') unless defined $n;
	my $code = $self->language_code_alpha2() // return 'other';
	my $rule = $PLURAL_RULES{$code} // sub { int($_[0]) == 1 ? 'one' : 'other' };
	return $rule->($n);
}

=head2 translation_file($dir, $ext)

Finds the translation file for the chosen language in the directory C<$dir>,
and returns its path.

It tries these file names, in order, and returns the first one that is a
readable regular file:

=over 4

=item 1. C<$dir/$lang-$sublang.$ext>  (for example F<en-gb.json>)

=item 2. C<$dir/$lang.$ext>           (for example F<en.json>)

=back

C<$ext> is the file extension. It is C<'json'> if you do not give it.
You can write it with or without the dot (C<'po'> or C<'.po'>).

Returns C<undef> when no such file exists, when no language was found,
when C<$dir> is C<undef>, or when C<$dir> or C<$ext> is unsafe (see below).
A directory, a device (such as F</dev/urandom>), a broken symbolic link or a
file you cannot read is never returned, even if it has the right name.

For safety, C<$dir> must be a non-empty string (not a reference) without
C<..> or a null byte, and C<$ext> may only contain letters, digits and C<->.
Control characters in a rejected value are shown as C<\xNN> in the warning.

=head3 API SPECIFICATION

=head4 Input

    [
        { type => 'string', min => 1 },
        { type => 'string', min => 1, matches => qr/^\.?[A-Za-z0-9-]+$/, optional => 1 },
    ]

=head4 Output

    {
        type     => 'string',
        optional => 1,
    }

=head3 EXAMPLE

    local $ENV{HTTP_ACCEPT_LANGUAGE} = 'en-gb';
    my $l = CGI::Lingua->new(supported => ['en-gb', 'en']);

    my $path = $l->translation_file('/var/www/i18n');
    # '/var/www/i18n/en-gb.json' if it exists,
    # else '/var/www/i18n/en.json' if it exists,
    # else undef

    # A different extension
    my $po = $l->translation_file('/var/www/i18n', 'po');

=head3 MESSAGES

These are warnings. C<translation_file()> does not die.

    "translation_file: unsafe directory '...' rejected"
    "translation_file: unsafe extension '...' rejected"

=cut

sub translation_file
{
	my ($self, $dir, $ext) = @_;
	local $!;	# a failed file test sets $!
	return undef unless defined $dir;

	# Reject traversal attempts in the directory argument.  A real translation
	# directory never needs '..' or null bytes; an empty name would mean "/",
	# and a reference would be used as the string "ARRAY(0x...)".
	if(ref($dir) || !length($dir) || $dir =~ /\.\./ || $dir =~ /\x00/) {
		$self->_warn({ warning => "translation_file: unsafe directory '" . _printable($dir) . "' rejected" });
		return undef;
	}

	$ext //= 'json';
	$ext =~ s/^\.//;    # accept '.json' or 'json'

	# Valid extensions are letters, digits and hyphens only (e.g. 'json', 'po',
	# 'yml'); \z, not $, so "json\n" is refused too
	unless($ext =~ /^[A-Za-z0-9\-]+\z/) {
		$self->_warn({ warning => "translation_file: unsafe extension '" . _printable($ext) . "' rejected" });
		return undef;
	}

	# The codes become part of a path, so check their shape even though they
	# come from the negotiated language
	my $lang = $self->language_code_alpha2();
	return undef unless defined($lang) && ($lang =~ $LANG_CODE_RE);
	my @candidates;
	if(defined(my $sub = $self->sublanguage_code_alpha2())) {
		push @candidates, "$lang-$sub" if $sub =~ $LANG_CODE_RE;
	}
	push @candidates, $lang;

	# A translation file must be a readable regular file: a directory, a
	# device such as /dev/urandom, a dangling symlink or an unreadable file
	# named en.json is not one, and handing it back would only fail later
	for my $code (@candidates) {
		my $path = "$dir/$code.$ext";
		return $path if -f $path && -r _;
	}
	return undef;
}

# ── _printable ────────────────────────────────────────────────────────────
# Purpose:      Make a caller-supplied value safe to put in a log message:
#               control and non-ASCII characters (newlines that would forge
#               log lines, NULs, terminal escapes) become \xNN.
# Entry:        $value — any scalar; a reference is shown as its type.
# Exit:         A printable ASCII string.
sub _printable
{
	my $value = shift;
	return 'undef' unless defined($value);
	return ref($value) . ' reference' if ref($value);
	$value =~ s/([^\x20-\x7e])/sprintf('\\x%02x', ord($1))/ge;
	return $value;
}

# ── _code2language ────────────────────────────────────────────────────────
# Purpose:      Translate a 2-char language code to its English name, with
#               optional CHI caching.
# Entry:        $code — 2-char ISO 639-1 code; must be defined and non-empty.
# Exit:         Human-readable language name string, or undef.
# Side Effects: Reads/writes cache.
sub _code2language
{
	my ($self, $code) = @_;

	return unless $code;
	if(defined($self->{_country})) {
		$self->_debug("_code2language $code, country ", $self->{_country});
	} else {
		$self->_debug("_code2language $code");
	}

	unless($self->{_cache}) {
		return Locale::Language::code2language($code);
	}

	if(my $from_cache = $self->_cache_get_valid($CACHE_NS . "code2language:$code", $NAME_RE)) {
		$self->_trace("_code2language found in cache $from_cache");
		return $from_cache;
	}

	# Compute, cache, then return the value separately —
	# CHI->set() is not guaranteed to return the stored value across all drivers
	$self->_trace('_code2language not in cache, storing');
	my $name = Locale::Language::code2language($code);
	if(defined $name) {
		$self->_cache_call($self->{_cache}, 'set', $CACHE_NS . "code2language:$code", $name, $CACHE_TTL_LONG);
	}
	return $name;
}

# ── _code2country ─────────────────────────────────────────────────────────
# Purpose:      Translate a 2-char country code to a Locale::Object::Country
#               object, suppressing the expected "No result found" warning.
# Entry:        $code — 2-char ISO 3166-1 alpha-2 code (any case).
# Exit:         Locale::Object::Country object, or undef.
# Side Effects: None beyond the Locale::Object::Country look-up.
sub _code2country
{
	my ($self, $code) = @_;

	return unless $code;
	if($self->{_country}) {
		$self->_trace(">_code2country $code, country ", $self->{_country});
	} else {
		$self->_trace(">_code2country $code");
	}

	my $rc;
	if($_locale_object_db_ok // 1) {
		# Suppress the routine "No result found" warning; catch the database-
		# absent exception that Windows installations sometimes throw.
		local $SIG{__WARN__} = _warn_filter(qr/No result found in country table/);
		eval { $rc = Locale::Object::Country->new(code_alpha2 => $code) };
		if($@) {
			$_locale_object_db_ok = 0
				if $@ =~ /database was not in/;
			$rc = undef;
		} else {
			$_locale_object_db_ok = 1;
		}
	}
	$self->_trace('<_code2country ', $code || 'undef');
	return $rc;
}

# ── _country_short_name ───────────────────────────────────────────────────
# Purpose:      Return the common short English name for an ISO 3166-1 alpha-2
#               code when Locale::Object's database is unavailable.  Uses
#               %COUNTRY_SHORT_NAMES overrides for codes where Locale::Codes
#               returns the full ISO official name rather than the short form.
# Entry:        $code — 2-char country code (any case).
# Exit:         Short name string, or undef.
sub _country_short_name
{
	my ($self, $code) = @_;
	return unless defined($code);
	my $lc = lc($code);
	return $COUNTRY_SHORT_NAMES{$lc} if exists $COUNTRY_SHORT_NAMES{$lc};
	# Locale::Object may have partially initialised Locale::Codes::Country as a
	# dependency before we get here; suppress the spurious 'redefine' warning
	# that some Perl/Locale::Codes combinations produce on first full load.
	{ local $SIG{__WARN__} = _warn_filter(qr/redefined/);
	  require Locale::Codes::Country; }
	return Locale::Codes::Country::code2country($lc, 'alpha-2');
}

# ── _code2countryname ─────────────────────────────────────────────────────
# Purpose:      Translate a 2-char country code to its English name string,
#               with optional CHI caching.
# Entry:        $code — 2-char ISO 3166-1 alpha-2 code.
# Exit:         Country name string, or undef.
# Side Effects: Reads/writes cache.
sub _code2countryname
{
	my ($self, $code) = @_;

	return unless $code;
	$self->_trace(">_code2countryname $code");

	unless($self->{_cache}) {
		my $country = $self->_code2country($code);
		return $country->name if defined($country);
		return $self->_country_short_name($code);
	}

	if(my $from_cache = $self->_cache_get_valid($CACHE_NS . "code2countryname:$code", $NAME_RE)) {
		$self->_trace("_code2countryname found in cache $from_cache");
		return $from_cache;
	}

	my $name;
	if(my $country = $self->_code2country($code)) {
		$name = $country->name();
	} else {
		# Locale::Object database absent (common on Windows); fall back to
		# Locale::Codes::Country with a short-name correction table.
		$name = $self->_country_short_name($code);
	}

	if(defined($name)) {
		$self->_debug('_code2countryname not in cache, storing');
		$self->_trace('<_code2countryname ', $name);
		$self->_cache_call($self->{_cache}, 'set', $CACHE_NS . "code2countryname:$code", $name, $CACHE_TTL_LONG);
		return $name;
	}
	$self->_trace('<_code2countryname undef');
	return;
}

# ── _log ──────────────────────────────────────────────────────────────────
# Purpose:      Append a message to $self->{messages} and forward to the
#               optional logger object.
# Entry:        $level — log level string (debug/info/notice/warn/trace/error);
#               @messages — one or more strings to concatenate.
# Exit:         void
# Side Effects: Mutates $self->{messages}; calls logger method if set.
sub _log
{
	my ($self, $level, @messages) = @_;

	return unless ref($self) && scalar(@messages);

	my $text = join('', grep defined, @messages);
	return unless length($text);
	push @{$self->{'messages'}}, { level => $level, message => $text };

	if(my $logger = $self->{'logger'}) {
		$logger->$level($text);
	}
}

sub _debug  { my $self = shift; $self->_log('debug',  @_) }
sub _info   { my $self = shift; $self->_log('info',   @_) }
sub _notice { my $self = shift; $self->_log('notice', @_) }
sub _trace  { my $self = shift; $self->_log('trace',  @_) }

# ── _warn ─────────────────────────────────────────────────────────────────
# Purpose:      Emit a warning through the logger (if set) or via Carp::carp.
# Entry:        A single hashref argument: { warning => 'message text' }.
#               All callers MUST use this structured form — plain-string calls
#               silently lose the message when no logger is configured.
# Exit:         void
# Side Effects: Calls logger->warn() or carp().
sub _warn
{
	my $self = shift;

	# Parse once; both branches need the same $msg.
	my $params = Params::Get::get_params('warning', @_);
	my $msg    = (ref($params) ? $params->{'warning'} : undef) // join('', grep defined, @_);

	if(defined($self->{'logger'})) {
		$self->{'logger'}->warn($msg);
	} else {
		$self->_log('warn', $msg);
		Carp::carp($msg);
	}
}

# ── _warn_filter ──────────────────────────────────────────────────────────
# Purpose:      Build a $SIG{__WARN__} handler that drops warnings matching
#               $skip and passes every other warning on to the handler that
#               was active when the filter was built.
# Entry:        $skip — compiled regex of warnings to drop.
# Exit:         Code reference suitable for "local $SIG{__WARN__} = ...".
# Notes:        A plain "warn" inside a __WARN__ handler bypasses every handler
#               and goes straight to STDERR, so the caller's handler (a logger,
#               Test::Warnings, ...) would never see the warning; hence the
#               explicit call to the previous handler.
sub _warn_filter
{
	my $skip = shift;
	my $prev = $SIG{__WARN__};

	return sub {
		return if $_[0] =~ $skip;
		if(ref($prev) eq 'CODE') {
			$prev->(@_);
		} else {
			warn @_;
		}
	};
}

# ── Pure-Perl IP-validation helpers ──────────────────────────────────────────
# These are installed into the CGI::Lingua symbol table as is_ipv4() etc. when
# Data::Validate::IP / NetAddr::IP are unavailable (see country()).

sub _is_ipv4 {
	my $ip = shift;
	# /a: without it \d also matches non-ASCII digits such as U+0661, which
	# then compare as 0 and make "\x{661}.\x{661}.\x{661}.\x{661}" look valid
	return unless defined($ip) && $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/a;
	return !(grep { $_ > 255 } ($1, $2, $3, $4));
}

sub _is_ipv6 {
	my $ip = shift;
	return unless defined($ip) && $ip =~ /:/;
	# Socket::inet_pton is core since Perl 5.14 and validates IPv6 reliably
	require Socket;
	if(defined &Socket::inet_pton) {
		return defined Socket::inet_pton(Socket::AF_INET6(), $ip);
	}
	# Structural fallback: hex+colons, at least two colons, at most one ::
	# (tr/// counts characters, not "::" pairs, so count matches of /::/ instead)
	return ($ip =~ /^[0-9a-fA-F:]+\z/ || $ip =~ /^[0-9a-fA-F:]+:\d{1,3}(?:\.\d{1,3}){3}\z/a)
		&& (() = $ip =~ /::/g) <= 1
		&& ($ip =~ tr/://) >= 2;
}

sub _is_private_ip {
	my $ip = shift;
	return unless defined($ip);
	if($ip =~ /^(\d+)\.(\d+)/) {
		my ($a, $b) = ($1 + 0, $2 + 0);
		return 1 if $a == 10;
		return 1 if $a == 172 && $b >= 16 && $b <= 31;
		return 1 if $a == 192 && $b == 168;
		return 1 if $a == 169 && $b == 254;     # link-local / APIPA
		return 0;
	}
	return 1 if $ip =~ /^fe[89ab][0-9a-f]:/i;  # fe80::/10 link-local
	return 1 if $ip =~ /^f[cd]/i;              # fc00::/7 ULA
	return 0;
}

sub _is_loopback_ip {
	my $ip = shift;
	return unless defined($ip);
	return 1 if $ip eq '::1';
	return $ip =~ /^127\./;
}

=head1 COMMON PITFALLS

=over 4

=item * B<Configuration files and environment variables win over your arguments>

L</new> passes its arguments to L<Object::Configure>.
If a configuration file (C<config_file>) or an environment variable such as
C<CGI__Lingua__supported> sets a value, that value B<replaces> the value you
gave to C<new()>.

Values are replaced, not merged. If you pass C<< supported => ['en', 'fr'] >>
and the configuration file says C<supported: [de]>, the object supports only
C<de>, not C<en>, C<fr> and C<de>.
For nested values (hashes inside hashes) see the rules in L<Object::Configure>.

=item * B<A copy made with C<< $object->new() >> keeps old answers>

When you call C<new()> on an object, the copy starts with every answer that the
original has already worked out. So if the original has already called
L</language>, the copy returns the same language,
even if you give the copy a different C<supported> list:

    my $l = CGI::Lingua->new(supported => ['en', 'fr']);
    print $l->language();             # "French"
    my $copy = $l->new(supported => ['en']);
    print $copy->language();          # still "French"

Make the copy before you call any other method, or create a new object with
C<< CGI::Lingua->new() >>.

=item * B<'Unknown' is not the same as undef>

Some methods return the B<string> C<'Unknown'> and some return C<undef>
when they do not know the answer. C<'Unknown'> is a true value in Perl,
so C<if($l-E<gt>language())> is always true.

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

Always test with C<eq 'Unknown'> or C<defined()>, as the table shows.

C<undef> really is one value, even in list context, so it is safe to build a
hash from the results:

    my %vars = (country => $l->country(), zone => $l->time_zone());
    # $vars{zone} is the time zone even when country() is undef

=item * B<plural_category() returns 'other' when there is no language>

When no supported language was found, C<plural_category(1)> returns
C<'other'>, not C<'one'>. Have an C<'other'> form for every message.
C<plural_category(undef)> dies.

=item * B<C<supported =E<gt> 0> and C<supported =E<gt> ''> count as missing>

A false value for C<supported> is treated as if you did not give it,
so C<new()> dies with "You must give a list of supported languages".

=item * B<Answers are worked out once, then remembered>

The first call to a language method reads C<%ENV> and remembers the answer.
If you change C<%ENV> afterwards, the object does not notice.
Create a new object for each web request.

=item * B<country() reads REMOTE_ADDR when you call it>

C<country()> reads C<$ENV{REMOTE_ADDR}> when you B<call> it,
not when you create the object. In tests, call C<country()> while
C<REMOTE_ADDR> still has the value you want:

    {
        local $ENV{REMOTE_ADDR} = '8.8.8.8';
        my $l = CGI::Lingua->new(supported => ['en']);
        $country = $l->country();    # correct: inside the block
    }

=item * B<A bad header is ignored completely>

If C<HTTP_ACCEPT_LANGUAGE> is longer than 256 characters, or contains a
character that is not allowed (see L</ENCODING>), the whole header is ignored
with a warning. CGI::Lingua then uses C<LANG> or the IP address instead.

=item * B<The supported list holds tags, not names>

C<< supported => ['english', 'fr'] >> supports only French: C<'english'> is not a
language tag, so it is dropped (with a warning). Use C<'en'>.

=item * B<Language names are in English>

L</language> returns C<'French'>, not C<'Francais'>, and C<'German'>, not
C<'Deutsch'>. Use L</language_code_alpha2> if you want to show the name in
the language itself.

=item * B<The logger you pass is replaced>

L<Object::Configure> always changes C<logger> into a new L<Log::Abstraction>
object, so C<< $l->{logger} >> is not the object you passed.

=item * B<Whole objects are only cached when REMOTE_ADDR is set>

The answers of an object are read from the cache in L</new>, and written to it
when the object is destroyed, only when C<REMOTE_ADDR> is set.
On the command line, only smaller look-ups (such as code-to-name) are cached.

=item * B<Local geo databases can be out of date>

Old F<GeoIP.dat> files can give the wrong country for some addresses
(see L</country>).

=back

=head1 ENCODING

CGI::Lingua works with ASCII text. This table shows what each input accepts.

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

All values that CGI::Lingua returns are plain ASCII: language names
(C<'French'>), country names (C<'Reunion'>), codes and time zone names.
You do not need to decode them.

=head1 CONFIGURATION VARIABLES

Two package variables say where CGI::Lingua looks for files on the local
machine. You do not normally need to change them; tests and unusual
installations can, with C<local>:

=over 4

=item * C<$CGI::Lingua::ZONE_FILE>

The file that L</time_zone> reads when there is no C<REMOTE_ADDR> (command-line
use). The default is F</etc/timezone>. Only a readable regular file is used,
and only its first 256 bytes are read; otherwise L<DateTime::TimeZone> is used.

    local $CGI::Lingua::ZONE_FILE = '/srv/myapp/timezone';

=item * C<@CGI::Lingua::GEOIP_DAT>

The places where L</country> and L</time_zone> look for the legacy MaxMind
F<GeoIP.dat> used by L<Geo::IP>; the first readable regular file is used. The
default is F</usr/share/GeoIP/GeoIP.dat> and F</usr/local/share/GeoIP/GeoIP.dat>
(and F<c:/GeoIP/GeoIP.dat> first, on Windows). A file that L<Geo::IP> cannot
open is skipped with the warning C<"Can't open ... with Geo::IP; not using it">.

    local @CGI::Lingua::GEOIP_DAT = ('/opt/geo/GeoIP.dat');

=back

=head1 LIMITATIONS

=over 4

=item * B<is_rtl() covers primary-script RTL languages only>

C<is_rtl()> returns true for the 10 ISO 639-1 codes whose overwhelmingly
dominant script is right-to-left.  Languages with script variants (e.g.
Azerbaijani C<az>, which uses Latin in modern Azerbaijan but Arabic in Iran)
are treated as LTR.  If you serve content in multiple scripts of the same
language, inspect the sublanguage or Accept-Language header directly.

=item * B<plural_category() uses embedded CLDR rules, not Locale::CLDR>

The embedded rules cover ~70 languages and truncate fractional C<$n> to an
integer.  For full CLDR v42 accuracy (including fractional forms and
languages not in the table) install and use C<Locale::CLDR> directly.

=item * B<The logger is always a Log::Abstraction object>

The C<logger> argument can be an object with C<warn()>, C<info()> and
C<error()> methods, or any value that L<Object::Configure> accepts (such as an
array reference or a hash reference of options).  In every case
L<Object::Configure> replaces it with a L<Log::Abstraction> object.  An object
that is missing one of the three methods is rejected by L</new>.

=item * B<es-419 sublanguage returns undef>

Three-part regional codes such as C<es-419> (Latin American Spanish) do not
resolve to a C<sublanguage()> value because ISO 3166-1 does not define '419'.
This is a known limitation of the Locale::Object layer.

=item * B<Whois lookups are slow and unreliable>

Without C<IP::Country>, C<Geo::IP>, or C<Geo::IPfree> installed, C<country()>
falls back to Whois queries against live RIPE/ARIN/IANA servers.  These can
time out under load.  Install at least one local geo-database module and enable
the CHI cache to avoid this.

=item * B<Private methods are accessible from outside the package>

The C<_*> methods use the naming convention for privacy but Perl does not enforce
it.  C<Sub::Private> or C<Sub::Protected> should be added once all white-box
tests (C<t/function.t>, C<t/extended_tests.t>) are updated to use the public API
exclusively.

=item * B<IPv4-mapped IPv6 addresses are normalised to IPv4>

C<REMOTE_ADDR> values in the form C<::ffff:a.b.c.d> (RFC 4291 section 2.5.5)
are silently rewritten to the embedded C<a.b.c.d> IPv4 address before any
geo-lookup.  This is correct for country detection purposes but means the raw
address string is not preserved in cache keys or log messages.

=item * B<EU country code is irresolvable (with one exception)>

IP addresses that Whois reports as country C<EU> are mapped to C<'Unknown'>
unless they fall within Baidu's known subnet (RT-86809).  There is no ISO
3166-1 country code for the European Union.

=item * B<country() does not cache undef results>

When C<country()> cannot determine a country (private IPs, loopback,
unresolvable addresses), it returns C<undef> without storing the result.  A
second call on the same object repeats the full validation pipeline.  This is
intentional: C<country()> reads C<REMOTE_ADDR> at call time rather than at
construction time, so caching C<undef> would return a wrong answer if
C<REMOTE_ADDR> changes between calls.  In practice this is rarely a problem
because C<country()> is called once per request and CGI applications typically
create a fresh object per request.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

If C<HTTP_ACCEPT_LANGUAGE> contains a sub-tag with a 3-digit UN M.49 region
code (e.g. C<es-419> for Latin American Spanish), C<sublanguage()> returns
C<undef> because ISO 3166-1 does not define numeric codes.

Uses L<I18N::AcceptLanguage> to find the highest priority accepted language.
This means that if you support languages at a lower priority, it may be missed.

Please report any bugs or feature requests to C<bug-cgi-lingua at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/CGI-Lingua/coverage/>

=item * VWF - Versatile Web Framework L<https://github.com/nigelhorne/vwf>

=item * L<HTTP::BrowserDetect>

=item * L<I18N::AcceptLanguage>

=item * L<Locale::Country>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc CGI::Lingua

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/CGI-Lingua>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Lingua>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/CGI-Lingua>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Lingua>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=CGI::Lingua>

=back

=encoding utf-8

=head1 FORMAL SPECIFICATION

This section describes each method in the Z notation.
You do not need it to use the module.

=head2 Types and state

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

=head2 new

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

=head2 language

    ┌─ Language ────────────────────────────────────────────────────
    │ EnsureResolved
    │ result! : LANGNAME ∪ {Unknown}
    ├───────────────────────────────────────────────────────────────
    │ result! = slanguage'
    └───────────────────────────────────────────────────────────────

    PreferredLanguage ≙ Language
    Name              ≙ Language

=head2 sublanguage

    ┌─ Sublanguage ─────────────────────────────────────────────────
    │ EnsureResolved
    │ result! : CNAME ∪ {⊥}
    ├───────────────────────────────────────────────────────────────
    │ result! = sublanguage'
    └───────────────────────────────────────────────────────────────

=head2 language_code_alpha2

    ┌─ LanguageCodeAlpha2 ──────────────────────────────────────────
    │ EnsureResolved
    │ result! : LC2 ∪ {⊥}
    ├───────────────────────────────────────────────────────────────
    │ result! = code2'
    │ slanguage' = Unknown ⇒ result! = ⊥
    └───────────────────────────────────────────────────────────────

    CodeAlpha2 ≙ LanguageCodeAlpha2

=head2 sublanguage_code_alpha2

    ┌─ SublanguageCodeAlpha2 ───────────────────────────────────────
    │ EnsureResolved
    │ result! : CC2 ∪ {⊥}
    ├───────────────────────────────────────────────────────────────
    │ result! = subcode2'
    └───────────────────────────────────────────────────────────────

=head2 requested_language

    ┌─ RequestedLanguage ───────────────────────────────────────────
    │ EnsureResolved
    │ result! : seq CHAR
    ├───────────────────────────────────────────────────────────────
    │ result! = rlanguage'
    │ -- rlanguage' = name(b) ⁀ " (" ⁀ cname(v) ⁀ ")" when the visitor
    │ -- asked for base b with variety v; name(b) when no variety;
    │ -- Unknown when nothing was asked for.
    └───────────────────────────────────────────────────────────────

=head2 country

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

=head2 locale

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

=head2 time_zone

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

=head2 is_rtl

    ┌─ IsRtl ───────────────────────────────────────────────────────
    │ EnsureResolved
    │ result! : {0, 1}
    ├───────────────────────────────────────────────────────────────
    │ result! = 1 ⇔ code2' ∈ RTL_LANGS
    └───────────────────────────────────────────────────────────────

=head2 text_direction

    ┌─ TextDirection ───────────────────────────────────────────────
    │ IsRtl
    │ dir! : DIR
    ├───────────────────────────────────────────────────────────────
    │ dir! = (if result! = 1 then rtl else ltr)
    └───────────────────────────────────────────────────────────────

=head2 plural_category

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

=head2 translation_file

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

=head1 STATE DIAGRAM

A CGI::Lingua object has several independent parts. Each part starts
empty and is filled in the first time a method needs it.
After that, the part does not change (it is remembered).

Part 1: the language (used by language(), sublanguage(),
language_code_alpha2(), sublanguage_code_alpha2(), requested_language(),
is_rtl(), text_direction(), plural_category(), translation_file())

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

Part 2: the country (used by country(), locale(), and the language IP path)

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

Part 3: each geo module (IP::Country, Geo::IP, Geo::IPfree)

    +-----------+  first use: module loads   +-----------+
    |  UNKNOWN  |--------------------------->|  PRESENT  |
    |   (-1)    |                            |    (1)    |
    +-----------+--------------------------->+-----------+
                   first use: module or      +-----------+
                   database is missing ----->|  ABSENT   |
                                             |    (0)    |
                                             +-----------+

Part 4: locale() and time_zone()

    +------------+  locale() / time_zone() finds a value  +------------+
    | NOT KNOWN  |--------------------------------------->|   KNOWN    |
    |  (undef)   |<-------+                               | remembered |
    +------------+        | nothing found: returns undef, +------------+
          |               | stays NOT KNOWN (time_zone()
          +---------------+ also warns)

Part 5: the life of the object

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

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1; # End of CGI::Lingua
