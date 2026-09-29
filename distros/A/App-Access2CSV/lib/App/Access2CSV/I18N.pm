package App::Access2CSV::I18N;

use strict;
use warnings;
use autodie qw(:all);

# Sub::Private must be switched to enforce mode before it is loaded,
# otherwise it falls back to namespace mode, which breaks OO dispatch
BEGIN { $Sub::Private::config{mode} = 'enforce' }

use Carp qw(carp confess croak);
use Config;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Return::Set qw(set_return);
use Sub::Private;
use Sub::Protected;

our $VERSION = '0.001.0';

# The wrappers installed by Sub::Private/Sub::Protected add stack frames;
# listing them here stops Carp from blaming the wrapper for our errors
our @CARP_NOT = qw(Sub::Private Sub::Protected);

# Catalog used when no better match for the user's locale exists
Readonly::Scalar my $DEFAULT_LANGUAGE => 'en';

# Locale values that mean "no preference" rather than a real language
Readonly::Hash my %NEUTRAL_LOCALES => (C => 1, POSIX => 1);

# Environment variables consulted, most specific first (GNU gettext order)
Readonly::Array my @LOCALE_VARIABLES => qw(LANGUAGE LC_ALL LC_MESSAGES LANG);

# Characters that a terminal or log viewer would act on rather than show:
# C0 controls except tab (ESC starts escape sequences, CR overwrites the
# line, LF forges new log lines, BEL rings), DEL, and the invisible
# text-direction controls.  C1 controls are matched as characters in
# Perl character strings and as their UTF-8 bytes in byte strings.
#
# One character class (faster than alternatives), made of these ranges:
#	\x00-\x08 \x0A-\x1F   C0 controls, except tab (\x09)
#	\x7F                  DEL
#	\x{80}-\x{9F}         C1 controls (U+009B works like ESC [)
#	\x{200E}\x{200F}      left-to-right and right-to-left marks
#	\x{202A}-\x{202E}     embeddings and overrides (U+202E is RLO)
#	\x{2066}-\x{2069}     isolates
# (No spaces or comments inside the brackets: /x does not apply there.)
Readonly::Scalar my $UNPRINTABLE_RE =>
	qr/[\x00-\x08\x0A-\x1F\x7F\x{80}-\x{9F}\x{200E}\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}]/;
Readonly::Scalar my $UNPRINTABLE_BYTES_RE => qr/
	  [\x00-\x08\x0A-\x1F\x7F]      # C0 controls except tab, and DEL
	| \xC2 [\x80-\x9F]              # C1 controls, UTF-8 encoded
	| \xE2 \x80 [\x8E\x8F\xAA-\xAE]  # LRM, RLM, embeddings, overrides
	| \xE2 \x81 [\xA6-\xA9]          # isolates
/x;

# Coverage: Devel::Cover finds code through the symbol table, but in
# enforce mode Sub::Private and Sub::Protected replace every private and
# protected sub there with a wrapper (at CHECK time), so the real subs
# would never appear in coverage reports.  Only when Devel::Cover is
# loaded, give each sub of this distribution a second name, in a package
# nothing calls, before the wrapping happens.  CHECK blocks run
# last-defined first, so this one runs before the attribute handlers'.
Readonly::Array my @OWN_PACKAGES => qw(App::Access2CSV App::Access2CSV::Exporter App::Access2CSV::I18N);
Readonly::Scalar my $UNWRAPPED => 'App::Access2CSV::_Unwrapped';

CHECK {
	if($INC{'Devel/Cover.pm'}) {
		require B;
		no strict 'refs';
		foreach my $package (@OWN_PACKAGES) {
			foreach my $name (keys %{"${package}::"}) {
				my $code = *{"${package}::$name"}{CODE} or next;
				# Only subs written in this package, not imported ones
				next unless B::svref_2object($code)->GV->STASH->NAME eq $package;
				*{"${UNWRAPPED}::${package}::$name"} = $code;
			}
		}
	}
}

