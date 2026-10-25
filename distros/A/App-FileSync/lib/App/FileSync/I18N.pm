package App::FileSync::I18N;

# Message catalogue lookup, interpolation and error raising for App::FileSync.
# Every user-facing string in the distribution is a key here, so a translation
# is one new catalogue rather than a hunt through the code.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp confess);
use Exporter qw(import);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Scalar::Util qw(blessed);

use App::FileSync::I18N::en;

use version; our $VERSION = version->declare('0.001.2');

our @EXPORT_OK = qw(message throw warning os_error strip_location);

# Croak and carp report the first caller outside the message machinery, not
# the line inside it that raised the error.
$Carp::Internal{ (__PACKAGE__) }++;

# The language every lookup falls back to, and the catalogue that must hold
# every key.
Readonly my $FALLBACK => 'en';

# Selector keys inside a catalogue entry, see "CATALOGUE FORMAT" below.
Readonly my $SELECT_KEY    => '_by';
Readonly my $SELECT_COUNT  => 'count';
Readonly my $SELECT_GENDER => 'gender';
Readonly my $OTHER         => 'other';

# Environment variables consulted, in order, when no language is configured.
# FILESYNC_LANG lets a cron job choose a language without touching the
# C library's locale.
Readonly my @LOCALE_VARIABLES => qw(FILESYNC_LANG LC_ALL LC_MESSAGES LANG);

# Territory to language, for a locale whose language has no catalogue but whose
# country does (for example "xx_DE" or a bare "DE").  Keys are upper case; the
# lookup upper-cases its input, so "gb" and "Gb" work too.
Readonly my %COUNTRY_LANGUAGE => (
	AT => 'de', AU => 'en', BE => 'fr', CA => 'en', CH => 'de', CN => 'zh',
	DE => 'de', ES => 'es', FR => 'fr', GB => 'en', HK => 'zh', IE => 'en',
	IN => 'en', IT => 'it', JP => 'ja', KR => 'ko', NL => 'nl', NZ => 'en',
	PT => 'pt', SG => 'zh', TW => 'zh', UK => 'en', US => 'en',
);

# Plural category for a count, per language (a small subset of CLDR).  Anything
# not listed uses the English rule.
Readonly my %PLURAL_RULE => (
	en => sub { $_[0] == 1 ? 'one' : $OTHER },
	de => sub { $_[0] == 1 ? 'one' : $OTHER },
	fr => sub { ($_[0] == 0 || $_[0] == 1) ? 'one' : $OTHER },
	ja => sub { $OTHER },
	ko => sub { $OTHER },
	zh => sub { $OTHER },
);

# Settings, in the shape Object::Configure fills: "language" overrides the
# environment, and "trace" makes throw() confess with a stack trace.
our %config = (
	language => undef,
	trace    => $ENV{FILESYNC_TRACE} ? 1 : 0,
);

# Registered catalogues by language.  English is always present.
my %CATALOG = ($FALLBACK => \%App::FileSync::I18N::en::MESSAGES);

=encoding utf8

=head1 NAME

App::FileSync::I18N - message catalogue and error raising for App::FileSync

=head1 SYNOPSIS

	use App::FileSync::I18N qw(message throw);

	print message('cli.sync.summary', { repo => 'docs', dry => '', pulled => 2, pushed => 0, deleted => 0, conflicts => 0 }), "\n";
	throw('path.unsafe', { path => $path, reason => $why });

=head1 DESCRIPTION

Every user-facing string is looked up by key in a catalogue.  English is built
in (L<App::FileSync::I18N::en>); other languages are added with
L</register>.  The language is chosen from C<$config{language}>, then
C<FILESYNC_LANG>, C<LC_ALL>, C<LC_MESSAGES> and C<LANG>, falling back to
English for any language or key that has no catalogue entry.

=head2 CATALOGUE FORMAT

An entry is either a string or a selector hash.

A string may contain C<%{name}FMT> placeholders, where FMT is any C<sprintf>
conversion (C<%{path}s>, C<%{count}d>, C<%{ratio}.1f>).  C<%%> is a literal
percent sign.  An undefined argument renders as the empty string (or 0 for a
numeric conversion).

