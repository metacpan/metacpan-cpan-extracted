package App::Actions::Runner;

use strict;
use warnings;
use autodie qw(:all);

use Cwd qw(abs_path);
use File::Basename qw(basename);
use File::Path qw(make_path remove_tree);
use File::Temp ();
use IO::Handle ();
use JSON::PP ();
use Readonly;
use Scalar::Util qw(weaken);
use Sub::Private ();

use App::Actions::Access;
use App::Actions::Check;
use App::Actions::Docker;
use App::Actions::Expression;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Logs;
use App::Actions::Process;
use App::Actions::Runner::Containers;
use App::Actions::Runner::Images;
use App::Actions::Runner::Parallel;
use App::Actions::Runner::Report;
use App::Actions::Runner::Steps;
use App::Actions::Runner::Support qw(
	boolean_value default_logger has_status_function redact resolve_env status_flags trim_error
	write_container_file
);
use App::Actions::Schema;
use App::Actions::Util ();

our $VERSION = '0.002.1';

# The shape of the preflight JSON document, which is the check document with
# an images array and the pull concurrency added.  It is versioned separately
# from the check document because the two can gain keys independently, but a
# change to the shared part bumps both.  Keep the schema below and the examples
# in t/fixtures/ in step.
#
# 3: docker.bin stopped being nullable, with the check document's 2.  It is
# always the resolved command, so the null type promised a shape no document
# can produce; t/schema.t requires every enum value and null variant to appear
# in the examples, which is what found it.
our $PREFLIGHT_SCHEMA_VERSION = 3;

# The schema of the document preflight --json prints, so that the installed
# action-run can hand the contract to a caller instead of leaving it in the
# tests.  A change to the document belongs here, in $JSON_SCHEMA_VERSION and
# in the examples in t/fixtures/, which t/schema.t holds against this and
# fails when a key it names appears in none of them.
my $JSON_SCHEMA = <<'JSON';
{
  "title": "action-run preflight --json",
  "description": "The document action-run preflight --json prints: the check document with an images array and the pull concurrency added.  Objects reject keys this file does not name, so a new key is a schema change.",
  "version": 3,
  "type": "object",
  "properties": {
    "schema_version": {
      "description": "The version of this shape; App::Actions::Runner->preflight_schema_version returns it.",
      "type": "integer",
      "const": 3
    },
    "ready": {
      "description": "True only when the checks passed and every image was prepared; a deferred image does not make the run unready.",
      "type": "boolean"
    },
    "problems": {
      "description": "How many problems were found, counting the failed images.",
      "type": "integer"
    },
    "pull_concurrency": {
      "description": "How many pulls the preflight allowed at once: the configured setting, but 1 on Windows, where images are pulled one at a time.  It is the number the puller was given, not how many pulls happened to overlap.",
      "type": "integer"
    },
    "host": {
      "type": "object",
      "properties": {
        "os": { "type": "string" },
        "name": { "type": "string" },
        "perl": { "type": "string" },
        "archname": { "type": "string" }
      },
      "required": [ "os", "name", "perl", "archname" ]
    },
    "docker": {
      "type": "object",
      "properties": {
        "bin": { "type": "string" },
        "client": { "type": [ "string", "null" ] },
        "daemon": { "type": [ "string", "null" ] },
        "containers": { "type": [ "string", "null" ] }
      },
      "required": [ "bin", "client", "daemon", "containers" ]
    },
    "image": {
      "description": "The probe image, or null when no container was run.",
      "type": [ "string", "null" ]
    },
    "mounts": {
      "type": "array",
      "items": {
        "oneOf": [
          {
            "description": "The temporary directory the probe reads back from.",
            "type": "object",
            "properties": {
              "host": { "type": "string" },
              "container": { "type": "string" },
              "ok": { "type": "boolean" }
            },
            "required": [ "host", "container", "ok" ]
          },
          {
            "description": "The project directory, whose entry count is compared with the host's.",
            "type": "object",
            "properties": {
              "host": { "type": "string" },
              "container": { "type": "string" },
              "entries": { "type": [ "integer", "null" ] },
              "expected": { "type": [ "integer", "null" ] },
              "ok": { "type": "boolean" }
            },
            "required": [ "host", "container", "entries", "expected", "ok" ]
          }
        ]
      }
    },
    "issues": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "problem": { "type": "string" },
          "remedies": {
            "type": "array",
            "items": { "type": "string" }
          }
        },
        "required": [ "problem", "remedies" ]
      }
    },
    "images": {
      "description": "Every image the selected jobs need, in the order the run would need it.",
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "image": {
            "description": "The image name, or null when it could not be resolved yet.",
            "type": [ "string", "null" ]
          },
          "source": {
            "description": "The job, service or action that needs it.",
            "type": "string"
          },
          "status": {
            "type": "string",
            "enum": [ "pulled", "present", "failed", "skipped", "deferred" ]
          },
          "expression": {
            "description": "Only on a deferred entry: the image name as it was written.",
            "type": "string"
          },
          "error": {
            "description": "Only on a failed or deferred entry: why it was not prepared or named.",
            "type": "string"
          }
        },
        "required": [ "image", "source", "status" ]
      }
    }
  },
  "required": [
    "schema_version",
    "ready",
    "problems",
    "pull_concurrency",
    "host",
    "docker",
    "image",
    "mounts",
    "issues",
    "images"
  ]
}
JSON



# The options a run is configured with, and the Params::Validate::Strict rule
# of each.  App::Actions accepts the same options and validates them with
# this table, so an option cannot be accepted there and dropped here.  Flags
# are strings rather than booleans because callers pass undef, 0, 1 and ''
# interchangeably, and they are read for truth; pull_concurrency and parallel
# are strings too, because new() explains what a valid value is.
Readonly::Hash my %OPTION_RULES => (
	jobs => { type => 'arrayref', optional => 1 },
	env => { type => 'hashref', optional => 1 },
	secrets => { type => 'hashref', optional => 1 },
	docker => { type => 'object', optional => 1 },
	# Where warnings and errors go: a Log::Abstraction logger, or anything
	# with its methods.  Without one they are printed to standard error.
	logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	map({ $_ => { type => 'string', optional => 1 } } qw(
		image perl_image platform user log_dir cache_file docker_bin pull_concurrency parallel
		dry_run explain verbose quiet keep keep_images pull no_pull strict_actions skip_check
	)),
);

# How many images are pulled at once when neither the option nor the
# environment says: four downloads saturate most connections without burying
# the pull output or the daemon.
Readonly::Scalar my $DEFAULT_PULL_CONCURRENCY => 4;
Readonly::Scalar my $PULL_CONCURRENCY_VARIABLE => 'ACTION_RUN_PULL_CONCURRENCY';

# A positive integer, as the concurrency options must be.
Readonly::Scalar my $POSITIVE_INTEGER => qr/\A[1-9][0-9]*\z/;

# The OWNER/REPO of a GitHub remote, in any of the forms git writes it:
# https://github.com/o/r.git, git@github.com:o/r, ssh://git@github.com/o/r/.
Readonly::Scalar my $GITHUB_REMOTE => qr{
	github\.com [:/]      # the host, then ":" (scp form) or "/" (URL form)
	(
		[^/]+ /          # the owner
		.+?              # the repository, as short as the rest allows
	)
	(?: \.git )?         # git's suffix
	/?                   # and a trailing slash
	\z
}x;

# The runner directory the job's container mounts, and where a run that
# keeps its temporary directory leaves it.  Its subdirectories are the
# runner's own: the tool cache, HOME, scripts, the step files, the event and
# the sudo and apt shims.
Readonly::Array my @RUNNER_DIRECTORIES => qw(_temp _tool home scripts env output summary path event bin aptbin);

# The runner context and the RUNNER_* variables describe the same machine.
Readonly::Hash my %RUNNER_CONTEXT => (
	os => 'Linux',
	arch => 'X64',
	name => 'local',
	temp => '/github/actions-runner/_temp',
	tool_cache => '/github/actions-runner/_tool',
	workspace => '/github/workspace',
);

# The sudo shim: the job container already runs as root, so privilege
# escalation is unnecessary, and the common sudo options are skipped.
Readonly::Scalar my $SUDO_SHIM => <<'SH';
#!/bin/sh
# action-run sudo shim.  The job container is already running as root, so
# privilege escalation is unnecessary.  Ignore the common sudo options.
while [ "$#" -gt 0 ]; do
    case "$1" in
        -E|-H|-n) shift ;;
        -u) shift 2 ;;
        --) shift; break ;;
        -*) shift ;;
        *) break ;;
    esac
done
exec "$@"
SH

# The apt shims.  GitHub-hosted runners configure apt with assume-yes, so
# unattended installs work; without a terminal apt aborts at its "Continue?"
# prompt, which breaks any workflow that runs "apt install" under sudo.  NAME
# is replaced by apt or apt-get.
Readonly::Scalar my $APT_SHIM => <<'SH';
#!/bin/sh
# action-run NAME shim: answer "yes" to mutating package commands so
# unattended installs behave like the GitHub-hosted runners.
subcommand=
assume_yes=
for arg in "$@"; do
    case "$arg" in
        --) break ;;
        -y|--yes|--assume-yes|-yq|-qy) assume_yes=1 ;;
        -*) ;;
        *) subcommand=$arg; break ;;
    esac
