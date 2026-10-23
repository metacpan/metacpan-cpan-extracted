package App::Actions::Docker::Variable;

use strict;
use warnings;

our $VERSION = '0.001.0';

# A job variable on its way to docker: "-e" followed by one of these.  It
# reads as NAME=VALUE wherever it is printed or compared, and lets
# App::Actions::Docker give the value to the client through its environment
# rather than its arguments, where every user of the host could read it.
use overload '""' => sub { "$_[0]{name}=$_[0]{value}" }, fallback => 1;

sub new {
	my ($class, $name, $value) = @_;

	return bless { name => $name, value => defined $value ? $value : '' }, $class;
}

sub name  { return $_[0]->{name} }
sub value { return $_[0]->{value} }

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Docker::Variable - an environment variable for a container, kept off the command line

=head1 SYNOPSIS

Pass a variable to a container:

	use App::Actions::Docker;
	use App::Actions::Docker::Variable;

	my $docker = App::Actions::Docker->new;
	my $token  = App::Actions::Docker::Variable->new('TOKEN', $secret);

	# The client is started as "docker run --rm -e TOKEN alpine env", and
	# TOKEN is set in its environment only.
	$docker->run('run', '--rm', '-e', $token, 'alpine', 'env');

Read its parts:

	print $token->name, "\n";     # TOKEN
	print $token->value, "\n";    # the secret

Print it, for a log (redact secrets first):

	print "$token\n";             # TOKEN=the secret

=head1 DESCRIPTION

A program's command line is public.  Every user of the computer can read it,
for example with C<ps> or from F</proc/PID/cmdline>.  So a command like
C<docker run -e TOKEN=s3cret ...> shows the secret to everybody.

A program's environment is private.  Only the same user (and root) can read
it.  The docker client accepts C<-e TOKEN> with no value: it then copies the
value from its own environment.

This class is how a job variable says "give me to docker in the private
way".  Put one after C<-e> in the arguments of an L<App::Actions::Docker>
method.  When the command runs, L<App::Actions::Docker> replaces it with the
bare name and puts the value in the client's environment for that one
command.  See L<App::Actions::Docker/Job variables> for the cases where the
variable must stay on the command line instead.

Everywhere else, the object behaves like the string C<NAME=VALUE>: when you
print it, join it, or compare it with C<eq>.

=head1 METHODS

=head2 new

	my $variable = App::Actions::Docker::Variable->new($name, $value);

Makes a variable.

=head3 ARGUMENTS

=over 4

=item * C<$name> - the variable's name, for example C<TOKEN>.

=item * C<$value> - its value.  C<undef> becomes the empty string.

=back

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $home = App::Actions::Docker::Variable->new('HOME_DIR', '/home/runner');

=head3 API SPECIFICATION

=head4 INPUT

	{
		name  => { type => 'string', min => 1 },
		value => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Docker::Variable' }

=head3 MESSAGES

None.

=head2 name

	my $name = $variable->name;

Returns the name given to L</new>.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head2 value

	my $value = $variable->value;

Returns the value given to L</new>, or the empty string if it was C<undef>.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head1 COMMON PITFALLS

=over 4

=item * B<Printing the object prints the secret.>  C<"$variable"> is
C<NAME=VALUE>.  Pass anything you log through
L<App::Actions::Docker/redact> first.  The Docker object's own verbose and
dry-run output already does this.

=item * B<Only App::Actions::Docker hides the value.>  If you pass the object
to C<system> or to another module, it becomes the string C<NAME=VALUE> and is
on the command line again.

=item * B<A plain string is never hidden.>  C<'-e', 'TOKEN=s3cret'> is passed
as it is.  Only an object of this class is moved to the environment.

=item * B<undef is not kept.>  C<new('X', undef)-E<gt>value> is the empty
string, so a container cannot tell an undefined value from an empty one.

=back

=head1 ENCODING

The name should be ASCII letters, digits and C<_>, and must not start with a
digit; any other name stays on the command line.  The value may hold any
text, including non-ASCII characters and emoji, but encode it to bytes (for
example UTF-8 with L<Encode>) before you pass it, because an environment and
a command line hold bytes, not characters.  A value with a NUL character
cannot go in an environment, so it stays on the command line.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞVariable> means the routine changes
nothing.  The lines below the rule are always true when the routine returns.

	Variable ≙ [ name : seq CHAR; value : seq CHAR ]

=head2 new

	┌─ New ─────────────────────────────────────────────
	│ name?  : seq CHAR
	│ value? : optional seq CHAR
	│ v!     : Variable
	├───────────────────────────────────────────────────
	│ v!.name = name?
	│ value? = ⊥ ⇒ v!.value = ⟨⟩
	│ value? ≠ ⊥ ⇒ v!.value = value?
	│ string(v!) = v!.name ⁀ ⟨'='⟩ ⁀ v!.value
	└───────────────────────────────────────────────────

=head2 name

	┌─ Name ────────────────────────────────────────────
	│ ΞVariable
	│ r! : seq CHAR
	├───────────────────────────────────────────────────
	│ r! = name
	└───────────────────────────────────────────────────

=head2 value

	┌─ Value ───────────────────────────────────────────
	│ ΞVariable
	│ r! : seq CHAR
	├───────────────────────────────────────────────────
	│ r! = value
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

A variable never changes after it is made.  It has one state, and its only
"transition" is how App::Actions::Docker uses it when a command runs:

	   new($name, $value)
	          |
	          v
	+------------------+
	|     CREATED      |   name and value fixed for ever;
	| (immutable)      |   "$v" reads as NAME=VALUE
	+------------------+
	          |
	          | passed after -e to App::Actions::Docker->run/capture
	          v
	+------------------+  hideable name?   +-----------------------------+
	|  CHECKED BY      |-------yes-------->| argv gets "NAME";            |
	|  _hide_variables |                   | %ENV{NAME} = value while the |
	+------------------+                   | client runs, then restored   |
	          |                            +-----------------------------+
	          no (client variable, bad name,
	          |   case clash or NUL in value)
	          v
	+-----------------------------+
	| argv gets "NAME=VALUE"      |
	| (visible to every user)     |
	+-----------------------------+

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
