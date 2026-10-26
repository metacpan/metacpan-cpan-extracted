package App::Actions::Runner::Images;

use strict;
use warnings;
use autodie qw(:all);

use Readonly;
use Sub::Private ();

use App::Actions::Access;
use App::Actions::Action;
use App::Actions::Cache;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Runner::Support qw(action_inputs chomp_error default_logger local_action_dir trim_error);

our $VERSION = '0.002.1';

# The image a job without a container or a known runner label runs in.
Readonly::Scalar my $DEFAULT_IMAGE => 'ubuntu:latest';

# The image the environment check probes with when no job names one.
Readonly::Scalar my $PROBE_IMAGE => 'alpine:3.20';

# How deep the walk into local composite actions goes.  The run refuses to
# nest them more deeply than this, so the walk stops at the same point
# instead of descending forever through an action that uses itself.
Readonly::Scalar my $MAX_ACTION_DEPTH => 10;

# Windows emulates fork() with threads that share the parent's handles, so
# pulls run one after another there.
Readonly::Scalar my $SERIAL_OS => 'MSWin32';

# The status prepare reports for an image the pull results leave out.
Readonly::Scalar my $NO_STATUS => -1;

=encoding utf-8

=head1 NAME

App::Actions::Runner::Images - work out, pull and track the images a run needs

=head1 SYNOPSIS

	my $images = App::Actions::Runner::Images->new(
		docker => $docker,
		expression => $expression,
		workflow => $workflow,
		project_dir => $project_dir,
		context => sub { $runner->preflight_context(shift) },
	);

	my $prepared = $images->prepare($instances);
	die $images->failure_message($prepared->{failures}[0]) if @{ $prepared->{failures} };

List the images a run will need, without pulling anything:

	for my $entry (@{ $images->required($instances) }) {
		print defined $entry->{image}
			? "$entry->{image}  (for $entry->{source})\n"
			: "deferred: $entry->{expression}\n";
	}

Make sure one image is there, then record what was downloaded:

	$images->ensure('perl:5.40');
	$images->remember($cache_file);    # for "action-run cache"

=head1 DESCRIPTION

B<In short:> this module finds every Docker image a run will need,
downloads the missing ones before any job starts, and remembers what it
downloaded.  It is a part of L<App::Actions::Runner>; you rarely use it on
its own.

Every image a run will use - each job's container, each service, and each
C<docker://> action, including those inside local composite actions - is
named before the first container starts, so that a mistyped image fails the
run at once rather than halfway through a job.  An image whose name depends
on a value that does not exist yet (a step's output) is I<deferred>: the
record says what could not be resolved, and the step that needs it prepares
it when it runs.

The object remembers which images it pulled, so that C<--pull> refreshes each
image once per run, a run told not to keep its images removes what it
fetched, and a run that keeps them records them for C<action-run cache>.

=head1 METHODS

=head2 new

Creates the image preparer for one run.

=head3 ARGUMENTS

=over 4

=item * C<docker> - the L<App::Actions::Docker> object, or one with the same
methods.

=item * C<expression> - the L<App::Actions::Expression> evaluator.

=item * C<workflow> - the L<App::Actions::Workflow>.

=item * C<project_dir> - the project's absolute path, where local actions are read.

=item * C<context> - a code reference that returns the expression context
known before the run for a job instance.

=item * C<image>, C<perl_image> - optional; the default image and the
template for a C<setup-perl> job.

=item * C<dry_run>, C<verbose>, C<quiet>, C<pull>, C<no_pull> - optional
flags.

=item * C<pull_concurrency> - optional; how many pulls run at once (default 4).

=item * C<logger> - optional; a L<Log::Abstraction> object (default:
L<App::Actions::Runner::Support/default_logger>, standard error).  With
C<verbose>, a failure to update the image cache is logged at the C<warn>
level; the run goes on without it.

=back

=head3 RETURNS

An C<App::Actions::Runner::Images> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $images = App::Actions::Runner::Images->new(
		docker => App::Actions::Docker->new,
		expression => App::Actions::Expression->new,
		workflow => App::Actions::Workflow->load('.github/workflows/ci.yml'),
		project_dir => '/home/me/project',
		context => sub { { matrix => $_[0]{matrix} } },
		pull => 1,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		docker           => { type => 'object', can => 'image_exists' },
		expression       => { type => 'object', can => [qw(interpolate interpolate_strict interpolate_known)] },
		workflow         => { type => 'object', can => 'container_image' },
		project_dir      => { type => 'string', min => 1 },
		context          => { type => 'coderef' },
		image            => { type => 'string', optional => 1 },
		perl_image       => { type => 'string', optional => 1 },
		dry_run          => { type => 'boolean', optional => 1 },
		verbose          => { type => 'boolean', optional => 1 },
		quiet            => { type => 'boolean', optional => 1 },
		pull             => { type => 'boolean', optional => 1 },
		no_pull          => { type => 'boolean', optional => 1 },
		pull_concurrency => { type => 'integer', min => 1, optional => 1 },
		logger           => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Images' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | A collaborator is missing or | Pass the documented objects |
	| ...Images::new: REASON    | an option has the wrong type |                             |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		docker => { type => 'object', can => 'image_exists' },
		expression => { type => 'object', can => [qw(interpolate interpolate_strict interpolate_known)] },
		workflow => { type => 'object', can => 'container_image' },
		project_dir => { type => 'string', min => 1 },
		context => { type => 'coderef' },
		image => { type => 'string', optional => 1 },
		perl_image => { type => 'string', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
		verbose => { type => 'boolean', optional => 1 },
		quiet => { type => 'boolean', optional => 1 },
		pull => { type => 'boolean', optional => 1 },
		no_pull => { type => 'boolean', optional => 1 },
		pull_concurrency => { type => 'integer', min => 1, optional => 1 },
		# Where warnings and errors go; standard error when none is given.
		logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	});

	return bless {
		%{$params},
		logger => $params->{logger} || default_logger(),
		pull_concurrency => $params->{pull_concurrency} || 4,
		# Images this run downloaded that were not there before, which a
		# run told not to keep its images removes again.
		pulled => {},
		# Every image this run has pulled, including one that was present
		# and refreshed by --pull: each is downloaded once per run.
		pulled_once => {},
	}, $class;
}

