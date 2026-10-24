package App::Actions::Runner::Support::Env;

use strict;
use warnings;

use App::Actions::Error;
use App::Actions::I18N qw(throw);

our $VERSION = '0.002.0';

# The env context App::Actions::Runner::Support::resolve_env gives the
# expression evaluator.  It looks like a hash of the variables being
# resolved, but a variable is worked out the first time it is read, and a
# variable read again while it is still being worked out is on a cycle
# (A refers to B, B to A), which is an error rather than a value.

sub TIEHASH {
	my ($class, $raw, $resolved, $resolve) = @_;

	return bless { raw => $raw, resolved => $resolved, resolve => $resolve, busy => {}, failure => undef }, $class;
}

sub FETCH {
	my ($self, $key) = @_;

	return $self->{resolved}{$key} if exists $self->{resolved}{$key};
	return undef unless exists $self->{raw}{$key};    ## no critic (ProhibitExplicitReturnUndef)
	$self->fail('runner.env_cycle', { name => $key }) if $self->{busy}{$key};

	# The caller's $@ is left as it was when the value is worked out.
	local $self->{busy}{$key} = 1;
	my ($value, $failure);
	{
		local $@;
		eval { $value = $self->{resolve}->($key); 1 } or $failure = $@;
	}
	return $self->{resolved}{$key} = $value unless defined $failure;

	# The evaluator turns an error raised inside a lookup into text, so by
	# the time a failure reaches the variables that referred to it, its code
	# is gone.  The first failure is kept and raised again, so the caller
	# sees what went wrong rather than every link of the chain.
	die $self->{failure} if $self->{failure};
	# Without its source line: the message is about the workflow.
	my $error = App::Actions::Error->describe($failure);

	return $self->fail('runner.env_failed', { name => $key, error => $error });
}

sub EXISTS { return exists $_[0]{raw}{ $_[1] } }

sub FIRSTKEY {
	my ($self) = @_;

	# keys resets the iterator, so a lookup that gave up part way through
	# cannot make the next walk start in the middle.
	keys %{ $self->{raw} };

	return scalar each %{ $self->{raw} };
}

sub NEXTKEY { return scalar each %{ $_[0]{raw} } }

sub SCALAR { return scalar %{ $_[0]{raw} } }

sub failure { return $_[0]{failure} }

