package App::Actions::I18N;

use strict;
use warnings;
use utf8;
use autodie qw(:all);

use Carp qw(carp confess croak);
use Exporter qw(import);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Return::Set qw(set_return);
use Scalar::Util qw(blessed looks_like_number reftype);
use Sub::Private ();

use App::Actions::Access;
use App::Actions::Error;
use App::Actions::I18N::de;
use App::Actions::I18N::en;
use App::Actions::I18N::fr;
use App::Actions::I18N::zh;

our $VERSION = '0.002.0';

our @EXPORT_OK = qw(i18n throw validate_args);

# The language used when nothing chooses one.  English is the language the
# catalogue is written in, so every key has an English text and every other
# language falls back to it.
Readonly::Scalar my $DEFAULT_LANGUAGE => 'en';

# The languages with a catalogue module under App::Actions::I18N.  A new
# language needs a module, an entry here and, if it does not count like
# English, a plural rule below.
Readonly::Array my @LANGUAGES => qw(de en fr zh);

# The environment variable that chooses the language of a whole run.  The
# POSIX locale (LC_ALL, LANG) is deliberately not consulted: the messages are
# also read by scripts in CI, and a translation they did not ask for would
# break them on any host whose locale happens not to be English.
Readonly::Scalar my $LANGUAGE_VARIABLE => 'ACTION_RUN_LANG';

# The plural category a language uses for a count.  These are the CLDR
# cardinal rules reduced to the integers this distribution counts with:
# English and German say "1 image, 2 images", French counts 0 as singular
# too, and Chinese does not inflect for number at all.
Readonly::Hash my %PLURAL_RULE => (
	en => sub { $_[0] == 1 ? 'one' : 'other' },
	de => sub { $_[0] == 1 ? 'one' : 'other' },
	fr => sub { ($_[0] == 0 || $_[0] == 1) ? 'one' : 'other' },
	zh => sub { 'other' },
);

# The language spoken for an ISO 3166-1 alpha-2 country code.  Only the
# languages that have a catalogue are listed: a country that maps to a
# language without one would get English anyway, and saying so here keeps
# that decision visible.
Readonly::Hash my %COUNTRY_LANGUAGE => (
	AT => 'de',
	AU => 'en',
	BE => 'fr',
	CA => 'en',
	CH => 'de',
	CN => 'zh',
	DE => 'de',
	FR => 'fr',
	GB => 'en',
	HK => 'zh',
	IE => 'en',
	LU => 'fr',
	NZ => 'en',
	SG => 'zh',
	TW => 'zh',
	UK => 'en',
	US => 'en',
);

# What new() and the lookups accept.  \A and \z rather than ^ and $, which
# would also let through a value with a newline on the end.
#
# A language as a caller may write it: "fr", or a locale such as "en_GB.UTF-8"
# whose first two or three letters are the language.
Readonly::Scalar my $LANGUAGE_TAG => qr/\A[A-Za-z]{2,3}(?:[_.-].*)?\z/;
# A language as the catalogues are named: "fr", "zh".
Readonly::Scalar my $LANGUAGE_CODE => qr/\A[a-z]{2,3}\z/;
# An ISO 3166 alpha-2 country, in either case: "GB", "fr".
Readonly::Scalar my $COUNTRY_CODE => qr/\A[A-Za-z]{2}\z/;

