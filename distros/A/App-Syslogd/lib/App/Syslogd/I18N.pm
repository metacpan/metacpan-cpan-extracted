package App::Syslogd::I18N;

# Message catalogue for App::Syslogd.
#
# This is a thin layer over Locale::Maketext (core Perl) rather than a
# home-grown catalogue.  Maketext already gives us language negotiation,
# [quant,...] pluralisation and [sprintf,...] formatting; all we add is
# named arguments (so callers never depend on positional order) and a
# [gender,...] bracket method.

use strict;
use warnings;
use autodie qw(:all);

use parent 'Locale::Maketext';

use Carp qw(croak);
use Readonly;

our $VERSION = '0.002.0';

# Language used when nothing in the environment matches a lexicon we ship
Readonly::Scalar my $FALLBACK_LANGUAGE => 'en';

# The order in which each message's named arguments become [_1], [_2], ...
# Translators of every language see the same positional slots, so this
# table is the single source of truth for every message's arguments.
Readonly my %ARGUMENT_ORDER => (
	usage => [qw(program)],
	listening => [qw(address port)],
	shutdown => [qw(count)],
	socket_failed => [qw(address port error)],
	open_failed => [qw(file error)],
	unsafe_file => [qw(file)],
	write_failed => [qw(file error)],
	recv_failed => [qw(error)],
	no_log_open => [],
	not_a_datagram => [qw(type)],
	missing_key => [],
	bad_values => [qw(type)],
	no_progress => [],
	not_cgi => [],
	not_a_log => [qw(file)],
	already_running => [],
);

=encoding utf8

=head1 NAME

App::Syslogd::I18N - Localised messages for App::Syslogd

=head1 VERSION

Version 0.002.0

=head1 SYNOPSIS

=head2 1. Get a message in the user's language

	use App::Syslogd::I18N;

	my $lh = App::Syslogd::I18N->handle();		# language from the environment
	print $lh->text('listening', { address => '0.0.0.0', port => 514 }), "\n";
	# Syslog server listening on 0.0.0.0 UDP port 514

=head2 2. Ask for one language

	my $lh = App::Syslogd::I18N->handle('en-gb');
	print $lh->text('shutdown', { count => 2 }), "\n";
	# Syslog server shutting down after recording 2 messages

=head2 3. Add a translation

Put this in F<lib/App/Syslogd/I18N/de.pm>.  Inherit from the English
lexicon, so that any message you have not translated yet is still shown in
English instead of causing an error.

	package App::Syslogd::I18N::de;
	use parent 'App::Syslogd::I18N::en';

	our %Lexicon = (
		listening => 'Syslog-Server wartet auf [_1], UDP-Port [_2]',
		shutdown => 'Syslog-Server endet nach [quant,_1,Nachricht,Nachrichten]',
	);

	1;

=head1 DESCRIPTION

A program shows messages to people: "listening on port 514", "could not
open the file", and so on.  This module keeps those messages in one place, so
that they can be translated into other languages.

Each message has a I<key> (a short name, such as C<listening>) and some
I<values> (such as the port number).  You give the key and the values; you
get back the finished sentence in the chosen language.

Each language is a small Perl package called C<App::Syslogd::I18N::xx>
(where C<xx> is the language code) with a hash called C<%Lexicon>.  The hash
maps each key to its text.  The text uses the "bracket notation" of
L<Locale::Maketext>:

=over 4

=item * C<[_1]>, C<[_2]>, ... are replaced by the values, in the order given
by the table in L</text>.

=item * C<[quant,_1,message,messages]> chooses the singular or plural form
for the number in C<[_1]>, and writes the number.

=item * C<[sprintf,%05d,_1]> formats a value, as Perl's C<sprintf> does.

=item * C<[gender,_1,his,her,their]> chooses a word by gender; see
L</gender>.

=item * A real square bracket is written C<~[> or C<~]>.

=back

=head1 ENCODING

=over 4

=item * B<Language tags> must be ASCII, for example C<en> or C<en-gb>.

=item * B<Lexicon text> may contain any Unicode characters, including
non-ASCII letters and emoji, if the language file starts with C<use utf8;>.
The English lexicon is pure ASCII.

