package App::Actions::Runner::Parallel;

use strict;
use warnings;
use autodie qw(:all);

use File::Spec;
use IO::Handle ();
use JSON::PP ();
use POSIX ();
use Readonly;
use Sub::Private ();
use Time::HiRes ();

use App::Actions::Access;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Runner::Support qw(chomp_error default_logger);

our $VERSION = '0.002.1';

# How long the parent waits between looks at the jobs' logs.  Short enough
# that a line appears while its job is still working, long enough that the
# polling costs nothing noticeable.
Readonly::Scalar my $POLL_SECONDS => 0.05;

# The exit status of a child that could not even redirect its output:
# EX_SOFTWARE, since it is a fault here rather than in the job.
Readonly::Scalar my $EX_SOFTWARE => 70;

# A kept log's name includes the job's, made safe for any filesystem and cut
# to this length.
Readonly::Scalar my $LOG_NAME_LENGTH => 60;

# Windows emulates fork() with threads that share the parent's handles.
Readonly::Scalar my $NO_FORK_OS => 'MSWin32';

=encoding utf-8

=head1 NAME

App::Actions::Runner::Parallel - run the jobs of one matrix beside each other

=head1 SYNOPSIS

	my $parallel = App::Actions::Runner::Parallel->new(
		capacity => 4,
		temp_path => $temp_path,
		run_job => sub { my ($entry) = @_; ...; return $result },
		on_result => sub { my ($result) = @_; ... },
	);

	my $outcomes = $parallel->run(\@plans, $fail_fast);
	if (!$outcomes) { ... run them one at a time ... }

Count the failures, and say where the logs are:

	my $outcomes = $parallel->run(\@plans, 0) or return;
	my @failed = grep { $_->{result}{result} eq 'failure' } grep { $_->{started} } @{$outcomes};
	print scalar(@failed), " jobs failed\n";
	print "$_->{name}: $_->{path}\n" for @{ $parallel->logs };

=head1 DESCRIPTION

B<In short:> this module runs several jobs of one matrix at the same time,
each in its own process, and shows their output as it happens with the job
name in front of every line.  It is a part of L<App::Actions::Runner>; you
rarely use it on its own.

Each job runs in a child process of its own, with its own runner directory,
its output written to a log, and its result written to a file the parent
reads when it exits.  The parent shows each log as it grows, a line at a
time, with the job's name in front of every line - C<[test (n=one)]> - so the
lines of jobs working at the same moment can be told apart.  With fail-fast,
a failed job stops further jobs from starting; the ones already running
finish.

=head1 METHODS

=head2 new

=head3 ARGUMENTS

=over 4

=item * C<capacity> - how many jobs may run at once.

=item * C<temp_path> - the run's temporary directory; each job gets
C<job-N> under it, with C<job-N.log> and C<job-N.json> beside it.

=item * C<run_job> - a code reference that runs one job in the current
process and returns its result hash; it is called in the child.

=item * C<on_result> - optional; called in the parent with each result
read back, so the caller can take what the child learned (the images it
pulled).

=item * C<quiet> - optional; show nothing of the jobs' logs.

=item * C<logger> - optional; a L<Log::Abstraction> object (default:
L<App::Actions::Runner::Support/default_logger>, standard error).  A job
that dies in its child process is logged there at the C<error> level, so
with the default logger it lands in that job's log file.

=back

=head3 RETURNS

An C<App::Actions::Runner::Parallel> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

See the L</SYNOPSIS>.

=head3 API SPECIFICATION

=head4 INPUT

	{
		capacity  => { type => 'integer', min => 1 },
		temp_path => { type => 'string', min => 1 },
		run_job   => { type => 'coderef' },
		on_result => { type => 'coderef', optional => 1 },
		quiet     => { type => 'boolean', optional => 1 },
		logger    => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Parallel' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | An argument is missing or    | Pass the documented         |
	| ...Parallel::new: REASON  | has the wrong type           | arguments                   |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		capacity => { type => 'integer', min => 1 },
		temp_path => { type => 'string', min => 1 },
		run_job => { type => 'coderef' },
		on_result => { type => 'coderef', optional => 1 },
		quiet => { type => 'boolean', optional => 1 },
		# Where warnings and errors go; standard error when none is given.
		logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	});

	return bless { on_result => sub { }, %{$params}, logger => $params->{logger} || default_logger(), slots => 0, logs => [] }, $class;
}