done
case "$subcommand" in
    install|remove|purge|upgrade|full-upgrade|dist-upgrade|autoremove|autoclean|build-dep)
        [ -n "$assume_yes" ] || set -- "$@" --yes
        ;;
esac
exec /usr/bin/NAME "$@"
SH

=encoding utf-8

=head1 NAME

App::Actions::Runner - plan and run a GitHub Actions workflow in Docker

=head1 SYNOPSIS

	use App::Actions::Runner;
	use App::Actions::Workflow;

	my $runner = App::Actions::Runner->new(
		workflow    => App::Actions::Workflow->load("$project/.github/workflows/ci.yml"),
		project_dir => $project,
		image       => 'ubuntu:latest',
	);
	my $exit = $runner->run;

Most callers use L<App::Actions>, which builds the runner for them.

Run only some jobs, without starting anything (a dry run):

	my $runner = App::Actions::Runner->new(
		workflow    => $workflow,
		project_dir => $project,
		jobs        => [ 'lint', 'test' ],
		dry_run     => 1,
	);
	$runner->run;    # prints the Docker commands it would run

Prepare everything, then report as data:

	my $result = App::Actions::Runner->new(workflow => $workflow, project_dir => $project)
		->preflight(json => 1);
	print "ready\n" if $result->{exit} == 0;

Test without Docker, with an object that has the L<App::Actions::Docker>
interface:

	my $runner = App::Actions::Runner->new(
		workflow    => $workflow,
		project_dir => $project,
		docker      => My::FakeDocker->new,
	);

=head1 DESCRIPTION

B<In short:> the runner is the part of App::Actions that decides what to
run, in what order, and then asks its helper modules to do it.

The runner is the planner of a run.  It expands the workflow's jobs, selects
the ones asked for, checks the host, orders the jobs by their C<needs>, decides
each job's C<if>, and hands the work to its parts:

=over 4

=item * L<App::Actions::Runner::Images> works out every image the run needs,
pulls them before anything starts, and remembers what it pulled.

=item * L<App::Actions::Runner::Containers> creates each job's network,
service containers and job container, explains why one would not start, and
removes them.

=item * L<App::Actions::Runner::Steps> runs a job's steps in its container.

=item * L<App::Actions::Runner::Parallel> runs the jobs of one matrix beside
each other.

=item * L<App::Actions::Runner::Report> prints the summary and keeps the logs.

=back

Each job gets its own Docker network, its own service containers, and a
long-lived job container.  Steps are executed with C<docker exec>, so
filesystem changes persist between steps while each step gets a fresh shell,
just as on GitHub.  Containers and networks are removed when the job or run
finishes.  The images the run pulled are kept by default, because they are
the next run's cache; C<keep_images> set to a false value removes the ones
this run pulled.  Use C<keep> for debugging, which keeps the containers and
networks as well.

The jobs of one matrix run beside each other, up to C<parallel> at a time,
when the host can fork and the run is not one that keeps its containers.
C<parallel> defaults to 1 in the library; L<action-run> sets it to the number
of processors unless C<--parallel> says otherwise, and the workflow's
C<strategy.max-parallel> still caps it.

=head1 METHODS

=head2 new

Creates a runner for one workflow and project.

=head3 ARGUMENTS

=over 4

=item * C<workflow> - an L<App::Actions::Workflow>.

=item * C<project_dir> - the project directory; it must exist.

=item * The run options of L</option_rules>: C<jobs>, C<image>,
C<perl_image>, C<platform>, C<user>, C<env>, C<secrets>, C<dry_run>,
C<explain>, C<verbose>, C<quiet>, C<keep>, C<keep_images>, C<log_dir>,
C<cache_file>, C<pull>, C<no_pull>, C<strict_actions>, C<skip_check>,
C<pull_concurrency>, C<parallel>, C<docker>, C<docker_bin>.  They are
described in L<App::Actions/new>.

=item * C<logger> - a L<Log::Abstraction> object (anything with C<warn>,
C<error> and C<notice> methods) that receives the run's warnings and errors.
Unlike L<App::Actions/new>, this takes only an object.  It defaults to
L<App::Actions::Runner::Support/default_logger>, which prints them to
standard error.  It is handed on to the parts of the runner, so every part
logs to the same place.

=back

=head3 RETURNS

An C<App::Actions::Runner> object.

=head3 SIDE EFFECTS

Reads C<ACTION_RUN_PULL_CONCURRENCY> when C<pull_concurrency> is not given.

=head3 EXAMPLE

	my $runner = App::Actions::Runner->new(
		workflow => $workflow,
		project_dir => '.',
		jobs => [ 'test' ],
		parallel => 4,
		keep_images => 0,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		workflow    => { type => 'object', can => 'expand_jobs' },
		project_dir => { type => 'string' },
		%{ App::Actions::Runner->option_rules },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| A workflow is required      | workflow was not given       | Load one with               |
	|                             |                              | App::Actions::Workflow      |
	| A project directory is      | project_dir was not given    | Pass the repository's path  |
	| required                    |                              |                             |
	| Project directory 'X' does  | The path is not a directory  | Check the path              |
	| not exist                   |                              |                             |
	| pull concurrency must be a  | pull_concurrency or          | Use a whole number above 0  |
	| positive integer, not 'X'   | ACTION_RUN_PULL_CONCURRENCY  |                             |
	|                             | is not one                   |                             |
	| --pull and --no-pull cannot | Both were given              | Choose one                  |
	| be used together            |                              |                             |
	| Invalid arguments to ...    | An unknown option, or one of | See App::Actions/new        |
	|                             | the wrong type               |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	validate the arguments against the option rules
	require the workflow and an existing project directory
	work out the pull concurrency and the parallelism
	build the Docker object unless one was given
	use the default logger (standard error) unless one was given
	refuse --pull with --no-pull
	build the image preparer, the container manager and the reporter,
	    each with the logger

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		workflow => { type => 'object', can => 'expand_jobs', optional => 1 },
		project_dir => { type => 'string', optional => 1 },
		%OPTION_RULES,
	});

	$class->throw('runner.workflow_required') unless $params->{workflow};
	$class->throw('runner.project_dir_required') unless defined $params->{project_dir};

	my $project_dir = abs_path($params->{project_dir});
	$class->throw('runner.project_dir_missing', { dir => $params->{project_dir} })
		unless defined $project_dir && -d $project_dir;

	my $self = bless {
		%{$params},
		project_dir => $project_dir,
		jobs => $params->{jobs} || [],
		perl_image => $params->{perl_image} || 'perl:%s',
		env => $params->{env} || {},
		secrets => $params->{secrets} || {},
		logger => $params->{logger} || default_logger(),
		# An explain run starts nothing, so it is a dry run whose output is
		# the containers rather than the commands that would start them.
		dry_run => ($params->{dry_run} || $params->{explain}) ? 1 : 0,
		# The images a run pulls are its cache: keeping them means the next
		# run of the same workflow starts from them, so removal is the
		# opt-out and keeping is the default.
		keep_images => defined $params->{keep_images} ? ($params->{keep_images} ? 1 : 0) : 1,
		(map { $_ => $params->{$_} ? 1 : 0 } qw(explain verbose quiet keep pull no_pull strict_actions skip_check)),
		pull_concurrency => $class->_pull_concurrency($params->{pull_concurrency}),
		# How many jobs of one matrix may run at once.  The library runs
		# them one at a time unless asked for more.
		parallel => _job_parallelism($params->{parallel}),
		# Whether the runner directory has to be open to other users of the
		# host, because the container runs as someone who is neither root
		# nor the user running this.
		share_files => _shares_runner_files($params->{user}),
		expression => App::Actions::Expression->new,
		run_id => sprintf('%x%04x', time, $$ & 0xffff),
		cleaned_up => 0,
	}, $class;

	$self->{docker} = ref $params->{docker} ? $params->{docker} : App::Actions::Docker->new(
		bin => $params->{docker_bin},
		(map { $_ => $self->{$_} } qw(dry_run explain verbose quiet platform secrets)),
	);

	$self->throw('runner.pull_conflict') if $self->{pull} && $self->{no_pull};

	return $self->_build_parts;
}

=head2 option_rules

	my $rules = App::Actions::Runner->option_rules;

Returns a copy of the L<Params::Validate::Strict> rule of every run option,
by name.  L<App::Actions> validates its own arguments with it, so the two
accept exactly the same options.

=head3 EXAMPLE

	my @options = sort keys %{ App::Actions::Runner->option_rules };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub option_rules {
	return { map { $_ => { %{ $OPTION_RULES{$_} } } } keys %OPTION_RULES };
}

=head2 json_schema

	my $schema = App::Actions::Runner->json_schema;

Returns the JSON schema of the preflight document as a hash, the same document
C<action-run schema preflight> prints.  It is kept here so that the contract
ships with the module rather than only with the tests.

