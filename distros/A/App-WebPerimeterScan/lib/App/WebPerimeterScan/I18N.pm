package App::WebPerimeterScan::I18N;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(carp confess croak);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Sub::Private { mode => 'enforce' };
use Sub::Protected;

use App::WebPerimeterScan::Messages ();

our $VERSION = '0.001.0';

# Run-time settings.  A plain hash rather than Readonly so that a caller, or
# Object::Configure, can pin a language for a whole run.
our %config = (
	# undef: take the language from the environment on every call.
	language => undef,
	# The catalogue every other language falls back to, key by key.
	fallback => 'en',
);

# Where the language comes from, most specific first.  LANGUAGE is GNU
# gettext's colon-separated preference list; the rest are POSIX.
Readonly::Array my @LOCALE_VARIABLES => qw(LANGUAGE LC_ALL LC_MESSAGES LANG);

# Locale names that mean "no preference", so they must not select a catalogue.
Readonly::Hash my %NEUTRAL_LOCALE => (C => 1, POSIX => 1);

# {name} or {name:%.1f} - the optional part is handed to sprintf.
Readonly::Scalar my $PLACEHOLDER => qr/\{(\w+)(?::(%[^{}]+))?\}/;

# The form every selector falls back to, as in ICU MessageFormat.
Readonly::Scalar my $OTHER_FORM => 'other';

# Carp's location suffix: " at FILE line N." with an optional trailing period
# and newline, and optionally ", <FH> line N." when a handle was being read.
Readonly::Scalar my $CARP_SUFFIX => qr/\s+at\s+\S.*?\s+line\s+\d+(?:,\s+<[^>]*>\s+(?:line|chunk)\s+\d+)?\.?\s*\z/s;

# Plural rules by language: count in, CLDR category out.  Only the languages
# with a catalogue need one; any other language uses the fallback's rule,
# because the words come from the fallback catalogue too.
our %PLURAL_RULE = (
	en => sub { return $_[0] == 1 ? 'one' : $OTHER_FORM },
);

=encoding utf8

=head1 NAME

App::WebPerimeterScan::I18N - message catalogue lookup and the shared error handler

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Render a message with values:

	use App::WebPerimeterScan::I18N;

	my $i18n = 'App::WebPerimeterScan::I18N';
	print $i18n->i18n('scope.not_listed', {
		host   => 'evil.example',
		source => 'scope.txt',
	}), "\n";

Let the count choose between singular and plural:

	# "1 endpoint defined in source was not scanned"
	# "3 endpoints defined in source were not scanned"
	print $i18n->i18n('source-routes-unvisited.title', { count => 3 }), "\n";

Choose the language, whatever the environment says:

	$App::WebPerimeterScan::I18N::config{language} = 'de';
	print $i18n->language, "\n";	# 'de' if a German catalogue exists, else 'en'

Remove the "at FILE line N." that C<croak> adds, before you show an error
to a person:

	eval { $scope->load_file('missing.txt'); 1 }
		or print App::WebPerimeterScan::I18N::clean_error($@), "\n";

Write a module that throws catalogued errors:

	package App::WebPerimeterScan::Example;

	use parent 'App::WebPerimeterScan::I18N';

	sub load
	{
		my ($self, $file) = @_;

		# croak()s with the catalogue text for the user's language
		$self->_throw('scope.empty', { file => $file }) unless -s $file;

		return $self;
	}

	# Any class or object in the distribution can render a message
	print App::WebPerimeterScan::I18N->i18n('report.summary', { summary => '0 high' }), "\n";

=head1 DESCRIPTION

Every user-facing string in the distribution - finding titles, error
messages, report labels and the command-line usage text - lives in
L<App::WebPerimeterScan::Messages> under a stable key.  This class looks the
key up for the user's language, fills in the placeholders and chooses the
plural or gender form, so no other module holds English text.

It is also the base class of every module in the distribution, which is what
gives each of them C<i18n> and the protected C<_throw> and C<_warn> helpers.
Those helpers are the only places that call C<croak> and C<carp>.

=head2 Message format

A message is either a string or a selector.

A string may contain C<{name}>, replaced by the argument of that name, or
C<{name:%.1f}>, where the part after the colon is a C<sprintf> format applied
to the argument.  A placeholder whose argument was not given is left in the
text as it is, so a missing value is visible rather than silently empty.