=item * B<Values> are copied into the message unchanged.  They may be byte
strings or character strings.  Square brackets and C<~> in a value are not
special: only the lexicon text is parsed.

=item * B<The result> is a Perl string.  If it contains characters above
255 (for example from a translation with emoji), set an output layer before
printing it: C<binmode(STDOUT, ':encoding(UTF-8)')>.  Otherwise Perl prints
a "Wide character" warning.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<A translation must inherit from the English lexicon.>  If
C<App::Syslogd::I18N::de> inherits only from C<App::Syslogd::I18N>, any key
it does not translate makes L<Locale::Maketext> die with "maketext doesn't
know how to say".  Inherit from C<App::Syslogd::I18N::en>, as in the
SYNOPSIS, and missing keys fall back to English.

=item * B<Missing values become empty strings.>  C<< text('open_failed', {}) >>
gives "Could not open log file : " with no warning.  This is on purpose (an
error message should never fail), but check your values if a message looks
incomplete.

=item * B<undef or non-numbers in a plural become 0.>
C<< text('shutdown', { count => undef }) >> says "0 messages".

=item * B<An unknown key does not die.>  C<< text('no_such_key', { a => 1 }) >>
returns C<no_such_key (a=1)>.  This keeps the information in an error path,
but it means a misspelt key is not reported.  Test the messages you use.

=item * B<Values are matched to positions by name, not by order.>  The order
of the C<[_1]>, C<[_2]> slots comes from a fixed table (see L</text>), not
from the order you write the hash.  A new key must be added to that table
too, or it is treated as unknown.

=item * B<gender() knows only "male" and "female".>  Any other value,
including C<m>, C<f> and C<undef>, gives the neutral form.  Upper and lower
case are the same.

=item * B<The language comes from the environment> when you give none:
C<LANGUAGE>, C<LC_ALL>, C<LC_MESSAGES>, then C<LANG>.  A language with no
lexicon falls back to English without a warning.

=item * B<Operating-system errors stay in English.>  A value such as C<"$!">
is in the C locale unless the code that made it used C<use locale>, whatever
C<LC_ALL> says.

=back

=head1 METHODS

=head2 handle

Purpose: get a "language handle", the object that makes messages in one
language.

Args: optional: a language tag, such as C<de> or C<en-gb>.  Without one, the
language is taken from the environment (C<LANGUAGE>, C<LC_ALL>,
C<LC_MESSAGES>, C<LANG>).

Returns: an object of a C<App::Syslogd::I18N> subclass.  Never C<undef>: if
there is no lexicon for the language, you get the English one.

Side Effects: may load the language's module file.

Usage:

	my $lh = App::Syslogd::I18N->handle();

=head3 EXAMPLE

	my $lh = App::Syslogd::I18N->handle('fr');	# there is no French yet...
	print ref($lh), "\n";				# ...so: App::Syslogd::I18N::en

=head3 API SPECIFICATION

=head4 INPUT

	{
		language => { type => 'string', optional => 1, position => 0 },
	}

Domains: a supported tag (C<en>, C<en-gb>, C<EN>) gives that language;
an unsupported (C<fr>), malformed (C<../x>, C<en;x>) or very long tag gives
English; undef or "" reads the environment.

=head4 OUTPUT

	{ type => 'object', isa => 'App::Syslogd::I18N' }

=head3 MESSAGES

None.

=cut

sub handle
{
	my ($class, $language) = @_;

	# Locale::Maketext returns undef when no lexicon matches, which is
	# never useful to a caller that just wants a message printed
	my @tags = defined($language) ? ($language) : ();

	return $class->get_handle(@tags) || $class->get_handle($FALLBACK_LANGUAGE);
}

=head2 text

Purpose: make one finished message.

Args:

=over 4

=item 1. The message key.

=item 2. Optional: a hash reference of named values.  A missing value becomes
an empty string.

=back

The keys, and the values each one uses (in slot order C<[_1]>, C<[_2]>,
...):

	+---------------+----------------------+
	| Key           | Values, in order     |
	+---------------+----------------------+
	| usage         | program              |
	| listening     | address, port        |
	| shutdown      | count                |
	| socket_failed | address, port, error |
	| open_failed   | file, error          |
	| unsafe_file   | file                 |
	| write_failed  | file, error          |
	| recv_failed   | error                |
	| no_log_open   | (none)               |
	| not_a_datagram| type                 |
	| missing_key   | (none)               |
	| bad_values    | type                 |
	| no_progress   | (none)               |
	| not_cgi       | (none)               |
	| not_a_log     | file                 |
	| already_running | (none)             |
	+---------------+----------------------+