=head3 EXAMPLE

	print JSON::PP->new->canonical->pretty->encode(App::Actions::Runner->json_schema);

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub json_schema {
	return JSON::PP->new->decode($JSON_SCHEMA);
}

=head2 preflight_schema_version

	my $version = App::Actions::Runner->preflight_schema_version;

Returns the version of the preflight JSON document, which is also its
C<schema_version> key.  The checked-in example is validated against the schema
in F<t/schema.t>.

=head3 EXAMPLE

	die 'too old' if App::Actions::Runner->preflight_schema_version < 3;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', min => 1 }

=head3 MESSAGES

None.

=cut

sub preflight_schema_version { return $PREFLIGHT_SCHEMA_VERSION }

=head2 workflow

Returns the L<App::Actions::Workflow> the runner was given.

=head3 EXAMPLE

	print $runner->workflow->name, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Workflow' }

=head3 MESSAGES

None.

=cut

sub workflow { return $_[0]->{workflow} }

=head2 list_jobs

Prints the selected job instances, one per line as C<base_id TAB display
name>, and returns 0.

=head3 EXAMPLE

	$runner->list_jobs;
	# test	test (perl=5.38)
	# test	test (perl=5.40)

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0 ] }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| No job matched 'X'          | A jobs filter names no job   | Use an id or a display name |
	|                             |                              | the listing shows           |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub list_jobs {
	my ($self) = @_;

	my $selected = $self->_select_jobs($self->{workflow}->expand_jobs);
	print $_->{base_id}, "\t", redact($self->{docker}, $_->{display_name}), "\n" for @{$selected};

	return 0;
}

=head2 run

Runs every selected job and returns an exit status: 0 for success, 1 for a
workflow failure, 2 for a usage or Docker error.

=head3 EXAMPLE

	exit App::Actions::Runner->new(workflow => $workflow, project_dir => '.')->run;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1, 2 ] }

=head3 MESSAGES

Everything the run fails with is printed as C<action-run: MESSAGE> on
standard error, and the run exits 2.  The commonest:

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| the environment is not      | The host check failed        | Fix what the report asks,   |
	| ready; ...                  |                              | or pass --skip-check        |
	| cannot prepare the image    | An image could not be pulled | Check the name and registry |
	| 'X', needed by S: E         |                              |                             |
	| Dependency cycle involving  | Jobs need each other         | Break the cycle in needs    |
	| job 'X'                     |                              |                             |
	| Interrupted / Terminated    | SIGINT or SIGTERM            | None                        |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	turn SIGINT and SIGTERM into errors, so the cleanup still runs
	expand and select the jobs
	unless it is a dry run, check the host and prepare every image
	make the temporary directory and the base environment
	run the jobs, group by group in needs order
	print the summary
	on an error, print it and exit 2
	clean up: containers, networks, images not kept, the temporary directory

=cut

sub run {
	my ($self) = @_;

	# The run is one eval, and its parts use more; the caller's $@ is its own.
	local $@;

	my $exit_code = 0;

	# A signal becomes an error, so the run still removes its containers.
	local $SIG{INT} = sub { die $self->i18n('runner.interrupted'), "\n" };
	local $SIG{TERM} = sub { die $self->i18n('runner.terminated'), "\n" };

	my $ran = eval {
		# Selecting the jobs first lets the probe use the image the run is
		# about to use, so a working setup needs no extra pull.
		my $instances = $self->{workflow}->expand_jobs;
		$self->_select_jobs($instances);
		$self->_check_environment($instances) unless $self->{dry_run};

		$self->_prepare_temp;
		$self->_build_base_env;
		$self->_run_groups;
		$self->{report}->print_summary;

		$exit_code = $self->{report}->failed ? 1 : 0;
		1;
	};

	if (!$ran) {
		# Without a source line: the message is for the person running the
		# workflow, and an error of this program's own says where it is.
		my $error = trim_error($@);
		$error = '' unless defined $error;
		# Whatever the run printed belongs before the error, even when the
		# two are written through different buffers.
		STDOUT->flush;
		$self->{logger}->error($self->i18n('runner.error', { error => $error })) unless $self->{quiet};
		$exit_code = 2;
	}

	$self->_cleanup;

	return $exit_code;
}

=head2 preflight

	my $result = $runner->preflight(json => 1);

Makes the same checks and image preparations as a run, without starting a
container, so a caller can report the outcome as data rather than as prose.

=head3 ARGUMENTS

=over 4

=item * C<json> - optional; print nothing (the checks write into a buffer
that is discarded and the pull output is dropped), and return the document
C<action-run preflight --json> prints, validated against L</json_schema>.

=item * C<schema_line> - optional, default true; end the text report with
the version of the document's schema.  A caller that prints its own report,
such as the smoke test, turns it off.

=back

=head3 RETURNS

C<< { exit => 0 | 2, summary => \%document, error => $message_or_undef } >>.
The document is the L<App::Actions::Check> report with C<images> added and
C<pull_concurrency> the number of pulls allowed at once (1 on Windows).  Its
C<schema_version> is L</preflight_schema_version>.  With C<json>, C<ready> is
a JSON boolean.

=head3 SIDE EFFECTS

Probes the host, pulls images and records them in the image cache; prints a
report unless C<json> is set.

=head3 EXAMPLE

	my $result = $runner->preflight;
	print STDERR "action-run: $result->{error}\n" if defined $result->{error};
	exit $result->{exit};

=head3 API SPECIFICATION

=head4 INPUT

	{
		json        => { type => 'boolean', optional => 1 },
		schema_line => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			exit    => { type => 'integer', memberof => [ 0, 2 ] },
			summary => { type => 'hashref' },
			error   => { type => 'string', optional => 1 },
		},
	}

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message (in error)          | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| the environment is not      | A host check failed          | Fix what the report asks    |
	| ready; ...                  |                              |                             |
	| cannot prepare the image    | An image could not be pulled | Check the name and registry |
	| 'X', needed by S: E         |                              |                             |
	| the action-run preflight    | The document does not match  | A bug in this distribution; |
	| --json document does not    | its schema; raised as an     | report it                   |
	| match ...json_schema: ...   | App::Actions::Schema::Invalid|                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	expand and select the jobs
	with skip_check: ask only whether Docker answers; if not, return a
		document that says so
	otherwise run the host check, silently for a JSON caller
	if the check failed, list the images the run would need as skipped
	otherwise prepare them and add an issue for each that failed
	print the image lines and the schema line, for a text caller
	record what was pulled in the image cache
	return the exit status, the document and the first error

=cut

sub preflight {
	my ($self, %options) = @_;

	local $@;

	my $json = $options{json} ? 1 : 0;
	my $schema_line = (defined $options{schema_line} && !$options{schema_line}) ? 0 : 1;

	my $instances = $self->{workflow}->expand_jobs;
	$self->_select_jobs($instances);

	my $checked = $self->{skip_check} ? $self->_reach_docker : $self->_run_check($instances, $json);

	# Docker did not answer, so there is nothing more to find out.
	return $self->_preflight_result($checked->{summary}, 0, $checked->{summary}{issues}, [], $json, $checked->{error})
		unless $checked->{reachable};

	my $summary = $checked->{summary};
	my ($records, $failures) = $checked->{exit} != 0
		? ($self->_skipped_images($instances), [])
		: @{ $self->{images}->prepare($instances, quiet => $json) }{qw(records failures)};

	my @issues = (
		@{ $summary->{issues} || [] },
		map { { problem => $self->{images}->failure_message($_), remedies => [ $self->i18n('runner.preflight.remedy_image') ] } } @{$failures},
	);

	# A text caller reads the images rather than the document, and the
	# version comes last, where the check report puts it, so a pasted report
	# says which contract the lines above were written against.
	if (!$json) {
		$self->{report}->report_images($records);
		print $self->i18n('runner.preflight.schema_line', { version => $PREFLIGHT_SCHEMA_VERSION }), "\n" if $schema_line;
	}

	# The preflight keeps what it pulled, so those images belong in the same
	# cache record a run writes.
	$self->{images}->remember($self->{cache_file}) if $self->{keep_images};

	my $ready = ($summary->{ready} && !@{$failures}) ? 1 : 0;
	my $error = @{$failures} ? $self->{images}->failure_message($failures->[0])
		: $ready ? undef
		: $self->i18n('runner.not_ready');

	return $self->_preflight_result($summary, $ready, \@issues, $records, $json, $error);
}

# _pull_concurrency
# Purpose:     How many images may be pulled at the same time.  The option
#              wins over the environment, which wins over four.
# Entry:       $class; $value - the option, or undef.
# Exit status: Returns a positive integer; croaks on anything else.
# Side effects: Reads ACTION_RUN_PULL_CONCURRENCY.
sub _pull_concurrency {
	my ($class, $value) = @_;

	($value) = grep { defined && length } ($value, $ENV{$PULL_CONCURRENCY_VARIABLE});
	return $DEFAULT_PULL_CONCURRENCY unless defined $value;

	$class->throw('runner.pull_concurrency_invalid', { value => $value })
		unless !ref $value && $value =~ $POSITIVE_INTEGER;

	return $value + 0;
}