=head2 run

	my $outcomes = $parallel->run(\@plans, $fail_fast);

Runs one matrix group's jobs beside each other.

=head3 ARGUMENTS

=over 4

=item * C<\@plans> - the runnable plans, each with C<display_name> and
C<max_parallel>, in the order the jobs should start.

=item * C<$fail_fast> - whether a failure stops the jobs not yet started.

=back

=head3 RETURNS

C<undef> when the group is better run one at a time - a single job, a
capacity below two once C<max-parallel> is applied, or a host without a
reliable C<fork()> - so the caller can fall back to its simple loop.
Otherwise an array reference of C<< { plan, started, result } >>, one per
plan in plan order.

=head3 SIDE EFFECTS

Forks; prints the jobs' output, prefixed; writes their logs and results
under the temporary directory.  Kills the jobs still running if one could
not report or the parent is interrupted, and then dies.

=head3 EXAMPLE

	my $outcomes = $parallel->run(\@plans, 1) or return $self->_run_serially(\@plans);
	for my $outcome (@{$outcomes}) {
		print "$outcome->{plan}{display_name}: ", ($outcome->{started} ? $outcome->{result}{result} : 'skipped'), "\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		plans     => { type => 'arrayref' },
		fail_fast => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref', optional => 1 }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| job 'X' did not run         | The job's process died       | Read its log, shown above   |
	|                             | before it reported a result  |                             |
	| action-run: E (in a log)    | The job itself died          | Read the message            |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	work out the capacity: the configured one, capped by max-parallel and
		by the number of plans
	give up (return undef) for fewer than two plans, a capacity below two,
		or Windows
	start jobs until the capacity is reached
	until no job is running:
		show what each running job has written since the last look
		when a job exits, read its result and show the rest of its log
		a job with no result stops new starts and is an error
		a failed job under fail-fast stops new starts
		otherwise start more jobs
	on an error, kill the running jobs and die with it
	return the outcomes

=cut

sub run {
	my ($self, $plans, $fail_fast) = @_;

	my $capacity = $self->_capacity($plans);
	return undef if $capacity < 2 || $^O eq $NO_FORK_OS;    ## no critic (ProhibitExplicitReturnUndef)

	my $group = {
		entries => [ map { { plan => $_, started => 0, result => undef } } @{$plans} ],
		next => 0,
		running => {},
		stopping => 0,
		error => undef,
		capacity => $capacity,
	};

	# The caller's $@ is left as it was when the group runs to the end.
	{
		local $@;
		eval {
			$self->_start_more($group);
			$self->_watch($group, $fail_fast);
			1;
		} or $group->{error} = $@;
	}

	if (defined $group->{error}) {
		# An interrupted or broken run should not leave jobs working behind
		# the report.  They are killed rather than waited for, which is why
		# a container they started can outlive this run.
		no autodie qw(kill);
		for my $pid (keys %{ $group->{running} }) {
			kill 'KILL', $pid;
			waitpid($pid, 0);
		}
		die $group->{error};
	}

	return $group->{entries};
}

=head2 logs

Returns an array reference of the logs the jobs wrote:
C<< { slot, name, file, path } >>, where C<file> is a name that says which
job the log belongs to once the numbered directory is gone.

=head3 EXAMPLE

	print "$_->{name}: $_->{path}\n" for @{ $parallel->logs };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None.

=cut

sub logs {
	my ($self) = @_;

	return $self->{logs};
}

# _capacity
# Purpose:     How many of these plans may run at once.
# Entry:       $plans.
# Exit status: Returns the configured capacity, capped by the group's
#              max-parallel and by the number of plans; 0 for no plans.
# Side effects: None.
sub _capacity {
	my ($self, $plans) = @_;

	my $capacity = $self->{capacity};
	my $max_parallel = @{$plans} ? $plans->[0]{max_parallel} : undef;
	$capacity = $max_parallel + 0
		if defined $max_parallel && !ref $max_parallel && $max_parallel =~ /\A[1-9][0-9]*\z/ && $max_parallel < $capacity;

	return $capacity > @{$plans} ? scalar @{$plans} : $capacity;
}

# _start_more
# Purpose:     Start jobs until the group's capacity is reached or none are left.
# Entry:       $group - the state of this run.
# Exit status: Returns nothing.
# Side effects: Forks children, or runs a job here when fork fails; records
#              each job's log.
sub _start_more {
	my ($self, $group) = @_;

	my $entries = $group->{entries};
	while ($group->{next} < @{$entries} && keys %{ $group->{running} } < $group->{capacity}) {
		my $entry = $entries->[ $group->{next}++ ];
		my $slot = ++$self->{slots};
		my $name = $entry->{plan}{display_name};

		@{$entry}{qw(started temp log result_path shown pending)} = (
			1,
			File::Spec->catdir($self->{temp_path}, "job-$slot"),
			File::Spec->catfile($self->{temp_path}, "job-$slot.log"),
			File::Spec->catfile($self->{temp_path}, "job-$slot.json"),
			0,
			'',
		);

		# The log is kept after the run, so it needs a name that says which
		# job it is once the numbered directory has gone.
		push @{ $self->{logs} }, { slot => $slot, name => $name, file => _log_name($slot, $name), path => $entry->{log} };

		my $pid = do { no autodie qw(fork); fork() };
		if (!defined $pid) {
			# No child could be made, so the job runs here, its output still
			# collected rather than mixed into the others'.
			$self->_run_here($entry);
			$self->_note_missing($group, $entry);
			next;
		}
		POSIX::_exit($self->_child($entry)) if $pid == 0;

		$group->{running}{$pid} = $entry;
	}

	return;
}

# _watch
# Purpose:     Show the running jobs' output and collect them as they finish.
# Entry:       $group; $fail_fast.
# Exit status: Returns when no job is running.
# Side effects: Prints; reaps children; starts more jobs as slots free up.
sub _watch {
	my ($self, $group, $fail_fast) = @_;

	my $running = $group->{running};
	while (%{$running}) {
		# Waiting for a child means waiting while it works, and a line it has
		# already printed is worth reading now.
		my $pid = waitpid(-1, POSIX::WNOHANG());
		if (!$pid) {
			$self->_stream($_) for values %{$running};
			Time::HiRes::sleep($POLL_SECONDS);
			next;
		}
		# -1 means there is no child left to wait for, although some are
		# still listed: the caller set $SIG{CHLD} to IGNORE, say, and the
		# system reaped them.  They have finished, so they are collected now
		# rather than left out of the results without a word.
		my @finished = $pid < 0 ? keys %{$running} : ($pid);
		for my $done (@finished) {
			my $entry = delete $running->{$done};
			next unless $entry;

			$self->_collect($entry);
			$self->_note_missing($group, $entry);
			$group->{stopping} = 1 if $fail_fast && $entry->{result} && ($entry->{result}{result} || '') eq 'failure';
		}

		$self->_start_more($group) unless $group->{stopping};
	}

	return;
}

# _note_missing
# Purpose:     A job that left no result died before it could report; its
#              log, just shown, has its own account of the failure.
# Entry:       $group; $entry.
# Exit status: Returns nothing.
# Side effects: Stops new starts and records the group's error.
sub _note_missing {
	my ($self, $group, $entry) = @_;

	if (!$entry->{result}) {
		$group->{stopping} = 1;
		$group->{error} = $self->i18n('runner.parallel.did_not_run', { name => $entry->{plan}{display_name} }) . "\n"
			unless defined $group->{error};
	}

	return;
}

# _child
# Purpose:     Run one job in a forked child, with its output going to its log.
# Entry:       $entry.
# Exit status: Returns the child's exit status: 0 when it wrote a result.
# Side effects: Redirects STDOUT and STDERR; never returns to the parent's
#              code (the caller exits with the status).
sub _child {
	my ($self, $entry) = @_;

	# autodie would die here, and a die in the child would carry on running
	# the parent's code; a child that cannot write its log just exits.
	{
		no autodie qw(open);
		open(STDOUT, '>', $entry->{log}) or POSIX::_exit($EX_SOFTWARE);
		open(STDERR, '>&', \*STDOUT) or POSIX::_exit($EX_SOFTWARE);
	}

	# Buffered writes would sit in this child until it exited, and the
	# parent would have nothing to show while the job works.
	STDOUT->autoflush(1);
	STDERR->autoflush(1);

	# A plain print goes to the selected handle, which the caller may have
	# pointed elsewhere; the job's output belongs in its log.
	select STDOUT;

	return $self->_run_job($entry);
}

# _run_job
# Purpose:     Run the job and write its result where the parent will read it.
# Entry:       $entry.
# Exit status: Returns 0 when a result was written, 1 otherwise.
# Side effects: Runs the job; writes the result file; prints an error.
sub _run_job {
	my ($self, $entry) = @_;

	my $ok = eval {
		$self->_write_result($entry->{result_path}, $self->{run_job}->($entry));
		1;
	};
	if (!$ok) {
		my $error = chomp_error($@ || $self->i18n('runner.parallel.did_not_run', { name => $entry->{plan}{display_name} }));
		$self->{logger}->error($self->i18n('runner.error', { error => $error }));
	}

	STDOUT->flush;
	STDERR->flush;

	return $ok ? 0 : 1;
}

# _run_here
# Purpose:     Run a job in this process, for a host where fork() failed,
#              with its output redirected to its log as a child's would be.
# Entry:       $entry.
# Exit status: Returns nothing.
# Side effects: Redirects and restores STDOUT and STDERR; runs the job;
#              collects its result.
sub _run_here {
	my ($self, $entry) = @_;

	my ($saved_stdout, $saved_stderr);
	{
		no autodie qw(open);
		open($saved_stdout, '>&', \*STDOUT) or $self->throw('runner.parallel.dup_failed', { handle => 'STDOUT' });
		open($saved_stderr, '>&', \*STDERR) or $self->throw('runner.parallel.dup_failed', { handle => 'STDERR' });
		open(STDOUT, '>', $entry->{log}) or $self->throw('runner.file_write_failed', { file => $entry->{log}, error => "$!" });
		open(STDERR, '>&', \*STDOUT) or $self->throw('runner.parallel.dup_failed', { handle => 'STDOUT' });
	}
	STDOUT->autoflush(1);
	STDERR->autoflush(1);

	# As in a child, the job's plain prints go to its log whatever handle
	# the caller had selected; the caller's choice is put back afterwards.
	my $selected = select STDOUT;
	$self->_run_job($entry);
	select $selected;

	{
		no autodie qw(open);
		open(STDOUT, '>&', $saved_stdout) or $self->throw('runner.parallel.restore_failed', { handle => 'STDOUT' });
		open(STDERR, '>&', $saved_stderr) or $self->throw('runner.parallel.restore_failed', { handle => 'STDERR' });
	}

	$self->_collect($entry);

	return;
}

# _stream
# Purpose:     Show the part of a job's log not shown yet, a line at a time,
#              with the job named on each line.  A partial last line waits
#              for the rest of it.
# Entry:       $entry.
# Exit status: Returns nothing.
# Side effects: Prints; advances the entry's shown offset and pending text.
sub _stream {
	my ($self, $entry) = @_;

	return if $self->{quiet};

	my $chunk = _read_from($entry->{log}, $entry->{shown});
	return unless defined $chunk && length $chunk;

	$entry->{shown} += length $chunk;
	$entry->{pending} .= $chunk;

	# The complete lines are split off in one pass; the unfinished last one
	# waits for the rest of it.  Cutting one line at a time off the front of
	# the buffer, while (s/\A([^\n]*)\n//), copies what is left every time,
	# which is quadratic: a 200,000-line chunk took sixteen seconds.
	my @lines = split /\n/, $entry->{pending}, -1;
	my $rest = pop @lines;
	$entry->{pending} = defined $rest ? $rest : q{};

	my $prefix = _prefix($entry);
	for my $line (@lines) {
		$line =~ s/\r\z//;

		# A blank line stays blank: a prefix on it would be noise rather
		# than a name for something the job said.
		print length $line ? "$prefix$line\n" : "\n";
	}
	STDOUT->flush;

	return;
}

# _collect
# Purpose:     Read the result a finished job left, after showing the rest of
#              its log, including a last line without a newline.
# Entry:       $entry.
# Exit status: Returns nothing.
# Side effects: Prints; sets the entry's result; calls on_result.
sub _collect {
	my ($self, $entry) = @_;

	$self->_stream($entry);
	if (!$self->{quiet} && length $entry->{pending}) {
		(my $last = $entry->{pending}) =~ s/\r\z//;
		$entry->{pending} = '';
		print _prefix($entry), $last, "\n";
		STDOUT->flush;
	}

	my $path = $entry->{result_path};
	return unless defined $path && -s $path;

	my $json = _read_from($path, 0);
	$self->throw('runner.file_read_failed', { file => $path, error => "$!" }) unless defined $json;

	my $result = do { local $@; eval { JSON::PP->new->decode($json) } };
	return unless ref $result eq 'HASH';

	$entry->{result} = $result;
	$self->{on_result}->($result);

	return;
}

# _write_result
# Purpose:     Write a job's result as JSON for the parent.
# Entry:       $path; $result.
# Exit status: Returns nothing.
# Side effects: Writes the file.
sub _write_result {
	my ($self, $path, $result) = @_;

	my $handle;
	my $written = do {
		no autodie qw(open close);
		open($handle, '>', $path)
			&& print({$handle} JSON::PP->new->canonical->encode($result))
			&& close($handle);
	};
	$self->throw('runner.file_write_failed', { file => $path, error => "$!" }) unless $written;

	return;
}

# _read_from
# Purpose:     Read a file from an offset to its end, as bytes.
# Entry:       $path; $offset.
# Exit status: Returns the text, or undef when the file cannot be read there.
# Side effects: None.
sub _read_from {
	my ($path, $offset) = @_;

	# A log that is being written may not be readable for a moment; the
	# next look will try again.
	no autodie qw(open seek close);
	my $text;
	if (defined $path && -f $path && open(my $handle, '<', $path)) {
		binmode $handle;
		$text = do { local $/; <$handle> } if seek($handle, $offset, 0);
		close $handle;
	}

	return $text;
}

# _log_name
# Purpose:     A file name that says which job a kept log belongs to, on a
#              filesystem that may not allow every character a matrix value
#              can contain.
# Entry:       $slot; $name - the job's display name.
# Exit status: Returns job-SLOT-NAME.log, or job-SLOT.log when nothing is left.
# Side effects: None.
sub _log_name {
	my ($slot, $name) = @_;

	$name = '' unless defined $name;
	$name =~ s/[^A-Za-z0-9_.-]+/_/g;
	# Each end separately: as one alternation the second branch rescans every
	# inner run of separators from each of its positions, which is quadratic.
	# The end is trimmed after the cut, which can leave a separator last.
	$name =~ s/\A[_.-]+//;
	$name = substr($name, 0, $LOG_NAME_LENGTH);
	$name =~ s/[_.-]+\z//;

	return length $name ? "job-$slot-$name.log" : "job-$slot.log";
}

# _prefix
# Purpose:     What goes in front of each line of a job's output.
# Entry:       $entry.
# Exit status: Returns "[name] ".
# Side effects: None.
sub _prefix {
	my ($entry) = @_;

	my $name = $entry->{plan}{display_name};

	return '[' . (defined $name ? $name : '') . '] ';
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

=item * Windows has no reliable C<fork()>, so its jobs run one at a time.

=item * A run that keeps its containers, a dry run and an explain run are not
run in parallel; the caller decides that, because only it knows why.

=item * The logs are polled rather than watched, twenty times a second.

=item * A killed job's containers are not removed: only the process that
started them knew their names.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<C<run> may return C<undef>.>  That is not an error: it means
"run these one at a time".  Always have a fallback.

=item * B<C<run_job> runs in a child process.>  Changes it makes to
variables are not seen by the parent.  Return everything the parent needs
in the result.

=item * B<C<max-parallel> wins.>  The workflow's C<strategy.max-parallel>
can lower C<capacity>, never raise it.

=item * B<Fail-fast does not stop running jobs.>  It only stops jobs that
have not started yet.

=item * B<Output lines can be delayed.>  The logs are read 20 times a
second, and a line is shown only when it is complete.

=item * B<A killed parent leaves containers.>  If the parent process is
killed with SIGKILL, the children's containers are not removed.  Use
C<docker ps --filter name=action-run-> to find them.

=back

=head1 ENCODING

Job output is copied from the log files to your terminal as bytes,
unchanged, so it may contain any characters the job printed.  Windows line
ends (C<\r\n>) are shown as C<\n>.  Job names in the line prefix are Perl
character strings and may contain non-ASCII characters and emoji; log file
names are made from them with unsafe characters replaced, so they are
ASCII.

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

	┌─ Parallel ────────────────────────────────────────
	│ capacity : ℕ₁
	│ slots    : ℕ          -- jobs started so far, numbering their files
	│ logs     : seq LOG
	├───────────────────────────────────────────────────
	│ #logs = slots
	└───────────────────────────────────────────────────

=head2 run

	┌─ RunParallel ─────────────────────────────────────
	│ ΔParallel
	│ plans?    : seq PLAN
	│ failFast? : 𝔹
	│ out!      : optional seq OUTCOME
	├───────────────────────────────────────────────────
	│ #plans? < 2 ∨ cap < 2 ∨ os = MSWin32 ⇒ out! = ⊥
	│ otherwise #out! = #plans? ∧
	│     (∀ t : TIME • #{o : ran out! | running(o, t)} ≤ cap) ∧
	│     (failFast? ∧ (∃ o : ran out! • failed(o)) ⇒ no plan after the
	│         first failure is started once it is seen)
	│ where cap = min(capacity, maxParallel(head plans?), #plans?)
	└───────────────────────────────────────────────────

=head2 logs

	┌─ Logs ────────────────────────────────────────────
	│ ΞParallel
	│ l! : seq LOG
	├───────────────────────────────────────────────────
	│ l! = logs
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The parent process goes through these states for one call to L</run>; each
child goes through the states on the right:

	  run(\@plans, $fail_fast)
	        |
	        v
	  one plan, capacity < 2, or no reliable fork()? --yes--> return undef
	        | no                                      (caller runs them serially)
	        v
	+------------------+                       Child (one per job):
	| STARTING         |  fork while fewer      +--------------------+
	|                  |  than capacity run --->| RUNNING            |
	+------------------+                        | own runner folder; |
	        |                                   | output -> log file |
	        v                                   +--------------------+
	+------------------+                                 |
	| WATCHING         |  every 1/20 s: new complete     | run_job returns
	|                  |  log lines printed as           v
	|                  |  "[job name] line"      +--------------------+
	+------------------+                         | RESULT WRITTEN     |
	   |       |      |                          | to a file; exit    |
	   |       |      |                          +--------------------+
	   |       |      | a child exits
	   |       |      v
	   |       |  +------------------+  result file missing or unreadable:
	   |       |  | COLLECTING       |  kill the others -> die
	   |       |  | on_result(...)   |
	   |       |  +------------------+
	   |       |      |
	   |       |      | failure and fail-fast: start no more jobs
	   |       |      | otherwise: back to STARTING if plans are left
	   |       |
	   |       | SIGINT / SIGTERM: kill the children -> die
	   |
	   | all children done
	   v
	  return [ { plan, started, result }, ... ]   (logs() lists the log files)

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