# Placeholders are sprintf conversions with a name: %(file)s, %(count)d,
# %(ratio).1f.  The name says which argument fills it, so a translation may
# put the arguments in whatever order its grammar needs.
#
# The flags and the width overlap - "0" is both - so with quantifiers that
# give back, a run of zeros not followed by a conversion is split between
# them in every possible way: 40,000 of them took forty seconds.  None of the
# quantifiers needs to give anything back, because the conversion letter is
# never a flag, a digit or a full stop, so they are possessive.
Readonly::Scalar my $PLACEHOLDER => qr/
	%
	\( (\w++) \)                # the argument's name
	(                           # the sprintf format, without its "%":
		[-+ 0#]*+               #   flags (the space is a flag; under \/x a
		                        #   class keeps its spaces)
		\d*+                    #   width
		(?: \. \d++ )?           #   precision
		[sdiouxXeEfgG]          #   conversion
	)
/x;

# Configuration in the shape Object::Configure produces: a flat hash of
# defaults that a configuration file or the environment can override.
our %config = (
	language => undef,
);

# The message catalogue.  Each entry is a string, or a hash that selects a
# string by grammatical gender ({ gender => { female => ..., male => ...,
# other => ... } }) or by plural category ({ plural => { one => ..., other =>
# ... } }); a gender branch may itself be a plural hash.  A key missing from a
# language falls back to the English entry.
my %CATALOGUE = map {
	$_ => "App::Actions::I18N::$_"->messages
} @LANGUAGES;

# The schema shared by every routine that takes a message key and its
# arguments, so the routines cannot disagree about what a key is.
Readonly::Hash my %MESSAGE_SCHEMA => (
	key => { type => 'string', min => 1 },
	args => { type => 'hashref', optional => 1 },
);

# The instance class methods and the exported helpers use when an object has
# no translator of its own.  It is rebuilt when the language it was made for
# is no longer the one the environment asks for, so a test or a long-lived
# process that changes ACTION_RUN_LANG sees the change.
my $shared;

=encoding utf-8

=head1 NAME

App::Actions::I18N - message catalogue and translator for App::Actions

=head1 SYNOPSIS

Translate one message:

	use App::Actions::I18N;

	my $i18n = App::Actions::I18N->new(language => 'fr');
	binmode STDOUT, ':encoding(UTF-8)';
	print $i18n->message('workflow.empty', { file => 'ci.yml' }), "\n";

Choose the language from a country:

	my $i18n = App::Actions::I18N->new(country => 'DE');    # German

Use the language the user asked for (C<ACTION_RUN_LANG>):

	my $text = App::Actions::I18N->shared->message('logs.removed', { count => 3, size => '2 KB' });

Throw a translated error from your own class:

	package My::Loader;
	use App::Actions::I18N qw(i18n throw);

	sub load {
		my ($self, $file) = @_;
		$self->throw('workflow.file_missing', { file => $file }) unless -f $file;
		return $self;
	}

Add a message of your own, with plural forms:

	App::Actions::I18N->add_messages(en => {
		'demo.files' => { plural => { one => '%(count)d file', other => '%(count)d files' } },
	});
	print App::Actions::I18N->new->message('demo.files', { count => 2 });    # 2 files

=head1 DESCRIPTION

This module translates the messages that App::Actions shows to people.

Every message has a I<key>, a dotted name such as C<workflow.no_jobs>.  For
each language there is a I<catalogue>: a table from keys to texts.  To show
a message, you give the key and the values to fill in, and you get the text
in the chosen language.  The key never changes, so programs can recognise
an error by its key even when the text is translated (see
L<App::Actions::Error>).

B<Placeholders.>  A text marks the places for values with a name in
brackets, followed by a C<sprintf> conversion: C<%(file)s> for a string,
C<%(count)d> for a whole number.  Because the values have names, a
translation can put them in a different order.  Write C<%%> for a percent
sign.

B<Plurals and genders.>  An entry can have different texts for different
numbers ("1 file", "2 files") or genders.  The C<count> value chooses the
plural form, using the rules of the language (for example, French uses the
singular for 0 and 1).  The C<gender> value (C<female>, C<male> or
C<other>) chooses the gendered form.

B<Languages.>  There are catalogues for English (C<en>), French (C<fr>),
German (C<de>) and Chinese (C<zh>).  If a language does not have a key, the
English text is used.  If English does not have it either, the key itself is
shown, with a warning.  So a missing translation makes a message less
helpful, but never stops the program.

B<Choosing the language.>  The first of these that is set wins:

=over 4

=item 1. the C<language> argument to L</new>;

=item 2. the C<country> argument to L</new> (a two-letter country code such
as C<GB> or C<cn>; upper or lower case);

=item 3. C<$App::Actions::I18N::config{language}>;

=item 4. the C<ACTION_RUN_LANG> environment variable;

=item 5. English.

=back

The system's own locale (C<LANG>, C<LC_ALL>) is ignored on purpose: see
L</LIMITATIONS>.

=head1 METHODS

=head2 new

Creates a translator.

=head3 ARGUMENTS

=over 4

=item * C<language> - optional; a language code such as C<fr> or C<de_DE>.
Only the part before C<_> or C<-> is used.

=item * C<country> - optional; an ISO 3166-1 alpha-2 country code.  Ignored
when C<language> is given.

=back

=head3 RETURNS

An C<App::Actions::I18N> object.

=head3 SIDE EFFECTS

Warns (in English, since no other catalogue can be trusted at that point)
when the requested language has no catalogue.

=head3 EXAMPLE

	my $english = App::Actions::I18N->new;
	my $german  = App::Actions::I18N->new(country => 'de');
	my $french  = App::Actions::I18N->new(language => 'fr_FR.UTF-8');
	print $german->language, "\n";    # de

=head3 API SPECIFICATION

=head4 INPUT

	{
		language => { type => 'string', optional => 1, matches => qr/\A[A-Za-z]{2,3}(?:[_.-].*)?\z/ },
		country  => { type => 'string', optional => 1, matches => qr/\A[A-Za-z]{2}\z/ },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::I18N' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Language 'X' has no      | No catalogue exists for the   | Use en, fr, de or zh, or add a |
	| catalogue; using English | requested language            | catalogue with add_messages    |
	| Invalid arguments to ... | An argument failed validation | Pass the documented types      |
	+--------------------------+-------------------------------+--------------------------------+

=head3 PSEUDOCODE

	validate the arguments
	work out the wanted language from the arguments, config and environment
	reduce it to its base code (de_DE.UTF-8 -> de)
	if there is no catalogue for it, warn and use English
	return a blessed object holding the language

=cut

sub new {
	my $class = shift;

	# Every argument is optional, so new() with none is English or whatever
	# the configuration and the environment choose.
	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		language => { type => 'string', optional => 1, matches => $LANGUAGE_TAG },
		country => { type => 'string', optional => 1, matches => $COUNTRY_CODE },
	});

	my $wanted = _wanted_language($params);

	# A language nobody wrote a catalogue for is a configuration mistake,
	# not a reason to fail: the English text still says what went wrong.
	if (!exists $CATALOGUE{$wanted}) {
		carp(_render($CATALOGUE{$DEFAULT_LANGUAGE}{'i18n.unknown_language'}, { language => $wanted }));
		$wanted = $DEFAULT_LANGUAGE;
	}

	# Return::Set clears $@, and a caller's own error must survive the
	# translator that the first message of a language creates.
	local $@;
	return set_return(bless({ language => $wanted }, $class), { type => 'object', isa => __PACKAGE__ });
}