# Signals that mean "stop now": Ctrl-C is INT, Ctrl-\ is QUIT; TERM and
# HUP come from kill, service managers and closed terminals
Readonly::Array my @INTERRUPT_SIGNALS => qw(INT QUIT TERM HUP);

# Plural category used when a language has no rule of its own
Readonly::Scalar my $PLURAL_OTHER => 'other';

# CLDR-style plural rules.  Each returns the category name for a count.
# Only languages whose rule differs from English need an entry here.
Readonly::Hash my %PLURAL_RULES => (
	en => sub { $_[0] == 1 ? 'one' : 'other' },
	de => sub { $_[0] == 1 ? 'one' : 'other' },
	fr => sub { ($_[0] == 0 || $_[0] == 1) ? 'one' : 'other' },
	ja => sub { 'other' },
	ko => sub { 'other' },
	zh => sub { 'other' },
);

# Message catalog: language => key => template.
# A template is either a sprintf() format, or a hashref whose keys are
# contexts (for example 'male'/'female') and/or plural categories
# ('zero', 'one', 'two', 'few', 'many', 'other').
# It is a package variable, not Readonly, so that applications and
# Object::Configure style configuration can add languages or override text.
our %MESSAGES = (
	en => {
		column_output      => 'OUTPUT FILE',
		column_rows        => 'ROWS',
		column_table       => 'TABLE',
		count_unreadable   => 'mdb-count printed no number: "%s"',
		count_failed       => 'Cannot count the rows of %s: %s',
		database_not_file  => 'Database %s is not a regular file',
		database_not_found => 'Cannot read database %s: %s',
		database_unreadable => 'Database %s is not readable',
		dry_run_title      => 'DRY RUN',
		export_failed      => 'FAILED: %s: %s',
		exported           => 'Exported %s => %s',
		exported_rows      => {
			one   => 'Exported %s => %s (%d row)',
			other => 'Exported %s => %s (%d rows)',
		},
		fatal              => 'access2csv: %s',
		invalid_name       => 'the name contains a NUL byte',
		interrupted_reading => 'Interrupted by SIG%s while reading the database from standard input',
		interrupted        => 'Interrupted by SIG%s: stopped, and the table being exported was discarded',
		invalid_setting    => 'Invalid setting: %s',
		invalid_utf8       => 'Table %s, line %d: output of mdb-export is not valid UTF-8',
		log_failed         => 'Cannot write to the log: %s',
		log_is_symlink     => 'it is a symbolic link',
		log_open_failed    => 'Cannot open log file %s: %s',
		logger_unavailable => 'no logger was created',
		missing_database   => 'Missing database filename',
		needs_object       => 'run() must be called on an object created by new()',
		mkdir_failed       => 'Cannot create output directory %s: %s',
		no_row_counter     => 'mdb-count not found in PATH; row counts are unavailable',
		output_exists      => 'Output file already exists: %s (use --overwrite to replace it)',
		program_failed     => '%s failed with exit status %d: %s',
		program_found      => 'Found %s at %s',
		program_missing    => 'Required program not found in PATH: %s',
		program_not_run    => '%s could not be run: %s',
		program_signalled  => '%s was killed by signal %d',
		progress           => '[%d/%d] %s',
		summary            => {
			one   => 'Processed %d table, %d failed',
			other => 'Processed %d tables, %d failed',
		},
		stdin_empty        => 'Standard input is empty: no database was piped in',
		stdin_is_terminal  => 'Standard input is a terminal: pipe the database in, or give its file name',
		stdin_read_failed  => 'Cannot read standard input: %s',
		version            => 'access2csv version %s',
		unknown_message    => 'Unknown message key: %s',
		unknown_tables     => {
			one   => 'Table not found in database: %s',
			other => 'Tables not found in database: %s',
		},
		unmappable         => 'Table %s, line %d: cannot be represented in %s',
		write_failed       => 'Cannot write %s: %s',
	},
);

=encoding utf8

=head1 NAME