A selector hash chooses a form by count or by gender, and may nest:

	'trash.pruned' => {
		_by   => 'count',
		one   => 'removed %{count}d day of trash',
		other => 'removed %{count}d days of trash',
	},
	'admin.owner' => {
		_by    => 'gender',
		female => '%{name}s owns her repo',
		male   => '%{name}s owns his repo',
		other  => '%{name}s owns their repo',
	},

The count form is chosen by the language's plural rule from C<< $args->{count} >>,
and the gender form from C<< $args->{gender} >>; C<other> is the fallback in both.

=cut

=head1 FUNCTIONS

=head2 register

Purpose: add or replace the catalogue for a language.

Args: C<$language> (two or three lower-case letters), C<\%entries>.

Returns: the language code.

Side Effects: later lookups in that language use the new entries.  Keys the
catalogue does not hold still fall back to English.

Usage:

	App::FileSync::I18N::register(de => { 'path.empty' => 'leerer Pfad' });

=head3 EXAMPLE

	App::FileSync::I18N::register(fr => { 'cli.no_repos' => 'Aucun depot configure' });
	print App::FileSync::I18N::message('cli.no_repos', {}, 'fr'), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'language', type => 'string', matches => qr/\A[a-z]{2,3}\z/ },
		{ name => 'entries',  type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'string', matches => qr/\A[a-z]{2,3}\z/ }

=head3 MESSAGES

	Key                  Meaning                         Resolution
	i18n.bad_language    language code is malformed      pass "de", not "de_DE"
	i18n.bad_catalogue   entries is not a hash           pass a hashref

=head3 FORMAL SPECIFICATION

	ΔCatalog
	lang? : LANG ; entries? : KEY ⇸ ENTRY
	Catalog' = Catalog ⊕ {lang? ↦ entries?}

=cut

sub register {
	my ($language, $entries) = @_;

	throw('i18n.bad_language', { language => $language })
		unless defined $language && $language =~ /\A[a-z]{2,3}\z/;
	throw('i18n.bad_catalogue', { language => $language })
		unless ref($entries) eq 'HASH';

	$CATALOG{$language} = $entries;
	return $language;
}

=head2 unregister

Purpose: remove a registered catalogue (English cannot be removed).

Args: C<$language>.

Returns: 1 when a catalogue was removed, otherwise 0.

Side Effects: later lookups in that language fall back to English.

Usage:

	App::FileSync::I18N::unregister('de');

=head3 EXAMPLE

	App::FileSync::I18N::register(de => {});
	App::FileSync::I18N::unregister('de');

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'language', type => 'string' } ]

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	ΔCatalog
	lang? : LANG ; r! : 𝔹
	lang? ≠ en ⇒ Catalog' = {lang?} ⩤ Catalog
	r! ⇔ lang? ≠ en ∧ lang? ∈ dom Catalog

=cut

sub unregister {
	my ($language) = @_;

	my $removed = (defined $language && $language ne $FALLBACK
		&& delete $CATALOG{$language}) ? 1 : 0;
	return $removed;
}

=head2 parse_locale

Purpose: split a POSIX locale name into language and country.

Args: C<$locale>, such as C<de_DE.UTF-8>, C<en_GB>, C<fr>, C<DE> or C<C>.

Returns: a hashref C<{ language =E<gt> 'de', country =E<gt> 'DE' }>; either
value is C<undef> when the name does not carry it.  Matching is
case-insensitive; the language is returned in lower case and the country in
upper case.

Side Effects: none.

Usage:

	my $parts = App::FileSync::I18N::parse_locale('zh_CN.UTF-8');

=head3 EXAMPLE

	my $parts = App::FileSync::I18N::parse_locale('EN_gb.utf8');
	# { language => 'en', country => 'GB' }

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'locale', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			language => { type => 'string', optional => 1 },
			country  => { type => 'string', optional => 1 },
		},
	}

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	parse : LOCALE → (LANG ∪ {⊥}) × (COUNTRY ∪ {⊥})
	parse("ll_CC.enc@mod") = (lower ll, upper CC)
	parse("CC") = (⊥, upper CC)    where CC is two letters in upper case
	parse("C") = parse("POSIX") = (⊥, ⊥)

=cut