Returns: the message, as a string.  An unknown key does not die: it returns
the key, followed by its values in brackets if there are any.  The most
likely caller is reporting an error, and losing that error would be worse
than showing an untranslated key.

Side Effects: none.

Usage:

	my $msg = $lh->text('open_failed', { file => '/x', error => "$!" });

=head3 EXAMPLE

	my $lh = App::Syslogd::I18N->handle('en');
	print $lh->text('shutdown', { count => 1 }), "\n";	# "... 1 message"
	print $lh->text('shutdown', { count => 2 }), "\n";	# "... 2 messages"
	print $lh->text('no_such_key', { a => 1 }), "\n";	# "no_such_key (a=1)"

=head3 API SPECIFICATION

=head4 INPUT

	{
		key => { type => 'string', min => 1, position => 0 },
		args => { type => 'hashref', optional => 1, position => 1 },
	}

Domains: C<key> as in the table below (undef, "" or a reference dies;
an unknown key comes back as text).  C<args>: a hash reference or undef;
an array, code, glob or plain string dies, including C<""> and C<0>.  Values: any text, including
non-ASCII characters, emoji and right-to-left text, copied unchanged;
missing ones become "".

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	+-----------------------------------+----------------------------+------------------------------+
	| Message (dies)                    | Meaning                    | What to do                   |
	+-----------------------------------+----------------------------+------------------------------+
	| maketext doesn't know how to say: | A translation has no text  | Make the language inherit    |
	|   KEY                             |   for KEY and does not     |   from App::Syslogd::I18N::en|
	|                                   |   inherit from English     |   (see COMMON PITFALLS)      |
	| A message key is needed           | KEY was undef, empty or a  | Pass a key from the table    |
	|                                   |   reference                |                              |
	| Message values must be a hash     | The values were not a hash | Pass { name => value, ... }  |
	|   reference (the type given was T)|   reference                |                              |
	+-----------------------------------+----------------------------+------------------------------+

The English text of every key is in L<App::Syslogd/i18n>.

=cut