sub fail {
	my ($self, $message, $args) = @_;

	eval { __PACKAGE__->throw($message, $args); 1 };
	$self->{failure} = $@;

	die $self->{failure};
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Runner::Support::Env - the env context that resolves variables when they are read

=head1 SYNOPSIS

Resolve a set of variables that refer to each other:

	use App::Actions::Expression;
	use App::Actions::Runner::Support::Env;

	my $expression = App::Actions::Expression->new;
	my %raw = (A => 'a', B => '${{ env.A }}b');
	my %resolved;
	my %context;

	my $state = tie my %env, 'App::Actions::Runner::Support::Env', \%raw, \%resolved, sub {
		return $expression->interpolate($raw{ $_[0] }, \%context);
	};
	$context{env} = \%env;

	print $env{B}, "\n";    # ab

Find out what went wrong:

	my $ok = eval { my $value = $env{B}; 1 };
	print $state->failure->message, "\n" unless $ok;

Clean up (the hash and the resolver refer to each other):

	undef $state;
	untie %env;

Most code does not use this class directly: it calls
L<App::Actions::Runner::Support/resolve_env>, which does all of the above.

=head1 DESCRIPTION

A workflow's C<env> values may use other variables:
C<B: ${{ env.A }}b>.  To work out C<B>, the evaluator must first know C<A>.

This class is a tied hash for the C<env> part of an expression context.
When the evaluator reads C<env.A>, the hash works out C<A> at that moment,
by calling a function you give it, and keeps the result.  So the variables
can be read in any order.

Each variable's text is worked out exactly once.  Its result is never worked
out again, so C<${{ }}> text that came from somewhere else, such as a commit
message, stays as text.

If C<A> is read again while C<A> is still being worked out, the variables
form a loop (C<A> uses C<B>, C<B> uses C<A>).  That is the error
C<runner.env_cycle>.

The hash can only be read.  It holds the names of the raw variables, so
C<exists>, C<keys> and a case-insensitive search all work.

=head1 METHODS

=head2 TIEHASH

	my $state = tie my %env, 'App::Actions::Runner::Support::Env', \%raw, \%resolved, $resolve;

Called by C<tie>.

=head3 ARGUMENTS

=over 4

=item * C<\%raw> - the variables' text, name to string.

=item * C<\%resolved> - an empty hash; each result is stored here.

=item * C<$resolve> - a code reference.  It is called with a name and must
return that variable's value.  It usually interpolates C<$raw{$name}> with a
context whose C<env> is this tied hash.

=back

=head3 RETURNS

The tie object.  Keep it if you want to call L</failure>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $state = tie my %env, 'App::Actions::Runner::Support::Env', { A => 'x' }, {}, sub { 'x' };

=head3 API SPECIFICATION

=head4 INPUT

	{
		raw      => { type => 'hashref' },
		resolved => { type => 'hashref' },
		resolve  => { type => 'coderef' },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Support::Env' }

=head3 MESSAGES

None.

=head2 FETCH

	my $value = $env{NAME};

Returns the value of a variable, working it out the first time.

=head3 ARGUMENTS

=over 4

=item * C<$key> - the variable's name, exactly as written (the evaluator
does the case-insensitive search by walking the keys).

=back

=head3 RETURNS

The value, or C<undef> for a name that is not one of the variables.

=head3 SIDE EFFECTS

Stores the value in the C<\%resolved> hash.  On a failure, remembers it (see
L</failure>).

=head3 EXAMPLE

	my $value = $env{B};

=head3 API SPECIFICATION

=head4 INPUT

	{ key => { type => 'string' } }

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Environment variable 'X'    | X refers to itself, or to a  | Break the loop: give one of |
	| refers to itself, directly  | variable that refers back    | the variables a value that  |
	| or through other variables  | to it                        | does not use the others     |
	+-----------------------------+------------------------------+-----------------------------+
	| Unable to evaluate          | The resolver failed for X    | Fix the expression in the   |
	| environment variable 'X': E |                              | workflow's env              |
	+-----------------------------+------------------------------+-----------------------------+

=head2 EXISTS, FIRSTKEY, NEXTKEY and SCALAR

	exists $env{NAME};
	my @names = keys %env;
	if (%env) { ... }

These see the raw variables, so a name is there before it is worked out.
Walking the keys does not work any variable out.

=head3 API SPECIFICATION

=head4 INPUT

	{ key => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=head2 failure

	my $error = $state->failure;

Returns the first error any read raised, or C<undef>.  The evaluator turns
an error inside a lookup into plain text; this keeps the original
L<App::Actions::Error> object with its code.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Error', optional => 1 }

=head3 MESSAGES

None.

=head2 fail

	$state->fail('runner.env_cycle', { name => 'A' });

Raises a catalogue error and remembers it as the first failure.  It never
returns.

=head3 ARGUMENTS

=over 4

=item * C<$message> - the message key.

=item * C<\%args> - its placeholders.

=back

=head3 API SPECIFICATION

=head4 INPUT

	{
		message => { type => 'string' },
		args    => { type => 'hashref' },
	}

=head4 OUTPUT

	{ type => 'undef' }

=head3 MESSAGES

The message it is given.

=head1 COMMON PITFALLS

=over 4

=item * B<Untie the hash when you are done.>  The context holds the hash,
the hash holds the resolver, and the resolver usually holds the context.
That loop is only broken by C<untie>.  Drop the object C<tie> returned
first, or C<untie> warns that a reference still exists.

=item * B<The hash is read-only.>  Storing or deleting a key dies, because
the class has no C<STORE> or C<DELETE>.

=item * B<Once a read fails, later failures report the first one.>  This is
what makes a chain report its cause, not its last link.  Use a new tie for a
new set of variables.

=back

=head1 ENCODING

Names and values are Perl character strings and may hold any text,
including non-ASCII characters and emoji.  Nothing is encoded or decoded
here.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΔEnv> means the routine may change the
state; C<ΞEnv> means it does not.  The lines below the rule are always true
when the routine returns.

	Env ≙ [ raw : NAME ⇸ TEXT; resolved : NAME ⇸ TEXT;
	        busy : ℙ NAME; failure : optional ERROR;
	        resolve : NAME → TEXT ]

=head2 TIEHASH

	┌─ TieHash ─────────────────────────────────────────
	│ Env'
	│ raw? : NAME ⇸ TEXT; resolve? : NAME → TEXT
	├───────────────────────────────────────────────────
	│ raw' = raw? ∧ resolve' = resolve?
	│ resolved' = ∅ ∧ busy' = ∅ ∧ failure' = ⊥
	└───────────────────────────────────────────────────

=head2 FETCH

	┌─ Fetch ───────────────────────────────────────────
	│ ΔEnv
	│ key? : NAME
	│ v!   : optional TEXT
	├───────────────────────────────────────────────────
	│ key? ∈ dom resolved ⇒ v! = resolved(key?) ∧ θEnv' = θEnv
	│ key? ∉ dom raw ⇒ v! = ⊥ ∧ θEnv' = θEnv
	│ key? ∈ busy ⇒ raises Cycle(key?) ∧ failure' = failure ∨ Cycle(key?)
	│ otherwise, with busy ∪ {key?} while resolve(key?) runs:
	│     resolve(key?) = t ⇒ v! = t ∧ resolved' = resolved ⊕ {key? ↦ t}
	│     resolve(key?) fails ∧ failure ≠ ⊥ ⇒ raises failure
	│     resolve(key?) fails ∧ failure = ⊥ ⇒ raises Failed(key?)
	│         ∧ failure' = Failed(key?)
	│ busy' = busy
	└───────────────────────────────────────────────────

=head2 EXISTS, FIRSTKEY, NEXTKEY and SCALAR

	┌─ Keys ────────────────────────────────────────────
	│ ΞEnv
	├───────────────────────────────────────────────────
	│ exists(k) ⇔ k ∈ dom raw
	│ keys = dom raw
	└───────────────────────────────────────────────────

=head2 failure

	┌─ Failure ─────────────────────────────────────────
	│ ΞEnv
	│ r! : optional ERROR
	├───────────────────────────────────────────────────
	│ r! = failure
	└───────────────────────────────────────────────────

=head2 fail

	┌─ Fail ────────────────────────────────────────────
	│ ΔEnv
	│ message? : KEY; args? : NAME ⇸ TEXT
	├───────────────────────────────────────────────────
	│ failure' = Error(message?, args?)
	│ raises failure'
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

Each variable is in one of three states.  A read of the variable moves it:

	                      $env{A}
	+----------------+ (first read)  +-----------------+
	|  RAW           |-------------->|  BUSY           |
	|  text only     |               |  resolve('A')   |
	+----------------+               |  is running     |
	                                 +-----------------+
	                                   |      |      |
	              resolve returned t   |      |      |  $env{A} read again
	                                   v      |      v  (a cycle)
	                     +-----------------+  |  +------------------------+
	                     |  RESOLVED       |  |  | fail: runner.env_cycle |
	                     |  resolved{A}=t  |  |  | failure := the error   |
	                     +-----------------+  |  +------------------------+
	                       |                  |
	      later reads      |                  | resolve died
	      return t at once |                  v
	                       v       +---------------------------------+
	                    $env{A}    | failure set? raise it again     |
	                               | else fail: runner.env_failed    |
	                               +---------------------------------+

	After a failure, A goes back to RAW (BUSY is undone on the way out),
	and failure keeps the first error until the hash is untied.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
