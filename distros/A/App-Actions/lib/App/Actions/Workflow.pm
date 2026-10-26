package App::Actions::Workflow;

use strict;
use warnings;
use utf8;
use autodie qw(:all);

use File::Basename qw(basename);
use Readonly;

use App::Actions::Expression;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Util qw(load_yaml_mapping mapping normalize_step stringify);

use Sub::Private ();

use App::Actions::Access;

our $VERSION = '0.002.1';

# An error in a workflow is reported where the workflow was asked for, which
# is usually the App::Actions or Runner call the user made, not a line here.
our @CARP_NOT = qw(App::Actions App::Actions::Runner);

# The image used when a job names none and runs on ubuntu-latest.
Readonly::Scalar my $UBUNTU_LATEST_IMAGE => 'ubuntu:latest';

# The image template used when a setup-perl step chooses the version and the
# caller gives no template of its own.  %s is the version.
Readonly::Scalar my $DEFAULT_PERL_TEMPLATE => 'perl:%s';

# The tag a template is completed with when no Perl version is known, and
# the versions that mean "the newest" to setup-perl.
Readonly::Scalar my $LATEST_TAG => 'latest';
Readonly::Hash my %LATEST_ALIASES => (dev => 1, latest => 1);

# Runner labels that are not Linux.  A job on one of these cannot be run in
# a Linux container, so it is skipped rather than run in the wrong place.
Readonly::Scalar my $NON_LINUX_RUNNER => qr/\b(?:windows|macos|darwin)\b/i;

# The setup-perl actions whose perl-version input chooses a Perl image.
Readonly::Scalar my $SETUP_PERL_ACTION => qr{^(?:shogo82148/actions-setup-perl|perl-actions/setup-perl)@}i;

# The matrix keys that are instructions rather than dimensions.
Readonly::Hash my %MATRIX_DIRECTIVES => (include => 1, exclude => 1);

=encoding utf-8

=head1 NAME

App::Actions::Workflow - parse and expand a GitHub Actions workflow

=head1 SYNOPSIS

List every job a workflow will run, after the matrix is expanded:

	use App::Actions::Workflow;

	my $workflow = App::Actions::Workflow->load('.github/workflows/perl-ci.yml');
	for my $job (@{ $workflow->expand_jobs }) {
		print $job->{display_name}, "\n";    # test (perl=5.38), test (perl=5.40), ...
	}

Find one job and see which image it would run in:

	my $job = $workflow->job_by_id('test');
	my ($first) = grep { $_->{base_id} eq 'test' } @{ $workflow->expand_jobs };
	my $runs_on = App::Actions::Workflow->runs_on_text($first->{'runs-on'});
	my $image = App::Actions::Workflow->container_image($first, $runs_on, 'ubuntu:latest');

Skip jobs that need macOS or Windows:

	for my $job (@{ $workflow->expand_jobs }) {
		my $runs_on = App::Actions::Workflow->runs_on_text($job->{'runs-on'});
		next unless App::Actions::Workflow->is_linux_runner($runs_on);
		...
	}

Turn a Perl version into an image name:

	App::Actions::Workflow->perl_image_for_version('v5.40');    # perl:5.40

=head1 DESCRIPTION

A GitHub Actions I<workflow> is a YAML file, usually in
F<.github/workflows/>.  It lists I<jobs>; each job has I<steps>.  A job can
have a I<matrix>: a list of values (for example several Perl versions), and
GitHub runs one copy of the job for each combination of values.

This module:

=over 4

=item * reads a workflow file and checks its shape (L</load>);

=item * expands each job's matrix into concrete jobs, applying C<include>
and C<exclude> as GitHub does, and gives each one a display name such as
C<test (perl=5.40)> (L</expand_jobs>);

=item * decides which Docker image each job runs in: the job's own
C<container>, else a Perl image for a setup-perl step, else an Ubuntu image
that matches C<runs-on> (L</container_image>).

=back

It does not run anything.  L<App::Actions::Runner> does that.

Every error is an L<App::Actions::Error> with a stable code (such as
C<workflow.no_jobs>) and a message in the language C<ACTION_RUN_LANG>
chooses (English by default).  The error points at the line of I<your> code
that called this module.

=head1 METHODS

=head2 load

Parses a workflow file.

=head3 ARGUMENTS

=over 4

=item * C<$file> - the path of the workflow.

=back

=head3 RETURNS

An C<App::Actions::Workflow> object.

=head3 SIDE EFFECTS

Reads the file.

=head3 EXAMPLE

	my $workflow = App::Actions::Workflow->load('.github/workflows/ci.yml');
	printf "%s has %d jobs\n", $workflow->name, scalar @{ $workflow->jobs };

=head3 API SPECIFICATION

