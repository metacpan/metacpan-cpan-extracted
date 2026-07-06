package CGI::Lingua;

use warnings;
use strict;
use autodie qw(:file);

use Object::Configure 0.14;
use Params::Get 0.13;
use Readonly;
use Scalar::Util qw(blessed);
use Storable;
use Class::Autouse qw{
	Carp
	Locale::Language
	Locale::Object::Country
	Locale::Object::DB
	I18N::AcceptLanguage
	I18N::LangTags::Detect
};

our $VERSION = '0.81';

# ── Module-level constants ───────────────────────────────────────────────────
# Gathering magic strings here makes behavioural changes one-edit operations.

Readonly my $CACHE_TTL_LONG      => '1 month';
Readonly my $CACHE_TTL_SHORT     => '1 hour';
Readonly my $CACHE_NS            => 'CGI::Lingua:';    # namespace prefix for every key
Readonly my $BROKEN_GEOIPFREE    => '45.128.139.41';  # https://github.com/bricas/geo-ipfree/issues/10
Readonly my $BAIDU_SUBNET        => '185.10.104.0/22';# RT-86809: Baidu misreports as EU
Readonly my $DEPRECATED_EN_UK    => 'en-uk';          # some browsers still send this
Readonly my $CANONICAL_EN_GB     => 'en-gb';
Readonly my $ACCEPT_LANG_MAX     => 256;              # max bytes we accept from the header
Readonly my $GEO_UNKNOWN         => -1;               # geo-module sentinel: not yet probed
Readonly my $GEO_ABSENT          =>  0;               # geo-module sentinel: unavailable
Readonly my $GEO_PRESENT         =>  1;               # geo-module sentinel: loaded OK

=head1 NAME

CGI::Lingua - Create a multilingual web page

=head1 VERSION

Version 0.80

=cut

