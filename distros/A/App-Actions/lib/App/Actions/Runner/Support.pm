package App::Actions::Runner::Support;

use strict;
use warnings;
use autodie qw(:all);

use Exporter qw(import);
use File::Spec;
use Readonly;

use Cwd qw(abs_path);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);

use Log::Abstraction ();

use App::Actions::Docker::Variable ();
use App::Actions::Runner::Support::Env;
use App::Actions::Error;
use App::Actions::I18N qw(throw);
use App::Actions::Util ();

our $VERSION = '0.002.0';

our @EXPORT_OK = qw(
	action_inputs
	boolean_value
	chomp_error
	default_logger
	env_args
	has_status_function
	local_action_dir
	local_action_path
	null_logger
	redact
	resolve_env
	status_flags
	trim_error
	write_container_file
);

# A file is created readable by its owner only; the caller widens it when
# the container runs as another user.
Readonly::Scalar my $NEW_FILE_MODE => oct('0600');

# The words a workflow may use for a boolean without writing an expression.
Readonly::Scalar my $TRUE_WORD => qr/\A(?:true|yes|1)\z/i;
Readonly::Scalar my $FALSE_WORD => qr/\A(?:false|no|0)\z/i;

# The status functions of the expression language.  A condition that calls
# none of them is given an implicit success(), as on GitHub.
Readonly::Scalar my $STATUS_FUNCTION => qr/\b(?:success|failure|always|cancelled)\s*\(/;

# The code logger default_logger gives Log::Abstraction.  It is handed the
# parts of the message as an array; printing them unchanged keeps what users
# and scripts read on standard error the same as before there was a logger.
# STDERR is looked up when a message is logged, so a forked child that has
# reopened it logs to its own file.
Readonly::Scalar my $PRINT_TO_STDERR => sub {
	my $message = $_[0]{message};
	print STDERR ref $message eq 'ARRAY' ? join('', @{$message}) : $message, "\n";
};

=encoding utf-8

=head1 NAME

App::Actions::Runner::Support - helpers shared by the parts of the runner

=head1 SYNOPSIS

	use App::Actions::Runner::Support qw(resolve_env status_flags trim_error);

	my $env = resolve_env($expression, [ $workflow_env, $job_env ], $context);
	my $status = status_flags($failed);

Write a file the container will read, safely:

	use App::Actions::Runner::Support qw(write_container_file);

	write_container_file("$temp/scripts/step-1.sh", "echo hello\n", 'the step script');

Find a local action, refusing one that leads out of the project:

	use App::Actions::Runner::Support qw(local_action_dir);

	my $found = local_action_dir($project_dir, './.github/actions/setup');
	print "$found->{relative} is in $found->{dir}\n";

Pass a job's variables to Docker without showing their values to other
users:

	use App::Actions::Runner::Support qw(env_args);

	$docker->container_start(@{ env_args({ TOKEN => $token }) }, 'alpine', 'sleep', '60');

=head1 DESCRIPTION

B<In short:> small helper functions that several parts of the runner
need.  You rarely use them on your own.

The runner is split into a planner (L<App::Actions::Runner>), an image
preparer (L<App::Actions::Runner::Images>), a container manager
(L<App::Actions::Runner::Containers>), a step executor
(L<App::Actions::Runner::Steps>), a parallel scheduler
(L<App::Actions::Runner::Parallel>) and a reporter
(L<App::Actions::Runner::Report>).  The functions here are the ones more than
one of them needs.  None keeps state.

=head1 FUNCTIONS

All are exported on request.

=head2 status_flags

	my $status = status_flags($failed);

Returns the values of the status functions for a job or a step that has, or
has not, failed so far: C<< { success => 1, failure => 0, cancelled => 0 } >>
or the reverse.  A run is never cancelled.

=head3 EXAMPLE

	$expression->condition('failure()', $context, status_flags(1));    # true

=head3 API SPECIFICATION

=head4 INPUT

	{ failed => { type => 'boolean' } }

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub status_flags {
	my ($failed) = @_;

	return {
		success => $failed ? 0 : 1,
		failure => $failed ? 1 : 0,
		cancelled => 0,
	};
}

=head2 chomp_error

	my $text = chomp_error($@);

Returns an exception as a string without its trailing white space.  The
location, if any, is kept: this is for messages that have always shown it.

=head3 EXAMPLE

	print STDERR 'action-run: ', chomp_error($@), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ error => { type => 'any', optional => 1 } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub chomp_error {
	my ($error) = @_;

	my $text = defined $error ? "$error" : '';
	$text =~ s/\s+\z//;

	return $text;
}

=head2 default_logger

	my $logger = default_logger();
	$logger->warn('the image cache could not be written');

Returns the L<Log::Abstraction> logger a run uses when it is given none.  It
prints each message on its own line on standard error, exactly as written:
no time, no level and no file name are added, and a message of several lines
is printed as it is.  It passes on messages of every level, because the
callers already decide which messages to send (for example, nothing but
errors when the run is quiet).  It keeps no copy of the messages, so a long
run does not use more and more memory.

Standard error is looked up each time a message is printed, so a forked job
whose standard error goes to its log file writes its messages there.

=head3 EXAMPLE

	my $runner = App::Actions::Runner->new(%options, logger => default_logger());

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'Log::Abstraction' }