A selector is a hash:

	{ plural => 'count',  forms => { one => '{count} file', other => '{count} files' } }
	{ select => 'gender', forms => { female => 'her', male => 'his', other => 'their' } }

C<plural> applies the language's plural rule to the named argument to choose
the form; C<select> uses the argument's value as the form name.  Either falls
back to C<other>, and the chosen form may itself be a selector.

=cut

=head1 SUBROUTINES/METHODS

=head2 language

Purpose: report which catalogue C<i18n> will read.

Args: none (callable as a class or an object method).

Returns: a language code such as C<en>; always one that has a catalogue.

Side Effects: none.  The environment is read on each call so a test can
change C<LC_ALL> between calls.

Usage: C<< my $lang = App::WebPerimeterScan::I18N->language; >>

=head3 EXAMPLE

	local $ENV{LC_ALL} = 'de_DE.UTF-8';
	# 'en' until a German catalogue is installed
	print App::WebPerimeterScan::I18N->language, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string', matches => qr/\A[a-z]{2,3}\z/ }

=head3 MESSAGES

None.

=cut

sub language
{
	my ($self) = @_;

	my $catalogue = \%App::WebPerimeterScan::Messages::CATALOGUE;

	# The first preference with a catalogue wins; the fallback always exists.
	my ($chosen) = grep { exists $catalogue->{$_} } @{ _wanted_languages() };

	return $chosen // $config{fallback};
}

=head2 i18n

Purpose: return the text of a message key in the user's language, with its
placeholders filled in.

Args: C<$key> (string) and an optional hash reference of named arguments.

Returns: the rendered string.

Side Effects: C<confess>es when no catalogue - not even the fallback - holds
the key, because that is a programming error and the stack trace is what
finds it.

Usage: C<< $self->i18n('scope.empty', { file => $file }) >>

=head3 EXAMPLE

	my $text = App::WebPerimeterScan::I18N->i18n(
		'source-routes-unvisited.title', { count => 3 },
	);
	# "3 endpoints defined in source were not scanned"

=head3 API SPECIFICATION

=head4 INPUT

	{
		key  => { type => 'string', min => 1, position => 0 },
		args => { type => 'hashref', optional => 1, position => 1 },
	}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Message                              Meaning / resolution
	-----------------------------------  ---------------------------------------
	No message is defined for "KEY"      The key is in no catalogue.  Add it to
	                                     App::WebPerimeterScan::Messages (en).

=head3 PSEUDOCODE

	look the key up in the user's catalogue, then in the fallback
	confess if neither has it
	while the message is a selector
		choose the form named by the plural rule or the argument value
		use 'other' if that form does not exist
	replace each {name} or {name:format} that has an argument

=cut