App::Access2CSV::I18N - Message catalog and translated error messages for App::Access2CSV

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

	use App::Access2CSV::I18N;

	# 1. Get a message as text
	my $text = App::Access2CSV::I18N->i18n('missing_database');
	# "Missing database filename"

	# 2. Fill in values (the message has %s and %d placeholders)
	print App::Access2CSV::I18N->i18n('progress', { params => [1, 3, 'Customers'] }), "\n";
	# "[1/3] Customers"

	# 3. Let the count choose between singular and plural
	print App::Access2CSV::I18N->i18n('summary', { params => [$n, 0], count => $n }), "\n";
	# $n == 1: "Processed 1 table, 0 failed"
	# $n == 4: "Processed 4 tables, 0 failed"

	# 4. Add a translation.  Keys you do not translate stay in English.
	$App::Access2CSV::I18N::MESSAGES{de}{missing_database} =
		'Name der Datenbankdatei fehlt';
	$ENV{LANG} = 'de_DE.UTF-8';

	# 5. Use it as a base class, to get i18n() and the error helpers
	package My::Tool;
	use parent 'App::Access2CSV::I18N';

	sub check {
		my ($self, $file) = @_;
		$self->_croak_i18n('database_not_file', { params => [$file] }) unless -f $file;
		return $self;
	}

=head1 DESCRIPTION

Every message that App::Access2CSV prints, logs or throws is looked up
here, by a short name called a I<key> (for example C<output_exists>).
This keeps all the text in one place, so the program can be translated.

The text for each key is a I<template>.  A template is usually a
C<sprintf> format: C<%s> is replaced by a text value and C<%d> by a whole
number, in order.  A template can also have different forms:

=over 4

=item * B<Plural forms>, chosen by a count: C<one> for one item,
C<other> for any other number.  Some languages use more forms
(C<zero>, C<two>, C<few>, C<many>).

=item * B<Context forms>, chosen by a word you give, such as C<male> or
C<female>.  A context form can itself contain plural forms.

=back

The templates live in the hash C<%App::Access2CSV::I18N::MESSAGES>:

	%MESSAGES = (
		en => {
			missing_database => 'Missing database filename',
			summary => {
				one   => 'Processed %d table, %d failed',
				other => 'Processed %d tables, %d failed',
			},
			...
		},
	);

Only English (C<en>) is included.

=head2 Which language is used

=over 4

=item 1. The C<language> field of the object, if you call C<i18n> on an
object that has one (for example
C<< App::Access2CSV::Exporter->new(language => 'en') >>).

=item 2. Otherwise the first of these environment variables that is set
and is not C<C> or C<POSIX>: C<LANGUAGE>, C<LC_ALL>, C<LC_MESSAGES>,
C<LANG>.  Only the language part is used: C<de_DE.UTF-8> means C<de>.
Upper or lower case does not matter.  C<LANGUAGE> can hold a list such as
C<fr:de>; only the first entry is used.  An empty value, or an empty
first entry (C<:de>), counts as "not set", so the next variable is tried.

=item 3. If there is no catalog for that language, English is used.

=back

Inside a language, a key that has no translation falls back to the
English text, one key at a time.

=head2 Helpers for subclasses

Subclasses get two protected methods.  They can be called only from this
class and its subclasses:

=over 4

=item * C<< $self->_croak_i18n($key, \%args) >> - throws an exception
(with L<Carp/croak>) with the translated message.  It never returns.

=item * C<< $self->_carp_i18n($key, \%args) >> - warns (with
L<Carp/carp>) with the translated message, with control characters
escaped.  It returns C<$self>.

=item * C<< $self->_printable($text) >> - returns C<$text> with control
characters (C0 except tab, DEL, C1, and text-direction controls) shown
as escapes such as C<\x1B>, so that text from an untrusted database is
safe to print or log.

=back

=head1 ENCODING

=over 4

=item * B<The English catalog> is plain ASCII.