=head3 MESSAGES

None.

=cut

sub default_logger {
	return Log::Abstraction->new(
		logger => $PRINT_TO_STDERR,
		level => 'debug',
		max_messages => 0,
	);
}

=head2 null_logger

	my $logger = null_logger();

Returns a L<Log::Abstraction> logger that throws every message away.  This is
what C<logger =E<gt> 'NULL'> (L<Object::Configure>'s word for "no logging")
becomes, so the code that logs never has to ask whether there is a logger.

=head3 EXAMPLE

	my $actions = App::Actions->new(workflow_file => $file, logger => 'NULL');

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'Log::Abstraction' }

=head3 MESSAGES

None.

=cut

sub null_logger {
	return Log::Abstraction->new(logger => sub { }, level => 'emergency', max_messages => 0);
}

=head2 trim_error

	my $reason = trim_error($@);

Returns an exception as a sentence: its message without the source location
(see L<App::Actions::Error/describe>), or C<undef> when there was no error.
Everything that ends up in a summary or a report goes through here, because a
location is useful in a stack trace and noise in a report someone reads.

=head3 EXAMPLE

	my $ok = eval { $docker->pull($image); 1 };
	$record->{error} = trim_error($@) unless $ok;

=head3 API SPECIFICATION

=head4 INPUT

	{ error => { type => 'any', optional => 1 } }

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=cut

sub trim_error {
	my ($error) = @_;

	return (defined $error && length "$error") ? App::Actions::Error->describe($error) : undef;
}

=head2 resolve_env

	my $env = resolve_env($expression, \@layers, $context);

Merges layers of environment variables, later layers winning, and resolves
the C<${{ }}> expressions in their values.  A value may refer to another
variable through C<env.*>, in any order: when C<B> reads C<env.A>, C<A> is
worked out first.  Each value's own text is interpolated exactly once, so
C<${{ }}> text that comes from somewhere else, such as a commit message, is
never evaluated.  Variables that refer to each other are an error.

=head3 ARGUMENTS

=over 4

=item * C<$expression> - an L<App::Actions::Expression>.

=item * C<\@layers> - hash references; anything else is skipped.

=item * C<$context> - the expression context.  The expressions see a copy
whose C<env> is the variables being resolved; the caller's hash is not
changed.

=back

=head3 RETURNS

A hash reference of name to string.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $env = resolve_env($expression, [ { A => 'x' }, { B => '${{ env.A }}y' } ], {});
	# { A => 'x', B => 'xy' }

=head3 API SPECIFICATION