=head2 concurrency

Returns the number of pulls allowed at once: the configured number, but
never more than one on Windows, where the pulls run one after another.  This
is the number handed to the puller, and so the one the preflight reports.

=head3 EXAMPLE

	print $images->concurrency;    # 4

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', min => 1 }

=head3 MESSAGES

None.

=cut

sub concurrency {
	my ($self) = @_;

	return $^O eq $SERIAL_OS ? 1 : $self->{pull_concurrency};
}

=head2 required

	my $entries = $images->required($instances);

Lists every image the jobs will use, in the order the run needs them, each
once.  An entry is C<< { image, source, kind } >>; one the values known
before the run cannot name is C<< { image => undef, expression, source, error } >>.
Jobs whose runner is not Linux are left out, because they will not run.

=head3 EXAMPLE

	for my $entry (@{ $images->required($instances) }) {
		print $entry->{image} // $entry->{expression}, " for $entry->{source}\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{ instances => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None; an expression that fails to resolve is reported in its entry.

=head3 PSEUDOCODE

	for each instance whose runner is Linux:
		build the context known before the run
		for each image expression the job uses:
			try to resolve it strictly
			if it resolved to a name not seen before, add { image, source, kind }
			if it did not resolve, add { expression, source, error } once per source

=cut

sub required {
	my ($self, $instances) = @_;

	# The resolving and the action walk use eval; the caller's $@ is theirs.
	local $@;

	my @entries;
	my %seen;

	for my $instance (@{$instances}) {
		my $runs_on = $self->_linux_runs_on($instance);
		next unless defined $runs_on;

		my $context = $self->{context}->($instance);

		for my $entry (@{ $self->job_expressions($instance, $runs_on, $context) }) {
			my $expression = $entry->{expression};
			next unless defined $expression && length $expression;

			my ($image, $error) = $self->_resolve_strictly($expression, $context);

			# An image named twice is pulled once; an expression that cannot
			# be named yet is reported once for each thing that needs it.
			if (defined $image) {
				next if $seen{"image\0$image"}++;
				push @entries, { image => $image, source => $entry->{source}, kind => $entry->{kind} };
				next;
			}
			next if $seen{"expression\0$expression\0$entry->{source}"}++;
			push @entries, { image => undef, expression => $expression, source => $entry->{source}, error => $error };
		}
	}

	return \@entries;
}

=head2 job_expressions

	my $entries = $images->job_expressions($job, $runs_on, $context);

Lists what one job needs, as expressions rather than resolved names, so that
each caller can resolve them with the values it has: the preflight with what
is known before the run, the job itself with its full context.  An entry is
C<< { expression, source, kind } >>, where kind is C<job>, C<service:ID>, or
absent for an action.

=head3 EXAMPLE

	my $entries = $images->job_expressions($job, 'ubuntu-latest', $context);

=head3 API SPECIFICATION

=head4 INPUT

	{
		job     => { type => 'hashref' },
		runs_on => { type => 'string' },
		context => { type => 'hashref' },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None; a local action that cannot be read contributes no images.

=head3 PSEUDOCODE

	add the job's container image, if the workflow can name one
	add each service's image, sorted by service id
	for each step, add its docker:// image, descending into local composite actions

=cut

sub job_expressions {
	my ($self, $job, $runs_on, $context) = @_;

	local $@;

	my $name = defined $job->{display_name} ? $job->{display_name} : $job->{base_id};
	my @entries;

	my $job_image = $self->_job_image($job, $runs_on);
	push @entries, {
		expression => $job_image,
		source => $self->i18n('runner.source.job', { name => $name }),
		kind => 'job',
	} if defined $job_image && length $job_image;

	# Sorted, so the order of the report is the same on every run.
	for my $id (sort keys %{ $job->{services} || {} }) {
		my $service = $job->{services}{$id};
		$service = { image => $service } unless ref $service eq 'HASH';
		next unless defined $service->{image} && length $service->{image};
		push @entries, {
			expression => $service->{image},
			source => $self->i18n('runner.source.service', { id => $id, name => $name }),
			kind => "service:$id",
		};
	}

	# The walk adds what it finds rather than returning lists, because it
	# recurses through nested actions.
	my $add = sub { push @entries, { expression => $_[0], source => $_[1] } };
	for my $step (@{ $job->{steps} || [] }) {
		$self->_collect_step_images($step, $name, $context, $add, {}, 0, undef);
	}

	return \@entries;
}

=head2 prepare

	my $prepared = $images->prepare($instances, quiet => 1);

Pulls or verifies every image the run will need.  The presence checks run in
turn, because an image that is already there needs no pull; the pulls run
together, up to L</concurrency> at a time.

=head3 ARGUMENTS

=over 4

=item * C<$instances> - the selected job instances.

=item * C<quiet> - optional; print nothing and discard the pull output.

=back

=head3 RETURNS

C<< { records => [...], failures => [...] } >>.  A record is
C<< { image, source, status, error } >> where status is C<present>,
C<pulled>, C<failed> or C<deferred>; a deferred record carries the
C<expression> instead of an image.  The caller decides whether a failure
stops the run or is only reported.

=head3 SIDE EFFECTS

Pulls images, prints progress unless quiet, and remembers what it pulled.

=head3 EXAMPLE

	my $prepared = $images->prepare($instances);
	for my $record (@{ $prepared->{records} }) {
		print "$record->{image}: $record->{status}\n" if defined $record->{image};
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		instances => { type => 'arrayref' },
		quiet     => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message (in a record)       | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Docker image 'X' is not     | --no-pull was given and the  | Pull it, or drop --no-pull  |
	| available locally (--no-pull)| image is absent             |                             |
	| Failed to pull Docker image | The pull exited non-zero     | Check the name, the registry|
	| 'X' (exit N)                | (-1: the Docker object gave  | and the Docker login        |
	|                             | no status for the image)     |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	for each required image:
		an unnamed one becomes a deferred record
		a present one (without --pull) becomes a present record
		with --no-pull, an absent one becomes a failed record
		otherwise it becomes pending
	if anything failed, return now, before downloading anything
	pull the pending images together
	mark each pending record pulled or failed, remembering what arrived
	return the records and the failed ones

=cut

sub prepare {
	my ($self, $instances, @options) = @_;

	local $@;

	my $params = validate_args(__PACKAGE__ . '::prepare', [ instances => $instances, @options ], {
		instances => { type => 'arrayref' },
		quiet => { type => 'boolean', optional => 1 },
	});
	my $quiet = $params->{quiet} ? 1 : 0;

	my @records = map { $self->_initial_record($_, $quiet) } @{ $self->required($params->{instances}) };
	# What this run uses, whether it pulls it or not: a kept image it finds is
	# used again, which the record of kept images is told at the end.
	$self->{used}{ $_->{image} } = 1 for grep { $_->{status} eq 'present' } @records;
	my @pending = grep { $_->{status} eq 'pending' } @records;

	# --no-pull is advice, so it stops the run before any image is
	# downloaded rather than after the ones that could be.
	my @failed = grep { $_->{status} eq 'failed' } @records;
	return { records => \@records, failures => \@failed } if @failed || !@pending;

	unless ($self->{quiet} || $quiet) {
		print $self->i18n('runner.image.pulling', { image => $_->{image} }), "\n" for @pending;
	}

	my $results = $self->_pull_all(\@pending, $quiet);

	# Every image that did arrive is recorded before the failure is
	# reported, so the cleanup at the end of the run removes it.
	for my $record (@pending) {
		# A Docker object of the caller's that says nothing about an image
		# has not shown that it arrived; -1 stands for "no exit status".
		my $rc = $results->{ $record->{image} };
		$rc = $NO_STATUS unless defined $rc;
		if ($rc != 0) {
			$record->{status} = 'failed';
			$record->{error} = $self->i18n('runner.image.pull_failed', { image => $record->{image}, status => $rc })
				unless defined $record->{error} && length $record->{error};
		} else {
			$self->{pulled}{ $record->{image} } = 1 unless $record->{present};
			$self->{pulled_once}{ $record->{image} } = 1;
			$self->{used}{ $record->{image} } = 1;
			$record->{status} = 'pulled';
		}
	}
	delete $_->{present} for @records;

	return { records => \@records, failures => [ grep { $_->{status} eq 'failed' } @records ] };
}

=head2 prepare_job

	my $job_images = $images->prepare_job($job, $context);

The final check of one job's images, made with the values the job itself
has.  An image built from another job's outputs was deferred by the
preflight; here it is resolved and prepared, while the job still has no
network and no containers, so a failure ends the run before the job starts.

=head3 ARGUMENTS

=over 4

=item * C<$job> - the job instance.

=item * C<$context> - its full expression context.

=back

=head3 RETURNS

C<< { image => $job_image, deferred => [ { expression, source, error }, ... ] } >>.
The deferred entries are the images a step decides, which cannot be known
until that step has run.

=head3 SIDE EFFECTS

Pulls images that are not present.

=head3 EXAMPLE

	my $job_images = $images->prepare_job($job, $context);
	print "image: $job_images->{image}\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		job     => { type => 'hashref' },
		context => { type => 'hashref' },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| cannot resolve the image    | A job or service image's     | Fix the expression, or the  |
	| 'X', needed by S: E         | expression has no value      | output it refers to         |
	| cannot prepare the image    | The image could not be       | Check the name and registry |
	| 'X', needed by S: E         | pulled                       |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	for each image expression the job uses:
		resolve it strictly with the job's context
		if it has no value:
			a job or service image is an error the run reports now
			an action image is deferred to its step
		remember the job's own image
		ensure each distinct image is present, failing the run if one cannot be

=cut

sub prepare_job {
	my ($self, $job, $context) = @_;

	local $@;

	my $runs_on = $self->{workflow}->runs_on_text($job->{'runs-on'}, $job->{matrix} || {});

	my ($job_image, @deferred, %seen);
	for my $entry (@{ $self->job_expressions($job, $runs_on, $context) }) {
		my ($image, $error) = $self->_resolve_strictly($entry->{expression}, $context);
		my $kind = defined $entry->{kind} ? $entry->{kind} : '';

		if (!defined $image) {
			# The run starts job and service containers itself, so a name it
			# cannot resolve now is a workflow error it can report before it
			# does anything.  An action's image is its step's business.
			$self->throw('runner.image.unresolved', {
				expression => $entry->{expression}, source => $entry->{source}, error => $error, location => 0,
			}) if $kind eq 'job' || $kind =~ /\Aservice:/;
			push @deferred, { expression => $entry->{expression}, source => $entry->{source}, error => $error };
			next;
		}

		$job_image = $image if $kind eq 'job';

		# Two steps may name the same image; it is prepared once.
		next if $seen{$image}++;
		next if eval { $self->ensure($image); 1 };
		$self->throw('runner.image.unprepared', {
			image => $image, source => $entry->{source}, error => trim_error($@), location => 0,
		});
	}

	return { image => $job_image, deferred => \@deferred };
}

=head2 probe

	my $image = $images->probe($instances);

Chooses the image the environment check probes with: the one the first
runnable job will use, which costs no extra pull and exercises the image the
run needs.  Falls back to the configured default image, then to C<alpine:3.20>.

=head3 EXAMPLE

	my $check = App::Actions::Check->new(image => $images->probe($instances));

=head3 API SPECIFICATION

=head4 INPUT

	{ instances => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=cut

sub probe {
	my ($self, $instances) = @_;

	local $@;

	for my $instance (@{$instances}) {
		my $runs_on = $self->_linux_runs_on($instance);
		next unless defined $runs_on;

		my $image = $self->_job_image($instance, $runs_on);
		next unless defined $image && length $image;

		# container_image does not resolve github.* or env.*; the probe needs
		# a real name, and the context known before the run has those values.
		my $resolved = eval { $self->{expression}->interpolate_known($image, $self->{context}->($instance)) };
		$image = $resolved if defined $resolved && length $resolved;
		return $image unless $image =~ /\{\{/;
	}

	return $self->{image} || $PROBE_IMAGE;
}

=head2 ensure

	$images->ensure('perl:5.40');

Makes sure an image is present, pulling it if it is absent or if C<--pull>
asked for fresh images.  C<--pull> refreshes an image once per run: the
preflight has prepared every image already, so a job, a second matrix job or
a second step that names the same image would otherwise download it again.

=head3 EXAMPLE

	$images->ensure($image);
	$docker->run('--rm', $image);

=head3 API SPECIFICATION

=head4 INPUT

	{ image => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Docker image 'X' is not     | --no-pull was given and the  | Pull it, or drop --no-pull  |
	| available locally (--no-pull)| image is absent             |                             |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub ensure {
	my ($self, $image) = @_;

	return 1 if $self->{dry_run} || $self->{pulled_once}{$image};

	my $exists = $self->{docker}->image_exists($image);
	if ($exists && !$self->{pull}) {
		$self->{used}{$image} = 1;
		return 1;
	}

	# Advice rather than a fault in the code, so it names no source line.
	$self->throw('runner.image.not_local', { image => $image, location => 0 }) if $self->{no_pull};

	print $self->i18n('runner.image.pulling', { image => $image }), "\n" unless $self->{quiet};
	$self->{docker}->pull($image);
	$self->{pulled}{$image} = 1 unless $exists;
	$self->{pulled_once}{$image} = 1;
	$self->{used}{$image} = 1;

	return 1;
}

=head2 note_pulled

	$images->note_pulled(@images);

Records images this run downloaded somewhere else: the probe the environment
check ran, or a step in a job that ran in another process.  A run told not
to keep its images removes them too.  Returns the object.

=head3 EXAMPLE

	$images->note_pulled(@{ $result->{pulled} || [] });

=head3 API SPECIFICATION

=head4 INPUT

	{ images => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Images' }

=head3 MESSAGES

None.

=cut

sub note_pulled {
	my ($self, @images) = @_;

	$self->{pulled}{$_} = 1 for grep { defined && length } @images;

	return $self;
}

=head2 pulled

Returns a sorted array reference of the images this run downloaded that were
not there before.

=head3 EXAMPLE

	$docker->image_remove($_) for @{ $images->pulled };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None.

=cut

sub pulled {
	my ($self) = @_;

	return [ sort keys %{ $self->{pulled} } ];
}

=head2 used

Returns a sorted array reference of the images this run made sure of: the
ones it found already there as well as the ones it pulled.

=head3 EXAMPLE

	my %pulled = map { $_ => 1 } @{ $images->pulled };
	my @reused = grep { !$pulled{$_} } @{ $images->used };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None.

=cut

sub used {
	my ($self) = @_;

	return [ sort keys %{ $self->{used} || {} } ];
}

=head2 note_used

	$images->note_used(@images);

Records images this run used in another process: a job that ran in a child
of the parallel runner.  Returns the object.

=head3 EXAMPLE

	$images->note_used(@{ $result->{used} || [] });

=head3 API SPECIFICATION

=head4 INPUT

	{ images => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Images' }

=head3 MESSAGES

None.

=cut

sub note_used {
	my ($self, @images) = @_;

	$self->{used}{$_} = 1 for grep { defined && length } @images;

	return $self;
}

=head2 remember

	$images->remember($cache_file);

Records the images this run pulled in the cache file that
C<action-run cache> reads, because the images a run keeps are the next run's
cache.  The images it used without pulling them have their last use updated
if the record already holds them (L<App::Actions::Cache/touch>), so a kept
image that every run uses is not taken for an old one by
C<action-run cache --prune --older-than>.  A failure to write the record does not fail a run that otherwise
worked: the images are still on disk, and the next run records them again.

=head3 ARGUMENTS

=over 4

=item * C<$cache_file> - optional; the record to update, as for L<App::Actions::Cache>.

=back

=head3 RETURNS

The object.

=head3 SIDE EFFECTS

Writes the cache record; warns (when verbose) if it cannot.

=head3 EXAMPLE

	$images->remember($ENV{ACTION_RUN_CACHE_FILE});

=head3 API SPECIFICATION

=head4 INPUT

	{ cache_file => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Images' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| action-run: could not update| The cache record could not   | Check the cache directory's |
	| the image cache: E          | be written (verbose only)    | permissions                 |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub remember {
	my ($self, $cache_file) = @_;

	local $@;

	my @images = @{ $self->pulled };
	my %pulled = map { $_ => 1 } @images;
	my @reused = grep { !$pulled{$_} } @{ $self->used };
	return $self if (!@images && !@reused) || $self->{dry_run};

	# A kept image this run used without pulling it has been used again, so
	# its last use moves on; one the record does not hold stays out of it.
	my $recorded = eval {
		my $cache = App::Actions::Cache->new(file => $cache_file);
		$cache->remember(@images) if @images;
		$cache->touch(@reused) if @reused;
		1;
	};
	$self->{logger}->warn($self->i18n('runner.image.cache_failed', { error => chomp_error($@) }))
		if !$recorded && $self->{verbose};

	return $self;
}

=head2 failure_message

	die $images->failure_message($record), "\n";

Returns the sentence a failed image record ends a run with: the image, what
needed it, and what went wrong.

=head3 EXAMPLE

	my $prepared = $images->prepare($instances);
	print $images->failure_message($_), "\n" for @{ $prepared->{failures} };

=head3 API SPECIFICATION

=head4 INPUT

	{ record => { type => 'hashref' } }

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

The text it returns is C<runner.image.unprepared>: "cannot prepare the image
'X', needed by S: E".

=cut

sub failure_message {
	my ($self, $record) = @_;

	return $self->i18n('runner.image.unprepared', {
		image => $record->{image}, source => $record->{source}, error => $record->{error},
	});
}

# _linux_runs_on
# Purpose:     Name a job's runner, if it is one the run can emulate.
# Entry:       $instance - a job instance.
# Exit status: Returns the runs-on text for a Linux runner, undef otherwise.
# Side effects: None.
sub _linux_runs_on {
	my ($self, $instance) = @_;

	my $workflow = $self->{workflow};
	my $runs_on = $workflow->runs_on_text($instance->{'runs-on'}, $instance->{matrix} || {});

	return $workflow->is_linux_runner($runs_on) ? $runs_on : undef;
}

# _job_image
# Purpose:     The expression naming a job's own container image.
# Entry:       $job - the job instance; $runs_on - its runner text.
# Exit status: Returns the expression, or undef when the workflow cannot name one.
# Side effects: None.
sub _job_image {
	my ($self, $job, $runs_on) = @_;

	# container_image croaks for an image it cannot read (an unclosed
	# ${{, say); that is reported when the job runs, so here it just names
	# nothing.  A container mapping without an image is not an error: the
	# job runs in the runner's image.
	return eval {
		$self->{workflow}->container_image($job, $runs_on, $self->{image} || $DEFAULT_IMAGE, $self->{perl_image});
	};
}

# _resolve_strictly
# Purpose:     Resolve an image expression, refusing to guess at unknown values.
# Entry:       $expression - the text; $context - the values known now.
# Exit status: Returns (image, undef) when it names an image, or
#              (undef, reason) when it does not.
# Side effects: None.
sub _resolve_strictly {
	my ($self, $expression, $context) = @_;

	my $image = eval { $self->{expression}->interpolate_strict($expression, $context) };
	my $error = trim_error($@);

	# An empty name is as unusable as an unresolved one, and says so.
	return (defined $image && length $image)
		? ($image, undef)
		: (undef, (defined $error && length $error) ? $error : $self->i18n('runner.image.empty'));
}

# _initial_record
# Purpose:     Turn one required image into a record before anything is pulled.
# Entry:       $entry - from required(); $quiet - whether the caller wants silence.
# Exit status: Returns a record whose status is deferred, present, failed or pending.
# Side effects: Asks the daemon whether the image is present; prints it when verbose.
sub _initial_record {
	my ($self, $entry, $quiet) = @_;

	my ($image, $source) = @{$entry}{qw(image source)};

	# No job has run yet, so a value that comes from a step or another job's
	# output is not known.  Rather than guess at a name, the record says
	# what could not be resolved; the job checks it again before it starts.
	return { image => undef, expression => $entry->{expression}, source => $source, status => 'deferred', error => $entry->{error} }
		unless defined $image;

	print $self->i18n('runner.image.checking', { image => $image, source => $source }), "\n"
		if $self->{verbose} && !$self->{quiet} && !$quiet;

	my $present = $self->{dry_run} ? 1 : $self->{docker}->image_exists($image);
	my %record = (image => $image, source => $source);

	if ($present && !$self->{pull}) {
		$record{status} = 'present';
	} elsif ($self->{no_pull}) {
		@record{qw(status error)} = ('failed', $self->i18n('runner.image.not_local', { image => $image }));
	} else {
		@record{qw(status present)} = ('pending', $present);
	}

	return \%record;
}

# _pull_all
# Purpose:     Pull the pending images, together where the Docker object can.
# Entry:       $pending - records; $quiet - discard the pull output.
# Exit status: Returns a hash reference of image to exit status.
# Side effects: Pulls images; sets a record's error when a single pull dies.
sub _pull_all {
	my ($self, $pending, $quiet) = @_;

	my $docker = $self->{docker};

	# A caller-supplied Docker object need only offer the single-image calls.
	return $docker->pull_many(
		[ map { $_->{image} } @{$pending} ],
		concurrency => $self->concurrency,
		($quiet ? (quiet => 1) : ()),
	) if $docker->can('pull_many');

	my %results;
	for my $record (@{$pending}) {
		my $pulled = eval { $docker->pull($record->{image}); 1 };
		$results{ $record->{image} } = $pulled ? 0 : 1;
		my $error = $pulled ? undef : trim_error($@);
		$record->{error} = $error if defined $error && length $error;
	}

	return \%results;
}

# _collect_step_images
# Purpose:     Find the image a step's `uses` needs, descending into local
#              composite actions so their images are known before any
#              container exists.
# Entry:       $step; $job_name - for the source; $context - for resolving;
#              $add - code ref taking (expression, source); $ancestors - the
#              actions already on this path; $depth; $via - the enclosing
#              action's reference, or undef at the top.
# Exit status: Returns nothing.
# Side effects: Calls $add; reads action metadata from the project.
sub _collect_step_images {
	my ($self, $step, $job_name, $context, $add, $ancestors, $depth, $via) = @_;

	my $uses = $step->{uses};
	return unless defined $uses;

	# What this context can resolve is resolved now - usually a composite
	# action's inputs.  An expression that still needs a value only the job
	# will have is left as written (interpolate would make it an empty
	# string), so the caller recognises it as deferred rather than taking
	# "alpine:" for an image name.
	my $resolve = sub {
		my ($text) = @_;
		my $value = eval { $self->{expression}->interpolate_known($text, $context) };
		return (defined $value && length $value) ? $value : $text;
	};

	my $action = $uses =~ m{\Adocker://}s ? $uses : eval { $self->{expression}->interpolate_known($uses, $context) };
	return unless defined $action && length $action;

	if ($action =~ m{\A\.\.?/}) {
		$self->_collect_action_images($action, $step, $job_name, $context, $add, $ancestors, $depth);
	} elsif ($action =~ m{\Adocker://(.*)\z}s) {
		my $source = defined $via
			? $self->i18n('runner.source.nested_action', { uses => $uses, via => $via, name => $job_name })
			: $self->i18n('runner.source.action', { uses => $uses, name => $job_name });
		$add->($resolve->($1), $source);
	}

	return;
}

# _collect_action_images
# Purpose:     Descend into a local composite action with its inputs resolved
#              as far as the caller's context allows.
# Entry:       As _collect_step_images, with $action the resolved reference.
# Exit status: Returns nothing.
# Side effects: Calls $add for each image found; reads action metadata.
sub _collect_action_images {
	my ($self, $action, $step, $job_name, $context, $add, $ancestors, $depth) = @_;

	return if $depth >= $MAX_ACTION_DEPTH;

	# An action may use itself, directly or through another one; and one that
	# cannot be read is the run's error to report, not the preflight's.
	my $location = eval { local_action_dir($self->{project_dir}, $action) };
	return if !$location || $ancestors->{ $location->{relative} };

	my ($relative, $host_dir) = @{$location}{qw(relative dir)};
	my $loaded = -d $host_dir ? eval { App::Actions::Action->load_from_dir($host_dir) } : undef;
	return unless $loaded && $loaded->is_composite;

	# Inputs usually decide the image ("uses: docker://${{ inputs.image }}").
	# A missing required input only leaves the image unresolved.
	my $inputs = eval { action_inputs($self->{expression}, $loaded, $step, $action, $context, undef) };
	my %nested = (
		%{$context},
		inputs => ref $inputs eq 'HASH' ? $inputs : {},
		steps => {},
		github => { %{ $context->{github} || {} }, action_path => "/github/workspace/$relative", action => $action },
	);

	my %deeper = (%{$ancestors}, $relative => 1);
	for my $nested_step (@{ $loaded->steps || [] }) {
		$self->_collect_step_images($nested_step, $job_name, \%nested, $add, \%deeper, $depth + 1, $action);
	}

	return;
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

=item * An image named by a step's output cannot be known until the step has
run, so it is pulled by that step, inside the job, after its containers have
started.  A bad name there fails the step rather than the preflight.

=item * Images are compared by name.  C<perl:5.40> and
C<docker.io/library/perl:5.40> are the same image to Docker but two entries
here, so the second is checked (and, with C<--pull>, pulled) again.

=item * The walk into local composite actions reads each action's metadata
again for every job that uses it.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Some images cannot be known in advance.>  An image whose name uses
a value that a step produces is I<deferred>: L</required> and L</prepare>
list its expression instead of a name, and L</prepare_job> pulls it when
the job starts.

=item * B<Image names are compared as text.>  C<perl:5.40> and
C<docker.io/library/perl:5.40> count as two images.

=item * B<On Windows, pulls run one at a time>, whatever
C<pull_concurrency> says.  L</concurrency> tells you the real number.

=item * B<With C<pull>, each image is pulled once per run>, not once per
job.  Call L</ensure> freely.

=item * B<Images pulled or used in another process are not known> until you
call L</note_pulled> and L</note_used> with them (the parallel runner does
this for its children).

=item * B<L</remember> never fails the run.>  If the cache file cannot be
written, the run goes on; with C<verbose> a warning is logged.

=back

=head1 ENCODING

Image names are ASCII, as Docker requires; a name built from workflow
values containing other characters is refused by Docker when it is pulled.
Expressions and source descriptions are Perl character strings and may
contain any Unicode text.  The cache file is written as UTF-8 JSON (see
L<App::Actions::Cache>).

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

	┌─ Images ──────────────────────────────────────────
	│ pulled     : ℙ IMAGE     -- images this run downloaded that were absent
	│ pulledOnce : ℙ IMAGE     -- images this run has pulled at all
	├───────────────────────────────────────────────────
	│ pulled ⊆ pulledOnce
	└───────────────────────────────────────────────────

	┌─ NewImages ───────────────────────────────────────
	│ Images'
	├───────────────────────────────────────────────────
	│ pulled' = ∅ ∧ pulledOnce' = ∅
	└───────────────────────────────────────────────────

=head2 concurrency

	┌─ Concurrency ─────────────────────────────────────
	│ ΞImages
	│ n! : ℕ₁
	├───────────────────────────────────────────────────
	│ os = MSWin32 ⇒ n! = 1
	│ os ≠ MSWin32 ⇒ n! = pullConcurrency
	└───────────────────────────────────────────────────

=head2 required

	┌─ Required ────────────────────────────────────────
	│ ΞImages
	│ instances? : seq JOB
	│ entries!   : seq ENTRY
	├───────────────────────────────────────────────────
	│ ∀ e : ran entries! • e.image ≠ ⊥ ∨ e.expression ≠ ⊥
	│ ∀ i, j : dom entries! | i ≠ j ∧ entries!(i).image ≠ ⊥ •
	│     entries!(i).image ≠ entries!(j).image
	└───────────────────────────────────────────────────

=head2 job_expressions

	┌─ JobExpressions ──────────────────────────────────
	│ ΞImages
	│ job? : JOB
	│ e!   : seq ENTRY
	├───────────────────────────────────────────────────
	│ e! = jobImage(job?) ⁀ serviceImages(job?) ⁀ ⁀/ (map actionImages job?.steps)
	└───────────────────────────────────────────────────

=head2 prepare

	┌─ Prepare ─────────────────────────────────────────
	│ ΔImages
	│ instances? : seq JOB
	│ records!   : seq RECORD
	│ failures!  : seq RECORD
	├───────────────────────────────────────────────────
	│ failures! = records! ↾ {r | r.status = failed}
	│ pulled' = pulled ∪ {r.image | r ∈ ran records! ∧ r.status = pulled ∧ ¬ present(r.image)}
	│ pulledOnce' = pulledOnce ∪ {r.image | r ∈ ran records! ∧ r.status = pulled}
	└───────────────────────────────────────────────────

=head2 prepare_job

	┌─ PrepareJob ──────────────────────────────────────
	│ ΔImages
	│ job?      : JOB
	│ image!    : optional IMAGE
	│ deferred! : seq ENTRY
	├───────────────────────────────────────────────────
	│ ∀ e : jobExpressions(job?) | e.kind ∈ {job} ∪ services •
	│     resolves(e) ∨ raises Unresolved
	│ image! = resolve(e) where e.kind = job
	│ ran deferred! = {e : jobExpressions(job?) | ¬ resolves(e) ∧ e.kind = ⊥}
	└───────────────────────────────────────────────────

=head2 probe

	┌─ Probe ───────────────────────────────────────────
	│ ΞImages
	│ instances? : seq JOB
	│ image!     : IMAGE
	├───────────────────────────────────────────────────
	│ (∃ i : ran instances? • linux(i) ∧ known(jobImage(i)))
	│     ⇒ image! = jobImage(first such i)
	│ otherwise image! = (if defaultImage ≠ ⊥ then defaultImage else alpine:3.20)
	└───────────────────────────────────────────────────

=head2 ensure

	┌─ Ensure ──────────────────────────────────────────
	│ ΔImages
	│ image? : IMAGE
	├───────────────────────────────────────────────────
	│ dryRun ∨ image? ∈ pulledOnce ⇒ θImages' = θImages
	│ present(image?) ∧ ¬ pull ⇒ θImages' = θImages
	│ (¬ present(image?) ∨ pull) ∧ noPull ⇒ raises NotLocal
	│ (¬ present(image?) ∨ pull) ∧ ¬ noPull ⇒
	│     pulledOnce' = pulledOnce ∪ {image?} ∧
	│     pulled' = pulled ∪ (if present(image?) then ∅ else {image?})
	└───────────────────────────────────────────────────

=head2 note_pulled

	┌─ NotePulled ──────────────────────────────────────
	│ ΔImages
	│ images? : ℙ IMAGE
	├───────────────────────────────────────────────────
	│ pulled' = pulled ∪ images?
	└───────────────────────────────────────────────────

=head2 pulled

	┌─ Pulled ──────────────────────────────────────────
	│ ΞImages
	│ images! : seq IMAGE
	├───────────────────────────────────────────────────
	│ ran images! = pulled ∧ images! is sorted
	└───────────────────────────────────────────────────

=head2 used

	┌─ Used ────────────────────────────────────────────
	│ ΞImages
	│ images! : seq IMAGE
	├───────────────────────────────────────────────────
	│ ran images! = used ∧ images! is sorted
	└───────────────────────────────────────────────────

=head2 note_used

	┌─ NoteUsed ────────────────────────────────────────
	│ ΔImages
	│ images? : ℙ IMAGE
	├───────────────────────────────────────────────────
	│ used' = used ∪ images?
	└───────────────────────────────────────────────────

=head2 remember

	┌─ Remember ────────────────────────────────────────
	│ ΞImages
	│ ΔCacheFile
	├───────────────────────────────────────────────────
	│ reused = used \ pulled
	│ ¬ dryRun ⇒ cache' = touch(cache ∪ pulled, reused ∩ dom cache)
	│ dryRun ∨ (pulled = ∅ ∧ reused = ∅) ⇒ cache' = cache
	└───────────────────────────────────────────────────

=head2 failure_message

	┌─ FailureMessage ──────────────────────────────────
	│ record? : RECORD
	│ text!   : seq CHAR
	├───────────────────────────────────────────────────
	│ text! = render(unprepared, record?.image, record?.source, record?.error)
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object remembers which images it has made sure of, and which it
downloaded.  One image goes through these states during a run:

	  required($instances) / job_expressions(...)
	        |   the image is found in a job, service or docker:// step
	        v   (also inside local composite actions)
	+-------------------+  name uses a step's output
	| NAMED             |--------------------------------+
	+-------------------+                                |
	        |                                            v
	        | prepare($instances)                 +---------------+
	        v                                     |   DEFERRED    |
	+-------------------+                         +---------------+
	| CHECKING          |  image_exists?                 |
	+-------------------+                                | prepare_job($job, $context)
	   |            |                                    | when the job starts:
	   | present,   | missing, or --pull                 | resolve with the job's
	   | no --pull  v                                    | values, then CHECKING
	   |    +-------------------+                        |
	   |    | PULLING           |  up to concurrency()   |
	   |    | (pull_many)       |  at once               |
	   |    +-------------------+                        |
	   |       |            |                            |
	   |       | ok         | failed                     |
	   |       v            v                            |
	   |   +--------+   +-------------------------+      |
	   |   | PULLED |   | FAILED: run stops with  |      |
	   |   +--------+   | failure_message(record) |      |
	   |       |        +-------------------------+      |
	   v       v                                         |
	+-------------------+ <------------------------------+
	| READY             |  ensure($image) later: no second pull,
	+-------------------+  even with --pull
	        |
	        | end of run
	        v
	  keep_images? --no--> images in pulled() are removed
	        | yes
	        v
	  remember($cache_file): pulled() recorded for "action-run cache"
	                          and used() \ pulled() touched if recorded

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