# _shares_runner_files
# Purpose:     Whether the runner directory must be readable and writable by
#              every user of the host.  Without --user the container runs as
#              its image's user, as before; root can use a private directory
#              anyway, and so can the user running this, because a bind mount
#              keeps the host's numeric owner.  Anyone else needs it open.
# Entry:       $user - the --user value: NAME, UID, NAME:GROUP or UID:GID.
# Exit status: Returns 1 when the directory must be shared, 0 otherwise.
# Side effects: None.
sub _shares_runner_files {
	my ($user) = @_;

	my ($who) = (defined $user && length $user) ? split(/:/, $user, 2) : ();

	# Asked inside an eval, which must not clear the caller's $@.
	local $@;

	# The user running this may be named as well as numbered.  getpwuid is
	# not implemented everywhere (Windows), and then no name matches.
	my $me = eval { (getpwuid $<)[0] };

	return !(defined $who && length $who) ? 0
		: ($who eq 'root' || $who eq '0') ? 0
		: ($who =~ /\A[0-9]+\z/ && $who == $<) ? 0
		: (defined $me && $who eq $me) ? 0
		: 1;
}

# _job_parallelism
# Purpose:     How many jobs of one matrix may run at once.
# Entry:       $value - the option, or undef.
# Exit status: Returns a positive integer; anything that is not one means 1.
# Side effects: None.
sub _job_parallelism {
	my ($value) = @_;

	return (defined $value && !ref $value && $value =~ $POSITIVE_INTEGER) ? $value + 0 : 1;
}

# _build_parts
# Purpose:     Make the runner's parts once its options are settled.
# Entry:       None.
# Exit status: Returns the runner.
# Side effects: Creates the image preparer, the container manager and the
#              reporter.  Their callbacks hold a weak reference, so the
#              runner and its parts do not keep each other alive.
sub _build_parts {
	my ($self) = @_;

	weaken(my $weak = $self);

	$self->{images} = App::Actions::Runner::Images->new(
		(map { $_ => $self->{$_} } qw(docker expression workflow project_dir image perl_image
			dry_run verbose quiet pull no_pull pull_concurrency logger)),
		context => sub { $weak->_preflight_context(@_) },
	);
	$self->{containers} = App::Actions::Runner::Containers->new(
		map { $_ => $self->{$_} } qw(docker expression project_dir run_id platform user quiet explain keep logger),
	);
	$self->{report} = App::Actions::Runner::Report->new(docker => $self->{docker}, quiet => $self->{quiet}, logger => $self->{logger});

	return $self;
}

# _check_environment
# Purpose:     Probe the host before starting anything - the daemon, the
#              container type and a real bind mount of the project - and
#              prepare every image.  Without this, the first symptom of an
#              unshared drive is a job that cannot see its own checkout.
# Entry:       $instances - the selected job instances.
# Exit status: Returns nothing; throws when the host or an image is not ready.
# Side effects: Runs the check, pulls images.
sub _check_environment {
	my ($self, $instances) = @_;

	# --skip-check skips the probes, not the question "is Docker there?",
	# because a cryptic failure deeper in the run helps nobody.
	if ($self->{skip_check}) {
		$self->{docker}->check;
		return;
	}

	my $images = $self->{images};
	my $check = App::Actions::Check->new(
		docker_bin => $self->_docker_bin,
		image => $images->probe($instances),
		platform => $self->{platform},
		directory => $self->{project_dir},
		# Silent when everything works, a full report with remedies when not.
		quiet => $self->{verbose} ? 0 : 1,
	);

	# The probe starts a container from the image the run is about to use,
	# and a daemon that has never seen it pulls it there and then.  A run
	# told not to keep its images has to remember that it fetched this one.
	my $probe = $check->image;
	my $probe_known = defined $probe && length $probe;
	my $probe_present = (!$self->{keep_images} && $probe_known) ? $self->{docker}->image_exists($probe) : 1;

	# Advice rather than a fault in the code, so it names no source line.
	$self->throw('runner.not_ready', { location => 0 }) if $check->run != 0;

	$images->note_pulled($probe) if !$probe_present && $probe_known && $self->{docker}->image_exists($probe);

	my $failures = $images->prepare($instances)->{failures};
	$self->throw('runner.image.unprepared', { %{ $failures->[0] }, location => 0 }) if @{$failures};

	return;
}

# _reach_docker
# Purpose:     The preflight's check under --skip-check: no probes, but Docker
#              still has to answer before anything is pulled.
# Entry:       None.
# Exit status: Returns { reachable, exit, summary, error }.
# Side effects: Runs docker version (through Docker->check).
sub _reach_docker {
	my ($self) = @_;

	my $reachable = eval { $self->{docker}->check; 1 } ? 1 : 0;
	my $error = $reachable ? undef : trim_error($@);

	return {
		reachable => $reachable,
		exit => 0,
		error => $error,
		summary => {
			ready => $reachable,
			# The host needs no probe, so it is reported even here: a
			# consumer of the document sees the same keys either way.
			host => App::Actions::Check->host_info,
			docker => { bin => $self->_docker_bin, client => undef, daemon => undef, containers => undef },
			image => undef,
			mounts => [],
			issues => $reachable ? [] : [ { problem => $error, remedies => [] } ],
		},
	};
}

# _run_check
# Purpose:     The preflight's host check, silent for a JSON caller.
# Entry:       $instances; $json.
# Exit status: Returns { reachable => 1, exit, summary }.
# Side effects: Runs App::Actions::Check, which may pull the probe image.
sub _run_check {
	my ($self, $instances, $json) = @_;

	my %check_args = (
		docker_bin => $self->_docker_bin,
		image => $self->{images}->probe($instances),
		platform => $self->{platform},
		directory => $self->{project_dir},
		# Silent when everything works, a full report with remedies when
		# not; a JSON caller keeps even that out of its streams.
		quiet => $json ? 1 : ($self->{verbose} ? 0 : 1),
		# The preflight's document has a version of its own; the line the
		# text report ends with names that one, not the check's.
		schema_line => 0,
	);

	if ($json) {
		my $report = '';
		no autodie qw(open);
		open(my $sink, '>', \$report)
			or $self->throw('runner.preflight.buffer_failed', { error => "$!", location => 0 });
		$check_args{output} = $sink;
	}

	my $check = App::Actions::Check->new(%check_args);
	my $exit = $check->run;

	return { reachable => 1, exit => $exit, summary => $check->summary($exit) };
}

# _skipped_images
# Purpose:     What the run would have needed, when the host is not ready and
#              nothing is pulled.
# Entry:       $instances.
# Exit status: Returns an array reference of records with status skipped.
# Side effects: None.
sub _skipped_images {
	my ($self, $instances) = @_;

	return [ map {
		defined $_->{image}
			? { source => $_->{source}, status => 'skipped', image => $_->{image} }
			: { source => $_->{source}, status => 'skipped', image => undef, expression => $_->{expression}, error => $_->{error} }
	} @{ $self->{images}->required($instances) } ];
}

# _preflight_result
# Purpose:     The value preflight() returns, built in one place so that a
#              text caller, a JSON caller and a JSON caller whose daemon is
#              unreachable all get the same keys.
# Entry:       $summary - the check's summary; $ready; $issues; $images;
#              $json; $error.
# Exit status: Returns { exit, summary, error }.
# Side effects: None; dies with App::Actions::Schema::Invalid when a JSON
#              document does not match the schema.
sub _preflight_result {
	my ($self, $summary, $ready, $issues, $images, $json, $error) = @_;

	my $document = {
		%{ $summary || {} },
		schema_version => $PREFLIGHT_SCHEMA_VERSION,
		ready => $ready ? 1 : 0,
		problems => scalar @{$issues},
		pull_concurrency => $self->{images}->concurrency,
		issues => $issues,
		images => $images,
	};

	# The printed document says true or false, so it is validated in the
	# form it is printed in.  A key added, removed or retyped without the
	# schema changing fails here rather than in whatever reads the document.
	if ($json) {
		$document->{ready} = $ready ? JSON::PP::true() : JSON::PP::false();
		App::Actions::Schema::assert_valid($document, $self->json_schema, $self->i18n('runner.preflight.schema_mismatch'));
	}

	return { exit => $ready ? 0 : 2, summary => $document, error => $error };
}

# _docker_bin
# Purpose:     The Docker command to probe with.  A caller-supplied Docker
#              object need not expose its binary.
# Entry:       None.
# Exit status: Returns the command, or undef.
# Side effects: None.
sub _docker_bin {
	my ($self) = @_;

	my $bin = eval { $self->{docker}->bin };

	return (defined $bin && length $bin) ? $bin : undef;
}

