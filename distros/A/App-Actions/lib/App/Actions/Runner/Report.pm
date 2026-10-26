package App::Actions::Runner::Report;

use strict;
use warnings;
use autodie qw(:all);

use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use IO::Handle ();
use POSIX ();
use Readonly;
use Sub::Private ();

use App::Actions::Access;
use App::Actions::I18N qw(i18n validate_args);
use App::Actions::Runner::Support qw(default_logger redact);

our $VERSION = '0.002.1';

# The width of the job-name column of the summary.
Readonly::Scalar my $NAME_WIDTH => 50;

# Kept logs may quote secrets from a job's environment, so they are private.
Readonly::Scalar my $DIRECTORY_MODE => oct('0700');
Readonly::Scalar my $FILE_MODE => oct('0600');

# A name keep_logs joins to a path must stay one name: letters, digits, _ . -
# but never . or .., which are directories.
Readonly::Scalar my $PLAIN_NAME => qr/\A(?!\.\.?\z)[A-Za-z0-9_.-]+\z/;

=encoding utf-8

=head1 NAME

App::Actions::Runner::Report - what a run tells its user at the end

=head1 SYNOPSIS

	my $report = App::Actions::Runner::Report->new(docker => $docker);

	$report->record('test (perl=5.40)', 'success');
	$report->record('lint', 'failure')->fail;
	$report->print_summary;    # === Workflow summary === ... Workflow FAILED

Keep the logs of a parallel run, and say where they went:

	$report->keep_logs($parallel->logs, App::Actions::Logs::default_directory(), $run_id)
		->print_kept_logs;

Tell the user what a run with C<keep> left behind:

	$report->print_kept_resources($containers->remaining, $temp_path);

Decide the exit status:

	exit($report->failed ? 1 : 0);

=head1 DESCRIPTION

B<In short:> this module writes what a run tells you at the end: one line
per job, whether the workflow passed, and where the logs are.  It is a part
of L<App::Actions::Runner>; you rarely use it on its own.

Collects one line per job as the run goes, says at the end whether the
workflow succeeded, and keeps the logs of the jobs that ran in parallel: they
are copied out of the temporary directory before it is removed, so a failed
job's own account of what went wrong can be read after the run (and
C<action-run logs> lists them).

=head1 METHODS

=head2 new

=head3 ARGUMENTS

=over 4

=item * C<docker> - used to mask secrets in job names.

=item * C<quiet> - optional; print nothing.

=item * C<logger> - optional; a L<Log::Abstraction> object (default:
L<App::Actions::Runner::Support/default_logger>, standard error).  Logs
the jobs' logs that could not be kept, at the C<warn> level.

=back

=head3 RETURNS

An C<App::Actions::Runner::Report> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $report = App::Actions::Runner::Report->new(docker => $docker, quiet => 0);

=head3 API SPECIFICATION

=head4 INPUT

	{
		docker => { type => 'object' },
		quiet  => { type => 'boolean', optional => 1 },
		logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | docker is missing            | Pass the Docker object      |
	| ...Report::new: REASON    |                              |                             |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		docker => { type => 'object' },
		quiet => { type => 'boolean', optional => 1 },
		# Where warnings and errors go; standard error when none is given.
		logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	});

	return bless { %{$params}, logger => $params->{logger} || default_logger(), entries => [], failed => 0, kept_dir => undef, kept_logs => [] }, $class;
}

=head2 record

	$report->record($display_name, $result);

Adds a job's line to the summary.  Returns the object.

=head3 EXAMPLE

	$report->record('lint', 'skipped');

=head3 API SPECIFICATION