=head4 INPUT

	{
		expression => { type => 'object', can => 'interpolate' },
		layers     => { type => 'arrayref' },
		context    => { type => 'hashref' },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Unable to evaluate          | A value holds an expression  | Fix the expression in the   |
	| environment variable 'X': E | that does not parse or run   | workflow's env              |
	+-----------------------------+------------------------------+-----------------------------+
	| Environment variable 'X'    | X refers to itself, or to a  | Break the loop: give one of |
	| refers to itself, directly  | variable that refers back    | the variables a value that  |
	| or through other variables  | to it                        | does not use the others     |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	merge the layers into one hash of strings, later layers winning
	for each name, in sorted order:
		resolve(name)
	return the resolved values

	resolve(name):
		if name is resolved, return its value
		if name is being resolved, fail: a cycle
		interpolate its text once, with env reading through resolve
		remember and return the result

=cut

sub resolve_env {
	my ($expression, $layers, $context) = @_;

	# Later layers win: the workflow's env, then the job's, then the step's.
	my %env;
	for my $layer (grep { ref $_ eq 'HASH' } @{$layers}) {
		$env{$_} = App::Actions::Util::stringify($layer->{$_}) for keys %{$layer};
	}

	# A value may refer to another (B: ${{ env.A }}).  Each value's own text
	# is interpolated exactly once, and env.A, when B asks for it, resolves A
	# first (see App::Actions::Runner::Support::Env).  Interpolating
	# results again would expand ${{ }} text that came from a context value,
	# such as a commit message holding ${{ secrets.TOKEN }}, and would let
	# two variables that refer to each other grow on every pass.
	my %resolved;
	my %with_env = %{$context};
	my $state = tie my %lazy, 'App::Actions::Runner::Support::Env', \%env, \%resolved, sub {
		return $expression->interpolate($env{ $_[0] }, \%with_env);
	};
	$with_env{env} = \%lazy;

	# Sorted, so a cycle is reported from the same variable on every run.
	# The caller's $@ is left as it was.
	my $failure;
	{
		local $@;
		eval { my $value; $value = $lazy{$_} for sort keys %env; 1 } or $failure = $@;
	}

	# The tie and %with_env refer to each other through the closure; untie
	# breaks that loop, failure or not.  The tie's first failure wins, and
	# one an evaluator swallowed is still raised.
	$failure = $state->failure || $failure;
	undef $state;
	untie %lazy;
	die $failure if $failure;

	return { %resolved };
}


=head2 boolean_value

	my $flag = boolean_value($expression, $value, $context, $status);

Reads a workflow boolean such as C<continue-on-error>: a YAML boolean, one of
the words C<true>, C<yes>, C<1>, C<false>, C<no>, C<0>, or an expression
whose result is truthy.

=head3 EXAMPLE

	boolean_value($expression, 'yes', {}, status_flags(0));                     # 1
	boolean_value($expression, '${{ matrix.experimental }}', $context, $status); # as the matrix says

=head3 API SPECIFICATION

=head4 INPUT

	{
		expression => { type => 'object', can => 'condition' },
		value      => { type => 'any', optional => 1 },
		context    => { type => 'hashref' },
		status     => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

Whatever the expression's evaluation croaks with.

=cut

sub boolean_value {
	my ($expression, $value, $context, $status) = @_;

	# A YAML boolean is a reference (JSON::PP::Boolean) or a core boolean;
	# either is already the answer.
	return $value ? 1 : 0 if ref $value;

	my $text = App::Actions::Util::trim($value);

	# The words are read without the evaluator, which would take "yes" for
	# a context name and "0" for a number.
	return 0 if $text eq '' || $text =~ $FALSE_WORD;
	return 1 if $text =~ $TRUE_WORD;

	return $expression->condition($text, $context, $status) ? 1 : 0;
}

=head2 has_status_function

Says whether a condition calls C<success()>, C<failure()>, C<always()> or
C<cancelled()>.  One that does not is given an implicit C<success()>.

=head3 EXAMPLE

	has_status_function('always() && matrix.os == "linux"');    # 1

=head3 API SPECIFICATION

=head4 INPUT

	{ condition => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub has_status_function {
	my ($condition) = @_;

	return (defined $condition && $condition =~ $STATUS_FUNCTION) ? 1 : 0;
}

=head2 write_container_file

	write_container_file($path, $contents, $description);

Writes a file that a container will read, in binary mode.  Scripts must keep
LF line endings: on Windows a text-mode handle would write CRLF, and bash
rejects a script whose lines end in C<\r>.

=head3 ARGUMENTS

=over 4

=item * C<$path> - where to write.

=item * C<$contents> - the bytes.

=item * C<$description> - what the file is, for the error message (for
example "the sudo shim").

=back

=head3 RETURNS

Nothing useful.

=head3 SIDE EFFECTS

Creates or replaces the file.

=head3 EXAMPLE

	write_container_file("$temp/scripts/step-1.sh", "echo hi\n", 'the step script');

=head3 API SPECIFICATION

=head4 INPUT

	{
		path        => { type => 'string', min => 1 },
		contents    => { type => 'string' },
		description => { type => 'string' },
	}

=head4 OUTPUT

	{ type => 'undef' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Unable to write WHAT: ERROR | The file could not be opened | Check the temporary         |
	|                             | or written                   | directory's space and mode  |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub write_container_file {
	my ($path, $contents, $description) = @_;

	# The file is created afresh and exclusively (O_EXCL), never opened for
	# writing as it stands: open '>' follows a symbolic link, so a link
	# planted at a predictable name such as scripts/step-1.sh would have the
	# run write a script, secrets and all, wherever it pointed.  A file this
	# run wrote before is removed first; one someone else planted cannot be
	# removed from the sticky directory a shared run uses, and then the
	# create fails rather than writing through it.  Checked by hand rather
	# than by autodie, whose message would name the builtin; the catalogue's
	# names the file the run was writing, which is the part a user can act on.
	my $handle;
	my $written = do {
		no autodie qw(unlink sysopen binmode close);
		unlink $path;
		sysopen($handle, $path, O_WRONLY | O_CREAT | O_EXCL, $NEW_FILE_MODE)
			&& binmode($handle)
			&& print({$handle} $contents)
			&& close($handle);
	};
	__PACKAGE__->throw('runner.write_failed', { what => $description, error => "$!" })
		unless $written;

	return;
}

=head2 local_action_path

	my $relative = local_action_path('./.github/actions/test');

Resolves a C<./path/to/action> reference to a path relative to the project.
Both the run and the preflight resolve references this way, so an action is
read from one place whichever finds it first.

=head3 EXAMPLE

	local_action_path('./.github/actions/build/');    # .github/actions/build

=head3 API SPECIFICATION

=head4 INPUT

	{ uses => { type => 'string' } }

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Local action 'X' does not   | The reference is "./" alone  | Name the action's directory |
	| name a directory inside the |                              |                             |
	| project                     |                              |                             |
	| Local action 'X' must not   | The path contains ".."       | Keep the action inside the  |
	| escape the project directory|                              | repository                  |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub local_action_path {
	my ($uses) = @_;

	# "./a/b/", "/a/b" and "a/b" all mean the directory a/b in the project.
	(my $relative = $uses) =~ s{\A\./}{};
	$relative =~ s{\A/+}{};
	$relative =~ s{/+\z}{};

	__PACKAGE__->throw('runner.local_action_empty', { uses => $uses })
		unless length $relative;
	__PACKAGE__->throw('runner.local_action_escapes', { uses => $uses })
		if $relative =~ m{(?:\A|/)\.\.(?:/|\z)};

	return $relative;
}

=head2 local_action_dir

	my $location = local_action_dir($project_dir, './.github/actions/test');
	print "$location->{dir}\n";

Resolves a C<./path/to/action> reference, as L</local_action_path> does, to
the directory on the host, and checks that the directory really is inside the
project.  The textual check refuses C<..>; this one also refuses a symbolic
link in the repository that leads out of it, which would otherwise have the
host read an F<action.yml> from anywhere the link pointed.  A directory that
does not exist is returned as it would be, for the caller to report.

=head3 EXAMPLE

	my $location = local_action_dir('/src/app', './.github/actions/build/');
	# { relative => '.github/actions/build', dir => '/src/app/.github/actions/build' }

=head3 API SPECIFICATION

=head4 INPUT

	{
		project_dir => { type => 'string', min => 1 },
		uses        => { type => 'string' },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			relative => { type => 'string', min => 1 },
			dir      => { type => 'string', min => 1 },
		},
	}

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Local action 'X' must not   | The path contains "..", or   | Keep the action inside the  |
	| escape the project directory| a link in it leads outside   | repository, as a directory  |
	+-----------------------------+------------------------------+-----------------------------+

And the messages of L</local_action_path>.

=cut

sub local_action_dir {
	my ($project_dir, $uses) = @_;

	my $relative = local_action_path($uses);
	my $dir = File::Spec->catdir($project_dir, split m{/}, $relative);

	# Only a directory that exists can lead anywhere; one that does not is
	# the caller's to report as missing.
	if (-d $dir) {
		my ($real, $root) = map { abs_path($_) } ($dir, $project_dir);
		my $inside = (defined $real && defined $root) ? File::Spec->abs2rel($real, $root) : undef;
		__PACKAGE__->throw('runner.local_action_escapes', { uses => $uses })
			unless defined $inside
				&& !File::Spec->file_name_is_absolute($inside)
				&& $inside !~ m{\A\.\.(?:[/\\]|\z)};
	}

	return { relative => $relative, dir => $dir };
}

=head2 action_inputs

	my $inputs = action_inputs($expression, $action, $step, $uses, $context, $status);

Resolves a local action's inputs: the defaults its metadata declares,
replaced by the calling step's C<with>.  An input the action requires and
neither supplies is an error.

=head3 EXAMPLE

	my $inputs = action_inputs($expression, $action, { with => { name => 'x' } },
		'./.github/actions/greet', $context, status_flags(0));

=head3 API SPECIFICATION

=head4 INPUT

	{
		expression => { type => 'object', can => 'interpolate' },
		action     => { type => 'object', isa => 'App::Actions::Action' },
		step       => { type => 'hashref' },
		uses       => { type => 'string' },
		context    => { type => 'hashref' },
		status     => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Action 'X' requires the     | A required input has no      | Pass it with "with:"        |
	| input 'Y'                   | default and was not given    |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	start with every declared input's default, interpolated, or ''
	overlay every value of the step's with, interpolated
	croak naming the first required input (by name) that is still empty
	return the inputs

=cut

sub action_inputs {
	my ($expression, $action, $step, $uses, $context, $status) = @_;

	my $declared = $action->inputs || {};
	my $with = ref $step->{with} eq 'HASH' ? $step->{with} : {};

	# Defaults first, so the step's own values replace them.
	my %inputs;
	for my $name (keys %{$declared}) {
		my $default = $declared->{$name}{default};
		$inputs{$name} = (defined $default && length $default)
			? $expression->interpolate($default, $context, $status)
			: '';
	}

	# A structured value (a YAML list, say) is passed as its JSON text, as
	# GitHub does; only a scalar can hold an expression.
	for my $name (keys %{$with}) {
		my $value = $with->{$name};
		$value = $expression->interpolate(App::Actions::Util::stringify($value), $context, $status)
			unless ref $value;
		$inputs{$name} = App::Actions::Util::stringify($value);
	}

	# Sorted, so the input named in the error is the same on every run.
	for my $name (sort keys %{$declared}) {
		next unless $declared->{$name}{required};
		next if defined $inputs{$name} && length $inputs{$name};
		__PACKAGE__->throw('runner.input_required', { uses => $uses, name => $name });
	}

	return \%inputs;
}

=head2 redact

	my $safe = redact($docker, $text);

Masks the secrets the Docker object knows about, when it can; a
caller-supplied Docker object need not offer redaction.

=head3 EXAMPLE

	print redact($docker, "token is $token\n");    # token is ***

=head3 API SPECIFICATION

=head4 INPUT

	{
		docker => { type => 'object' },
		text   => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=cut

sub redact {
	my ($docker, $text) = @_;

	return (defined $text && $docker->can('redact')) ? $docker->redact($text) : $text;
}

=head2 env_args

	push @args, @{ env_args(\%env) };

Turns an environment into C<docker> arguments: C<-e> and an
L<App::Actions::Docker::Variable>
for each variable, sorted by name so the command line is the same on every
run.  Each variable reads as C<NAME=VALUE>; L<App::Actions::Docker> passes its
value to the client through the environment, so it never appears among the
client's arguments, which every user of the host can read.

=head3 EXAMPLE

	my $args = env_args({ B => 2, A => 1 });
	print join(' ', @{$args}), "\n";    # -e A=1 -e B=2

=head3 API SPECIFICATION

=head4 INPUT

	{ env => { type => 'hashref' } }

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None.

=cut

sub env_args {
	my ($env) = @_;

	# Each variable is an object that reads as NAME=VALUE, so that
	# App::Actions::Docker can give its value to the client through the
	# environment rather than on a command line every user can read.
	return [ map { ('-e', App::Actions::Docker::Variable->new($_, $env->{$_})) } sort keys %{$env} ];
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The functions do not validate their arguments: they are called many
times per step by the other parts of the runner, which validate what they
were given when they are constructed.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Arguments are not checked.>  These functions trust their callers,
for speed.  Pass what the documentation says.

=item * B<L</write_container_file> replaces the file.>  It removes the old
file and creates a new one with mode 0600; it never writes through a
symbolic link.  If someone else's file is in the way (in a shared folder),
it fails rather than overwrite it.

=item * B<L</local_action_dir> refuses links out of the project>, with
C<runner.local_action_escapes>.  A link that stays inside the project is
allowed.  A path that does not exist is returned as it is, for the caller to
report.

=item * B<L</env_args> returns objects, not strings.>  Pass them to an
L<App::Actions::Docker> method so that their values are kept off the
command line; elsewhere they turn into C<NAME=VALUE> text.

=item * B<L</redact> replaces whole values only.>  A secret that appears
split or encoded is not hidden.

=item * B<L</resolve_env> refuses a cycle.>  C<A: ${{ env.B }}> with
C<B: ${{ env.A }}>, or a variable that uses itself, is the error
C<runner.env_cycle>, not a partly filled-in value.  To add to a variable
from an outer layer, give the new value another name.

=item * B<L</default_logger> does not filter by level.>  It prints every
message it is given.  To keep only some levels, or to write them to a file,
give the run a L<Log::Abstraction> logger of your own (see
L<App::Actions/new>).

=back

=head1 ENCODING

Environment names and values, step text and secrets are Perl character
strings and may contain any Unicode text, including non-ASCII characters
and emoji.  L</write_container_file> writes the bytes it is given: encode
text (for example as UTF-8) before you pass it.  Paths are used as bytes.
Action paths (C<./...>) should be ASCII, as on GitHub.

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

=head2 status_flags

	┌─ StatusFlags ─────────────────────────────────────
	│ failed? : 𝔹
	│ s!      : {success, failure, cancelled} → 𝔹
	├───────────────────────────────────────────────────
	│ s!(success) = ¬ failed? ∧ s!(failure) = failed? ∧ s!(cancelled) = false
	└───────────────────────────────────────────────────

=head2 chomp_error

	┌─ ChompError ──────────────────────────────────────
	│ error? : VALUE
	│ s!     : seq CHAR
	├───────────────────────────────────────────────────
	│ s! = rtrim(string(error?))
	└───────────────────────────────────────────────────

=head2 default_logger

	┌─ DefaultLogger ───────────────────────────────────
	│ logger! : LogAbstraction
	├───────────────────────────────────────────────────
	│ ∀ level : LEVEL; m : seq CHAR •
	│     logger!.log(level, m) ⇒ stderr' = stderr ⁀ m ⁀ ⟨NEWLINE⟩
	│ logger!.history = ⟨⟩
	└───────────────────────────────────────────────────

=head2 null_logger

	┌─ NullLogger ──────────────────────────────────────
	│ logger! : LogAbstraction
	├───────────────────────────────────────────────────
	│ ∀ level : LEVEL; m : seq CHAR • logger!.log(level, m) ⇒ stderr' = stderr
	└───────────────────────────────────────────────────

=head2 trim_error

	┌─ TrimError ───────────────────────────────────────
	│ error? : VALUE
	│ s!     : optional seq CHAR
	├───────────────────────────────────────────────────
	│ error? = ⊥ ∨ string(error?) = ⟨⟩ ⇒ s! = ⊥
	│ otherwise s! = Describe(error?)
	└───────────────────────────────────────────────────

=head2 resolve_env

	┌─ ResolveEnv ──────────────────────────────────────
	│ layers?  : seq (NAME ⇸ VALUE)
	│ context? : CONTEXT
	│ env!     : NAME ⇸ seq CHAR
	├───────────────────────────────────────────────────
	│ let merged == ⊕/ layers?
	│ let refs == {a, b : dom merged | interpolating merged(a) reads env.b}
	│ (∃ n : dom merged • (n, n) ∈ refs⁺) ⇒ raise runner.env_cycle
	│ otherwise env! = μ e • {n : dom merged •
	│     n ↦ interpolate(merged(n), context? ⊕ {env ↦ e})}
	│ (each merged(n) is interpolated once; a result is never re-read)
	└───────────────────────────────────────────────────

=head2 boolean_value

	┌─ BooleanValue ────────────────────────────────────
	│ value? : VALUE
	│ b!     : 𝔹
	├───────────────────────────────────────────────────
	│ value? ∈ REF ⇒ b! = truthy(value?)
	│ value? = ⊥ ∨ trim(value?) = ⟨⟩ ⇒ b! = false
	│ trim(value?) ∈ TRUE_WORD ⇒ b! = true
	│ trim(value?) ∈ FALSE_WORD ⇒ b! = false
	│ otherwise b! = condition(trim(value?))
	└───────────────────────────────────────────────────

=head2 has_status_function

	┌─ HasStatusFunction ───────────────────────────────
	│ condition? : optional seq CHAR
	│ b!         : 𝔹
	├───────────────────────────────────────────────────
	│ b! ⇔ condition? ≠ ⊥ ∧ condition? contains f( for some f ∈ STATUS
	└───────────────────────────────────────────────────

=head2 write_container_file

	┌─ WriteContainerFile ──────────────────────────────
	│ ΔFileSystem
	│ path?, contents? : seq CHAR
	├───────────────────────────────────────────────────
	│ files' = files ⊕ {path? ↦ contents?}
	└───────────────────────────────────────────────────

=head2 local_action_path

	┌─ LocalActionPath ─────────────────────────────────
	│ uses? : seq CHAR
	│ rel!  : seq CHAR
	├───────────────────────────────────────────────────
	│ rel! = stripSlashes(stripDotSlash(uses?))
	│ rel! ≠ ⟨⟩ ∧ ".." ∉ segments(rel!)
	└───────────────────────────────────────────────────

=head2 local_action_dir

	┌─ LocalActionDir ──────────────────────────────────
	│ projectDir?, uses? : seq CHAR
	│ loc!               : LOCATION
	├───────────────────────────────────────────────────
	│ loc!.relative = localActionPath(uses?)
	│ loc!.dir = projectDir? ⁀ "/" ⁀ loc!.relative
	│ isDirectory(loc!.dir) ⇒ realpath(loc!.dir) ∈ subtree(realpath(projectDir?))
	└───────────────────────────────────────────────────

=head2 action_inputs

	┌─ ActionInputs ────────────────────────────────────
	│ declared : NAME ⇸ INPUT
	│ with?    : NAME ⇸ VALUE
	│ inputs!  : NAME ⇸ seq CHAR
	├───────────────────────────────────────────────────
	│ inputs! = {n : dom declared • n ↦ interpolate(default(n))} ⊕
	│           {n : dom with? • n ↦ interpolate(with?(n))}
	│ ∀ n : dom declared | required(n) • inputs!(n) ≠ ⟨⟩
	└───────────────────────────────────────────────────

=head2 redact

	┌─ Redact ──────────────────────────────────────────
	│ text? : optional seq CHAR
	│ s!    : optional seq CHAR
	├───────────────────────────────────────────────────
	│ text? = ⊥ ⇒ s! = ⊥
	│ docker can redact ⇒ s! = docker.redact(text?)
	│ otherwise s! = text?
	└───────────────────────────────────────────────────

=head2 env_args

	┌─ EnvArgs ─────────────────────────────────────────
	│ env? : NAME ⇸ seq CHAR
	│ a!   : seq seq CHAR
	├───────────────────────────────────────────────────
	│ a! = ⁀/ ⟨n : sorted(dom env?) • ⟨"-e", n ⁀ "=" ⁀ env?(n)⟩⟩
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The functions keep no state.  The one with a life cycle is
L</write_container_file>, which takes a file in a runner folder through
these states:

	  write_container_file($path, $contents, $what)
	        |
	        v
	+------------------+  a file this run wrote before, or a
	| REMOVE OLD NAME  |  symbolic link: removed (unlink)
	+------------------+  (in a shared sticky folder, another user's
	        |              file cannot be removed and stays)
	        v
	+------------------+  O_CREAT | O_EXCL: fails if anything
	| CREATE NEW FILE  |  is still at the name; never follows a link
	| mode 0600        |----------------------------------------------+
	+------------------+                                              |
	        |                                                         |
	        v                                                         |
	+------------------+  print fails (disk full, ...)                |
	| WRITE AND CLOSE  |--------------------------------------------->+
	+------------------+                                              |
	        |                                                         v
	        v                                         +---------------------------+
	+------------------+                              | throw runner.write_failed |
	| WRITTEN          |                              | naming $what and the error|
	+------------------+                              +---------------------------+

	And local_action_dir($project, $uses):

	  "./path" -> relative path -> exists? --no--> returned as it is
	                                 | yes
	                                 v
	                 real path inside the project? --no--> throw
	                                 | yes                 runner.local_action_escapes
	                                 v
	                           { relative, dir }

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