# _select_jobs
# Purpose:     Apply the jobs filter and group the instances by job id, in
#              the order the workflow gives them.
# Entry:       $instances - every expanded instance.
# Exit status: Returns an array reference of the selected instances; throws
#              when a filter matches nothing.
# Side effects: Sets instances, job_groups and job_order.
sub _select_jobs {
	my ($self, $instances) = @_;

	my @selected = @{$instances};
	if (my @filters = @{ $self->{jobs} }) {
		# A filter is a job id or a display name; the instances keep the
		# workflow's order whatever order the filters are in.
		my %matched;
		for my $filter (@filters) {
			my @hits = grep { $instances->[$_]{base_id} eq $filter || $instances->[$_]{display_name} eq $filter } 0 .. $#{$instances};
			$self->throw('runner.no_job_matched', { filter => $filter }) unless @hits;
			$matched{$_} = 1 for @hits;
		}
		@selected = @{$instances}[ sort { $a <=> $b } keys %matched ];
	}

	my (%groups, @order);
	for my $instance (@selected) {
		push @order, $instance->{base_id} unless $groups{ $instance->{base_id} };
		push @{ $groups{ $instance->{base_id} } }, $instance;
	}
	@{$self}{qw(instances job_groups job_order)} = (\@selected, \%groups, \@order);

	return \@selected;
}

# _prepare_temp
# Purpose:     Make the runner directory the job container mounts, with the
#              sudo and apt shims in it.
# Entry:       $root - optional; the directory to use (a parallel job's own),
#              else a new temporary directory.
# Exit status: Returns nothing.
# Side effects: Creates directories and files; sets temp_path.
sub _prepare_temp {
	my ($self, $root) = @_;

	# The directory holds scripts and environment files, which may contain
	# secrets.  It stays private unless the container runs as another user,
	# who must then be able to write into it.  Such a directory is sticky, so
	# nobody can remove or replace a file of the run's, and every file in it
	# is created exclusively (see write_container_file), so a name someone
	# planted in advance stops the run instead of redirecting a write.
	my $mode = $self->{share_files} ? oct('1777') : oct('0700');

	if (defined $root && length $root) {
		# A job running beside another gets its own directory under the
		# run's root, so neither can write over the other's step files.
		make_path($root);
		$self->{temp_path} = $root;
	} else {
		$self->{tempdir} = File::Temp->newdir('app-actions-XXXXXX', TMPDIR => 1, CLEANUP => 0);
		$self->{temp_path} = "$self->{tempdir}";
	}

	# A mode the filesystem will not take is not worth failing the run for.
	no autodie qw(chmod);
	chmod $mode, $self->{temp_path};
	for my $directory (@RUNNER_DIRECTORIES) {
		make_path("$self->{temp_path}/$directory");
		chmod $mode, "$self->{temp_path}/$directory";
	}

	# Said once, by the process that made the directory, not by each
	# parallel job in its own corner of it.
	$self->_complain('runner.shared_files', { user => $self->{user}, dir => $self->{temp_path} })
		if $self->{share_files} && !(defined $root && length $root);

	$self->_write_shim("$self->{temp_path}/bin/sudo", $SUDO_SHIM, $self->i18n('runner.what.sudo_shim'));
	for my $name (qw(apt apt-get)) {
		(my $shim = $APT_SHIM) =~ s/NAME/$name/g;
		$self->_write_shim("$self->{temp_path}/aptbin/$name", $shim, $self->i18n('runner.what.apt_shim', { name => $name }));
	}

	return;
}

# _write_shim
# Purpose:     Write an executable shim into the runner directory.
# Entry:       $path; $contents; $description - for the error message.
# Exit status: Returns nothing.
# Side effects: Writes the file and makes it executable.
sub _write_shim {
	my (undef, $path, $contents, $description) = @_;

	write_container_file($path, $contents, $description);
	no autodie qw(chmod);
	chmod oct('0755'), $path;

	return;
}

# _repository_env
# Purpose:     The GitHub values a run derives from the checkout: branch,
#              commit, repository and run identifiers.  They are needed
#              before any temporary directory exists, so the preflight
#              resolves github.* in an image name as the run will.
# Entry:       None.
# Exit status: Returns a hash reference of GITHUB_* variables (cached).
# Side effects: Runs git in the project.
sub _repository_env {
	my ($self) = @_;

	return $self->{repository_env} if $self->{repository_env};

	my $remote = App::Actions::Util::trim($self->_git('config', '--get', 'remote.origin.url'));
	my ($repository) = $remote =~ $GITHUB_REMOTE;
	$repository = basename($self->{project_dir}) unless defined $repository;
	$repository =~ s/\.git\z//;

	my $branch = App::Actions::Util::trim($self->_git('symbolic-ref', '--short', '-q', 'HEAD'));
	$branch = 'main' unless length $branch;
	my $sha = App::Actions::Util::trim($self->_git('rev-parse', 'HEAD'));
	$sha = '0' x 40 unless length $sha;

	my $actor = $ENV{GITHUB_ACTOR} || $ENV{USER} || 'local';
	my ($owner) = split m{/}, $repository, 2;
	$owner = $actor unless defined $owner && length $owner;

	return $self->{repository_env} = {
		GITHUB_ACTOR => $actor,
		GITHUB_API_URL => 'https://api.github.com',
		GITHUB_EVENT_NAME => 'push',
		GITHUB_GRAPHQL_URL => 'https://api.github.com/graphql',
		GITHUB_REF => "refs/heads/$branch",
		GITHUB_REF_NAME => $branch,
		GITHUB_REF_TYPE => 'branch',
		GITHUB_REPOSITORY => $repository,
		GITHUB_REPOSITORY_OWNER => $owner,
		GITHUB_RUN_ATTEMPT => '1',
		GITHUB_RUN_ID => sprintf('%d%05d', time, $$ % 100_000),
		GITHUB_RUN_NUMBER => '1',
		GITHUB_SERVER_URL => 'https://github.com',
		GITHUB_SHA => $sha,
	};
}

# _build_base_env
# Purpose:     Write event.json and build the environment every job starts
#              with, as a GitHub-hosted runner would give it.
# Entry:       None; temp_path must exist.
# Exit status: Returns nothing.
# Side effects: Writes event.json; sets event and base_env.
sub _build_base_env {
	my ($self) = @_;

	my $github = $self->_repository_env;

	$self->{event} = {
		repository => {
			full_name => $github->{GITHUB_REPOSITORY},
			name => (split m{/}, $github->{GITHUB_REPOSITORY})[-1],
			owner => { login => $github->{GITHUB_REPOSITORY_OWNER} },
		},
		ref => $github->{GITHUB_REF},
		after => $github->{GITHUB_SHA},
		before => '0' x 40,
		pusher => { name => $github->{GITHUB_ACTOR} },
	};

	my $event_path = "$self->{temp_path}/event.json";
	write_container_file($event_path, JSON::PP->new->canonical->encode($self->{event}), 'event.json');
	{
		no autodie qw(chmod);
		chmod($self->{share_files} ? oct('0644') : oct('0600'), $event_path);
	}

	$self->{base_env} = {
		%{$github},
		CI => 'true',
		DEBIAN_FRONTEND => 'noninteractive',
		GITHUB_ACTIONS => 'true',
		# The step-specific variables exist from the start, empty, as on GitHub.
		(map { $_ => '' } qw(GITHUB_ACTION GITHUB_BASE_REF GITHUB_ENV GITHUB_HEAD_REF GITHUB_JOB
			GITHUB_OUTPUT GITHUB_PATH GITHUB_STATE GITHUB_STEP_SUMMARY GITHUB_TOKEN)),
		GITHUB_EVENT_PATH => '/github/actions-runner/event.json',
		GITHUB_WORKFLOW => $self->{workflow}->name,
		GITHUB_WORKSPACE => '/github/workspace',
		HOME => defined $self->{user} ? '/github/actions-runner/home' : '/root',
		RUNNER_ARCH => $RUNNER_CONTEXT{arch},
		RUNNER_NAME => $RUNNER_CONTEXT{name},
		RUNNER_OS => $RUNNER_CONTEXT{os},
		RUNNER_TEMP => $RUNNER_CONTEXT{temp},
		RUNNER_TOOL_CACHE => $RUNNER_CONTEXT{tool_cache},
		RUNNER_WORKSPACE => '/github',
		($self->{verbose} ? (RUNNER_DEBUG => '1', ACTIONS_STEP_DEBUG => 'true') : ()),
	};

	return;
}

# _git
# Purpose:     Ask git about the project.
# Entry:       @args - git's arguments.
# Exit status: Returns its output, or '' when git fails or is absent.
# Side effects: Runs git (not fork plus a piped open, which Windows does not
#              reliably support).
sub _git {
	my ($self, @args) = @_;

	my ($output) = App::Actions::Process::capture([ 'git', '-C', $self->{project_dir}, @args ], quiet_stderr => 1);

	return defined $output ? $output : '';
}

# _run_groups
# Purpose:     Run every selected job, each after the jobs it needs.
# Entry:       None; _select_jobs has run.
# Exit status: Returns a hash reference of job id to its group result.
# Side effects: Runs the jobs.
sub _run_groups {
	my ($self) = @_;

	my $graph = { results => {}, visited => {}, running => {} };
	$self->_run_base_job($_, $graph) for @{ $self->{job_order} };

	return $graph->{results};
}