sub parse_locale {
	my ($locale) = @_;

	my %parts = (language => undef, country => undef);

	# "C" and "POSIX" name no language at all; an empty value is not a locale.
	if (defined $locale && length $locale && $locale !~ /\A(?:C|POSIX)(?:\.|\z)/i) {
		if ($locale =~ /\A([A-Za-z]{2,3})(?:[_-]([A-Za-z]{2}))?(?:[.@].*)?\z/) {
			my ($first, $second) = ($1, $2);

			# A bare upper-case pair is a country code ("DE"), as a GeoIP
			# lookup or a web form would supply; anything else leads with a
			# language.
			if (!defined $second && $first =~ /\A[A-Z]{2}\z/) {
				$parts{country} = $first;
			} else {
				$parts{language} = lc $first;
				$parts{country}  = uc $second if defined $second;
			}
		}
	}

	return \%parts;
}

=head2 country_language

Purpose: the language usually spoken in a country.

Args: C<$country>, an ISO 3166-1 alpha-2 code in any case.

Returns: a lower-case language code, or C<undef> for an unknown country.

Side Effects: none.

Usage:

	my $language = App::FileSync::I18N::country_language('fr');	# 'fr'

=head3 EXAMPLE

	print App::FileSync::I18N::country_language('CN'), "\n";	# zh

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'country', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', optional => 1, matches => qr/\A[a-z]{2}\z/ }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	country_language : COUNTRY ⇸ LANG
	country_language(c) = CountryLanguage(upper c)   if upper c ∈ dom CountryLanguage

=cut

sub country_language {
	my ($country) = @_;

	return defined $country ? $COUNTRY_LANGUAGE{ uc $country } : undef;
}

=head2 language

Purpose: the catalogue language a lookup will use.

Args: optional C<$wanted>, a language code or locale name that overrides the
configuration and the environment.

Returns: a language code that has a registered catalogue; English when nothing
better matches.

Side Effects: none.

Usage:

	my $language = App::FileSync::I18N::language();
	my $german   = App::FileSync::I18N::language('de_DE.UTF-8');

=head3 EXAMPLE

	local $ENV{LC_ALL} = 'fr_FR.UTF-8';
	print App::FileSync::I18N::language(), "\n";	# fr when registered, else en

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'wanted', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', matches => qr/\A[a-z]{2,3}\z/ }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	language : LOCALE ∪ {⊥} → dom Catalog
	let (l, c) = parse(first defined of wanted, config, env)
	language = l          if l ∈ dom Catalog
	         = cl(c)      if cl(c) ∈ dom Catalog
	         = en         otherwise

=head3 PSEUDOCODE

	source := wanted, else config{language}, else the first set of
	          FILESYNC_LANG, LC_ALL, LC_MESSAGES, LANG
	(language, country) := parse_locale(source)
	if language has a catalogue: return language
	if country_language(country) has a catalogue: return it
	return en

=cut

sub language {
	my ($wanted) = @_;

	my $source = $wanted;
	$source = $config{language} unless defined $source && length $source;
	for my $variable (@LOCALE_VARIABLES) {
		last if defined $source && length $source;
		$source = $ENV{$variable};
	}

	my $parts = parse_locale($source);
	my $by_country = country_language($parts->{country});

	# The language named by the locale wins; the country is only a hint for
	# a language that has no catalogue of its own.
	my $chosen = (defined $parts->{language} && $CATALOG{ $parts->{language} })
		? $parts->{language}
		: (defined $by_country && $CATALOG{$by_country}) ? $by_country : $FALLBACK;

	return $chosen;
}

=head2 message

Purpose: render a catalogue entry.

Args: C<$key>, optional C<\%args> for the placeholders and selectors, and an
optional C<$language> (code or locale name).

Returns: the rendered string, without a trailing newline.  A key that no
catalogue holds renders as the key itself followed by its arguments, so a
missing translation is visible rather than silent.

Side Effects: none.

Usage:

	my $text = message('path.unsafe', { path => 'a/../b', reason => 'parent path component' });