=head4 INPUT

	{
		name   => { type => 'string' },
		result => { type => 'string', memberof => [ 'success', 'failure', 'skipped' ] },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

None.

=cut

sub record {
	my ($self, $name, $result) = @_;

	push @{ $self->{entries} }, { name => $name, result => $result };

	return $self;
}

=head2 fail

Marks the workflow as failed.  Returns the object.

=head3 EXAMPLE

	$report->record($name, 'failure')->fail unless $continue_on_error;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

None.

=cut

sub fail {
	my ($self) = @_;

	$self->{failed} = 1;

	return $self;
}

=head2 failed

Says whether the workflow has failed: 1 or 0.

=head3 EXAMPLE

	return $report->failed ? 1 : 0;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub failed {
	my ($self) = @_;

	return $self->{failed} ? 1 : 0;
}

=head2 print_summary

Prints one line per job and whether the workflow succeeded, unless quiet.
Returns the object.

=head3 EXAMPLE

	$report->print_summary;
	#
	# === Workflow summary ===
	#   test (perl=5.40)                                   success
	# Workflow succeeded

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| No jobs were run.         | Every job was skipped or     | Check --job and the jobs'   |
	|                           | none was selected            | conditions                  |
	| Workflow FAILED           | A job failed without         | Read the job's output       |
	|                           | continue-on-error            |                             |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub print_summary {
	my ($self) = @_;

	return $self if $self->{quiet};

	print "\n", $self->i18n('runner.summary.header'), "\n";
	print $self->i18n('runner.summary.none'), "\n" unless @{ $self->{entries} };
	printf "  %-${NAME_WIDTH}s %s\n", redact($self->{docker}, $_->{name}), $_->{result} for @{ $self->{entries} };
	print $self->i18n($self->{failed} ? 'runner.summary.failed' : 'runner.summary.succeeded'), "\n";

	return $self;
}

=head2 report_images

	$report->report_images($records);

Prints one line per image for a preflight that reports as text: what needs
it, and whether it was pulled, present, failed, skipped or deferred.  A
deferred image is named by its expression and followed by the reason it
could not be resolved, which the reader could not see otherwise.  Returns
the object.

=head3 EXAMPLE

	$report->report_images($prepared->{records});
	#   image     perl:5.40 (job 'test'): present

=head3 API SPECIFICATION

=head4 INPUT

	{ records => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

None.

=cut

sub report_images {
	my ($self, $records) = @_;

	for my $record (@{$records}) {
		my ($name) = grep { defined && length } ($record->{image}, $record->{expression});
		my $source = $record->{source};

		print $self->i18n('runner.preflight.image', {
			name => defined $name ? $name : $self->i18n('runner.preflight.unnamed'),
			source => (defined $source && length $source) ? $source : $self->i18n('runner.preflight.workflow'),
			status => $record->{status},
		}), "\n";

		print $self->i18n('runner.preflight.deferred', { error => $record->{error} }), "\n"
			if $record->{status} eq 'deferred' && defined $record->{error} && length $record->{error};
	}

	return $self;
}

=head2 keep_logs

	$report->keep_logs($logs, $root, $run_id);

Copies the logs of a parallel run into a directory of their own under
C<$root>, named after the time and the run, so C<--keep> is not needed to
read them afterwards.  A failure to copy them is a warning, not a failed
run.  Returns the object.

=head3 ARGUMENTS

=over 4

=item * C<$logs> - from L<App::Actions::Runner::Parallel/logs>.  Each
C<file> must be a plain file name (letters, digits, C<_>, C<.> and C<->,
not C<.> or C<..>).

=item * C<$root> - where the run's log directories go.

=item * C<$run_id> - the run's identifier, also a plain name.

=back

=head3 SIDE EFFECTS

Creates a private directory and copies the logs into it; warns on failure.

=head3 EXAMPLE

	$report->keep_logs($parallel->logs, App::Actions::Logs->default_directory, $run_id);

=head3 API SPECIFICATION

=head4 INPUT

	{
		logs   => { type => 'arrayref' },
		root   => { type => 'string', min => 1 },
		run_id => { type => 'string', min => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| action-run: could not keep  | The directory could not be   | Check the log directory's   |
	| the job logs: cannot copy   | made or a log copied         | space and permissions       |
	| 'X' to 'Y': E               |                              |                             |
	+-----------------------------+------------------------------+-----------------------------+
	| action-run: could not keep  | A log's file name, or the    | Use a plain name: letters,  |
	| the job logs: 'X' is not a  | run's identifier, has a      | digits, _ . and -; the      |
	| plain file name             | directory in it, or is . or  | parallel runner always does |
	|                             | ..                           |                             |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub keep_logs {
	my ($self, $logs, $root, $run_id) = @_;

	my @present = grep { defined $_->{path} && -f $_->{path} } @{ $logs || [] };
	return $self unless @present;

	my $directory = File::Spec->catdir($root, POSIX::strftime('%Y%m%d-%H%M%S', localtime) . "-$run_id");

	# The parallel runner makes these names safe, but this method is public:
	# a name such as ../x would copy a log out of the private directory, and
	# so it is refused before anything is made.
	my @bad = grep { !(defined $_ && $_ =~ $PLAIN_NAME) } ($run_id, map { $_->{file} } @present);
	my $problem = @bad
		? $self->i18n('runner.logs.bad_name', { name => defined $bad[0] ? $bad[0] : '' })
		: $self->_copy_logs(\@present, $directory);

	if (defined $problem) {
		$self->{logger}->warn($self->i18n('runner.logs.keep_failed', { error => $problem }));
		return $self;
	}

	$self->{kept_dir} = $directory;
	$self->{kept_logs} = [ grep { $_->{kept} } @present ];

	return $self;
}

# _copy_logs
# Purpose:     Copy the logs into the directory keep_logs chose for the run.
# Entry:       $self - the report; $present - the log entries whose files
#              exist; $directory - the run's log directory (not made yet).
# Exit status: Returns undef when every log was copied, else the reason, in
#              the catalogue's words: the first log could not be copied to a
#              directory that could not be made, or a log could not be copied.
# Side effects: Makes the directory, copies the logs (owner-only modes where
#              the filesystem takes them) and sets each copied entry's kept.
sub _copy_logs {
	my ($self, $present, $directory) = @_;

	# make_path reports a directory it could not make in its own words and
	# with its own line; the reader needs the log that could not be kept.
	make_path($directory, { error => \my $problems });
	if (!-d $directory) {
		my ($reason) = map { values %{$_} } @{ $problems || [] };
		return $self->i18n('runner.logs.copy_failed', {
			from => $present->[0]{path}, to => $directory, error => defined $reason ? $reason : 'unknown error',
		});
	}

	# A filesystem that will not take the mode still holds the logs, so a
	# failed chmod does not cost the copies.
	no autodie qw(chmod);
	chmod $DIRECTORY_MODE, $directory;
	for my $entry (@{$present}) {
		my $target = File::Spec->catfile($directory, $entry->{file});
		copy($entry->{path}, $target)
			or return $self->i18n('runner.logs.copy_failed', { from => $entry->{path}, to => $target, error => "$!" });
		chmod $FILE_MODE, $target;
		$entry->{kept} = $target;
	}

	return;
}

=head2 print_kept_logs

Says where L</keep_logs> put the logs, one line per job, unless quiet or
there were none.  Returns the object.

=head3 EXAMPLE

	$report->print_kept_logs;
	#
	# Job logs kept in /home/me/.cache/action-run/logs/20260101-120000-65f0a1b2c3
	#   test (n=one)  job-1-test_n_one.log

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

None.

=cut

sub print_kept_logs {
	my ($self) = @_;

	my $directory = $self->{kept_dir};
	return $self if $self->{quiet} || !defined $directory;

	print "\n", $self->i18n('runner.logs.kept', { dir => $directory }), "\n";
	print "  $_->{name}  $_->{file}\n" for @{ $self->{kept_logs} };
	STDOUT->flush;

	return $self;
}

=head2 print_kept_resources

	$report->print_kept_resources($containers->remaining, $temp_path);

Lists what a run that keeps its resources left behind: its containers, its
networks and its temporary directory, so they can be inspected and removed.
Prints nothing when there are none.  Returns the object.

=head3 EXAMPLE

	$report->print_kept_resources({ containers => [ 'c1' ], networks => [ 'n1' ] }, '/tmp/x');
	# Kept Docker resources:
	#   container c1
	#   network n1
	#   temporary directory /tmp/x

=head3 API SPECIFICATION

=head4 INPUT

	{
		remaining => { type => 'hashref' },
		temp_path => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Report' }

=head3 MESSAGES

None.

=cut

sub print_kept_resources {
	my ($self, $remaining, $temp_path) = @_;

	my @containers = @{ $remaining->{containers} || [] };
	my @networks = @{ $remaining->{networks} || [] };
	return $self unless @containers || @networks || $temp_path;

	# The list is what the user needs to clean up by hand, so even a quiet
	# run prints it; only the heading is left out.
	print $self->i18n('runner.kept.header'), "\n" unless $self->{quiet};
	print $self->i18n('runner.kept.container', { name => $_ }), "\n" for @containers;
	print $self->i18n('runner.kept.network', { name => $_ }), "\n" for @networks;
	print $self->i18n('runner.kept.temp', { dir => $temp_path }), "\n" if $temp_path;

	return $self;
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

=item * The summary's name column is 50 characters wide; a longer matrix name
pushes its result to the right.

=item * Logs are kept by copying, so a run's logs briefly take twice the
space.  Nothing expires them except C<action-run logs --prune>.

=item * The result words (C<success>, C<failure>, C<skipped>) and image
statuses are left untranslated: they are values a script may match, as in
the JSON documents.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Recording a failure does not fail the workflow.>  Call L</fail>
too; L</print_summary> and L</failed> look only at that flag.  A skipped job
does not fail the workflow.

=item * B<Most methods return the object>, so calls can be chained; but
L</failed> returns 0 or 1.

=item * B<Kept logs are copies.>  They stay until you run C<action-run logs
--prune>.

=item * B<C<quiet> hides the summary and the log list>, but not
L</report_images> output for a text preflight.

=item * B<Result words are not translated.>  C<success>, C<failure> and
C<skipped> stay in English so scripts can match them.

=back

=head1 ENCODING

Job names in the summary are Perl character strings and may contain any
Unicode text, including emoji; the name column is counted in characters, so
wide characters (such as Chinese) can make the columns uneven.  Messages are
in the language of L<App::Actions::I18N>.  Paths of kept logs are shown as
bytes.  Log files are copied byte for byte.

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

	┌─ Report ──────────────────────────────────────────
	│ entries : seq (NAME × RESULT)
	│ failed  : 𝔹
	│ kept    : optional DIRECTORY
	├───────────────────────────────────────────────────
	│ true
	└───────────────────────────────────────────────────

=head2 record

	┌─ Record ──────────────────────────────────────────
	│ ΔReport
	│ name?, result? : seq CHAR
	├───────────────────────────────────────────────────
	│ entries' = entries ⁀ ⟨(name?, result?)⟩
	└───────────────────────────────────────────────────

=head2 fail

	┌─ Fail ────────────────────────────────────────────
	│ ΔReport
	├───────────────────────────────────────────────────
	│ failed' = true
	└───────────────────────────────────────────────────

=head2 failed

	┌─ Failed ──────────────────────────────────────────
	│ ΞReport
	│ f! : 𝔹
	├───────────────────────────────────────────────────
	│ f! = failed
	└───────────────────────────────────────────────────

=head2 print_summary

	┌─ PrintSummary ────────────────────────────────────
	│ ΞReport
	│ out! : seq LINE
	├───────────────────────────────────────────────────
	│ quiet ⇒ out! = ⟨⟩
	│ ¬ quiet ⇒ out! = ⟨header⟩ ⁀ lines(entries) ⁀ ⟨verdict(failed)⟩
	└───────────────────────────────────────────────────

=head2 report_images

	┌─ ReportImages ────────────────────────────────────
	│ ΞReport
	│ records? : seq RECORD
	│ out!     : seq LINE
	├───────────────────────────────────────────────────
	│ #out! = #records? + #{r : ran records? | r.status = deferred ∧ r.error ≠ ⊥}
	└───────────────────────────────────────────────────

=head2 keep_logs

	┌─ KeepLogs ────────────────────────────────────────
	│ ΔReport
	│ logs? : seq LOG
	├───────────────────────────────────────────────────
	│ let present == {l : ran logs? | exists(l.path)}
	│ present = ∅ ⇒ kept' = kept
	│ (∃ l : present • l.file ∉ PLAIN) ∨ run_id? ∉ PLAIN ⇒ kept' = kept ∧ warns
	│ present ≠ ∅ ∧ copied ⇒ kept' = dir ∧ files(dir) = {l.file | l ∈ present}
	└───────────────────────────────────────────────────

=head2 print_kept_logs

	┌─ PrintKeptLogs ───────────────────────────────────
	│ ΞReport
	├───────────────────────────────────────────────────
	│ quiet ∨ kept = ⊥ ⇒ out! = ⟨⟩
	└───────────────────────────────────────────────────

=head2 print_kept_resources

	┌─ PrintKeptResources ──────────────────────────────
	│ ΞReport
	│ r?    : RESOURCES
	│ temp? : optional DIRECTORY
	├───────────────────────────────────────────────────
	│ r?.containers = ⟨⟩ ∧ r?.networks = ⟨⟩ ∧ temp? = ⊥ ⇒ out! = ⟨⟩
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The report collects results while the run goes on, then prints once:

	  new(docker => ..., quiet => ...)
	        |
	        v
	+-------------------+  record($name, 'success' | 'skipped')
	| COLLECTING        |<---------------------------------------+
	| (flag: passing)   |                                        |
	+-------------------+                                        |
	        |     |  record($name, 'failure')->fail               |
	        |     v                                               |
	        |  +-------------------+  more record() calls ------->+
	        |  | COLLECTING        |
	        |  | (flag: failed)    |  failed() = 1 from now on
	        |  +-------------------+
	        |     |
	        +--+--+
	           |  preflight with text output: report_images($records)
	           |  (one line per image: pulled / present / failed /
	           |   skipped / deferred)
	           v
	+-------------------+  parallel run: keep_logs($logs, $root, $run_id)
	| RUN FINISHED      |  copies logs to $root/DATE-TIME-RUNID/
	+-------------------+  (a copy error is only a warning)
	           |
	           v
	+-------------------+  "=== Workflow summary ===", one line per
	| print_summary     |  job, then "Workflow succeeded" or
	+-------------------+  "Workflow FAILED" (unless quiet)
	           |
	           +--> print_kept_logs: where the logs are (unless quiet)
	           +--> print_kept_resources: containers, networks and
	                temporary folder left by a run with keep

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