# _run_base_job
# Purpose:     Run one job id - every matrix instance of it - after the jobs
#              it needs, deciding each instance's condition first.
# Entry:       $base_id; $graph - results, visited and running sets.
# Exit status: Returns { result, outputs, instances }; throws on a cycle.
# Side effects: Runs the instances, in parallel where it can; records them
#              in the report.
sub _run_base_job {
	my ($self, $base_id, $graph) = @_;

	return $graph->{results}{$base_id} if $graph->{visited}{$base_id};
	$self->throw('runner.dependency_cycle', { job => $base_id }) if $graph->{running}{$base_id};

	my $instances = $self->{job_groups}{$base_id};
	$self->throw('runner.unknown_job', { job => $base_id }) unless $instances && @{$instances};
	$graph->{running}{$base_id} = 1;

	# The jobs this one needs run first; one that was not selected is
	# assumed to have succeeded, and the user is told so.
	my @needs = @{ $instances->[0]{needs} || [] };
	$self->_run_base_job($_, $graph) for grep { exists $self->{job_groups}{$_} } @needs;
	my %need_results;
	for my $need (@needs) {
		$self->_complain('runner.need_not_selected', { job => $base_id, need => $need }) unless exists $graph->{results}{$need};
		$need_results{$need} = $graph->{results}{$need} || { result => 'success', outputs => {} };
	}
	my $needs_failed = (grep { $_->{result} ne 'success' } values %need_results) ? 1 : 0;

	my $strategy = $instances->[0]{strategy} || {};
	my $fail_fast = exists $strategy->{'fail-fast'} ? _truthy_scalar($strategy->{'fail-fast'}) : 1;

	# Every instance is planned before any runs: in parallel the runnable
	# ones start together, so their conditions are decided first.
	my $group = { result => 'skipped', stop => 0 };
	my @runnable = grep { $self->_admit($_, \%need_results, $group) }
		map { $self->_plan_instance($_, \%need_results, $needs_failed, $fail_fast) } @{$instances};

	# An instance fail-fast stopped from starting is reported as skipped,
	# whichever way the group ran.
	my $outcomes = $self->_runs_in_parallel ? $self->_parallel->run(\@runnable, $fail_fast) : undef;
	if ($outcomes) {
		for my $outcome (@{$outcomes}) {
			if ($outcome->{started}) {
				$self->_record_instance_result($outcome->{plan}, $outcome->{result}, $group);
			} else {
				$self->_skip_fail_fast($outcome->{plan});
			}
		}
	} else {
		for my $plan (@runnable) {
			if ($group->{stop}) {
				$self->_skip_fail_fast($plan);
			} else {
				$self->_record_instance_result($plan, $self->_run_instance($plan->{instance}, $plan->{context}), $group);
			}
		}
	}

	my $entry = { result => $group->{result}, outputs => {}, instances => $instances };
	$graph->{results}{$base_id} = $entry;
	$graph->{visited}{$base_id} = 1;
	delete $graph->{running}{$base_id};

	return $entry;
}

# _admit
# Purpose:     Decide whether a planned instance runs, reporting the ones
#              that do not.
# Entry:       $plan; $need_results; $group - the group's result so far.
# Exit status: Returns 1 for a plan that runs, 0 otherwise.
# Side effects: Prints and records skipped and failed conditions; a
#              condition that fails to evaluate fails the workflow.
sub _admit {
	my ($self, $plan, $need_results, $group) = @_;

	my $name = $plan->{instance}{display_name};
	if (defined $plan->{error}) {
		$self->_complain('runner.job.if_failed', { name => $plan->{display_name}, error => $plan->{error} });
		$group->{result} = 'failure';
		$self->{report}->record($name, 'failure')->fail;
	} elsif (!$plan->{should_run}) {
		$self->_say($self->i18n('runner.job.skipped', { name => $plan->{display_name} }));
		$self->{report}->record($name, 'skipped');
	} else {
		$plan->{instance}{needs_results} = $need_results;
	}

	return (!defined $plan->{error} && $plan->{should_run}) ? 1 : 0;
}

# _skip_fail_fast
# Purpose:     Report an instance fail-fast stopped from starting.
# Entry:       $plan.
# Exit status: Returns nothing.
# Side effects: Prints; records it as skipped.
sub _skip_fail_fast {
	my ($self, $plan) = @_;

	$self->_say($self->i18n('runner.job.fail_fast', { name => $plan->{display_name} }));
	$self->{report}->record($plan->{instance}{display_name}, 'skipped');

	return;
}

# _runs_in_parallel
# Purpose:     Whether this run may start jobs beside each other.  A run that
#              keeps its containers has to name them, which only the process
#              that started them can do, and a dry run or an explain run is a
#              report whose blocks belong in one order.
# Entry:       None.
# Exit status: Returns 1 or 0.
# Side effects: None.
sub _runs_in_parallel {
	my ($self) = @_;

	return ($self->{parallel} > 1 && !$self->{keep} && !$self->{dry_run} && !$self->{explain}) ? 1 : 0;
}

# _parallel
# Purpose:     The run's parallel scheduler, made when first needed, once the
#              temporary directory exists.
# Entry:       None.
# Exit status: Returns an App::Actions::Runner::Parallel.
# Side effects: Creates it on first use.
sub _parallel {
	my ($self) = @_;

	weaken(my $weak = $self);

	return $self->{parallel_runner} ||= App::Actions::Runner::Parallel->new(
		capacity => $self->{parallel},
		temp_path => $self->{temp_path},
		quiet => $self->{quiet},
		logger => $self->{logger},
		# In the child: its own runner directory and base environment, and
		# the images it pulled and used, so the parent can remove them if it
		# must and the record of kept images hears of both.
		run_job => sub {
			my ($entry) = @_;
			$weak->_prepare_temp($entry->{temp});
			$weak->_build_base_env;
			my $result = $weak->_run_instance($entry->{plan}{instance}, $entry->{plan}{context});
			$result->{pulled} = $weak->{images}->pulled;
			$result->{used} = $weak->{images}->used;
			return $result;
		},
		on_result => sub {
			$weak->{images}->note_pulled(@{ $_[0]{pulled} || [] });
			$weak->{images}->note_used(@{ $_[0]{used} || [] });
		},
	);
}

# _plan_instance
# Purpose:     Decide whether one matrix instance runs, and with what context.
# Entry:       $instance; $need_results; $needs_failed; $fail_fast.
# Exit status: Returns a plan: { instance, display_name, context, status,
#              fail_fast, max_parallel, should_run, error }.
# Side effects: None.
sub _plan_instance {
	my ($self, $instance, $need_results, $needs_failed, $fail_fast) = @_;

	my $status = status_flags($needs_failed);
	my $context = {
		github => $self->_github_context($instance),
		matrix => $instance->{matrix} || {},
		needs => $need_results,
		secrets => $self->{secrets},
		vars => {},
		inputs => {},
		runner => { %RUNNER_CONTEXT },
		strategy => {
			'fail-fast' => $fail_fast,
			'job-index' => $instance->{matrix_index},
			'job-total' => $instance->{matrix_total},
			'max-parallel' => $instance->{strategy}{'max-parallel'},
		},
		env => {},
		job => { status => $needs_failed ? 'failure' : 'success' },
		steps => {},
	};

	my $plan = {
		instance => $instance,
		display_name => redact($self->{docker}, $instance->{display_name}),
		context => $context,
		status => $status,
		fail_fast => $fail_fast,
		max_parallel => $instance->{strategy}{'max-parallel'},
		should_run => $needs_failed ? 0 : 1,
		error => undef,
	};

	# An `if` without a status function gets an implicit success(), so a job
	# whose needs failed is skipped unless its condition says otherwise.
	if (defined $instance->{if}) {
		my $condition = eval { $self->{expression}->condition($instance->{if}, $context, $status) };
		if (defined $condition) {
			$plan->{should_run} = ($condition && $needs_failed && !has_status_function($instance->{if})) ? 0 : $condition;
		} else {
			$plan->{error} = trim_error($@);
			$plan->{error} = '' unless defined $plan->{error};
		}
	}

	return $plan;
}

# _record_instance_result
# Purpose:     Record what one instance's run means for its group: whether it
#              failed, the summary line, and whether fail-fast stops the rest.
# Entry:       $plan; $result - { result => ... }; $group - result and stop.
# Exit status: Returns nothing.
# Side effects: Updates the group and the report; prints a continued failure.
sub _record_instance_result {
	my ($self, $plan, $result, $group) = @_;

	my $instance = $plan->{instance};
	my $continue = 0;
	if (defined $instance->{'continue-on-error'}) {
		$continue = eval { boolean_value($self->{expression}, $instance->{'continue-on-error'}, $plan->{context}, status_flags(0)) };
		$self->_complain('runner.job.continue_failed', { name => $plan->{display_name}, error => trim_error($@) })
			unless defined $continue;
	}

	my $report = $self->{report}->record($instance->{display_name}, $result->{result});
	if ($result->{result} eq 'failure') {
		$group->{result} = 'failure';
		# On GitHub an instance that may fail does not cancel the rest of its
		# matrix: continue-on-error applies to the job, fail-fast to the
		# others, and the first wins for this one.
		$group->{stop} = 1 if $plan->{fail_fast} && !$continue;
		$continue ? $self->_say($self->i18n('runner.job.continued', { name => $plan->{display_name} })) : $report->fail;
	} elsif ($result->{result} eq 'success' && $group->{result} eq 'skipped') {
		$group->{result} = 'success';
	}

	return;
}