=head3 EXAMPLE

	print message('word.file', { count => 3 }), "\n";	# 3 files

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'key',      type => 'string', min => 1 },
		{ name => 'args',     type => 'hashref', optional => 1 },
		{ name => 'language', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None; this is the function that renders them.

=head3 FORMAL SPECIFICATION

	message : KEY × ARGS × LANG → TEXT
	let l = language(lang?) ; e = Catalog(l)(key) if defined, else Catalog(en)(key)
	message(key, a, lang?) = interpolate(select(e, a, l), a)   if key ∈ dom Catalog(en) ∪ dom Catalog(l)
	                       = key ⁀ describe(a)                otherwise

=head3 PSEUDOCODE

	language := language(requested)
	entry := catalogue(language){key}, else catalogue(en){key}
	if no entry: return key and its arguments
	while entry is a selector hash:
		pick the form named by the plural category of args{count}
		or by args{gender}; fall back to "other"
	replace each %{name}FMT with sprintf(FMT, args{name}); %% with %

=cut

sub message {
	my ($key, $args, $wanted) = @_;

	$args = {} unless ref($args) eq 'HASH';
	my $language = language($wanted);

	my $entry = $CATALOG{$language}{$key};
	$entry = $CATALOG{$FALLBACK}{$key} unless defined $entry;

	# An unknown key is a bug, but the person reading the error still
	# deserves its arguments.
	return $key . _describe($args) unless defined $entry;

	return _interpolate(_select($entry, $args, $language), $args);
}

=head2 throw

Purpose: raise a catalogued error.

Args: C<$key>, optional C<\%args>, optional C<$language>.

Returns: never returns.

Side Effects: croaks with the rendered message, which reports the caller's
location; with C<$config{trace}> (or C<FILESYNC_TRACE>) set it confesses with a
full stack trace instead.  L</strip_location> removes either for display.

Usage:

	throw('snapshot.no_root') unless defined $root;

=head3 EXAMPLE

	eval { throw('path.empty') };
	print strip_location($@);	# "empty path\n"

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'key',      type => 'string', min => 1 },
		{ name => 'args',     type => 'hashref', optional => 1 },
		{ name => 'language', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'void' }

=head3 MESSAGES

Whatever C<$key> names.

=head3 FORMAL SPECIFICATION

	throw : KEY × ARGS × LANG ↛ ∅
	throw(k, a, l) raises message(k, a, l) ⁀ "\n" ⁀ location

=cut

sub throw {
	my ($key, $args, $wanted) = @_;

	# The newline keeps the location croak appends on a line of its own, which
	# is what lets strip_location remove it without touching the message.
	my $text = message($key, $args, $wanted) . "\n";
	$config{trace} ? confess($text) : croak($text);
}

=head2 warning

Purpose: emit a catalogued warning.

Args: as for L</throw>.

Returns: 1.

Side Effects: carps the rendered message to STDERR (or C<$SIG{__WARN__}>).

Usage:

	warning('client.record_failed', { path => $path, error => $reason });