sub text
{
	my ($self, $key, $args) = @_;

	# Programming errors, reported clearly rather than as an
	# "uninitialized" warning or Perl's "Not a HASH reference".  These two
	# messages come straight from the lexicon with maketext(), never
	# through text() again: an error path that calls the routine it guards
	# can recurse for ever if the guard is ever wrong (mutation testing
	# found exactly that).  Their single value is the [_1] of
	# %ARGUMENT_ORDER.
	croak($self->maketext('missing_key')) if(!defined($key) || ref($key) || !length($key));

	# The values are undef (none) or a hash reference; nothing else.  "||="
	# used to turn "" and 0 into "no values" too, which broke that rule.
	$args //= {};
	if(ref($args) ne 'HASH') {
		croak($self->maketext('bad_values', ref($args) || 'SCALAR'));
	}

	# Unknown keys still produce something readable; see POD above
	my $order = $ARGUMENT_ORDER{$key};
	if(!defined($order)) {
		my $detail = join(', ', map { "$_=" . ($args->{$_} // '') } sort keys %{$args});
		return length($detail) ? "$key ($detail)" : $key;
	}

	# Missing arguments become empty strings so a sloppy caller gets a
	# slightly odd message instead of "Use of uninitialized value" noise
	return $self->maketext($key, map { $args->{$_} // '' } @{$order});
}

=head2 gender

Purpose: choose a word by grammatical gender inside a message.  You do not
call it directly; a lexicon uses it with bracket notation:
C<[gender,_1,male form,female form,neutral form]>.

Args: the gender value, then the male, female and neutral forms.

Returns: the male form for C<male>, the female form for C<female> (upper or
lower case), and the neutral form for anything else, including C<undef>.

Side Effects: none.

Usage:

	# In a lexicon:
	owner_changed => '[_1] changed [gender,_2,his,her,their] password',

=head3 EXAMPLE

	my $lh = App::Syslogd::I18N->handle('en');
	print $lh->gender('Female', 'his', 'her', 'their'), "\n";	# her
	print $lh->gender(undef, 'his', 'her', 'their'), "\n";	# their

=head3 API SPECIFICATION

=head4 INPUT

	{
		gender => { type => 'string', optional => 1, position => 0 },
		male => { type => 'string', position => 1 },
		female => { type => 'string', position => 2 },
		neutral => { type => 'string', position => 3 },
	}

Domains of C<gender>: "male" or "female" in any case pick their form;
everything else (undef, "", "m", "f", references) picks the neutral
form.

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub gender
{
	my ($self, $gender, $male, $female, $neutral) = @_;

	# A single lookup table keeps this to one return statement
	my %form = (male => $male, female => $female);

	return defined($gender) && exists($form{lc $gender}) ? $form{lc $gender} : $neutral;
}

=head1 LIMITATIONS

Only English is included.  Messages that contain an operating-system error
(C<$!>) show it in English, as explained in L</COMMON PITFALLS>.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2
(see the F<LICENSE> file).  If you use it, please let me know.

=head1 FORMAL SPECIFICATION

This section describes each method exactly, in the Z notation.  You do not
need it to use the module.

=head2 handle

	[LANGTAG, KEY, NAME, VALUE, STRING]
	lexicons : LANGTAG ⇸ (KEY ⇸ STRING)
	en ∈ dom lexicons

	Handle
	  lang? : LANGTAG ∪ {⊥}
	  h! : HANDLE
	  ─────────
	  let l == (if lang? = ⊥ then fromEnvironment else lang?) •
	    (l ∈ dom lexicons ⇒ language(h!) = l) ∧
	    (l ∉ dom lexicons ⇒ language(h!) = en)

=head2 text

	ARGUMENT_ORDER : KEY ⇸ seq NAME

	Text
	  h? : HANDLE ; key? : KEY ; args? : NAME ⇸ VALUE
	  out! : STRING
	  ─────────
	  key? ∈ dom ARGUMENT_ORDER ⇒
	    out! = render(lexicon(language(h?), key?),
	                  ⟨ n : ran ARGUMENT_ORDER(key?) •
	                    if n ∈ dom args? ∧ args?(n) ≠ ⊥ then args?(n) else "" ⟩)
	  key? ∉ dom ARGUMENT_ORDER ∧ args? = ∅ ⇒ out! = key?
	  key? ∉ dom ARGUMENT_ORDER ∧ args? ≠ ∅ ⇒
	    out! = key? ⁀ " (" ⁀ join(", ", sorted(args?)) ⁀ ")"

=head2 gender

	Gender
	  g? : STRING ∪ {⊥} ; m?, f?, n? : STRING ; out! : STRING
	  ─────────
	  (g? ≠ ⊥ ∧ lower(g?) = "male" ⇒ out! = m?) ∧
	  (g? ≠ ⊥ ∧ lower(g?) = "female" ⇒ out! = f?) ∧
	  (g? = ⊥ ∨ lower(g?) ∉ {"male", "female"} ⇒ out! = n?)

=head1 STATE DIAGRAM

A language handle has no states that change.  C<handle()> makes it, and
after that C<text()> and C<gender()> only read it.

	   handle(LANG)
	        |   [load LANG's lexicon, or English if there is none]
	        v
	  +-----------+
	  |   READY   |<-- text(KEY, VALUES)  [return a message; no change]
	  |           |<-- gender(...)        [return a word; no change]
	  +-----------+

	+--------+-------------------+--------+--------------------------------------+
	| From   | Trigger           | To     | Action / side effect                 |
	+--------+-------------------+--------+--------------------------------------+
	| (none) | handle(LANG)      | READY  | language chosen; module may be       |
	|        |                   |        |   loaded                             |
	| READY  | text(KEY, VALUES) | READY  | message returned                     |
	| READY  | gender(...)       | READY  | word returned                        |
	| READY  | text() for a key  | READY  | dies "maketext doesn't know how to   |
	|        |   the language    |        |   say" (only if the language does    |
	|        |   lacks           |        |   not inherit from English)          |
	+--------+-------------------+--------+--------------------------------------+

=cut

1;