# _run_instance
# Purpose:     Run one job instance: check its images, start its network,
#              services and container, run its steps, and clean up.
# Entry:       $job - the instance; $context - its expression context.
# Exit status: Returns { result => success | failure | skipped, ... };
#              throws an infrastructure failure after cleaning up.
# Side effects: Pulls images; starts and removes containers; prints progress.
sub _run_instance {
	my ($self, $job, $context) = @_;

	my $display_name = redact($self->{docker}, $job->{display_name});
	my $runs_on = $self->{workflow}->runs_on_text($job->{'runs-on'}, $job->{matrix} || {});

	if (!$self->{workflow}->is_linux_runner($runs_on)) {
		$self->_say($self->i18n('runner.job.not_linux', { name => $display_name, runs_on => $runs_on }));
		return { result => 'skipped', reason => $self->i18n('runner.job.unsupported_runner', { runs_on => $runs_on }) };
	}

	$self->_say("\n" . $self->i18n('runner.job.start', { name => $display_name }));

	# The preflight could not name an image that comes from another job's
	# output; now that the job's values exist, the images are resolved and
	# prepared before its network or containers, so a bad image stops the
	# run before the job starts rather than halfway through it.
	my $job_images = $self->{images}->prepare_job($job, $context);
	my $image = $job_images->{image};
	$self->throw('runner.job.no_image', { name => $display_name }) unless defined $image && $image =~ /\S/;

	$self->_say($self->i18n('runner.job.image', { image => $image }));
	$self->_say($self->i18n('runner.job.deferred', $_)) for @{ $job_images->{deferred} };

	my $containers = $self->{containers};
	my ($network, @started, $result);
	my $ran = eval {
		$network = $containers->create_network($job);
		my $services = $containers->start_services($job, $network, $context, \@started);

		my $job_env = resolve_env($self->{expression}, [
			$self->{base_env},
			$self->{workflow}->env,
			$job->{env},
			(ref $job->{container} eq 'HASH' ? $job->{container}{env} : undef),
			$self->{env},
		], $context);
		$job_env->{GITHUB_JOB} = $job->{base_id};
		$job_env->{GITHUB_WORKSPACE} = '/github/workspace';

		my $container = $containers->start_job($job, $network, $job_env, $context, $image, $self->{temp_path});
		push @started, $container;

		$result = App::Actions::Runner::Steps->new(
			(map { $_ => $self->{$_} } qw(expression docker images containers workflow project_dir temp_path
				user share_files quiet verbose dry_run strict_actions logger)),
			job => $job,
			container => $container,
			network => $network,
			facts => $containers->inspect($container),
			job_env => $job_env,
			context => $context,
		)->run;

		# A service that restarted during the run is not the one the steps
		# talked to, so the job fails as an infrastructure fault rather than
		# passing with a container its restart policy kept alive.
		$containers->check_services($services);
		1;
	};
	my $error = $ran ? undef : $@;

	$containers->cleanup_job($network, \@started) if defined $network;
	die $error if defined $error;

	return $result;
}

# _github_context
# Purpose:     The github.* context for a job.  Before the run has built its
#              base environment, the values derived from the checkout are
#              still enough to resolve github.ref and friends.
# Entry:       $job - an instance, or a job id.
# Exit status: Returns a hash reference.
# Side effects: May run git (once).
sub _github_context {
	my ($self, $job) = @_;

	my $env = $self->{base_env} || $self->_repository_env;

	return {
		event_name => $env->{GITHUB_EVENT_NAME},
		event => $self->{event} || {},
		event_path => '/github/actions-runner/event.json',
		ref => $env->{GITHUB_REF},
		ref_name => $env->{GITHUB_REF_NAME},
		ref_type => $env->{GITHUB_REF_TYPE},
		sha => $env->{GITHUB_SHA},
		repository => $env->{GITHUB_REPOSITORY},
		repository_owner => $env->{GITHUB_REPOSITORY_OWNER},
		workflow => $self->{workflow}->name,
		job => ref $job eq 'HASH' ? $job->{base_id} : $job,
		run_id => $env->{GITHUB_RUN_ID},
		run_number => $env->{GITHUB_RUN_NUMBER},
		run_attempt => $env->{GITHUB_RUN_ATTEMPT},
		actor => $env->{GITHUB_ACTOR},
		server_url => $env->{GITHUB_SERVER_URL},
		api_url => $env->{GITHUB_API_URL},
		graphql_url => $env->{GITHUB_GRAPHQL_URL},
		workspace => '/github/workspace',
		token => '',
		head_ref => '',
		base_ref => '',
	};
}

# _preflight_context
# Purpose:     The values known before the run.  github.* is resolved as the
#              run will resolve it; needs.* is not, because those outputs
#              belong to jobs that have not run, so the job checks its images
#              again when they have.
# Entry:       $instance.
# Exit status: Returns an expression context.
# Side effects: May run git (once).
sub _preflight_context {
	my ($self, $instance) = @_;

	return {
		matrix => $instance->{matrix} || {},
		env => { %{ $self->{env} } },
		secrets => $self->{secrets},
		vars => {},
		inputs => {},
		steps => {},
		needs => {},
		job => { status => 'success' },
		github => $self->_github_context($instance),
		strategy => { 'job-index' => $instance->{matrix_index}, 'job-total' => $instance->{matrix_total} },
		runner => { %RUNNER_CONTEXT },
	};
}

# _cleanup
# Purpose:     Remove what the run created, once: its containers and
#              networks, the images it pulled when it is not keeping them,
#              and its temporary directory - or, with keep, list them.
# Entry:       None.
# Exit status: Returns nothing.
# Side effects: Records cached images; keeps the parallel logs; removes
#              Docker resources and files; prints what was kept.
sub _cleanup {
	my ($self) = @_;

	return if $self->{cleaned_up}++;

	$self->{images}->remember($self->{cache_file}) if $self->{keep_images};
	my $report = $self->{report};
	$report->keep_logs($self->{parallel_runner}->logs, $self->_log_root, $self->{run_id}) if $self->{parallel_runner};

	if ($self->{keep}) {
		$report->print_kept_resources($self->{containers}->remaining, $self->{temp_path});
		return;
	}

	$self->{containers}->remove_all;
	if (!$self->{keep_images}) {
		$self->{docker}->image_remove($_) for @{ $self->{images}->pulled };
	}
	eval { remove_tree($self->{temp_path}) } if $self->{temp_path} && -d $self->{temp_path};
	$report->print_kept_logs;

	return;
}

# _log_root
# Purpose:     Where a parallel run's logs go: log_dir, else
#              App::Actions::Logs' default (ACTION_RUN_LOG_DIR or the per-user
#              cache), so `action-run logs` reads the directory a run wrote to.
# Entry:       None.
# Exit status: Returns a directory path.
# Side effects: None.
sub _log_root {
	my ($self) = @_;

	my $dir = $self->{log_dir};

	return (defined $dir && length $dir) ? $dir : App::Actions::Logs->default_directory;
}

# _truthy_scalar
# Purpose:     Read fail-fast: a YAML boolean, or anything but false/no/0.
#              Perl's own false (YAML::PP's, from 5.36) reads as '', and an
#              empty value is false too.
# Entry:       $value.
# Exit status: Returns 1 or 0.
# Side effects: None.
sub _truthy_scalar {
	my ($value) = @_;

	return ref $value ? ($value ? 1 : 0)
		: !defined $value ? 0
		: (!length $value || $value =~ /\A(?:false|no|0)\z/i) ? 0
		: 1;
}

# _say
# Purpose:     Print a progress line unless the run is quiet.
# Entry:       $text - without the newline.
# Exit status: Returns nothing.
# Side effects: Prints to standard output.
sub _say {
	my ($self, $text) = @_;

	print "$text\n" unless $self->{quiet};

	return;
}