=head3 EXAMPLE

	local $SIG{__WARN__} = sub { print "warned: ", strip_location($_[0]) };
	warning('path.empty');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'key',      type => 'string', min => 1 },
		{ name => 'args',     type => 'hashref', optional => 1 },
		{ name => 'language', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

Whatever C<$key> names.

=head3 FORMAL SPECIFICATION

	warning(k, a, l) ⇒ STDERR' = STDERR ⁀ message(k, a, l) ⁀ location

=cut

sub warning {
	my ($key, $args, $wanted) = @_;

	carp(message($key, $args, $wanted) . "\n");
	return 1;
}

=head2 os_error

Purpose: the operating-system reason behind a failed call.

Args: optional C<$error>: an L<autodie::exception>, or anything else.

Returns: the C<$!> string the exception recorded, or the current C<$!>.

Side Effects: none.

Usage:

	eval { open my $fh, '<', $path; 1 } or throw('io.read', { path => $path, error => os_error($@) });

=head3 EXAMPLE

	use autodie;
	eval { opendir my $dh, '/nonexistent' };
	print os_error($@), "\n";	# No such file or directory

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'error', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	os_error(e) = e.errno   if e ∈ AutodieException
	            = errno     otherwise

=cut

sub os_error {
	my ($error) = @_;

	my $text = (blessed($error) && $error->can('errno')) ? $error->errno : $!;
	return defined $text ? "$text" : '';
}

=head2 strip_location

Purpose: turn a raised error into text for a person or a log line.

Args: C<$error> as caught in C<$@>.

Returns: the message without the C<at FILE line N.> suffix croak adds, without
a confess stack trace, and without a trailing newline.

Side Effects: none.

Usage:

	print STDERR strip_location($@), "\n";

=head3 EXAMPLE

	eval { throw('path.empty') };
	print strip_location($@), "\n";	# empty path

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'error', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	strip(m ⁀ "\n at " ⁀ f ⁀ " line " ⁀ n ⁀ "." ⁀ trace) = m
	strip(m ⁀ "\n") = m
	strip(m) = m   otherwise

=cut

sub strip_location {
	my ($error) = @_;

	my $text = defined $error ? "$error" : '';

	# throw() ends its message with a newline, so croak's location (and a
	# confess trace) always starts on a fresh line and cannot be confused
	# with a path inside the message.
	$text =~ s/\n\s*at [^\n]+ line \d+[^\n]*\.\n(?:\t[^\n]*\n?)*\z/\n/;

	# autodie and plain die put the location on the same line instead.
	$text =~ s/ at \S+ line \d+\.?\s*\z//;
	$text =~ s/\s+\z//;

	return $text;
}

# _select
# Purpose:     choose the plural or gender form of a catalogue entry.
# Entry:       $entry is a string or a selector hash; $args holds count/gender;
#              $language names the plural rule.
# Exit:        returns a string (an empty one if a selector has no usable form).
# Side effects: none.
sub _select :Private {
	my ($entry, $args, $language) = @_;

	# Selectors may nest (gender, then count), so keep choosing until a
	# plain string is left.
	while (ref($entry) eq 'HASH') {
		my $by = $entry->{$SELECT_KEY} || $SELECT_COUNT;
		my $form;
		if ($by eq $SELECT_GENDER) {
			$form = defined $args->{gender} ? $args->{gender} : $OTHER;
		} else {
			my $rule = $PLURAL_RULE{$language} || $PLURAL_RULE{$FALLBACK};
			my $count = defined $args->{count} && $args->{count} =~ /\A-?\d+(?:\.\d+)?\z/
				? $args->{count} : 0;
			$form = $rule->($count);
		}
		$entry = defined $entry->{$form} ? $entry->{$form} : $entry->{$OTHER};
	}

	return defined $entry ? $entry : '';
}

# _interpolate
# Purpose:     replace %{name}FMT placeholders and %% in a template.
# Entry:       $template is a string; $args is a hashref.
# Exit:        returns the rendered string.
# Side effects: none.  sprintf runs with warnings off for the conversion only,
#              so an argument of the wrong type renders rather than warns.
sub _interpolate :Private {
	my ($template, $args) = @_;

	$template =~ s{%(?:(%)|\{(\w+)\}([-+ 0#]*\d*(?:\.\d+)?[a-zA-Z]))}{
		defined $1 ? '%' : _format($3, $args->{$2})
	}ge;

	return $template;
}

# _format
# Purpose:     sprintf one value, treating undef as empty (or 0 for numbers).
# Entry:       $conversion is a sprintf conversion without the leading %.
# Exit:        returns the formatted value.
# Side effects: none.
sub _format :Private {
	my ($conversion, $value) = @_;

	my $numeric = $conversion =~ /[dioxXeEfgGbBu]\z/ ? 1 : 0;
	$value = $numeric ? 0 : '' unless defined $value;

	no warnings 'numeric';
	return sprintf('%' . $conversion, $value);
}

# _describe
# Purpose:     show the arguments of a message whose key has no entry.
# Entry:       $args is a hashref.
# Exit:        returns " (k=v, ...)" or "" when there are none.
# Side effects: none.
sub _describe :Private {
	my ($args) = @_;

	my @pairs = map { "$_=" . (defined $args->{$_} ? $args->{$_} : '') } sort keys %{$args};
	return @pairs ? ' (' . join(', ', @pairs) . ')' : '';
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Only English ships.  Other languages are registered at run time; the
locale tests use stub catalogues.

=item * The plural rules cover English, German, French, Chinese, Japanese and
Korean.  Other languages use the English rule until one is added to
C<%PLURAL_RULE>.

=item * Operating-system reasons (C<$!>) come from the C library and follow
the process locale set at start-up, not the catalogue language, so a German
message can carry an English reason when the C library has no German locale.

=item * Country selection comes from the territory in a locale name, or a bare
country code passed to L</language>.  The distribution performs no GeoIP
lookup: a sync tool has no business locating its user.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