sub i18n
{
	my ($self, $key, $args) = @_;

	# Validated by hand rather than with validate_strict: this runs for
	# every string in every report, and the two checks are all it needs.
	my $language = $self->language;
	$args = {} unless ref $args eq 'HASH';

	# A missing key is a programming error, so the full stack trace is
	# worth more than a short message.  The text itself is catalogued too.
	my $message = (defined $key && length $key) ? _lookup($language, $key) : undef;
	confess(_render(_lookup($config{fallback}, 'i18n.missing_key'), { key => $key // '' }))
		unless defined $message;

	# A selector may nest another selector (plural inside gender, say).
	$message = _select_form($language, $message, $args) while ref $message eq 'HASH';

	return _render($message, $args);
}

=head2 has_message

Purpose: say whether a key exists, for optional parts of a message family
such as a finding's C<.fix> text.

Args: C<$key> (string).

Returns: 1 if the user's catalogue or the fallback has the key, else 0.

Side Effects: none.

Usage: C<< $self->i18n("$id.fix") if $self->has_message("$id.fix") >>

=head3 EXAMPLE

	print "has a fix\n" if App::WebPerimeterScan::I18N->has_message('csp-missing.fix');

=head3 API SPECIFICATION

=head4 INPUT

	{ key => { type => 'string', min => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub has_message
{
	my ($self, $key) = @_;

	# An undefined key cannot name a message; say no rather than warn.
	return (defined $key && defined _lookup($self->language, $key)) ? 1 : 0;
}

=head2 clean_error

Purpose: turn an exception into a one-line message for a person, by removing
the C<at FILE line N.> suffix that C<croak> and C<die> append.

Args: the exception: a string, or an object that stringifies, such as an
L<autodie::exception>.

Returns: the message without the location or trailing newline; an empty
string for C<undef>.

Side Effects: none.

Usage: C<< print STDERR clean_error($@), "\n" if $@; >>

=head3 EXAMPLE

	eval { $scope->load_file('missing.txt') };
	print App::WebPerimeterScan::I18N::clean_error($@), "\n";
	# Cannot read scope file 'missing.txt': No such file or directory

=head3 API SPECIFICATION

=head4 INPUT

	{ error => { type => 'scalar|object', optional => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub clean_error
{
	my ($error) = @_;

	# Stringify first so an exception object is handled like a plain string.
	my $text = defined $error ? "$error" : '';
	$text =~ s/$CARP_SUFFIX//;
	chomp $text;

	return $text;
}

# _throw
# Purpose:     croak with the rendered text of a message key, so every error
#              in the distribution is translatable and reported from the
#              caller's point of view.
# Entry:       $self is a class name or object inheriting from this class;
#              $key exists in the catalogue; $args is an optional hashref.
# Exit:        never returns.
# Side effects: throws.
sub _throw :Protected
{
	my ($self, $key, $args) = @_;

	croak($self->i18n($key, $args));
}

# _warn
# Purpose:     carp the rendered text of a message key.
# Entry:       as _throw.
# Exit:        $self, so a caller can chain on.
# Side effects: emits a warning through Carp (and so through $SIG{__WARN__}).
sub _warn :Protected
{
	my ($self, $key, $args) = @_;

	carp($self->i18n($key, $args));

	return $self;
}

# _wanted_languages
# Purpose:     the user's language preferences, most preferred first.
# Entry:       none; reads %config and %ENV.
# Exit:        arrayref of lowercase language codes, possibly empty.
# Side effects: none.
sub _wanted_languages :Private
{
	my @wanted;
	push @wanted, $config{language} if defined $config{language};

	for my $variable (@LOCALE_VARIABLES) {
		my $value = $ENV{$variable};
		next unless defined $value && length $value;

		# LANGUAGE may be "de:fr:en"; the others hold a single locale.
		for my $locale (split /:/, $value) {
			next if $NEUTRAL_LOCALE{$locale};

			# de_DE.UTF-8@euro -> de
			push @wanted, lc $1 if $locale =~ /\A([A-Za-z]{2,3})(?:[_.@-]|\z)/;
		}
	}

	return \@wanted;
}

# _lookup
# Purpose:     find a key in one language, then in the fallback.
# Entry:       $language has a catalogue; $key is a non-empty string.
# Exit:        the message (string or selector hash), or undef if absent.
# Side effects: none.
sub _lookup :Private
{
	my ($language, $key) = @_;

	my $catalogue = \%App::WebPerimeterScan::Messages::CATALOGUE;

	# Per-key fallback, so a partial translation still renders every message.
	return $catalogue->{$language}{$key} // $catalogue->{ $config{fallback} }{$key};
}

# _select_form
# Purpose:     resolve one level of a plural or select message.
# Entry:       $message is a hashref with 'forms' and one of 'plural'/'select'.
# Exit:        the chosen form (a string or a nested selector).
# Side effects: none.
sub _select_form :Private
{
	my ($language, $message, $args) = @_;

	my $forms = $message->{forms} || {};
	my $form;

	if(defined(my $name = $message->{plural})) {
		# A count that is missing or not a number is treated as plural:
		# "0 files" reads better than a crash in the middle of a report.
		my $count = $args->{$name};
		my $rule = $PLURAL_RULE{$language} || $PLURAL_RULE{ $config{fallback} };
		$form = (defined $count && $count =~ /\A-?\d+(?:\.\d+)?\z/) ? $rule->($count) : $OTHER_FORM;
	} elsif(defined(my $selector = $message->{select})) {
		$form = $args->{$selector} // $OTHER_FORM;
	}

	return $forms->{ $form // $OTHER_FORM } // $forms->{$OTHER_FORM} // '';
}

# _render
# Purpose:     substitute {name} and {name:%fmt} placeholders.
# Entry:       $text is a string; $args is a hashref.
# Exit:        the rendered string.  Unknown placeholders are left as is.
# Side effects: none.
sub _render :Private
{
	my ($text, $args) = @_;

	# One pass, so a value that itself contains "{x}" is never expanded.
	$text =~ s{$PLACEHOLDER}{
		!exists $args->{$1} || !defined $args->{$1} ? $&
			: defined $2 ? sprintf($2, $args->{$1})
			: $args->{$1}
	}ge;

	return $text;
}

1;

__END__

=head1 COMMON PITFALLS

=over 4

=item * B<A missing key is fatal; a missing value is not.>  C<i18n> with a
key that no catalogue has dies with a stack trace, because that is a bug in
the code.  A placeholder with no value (or an C<undef> value) stays in the
text as C<{name}>, because the message is still useful.

=item * B<A format must suit its value.>  C<{seconds:%.1f}> with the value
C<'soon'> prints C<0.0> and a Perl warning "isn't numeric".  Pass numbers
to numeric formats.

=item * B<Give every selector an C<other> form.>  When the chosen form is
missing, the C<other> form is used.  When C<other> is missing too, the
message is the empty string, with no warning.

=item * B<A count that is not a number is plural.>  C<{ count => 'many' }>
and a missing C<count> both choose the C<other> form.

=item * B<A new language needs a plural rule.>  A catalogue for a language
with no entry in C<%App::WebPerimeterScan::I18N::PLURAL_RULE> uses the
English rule (1 is C<one>, every other number is C<other>).  That is wrong
for languages such as Polish or Arabic, and for Japanese, which has no
plural.

=item * B<The order of the environment variables matters.>  The first
language found wins, in this order: C<$config{language}>, then
C<LANGUAGE> (which may be a list such as C<de:fr>), then C<LC_ALL>,
C<LC_MESSAGES> and C<LANG>.  The values C<C> and C<POSIX> are skipped.
A language with no catalogue is skipped too, so the answer is often C<en>.

=item * B<C<clean_error> is a function, not a method.>  Call it as
C<App::WebPerimeterScan::I18N::clean_error($@)>.  It only removes Perl's
location suffix; the message text is not changed.

=back

=head1 ENCODING

=over 4

=item * B<Catalogue text is bytes.>  F<Messages.pm> does not say
C<use utf8>, so a translation written in UTF-8 in that file is a UTF-8 byte
string.  That matches the rest of the distribution, where page text and
file names are byte strings too, and the reports come out as correct
UTF-8.  Any language and emoji can be used this way.

=item * B<Do not add C<use utf8> to a catalogue.>  It makes the messages
character strings.  Joined with the byte strings from web pages, the bytes
are then encoded a second time, and the report shows C<E<Atilde>E<copy>>
for C<E<eacute>>.

=item * B<Values are inserted as they are.>  A value that is a byte string
stays a byte string.  A value that is a character string makes the whole
message a character string; print it through an C<:encoding(UTF-8)> layer.

=item * B<C<sprintf> widths count bytes.>  C<{name:%-10s}> pads a UTF-8
byte string by bytes, so a name with non-ASCII letters looks shorter than
ten letters.

=item * B<Keys and placeholder names are ASCII:> letters, digits, C<_>,
C<.> and C<->.

=back

=head1 LIMITATIONS

=over 4

=item * Only an English catalogue ships.  The lookup, plural and select
machinery is language-neutral and falls back key by key, but a German or
Japanese user sees English until a catalogue is added to
C<%App::WebPerimeterScan::Messages::CATALOGUE> together with a
C<%PLURAL_RULE> entry.

=item * L<Locale::Maketext> and L<Locale::TextDomain> were considered and not
used.  Maketext takes positional arguments (C<[_1]>) where this API takes a
hash of named ones, and has no select form for gender; TextDomain needs
compiled C<.mo> files, which is a build step out of proportion to a single
language.  The renderer here is about twenty lines.

=item * The language is read from the environment on every call rather than
cached, so a long-running caller that changes C<LC_ALL> gets the new
language at once.  The cost is a few hash lookups per message.

=back

=head1 FORMAL SPECIFICATION

This section states exactly what each method does, in the Z notation.  You
do not need it to use the module: the method descriptions above say the same
thing in words.  It is here for reviewers and for anyone who writes tests.

How to read a schema box:

=over 4

=item * The part above the middle line declares names.  A name that ends in
C<?> is an input.  A name that ends in C<!> is an output.

=item * The part below the middle line lists facts that are true after the
call.

=item * A name with a dash after it, such as C<items'>, is the value after
the call.  The same name without the dash is the value before the call.

=item * C<Delta X> (written with the Greek capital delta) means the call
may change the state C<X>.  C<Xi X> (the Greek capital xi) means the call
does not change it.

=back

The symbols used are:

	Δ   may change            Ξ   does not change      •   such that
	∀   for all               ∃   there is             ¬   not
	∧   and                   ∨   or                   ⇒   implies
	⇔   if and only if        ≠   not equal            ≤ ≥ at most, at least
	∈   is in                 ∉   is not in            ⊆   is a subset of
	∪   union                 ∩   intersection         ∅   the empty set
	ℙ X sets of X             ⊥   undefined (undef)    …   and so on
	⟨⟩  the empty sequence    ⁀   join sequences       ⇸   partial mapping
	↦   maps to               ⊕   override a mapping   ↾   keep only these keys
	∘   compose               →   function             × ÷ − times, divide, minus
	ℕ   0, 1, 2, ...          ℕ₁  1, 2, 3, ...         ℝ   real numbers
	𝔹   true or false         ⌊x⌋ x rounded down
	dom M  the keys of M      ran M  the values of M   #S  the size of S


=head2 language

	┌─ Language ──────────────────────────────────────────
	│ Ξenvironment; catalogue : LANG ⇸ MESSAGES
	│ result! : LANG
	├─────────────────────────────────────────────────────
	│ prefs = ⟨ configured ⟩ ⁀ wanted(environment)
	│ (∃ l ∈ ran prefs ∩ dom catalogue ⇒
	│     result! = head(prefs ↾ dom catalogue))
	│ (ran prefs ∩ dom catalogue = ∅ ⇒ result! = fallback)
	└─────────────────────────────────────────────────────

=head2 i18n

	┌─ I18n ──────────────────────────────────────────────
	│ ΞCatalogue
	│ key? : KEY; args? : NAME ⇸ VALUE; result! : STRING
	├─────────────────────────────────────────────────────
	│ key? ∈ dom catalogue(language) ∪ dom catalogue(fallback)
	│ m = (catalogue(language) ⊕ ∅) (key?) ⊕ catalogue(fallback)(key?)
	│ result! = render(select(m, args?), args?)
	│ ∀ p ∈ placeholders(result!) • p ∉ dom args?
	└─────────────────────────────────────────────────────

=head2 has_message

	┌─ HasMessage ────────────────────────────────────────
	│ ΞCatalogue; key? : KEY; result! : 𝔹
	├─────────────────────────────────────────────────────
	│ result! ⇔ key? ∈ dom catalogue(language) ∪ dom catalogue(fallback)
	└─────────────────────────────────────────────────────

=head2 clean_error

	┌─ CleanError ────────────────────────────────────────
	│ error? : STRING; result! : STRING
	├─────────────────────────────────────────────────────
	│ ∃ loc : LOCATION • error? = result! ⁀ loc ∨ error? = result!
	│ ¬ (∃ loc : LOCATION • suffix(result!) = loc)
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The class keeps no state of its own.  It reads C<%config>, the
environment and the catalogue every time.  One call to C<i18n> goes
through these steps:

	  i18n(key, args)
	        |
	        v
	  +----------------+
	  | CHOOSE         |  first of: $config{language}, LANGUAGE (a list),
	  | LANGUAGE       |  LC_ALL, LC_MESSAGES, LANG that has a catalogue;
	  +----------------+  'C' and 'POSIX' skipped; else the fallback 'en'
	        |
	        v
	  +----------------+
	  | LOOK UP KEY    |--- not in that language, and not in 'en'
	  +----------------+       -> confess (dies with a stack trace)
	        |
	        |  found (in that language, or else in 'en')
	        v
	  +----------------+
	  | SELECT FORM    |<---------------------------------+
	  +----------------+                                  |
	     |          |                                     |
	     | a string | a selector                          |
	     |          v                                     |
	     |   plural: the language's rule on args{name}    |
	     |   select: the value of args{name}              |
	     |   form missing -> 'other'                      |
	     |   'other' missing -> ''                        |
	     |          |                                     |
	     |          |  the chosen form is a selector -----+
	     |          |
	     |          |  the chosen form is a string
	     v          v
	  +----------------+
	  | FILL IN        |  each {name} or {name:%fmt} that has a defined
	  | PLACEHOLDERS   |  value is replaced, in one pass; the others stay
	  +----------------+
	        |
	        v
	  the message (a string)

The protected helpers add one step after that:

	  _throw(key, args)  -> i18n(key, args) -> croak   (the caller dies)
	  _warn(key, args)   -> i18n(key, args) -> carp    (returns the object)

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