=head2 shared

Returns the shared translator for the language the configuration and the
environment choose.

=head3 ARGUMENTS

None.  May be called as a class method or a function.

=head3 RETURNS

An C<App::Actions::I18N> object.

=head3 SIDE EFFECTS

Creates and caches the shared instance; replaces it when C<ACTION_RUN_LANG>
or C<$config{language}> has changed since it was made.

=head3 EXAMPLE

	local $ENV{ACTION_RUN_LANG} = 'de';
	print App::Actions::I18N->shared->language, "\n";    # de

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::I18N' }

=head3 MESSAGES

None of its own; see L</new>.

=cut

sub shared {
	# The cache key is what the language would be computed from, so a change
	# to either source makes a new translator without anyone having to say so.
	my $source = join "\0", map { defined $_ ? $_ : '' } $config{language}, $ENV{$LANGUAGE_VARIABLE};

	if (!$shared || $shared->{source} ne $source) {
		$shared = __PACKAGE__->new;
		$shared->{source} = $source;
	}

	return $shared;
}

=head2 language

Returns the code of the language the translator writes, such as C<en>.

=head3 EXAMPLE

	print App::Actions::I18N->new(country => 'CN')->language;    # zh

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string', matches => qr/\A[a-z]{2,3}\z/ }

=head3 MESSAGES

None.

=cut

sub language {
	return $_[0]->{language};
}

=head2 languages

Returns an array reference of the language codes that have a catalogue,
sorted.

=head3 EXAMPLE

	print join(', ', @{ App::Actions::I18N->languages }), "\n";    # de, en, fr, zh

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', min => 1 }

=head3 MESSAGES

None.

=cut

sub languages {
	return [ sort keys %CATALOGUE ];
}

=head2 catalogue_keys

Lists the keys a language's own catalogue defines, without the English
fallback, so a translator or a test can see what is missing.

=head3 ARGUMENTS

=over 4

=item * C<language> - a catalogue language code.

=back

=head3 RETURNS

A sorted array reference of keys; empty for a language with no catalogue.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my %french = map { $_ => 1 } @{ App::Actions::I18N->catalogue_keys('fr') };
	my @untranslated = grep { !$french{$_} } @{ App::Actions::I18N->catalogue_keys('en') };

=head3 API SPECIFICATION

=head4 INPUT

	{ language => { type => 'string', matches => qr/\A[a-z]{2,3}\z/ } }

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to ... | The code is not 2-3 lower-case| Pass a code such as fr         |
	|                          | letters                       |                                |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub catalogue_keys {
	shift;    # the invocant: the class or an instance, neither of which is needed

	my $language = validate_args(__PACKAGE__ . '::catalogue_keys', \@_, {
		language => { type => 'string', matches => $LANGUAGE_CODE },
	}, 'language')->{language};

	return [ sort keys %{ $CATALOGUE{$language} || {} } ];
}

=head2 language_for_country

Maps an ISO 3166-1 alpha-2 country code to the language of its catalogue.

=head3 ARGUMENTS

=over 4

=item * C<country> - a two-letter country code, in any case.

=back

=head3 RETURNS

The language code, or C<undef> when the country has no mapped catalogue.

=head3 EXAMPLE

	App::Actions::I18N->language_for_country('gb');    # en
	App::Actions::I18N->language_for_country('FR');    # fr
	App::Actions::I18N->language_for_country('JP');    # undef

=head3 API SPECIFICATION

=head4 INPUT

	{ country => { type => 'string', matches => qr/\A[A-Za-z]{2}\z/ } }

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to ... | The code is not two letters   | Pass an ISO 3166-1 alpha-2 code|
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub language_for_country {
	shift;    # the invocant: the class or an instance, neither of which is needed

	my $params = validate_args(__PACKAGE__ . '::language_for_country', \@_, {
		country => { type => 'string', matches => $COUNTRY_CODE },
	}, 'country');

	return $COUNTRY_LANGUAGE{ uc $params->{country} };
}

=head2 message

Renders one message in the translator's language.

=head3 ARGUMENTS

=over 4

=item * C<$key> - the catalogue key, such as C<workflow.no_jobs>.

=item * C<\%args> - optional; the values of the placeholders.  C<count>
chooses the plural form and C<gender> (C<female>, C<male> or C<other>) the
gendered form, where the entry has them.

=back

=head3 RETURNS

The rendered message as a character string.  Placeholders without a value
render as an empty string (or 0 for a numeric conversion), never as a
warning.  A key that is in no catalogue is warned about and returned as
it is, so the reader still sees which message was meant.

=head3 SIDE EFFECTS

Warns when the key is in no catalogue, and then returns the key itself.