=head4 INPUT

	{ file => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Workflow' }

=head3 MESSAGES

	+-----------------------------------+------------------------------+-------------------------------+
	| Message                           | Meaning                      | Resolution                    |
	+-----------------------------------+------------------------------+-------------------------------+
	| No workflow file given            | The path was undef or empty  | Pass a path                   |
	| Workflow file 'F' does not exist  | No file at the path          | Check the path                |
	| Unable to parse workflow 'F': E   | The YAML is malformed        | Fix the YAML                  |
	| Workflow 'F' is empty             | No document in the file      | Add the workflow              |
	| Workflow 'F' must contain a YAML  | The top level is not a       | Make it a mapping             |
	| mapping                           | mapping                      |                               |
	| Workflow 'F' has no 'jobs'        | jobs is missing or not a     | Add a jobs: mapping           |
	| mapping                           | mapping                      |                               |
	| Job 'J' must be a mapping         | A job is a scalar or a list  | Indent the job's keys         |
	| Job 'J' has no 'steps' list       | steps is missing or not a    | Add a steps: list             |
	|                                   | list                         |                               |
	| Job 'J' container must be a       | container is a list          | Give an image name or a       |
	| mapping or a string               |                              | mapping with image:           |
	| Job 'J' services must be a        | services is not a mapping    | Name each service             |
	| mapping                           |                              |                               |
	| PLACE must be a mapping           | env, defaults or strategy is | Indent it as KEY: VALUE       |
	|                                   | not a mapping                |                               |
	| PLACE run must be a mapping       | defaults.run is not a        | Indent it as KEY: VALUE       |
	|                                   | mapping                      |                               |
	+-----------------------------------+------------------------------+-------------------------------+

The step messages of L<App::Actions::Util/normalize_step> apply to every
step.

=head3 PSEUDOCODE

	read the file as a YAML mapping
	refuse a document whose jobs is not a mapping
	for each job, in file order:
		normalise it (needs, container, services, env, defaults, strategy, steps)
	return the workflow with its name, env, defaults and jobs

=cut

sub load {
	my $class = shift;

	# The path is checked by load_yaml_mapping, whose messages say which
	# kind of file was missing; only the call's shape is checked here.
	my $params = validate_args(__PACKAGE__ . '::load', [ { file => $_[0] } ], {
		file => { type => 'string', optional => 1 },
	});
	my $file = $params->{file};

	my $data = load_yaml_mapping($file, 'workflow');
	$class->throw('workflow.no_jobs', { file => $file }) unless ref $data->{jobs} eq 'HASH';

	my @jobs = map { $class->_normalize_job($_, $data->{jobs}{$_}) } keys %{ $data->{jobs} };

	return bless {
		file => $file,
		name => defined $data->{name} ? "$data->{name}" : basename($file),
		env => mapping($data->{env}, ['where.workflow_env']),
		defaults => _defaults($data->{defaults}, ['where.workflow_defaults']),
		jobs => \@jobs,
		raw => $data,
	}, $class;
}

=head2 file, name, env, defaults, jobs, raw

	my $path = $workflow->file;
	my $name = $workflow->name;        # the name: key, or the file's base name
	my $env  = $workflow->env;         # workflow-level env, a hash reference
	my $defs = $workflow->defaults;    # workflow-level defaults, a hash reference
	my $jobs = $workflow->jobs;        # array reference, in file order
	my $raw  = $workflow->raw;         # the parsed document, untouched

Read-only accessors.  The references they return are the object's own, so
a caller that wants to change one should copy it first.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	file, name:          { type => 'string' }
	env, defaults, raw:  { type => 'hashref' }
	jobs:                { type => 'arrayref' }

=head3 MESSAGES

None.

=head3 EXAMPLE

	print $_->{id}, "\n" for @{ $workflow->jobs };

=cut

sub file     { return $_[0]->{file} }
sub name     { return $_[0]->{name} }
sub env      { return $_[0]->{env} }
sub defaults { return $_[0]->{defaults} }
sub jobs     { return $_[0]->{jobs} }
sub raw      { return $_[0]->{raw} }

=head2 job_by_id

Finds a job by its key in the C<jobs> mapping.

=head3 ARGUMENTS

=over 4

=item * C<$id> - the job's key.

=back

=head3 RETURNS

The job's hash reference, or C<undef> (also in list context) when there is
no such job.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $test = $workflow->job_by_id('test') or die "no test job\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ id => { type => 'string' } }

=head4 OUTPUT

	{ type => 'hashref', optional => 1 }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to ... | The id is missing or a        | Pass the job's key             |
	|                          | reference                     |                                |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub job_by_id {
	my $self = shift;

	my $params = validate_args(__PACKAGE__ . '::job_by_id', [ { id => $_[0] } ], {
		id => { type => 'string' },
	});

	# A scalar assignment from grep would be a count; the list assignment
	# takes the first match, or undef when there is none.
	my ($job) = grep { $_->{id} eq $params->{id} } @{ $self->{jobs} };

	return $job;
}

=head2 expand_jobs

Expands every job's matrix into concrete job instances.

=head3 ARGUMENTS

None.

=head3 RETURNS

An array reference with one hash reference per matrix combination, in job
order.  Each instance is a copy of its job with C<base_id>, C<matrix>,
C<matrix_index>, C<matrix_total>, C<display_name> and C<setup_perl_version>
added.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	# jobs: { test: { strategy: { matrix: { perl: ['5.38', '5.40'] } }, ... } }
	for my $job (@{ $workflow->expand_jobs }) {
		print "$job->{display_name}\n";    # test (perl=5.38), test (perl=5.40)
	}

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	+--------------------------------+-------------------------------+--------------------------------+
	| Message                        | Meaning                       | Resolution                     |
	+--------------------------------+-------------------------------+--------------------------------+
	| strategy.matrix must be a      | matrix is a list or a string  | Make it a mapping of keys to   |
	| mapping                        |                               | lists                          |
	| Matrix key 'K' must be a list  | The key's list is empty       | Give it a value, or remove it  |
	| with at least one value        |                               |                                |
	| Each matrix exclude entry must | An exclude item is not a      | Write each as KEY: VALUE       |
	| be a mapping                   | mapping                       |                                |
	| Each matrix include entry must | An include item is not a      | Write each as KEY: VALUE       |
	| be a mapping                   | mapping                       |                                |
	+--------------------------------+-------------------------------+--------------------------------+

=head3 PSEUDOCODE

	for each job:
		expand its matrix into combinations
		for each combination, at index i of n:
			copy the job, adding base_id, matrix, i, n,
			the display name and any setup-perl version
	return the instances

=cut

sub expand_jobs {
	my ($self) = @_;

	my $expression = $self->_expression;
	my @instances;

	for my $job (@{ $self->{jobs} }) {
		my $combinations = _expand_matrix($job->{strategy}{matrix});

		# Index and total are kept so a report can say "2 of 6" and a
		# resource name stays unique within the job.
		for my $index (0 .. $#{$combinations}) {
			my $values = $combinations->[$index];
			# Each instance is a copy of its own, so a change to one instance's
			# steps or environment reaches neither the job nor its siblings.
			push @instances, {
				%{ _copy($job) },
				base_id => $job->{id},
				matrix => $values,
				matrix_index => $index,
				matrix_total => scalar @{$combinations},
				display_name => _job_display_name($job, $values, $expression),
				setup_perl_version => _find_setup_perl_version($job, $values, $expression),
			};
		}
	}

	return \@instances;
}

=head2 runs_on_text

Renders a job's C<runs-on> as one string, with matrix values substituted.

=head3 ARGUMENTS

=over 4

=item * C<$runs_on> - the C<runs-on> value: a string, a list, or undef.

=item * C<$matrix> - optional; the job's matrix values.

=back

=head3 RETURNS

The labels joined by spaces, as a string.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	$workflow->runs_on_text('${{ matrix.os }}', { os => 'ubuntu-24.04' });    # ubuntu-24.04
	$workflow->runs_on_text([ 'self-hosted', 'linux' ]);                      # self-hosted linux

=head3 API SPECIFICATION

=head4 INPUT

	{
		runs_on => { type => 'string|arrayref', optional => 1 },
		matrix  => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	+--------------------------------+-------------------------------+--------------------------------+
	| Message                        | Meaning                       | Resolution                     |
	+--------------------------------+-------------------------------+--------------------------------+
	| 'runs-on' must be a string or  | runs-on is a mapping (such as | Use a label or a list of       |
	| a list                         | a runner group)               | labels                         |
	+--------------------------------+-------------------------------+--------------------------------+

=cut

sub runs_on_text {
	my $self = shift;

	# A lone list of labels must not be read by Params::Get as its own
	# argument list, so the arguments are named before they are checked.
	# runs-on is checked by hand below, because its one wrong shape (a
	# runner group) deserves a sentence of its own.
	my $params = validate_args(__PACKAGE__ . '::runs_on_text', [ { runs_on => $_[0], matrix => $_[1] } ], {
		runs_on => { type => 'string|arrayref|hashref', optional => 1 },
		matrix => { type => 'hashref', optional => 1 },
	});
	my ($runs_on, $matrix) = @{$params}{qw(runs_on matrix)};

	# A mapping is a runner group ({ group: ..., labels: ... }), which a
	# local run has no way to honour; say so rather than print HASH(0x...).
	$self->throw('workflow.runs_on_invalid') if ref $runs_on && ref $runs_on ne 'ARRAY';

	my $text = ref $runs_on eq 'ARRAY' ? join(' ', map { stringify($_) } @{$runs_on}) : stringify($runs_on);

	return $self->_expression->interpolate($text, { matrix => $matrix || {} });
}

=head2 is_linux_runner

Says whether a C<runs-on> text names a runner a Linux container can stand
in for.

=head3 ARGUMENTS

=over 4

=item * C<$runs_on> - the text from L</runs_on_text>.

=back

=head3 RETURNS

1 when no label names Windows or macOS, otherwise 0.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	$workflow->is_linux_runner('ubuntu-latest');        # 1
	$workflow->is_linux_runner('self-hosted linux');    # 1
	$workflow->is_linux_runner('windows-2022');         # 0

=head3 API SPECIFICATION

=head4 INPUT

	{ runs_on => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=cut

sub is_linux_runner {
	shift;    # the invocant: a workflow or the class, neither of which is needed

	my $runs_on = validate_args(__PACKAGE__ . '::is_linux_runner', [ { runs_on => $_[0] } ], {
		runs_on => { type => 'string', optional => 1 },
	})->{runs_on};

	# An unknown runner is assumed to be Linux: self-hosted labels are free
	# text, and only Windows and macOS are known not to be.
	return (defined $runs_on && $runs_on =~ $NON_LINUX_RUNNER) ? 0 : 1;
}

=head2 default_image_for_runner

Chooses the image a job with no container runs in, from its C<runs-on>.

=head3 ARGUMENTS

=over 4

=item * C<$runs_on> - the text from L</runs_on_text>.

=item * C<$fallback> - the image to use when the runner names no Ubuntu.

=back

=head3 RETURNS

C<ubuntu:VERSION> for C<ubuntu-VERSION>, C<ubuntu:latest> for
C<ubuntu-latest>, otherwise C<$fallback>.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	$workflow->default_image_for_runner('ubuntu-22.04', 'perl:5.40');    # ubuntu:22.04
	$workflow->default_image_for_runner('self-hosted', 'perl:5.40');     # perl:5.40

=head3 API SPECIFICATION

=head4 INPUT

	{
		runs_on  => { type => 'string', optional => 1 },
		fallback => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=cut

sub default_image_for_runner {
	shift;    # the invocant: a workflow or the class, neither of which is needed

	my $params = validate_args(__PACKAGE__ . '::default_image_for_runner', [ { runs_on => $_[0], fallback => $_[1] } ], {
		runs_on => { type => 'string', optional => 1 },
		fallback => { type => 'string', optional => 1 },
	});
	my ($runs_on, $fallback) = @{$params}{qw(runs_on fallback)};

	# The runner's Ubuntu release is the closest image to what the job would
	# have had on GitHub; anything else is the caller's choice.
	$runs_on = '' unless defined $runs_on;
	my $image = $runs_on =~ /\bubuntu-(\d+\.\d+)\b/i ? "ubuntu:$1"
		: $runs_on =~ /\bubuntu-latest\b/i ? $UBUNTU_LATEST_IMAGE
		: $fallback;

	return $image;
}

=head2 perl_image_for_version

Turns a setup-perl version into an image name.

=head3 ARGUMENTS

=over 4

=item * C<$version> - the Perl version, such as C<5.38> or C<v5.40>; undef,
empty, C<dev> and C<latest> all mean the newest.

=item * C<$template> - optional; the image name with C<%s> where the
version goes, or a repository name to which C<:VERSION> is appended.
Defaults to C<perl:%s>.

=back

=head3 RETURNS

The image name.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	$workflow->perl_image_for_version('5.38');                          # perl:5.38
	$workflow->perl_image_for_version('v5.40', 'ghcr.io/me/perl:%s');   # ghcr.io/me/perl:5.40
	$workflow->perl_image_for_version('dev', 'perl');                   # perl:latest

=head3 API SPECIFICATION

=head4 INPUT

	{
		version  => { type => 'string', optional => 1 },
		template => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=cut

sub perl_image_for_version {
	shift;    # the invocant: a workflow or the class, neither of which is needed

	my $params = validate_args(__PACKAGE__ . '::perl_image_for_version', [ { version => $_[0], template => $_[1] } ], {
		version => { type => 'string', optional => 1 },
		template => { type => 'string', optional => 1 },
	});
	my ($version, $template) = @{$params}{qw(version template)};

	$template = $DEFAULT_PERL_TEMPLATE unless defined $template && length $template;
	$version = $LATEST_TAG unless defined $version && length $version;
	$version =~ s/^v//i;
	$version = $LATEST_TAG if $LATEST_ALIASES{ lc $version };

	# A substitution rather than sprintf: a registry path may contain a
	# literal % that sprintf would read as a conversion, and a template that
	# names the version twice should get it twice.
	(my $image = $template) =~ s/%s/$version/g;

	return $image eq $template ? "$template:$version" : $image;
}

=head2 container_image

Chooses the Docker image for a job.

=head3 ARGUMENTS

=over 4

=item * C<$job> - an instance from L</expand_jobs>.

=item * C<$runs_on> - the text from L</runs_on_text>.

=item * C<$fallback> - the image for a runner that names no Ubuntu.

=item * C<$perl_template> - optional; see L</perl_image_for_version>.

=back

=head3 RETURNS

C<container.image> with its matrix values resolved, if the job has one;
else the image for a setup-perl step's version; else
L</default_image_for_runner>.  A C<github.*> or C<env.*> reference in
C<container.image> is left as written, for a caller that knows those values.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $image = $workflow->container_image($job, 'ubuntu-latest', 'perl:latest');

=head3 API SPECIFICATION

=head4 INPUT

	{
		job           => { type => 'hashref' },
		runs_on       => { type => 'string', optional => 1 },
		fallback      => { type => 'string', optional => 1 },
		perl_template => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to ... | The job is not a hash         | Pass an expanded job           |
	|                          | reference                     |                                |
	+--------------------------+-------------------------------+--------------------------------+

=head3 PSEUDOCODE

	validate the job
	if the job names a container image, resolve its matrix values and return it
	if a setup-perl step chose a version, return the Perl image for it
	return the image the runner implies

=cut

sub container_image {
	my $self = shift;

	# Built as a named hash so a lone job hash is never mistaken by
	# Params::Get for a hash of named arguments.
	my $params = validate_args(__PACKAGE__ . '::container_image', [ {
		job => $_[0],
		runs_on => $_[1],
		fallback => $_[2],
		perl_template => $_[3],
	} ], {
		job => { type => 'hashref' },
		runs_on => { type => 'string', optional => 1 },
		fallback => { type => 'string', optional => 1 },
		perl_template => { type => 'string', optional => 1 },
	});
	my $job = $params->{job};

	# Only the matrix is known here.  A github.* or env.* reference is left
	# as written, so the caller that has those values can resolve it rather
	# than receiving an image name with the value torn out.
	if (ref $job->{container} eq 'HASH' && defined $job->{container}{image}) {
		return $self->_expression->interpolate_known($job->{container}{image}, { matrix => $job->{matrix} || {} });
	}

	if (defined $job->{setup_perl_version} && length $job->{setup_perl_version}) {
		return $self->perl_image_for_version($job->{setup_perl_version}, $params->{perl_template});
	}

	return $self->default_image_for_runner($params->{runs_on}, $params->{fallback});
}

# _expression
# Purpose:     Return the expression evaluator this workflow shares across calls.
# Entry:       $self - a workflow object (a class name gets a fresh evaluator).
# Exit status: Returns an App::Actions::Expression object.
# Side effects: Creates and caches the evaluator on first use.
sub _expression {
	my ($self) = @_;

	# The evaluator holds no state between calls that matters here, so one
	# per workflow is enough; a class-method call cannot cache and need not.
	return ref $self ? ($self->{expression} ||= App::Actions::Expression->new) : App::Actions::Expression->new;
}

# _normalize_job
# Purpose:     Check one job of the jobs mapping and return its normalised copy.
# Entry:       $class - the invocant (for throw); $id - the job's key;
#              $job - the job as parsed.
# Exit status: Returns a hash reference; throws on a malformed job.
# Side effects: None.
sub _normalize_job {
	my ($class, $id, $job) = @_;

	$class->throw('workflow.job_not_mapping', { job => $id }) unless ref $job eq 'HASH';
	$class->throw('workflow.job_no_steps', { job => $id }) unless ref $job->{steps} eq 'ARRAY';

	# "needs: build" and "needs: [build]" mean the same thing; one shape is
	# easier for every caller than two.
	my $needs = defined $job->{needs} ? $job->{needs} : [];
	$needs = [$needs] unless ref $needs eq 'ARRAY';

	# "container: alpine" is shorthand for "container: { image: alpine }".
	my $container = $job->{container};
	$container = { image => $container } if defined $container && !ref $container;
	$class->throw('workflow.container_invalid', { job => $id })
		if defined $container && ref $container ne 'HASH';

	my $services = defined $job->{services} ? $job->{services} : {};
	$class->throw('workflow.services_invalid', { job => $id }) unless ref $services eq 'HASH';

	return {
		%{$job},
		id => $id,
		needs => [ map { "$_" } @{$needs} ],
		container => $container,
		services => { %{$services} },
		env => mapping($job->{env}, ['where.job_env', { job => $id }]),
		defaults => _defaults($job->{defaults}, ['where.job_defaults', { job => $id }]),
		strategy => mapping($job->{strategy}, ['where.job_strategy', { job => $id }]),
		steps => [ map { normalize_step($_, ['where.job', { job => $id }]) } @{ $job->{steps} } ],
	};
}

# _defaults
# Purpose:     Copy a defaults: mapping, checking that defaults.run is a mapping.
# Entry:       $value - the defaults value (may be undef); $place - its place
#              for error messages ([key, args]).
# Exit status: Returns a new hash reference.
# Side effects: None.
sub _defaults {
	my ($value, $place) = @_;

	my $copy = mapping($value, $place);

	# defaults.run is the only nested mapping a step reads from defaults,
	# and it is copied too so a step cannot change the job's defaults.
	if (defined $copy->{run}) {
		__PACKAGE__->throw('workflow.defaults_run_invalid', { where => __PACKAGE__->i18n(@{$place}) })
			unless ref $copy->{run} eq 'HASH';
		$copy->{run} = { %{ $copy->{run} } };
	}

	return $copy;
}

# _copy
# Purpose:     A deep copy of a parsed job, for one matrix instance.  Storable
#              3.26, the version in Perl 5.36, copies a core boolean as a
#              plain empty string, which turned if: false and fail-fast: false
#              into empty values, so a job that should not run did; here every
#              value that is not a hash or an array is kept as it is.
# Entry:       $value - a value YAML::PP loaded: hashes, arrays and scalars.
# Exit status: Returns the copy.
# Side effects: None.
sub _copy {
	my ($value) = @_;

	return { map { $_ => _copy($value->{$_}) } keys %{$value} } if ref $value eq 'HASH';
	return [ map { _copy($_) } @{$value} ] if ref $value eq 'ARRAY';

	return $value;
}

# _expand_matrix
# Purpose:     Expand strategy.matrix into its combinations, as GitHub does.
# Entry:       $matrix - the matrix mapping, or undef for no matrix.
# Exit status: Returns an array reference of combination hashes; throws on a
#              malformed matrix.
# Side effects: None.
sub _expand_matrix {
	my ($matrix) = @_;

	# No matrix is a single run with no matrix values.
	return [ {} ] unless defined $matrix;
	__PACKAGE__->throw('workflow.matrix_not_mapping') unless ref $matrix eq 'HASH';

	# Keys are sorted so the expansion order, and therefore matrix_index, is
	# the same on every run whatever order the hash returns them in.
	my @keys = sort grep { !$MATRIX_DIRECTIVES{$_} } keys %{$matrix};
	my $includes = _as_list($matrix->{include});
	my $excludes = _as_list($matrix->{exclude});

	# A matrix consisting only of include entries yields one combination per
	# include entry, as on GitHub.
	if (!@keys) {
		my @combinations = map { +{ %{$_} } } grep { ref $_ eq 'HASH' } @{$includes};
		return @combinations ? \@combinations : [ {} ];
	}

	my $combinations = _cartesian_product($matrix, \@keys);

	for my $exclude (@{$excludes}) {
		__PACKAGE__->throw('workflow.exclude_invalid') unless ref $exclude eq 'HASH';
		$combinations = [ grep { !_matches($_, $exclude) } @{$combinations} ];
	}

	return _apply_includes($combinations, $includes, { map { $_ => 1 } @keys });
}

# _cartesian_product
# Purpose:     Build every combination of the matrix's dimensions.
# Entry:       $matrix - the matrix mapping; $keys - its dimension names, sorted.
# Exit status: Returns an array reference of combination hashes; throws when a
#              dimension has no values.
# Side effects: None.
sub _cartesian_product {
	my ($matrix, $keys) = @_;

	my @combinations = ({});
	for my $key (@{$keys}) {
		# A scalar is a one-value dimension; an empty list would multiply the
		# whole matrix by zero, which GitHub reports and so do we.
		my $values = _as_list($matrix->{$key});
		__PACKAGE__->throw('workflow.matrix_empty', { key => $key }) unless @{$values};

		@combinations = map {
			my $combination = $_;
			map { +{ %{$combination}, $key => $_ } } @{$values};
		} @combinations;
	}

	return \@combinations;
}

# _apply_includes
# Purpose:     Merge matrix include entries into the combinations, as GitHub does.
# Entry:       $combinations - array reference of combinations (modified in
#              place); $includes - array reference of include entries;
#              $original - hash of the matrix's own dimension names.
# Exit status: Returns the array reference of combinations, with any include
#              that matched nothing appended as a combination of its own.
# Side effects: Adds keys to the combinations the includes match.
sub _apply_includes {
	my ($combinations, $includes, $original) = @_;

	my @extra;
	for my $include (@{$includes}) {
		__PACKAGE__->throw('workflow.include_invalid') unless ref $include eq 'HASH';

		# An include extends every combination it does not contradict on one
		# of the matrix's own keys; one that extends none is a new job.
		my @compatible = grep {
			my $combination = $_;
			!grep { $original->{$_} && !_scalar_equal($combination->{$_}, $include->{$_}) } keys %{$include};
		} @{$combinations};

		@{$_}{ keys %{$include} } = values %{$include} for @compatible;
		push @extra, { %{$include} } unless @compatible;
	}

	return [ @{$combinations}, @extra ];
}

# _as_list
# Purpose:     Treat a scalar as a one-element list and undef as an empty one.
# Entry:       $value - anything.
# Exit status: Returns an array reference (the original when it already is one).
# Side effects: None.
sub _as_list {
	my ($value) = @_;

	return !defined $value ? [] : ref $value eq 'ARRAY' ? $value : [$value];
}

# _matches
# Purpose:     Say whether a combination has every key/value of an exclude filter.
# Entry:       $combination, $filter - hash references.
# Exit status: Returns 1 or 0.
# Side effects: None.
sub _matches {
	my ($combination, $filter) = @_;

	# An exclude names a subset of keys; every one must be present and equal.
	my $mismatch = grep {
		!exists $combination->{$_} || !_scalar_equal($combination->{$_}, $filter->{$_})
	} keys %{$filter};

	return $mismatch ? 0 : 1;
}

# _scalar_equal
# Purpose:     Compare two matrix values the way a workflow sees them.
# Entry:       $left, $right - any values.
# Exit status: Returns 1 when equal, else 0.
# Side effects: None.
sub _scalar_equal {
	my ($left, $right) = @_;

	# Undef equals only undef; everything else is compared as the string the
	# workflow would see, so a boolean true equals the YAML word true and a
	# structure equals another with the same canonical JSON.
	return (!defined $left || !defined $right)
		? ((!defined $left && !defined $right) ? 1 : 0)
		: (stringify($left) eq stringify($right) ? 1 : 0);
}

# _job_display_name
# Purpose:     Name one matrix instance of a job for the report.
# Entry:       $job - the job; $matrix - the combination; $expression - an
#              evaluator.
# Exit status: Returns the name: the job's name: with matrix values resolved,
#              or "id (key=value, ...)".
# Side effects: None.
sub _job_display_name {
	my ($job, $matrix, $expression) = @_;

	# A name: that is not a string is ignored rather than printed as a
	# reference address.
	return $expression->interpolate($job->{name}, { matrix => $matrix })
		if defined $job->{name} && !ref $job->{name};

	my @parts = map { "$_=" . stringify($matrix->{$_}) } sort keys %{$matrix};

	return @parts ? "$job->{id} (" . join(', ', @parts) . ')' : $job->{id};
}

# _find_setup_perl_version
# Purpose:     Find the Perl version a job's setup-perl step asks for.
# Entry:       $job - the job; $matrix - the combination; $expression - an
#              evaluator.
# Exit status: Returns the version with matrix values resolved, or undef when
#              the job has no setup-perl step or the step names no version.
# Side effects: None.
sub _find_setup_perl_version {
	my ($job, $matrix, $expression) = @_;

	# Only the first setup-perl step counts, as it is the one that installs
	# the Perl the later steps run.
	my ($step) = grep { defined $_->{uses} && $_->{uses} =~ $SETUP_PERL_ACTION } @{ $job->{steps} || [] };
	my $version = $step ? $step->{with}{'perl-version'} : undef;

	return defined $version ? $expression->interpolate($version, { matrix => $matrix }) : undef;
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

=item * A matrix whose dimension is an expression, such as
C<perl: ${{ fromJSON(needs.setup.outputs.versions) }}>, is expanded as the
single literal string, because job outputs do not exist before the run.

=item * Job display names are C<id (key=value, ...)>, which is clearer in a
terminal but not what the GitHub web interface shows (C<id (value, ...)>).

=item * C<include> follows GitHub's rule for the matrix's own keys only: an
include whose added key conflicts with a key added by an earlier include
overwrites it rather than forming a new combination.

=item * C<runs-on> runner groups (a mapping with C<group> and C<labels>) are
rejected, and an ARM runner such as C<ubuntu-24.04-arm> is given the
C<ubuntu:24.04> image without a platform, so it runs on the host's
architecture.

=item * On Perl older than 5.36 a boolean matrix value is indistinguishable
from 1 or the empty string; see L<App::Actions::Util/LIMITATIONS>.

=item * The object holds references to its parsed data; the accessors return
them without copying, so a caller can change the workflow it was given.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<C<jobs> and C<expand_jobs> are different.>  L</jobs> has one entry
per job in the file.  L</expand_jobs> has one entry per matrix combination.

=item * B<Do not change what the accessors return.>  They return the
object's own data, so a change affects later calls.  Copy first.

=item * B<Display names are not GitHub's.>  This module writes C<test
(perl=5.40)>; GitHub shows C<test (5.40)>.  Match jobs by C<base_id>, not by
display name.

=item * B<Booleans in a matrix need Perl 5.36.>  On older Perls, a matrix
value of C<true> becomes C<1>.

=item * B<A matrix from an expression is not expanded.>  C<${{
fromJSON(...) }}> is kept as one literal value, because the value it needs
does not exist before the run.

=item * B<C<runs-on> must be text or a list.>  A runner group (a mapping
with C<group> and C<labels>) is refused with C<workflow.runs_on_invalid>.

=item * B<A non-Ubuntu runner gets the fallback image.>  C<macos-latest> or
C<windows-latest> are not emulated; L</is_linux_runner> tells you which jobs
to skip.

=item * B<C<container.image> may still hold expressions.>
L</container_image> resolves C<matrix.*> only.  C<github.*> and C<env.*>
are left for the caller.

=back

=head1 ENCODING

The workflow file is read as UTF-8 (see L<App::Actions::Util/ENCODING>).
Names, step commands and matrix values may contain any Unicode text,
including non-ASCII characters and emoji, and are returned as Perl
character strings.  Job ids should be ASCII letters, digits, C<-> and C<_>,
as GitHub requires.  Image names are ASCII, as Docker requires.  The file
name you pass is used as bytes.

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

=head2 load

	┌─ Load ────────────────────────────────────────────
	│ file? : PATH
	│ wf!   : Workflow
	├───────────────────────────────────────────────────
	│ let doc == LoadYamlMapping(file?, workflow)
	│ doc.jobs ∉ MAPPING ⇒ raises NoJobs(file?)
	│ ∀ id : dom doc.jobs •
	│     doc.jobs(id) ∈ MAPPING ∧ doc.jobs(id).steps ∈ seq VALUE
	│ wf!.file = file?
	│ wf!.name = (doc.name ≠ ⊥ ⇒ doc.name) ∧ (doc.name = ⊥ ⇒ basename(file?))
	│ #wf!.jobs = #(dom doc.jobs)
	│ ∀ j : ran wf!.jobs • j.needs ∈ seq STRING
	└───────────────────────────────────────────────────

=head2 file, name, env, defaults, jobs, raw

	┌─ Accessor ────────────────────────────────────────
	│ ΞWorkflow
	│ field? : {file, name, env, defaults, jobs, raw}
	│ value! : VALUE
	├───────────────────────────────────────────────────
	│ value! = θWorkflow.field?
	└───────────────────────────────────────────────────

=head2 job_by_id

	┌─ JobById ─────────────────────────────────────────
	│ ΞWorkflow
	│ id?  : STRING
	│ job! : optional Job
	├───────────────────────────────────────────────────
	│ (∃ j : ran jobs • j.id = id?) ⇒ job! = first {j : ran jobs | j.id = id?}
	│ (∄ j : ran jobs • j.id = id?) ⇒ job! = ⊥
	└───────────────────────────────────────────────────

=head2 expand_jobs

	COMBINATION == KEY ⇸ VALUE

	┌─ ExpandJobs ──────────────────────────────────────
	│ ΞWorkflow
	│ out! : seq Instance
	├───────────────────────────────────────────────────
	│ out! = ⁀/ ⟨ j : jobs • ⟨ i : 1 .. #C(j) • instance(j, C(j)(i), i-1, #C(j)) ⟩ ⟩
	│   where C(j) = ExpandMatrix(j.strategy.matrix)
	│ ∀ o : ran out! • 0 ≤ o.matrix_index < o.matrix_total
	└───────────────────────────────────────────────────

	┌─ ExpandMatrix ────────────────────────────────────
	│ m?  : optional (KEY ⇸ VALUE)
	│ cs! : seq COMBINATION
	├───────────────────────────────────────────────────
	│ m? = ⊥ ⇒ cs! = ⟨∅⟩
	│ let K == dom m? \ {include, exclude}
	│ K = ∅ ⇒ cs! = m?.include (or ⟨∅⟩ when that is empty)
	│ K ≠ ∅ ⇒ cs! = (product(K) ▷ ¬excluded) ⊕ includes
	│ ∀ k : K • #m?(k) ≥ 1
	└───────────────────────────────────────────────────

=head2 runs_on_text

	┌─ RunsOnText ──────────────────────────────────────
	│ runsOn? : optional (STRING ∪ seq STRING)
	│ matrix? : optional COMBINATION
	│ text!   : STRING
	├───────────────────────────────────────────────────
	│ runsOn? ∈ MAPPING ⇒ raises RunsOnInvalid
	│ runsOn? = ⊥ ⇒ text! = ⟨⟩
	│ runsOn? ∈ STRING ⇒ text! = interpolate(runsOn?, matrix?)
	│ runsOn? ∈ seq STRING ⇒ text! = interpolate(join(" ", runsOn?), matrix?)
	└───────────────────────────────────────────────────

=head2 is_linux_runner

	┌─ IsLinuxRunner ───────────────────────────────────
	│ runsOn? : optional STRING
	│ linux!  : {0, 1}
	├───────────────────────────────────────────────────
	│ linux! = 0 ⇔ (∃ w : {windows, macos, darwin} • w is a word of lower(runsOn?))
	└───────────────────────────────────────────────────

=head2 default_image_for_runner

	┌─ DefaultImageForRunner ───────────────────────────
	│ runsOn?   : optional STRING
	│ fallback? : optional STRING
	│ image!    : optional STRING
	├───────────────────────────────────────────────────
	│ "ubuntu-" ⁀ v ⊆ runsOn? ∧ v ∈ VERSION ⇒ image! = "ubuntu:" ⁀ v
	│ "ubuntu-latest" ⊆ runsOn? ⇒ image! = "ubuntu:latest"
	│ otherwise image! = fallback?
	└───────────────────────────────────────────────────

=head2 perl_image_for_version

	┌─ PerlImageForVersion ─────────────────────────────
	│ version?  : optional STRING
	│ template? : optional STRING
	│ image!    : STRING
	├───────────────────────────────────────────────────
	│ let t == (template? ∈ {⊥, ⟨⟩} ⇒ "perl:%s") ∧ (otherwise ⇒ template?)
	│ let v == (version? ∈ {⊥, ⟨⟩, dev, latest} ⇒ "latest")
	│          ∧ (otherwise ⇒ version? without a leading v)
	│ "%s" ⊆ t ⇒ image! = t with every "%s" replaced by v
	│ "%s" ⊈ t ⇒ image! = t ⁀ ":" ⁀ v
	└───────────────────────────────────────────────────

=head2 container_image

	┌─ ContainerImage ──────────────────────────────────
	│ job?      : Instance
	│ runsOn?   : optional STRING
	│ fallback? : optional STRING
	│ image!    : optional STRING
	├───────────────────────────────────────────────────
	│ job?.container.image ≠ ⊥
	│     ⇒ image! = interpolateKnown(job?.container.image, job?.matrix)
	│ job?.container.image = ⊥ ∧ job?.setup_perl_version ∉ {⊥, ⟨⟩}
	│     ⇒ image! = PerlImageForVersion(job?.setup_perl_version, template?)
	│ otherwise image! = DefaultImageForRunner(runsOn?, fallback?)
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

A workflow object never changes after L</load>.  This is the path from a
file to the jobs the runner starts:

	 load($file)
	      |
	      v
	+---------------------+  file / YAML / mapping checks
	| READ FILE           |  -> workflow.file_required, file_missing,
	+---------------------+     parse_failed, empty, not_mapping
	      |
	      v
	+---------------------+  jobs not a mapping -> workflow.no_jobs
	| CHECK EACH JOB      |  job not a mapping  -> workflow.job_not_mapping
	| (in file order)     |  no steps list      -> workflow.job_no_steps
	|                     |  bad container / services / runs-on / env /
	|                     |  defaults / strategy -> workflow.* codes
	|                     |  each step: App::Actions::Util::normalize_step
	+---------------------+
	      |
	      v
	+---------------------+
	| LOADED (immutable)  |  file, name, env, defaults, jobs, raw,
	+---------------------+  job_by_id
	      |
	      | expand_jobs
	      v
	+---------------------+  matrix not a mapping   -> workflow.matrix_not_mapping
	| EXPAND MATRIX       |  matrix with no values  -> workflow.matrix_empty
	| cross product,      |  bad include / exclude  -> workflow.include_invalid,
	| - exclude,          |                            workflow.exclude_invalid
	| + include           |
	+---------------------+
	      |
	      v
	+---------------------+  each has base_id, matrix, matrix_index,
	| JOB INSTANCES       |  matrix_total, display_name,
	+---------------------+  setup_perl_version
	      |
	      | runs_on_text, is_linux_runner
	      v
	  Linux runner? --no--> the runner skips the job
	      | yes
	      v
	  container_image:
	    container.image? --yes--> that image, matrix.* filled in
	          | no
	    setup-perl step? --yes--> perl_image_for_version(version)
	          | no
	    default_image_for_runner(runs-on, fallback)
	          |
	          v
	    image for the runner (App::Actions::Runner)

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