# _complain
# Purpose:     Log a warning from the catalogue unless the run is quiet.
# Entry:       $key; $args.
# Exit status: Returns nothing.
# Side effects: Sends the message to the logger (by default, standard error).
sub _complain {
	my ($self, $key, $args) = @_;

	$self->{logger}->warn($self->i18n($key, $args)) unless $self->{quiet};

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

=item * Only Linux C<runs-on> runners are emulated; macOS and Windows jobs are
skipped.

=item * Remote actions are not fetched, and local C<docker> actions are not
built.  Checkout, setup-perl, cache, artifact and Codecov actions are no-ops;
other actions are skipped with a warning unless C<strict_actions> is set.
Local composite and JavaScript actions are run; JavaScript actions need
C<node> in the job image.

=item * Job outputs, C<needs.*.outputs>, C<timeout-minutes> and
C<hashFiles()> are not implemented.

=item * The runner object is not reusable: a second C<run> after the first
has cleaned up starts with the first one's state.  Build a new runner, as
L<App::Actions> does for every call.

=item * The run's state is still shared between the planner and its parts
through the option values they are built with; a part is not given the whole
runner, but a change of option after construction is not seen by the parts.

=item * A workflow is trusted as GitHub trusts it.  Its C<container.volumes>
and C<container.options> can mount any host path the Docker daemon can
reach, and its steps run with the daemon's privileges.  Run only workflows
from repositories you trust.

=item * With C<user> set to anyone but yourself or root, the runner
directory is made writable by every user of the host (sticky, so nobody can
replace another's files), and the step scripts in it, secrets included, are
readable by them; a warning says so.  With rootless Docker, a C<user> that
is your own uid inside the container maps to another uid on the host, and
the job may then be unable to write its files.

=item * Taint mode (C<-T>) is not supported.  F<action-run> runs with its
user's own privileges, so taint checks would protect nothing that user
could not already do; the environment, directory listings and C<PATH>
lookups it relies on would all fail them.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Make a new runner for each run.>  A runner is not reusable: a
second L</run> starts with the state the first left behind.

=item * B<C<project_dir> must exist.>  It is mounted into every job
container.

=item * B<Options are fixed when the runner is made.>  The parts copy them,
so changing an option afterwards has no effect.

=item * B<C<run> reports failures by status, not by exception.>  Errors of
the run are printed as C<action-run: MESSAGE> and give status 2.

=item * B<Ctrl-C still cleans up.>  SIGINT and SIGTERM stop the run, but the
containers and networks are removed first.  Press Ctrl-C again only if the
clean-up itself hangs.

=item * B<C<keep> keeps everything.>  With C<keep>, containers and networks
are left running for you to inspect; remove them yourself afterwards (their
names start with C<action-run->).

=item * B<C<parallel> is ignored with C<keep>>, on Windows, and where
C<fork> does not work; jobs then run one at a time.

=item * B<C<user> other than yourself or root opens the runner folder to
all users.>  See L</LIMITATIONS>.

=back

=head1 ENCODING

Text from the workflow (commands, names, environment values, secrets) is
handled as Perl character strings and passed to Docker as UTF-8 bytes, so
non-ASCII characters and emoji work in step commands and values.  Step
scripts are written as UTF-8 with LF line endings.  Paths (the project
folder, the temporary folder) are used as bytes, as your system stores them.
Output from the containers is passed to your terminal as bytes, unchanged.
Messages from the runner itself are in the language of L<App::Actions::I18N>;
non-English messages contain non-ASCII characters.

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

	┌─ NewRunner ───────────────────────────────────────
	│ workflow?    : WORKFLOW
	│ projectDir?  : PATH
	│ options?     : OPTION ⇸ VALUE
	│ r!           : Runner
	├───────────────────────────────────────────────────
	│ dom options? ⊆ dom optionRules
	│ isDirectory(projectDir?)
	│ ¬ (options?(pull) ∧ options?(no_pull))
	│ r!.pullConcurrency =
	│     first(options?(pull_concurrency), env(ACTION_RUN_PULL_CONCURRENCY), 4) ∈ ℕ₁
	│ r!.parallel = (if options?(parallel) ∈ ℕ₁ then options?(parallel) else 1)
	│ r!.dryRun = options?(dry_run) ∨ options?(explain)
	│ r!.keepImages = (if options?(keep_images) = ⊥ then true else options?(keep_images))
	│ r!.logger = (if options?(logger) = ⊥ then stderrLogger else options?(logger))
	│ ∀ part : {images, containers, steps, parallel, report} • part.logger = r!.logger
	└───────────────────────────────────────────────────

=head2 option_rules

	┌─ OptionRules ─────────────────────────────────────
	│ rules! : OPTION ⇸ RULE
	├───────────────────────────────────────────────────
	│ rules! = optionRules
	└───────────────────────────────────────────────────

=head2 json_schema

	┌─ JsonSchema ──────────────────────────────────────
	│ schema! : JSON
	├───────────────────────────────────────────────────
	│ schema! = decode(JSON_SCHEMA) ∧ schema!.version = PREFLIGHT_SCHEMA_VERSION
	└───────────────────────────────────────────────────

=head2 preflight_schema_version

	┌─ PreflightSchemaVersion ──────────────────────────
	│ v! : ℕ₁
	├───────────────────────────────────────────────────
	│ v! = PREFLIGHT_SCHEMA_VERSION
	└───────────────────────────────────────────────────

=head2 workflow

	┌─ Workflow ────────────────────────────────────────
	│ ΞRunner
	│ w! : WORKFLOW
	├───────────────────────────────────────────────────
	│ w! = workflow
	└───────────────────────────────────────────────────

=head2 list_jobs

	┌─ ListJobs ────────────────────────────────────────
	│ ΞRunner
	│ out! : seq LINE
	│ exit! : ℤ
	├───────────────────────────────────────────────────
	│ out! = ⟨ j : selected(expand(workflow)) • j.base_id ⁀ TAB ⁀ redact(j.display_name) ⟩
	│ exit! = 0
	└───────────────────────────────────────────────────

=head2 run

	┌─ Run ─────────────────────────────────────────────
	│ ΔRunner
	│ exit! : {0, 1, 2}
	├───────────────────────────────────────────────────
	│ raised ⇒ exit! = 2
	│ ¬ raised ∧ report.failed' ⇒ exit! = 1
	│ ¬ raised ∧ ¬ report.failed' ⇒ exit! = 0
	│ cleanedUp'
	└───────────────────────────────────────────────────

=head2 preflight

	┌─ Preflight ───────────────────────────────────────
	│ ΔRunner
	│ json? : 𝔹
	│ r!    : RESULT
	├───────────────────────────────────────────────────
	│ r!.summary.ready ⇔ checksPassed ∧ (∀ i : r!.summary.images • i.status ≠ failed)
	│ r!.exit = (if r!.summary.ready then 0 else 2)
	│ json? ⇒ valid(r!.summary, JsonSchema)
	│ ¬ checksPassed ⇒ ∀ i : r!.summary.images • i.status = skipped
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The runner is used once.  These are the states of one L</run> (L</preflight>
stops after PREPARING IMAGES; a dry run prints the Docker commands instead
of running them):

	  new(workflow, project_dir, %options)
	        |   options checked, parts built from copies of the options
	        v
	  +-----------+  run / preflight
	  |  CREATED  |-----------------+
	  +-----------+                 |
	                                v
	                       +-----------------+  SIGINT / SIGTERM at any later
	                       | SELECTING JOBS  |  point -> error "Interrupted" ->
	                       | expand matrix;  |  CLEANING UP; status 2
	                       | jobs filter;    |
	                       | non-Linux: skip |
	                       +-----------------+
	                                |
	                                v
	                       +-----------------+  daemon / Linux / mount problem
	                       | CHECKING HOST   |  -> report printed -> FAILED (2)
	                       | (skip_check:    |
	                       |  skipped)       |
	                       +-----------------+
	                                |
	                                v
	                       +-----------------+  a pull fails -> FAILED (2)
	                       | PREPARING IMAGES|  preflight: return here
	                       | (Images part)   |  { exit, summary, error }
	                       +-----------------+
	                                |
	                                v
	                       +-----------------+  needs cycle -> FAILED (2)
	                       | ORDERING JOBS   |
	                       | by needs        |
	                       +-----------------+
	                                |
	                                v
	           +---------> +-----------------+
	           |           | NEXT GROUP      |  jobs whose needs are done
	           |           +-----------------+
	           |              |           |
	           |   if: false, |           | one job, or a matrix with
	           |   or a need  |           | parallel = 1
	           |   failed:    |           v
	           |   SKIPPED    |   +----------------+    a matrix with parallel > 1:
	           |              |   | RUNNING JOB    |    Parallel part forks one
	           |              |   | Containers:    |    child per job, up to
	           |              |   |   network,     |    "parallel" at once; each
	           |              |   |   services,    |    child does RUNNING JOB;
	           |              |   |   job container|    output goes to log files
	           |              |   | Steps: each    |
	           |              |   |   step         |
	           |              |   | Containers:    |
	           |              |   |   remove       |
	           |              |   +----------------+
	           |              |           |
	           |              +-----+-----+  job passed / failed / skipped
	           |                    |
	           +---- more groups ---+
	                                | no more
	                                v
	                       +-----------------+
	                       | REPORTING       |  summary table (Report part);
	                       +-----------------+  logs kept for parallel jobs
	                                |
	                                v
	                       +-----------------+  containers, networks; images
	                       | CLEANING UP     |  this run pulled (unless
	                       |                 |  keep_images); temporary folder
	                       +-----------------+  (all skipped with keep)
	                                |
	                                v
	              status 0 (all passed), 1 (a job failed), 2 (FAILED)

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