=head1 SYNOPSIS

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
    } else {	# $language eq 'Unknown'
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

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Lingua object.

=head3 API SPECIFICATION

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

=head3 MESSAGES

    "You must give a list of supported languages"  - no 'supported' key provided
    "List of supported languages must be an array ref" - supported is wrong ref type
    "Supported languages must be the short code"  - string too short or too long
    "Logger must be a blessed object with warn/info/error methods" - bad logger arg

=head3 PSEUDOCODE

    1. Normalise args via Params::Get and Object::Configure
    2. Validate logger (must be blessed with warn/info/error) if provided
    3. Validate supported (required, string or arrayref)
    4. If cache and REMOTE_ADDR set, attempt to thaw a previously stored state
    5. Bless and return fresh object with sentinel flags set to GEO_UNKNOWN

=cut

sub new
{
	my $class = shift;
	my $params = Params::Get::get_params('supported', @_);

	# Handle ::new() misuse
	if(!defined($class)) {
		if($params) {
			if(my $logger = $params->{'logger'}) {
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
	if(defined $params->{'logger'} && blessed($params->{'logger'})) {
		unless(
			$params->{'logger'}->can('warn')
			&& $params->{'logger'}->can('info')
			&& $params->{'logger'}->can('error')
		) {
			Carp::croak('Logger must be a blessed object with warn/info/error methods');
		}
	}

	$params = Object::Configure::configure($class, $params);

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

	# Try to restore a frozen state from the cache before doing any work
	if($cache && $ENV{'REMOTE_ADDR'}) {
		my $key = _build_cache_key($ENV{'REMOTE_ADDR'}, $params, $class, $info);
		if(my $rc = $cache->get($key)) {
			$rc = Storable::thaw($rc);
			# Re-inject transient/non-serialisable fields
			$rc->{logger}           = $params->{'logger'};
			$rc->{_syslog}          = $params->{syslog};
			$rc->{_cache}           = $cache;
			$rc->{_supported}       = $params->{supported};
			$rc->{_info}            = $info;
			$rc->{_have_ipcountry}  = $GEO_UNKNOWN;
			$rc->{_have_geoip}      = $GEO_UNKNOWN;
			$rc->{_have_geoipfree}  = $GEO_UNKNOWN;

			# If lang= CGI param is active, the cached language choice may be stale
			if(($rc->{_what_language} || $rc->{_rlanguage}) && $info && $info->lang()) {
				delete @{$rc}{qw(_what_language _rlanguage _country)};
			}
			return $rc;
		}
	}

	return bless {
		%{$params},
		_supported => ref($params->{supported}) ? $params->{supported} : [ $params->{'supported'} ],
		_cache           => $cache,
		_info            => $info,
		_syslog          => $params->{syslog},
		_dont_use_ip     => $params->{dont_use_ip} || 0,
		_have_ipcountry  => $GEO_UNKNOWN,
		_have_geoip      => $GEO_UNKNOWN,
		_have_geoipfree  => $GEO_UNKNOWN,
		_debug           => $params->{debug} || 0,
	}, $class;
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

	my $key = "$addr/";

	# Include the requested language (if determinable) so different
	# Accept-Language values get distinct cache slots for the same IP.
	my $l;
	if($info && ($l = $info->lang())) {
		$key .= "$l/";
	} elsif($l = $class->_what_language()) {
		$key .= "$l/";
	}

	# Fix: was ref($params->{'supported'} eq 'ARRAY') — eq was inside ref(),
	# so ref() always received a boolean (1 or ''), never the arrayref itself.
	# Result: arrayref-supported always fell through to the else branch and
	# stringified to 'ARRAY(0x...)' — a different address every request —
	# making cache lookups in new() permanently fail.
	if(ref($params->{'supported'}) eq 'ARRAY') {
		$key .= join('/', @{$params->{supported}});
	} else {
		$key .= $params->{'supported'};
	}

	return $key;
}

# Some of the information takes a long time to work out, so cache what we can
sub DESTROY {
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
	return if $cache->get($key);

	$self->_debug("Storing self in cache as $key");

	# Freeze only the computed state — not loggers, file handles, or
	# geo-module objects (they are re-initialised on next construction).
	my $copy = bless {
		_slanguage              => $self->{_slanguage},
		_slanguage_code_alpha2  => $self->{_slanguage_code_alpha2},
		_sublanguage_code_alpha2 => $self->{_sublanguage_code_alpha2},
		_country                => $self->{_country},
		_rlanguage              => $self->{_rlanguage},
		_dont_use_ip            => $self->{_dont_use_ip},
		_have_ipcountry         => $self->{_have_ipcountry},
		_have_geoip             => $self->{_have_geoip},
		_have_geoipfree         => $self->{_have_geoipfree},
	}, ref($self);

	$cache->set($key, Storable::nfreeze($copy), $CACHE_TTL_LONG);
}

=head2 language

Tells the CGI application in what language to display its messages.
The language is the natural name e.g. 'English' or 'Japanese'.

Sublanguages are handled sensibly, so that if a client requests U.S. English
on a site that only serves British English, language() will return 'English'.

If none of the requested languages is included within the supported lists,
language() returns 'Unknown'.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str - human-readable language name, or 'Unknown'

=cut

sub language {
	my $self = $_[0];

	$self->_find_language() unless $self->{_slanguage};
	return $self->{_slanguage};
}

=head2 preferred_language

Same as language().

=cut

sub preferred_language
{
	my $self = shift;
	return $self->language(@_);
}

=head2 name

Synonym for language, for compatibility with Locale::Object::Language.

=cut

sub name {
	my $self = $_[0];
	return $self->language();
}

=head2 sublanguage

Tells the CGI what variant to use e.g. 'United Kingdom', or undef if
it can't be determined.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str | undef

=cut

sub sublanguage {
	my $self = $_[0];

	$self->_trace('Entered sublanguage');
	$self->_find_language() unless $self->{_slanguage};
	$self->_trace('Leaving sublanguage ', ($self->{_sublanguage} || 'undef'));
	return $self->{_sublanguage};
}

=head2 language_code_alpha2

Gives the two-character representation of the supported language, e.g. 'en'
when you've asked for en-gb.

If none of the requested languages is included within the supported lists,
language_code_alpha2() returns undef.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 chars) | undef

=cut

sub language_code_alpha2 {
	my $self = $_[0];

	$self->_trace('Entered language_code_alpha2');
	$self->_find_language() unless $self->{_slanguage};
	$self->_trace('language_code_alpha2 returns ', $self->{_slanguage_code_alpha2});
	return $self->{_slanguage_code_alpha2};
}

=head2 code_alpha2

Synonym for language_code_alpha2, kept for historical reasons.

=cut

sub code_alpha2 {
	my $self = $_[0];
	return $self->language_code_alpha2();
}

=head2 sublanguage_code_alpha2

Gives the two-character representation of the supported language, e.g. 'gb'
when you've asked for en-gb, or undef.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 chars) | undef

=cut

sub sublanguage_code_alpha2 {
	my $self = $_[0];

	$self->_find_language() unless $self->{_slanguage};
	return $self->{_sublanguage_code_alpha2};
}

=head2 requested_language

Gives a human-readable rendition of what language the user asked for whether
or not it is supported.

Returns the sublanguage (if appropriate) in parentheses,
e.g. "English (United Kingdom)"

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str - e.g. "English (United Kingdom)" or "Unknown"

=cut

sub requested_language {
	my $self = $_[0];

	$self->_find_language() unless $self->{_rlanguage};
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

	$self->_trace('Entered _find_language');

	$self->{_rlanguage} = 'Unknown';
	$self->{_slanguage} = 'Unknown';

	my $http_accept_language = $self->_what_language();
	if(defined($http_accept_language)) {
		$self->_debug(
			"language wanted: $http_accept_language, "
			. 'languages supported: '
			. join(', ', @{$self->{_supported}} // '')
		);

		# Normalise the deprecated en-uk tag that some browsers send
		if($http_accept_language eq $DEPRECATED_EN_UK) {
			$self->_debug("Resetting country code to GB for $http_accept_language");
			$http_accept_language = $CANONICAL_EN_GB;
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

		# Detected slanguage but rlanguage still Unknown — try I18N::LangTags
		if($self->{_slanguage} && ($self->{_slanguage} ne 'Unknown')) {
			if($self->{_rlanguage} eq 'Unknown') {
				$self->{_rlanguage} = I18N::LangTags::Detect::detect();
			}
			if($self->{_rlanguage}) {
				if(my $resolved = $self->_code2language($self->{_rlanguage})) {
					$self->{_rlanguage} = $resolved;
				}
				return;
			}
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

	# Suppress I18N::AcceptLanguage's uninitialized-value warnings (RT 74338)
	local $SIG{__WARN__} = sub {
		warn $_[0] unless $_[0] =~ /^Use of uninitialized value/;
	};
	my $i18n = I18N::AcceptLanguage->new(debug => $self->{_debug}, strict => 1);
	my $l = $i18n->accepts($http_accept_language, $self->{_supported});
	local $SIG{__WARN__} = 'DEFAULT';

	# I18N-AcceptLanguage strict mode can return a sublanguage variant when
	# the request contains a sublanguage we don't support; force a retry.
	if($l && ($http_accept_language =~ /-/) && ($http_accept_language !~ qr/$l/i)) {
		$self->_debug('Forcing fallback');
		undef $l;
	}

	my $requested_sublanguage;
	if(!$l) {
		# First fallback: scan for xx-yy pairs, try base language xx
		($l, $requested_sublanguage) =
			$self->_scan_sublanguage_pairs($i18n, $http_accept_language);
	}
	if(!$l) {
		# Second fallback: scan plain tokens without sublanguages
		$l = $self->_scan_plain_tokens($i18n, $http_accept_language);
		undef $requested_sublanguage if $l;
	}

	return ($l, $requested_sublanguage);
}

# ── _scan_sublanguage_pairs ───────────────────────────────────────────────
# Purpose:      Walk the Accept-Language value looking for xx-yy pairs;
#               try accepting the base language xx from the supported list.
# Entry:        $i18n — I18N::AcceptLanguage instance; $header — header string.
# Exit:         ($matched_code, $sublanguage_code) or (undef, undef).
# Side Effects: Debug logging.
sub _scan_sublanguage_pairs
{
	my ($self, $i18n, $header) = @_;

	$self->_debug(__PACKAGE__, ': ', __LINE__, ": look through $header for alternatives");
	while($header =~ /(..)\-(..)/g) {
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
# Purpose:      Walk Accept-Language tokens that have no sublanguage suffix
#               and try accepting each against the supported list.
# Entry:        $i18n — I18N::AcceptLanguage instance; $header — header string.
# Exit:         Matched code string, or undef.
# Side Effects: Debug logging.
sub _scan_plain_tokens
{
	my ($self, $i18n, $header) = @_;

	$self->_debug(__PACKAGE__, ': ', __LINE__, ": look harder through $header for alternatives");
	foreach my $possible(split(/,/, $header)) {
		next if $possible =~ /..\-../;    # already tried these in the pair scan
		$possible =~ s/;.*$//;
		$self->_debug(__PACKAGE__, ': ', __LINE__, ": see if $possible is supported");
		if($i18n->accepts($possible, $self->{_supported})) {
			$self->_debug("Fallback to $possible as best alternative");
			return $possible;
		}
	}
	return undef;
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
		eval { $sl = Locale::Object::Country->new(code_alpha3 => $1) };
		$self->_info($@) if $@;
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
	$self->_debug("accepts = $accepts");

	if($accepts) {
		$self->_debug("accepts: $accepts");

		if($accepts =~ /\-/) {
			delete $self->{_slanguage};
		} else {
			# Cache look-up for the base-language name
			my $from_cache;
			if($self->{_cache}) {
				$from_cache = $self->{_cache}->get($CACHE_NS . "accepts:$accepts");
			}
			my $slanguage;
			if($from_cache) {
				$self->_debug("$accepts is in cache as $from_cache");
				$slanguage = (split(/=/, $from_cache))[0];
			} else {
				$slanguage = $self->_code2language($accepts);
			}

			if($slanguage) {
				$self->{_slanguage} = $slanguage;

				# Normalise deprecated en-uk variety
				if($variety eq 'uk') {
					$self->_warn({ warning => "Resetting country code to GB for $header" });
					$variety = 'gb';
				}

				if(defined(my $c = $self->_code2countryname($variety))) {
					$self->_debug(__PACKAGE__, ': ', __LINE__, ":  setting sublanguage to $c");
					$self->{_sublanguage} = $c;
				}
				$self->{_slanguage_code_alpha2}   = $accepts;
				$self->{_sublanguage_code_alpha2}  = $variety;

				if($self->{_sublanguage}) {
					$self->{_rlanguage} = "$self->{_slanguage} ($self->{_sublanguage})";
					$self->_debug(__PACKAGE__, ': ', __LINE__, ": _rlanguage: $self->{_rlanguage}");
				}

				unless($from_cache) {
					$self->_debug("Set $variety to $slanguage=$accepts");
					$self->{_cache}->set(
						$CACHE_NS . "accepts:$variety",
						"$slanguage=$accepts",
						$CACHE_TTL_LONG
					) if $self->{_cache};
				}
				return 1;
			}
		}
	}

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

		if($variety eq 'uk') {
			$self->_warn({ warning => "Resetting country code to GB for $header" });
			$variety = 'gb';
		}

		my ($from_cache, $language_name);
		if($self->{_cache}) {
			$from_cache = $self->{_cache}->get($CACHE_NS . "variety:$variety");
		}

		if(defined($from_cache)) {
			$self->_debug("$variety is in cache as $from_cache");
			# Cache stores "countryname=langcode" (e.g. "United Kingdom=en").
			# Splitting on = gives the country name as the first field.
			($language_name) = split(/=/, $from_cache);
		} else {
			my $db = Locale::Object::DB->new();
			my @results = @{$db->lookup(
				table         => 'country',
				result_column => 'name',
				search_column => 'code_alpha2',
				value         => $variety
			)};
			if(defined($results[0])) {
				eval { $language_name = $self->_code2countryname($variety) };
			} else {
				$self->_debug("Can't find the country code for $variety in Locale::Object::DB");
			}
		}

		if($@ || !defined($language_name)) {
			$self->_warn({ warning => $@ }) if $@;
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
				$self->{_cache}->set(
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
		$from_cache = $self->{_cache}->get($CACHE_NS . 'language_name:' . $country);
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

	my $ip = $ENV{'REMOTE_ADDR'};
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
					warning => "Couldn't determine closest language for $language_name in $self->{_supported}"
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
		$self->{_cache}->set(
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
		if($self->{_what_language}) {
			$self->_trace('_what_language: returning cached value: ', $self->{_what_language});
			return $self->{_what_language};
		}
		if(my $info = $self->{_info}) {
			if(my $rc = $info->lang()) {
				$self->_trace("_what_language set language to $rc from the lang argument");
				return $self->{_what_language} = $rc;
			}
		}
	}

	if(my $raw_lang = $ENV{'HTTP_ACCEPT_LANGUAGE'}) {
		# Validate and untaint — RFC 7231 §5.3.5 character set plus * wildcard
		if($raw_lang =~ /^([A-Za-z0-9\-,;=.*\s]{1,$ACCEPT_LANG_MAX})$/a) {
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

Returns the two-character country code of the remote end in lowercase.

If L<IP::Country>, L<Geo::IPfree> or L<Geo::IP> is installed,
CGI::Lingua will make use of that, otherwise, it will do a Whois lookup.
If you do not have any of those installed I recommend you use the
caching capability of CGI::Lingua.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (2 lowercase chars) | undef
      'Unknown' is only returned in the Baidu-EU special case via _handle_eu_country.

=head3 MESSAGES

    "GEOIP_COUNTRY_CODE contains an invalid country code; ignoring"
    "HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring"
    "X.X.X.X isn't a valid IP address"
    "Can't determine country from LAN connection X"
    "Can't determine country from loopback connection X"
    "cache contains a numeric country: N"
    "IP matches to a numeric country"

=cut

sub country {
	my $self = shift;

	$self->_trace(__PACKAGE__, ': Entered country()');

	# Return cached result immediately (but see FIXME below about undef caching)
	if($self->{_country}) {
		$self->_trace('quick return: ', $self->{_country});
		return $self->{_country};
	}

	# mod_geoip: validate against ISO 3166-1 alpha-2 before trusting
	if(defined($ENV{'GEOIP_COUNTRY_CODE'})) {
		if($ENV{'GEOIP_COUNTRY_CODE'} =~ /^([A-Z]{2})$/a) {
			$self->{_country} = lc($1);
			return $self->{_country};
		} else {
			$self->_warn({ warning => 'GEOIP_COUNTRY_CODE contains an invalid country code; ignoring' });
		}
	}

	# Cloudflare: 'XX' means Cloudflare couldn't determine country — skip it
	if(($ENV{'HTTP_CF_IPCOUNTRY'}) && ($ENV{'HTTP_CF_IPCOUNTRY'} ne 'XX')) {
		if($ENV{'HTTP_CF_IPCOUNTRY'} =~ /^([A-Z]{2})$/a) {
			$self->{_country} = lc($1);
			return $self->{_country};
		} else {
			$self->_warn({ warning => 'HTTP_CF_IPCOUNTRY contains an invalid country code; ignoring' });
		}
	}

	my $raw_ip = $ENV{'REMOTE_ADDR'};
	return unless defined $raw_ip;

	# Validate and untaint the IP address before passing to any geo module
	my $ip;
	if($raw_ip =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/a) {
		$ip = $1;    # untainted IPv4
	} elsif($raw_ip =~ /^([0-9a-fA-F:]{2,39}|[0-9a-fA-F:]{2,30}:(?:\d{1,3}\.){3}\d{1,3})$/a) {
		$ip = $1;    # untainted IPv6, including mixed notation (e.g. ::ffff:192.0.2.1)
	} else {
		$self->_warn({ warning => "$raw_ip isn't a valid IP address" });
		return;
	}

	require Data::Validate::IP;
	Data::Validate::IP->import();

	if(!is_ipv4($ip)) {
		$self->_debug("$ip isn't IPv4. Is it IPv6?");
		if($ip eq '::1') {
			$ip = '127.0.0.1';    # normalise loopback
		} elsif($ip =~ /^::ffff:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/i) {
			$ip = $1;             # normalise IPv4-mapped IPv6 (::ffff:a.b.c.d) to plain IPv4
		} elsif(!is_ipv6($ip)) {
			$self->_warn({ warning => "$ip isn't a valid IP address" });
			return;
		}
	}
	if(is_private_ip($ip)) {
		$self->_debug("Can't determine country from LAN connection $ip");
		return;
	}
	if(is_loopback_ip($ip)) {
		$self->_debug("Can't determine country from loopback connection $ip");
		return;
	}

	# Cache look-up — skip for LAN/loopback (already returned above)
	if($self->{_cache}) {
		$self->{_country} = $self->{_cache}->get($CACHE_NS . "country:$ip");
		if(defined($self->{_country})) {
			if($self->{_country} !~ /\D/) {
				$self->_warn({ warning => 'cache contains a numeric country: ' . $self->{_country} });
				$self->{_cache}->remove($CACHE_NS . "country:$ip");
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
		if(eval { require IP::Country }) {
			IP::Country->import();
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
					Geo::IPfree::IP->import();
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
		LWP::Simple::WithCache->import();
		JSON::Parse->import();

		if(my $data = LWP::Simple::WithCache::get("http://www.geoplugin.net/json.gp?ip=$ip")) {
			eval { $self->{_country} = JSON::Parse::parse_json($data)->{'geoplugin_countryCode'} };
			$self->_warn({ warning => "geoplugin returned unparseable JSON: $@" }) if $@;
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
			} elsif($self->{_country} && $self->{_cache}) {
				$self->_debug("Set $ip to $self->{_country}");
				$self->{_cache}->set(
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
	Net::Whois::IP->import();

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
		# Strip carriage returns (e.g. 190.24.1.122) and trailing comments
		$self->{_country} =~ s/[\r\n]//g;
		if($self->{_country} =~ /^(..)\s*#/) {
			$self->{_country} = $1;
		}
		return;
	}

	$self->_debug("Look up $ip on IANA");

	require Net::Whois::IANA;
	Net::Whois::IANA->import();

	my $iana = Net::Whois::IANA->new();
	eval { $iana->whois_query(-ip => $ip) };
	unless($@) {
		$self->{_country} = $iana->country();
		$self->_debug("IANA reports $ip as ", $self->{_country});
	}

	if($self->{_country}) {
		$self->{_country} =~ s/[\r\n]//g;
		if($self->{_country} =~ /^(..)\s*#/) {
			$self->{_country} = $1;
		}
	}
}

# ── _handle_eu_country ────────────────────────────────────────────────────
# Purpose:      Resolve the ambiguous 'eu' country code.  RT-86809 shows that
#               Baidu reports itself as EU when it is actually in CN.  All
#               other 'eu' addresses are logged as Unknown.
# Entry:        $ip — validated, untainted IP string.
# Exit:         Sets $self->{_country} to 'cn' or 'Unknown'.
# Side Effects: Loads Net::Subnet; writes info log entry.
sub _handle_eu_country
{
	my ($self, $ip) = @_;

	require Net::Subnet;
	Net::Subnet->import();

	if(subnet_matcher($BAIDU_SUBNET)->($ip)) {
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
	my $db_present = (
		(($^O eq 'MSWin32') && (-r 'c:/GeoIP/GeoIP.dat'))
		|| (-r '/usr/local/share/GeoIP/GeoIP.dat')
		|| (-r '/usr/share/GeoIP/GeoIP.dat')
	);

	unless($db_present) {
		$self->{_have_geoip} = $GEO_ABSENT;
		return;
	}

	eval { require Geo::IP };
	if($@) {
		$self->{_have_geoip} = $GEO_ABSENT;
		return;
	}

	Geo::IP->import();
	$self->{_have_geoip} = $GEO_PRESENT;

	# GEOIP_STANDARD = 0 (can't use the constant name directly)
	if(-r '/usr/share/GeoIP/GeoIP.dat') {
		$self->{_geoip} = Geo::IP->open('/usr/share/GeoIP/GeoIP.dat', 0);
	} else {
		$self->{_geoip} = Geo::IP->new(0);
	}
}

=head2 locale

HTTP doesn't have a way of transmitting a browser's localisation information
which would be useful for default currency, date formatting, etc.

This method attempts to detect the information, but it is a best guess
and is not 100% reliable.  But it's better than nothing ;-)

Returns a L<Locale::Object::Country> object.

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Locale::Object::Country | undef

=cut

sub locale {
	my $self = shift;

	return $self->{_locale} if $self->{_locale};

	my $agent = $ENV{'HTTP_USER_AGENT'};

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
			if($browser && $browser->country() && (my $c = $self->_code2country($browser->country()))) {
				$self->{_locale} = $c;
				return $c;
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
		if($ENV{'GEOIP_COUNTRY_CODE'} =~ /^([A-Z]{2})$/a) {
			if(my $c = $self->_code2country(lc($1))) {
				$self->{_locale} = $c;
				return $c;
			}
		}
	}
	return undef;
}

=head2 time_zone

Returns the timezone of the web client.

If L<Geo::IP> is installed,
CGI::Lingua will make use of that, otherwise it will use L<ip-api.com>

=head3 API SPECIFICATION

    Input:  none beyond $self
    Returns: Str (IANA timezone name) | undef

=head3 MESSAGES

    "Couldn't determine the timezone"
    "LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com"
      Returns undef rather than croaking; install either LWP variant to enable ip-api lookups.

=cut

sub time_zone {
	my $self = shift;

	$self->_trace('Entered time_zone');

	if($self->{_timezone}) {
		$self->_trace('quick return: ', $self->{_timezone});
		return $self->{_timezone};
	}

	my $raw_ip = $ENV{'REMOTE_ADDR'};

	if(defined $raw_ip) {
		# Untaint before any external use — kept in sync with country()'s pattern,
		# including the mixed-notation branch for ::ffff:a.b.c.d addresses.
		my $ip;
		if($raw_ip =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/a) {
			$ip = $1;
		} elsif($raw_ip =~ /^([0-9a-fA-F:]{2,39}|[0-9a-fA-F:]{2,30}:(?:\d{1,3}\.){3}\d{1,3})$/a) {
			$ip = $1;
		} else {
			$self->_warn({ warning => "$raw_ip isn't a valid IP address" });
			return;
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
				LWP::Simple::WithCache->import();
				JSON::Parse->import();

				if(my $data = LWP::Simple::WithCache::get("http://ip-api.com/json/$ip")) {
					eval { $self->{_timezone} = JSON::Parse::parse_json($data)->{'timezone'} };
					$self->_warn({ warning => "ip-api.com returned unparseable JSON: $@" }) if $@;
				}
			} elsif(eval { require LWP::Simple; require JSON::Parse }) {
				$self->_debug("Look up $ip on ip-api.com");
				LWP::Simple->import();
				JSON::Parse->import();

				if(my $data = LWP::Simple::get("http://ip-api.com/json/$ip")) {
					eval { $self->{_timezone} = JSON::Parse::parse_json($data)->{'timezone'} };
					$self->_warn({ warning => "ip-api.com returned unparseable JSON: $@" }) if $@;
				}
			} else {
				# Neither LWP variant is available — degrade gracefully rather than
				# killing the entire request with a croak; caller can check for undef.
				$self->_warn({ warning => 'LWP::Simple::WithCache and LWP::Simple are both absent; cannot contact ip-api.com' });
			}
		}
	} else {
		# Local connection — read from /etc/timezone or DateTime::TimeZone
		if(CORE::open(my $fin, '<', '/etc/timezone')) {
			my $tz = <$fin>;
			chomp $tz;
			$self->{_timezone} = $tz;
		} else {
			$self->{_timezone} = DateTime::TimeZone::Local->TimeZone()->name();
		}
	}

	unless(defined($self->{_timezone})) {
		$self->_warn({ warning => "Couldn't determine the timezone" });
	}
	return $self->{_timezone};
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

	if(my $from_cache = $self->{_cache}->get($CACHE_NS . "code2language:$code")) {
		$self->_trace("_code2language found in cache $from_cache");
		return $from_cache;
	}

	# Compute, cache, then return the value separately —
	# CHI->set() is not guaranteed to return the stored value across all drivers
	$self->_trace('_code2language not in cache, storing');
	my $name = Locale::Language::code2language($code);
	if(defined $name) {
		$self->{_cache}->set($CACHE_NS . "code2language:$code", $name, $CACHE_TTL_LONG);
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
	{
		# Scope the signal handler tightly — only suppress the one known-harmless warning
		local $SIG{__WARN__} = sub {
			warn $_[0] unless $_[0] =~ /No result found in country table/;
		};
		$rc = Locale::Object::Country->new(code_alpha2 => $code);
	}
	$self->_trace('<_code2country ', $code || 'undef');
	return $rc;
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
		return defined($country) ? $country->name : undef;
	}

	if(my $from_cache = $self->{_cache}->get($CACHE_NS . "code2countryname:$code")) {
		$self->_trace("_code2countryname found in cache $from_cache");
		return $from_cache;
	}

	if(my $country = $self->_code2country($code)) {
		$self->_debug('_code2countryname not in cache, storing');
		my $name = $country->name();
		$self->_trace('<_code2countryname ', $name);
		# Store then return explicitly — don't rely on set() return value
		$self->{_cache}->set($CACHE_NS . "code2countryname:$code", $name, $CACHE_TTL_LONG);
		return $name;
	}
	$self->_trace('<_code2countryname undef');
	return undef;
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
# Side Effects: Calls logger->warn() or Carp::carp().
sub _warn
{
	my $self = shift;
	if(defined($self->{'logger'})) {
		# Logger gets the warning text as a plain string, not a data structure
		my $params = Params::Get::get_params('warning', @_);
		$self->{'logger'}->warn($params->{'warning'} // join('', grep defined, @_));
	} else {
		my $params = Params::Get::get_params('warning', @_);
		my $msg    = $params->{'warning'} // join('', grep defined, @_);
		$self->_log('warn', $msg);
		Carp::carp($msg);
	}
}

=head1 LIMITATIONS

=over 4

=item * B<Accept-Language left-to-right scan ignores q-values>

The second and third pass in C<_accept_language_match()> scan the header
left-to-right and ignore quality (C<q=0.x>) values.  A header such as
C<de;q=0.9,en;q=0.1> on a site that only supports C<en> would currently
fail to fall back to English.  Use C<I18N::AcceptLanguage> passes only when
possible.

=item * B<Logger must be a blessed object>

The C<logger> parameter is documented as accepting a code ref, array ref, or
filename, but the current implementation calls C<< $logger->$level() >> and will
die on non-blessed values.  Wrap alternative logger types in a
C<Log::Abstraction> instance before passing them to C<new()>.

=item * B<es-419 sublanguage returns undef>

Three-part regional codes such as C<es-419> (Latin American Spanish) do not
resolve to a C<sublanguage()> value because ISO 3166-1 does not define '419'.
This is a known limitation of the Locale::Object layer.

=item * B<Whois lookups are slow and unreliable>

Without C<IP::Country>, C<Geo::IP>, or C<Geo::IPfree> installed, C<country()>
falls back to Whois queries against live RIPE/ARIN/IANA servers.  These can
time out under load.  Install at least one local geo-database module and enable
the CHI cache to avoid this.

=item * B<Sub::Private not yet enforced>

The C<_*> private methods are currently accessible from outside the package.
C<Sub::Private> should be added to enforce encapsulation once white-box tests
are updated to call only the public API.

=item * B<IPv4-mapped IPv6 addresses are normalised to IPv4>

C<REMOTE_ADDR> values in the form C<::ffff:a.b.c.d> (RFC 4291 section 2.5.5)
are silently rewritten to the embedded C<a.b.c.d> IPv4 address before any
geo-lookup.  This is correct for country detection purposes but means the raw
address string is not preserved in cache keys or log messages.

=item * B<EU country code is irresolvable (with one exception)>

IP addresses that Whois reports as country C<EU> are mapped to C<'Unknown'>
unless they fall within Baidu's known subnet (RT-86809).  There is no ISO
3166-1 country code for the European Union.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

If C<HTTP_ACCEPT_LANGUAGE> contains a sub-tag with a 3-digit UN M.49 region
code (e.g. C<es-419> for Latin American Spanish), C<sublanguage()> returns
C<undef> because ISO 3166-1 does not define numeric codes.

Please report any bugs or feature requests to C<bug-cgi-lingua at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Lingua>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Uses L<I18N::AcceptLanguage> to find the highest priority accepted language.
This means that if you support languages at a lower priority, it may be missed.

=head1 SEE ALSO

=over 4

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

=head2 new

    new : Class × Params → CGI::Lingua
    ∀ p : Params • p.supported ≠ ∅ ⟹ result.language ∈ (p.supported ∪ {'Unknown'})

=head2 language

    language : CGI::Lingua → Str
    result ∈ {name(l) | l ∈ supported} ∪ {'Unknown'}

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of CGI::Lingua