=head3 EXAMPLE

	my $i18n = App::Actions::I18N->new(language => 'fr');
	print $i18n->message('logs.removed', { count => 0, size => '0 B' }), "\n";
	# the French singular form ("journal", not "journaux"): French counts 0 as one

=head3 API SPECIFICATION

=head4 INPUT

	{
		key  => { type => 'string', min => 1 },
		args => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| No message is defined    | The key is in no catalogue    | Add the key to the English     |
	| for 'KEY'                |                               | catalogue                      |
	+--------------------------+-------------------------------+--------------------------------+

=head3 PSEUDOCODE

	validate the key and the arguments
	look the key up in the language's catalogue, then in English
	if it is in neither, warn and return the key
	while the entry is a hash:
		if it has a gender branch, take the one args{gender} names (else other)
		if it has a plural branch, take the one the language's rule gives args{count}
	replace every %(name)fmt with sprintf(fmt, args{name})
	return the text

=cut

sub message {
	my $self = shift;

	my $params = validate_args(__PACKAGE__ . '::message', \@_, \%MESSAGE_SCHEMA, ['key', 'args']);
	my ($key, $args) = ($params->{key}, $params->{args} || {});

	# A translation that lacks a key borrows the English text, which is
	# better than an error about a missing translation.
	my $entry = $CATALOGUE{ $self->{language} }{$key};
	$entry = $CATALOGUE{$DEFAULT_LANGUAGE}{$key} unless defined $entry;

	if (!defined $entry) {
		carp(_render($CATALOGUE{$DEFAULT_LANGUAGE}{'i18n.unknown_key'}, { key => $key }));
		return $key;
	}

	return _render($self->_select($entry, $args), $args);
}

=head2 add_messages

Adds entries to, or replaces entries in, a language's catalogue.  This is
how a downstream tool or a test supplies a translation without editing this
file.

=head3 ARGUMENTS

=over 4

=item * C<$language> - the language code; a new code creates a catalogue.

=item * C<\%entries> - key to entry, in the shape described in L</message>.

=back

=head3 RETURNS

The class name or object it was called on, so calls can be chained.

=head3 SIDE EFFECTS

Changes the catalogue for every translator in the process.  A new language
uses the English plural rule unless it is one of en, fr, de or zh.

=head3 EXAMPLE

	App::Actions::I18N->add_messages(en => {
		'demo.greeting' => {
			gender => {
				female => 'She ran %(count)d jobs',
				male   => 'He ran %(count)d jobs',
				other  => 'They ran %(count)d jobs',
			},
		},
	});

=head3 API SPECIFICATION

=head4 INPUT

	{
		language => { type => 'string', matches => qr/\A[a-z]{2,3}\z/ },
		entries  => { type => 'hashref' },
	}

=head4 OUTPUT

	{ type => 'string|object' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to ... | Bad language code or entries  | Pass a lower-case code and a   |
	|                          | not a hash reference          | hash reference                 |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub add_messages {
	my $self = shift;

	my $params = validate_args(__PACKAGE__ . '::add_messages', \@_, {
		language => { type => 'string', matches => $LANGUAGE_CODE },
		entries => { type => 'hashref' },
	}, ['language', 'entries']);

	# Merged rather than replaced, so a partial translation keeps the keys
	# it did not mention.
	my $catalogue = $CATALOGUE{ $params->{language} } ||= {};
	@{$catalogue}{ keys %{ $params->{entries} } } = values %{ $params->{entries} };

	return $self;
}

=head1 FUNCTIONS

All three are exported on request.  C<i18n> and C<throw> are meant to be imported into a class,
where they act as methods.  The object's own C<i18n> translator is used when
it has one (C<< $self->{i18n} >>), and the L</shared> translator when
it has not, which is also what a class-method call gets.  C<validate_args>
is a plain function.

=head2 i18n

	my $text = $self->i18n('workflow.empty', { file => $file });

Returns the rendered message; see L</message>.

=head3 API SPECIFICATION

=head4 INPUT

	{
		key  => { type => 'string', min => 1 },
		args => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

See L</message>.

=head3 EXAMPLE

	package My::Class;
	use App::Actions::I18N qw(i18n);
	sub greet { my $self = shift; return $self->i18n('workflow.empty', { file => 'x' }) }

=cut

sub i18n {
	my $self = shift;

	return _translator_for($self)->message(@_);
}

=head2 throw

	$self->throw('workflow.no_jobs', { file => $file });
	$self->throw('workflow.no_jobs', { file => $file, trace => 1 });

Croaks with the rendered message, reported from the perspective of the
caller of the routine that threw it, exactly as C<croak> in that routine
would have.  With C<< trace => 1 >> in the arguments it confesses instead, so
the message carries a full stack trace; there is no hand-rolled C<caller>
loop.

=head3 API SPECIFICATION

=head4 INPUT

	{
		key  => { type => 'string', min => 1 },
		args => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

Does not return.

=head3 MESSAGES

The message named by the key.

=head3 EXAMPLE

	sub load {
		my ($class, $file) = @_;
		$class->throw('workflow.file_missing', { file => $file }) unless -f $file;
		...
	}

=cut

sub throw {
	my ($self, $key, $args) = @_;

	my $text = _translator_for($self)->message($key, $args);

	# Carp skips a frame whose two packages trust each other.  Trusting the
	# module that called throw, for this call only, makes the location the
	# line that called that module - where its own croak would have pointed -
	# so moving a croak into the catalogue does not move the line a user sees.
	local our @CARP_NOT = (scalar caller);

	# A message that is advice rather than a fault in the code names no
	# place, as die "...\n" did; one raised with a trace carries the stack.
	my %options = %{ $args || {} };
	my $location = (exists $options{location} && !$options{location}) ? "\n"
		: $options{trace} ? Carp::longmess('')
		: Carp::shortmess('');

	die App::Actions::Error->new(
		code => $key,
		message => $text,
		args => $args || {},
		location => $location,
	);
}

# _translator_for
# Purpose:     Choose the translator for an object or a class name.
# Entry:       $invocant - an object, a class name, or undef.
# Exit status: Returns an App::Actions::I18N object; never fails.
# Side effects: May create the shared default translator.
sub _translator_for {
	my ($invocant) = @_;

	# Only a hash-based object can carry a translator of its own; a class
	# name or any other kind of object shares the default.
	my $own = (reftype($invocant) || '') eq 'HASH' ? $invocant->{i18n} : undef;

	return (blessed($own) && $own->isa(__PACKAGE__)) ? $own : shared();
}

# _wanted_language
# Purpose:     Work out which language the arguments, config and environment ask for.
# Entry:       $params - the validated arguments of new().
# Exit status: Returns a lower-case base language code (e.g. 'de').
# Side effects: None.
sub _wanted_language {
	my ($params) = @_;

	# The first source that says anything wins; a country that maps to no
	# catalogue says nothing, so the later sources still get their turn.
	my @candidates = (
		$params->{language},
		defined $params->{country} ? $COUNTRY_LANGUAGE{ uc $params->{country} } : undef,
		$config{language},
		$ENV{$LANGUAGE_VARIABLE},
	);
	my ($wanted) = grep { defined && length } @candidates;
	$wanted = $DEFAULT_LANGUAGE unless defined $wanted;

	# de_DE.UTF-8, de-AT and DE all mean the German catalogue.
	(my $base = lc $wanted) =~ s/[_.\-].*\z//s;

	return $base;
}

# _select
# Purpose:     Reduce a catalogue entry to a single template string.
# Entry:       $entry - a string, or a { gender => ... } / { plural => ... } hash;
#              $args  - the message arguments (gender, count).
# Exit status: Returns a template string ('' for a malformed entry).
# Side effects: None.
sub _select {
	my ($self, $entry, $args) = @_;

	# Gender is resolved before number because a gendered form may still
	# need to agree in number ("elle est partie" / "elles sont parties").
	while (ref $entry eq 'HASH') {
		if (ref $entry->{gender} eq 'HASH') {
			my $gender = defined $args->{gender} ? lc $args->{gender} : 'other';
			$entry = exists $entry->{gender}{$gender} ? $entry->{gender}{$gender} : $entry->{gender}{other};
		} elsif (ref $entry->{plural} eq 'HASH') {
			$entry = $entry->{plural}{ $self->_plural_category($args->{count}) };
		} else {
			# Neither branch: a malformed entry renders as nothing rather
			# than as a hash address.
			$entry = '';
		}
	}

	return defined $entry ? $entry : '';
}

# _plural_category
# Purpose:     Name the CLDR plural category of a count in this language.
# Entry:       $count - any value; non-numbers count as 0.
# Exit status: Returns 'one' or 'other'.
# Side effects: None.
sub _plural_category {
	my ($self, $count) = @_;

	# A count that is not a number is treated as zero, so a missing count
	# picks a form rather than warning about a non-numeric comparison.
	$count = 0 unless defined $count && $count =~ /\A-?\d+(?:\.\d+)?\z/;
	my $rule = $PLURAL_RULE{ $self->{language} } || $PLURAL_RULE{$DEFAULT_LANGUAGE};

	return $rule->(abs $count);
}

# _render
# Purpose:     Fill a template's %(name)fmt placeholders.
# Entry:       $template - the text; $args - name to value.
# Exit status: Returns the rendered string.
# Side effects: None (warnings from sprintf are suppressed by supplying defaults).
sub _render {
	my ($template, $args) = @_;

	# Each placeholder is formatted on its own, so a translation that drops
	# or repeats an argument cannot shift the others out of place.
	$template =~ s{$PLACEHOLDER}{
		my ($name, $format) = ($1, $2);
		my $value = $args->{$name};
		# A string conversion of a missing value is ''; a numeric one of a
		# missing or non-numeric value is 0.  Either way no "uninitialized"
		# or "isn't numeric" warning reaches the user's output.
		my $numeric = $format !~ /s\z/;
		$value = $numeric ? 0 : '' unless defined $value;
		$value = 0 if $numeric && !looks_like_number($value);
		sprintf("%$format", $value);
	}ge;

	return $template;
}

=head2 validate_args

	my $params = validate_args(__PACKAGE__ . '::load', \@_, \%schema, 'file');

Normalises a routine's arguments with L<Params::Get> and validates them with
L<Params::Validate::Strict>.  When they do not match, it throws an
L<App::Actions::Error> with the code C<actions.invalid_arguments>, which
reads (as a string) as the catalogue's message and the caller's line, as
a C<croak> would.  It is the one place the distribution turns a validator
failure into a user-facing message, so every public routine reports bad
arguments in the same words and the same language.

=head3 ARGUMENTS

=over 4

=item * C<$routine> - the fully qualified routine name, for the message.

=item * C<\@args> - the routine's arguments with the invocant removed.

=item * C<\%schema> - a L<Params::Validate::Strict> schema.

=item * C<$positional> - optional; the L<Params::Get> default: a key name
for a lone positional argument, or an array reference of positional names.
L<Params::Get> maps an array of names by position only, so arguments that
outnumber the names and come in pairs whose keys are all in the schema are
taken as named pairs instead: C<load_yaml_mapping(file =E<gt> $f, kind =E<gt>
'workflow')> works as well as C<load_yaml_mapping($f, 'workflow')>.  A single
pair is still positional, since it cannot be told apart from two values.

=back

=head3 RETURNS

The validated hash reference.

=head3 SIDE EFFECTS

None; throws an App::Actions::Error on invalid arguments.

=head3 EXAMPLE

	sub load {
		my $class = shift;
		my $params = validate_args(__PACKAGE__ . '::load', \@_, {
			file => { type => 'string', min => 1 },
		}, 'file');
		return $params->{file};
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		routine    => { type => 'string', min => 1 },
		args       => { type => 'arrayref' },
		schema     => { type => 'hashref' },
		positional => { type => 'string|arrayref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to     | An argument is missing, of    | Call the routine as its POD    |
	| ROUTINE: REASON          | the wrong type, or unknown    | documents                      |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub validate_args {
	my ($routine, $args, $schema, $positional) = @_;

	# Positional calls ($i18n->message('key', {...})) and named ones are both
	# accepted; Params::Get turns either into one hash.  An empty argument
	# list is an empty hash rather than Params::Get's usage error, so the
	# schema alone decides whether that is allowed.  Params::Get maps an
	# array of names by position only, so named pairs given to a routine
	# with positional names are passed as pairs.
	my $names = (ref $positional eq 'ARRAY' && @{$args} > @{$positional} && _named_pairs($args, $schema))
		? undef : $positional;
	my $given = @{$args} ? get_params($names, @{$args}) : {};

	# Params::Get fills the positions a caller left out with undef, which
	# the validator takes as given; they are removed, so that a required
	# argument that was left out is reported as missing.
	if (ref $names eq 'ARRAY') {
		delete $given->{$_} for grep { !defined $given->{$_} } @{$names}[ scalar(@{$args}) .. $#{$names} ];
	}

	# For the same reason, an undef given for a required argument would pass;
	# it is removed so that it is reported as missing.  An optional argument
	# may still be passed as undef, which means "not given".
	if (ref $given eq 'HASH') {
		delete $given->{$_} for grep {
			!defined $given->{$_} && ref $schema->{$_} eq 'HASH' && !$schema->{$_}{optional}
		} keys %{$given};
	}

	# $@ is localised: every public routine validates its arguments here, and
	# a caller's own error must survive a call that succeeds.
	my ($params, $failure);
	{
		local $@;
		$params = eval {
			validate_strict({
				args => $given,
				schema => $schema,
			});
		};
		$failure = $@;
	}
	return $params if $params;

	# The innermost "validate_strict:" clause is the specific reason, and the
	# validator may append more than one " at FILE line N." to it.
	(my $reason = $failure || 'invalid') =~ s/\A.*validate_strict:\s*//s;
	1 while $reason =~ s/\s+at \S+ line \d+\.?\s*\z//s;

	# Reported from the caller of the routine that was called wrongly, which
	# is where the mistake is.  It is an error with a code, like every other
	# failure, and reads as the croak it replaced.
	local our @CARP_NOT = (scalar caller);
	my $details = { routine => $routine, reason => $reason };
	die App::Actions::Error->new(
		code => 'actions.invalid_arguments',
		message => shared()->message('actions.invalid_arguments', $details),
		args => $details,
		location => Carp::shortmess(''),
	);
}

# _named_pairs
# Purpose:     Say whether a routine's arguments are key => value pairs.
# Entry:       $args - the arguments; $schema - the routine's schema.
# Exit status: Returns 1 when there is an even number of arguments and every
#              key position holds a plain string the schema names, else 0.
# Side effects: None.
sub _named_pairs {
	my ($args, $schema) = @_;

	my @keys = @{$args}[ grep { $_ % 2 == 0 } 0 .. $#{$args} ];
	my $named = (@{$args} % 2 == 0) && !grep { !defined || ref || !exists $schema->{$_} } @keys;

	return $named ? 1 : 0;
}

# Every _name routine above may be called only from this package.
# Sub::Private's mode is process-wide, so it is set to enforce for this one
# call rather than for good, which would change how other modules' :Private
# routines behave.
BEGIN {
	local $Sub::Private::config{mode} = 'enforce';
	Sub::Private->import(@{ App::Actions::Access->private_names(__PACKAGE__) });
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Coverage is partial.  The catalogue holds the messages of
L<App::Actions>, L<App::Actions::Workflow>, L<App::Actions::Action>,
L<App::Actions::Util>, L<App::Actions::Runner> and its parts, and the counted
phrases of L<App::Actions::Cache> and L<App::Actions::Logs>.
L<App::Actions::Check>, L<App::Actions::Docker>, L<App::Actions::Expression>,
L<App::Actions::Process> and the command-line scripts still print English
literals, so a non-English run prints a mixture.

=item * The POSIX locale is ignored on purpose.  Error text is matched by
scripts in CI, and choosing a language from C<LANG> would change it on any
host whose locale is not English.  Set C<ACTION_RUN_LANG> to opt in.

=item * Messages are character strings.  A caller printing a non-English
message to a handle without an encoding layer gets a "Wide character"
warning; the command-line scripts do not yet set one, because they also
print raw bytes captured from Docker, which an encoding layer would encode a
second time.

=item * The plural rules cover the integers the distribution counts with,
not the full CLDR rules (no fractions, no "few"/"many" categories).  A
language added with L</add_messages> uses the English rule.

=item * The catalogue is process-wide.  L</add_messages> affects every
translator, so two threads of a program that want different entries for the
same key cannot both have them.

=item * The French, German and Chinese texts were written without review by
a native speaker.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Set an encoding before you print.>  Messages are character
strings, and French, German and Chinese texts contain non-ASCII characters.
Without C<binmode STDOUT, ':encoding(UTF-8)'>, Perl prints a "Wide
character" warning.

=item * B<C<LANG> does not choose the language.>  Only C<ACTION_RUN_LANG>
(or the arguments) does.  This keeps error messages in English on CI
machines unless you ask.

=item * B<Placeholders need a conversion letter.>  Write C<%(file)s>, not
C<%(file)>: without the letter, the text is printed as it is.

=item * B<A missing value is silent.>  If C<\%args> has no value for a
placeholder, a string placeholder becomes empty and a number placeholder
becomes 0.  There is no warning, so check your keys.

=item * B<A number placeholder needs a number.>  C<%(count)d> with C<count
=E<gt> 'three'> prints 0, and the C<other> plural form is used.

=item * B<C<add_messages> changes every translator in the program>, not just
one object.  In a test, restore what you changed.

=item * B<L</shared> follows the environment.>  If C<ACTION_RUN_LANG>
changes while the program runs, the next call to L</shared> returns a new
translator in the new language.  Do not keep the object if you want that.

=item * B<C<throw> does not return.>  Code after it in the same branch never
runs.

=item * B<Keys are case sensitive.>  C<Workflow.Empty> is not
C<workflow.empty>.

=back

=head1 ENCODING

All texts in the catalogues are Perl character strings (the language
modules use C<use utf8>).  They may contain any Unicode character, including
accented letters, Chinese characters and emoji.  Values you pass in
C<\%args> may also contain any Unicode text; they are inserted as they are.
The result is a character string: encode it when you print it or write it
to a file.  Keys and placeholder names must be ASCII.  Language codes are
two or three ASCII letters, country codes two ASCII letters.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞState> means the routine changes
nothing, and C<ΔState> means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

=head2 new

	LANG ::= en | fr | de | zh
	COUNTRY == seq CHAR

	┌─ New ────────────────────────────────────────────
	│ language? : optional seq CHAR
	│ country?  : optional COUNTRY
	│ lang!     : LANG
	├───────────────────────────────────────────────────
	│ let wanted ==
	│     if language? ≠ ⊥ then base(language?)
	│     else if country? ≠ ⊥ ∧ upper(country?) ∈ dom countryLanguage
	│          then countryLanguage(upper(country?))
	│     else if config.language ≠ ⊥ then base(config.language)
	│     else if env(ACTION_RUN_LANG) ≠ ⊥ then base(env(ACTION_RUN_LANG))
	│     else en
	│ wanted ∈ dom catalogue ⇒ lang! = wanted
	│ wanted ∉ dom catalogue ⇒ lang! = en
	└───────────────────────────────────────────────────

=head2 shared

	┌─ Default ─────────────────────────────────────────
	│ ΔCache
	│ t! : Translator
	├───────────────────────────────────────────────────
	│ cache ≠ ⊥ ∧ cache.source = currentSource ⇒ t! = cache ∧ cache' = cache
	│ cache = ⊥ ∨ cache.source ≠ currentSource ⇒ t! = New(∅) ∧ cache' = t!
	└───────────────────────────────────────────────────

=head2 language

	┌─ Language ────────────────────────────────────────
	│ ΞTranslator
	│ lang! : LANG
	├───────────────────────────────────────────────────
	│ lang! = θTranslator.lang
	└───────────────────────────────────────────────────

=head2 languages

	┌─ Languages ───────────────────────────────────────
	│ ΞCatalogue
	│ langs! : seq LANG
	├───────────────────────────────────────────────────
	│ ran langs! = dom catalogue ∧ langs! is sorted
	└───────────────────────────────────────────────────

=head2 catalogue_keys

	┌─ CatalogueKeys ───────────────────────────────────
	│ ΞCatalogue
	│ lang? : seq CHAR
	│ keys! : seq KEY
	├───────────────────────────────────────────────────
	│ lang? ∈ dom catalogue ⇒ ran keys! = dom catalogue(lang?) ∧ keys! is sorted
	│ lang? ∉ dom catalogue ⇒ keys! = ⟨⟩
	└───────────────────────────────────────────────────

=head2 language_for_country

	┌─ LanguageForCountry ──────────────────────────────
	│ country? : COUNTRY
	│ lang!    : optional LANG
	├───────────────────────────────────────────────────
	│ #country? = 2
	│ upper(country?) ∈ dom countryLanguage ⇒ lang! = countryLanguage(upper(country?))
	│ upper(country?) ∉ dom countryLanguage ⇒ lang! = ⊥
	└───────────────────────────────────────────────────

=head2 message

	ENTRY ::= text⟨⟨STRING⟩⟩ | plural⟨⟨CATEGORY ⇸ ENTRY⟩⟩ | gender⟨⟨GENDER ⇸ ENTRY⟩⟩

	┌─ Message ─────────────────────────────────────────
	│ ΞTranslator
	│ key?  : KEY
	│ args? : NAME ⇸ VALUE
	│ text! : STRING
	├───────────────────────────────────────────────────
	│ key? ∈ dom catalogue(lang)
	│     ⇒ text! = render(select(catalogue(lang)(key?), args?), args?)
	│ key? ∉ dom catalogue(lang) ∧ key? ∈ dom catalogue(en)
	│     ⇒ text! = render(select(catalogue(en)(key?), args?), args?)
	│ key? ∉ dom catalogue(lang) ∪ dom catalogue(en)
	│     ⇒ text! = key?
	└───────────────────────────────────────────────────

=head2 add_messages

	┌─ AddMessages ─────────────────────────────────────
	│ ΔCatalogue
	│ lang?    : LANG
	│ entries? : KEY ⇸ ENTRY
	├───────────────────────────────────────────────────
	│ catalogue' = catalogue ⊕ {lang? ↦ (catalogue(lang?) ⊕ entries?)}
	└───────────────────────────────────────────────────

=head2 i18n

	┌─ I18n ────────────────────────────────────────────
	│ self? : Object
	│ text! : STRING
	├───────────────────────────────────────────────────
	│ self?.i18n ≠ ⊥ ⇒ text! = Message[self?.i18n/θTranslator]
	│ self?.i18n = ⊥ ⇒ text! = Message[Shared/θTranslator]
	└───────────────────────────────────────────────────

=head2 throw

	┌─ Throw ───────────────────────────────────────────
	│ self? : Object
	│ key?  : KEY
	│ args? : NAME ⇸ VALUE
	├───────────────────────────────────────────────────
	│ raises Exception(I18n(self?, key?, args?))
	└───────────────────────────────────────────────────

=head2 validate_args

	┌─ ValidateArgs ────────────────────────────────────
	│ routine? : seq CHAR
	│ args?    : seq VALUE
	│ schema?  : NAME ⇸ RULE
	│ params!  : NAME ⇸ VALUE
	├───────────────────────────────────────────────────
	│ let p == getParams(positional?, args?)
	│ satisfies(p, schema?) ⇒ params! = coerce(p, schema?)
	│ ¬ satisfies(p, schema?) ⇒ raises InvalidArguments(routine?)
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

A translator object never changes its language after it is made.  The
catalogue (shared by every translator) and the L</shared> translator do
change:

	 Choosing a language (new):

	   language arg? --yes--> use it
	        | no
	   country arg?  --yes--> language_for_country(country)
	        | no
	   $config{language}? --yes--> use it
	        | no
	   ACTION_RUN_LANG? --yes--> use it
	        | no
	   English
	        |
	        v  reduce to the base code (de_DE.UTF-8 -> de)
	   catalogue for it?  --no--> warn; use English
	        | yes
	        v
	   +-----------------+
	   |  TRANSLATOR     |  language fixed
	   +-----------------+

	 Rendering a message (message / i18n / throw):

	   key in the language's catalogue? --no--> key in English? --no--> warn;
	        | yes                                    | yes             text = the key
	        v                                        v
	   entry --------------------------------> entry
	        |
	        v
	   gender form (args.gender) -> plural form (args.count, language rule)
	        |
	        v
	   fill in %(name)s placeholders -> text
	        |
	        +-- message / i18n: return the text
	        +-- throw: die with App::Actions::Error(code = key, message = text,
	                   location = caller's " at FILE line N.")

	 The shared translator:

	   +-----------+  shared()  +-----------------+  shared() with the same
	   |   NONE    |----------->|  CACHED (for    |  config{language} and
	   +-----------+            |  config+ENV)    |<-+ ACTION_RUN_LANG
	                            +-----------------+--+
	                                    |
	                                    | config{language} or ACTION_RUN_LANG
	                                    | changed, then shared()
	                                    v
	                            new translator replaces the cached one

	 The catalogue:

	   +----------------+  add_messages($lang, \%entries)  +----------------+
	   | BUILT-IN       |--------------------------------->| EXTENDED       |
	   | (en, fr, de,   |  (new language: created, with    | (for every     |
	   |  zh)           |   the English plural rule)       |  translator)   |
	   +----------------+                                  +----------------+

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
