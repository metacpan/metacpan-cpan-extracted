package App::Actions::Error;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(blessed);

# Stringifying the object gives what croak would have printed, so code that
# reads "$@", matches it with a regex or prints it sees no difference; code
# that wants to tell failures apart asks for the code instead.
use overload
	'""' => sub { $_[0]->text },
	bool => sub { 1 },
	fallback => 1;

our $VERSION = '0.002.1';

# What Carp appends to a message: " at FILE line N.".  It is found in two
# steps, the tail and then the " at " before it, because one pattern that
# does both - \A(.*)\s+at\s+.+?\s+line\s+\d+\.?\z - tries every " at " and
# scans to the end from each, which is quadratic: 40,000 characters of
# "x at f line " took three seconds.  Each step below is linear.
#
# The tail: " line N." at the very end.  It is tried only where a run of
# white space starts, and its quantifiers never give back, so no run of
# spaces is scanned twice.
Readonly::Scalar my $LOCATION_TAIL => qr/
	(?<!\s)        # the start of a run of white space, or of the text
	\s++ line      # " line"
	\s++ \d++      # " N"
	\.?            # Carp's full stop
	\z
/x;

# The message: everything before the last " at " that is followed by a file
# name.  The greedy prefix is what makes it the last, because a message may
# quote a position of its own ("at character offset 9") and a file name may
# contain spaces; ending the prefix at a non-space (or leaving it empty)
# means each run of white space is tried from its start only.
Readonly::Scalar my $LOCATION_HEAD => qr/
	\A
	(.*\S|)        # the message: ends at a non-space, or is empty
	\s+ at \s+     # " at "
	\S             # the start of the file name
/xs;