=item * B<Values in params> are copied into the message as they are.
Byte strings (such as UTF-8 file names from the command line) stay byte
strings, so non-ASCII text and emoji come out unchanged when printed.

=item * B<Translations with non-ASCII text> (for example German C<ue>
written as one letter, or Japanese) must be Perl character strings: write
them in a source file with C<use utf8;>.  Do not mix them with UTF-8
I<byte> strings in C<params>, or the bytes will be encoded a second time.
When you print such messages, give the output handle an encoding, for
example C<binmode(STDERR, ':encoding(UTF-8)')>, or Perl warns
"Wide character in print".

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Percent signs.>  A template with no C<params> is returned
exactly as written, so C<100%> is safe.  But when you give C<params>, the
template goes through C<sprintf>, so a literal percent sign must be
written C<%%>.

=item * B<Number of values.>  Give exactly as many C<params> as the
template has placeholders.  Too few gives a Perl "Missing argument"
warning; C<undef> in C<params> gives a "Use of uninitialized value"
warning.

=item * B<No count means plural.>  If you do not give C<count>, the
C<other> form is used, even if the number in C<params> is 1.

=item * B<Replacing a key replaces all of its forms.>
C<%MESSAGES> is not merged in depth.  If you set
C<< $MESSAGES{en}{summary} = 'Done' >>, the C<one> and C<other> forms of
C<summary> are gone.  If a translation gives a plural hash, it should have
an C<other> form: when no form fits, the English text for that key is
used instead.

=item * B<Unknown context.>  A C<context> that the template does not have
is ignored; the plural forms (or the plain text) are used instead.

=item * B<Unknown keys are fatal.>  A key that is not in the English
catalog is a programming error: C<i18n> calls C<confess>, which stops the
program and prints a stack trace.

=item * B<undef arguments.>  C<undef> for C<args>, or for a field inside
the hashref form, is treated as "not given".  C<undef> as the key is
reported as a missing key.

=item * B<Load with use, not require.>  The protection of C<_croak_i18n>
and C<_carp_i18n> is set up at compile time.  After a run-time
C<require> it is missing, and Perl prints "Too late to run CHECK block".

=back

=head1 METHODS

=head2 i18n

=head3 Purpose

Turn a message key into text in the user's language.  Choose the right
context and plural form, then fill in the values.

=head3 Arguments

You can call C<i18n> on the class or on an object.  There are two ways
to give the arguments:

	$obj->i18n($key, \%args);
	$obj->i18n({ key => $key, args => \%args });

=over 4

=item C<key> (string, required)

The message key, for example C<'output_exists'>.

=item C<args> (hash reference, optional)

=over 4

=item C<params> - an array reference of the values for the placeholders,
in order.

=item C<count> - a whole number, 0 or more, that chooses the plural form.

=item C<context> - a word that chooses a context form, for example
C<'female'>.

=back

=back

=head3 Returns

The message as a string, without a newline at the end.

=head3 Side Effects

None.  It only reads C<%MESSAGES> and C<%ENV>.  Your C<$@>, C<$!> and
C<$_> are left as they were.

=head3 Usage

	my $text = $self->i18n('summary', { params => [3, 0], count => 3 });

=head3 EXAMPLE

	# "Output file already exists: out/Orders.csv (use --overwrite to replace it)"
	my $msg = App::Access2CSV::I18N->i18n('output_exists', { params => ['out/Orders.csv'] });

	# A message with context and plural forms
	$App::Access2CSV::I18N::MESSAGES{en}{greeting} = {
		female => { one => 'She sent %d letter', other => 'She sent %d letters' },
		other  => 'They sent %d letters',
	};
	print App::Access2CSV::I18N->i18n('greeting',
		{ params => [2], count => 2, context => 'female' }), "\n";
	# "She sent 2 letters"

=head3 API SPECIFICATION

=head4 Input

	{
		key => {
			type     => 'string',
			min      => 1,
			optional => 0,
		},
		args => {
			type     => 'hashref',
			optional => 1,
			schema   => {
				params  => { type => 'arrayref', optional => 1 },
				count   => { type => 'integer', optional => 1, min => 0 },
				context => { type => 'string', optional => 1 },
			},
		},
	}