# A message key is a dotted lower-case name such as workflow.no_jobs.
Readonly::Scalar my $CODE => qr/\A[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+\z/;

=encoding utf-8

=head1 NAME

App::Actions::Error - an exception that carries a stable code

=head1 SYNOPSIS

Tell one failure from another by its code:

	use App::Actions::Error;
	use App::Actions::Workflow;

	my $workflow = eval { App::Actions::Workflow->load($file) };
	if (!$workflow) {
		my $error = App::Actions::Error->caught($@);
		if ($error && $error->is('workflow.file_missing')) {
			print 'No workflow at ', $error->args->{file}, "\n";
		} else {
			die $@;    # not one we handle: pass it on
		}
	}

Handle a whole family of failures:

	if (my $error = App::Actions::Error->caught($@)) {
		exit 3 if $error->is('runner.image.');    # any image problem
	}

Show any failure to a person, without the file and line number:

	eval { $runner->run; 1 }
		or print STDERR 'action-run: ', App::Actions::Error->describe($@), "\n";

Code that treats exceptions as strings keeps working:

	eval { App::Actions::Workflow->load('missing.yml') };
	print "not found\n" if $@ =~ /does not exist/;

=head1 DESCRIPTION

When something goes wrong, this distribution throws (C<die>s with) an
C<App::Actions::Error> object.  The object has:

=over 4

=item * a B<code>, such as C<workflow.file_missing>.  The code never
changes when the message is translated or reworded, so your program can
check it safely;

=item * a B<message>, such as C<Workflow file 'ci.yml' does not exist>, in
the user's language;

=item * the B<arguments> used to build the message, such as C<{ file =E<gt>
'ci.yml' }>;

=item * a B<location>, such as C< at lib/App/Actions.pm line 42.>, the same
text C<croak> adds.

=back

As a string, the object is exactly the message followed by the location: the
same text C<croak> would have died with.  So older code that reads C<$@> as
a string, prints it or matches it with a regular expression sees no
difference.

You do not usually make these objects yourself.  Code inside the
distribution calls C<< $self->throw($code, \%args) >> from
L<App::Actions::I18N>, which looks the code up in the message catalogue,
translates and fills in the message, and throws the object.  The codes are
the keys of the catalogue in L<App::Actions::I18N::en>.

=head1 METHODS

=head2 new

Creates an exception without throwing it.  Most code never calls this: it
uses C<< $self->throw($key, \%args) >> from L<App::Actions::I18N>, which
renders the message and records where it was thrown from.

=head3 ARGUMENTS

=over 4

=item * C<code> - the catalogue key, such as C<workflow.no_jobs>.

=item * C<message> - the rendered text, without a location.

=item * C<args> - optional; the values the message was rendered with.

=item * C<location> - optional; what follows the message when it is
stringified, normally C<" at FILE line N.\n">.  Defaults to C<"\n">.

=back

=head3 RETURNS

An C<App::Actions::Error> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $error = App::Actions::Error->new(
		code    => 'workflow.empty',
		message => "Workflow 'ci.yml' is empty",
		args    => { file => 'ci.yml' },
	);
	die $error;

=head3 API SPECIFICATION

=head4 INPUT

	{
		code     => { type => 'string', matches => qr/\A[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+\z/ },
		message  => { type => 'string' },
		args     => { type => 'hashref', optional => 1 },
		location => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Error' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | A required argument is       | Pass a dotted code and a    |
	| App::Actions::Error::new  | missing or has the wrong type| message string              |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	# The validator is called directly rather than through
	# App::Actions::I18N::validate_args, because that module throws these
	# objects and so loads this one first.
	# $@ is localised: an exception is often made while the caller is still
	# looking at the one it caught.
	my @arguments = @_;
	my ($params, $failure);
	{
		local $@;
		$params = eval {
			# The validator takes a key that holds undef as given; an exception
			# with no code or no message is a mistake, so undef counts as left out.
			my $given = get_params(undef, @arguments);
			delete @{$given}{ grep { !defined $given->{$_} } keys %{$given} };
			validate_strict({
				args => $given,
				schema => {
					code => { type => 'string', matches => $CODE },
					message => { type => 'string' },
					args => { type => 'hashref', optional => 1 },
					location => { type => 'string', optional => 1 },
				},
			});
		};
		$failure = $@;
	}
	if (!$params) {
		# The innermost "validate_strict:" clause is the reason; the
		# validator's own name and its " at FILE line N." suffixes are not.
		(my $reason = $failure || 'invalid') =~ s/\A.*validate_strict:\s*//s;
		1 while $reason =~ s/\s+at \S+ line \d+\.?\s*\z//s;
		croak("Invalid arguments to ${class}::new: $reason");
	}

	return bless {
		code => $params->{code},
		message => $params->{message},
		args => { %{ $params->{args} || {} } },
		location => defined $params->{location} ? $params->{location} : "\n",
	}, $class;
}

=head2 code

Returns the catalogue key the exception was raised with.

=head3 EXAMPLE

	print $error->code;    # workflow.file_missing

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub code { return $_[0]->{code} }

=head2 message

Returns the rendered message without the location, as a person would want to
read it.

=head3 EXAMPLE

	print STDERR 'action-run: ', $error->message, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub message { return $_[0]->{message} }

=head2 args

Returns a copy of the values the message was rendered with, so a caller can
act on the file, job or image the failure is about.

=head3 EXAMPLE

	my $file = $error->args->{file};

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub args { return { %{ $_[0]->{args} } } }

=head2 location

Returns what follows the message when it is stringified: C<" at FILE line
N.\n">, a stack trace for an exception raised with C<< trace => 1 >>, or
C<"\n"> for one that names no place in the code.

=head3 EXAMPLE

	warn 'raised', $error->location;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub location { return $_[0]->{location} }

=head2 text

Returns the message followed by the location: what the object stringifies
to, and what C<croak> would have died with.

=head3 EXAMPLE

	is("$error", $error->text, 'stringification is the text');

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub text { return $_[0]->{message} . $_[0]->{location} }

=head2 is

Says whether the exception has a code, or belongs to a family of codes.

=head3 ARGUMENTS

=over 4

=item * C<$code> - a full code (C<workflow.no_jobs>), or a prefix ending in a
dot (C<workflow.>) for every code that starts with it.

=back

=head3 RETURNS

1 or 0.

=head3 EXAMPLE

	if ($error->is('runner.image.')) { ... }    # any image failure

=head3 API SPECIFICATION

=head4 INPUT

	{ code => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub is {
	my ($self, $code) = @_;

	my $mine = $self->{code};

	# A trailing dot names a family, so a caller can handle every image
	# failure without listing their codes.
	return ($code =~ /\.\z/ ? index($mine, $code) == 0 : $mine eq $code) ? 1 : 0;
}

=head2 caught

	my $error = App::Actions::Error->caught($@);

Returns the value if it is an C<App::Actions::Error> (or a subclass of the
class it is called on), and C<undef> otherwise, so a caller can ask for the
code without first checking what kind of value C<$@> holds.

=head3 EXAMPLE

	if (my $error = App::Actions::Error->caught($@)) {
		exit 70 if $error->is('schema.invalid');
	}

=head3 API SPECIFICATION

=head4 INPUT

	{ error => { type => 'any', optional => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Error', optional => 1 }

=head3 MESSAGES

None.

=cut

sub caught {
	my ($class, $error) = @_;

	return (blessed($error) && $error->isa($class)) ? $error : undef;
}

=head2 describe

	print STDERR 'action-run: ', App::Actions::Error->describe($@), "\n";

Returns any exception as a sentence for a person: the message of an
C<App::Actions::Error>, or a string exception with its final
C<" at FILE line N."> and trailing white space removed.  A position the
message gives of its own, such as JSON::PP's C<at character offset 9>, is
kept, because it is part of the diagnosis.

=head3 ARGUMENTS

=over 4

=item * C<$error> - an exception: an object or a string.  C<undef> gives
the empty string.

=back

=head3 RETURNS

A string.

=head3 EXAMPLE

	App::Actions::Error->describe("No job matched 'x' at lib/App/Actions.pm line 9.\n");
	# No job matched 'x'

=head3 API SPECIFICATION

=head4 INPUT

	{ error => { type => 'any', optional => 1 } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub describe {
	my ($class, $error) = @_;

	# An exception of this kind knows its message apart from its location;
	# anything else is a string and has the location cut off.
	my $text = !defined $error ? ''
		: $class->caught($error) ? $error->message
		: "$error";
	$text =~ s/\s+\z//;
	if ($text =~ $LOCATION_TAIL) {
		my $before = substr($text, 0, $-[0]);
		$text = $1 if $before =~ $LOCATION_HEAD;
	}
	$text =~ s/\s+\z//;

	return $text;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * Only messages raised through the catalogue are objects.  Errors from
Perl itself, from CPAN modules and from code that still calls C<croak> with a
literal are strings; L</describe> and L</caught> accept both so a caller does
not have to know which it was given.

=item * The code is the catalogue key, so renaming a key is an interface
change.  The keys are listed in the language modules under
L<App::Actions::I18N>.

=item * The arguments are copied when the exception is made, but values in
them that are references are shared with the code that threw it.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Do not match the message text.>  It is translated, and its
wording may change.  Use L</is> with the code.

=item * B<Not every exception is an object.>  Errors from Perl and from
other modules are strings.  Use L</caught>, which returns C<undef> for them,
before you call a method on C<$@>.

=item * B<C<is> needs a trailing dot for a family.>  C<is('runner.image')>
matches only that exact code; C<is('runner.image.')> matches every code
that starts with C<runner.image.>.

=item * B<C<args> returns a copy of the hash, but not of what is inside
it.>  If an argument is a reference, changing what it points to changes the
error too.

=item * B<A method call does not work inside a string.>  C<"$error-E<gt>code">
prints the whole error followed by C<-E<gt>code>.  Write C<'...' .
$error-E<gt>code>.

=item * B<The object is always true.>  Even an error with an empty message
counts as true, so C<if ($@)> works as expected.

=item * B<Keep a copy of C<$@>.>  Any C<eval> you run later (even inside a
destructor) can reset it.  Write C<my $error = $@;> first.

=back

=head1 ENCODING

The message is a Perl character string.  It may contain any Unicode text,
including non-ASCII characters and emoji, because it may be a translation
(for example into Chinese) and may quote a workflow's own text.  Set an
encoding on the handle before you print it, for example C<binmode STDERR,
':encoding(UTF-8)'>.  The code is always ASCII: lower-case letters, digits,
C<_> and dots.  The location is the file name as Perl knows it.

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

	┌─ NewError ────────────────────────────────────────
	│ code?     : KEY
	│ message?  : seq CHAR
	│ args?     : optional (NAME ⇸ VALUE)
	│ location? : optional seq CHAR
	│ e!        : Error
	├───────────────────────────────────────────────────
	│ e!.code = code? ∧ e!.message = message?
	│ e!.args = (if args? = ⊥ then ∅ else args?)
	│ e!.location = (if location? = ⊥ then "\n" else location?)
	│ text(e!) = e!.message ⁀ e!.location
	└───────────────────────────────────────────────────

=head2 code

	┌─ Code ────────────────────────────────────────────
	│ ΞError
	│ code! : KEY
	├───────────────────────────────────────────────────
	│ code! = θError.code
	└───────────────────────────────────────────────────

=head2 message

	┌─ Message ─────────────────────────────────────────
	│ ΞError
	│ message! : seq CHAR
	├───────────────────────────────────────────────────
	│ message! = θError.message
	└───────────────────────────────────────────────────

=head2 args

	┌─ Args ────────────────────────────────────────────
	│ ΞError
	│ args! : NAME ⇸ VALUE
	├───────────────────────────────────────────────────
	│ args! = θError.args
	└───────────────────────────────────────────────────

=head2 location

	┌─ Location ────────────────────────────────────────
	│ ΞError
	│ location! : seq CHAR
	├───────────────────────────────────────────────────
	│ location! = θError.location
	└───────────────────────────────────────────────────

=head2 text

	┌─ Text ────────────────────────────────────────────
	│ ΞError
	│ text! : seq CHAR
	├───────────────────────────────────────────────────
	│ text! = θError.message ⁀ θError.location
	└───────────────────────────────────────────────────

=head2 is

	┌─ Is ──────────────────────────────────────────────
	│ ΞError
	│ code? : seq CHAR
	│ r!    : 𝔹
	├───────────────────────────────────────────────────
	│ last(code?) = '.' ⇒ (r! ⇔ code? prefix θError.code)
	│ last(code?) ≠ '.' ⇒ (r! ⇔ code? = θError.code)
	└───────────────────────────────────────────────────

=head2 caught

	┌─ Caught ──────────────────────────────────────────
	│ class? : CLASS
	│ value? : VALUE
	│ e!     : optional Error
	├───────────────────────────────────────────────────
	│ value? ∈ class? ⇒ e! = value?
	│ value? ∉ class? ⇒ e! = ⊥
	└───────────────────────────────────────────────────

=head2 describe

	┌─ Describe ────────────────────────────────────────
	│ error? : VALUE
	│ s!     : seq CHAR
	├───────────────────────────────────────────────────
	│ error? ∈ Error ⇒ s! = rtrim(error?.message)
	│ error? = ⊥ ⇒ s! = ⟨⟩
	│ otherwise s! = rtrim(stripLocation(rtrim(error?)))
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

An error object never changes after it is made.  This is its life:

	 $self->throw($code, \%args)              App::Actions::Error->new(...)
	 (App::Actions::I18N: look up $code,       (rare: a caller that builds
	  translate, fill in %args, add the         its own)
	  caller's " at FILE line N.")                    |
	           |                                      |
	           +------------------+-------------------+
	                              v
	                     +-----------------+
	                     |    CREATED      |  code, message, args,
	                     |   (immutable)   |  location fixed
	                     +-----------------+
	                              |
	                              | die
	                              v
	                     +-----------------+
	                     |    THROWN       |  in $@
	                     +-----------------+
	                       |      |      |
	   not caught by any   |      |      | caught as a string ("$@", =~, print):
	   eval                |      |      | reads as message . location
	                       v      |      v
	        program stops;        |   old code works unchanged
	        STDERR shows the      |
	        message and location  | App::Actions::Error->caught($@)
	                              v
	                     +-----------------+
	                     |   INSPECTED     |  is($code) / is('family.')
	                     +-----------------+  code / message / args / location
	                              |
	                              | describe($@)
	                              v
	                     message without the location, for a person

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