Valid and invalid values (tested in F<t/domain.t>):

	key      valid:   a key in the English catalog
	         invalid: "" (1 character is the minimum), undef, a
	                  reference, an unknown key (fatal: "Unknown message
	                  key"), a known key with extra characters
	count    valid:   whole numbers from 0 up (0 is the minimum; 2**53
	                  works); undef means "no count"
	         invalid: -1 and below, fractions (1.5), words
	         edges:   English and German: 1 is singular, 0 and 2 plural.
	                  French: 0 and 1 singular.  Japanese, Korean,
	                  Chinese: always the "other" form
	params   any number of values, including none; each value is
	         copied into the text exactly, whether it is a Perl
	         character string or UTF-8 bytes (non-ASCII letters,
	         emoji, joined emoji, combining marks, right-to-left text)
	context  any string; one the template does not have (including "")
	         is ignored; a reference is invalid
	language (from the environment) the first 2 or 3 letters, in any
	         case; 1 letter, non-ASCII letters, C and POSIX all mean
	         "no language"

=head4 Output

	{
		type => 'string',
	}

=head3 MESSAGES

	+-----------------------------+-------------------------------+---------------------------------+
	| Message                     | Meaning                       | What to do                      |
	+-----------------------------+-------------------------------+---------------------------------+
	| Unknown message key: KEY    | KEY is not in the English     | Programming error: add KEY to   |
	|  (fatal, with stack trace)  | catalog                       | $MESSAGES{en}                   |
	| Required parameter 'key' is | No key was given              | Give a key                      |
	|  missing (fatal)            |                               |                                 |
	| Unknown parameter 'X'       | args has a field that is not  | Use only params, count and      |
	|  (fatal)                    | params, count or context      | context                         |
	| Parameter 'count' (X) must  | count is negative or not a    | Give a whole number, 0 or more  |
	|  be ... (fatal)             | whole number                  |                                 |
	| Parameter 'params' must be  | params is not an array        | Give an array reference         |
	|  an arrayref (fatal)        | reference                     |                                 |
	+-----------------------------+-------------------------------+---------------------------------+

=head3 PSEUDOCODE

	check key and args
	lang := the object's language, or the language from the environment,
	        or English if there is no catalog for it
	for try in (lang, then en if lang is not en):   # at most 2 tries, no recursion
		entry := catalog[try][key], or else catalog[en][key]
		if entry has forms and one matches args.context:
			entry := that form
		if entry still has forms:
			entry := the form for plural_category(try, count),
			         or else the "other" form
		stop if entry is now a plain string
	if no try gave a plain string: confess (the catalog is broken)
	if there are params: return sprintf(entry, params)
	else: return entry unchanged

=cut

sub i18n {
	my $self = shift;

	# Validation uses eval internally; the caller's $@ must survive
	local $@;

	# Accept both i18n('key', {...}) and i18n({ key => ..., args => {...} })
	# Undefined values are dropped so that validation reports them as missing
	my $in = (ref($_[0]) eq 'HASH') ? { %{ $_[0] } } : { key => $_[0], args => $_[1] };
	delete @{$in}{ grep { !defined $in->{$_} } keys %{$in} };

	my $params = validate_strict(
		schema => {
			key  => { type => 'string', min => 1 },
			args => {
				type     => 'hashref',
				optional => 1,
				schema   => {
					params  => { type => 'arrayref', optional => 1 },
					count   => { type => 'integer', optional => 1, min => 0 },
					context => { type => 'string', optional => 1 },
				},
			},
		},
		input => $in,
	);
	my $args = $params->{args} || {};

	# Resolve the template in the user's language, falling back to English
	# Try the chosen language, then English: a fixed list of at most two
	# attempts.  There is deliberately no recursion here, so no mistake in
	# choosing the language (a bug, or a mutation of _language) can ever
	# make this loop forever.
	my $key = $params->{key};
	# An undefined language (only possible through a bug) means English
	my $lang = $self->_language() // $DEFAULT_LANGUAGE;
	my $entry;
	foreach my $try ($lang eq $DEFAULT_LANGUAGE ? ($lang) : ($lang, $DEFAULT_LANGUAGE)) {
		$entry = _narrow($self->_lookup($try, $key), $try, $args);
		last if defined $entry;
	}

	# Premise 1: every English template is complete.  Premise 2: not even
	# the English one gave a usable form.  Conclusion: the catalog is
	# broken, which is a programming error.
	_unknown_key($key) unless defined $entry;

	# A literal message with no placeholders is returned untouched, which
	# protects any '%' characters it contains from sprintf()
	# Use the validated array reference directly rather than copying it
	my $values = $args->{params};
	my $text = ($values && @{$values}) ? sprintf($entry, @{$values}) : $entry;

	return set_return($text, { type => 'string' });
}

# _croak_i18n
# Purpose:        Throw a localised exception from the caller's point of view.
# Entry Criteria: $key is a catalog key; $args is an optional i18n() hashref.
# Exit Status:    Never returns; always croaks.
# Side Effects:   Unwinds the stack with a Carp exception.
sub _croak_i18n :Protected {
	my ($self, $key, $args) = @_;

	croak($self->i18n($key, $args));
}

# _carp_i18n
# Purpose:        Emit a localised warning from the caller's point of view.
# Entry Criteria: $key is a catalog key; $args is an optional i18n() hashref.
# Exit Status:    Returns $self for chaining.
# Side Effects:   Writes a warning to STDERR (or $SIG{__WARN__}).
sub _carp_i18n :Protected {
	my ($self, $key, $args) = @_;

	carp($self->_printable($self->i18n($key, $args)));
	return $self;
}

# _interrupt_signals
# Purpose:        List the "stop now" signals that this program may take
#                 over: those that exist on this system and that nobody
#                 has set a handler for.  Used by code that must clean up
#                 (delete temporary files) when stopped, since Perl's
#                 default action for these signals skips all clean-up.
# Entry Criteria: None.
# Exit Status:    Returns an arrayref of signal names, e.g. ['INT', 'TERM'].
#                 The caller localises %SIG for exactly these names.
# Side Effects:   None.
sub _interrupt_signals :Protected {
	my %exists = map { $_ => 1 } split ' ', $Config{sig_name};
	return [ grep { $exists{$_} && ($SIG{$_} // 'DEFAULT') eq 'DEFAULT' } @INTERRUPT_SIGNALS ];
}

# _printable
# Purpose:        Make text safe to show on a terminal or write to a log,
#                 by replacing control characters with visible escapes
#                 such as \x1B.  Text may come from a hostile database
#                 (table names, mdbtools error output).
# Entry Criteria: $text is a string (Perl characters or UTF-8 bytes) or undef.
# Exit Status:    Returns the escaped string ('' for undef).
# Side Effects:   None.
sub _printable :Protected {
	my ($self, $text) = @_;

	$text //= '';
	if(utf8::is_utf8($text)) {
		$text =~ s/($UNPRINTABLE_RE)/sprintf(ord($1) > 0xFF ? '\\x{%X}' : '\\x%02X', ord $1)/ge;
	} else {
		$text =~ s{($UNPRINTABLE_BYTES_RE)}{join(q{}, map { sprintf(q{\\x%02X}, ord) } split(//, $1))}ge;
	}
	return $text;
}

# _language
# Purpose:        Work out which catalog language to use.
# Entry Criteria: $self is a class name or an object (optionally with {language}).
# Exit Status:    Returns a lower-case language code, e.g. 'en' or 'de'.
# Side Effects:   None; reads %ENV only.
sub _language :Private {
	my $self = shift;

	# An explicit per-object choice beats anything in the environment.
	# Otherwise take the first meaningful locale variable; LANGUAGE may be
	# a colon-separated preference list, so only its first entry counts.
	# Empty values and C/POSIX mean "no preference", so they are skipped.
	my $wanted = ref($self) && $self->{language};
	($wanted) = grep { length && !$NEUTRAL_LOCALES{$_} }
		map { (split /:/, $ENV{$_} // '')[0] // '' } @LOCALE_VARIABLES
		unless $wanted;

	# "de_DE.UTF-8@euro" -> "de"; anything unparseable means English
	my ($code) = ($wanted // '') =~ /\A([A-Za-z]{2,3})(?:[_\-.@]|\z)/;
	return (defined($code) && exists($MESSAGES{lc $code})) ? lc($code) : $DEFAULT_LANGUAGE;
}

# _lookup
# Purpose:        Fetch the raw template for $key in $lang.
# Entry Criteria: $lang is a catalog language; $key is a non-empty string.
# Exit Status:    Returns a string or hashref template.
# Side Effects:   confess()es if $key is missing from the default catalog,
#                 because that can only be a programming error.
sub _lookup :Private {
	my ($self, $lang, $key) = @_;

	# A partial translation silently falls back to English per key
	foreach my $catalog ($MESSAGES{$lang}, $MESSAGES{$DEFAULT_LANGUAGE}) {
		return $catalog->{$key} if $catalog && exists($catalog->{$key});
	}

	return _unknown_key($key);
}

# _narrow
# Purpose:        Reduce a template to one sprintf() format: first the
#                 form for the context (if the template has one), then
#                 the plural form for the count, falling back to "other".
# Entry Criteria: $entry is a string or hashref template; $lang is the
#                 language whose plural rule applies; $args is the
#                 validated i18n() args hashref.
# Exit Status:    Returns a plain string, or undef if the template has no
#                 usable form (a gap in a translation).
# Side Effects:   None.  A plain function, not a method.
sub _narrow :Private {
	my ($entry, $lang, $args) = @_;

	if(ref($entry) eq 'HASH' && defined($args->{context}) && exists($entry->{$args->{context}})) {
		$entry = $entry->{$args->{context}};
	}
	if(ref($entry) eq 'HASH') {
		my $category = _plural_category($lang, $args->{count});
		$entry = exists($entry->{$category}) ? $entry->{$category} : $entry->{$PLURAL_OTHER};
	}
	return (defined($entry) && !ref($entry)) ? $entry : undef;
}

# _unknown_key
# Purpose:        Report a message key that the English catalog lacks.
# Entry Criteria: $key is the key that could not be resolved.
# Exit Status:    Never returns; always confesses (a stack trace helps,
#                 because this can only be a programming error).
# Side Effects:   Unwinds the stack.
# The text is built directly from the catalog, not through i18n(), which
# could recurse forever if 'unknown_message' itself were missing.
sub _unknown_key :Private {
	my $key = shift;

	confess(sprintf($MESSAGES{$DEFAULT_LANGUAGE}{unknown_message} || 'Unknown message key: %s', $key));
}

# _plural_category
# Purpose:        Map a count to a CLDR plural category for a language.
# Entry Criteria: $lang is a language code; $count is a non-negative
#                 integer or undef (undef means "no plural choice").
# Exit Status:    Returns a category name such as 'one' or 'other'.
# Side Effects:   None.  A plain function, not a method.
sub _plural_category :Private {
	my ($lang, $count) = @_;

	my $rule = $PLURAL_RULES{$lang} || $PLURAL_RULES{$DEFAULT_LANGUAGE};
	return defined($count) ? $rule->($count) : $PLURAL_OTHER;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Only an English catalog is included.  Other languages fall back
to English, one key at a time.

=item * Plural rules exist only for a few languages (C<en>, C<de>, C<fr>,
C<ja>, C<ko>, C<zh>).  Other languages use the English rule.

=item * Messages from other modules (for example
L<Params::Validate::Strict> and L<autodie>) are not translated.

=item * L<Sub::Private> and L<Sub::Protected> set up their protection at
C<CHECK> time.  If this module is first loaded at run time (with
C<require> after the program has been compiled), Perl warns
"Too late to run CHECK block" and the private and protected helpers are
B<not> protected.

=back

=head1 SEE ALSO

L<App::Access2CSV>, L<App::Access2CSV::Exporter>

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=head1 FORMAL SPECIFICATION

These schemas use the Z notation.  C<?> marks an input and C<!> an
output.  You do not need to read this section to use the module.

	[KEY, LANG, CTX, VALUE]
	CATEGORY ::= zero | one | two | few | many | other
	TEMPLATE ::= text⟨⟨seq CHAR⟩⟩
	           | forms⟨⟨(CTX ∪ CATEGORY) ⇸ TEMPLATE⟩⟩

	┌─ Catalog ──────────────────────────────────────────────────
	│ MESSAGES : LANG ⇸ (KEY ⇸ TEMPLATE)
	│ plural : LANG × ℕ → CATEGORY
	├────────────────────────────────────────────────────────────
	│ en ∈ dom MESSAGES
	└────────────────────────────────────────────────────────────

=head2 i18n

	┌─ I18n ─────────────────────────────────────────────────────
	│ ΞCatalog
	│ key? : KEY ; params? : seq VALUE ; count? : ℕ ; context? : CTX
	│ userLang : LANG ; lang : LANG ; msg! : seq CHAR
	├────────────────────────────────────────────────────────────
	│ key? ∈ dom MESSAGES(en)
	│ lang = (if userLang ∈ dom MESSAGES then userLang else en)
	│ t₀ = (if key? ∈ dom MESSAGES(lang)
	│        then MESSAGES(lang)(key?) else MESSAGES(en)(key?))
	│ t₁ = (if t₀ = forms(f) ∧ context? ∈ dom f then f(context?) else t₀)
	│ t₂ = (if t₁ = forms(g)
	│        then (if plural(lang, count?) ∈ dom g
	│              then g(plural(lang, count?)) else g(other))
	│        else t₁)
	│ msg! = (if params? = ⟨⟩ then t₂ else sprintf(t₂, params?))
	└────────────────────────────────────────────────────────────

	┌─ I18nUnknownKey ───────────────────────────────────────────
	│ ΞCatalog
	│ key? : KEY ; error! : seq CHAR
	├────────────────────────────────────────────────────────────
	│ key? ∉ dom MESSAGES(en)
	│ error! = "Unknown message key: " ⁀ key?
	└────────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

This module keeps no state between calls: C<i18n> only reads
C<%MESSAGES> and C<%ENV>.  The diagram shows the steps of one call.
Each box is a step.  Each arrow shows what decides the next step.

	      i18n($key, \%args)
	              |
	              v
	     +------------------+  key missing, or args
	     |    VALIDATING    |  has a bad field
	     +------------------+-----------------------------+
	              | OK                                    |
	              v                                       |
	     +------------------+                             |
	     | CHOOSING LANGUAGE|  object language, else      |
	     |                  |  LANGUAGE/LC_ALL/           |
	     |                  |  LC_MESSAGES/LANG, else en  |
	     +------------------+                             |
	              |                                       |
	              v                                       v
	     +------------------+  key not in       +------------------+
	     |  LOOKING UP KEY  |  English either   |      FATAL       |
	     | (language, then  |------------------>| croak / confess  |
	     |  English)        |                   +------------------+
	     +------------------+
	              | template found
	              v
	     +------------------+  plain text
	     | NARROWING FORMS  |-----------------------+
	     | 1. context form  |                       |
	     | 2. plural form   |                       |
	     |    (else other)  |                       |
	     +------------------+                       |
	              | one plain template left         |
	              v                                 v
	     +------------------+  no params    +------------------+
	     |   FORMATTING     |-------------->|   return text    |
	     | sprintf(params)  |-------------->|   unchanged /    |
	     +------------------+   params      |   formatted      |
	                                        +------------------+

=cut
