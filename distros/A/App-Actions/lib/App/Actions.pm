package App::Actions;

use strict;
use warnings;
use utf8;
use autodie qw(:all);

use Cwd qw(abs_path);
use Log::Abstraction ();
use Readonly;
use Scalar::Util qw(blessed);

use App::Actions::Cache;
use App::Actions::Check;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Logs;
use App::Actions::Runner;
use App::Actions::Runner::Support qw(default_logger null_logger);
use App::Actions::Workflow;

use Object::Configure;

use Sub::Private ();
use Sub::Protected ();

use App::Actions::Access;

# The options a run is configured with, and the Params::Validate::Strict rule
# of each.  new() accepts them, run(), preflight() and list_jobs() accept them
# again as overrides, and every one is handed to App::Actions::Runner under
# the same name.  The table is the runner's own, so an option cannot be
# accepted here and silently dropped on its way there, which is what had
# happened to cache_file.
Readonly::Hash my %OPTION_RULES => %{ App::Actions::Runner->option_rules };
Readonly::Array my @RUNNER_OPTIONS => sort keys %OPTION_RULES;

# The machine-readable documents, in the order the error message lists them,
# and the module whose json_schema describes each.
Readonly::Array my @DOCUMENTS => qw(check preflight cache logs);
Readonly::Hash my %DOCUMENT_OWNER => (
	check => 'App::Actions::Check',
	preflight => 'App::Actions::Runner',
	cache => 'App::Actions::Cache',
	logs => 'App::Actions::Logs',
);

# Where a workflow lives inside a repository, so the repository root can be
# found from the workflow's own path.
Readonly::Scalar my $WORKFLOW_IN_REPOSITORY => qr{\A(.*)/\.github/workflows/[^/]+\z}s;

# The options list_jobs forces: listing never starts anything or prints
# anything but the list.
Readonly::Hash my %LIST_OPTIONS => (dry_run => 1, quiet => 1);

# Object::Configure's word for "no logging".
Readonly::Scalar my $NO_LOGGER => 'NULL';

=head1 NAME

App::Actions - run GitHub Actions workflows locally

=head1 VERSION

0.002.0

=cut

our $VERSION = '0.002.0';

=head1 SYNOPSIS

Run every job of a workflow (this is what C<action-run run> does):

	use App::Actions;

	my $actions = App::Actions->new(
		workflow_file => "$ENV{HOME}/src/CGI-Info/.github/workflows/perl-ci.yml",
		project_dir   => "$ENV{HOME}/src/CGI-Info",
	);

	exit $actions->run();    # 0 = passed, 1 = a job failed, 2 = could not run

Run one job, with a secret, and show the Docker commands:

	my $actions = App::Actions->new(
		workflow_file => '.github/workflows/ci.yml',
		jobs          => [ 'test' ],
		secrets       => { CODECOV_TOKEN => $ENV{CODECOV_TOKEN} },
		verbose       => 1,
	);
	exit $actions->run;

See what would run, without running it:

	App::Actions->new(workflow_file => '.github/workflows/ci.yml')->list_jobs;
	exit App::Actions->new(workflow_file => '.github/workflows/ci.yml', dry_run => 1)->run;

Check Docker and download the images first, for a CI job:

	use JSON::PP;

	my $result = App::Actions->new(workflow_file => '.github/workflows/ci.yml')->preflight(json => 1);
	print JSON::PP->new->canonical->encode($result->{summary}), "\n";
	exit $result->{exit};

Run the jobs of a matrix four at a time, and keep their logs:

	App::Actions->new(workflow_file => '.github/workflows/ci.yml', parallel => 4)->run;
	# logs: see "action-run logs"

Set an option for every run on this computer, without changing the code
(see L</new> for where the file may live; the environment wins over it):

	# ~/.conf/local.yaml
	---
	App__Actions:
	  keep_images: 0

	# or, for one command:  App__Actions__keep_images=0 action-run ci.yml .

Collect the warnings and errors instead of printing them, or turn them off:

	my @messages;
	my $exit = App::Actions->new(workflow_file => 'ci.yml', logger => \@messages)->run;
	print "$_->{level}: $_->{message}\n" for @messages;

	App::Actions->new(workflow_file => 'ci.yml', logger => 'NULL')->run;

=head1 DESCRIPTION

B<In short:> this module runs a GitHub Actions workflow on your own
computer, in Docker containers, so you can test and debug it without
pushing to GitHub.  Most people use it through the C<action-run> command;
see L<action-run>.

How it works, in brief:

=over 4

=item 1. It reads the workflow file (L<App::Actions::Workflow>) and expands
each job's matrix.

=item 2. It checks that Docker works and can see your project (as
C<action-run check> does).

=item 3. It downloads the images the jobs need, several at a time.

=item 4. For each job, it makes a private Docker network, starts the job's
service containers (for example a database), and starts one long-lived
container for the job, with your project mounted in it.

=item 5. It runs each step in that container with C<docker exec>.  Files and
installed modules stay between steps, as on GitHub.

=item 6. It removes the job's containers and network, and reports the
result.

=back

The rest of this section gives the details.

App::Actions runs a GitHub Actions workflow on a local machine using Docker
containers, allowing troublesome issues to be more easily debugged.
It understands the parts of a workflow that are useful for local
testing: jobs, matrix expansion, container images, service containers,
environment files, working directories, shells, and C<if> conditions.

Each job gets a private Docker network, its own service containers, and a
long-lived job container.  Steps are executed in that container with
C<docker exec>, so files and installed modules persist between steps.  A
service must stay up: one that stops, or that a restart policy keeps bringing
back, stops the run with the state and restart count the daemon reports and
the last lines the container printed.  A container the daemon refuses to start
is reported the same way: its message is quoted and the image, entrypoint or
published port it names is called out, because there is nothing of the
container's own to quote.  When a job finishes, its containers and network are
removed; the images the run pulled are kept, as the next run's cache, unless
C<keep_images> is set to a false value.  The C<GITHUB_ENV>, C<GITHUB_PATH>,
C<GITHUB_OUTPUT>, C<GITHUB_STATE>, and C<GITHUB_STEP_SUMMARY> files written by
steps are honoured.  If an image has no C<sudo> and the container is running
as root, a small C<sudo> shim is placed on C<PATH> so that steps such as
C<sudo apt update> work locally.

The host may run UNIX or Windows; only the containers are Linux.  Command
output is captured without C<fork> or a piped C<open>, and paths, volumes and
permissions are handled in a platform-neutral way, so the same code and test
suite run on both.  Step scripts, the C<sudo> and C<apt> shims, and
C<event.json> are written with LF line endings, which is what the container's
shell expects.  Arguments are quoted for the Windows command line by
L<App::Actions::Process> itself, because Perl's own Windows quoting gives up
on any argument containing a double quote and the C runtime then splits it at
its spaces.

Run C<action-run check> to diagnose the host before running a workflow.  It
reports the platform, the Docker client and daemon versions, whether the
daemon runs Linux containers, and whether Docker can bind-mount a temporary
directory and the project directory.  Each problem it finds is followed by the
step that fixes it, such as starting Docker Desktop, switching it to Linux
containers, or sharing the drive that holds the project.  See L<action-run>
for the details.

Errors raised by this module, L<App::Actions::Workflow> and
L<App::Actions::Action> come from the catalogue in L<App::Actions::I18N>.
They are in English unless C<ACTION_RUN_LANG> names another catalogue
(C<fr>, C<de> or C<zh>).

=head1 METHODS

=head2 new

Creates the object that runs one workflow.

=head3 ARGUMENTS

=over 4

=item * C<workflow_file> - required; the path of the workflow.

=item * C<project_dir> - the repository the workflow runs against.  It may
be omitted when the workflow is inside a repository's C<.github/workflows>
directory; the repository root is then used.

=item * Run options: C<jobs>, C<image>, C<perl_image>, C<platform>, C<user>,
C<env>, C<secrets>, C<dry_run>, C<explain>, C<verbose>, C<quiet>, C<keep>,
C<keep_images>, C<pull>, C<no_pull>, C<strict_actions>, C<skip_check>,
C<pull_concurrency>, C<parallel>, C<log_dir>, C<cache_file>, C<docker>, and
C<docker_bin>.  Any other key is an error.

=item * C<logger> - where warnings and errors go: a L<Log::Abstraction>
object, an array reference to collect them in, a hash reference of
L<Log::Abstraction> options (for example C<{ file =E<gt> $path }>), or the
string C<'NULL'> to throw them away.  By default they are printed to standard
error.

=back

C<parallel> says how many jobs of one matrix may run at the same time; it is
1 unless it is set, and C<action-run> sets it to the number of processors
unless C<--parallel> says otherwise.  C<pull_concurrency> says how many images
may be pulled at the same time; it defaults to C<ACTION_RUN_PULL_CONCURRENCY>
from the environment, and to four when that is not set or empty.  It must be
a positive integer.  C<keep_images> defaults to true: the images a run pulls
stay behind as the next run's cache, and a false value removes the ones the
run itself pulled when it finishes.  The kept images are recorded by
L<App::Actions::Cache>, which is what C<action-run cache> lists and
C<action-run cache --prune> removes; the record lives in the user's cache
directory, and C<cache_file> or C<ACTION_RUN_CACHE_FILE> moves it.
C<log_dir> says where the per-job logs of a parallel run are kept; it
defaults to C<ACTION_RUN_LOG_DIR>, then to C<action-run/logs> under that same
cache directory.  C<action-run logs> reads that directory, with the sizes and
ages of the logs, C<action-run logs --json> prints them, with the clock their
ages are measured from, as a versioned document, and
C<action-run logs --prune> removes them.  C<--older-than> filters that listing,
and with C<--prune> removes only logs at least that old; a log is selected on
its own modification time, so newer logs in the same run stay.

C<explain> is a dry run whose output is the containers rather than the Docker
commands: nothing is started and no daemon is contacted, and one block per
container says what it would be told to run, which is how a service that stops
on start-up can be diagnosed without running it.

Before any job starts, the environment is probed exactly as C<action-run>
C<check> does: the daemon must be reachable and run Linux containers, and the
project directory must be readable through a bind mount.  The probe uses the
image the first runnable job will use, so a working setup needs no extra pull.
It says nothing when it passes and prints the full report, with remedies, when
it does not, in which case no container is started.  C<skip_check> starts the
workflow anyway, and is what C<action-run --skip-check> sets.

The images the run needs are then prepared before the first container:
job images, service images and C<docker://> action images, with matrix values
resolved.  A missing image is pulled at that point, so a mistyped image is
reported before any job has started rather than halfway through one.  Local
composite actions are read up front for the same reason, including actions
used inside other actions, so an image named within one is known before its
first step; only an image whose name the run alone can resolve is left until
it is used.  Presence is checked first, then the missing images are pulled
C<pull_concurrency> at a time (four by default), so a wide matrix does not sit
through one download after another; a failure is still reported against the
image and the job, service or action that needed it, whichever pull finished
first.

C<pull> refreshes the images even when they are present locally, and each
image is pulled once per run, however many jobs, services or steps use it: the
check a job makes of its own image reuses what the run has already fetched.

C<docker> and C<docker_bin> name the Docker command.  It may also be a wrapper
script; a wrapper written in Perl is run with the current Perl interpreter, so
it works on Windows too, where the operating system cannot start a shebang
script directly.  C<docker> may instead be an object with the
L<App::Actions::Docker> interface, which is how the tests run without one.

B<Configuration files and environment variables.>  After the arguments are
checked, L<Object::Configure> adds settings from two more places.  Both can
set any of the options above, and B<both win over the arguments>:

=over 4

=item 1. Configuration files.  L<Config::Abstraction> looks for files named
F<base.yaml> and then F<local.yaml> (or C<.json>, C<.xml>, C<.ini> and so
on) in the directory C<CONFIG_DIR> names or, when it is not set, in
F<~/.conf>, F<~/config>, F<~/conf> and F<conf>.  The settings for this
module go in a section called C<App__Actions>:

	# ~/.conf/local.yaml
	---
	App__Actions:
	  parallel: 2
	  keep_images: 0

=item 2. Environment variables named C<App__Actions__> and then the option,
which win over everything else:

	App__Actions__parallel=2 App__Actions__quiet=1 action-run ci.yml .

=back

So the order, from weakest to strongest, is: the arguments, then the
configuration files, then the environment variables.  Only top-level options
can be set this way; C<App__Actions__env__NAME> does not add to C<env>.  There
is no argument for naming a configuration file: C<config_file> is refused as
an unknown option.

B<Warnings and errors.>  What a run reports as a problem - a step that
failed, a job that could not run, a container that could not be removed -
goes to a L<Log::Abstraction> logger, at the C<error> or C<warn> level.  The
progress lines, the C<[dry-run]> and Docker command echoes and the job
summary are the run's output, not diagnostics, and stay on standard output.
The default logger prints each message to standard error as a plain line, as
earlier versions did.  A C<logger> in the configuration replaces it: in the
C<App__Actions> section, or in a C<UNIVERSAL> section of F<universal.yaml>,
which L<Object::Configure> applies to every class that uses it.  A C<logger>
argument replaces both.

	# ~/.conf/local.yaml: keep this module's messages in a file
	---
	App__Actions:
	  logger:
	    file: /var/log/action-run.log
	    level: warning

=head3 RETURNS

An C<App::Actions> object.  Besides the options it holds C<logger>, a
L<Log::Abstraction> object (a silent one for C<'NULL'>), and any other
top-level keys found in the configuration files.  Only the options
listed above are passed on to L<App::Actions::Runner>, so the other keys
have no effect.

=head3 SIDE EFFECTS

Reads and parses the workflow file.  Reads the configuration files described
above, if there are any, and the C<App__Actions__*> environment variables.

=head3 EXAMPLE

	# The repository root is found from the workflow's path.
	my $actions = App::Actions->new(
		workflow_file => 'project/.github/workflows/ci.yml',
		jobs          => [ 'test' ],
		dry_run       => 1,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		workflow_file    => { type => 'string', min => 1 },
		project_dir      => { type => 'string', optional => 1 },
		jobs             => { type => 'arrayref', optional => 1 },
		env              => { type => 'hashref', optional => 1 },
		secrets          => { type => 'hashref', optional => 1 },
		docker           => { type => 'object', optional => 1 },
		image            => { type => 'string', optional => 1 },
		perl_image       => { type => 'string', optional => 1 },
		platform         => { type => 'string', optional => 1 },
		user             => { type => 'string', optional => 1 },
		log_dir          => { type => 'string', optional => 1 },
		cache_file       => { type => 'string', optional => 1 },
		docker_bin       => { type => 'string', optional => 1 },
		pull_concurrency => { type => 'string', optional => 1 },
		parallel         => { type => 'string', optional => 1 },
		dry_run          => { type => 'string', optional => 1 },
		explain          => { type => 'string', optional => 1 },
		verbose          => { type => 'string', optional => 1 },
		quiet            => { type => 'string', optional => 1 },
		keep             => { type => 'string', optional => 1 },
		keep_images      => { type => 'string', optional => 1 },
		pull             => { type => 'string', optional => 1 },
		no_pull          => { type => 'string', optional => 1 },
		strict_actions   => { type => 'string', optional => 1 },
		skip_check       => { type => 'string', optional => 1 },
		logger           => { type => [qw(object arrayref hashref string)], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions' }

=head3 MESSAGES

	+-----------------------------------+------------------------------+-------------------------------+
	| Message                           | Meaning                      | Resolution                    |
	+-----------------------------------+------------------------------+-------------------------------+
	| workflow_file is required         | No workflow was named        | Pass workflow_file            |
	| Workflow file 'F' does not exist  | No file at the path          | Check the path                |
	| project_dir is required when the  | The repository root cannot   | Pass project_dir              |
	| workflow is not inside            | be inferred                  |                               |
	| .github/workflows                 |                              |                               |
	| Project directory 'D' does not    | No directory at the path     | Check the path                |
	| exist                             |                              |                               |
	| Invalid arguments to              | An unknown option, or one of | Use the documented options    |
	| App::Actions::new: REASON         | the wrong type               |                               |
	| Object::Configure: config_path    | A configuration file or      | Remove the ".." from that     |
	| contains path traversal           | variable names a path with   | setting                       |
	| sequences: PATH                   | ".." in it                   |                               |
	| Warning: Can't load configuration | A configuration file has a   | Fix the file; the run goes on |
	| from FILE: DETAIL (a warning)     | syntax error                 | without it                    |
	+-----------------------------------+------------------------------+-------------------------------+

The messages of L<App::Actions::Workflow/load> apply to the workflow file.

=head3 PSEUDOCODE

	validate the arguments, refusing unknown options
	make the logger argument into a logger, or use the default (standard error)
	merge in the App__Actions section of the configuration files, then the
	    App__Actions__* environment variables (both win; neither is validated)
	put back the logger made from the argument, or make the configured one
	    into a logger ('NULL' is a silent one)
	refuse a missing workflow_file, then one that does not exist
	take project_dir as given, or the repository root that holds .github/workflows
	refuse a project directory that does not exist
	load the workflow
	return the object holding the paths, the workflow and the options

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		workflow_file => { type => 'string', optional => 1 },
		project_dir => { type => 'string', optional => 1 },
		%OPTION_RULES,
		# Anything Object::Configure turns into a logger: a Log::Abstraction
		# object, an array to collect the messages in, a hash of
		# Log::Abstraction options, or 'NULL' for none.
		logger => { type => [qw(object arrayref hashref string)], optional => 1 },
	});

	# Warnings and errors go through a Log::Abstraction logger.  The default
	# prints them to standard error as plain lines; a logger in the
	# configuration (an App__Actions or UNIVERSAL section) replaces it, and a
	# logger argument replaces both.  Object::Configure would let the
	# configuration replace the argument too (it protects only an array), so
	# the argument is made into a logger here and put back afterwards.
	my $given_logger = defined $params->{logger} ? _logger($params->{logger}) : undef;
	$params->{logger} = $given_logger || default_logger();

	$params = Object::Configure::configure($class, $params);

	$params->{logger} = $given_logger || _logger($params->{logger});

	$class->throw('actions.workflow_file_required') unless defined $params->{workflow_file};

	# abs_path is undef for a path that does not exist on some platforms and
	# the path itself on others, so both outcomes are checked with -f.
	my $workflow_file = abs_path($params->{workflow_file});
	$class->throw('actions.workflow_file_missing', { file => $params->{workflow_file} })
		unless defined $workflow_file && -f $workflow_file;

	my $project_dir = $class->_project_dir($params->{project_dir}, $workflow_file);

	return bless {
		%{$params},
		workflow_file => $workflow_file,
		project_dir => $project_dir,
		workflow => App::Actions::Workflow->load($workflow_file),
		jobs => $params->{jobs} || [],
	}, $class;
}

=head2 workflow, workflow_file, project_dir

	my $workflow = $actions->workflow;         # the App::Actions::Workflow
	my $file     = $actions->workflow_file;    # its absolute path
	my $root     = $actions->project_dir;      # the absolute project directory

Read-only accessors.

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	workflow:                   { type => 'object', isa => 'App::Actions::Workflow' }
	workflow_file, project_dir: { type => 'string' }

=head3 MESSAGES

None.

=head3 EXAMPLE

	printf "%s from %s\n", $actions->workflow->name, $actions->project_dir;

=cut

sub workflow      { return $_[0]->{workflow} }
sub workflow_file { return $_[0]->{workflow_file} }
sub project_dir   { return $_[0]->{project_dir} }

=head2 run

Runs the selected jobs.

=head3 ARGUMENTS

Any of the run options of L</new>, which override the object's for this run
only.

=head3 RETURNS

0 for success, 1 when a job fails, and 2 for a usage, Docker, or other
infrastructure error.

=head3 SIDE EFFECTS

Starts and removes Docker containers and networks, pulls images, writes the
image cache record and, for a parallel run, the job logs; prints the run's
progress unless C<quiet>.

=head3 EXAMPLE

	my $exit = $actions->run(jobs => [ 'lint' ], verbose => 1);
	exit $exit;

=head3 API SPECIFICATION

=head4 INPUT

The option rules of L</new>, all optional, without C<workflow_file> and
C<project_dir>.

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1, 2 ] }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to     | An unknown or mistyped        | Use the options of new         |
	| App::Actions::run: R     | override                      |                                |
	+--------------------------+-------------------------------+--------------------------------+

Failures of the run itself are printed by L<App::Actions::Runner> and
reported by the exit code rather than raised.

=cut

sub run {
	my $self = shift;

	return $self->_runner($self->_overrides('run', \@_))->run;
}

=head2 preflight

Makes the same checks as a run before its first job, then prepares the
images the selected jobs need, without starting anything.

=head3 ARGUMENTS

=over 4

=item * C<json> - optional; true to print nothing and return the document
C<action-run preflight --json> prints.

=item * C<schema_line> - optional; passed to the runner.

=item * Any run option of L</new>, overriding the object's.

=back

=head3 RETURNS

A hash of C<exit> (0 or 2), C<summary> and C<error>.  C<summary> is the report
L<App::Actions::Check> produces as data, with an C<images> array added; each
entry is C<< { image, source, status, error } >>, and C<status> is C<pulled>,
C<present>, C<failed>, C<skipped> or C<deferred>.  A deferred entry could not
be named from the values available before the run, because a job has not
produced it yet; it carries C<expression> instead of C<image>, and the job
prepares it with its own values before it starts.  C<summary> also carries
C<schema_version>, which is
L<App::Actions::Runner/preflight_schema_version>; the schema and the
checked-in examples in F<t/fixtures/> are validated in F<t/schema.t>, which
also fails when a key, an enum value or a null variant the schema names
appears in none of them.  With C<json =E<gt> 1> nothing is
printed, so the caller's output can be a single document; C<ready> is then a
JSON boolean and the summary is the document C<action-run preflight --json>
prints, already validated against that schema, so a mismatch dies with an
L<App::Actions::Schema::Invalid>
exception naming the first key at fault rather than being returned; the
command gives that exit 70.

=head3 SIDE EFFECTS

Contacts the Docker daemon, starts a probe container and pulls images.

=head3 EXAMPLE

	my $result = $actions->preflight(json => 1);
	print JSON::PP->new->canonical->encode($result->{summary}), "\n";
	exit $result->{exit};

=head3 API SPECIFICATION

=head4 INPUT

The option rules of L</new>, all optional, plus

	{
		json        => { type => 'string', optional => 1 },
		schema_line => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }    # { exit => 0|2, summary => {...}, error => string|undef }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to     | An unknown or mistyped option | Use the options of new         |
	| App::Actions::preflight  |                               |                                |
	| the action-run preflight | The document drifted from its | A bug in this distribution;    |
	| --json document does not | schema (an                    | report it                      |
	| match ...                | App::Actions::Schema::Invalid)|                                |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub preflight {
	my $self = shift;

	# json and schema_line belong to the preflight, not to the runner's
	# construction, so they are separated from the overrides here.
	my $params = validate_args(__PACKAGE__ . '::preflight', \@_, {
		%OPTION_RULES,
		json => { type => 'string', optional => 1 },
		schema_line => { type => 'string', optional => 1 },
	});
	my %preflight = map { $_ => delete $params->{$_} } qw(json schema_line);

	return $self->_runner($params)->preflight(%preflight);
}

=head2 json_schema

Returns the JSON schema of one of the machine-readable documents.

=head3 ARGUMENTS

=over 4

=item * C<$name> - C<check>, C<preflight>, C<cache> or C<logs>.

=back

=head3 RETURNS

The schema as a hash reference, which is what C<action-run schema> prints.
The schemas live in L<App::Actions::Check>, L<App::Actions::Runner>,
L<App::Actions::Cache> and L<App::Actions::Logs>, so the contract is
available from an installed distribution.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $schema = App::Actions->json_schema('check');
	print $schema->{title}, "\n";    # action-run check --json

=head3 API SPECIFICATION

=head4 INPUT

	{ name => { type => 'string', optional => 1 } }

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| A document name is       | The name was undef or empty   | Pass check, preflight, cache   |
	| required                 |                               | or logs                        |
	| Unknown document 'N';    | No such document              | Use one of the names listed    |
	| expected check,          |                               |                                |
	| preflight, cache or logs |                               |                                |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub json_schema {
	my $class = shift;

	my $name = validate_args(__PACKAGE__ . '::json_schema', [ { name => $_[0] } ], {
		name => { type => 'string', optional => 1 },
	})->{name};

	$class->throw('actions.document_required') unless defined $name && length $name;

	# The list in the message comes from the same table as the lookup, so a
	# new document cannot be added to one and forgotten in the other.
	my $owner = $DOCUMENT_OWNER{$name};
	$class->throw('actions.document_unknown', {
		name => $name,
		expected => $class->i18n('list.or', {
			head => join(', ', @DOCUMENTS[ 0 .. $#DOCUMENTS - 1 ]),
			last => $DOCUMENTS[-1],
		}),
	}) unless defined $owner;

	return $owner->json_schema;
}

=head2 list_jobs

Prints one line per expanded job: its id, a tab, and its display name.

=head3 ARGUMENTS

Any of the run options of L</new>.  C<dry_run> and C<quiet> are always set,
because listing starts nothing and prints only the list.

=head3 RETURNS

0.

=head3 SIDE EFFECTS

Prints to standard output.

=head3 EXAMPLE

	$actions->list_jobs(jobs => [ 'test' ]);
	# test	test (perl=5.38)
	# test	test (perl=5.40)

=head3 API SPECIFICATION

=head4 INPUT

The option rules of L</new>, all optional.

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0 ] }

=head3 MESSAGES

	+--------------------------+-------------------------------+--------------------------------+
	| Message                  | Meaning                       | Resolution                     |
	+--------------------------+-------------------------------+--------------------------------+
	| Invalid arguments to     | An unknown or mistyped        | Use the options of new         |
	| App::Actions::list_jobs  | override                      |                                |
	+--------------------------+-------------------------------+--------------------------------+

=cut

sub list_jobs {
	my $self = shift;

	my $overrides = $self->_overrides('list_jobs', \@_);

	return $self->_runner({ %{$overrides}, %LIST_OPTIONS })->list_jobs;
}

# _runner
# Purpose:     Build the App::Actions::Runner for one call, with overrides applied.
# Entry:       $self - the object; $overrides - a hash reference of run
#              options that replace the object's for this call.  An override
#              that is present but undef does replace the object's value; an
#              absent one does not.  docker is the exception: an undef
#              override keeps the object's, as it always has.
# Exit status: Returns an App::Actions::Runner; croaks (via the runner) on
#              options the runner rejects.
# Side effects: None until the runner is used.
# Protected rather than private so a subclass can substitute its own runner.
sub _runner {
	my ($self, $overrides) = @_;

	my %options = map { $_ => (exists $overrides->{$_} ? $overrides->{$_} : $self->{$_}) } @RUNNER_OPTIONS;
	$options{docker} ||= $self->{docker};

	return App::Actions::Runner->new(
		workflow => $self->{workflow},
		project_dir => $self->{project_dir},
		%options,
	);
}

# _logger
# Purpose:     Make a Log::Abstraction logger from any of the forms new()
#              accepts for one.
# Entry:       $spec - a Log::Abstraction object, an array reference to
#              collect the messages in, a hash reference of Log::Abstraction
#              options, 'NULL' for none, or another string, which
#              Log::Abstraction takes as the name of a logger.
# Exit status: Returns a Log::Abstraction object; 'NULL' gives a silent one,
#              because the runner always calls its logger.
# Side effects: None; Log::Abstraction croaks on options it does not know.
sub _logger {
	my ($spec) = @_;

	my $logger;
	if (blessed $spec) {
		$logger = $spec;
	} elsif (ref $spec eq 'ARRAY') {
		$logger = Log::Abstraction->new(array => $spec);
	} elsif (ref $spec eq 'HASH') {
		$logger = Log::Abstraction->new($spec);
	} elsif ($spec eq $NO_LOGGER) {
		$logger = null_logger();
	} else {
		$logger = Log::Abstraction->new(logger => $spec);
	}

	return $logger;
}

# _overrides
# Purpose:     Validate the run options a method was given as overrides.
# Entry:       $self - the object; $routine - the method's name, for the
#              message; $args - its arguments (invocant removed).
# Exit status: Returns a hash reference of the overrides (empty when none).
# Side effects: None; croaks on an unknown or mistyped option.
sub _overrides {
	my (undef, $routine, $args) = @_;

	return validate_args(__PACKAGE__ . "::$routine", $args, \%OPTION_RULES);
}

# _project_dir
# Purpose:     Decide and check the project directory.
# Entry:       $class - the invocant (for throw); $given - project_dir as
#              passed, or undef; $workflow_file - the workflow's absolute path.
# Exit status: Returns the absolute project directory; throws when it cannot
#              be inferred or does not exist.
# Side effects: None.
sub _project_dir {
	my ($class, $given, $workflow_file) = @_;

	# A workflow in a repository's .github/workflows knows its repository.
	my $wanted = $given;
	if (!defined $wanted) {
		($wanted) = $workflow_file =~ $WORKFLOW_IN_REPOSITORY;
		$class->throw('actions.project_dir_required') unless defined $wanted;

		# /.github/workflows/ci.yml is in the root directory; an empty name
		# would be taken by abs_path for the current directory instead.
		$wanted = '/' unless length $wanted;
	}

	my $project_dir = abs_path($wanted);
	$class->throw('actions.project_dir_missing', { dir => $wanted }) unless defined $project_dir && -d $project_dir;

	return $project_dir;
}

# _runner is protected, so a subclass may build its own runner; every other
# _name routine above may be called only from this package.  Sub::Private's
# mode is process-wide, so it is set to enforce for this one call rather than
# for good, which would change how other modules' :Private routines behave.
BEGIN {
	Sub::Protected->import('_runner');
	local $Sub::Private::config{mode} = 'enforce';
	Sub::Private->import(@{ App::Actions::Access->private_names(__PACKAGE__, '_runner') });
}

1;

__END__

=head1 TESTING

The suite runs against a fake Docker command, so it needs neither Docker nor
a daemon:

	prove -l t

One of its tests copies the suite into a temporary directory whose name
contains spaces and runs every test file there again, which is how paths with
spaces are covered on every platform.  The copy is made from F<MANIFEST>, so it
holds exactly what the distribution ships and a test that reads a new file
finds it there as soon as that file is listed.  That doubles the running time;
set C<SPACE_PATH=0> to skip it, or run just that check with
C<prove -l t/space-path.t>.  It is skipped when C<AUTOMATED_TESTING> is set
(continuous integration, CPAN testers) unless C<SPACE_PATH> is set to a true
value.

F<t/locales.t> covers the message catalogue: the country-to-language table
for GB, US, FR, DE and CN, and the error paths under the C<en_US.UTF-8>,
C<de_DE.UTF-8> and C<ja_JP.UTF-8> POSIX locales.

The repository ships a pre-commit hook in F<.githooks/> that runs the schema
checks and the live-knob check against the files a commit stages, so a version
bump applied to the schema or to the documents but not to both, or a live
test's knob added without its documentation or whitelist, is refused where it
happens rather than by CI afterwards.  Each check starts only when a staged
path can affect it.  It is off until a clone asks for it:

	git config core.hooksPath .githooks

A commit that touches nothing either check reads passes without a check being
run at all, and C<git commit --no-verify> skips it for one commit.

The same checks can be run from the command line without attempting a commit:

	make check-staged    # against the index
	make check-worktree  # against the working tree, unstaged edits included

C<check-worktree> always runs both checks, including files that are not tracked
yet, so a new fixture or live test is not skipped.  Both targets need the
F<Makefile> that C<perl Makefile.PL> writes.

The tests that need a real Docker daemon sit behind one switch,
C<LIVE_TESTING>: C<make test LIVE_TESTING=1> runs them all.  C<t/real-docker.t>
runs one small workflow end to end with C<action-run check> and the smoke
script, C<t/real-docker-preflight.t> the preflight including an image that
cannot be pulled, and C<t/self_test.t> the command a user runs -
C<bin/action-run t/lib/self_test.yml .> - in a real container rather than the
fake one it uses by default.  One of them on its own is C<LIVE_TESTING=1
prove -l t/real-docker.t>.

The I<Live Docker> workflow sets the switch and runs C<t/self_test.t> on every
push, so the command a user runs is exercised on a daemon in CI rather than
only on a machine that has one.  The two daemon-specific files stay where a
particular daemon is the point: a local C<LIVE_TESTING=1> run, and the
I<Real Docker on Windows> workflow.

The fake Docker executes step scripts with the host's shell, mapping the paths
C<docker exec> was given back to the host, so a step's output and the files it
writes to C<GITHUB_ENV> and C<GITHUB_OUTPUT> are exercised without a daemon.
It runs the command of a C<docker://> action the same way, so what a one-shot
container prints, and the status it exits with, are what the run sees.

The self test runs two workflows the distribution ships: the one above, which
proves the command surface, and F<t/lib/self_test_cli.yml>, which runs
C<action-run schema> and C<action-run validate> inside a Perl image for every
check and preflight document and every cache and logs fixture, including the
unready, unreachable, uncounted, empty and prune examples, so the tool is
exercised where it is being tested rather than only from the checkout that
started it.  All four sets are discovered from F<t/fixtures/check*.json>,
F<t/fixtures/preflight*.json>, F<t/fixtures/cache*.json> and
F<t/fixtures/logs*.json> rather than listed by name, so a new one is validated
without editing the workflow.  That image gets
the tool's dependencies only when it does not have them, so the fake run
stays off the network.  It is named by digest rather than by the
C<perl:5.38> tag, so the live job pulls the same image every time instead of
whatever that tag points at on the day it runs.  The test says which half it
ran: with C<LIVE_TESTING=1> it reports that the workflow is in a real
container, and without it that the steps ran against the fake and the
container path was not exercised.

The live tests read two variables and both carry the C<LIVE_TESTING>
prefix, so there is one name to remember: C<LIVE_TESTING> turns them on and
C<LIVE_TESTING_IMAGE> names the image they start, C<alpine:3.20> by default.
C<DOCKER> overrides the Docker command.  The daemon must run Linux containers.
C<t/live-knobs.t> holds the tests, the documentation and the workflow to that
prefix, so a rename that misses one of them fails the ordinary suite.
The same ground is covered by C<action-run-smoke>, which does not need C<prove>
and reports the environment before it runs anything; use it when Docker, not
the code, is in doubt.  On Windows it is the check to run against Docker
Desktop, whose Linux engine C<action-run-smoke> verifies before it starts a
container.

The opt-in I<Real Docker on Windows> workflow runs the same test on a Windows
host.  Dispatch it on a self-hosted Windows runner with Docker Desktop, or set
the C<docker_host> input to a Linux daemon.  GitHub-hosted Windows runners
only run Windows containers, so the job stops there with an explanation.

=head1 LIMITATIONS

Only Linux runners can be emulated.  Windows and macOS jobs are skipped.
Local composite and JavaScript actions are run; remote actions and local
C<docker> actions cannot be run.  Checkout, setup-perl, cache, artifact, and
Codecov actions are treated as no-ops.  Use C<strict_actions> to turn unknown
actions into failures instead of skips.  JavaScript actions need C<node> in
the job image.  Job outputs, C<needs.*.outputs>, and C<timeout-minutes> are
not implemented.

Images are pulled concurrently only where C<fork()> is reliable; on Windows
they are pulled one at a time, because Perl's emulation of C<fork()> shares the
parent's handles with the child.

Design weaknesses that remain:

=over 4

=item * L<App::Actions::Runner> plans the run and hands the work to five
parts (images, containers, steps, parallel jobs and the report), each in its
own module under F<App/Actions/Runner/>.  The parts are built from copies of
the runner's options rather than given the runner, so they can be tested
alone, but a change to an option after construction is not seen by them, and
the planner is still the largest of them.

=item * Errors raised through the catalogue are L<App::Actions::Error>
objects carrying the message key as a stable code, and F<bin/action-run>
asks for the code rather than matching the text.  The errors of
L<App::Actions::Check>, L<App::Actions::Docker>, L<App::Actions::Expression>,
L<App::Actions::Process>, L<App::Actions::Cache> and L<App::Actions::Logs> are
still strings.

=item * The option rules are one table, the runner's (see
L<App::Actions::Runner/option_rules>), but the options are still checked
twice: here, where the caller passes them, and in the runner, which is a
public class and so checks its own arguments.  The cost is a second pass
over a dozen keys per call.

=item * Unknown options are now an error.  A caller that passed an option
this module never forwarded (and which therefore had no effect) will now be
told so.

=item * The Check, Docker, Expression, Process and command-line messages
have not been moved into the catalogue yet; see
L<App::Actions::I18N/LIMITATIONS>.

=item * Settings from configuration files and C<App__Actions__*> environment
variables are merged in by L<Object::Configure> after L</new> has checked its
arguments, so they are not checked: C<App__Actions__parallel=banana> is
accepted.  They also win over the arguments, which is the reverse of what
most programs do, and a caller cannot choose a configuration file.

=item * Not everything a run prints goes through the logger.  The progress
lines, the command echoes and the summary are output and stay on standard
output.  L<App::Actions::I18N> warns about a missing catalogue entry with
C<carp>, because it has no object to hold a logger.  A pulling child of
L<App::Actions::Process> prints straight to the log file it was given, since
it is a separate process whose output is already captured.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Docker must be running, and able to see your project.>  Run
C<action-run check> first if a run fails before any job starts.

=item * B<Only Linux jobs run.>  Jobs with C<runs-on: macos-*> or
C<windows-*> are skipped, not failed.

=item * B<Remote actions are not downloaded.>  C<actions/checkout>,
setup-perl and a few others are treated as no-ops (your project is already
mounted).  Other remote actions are skipped with a warning; set
C<strict_actions> to make them fail instead.

=item * B<Secrets must be passed in.>  Nothing is read from GitHub.  Pass
C<secrets =E<gt> { NAME =E<gt> value }> (or C<--secret> on the command
line).  Missing secrets are empty, as on GitHub for a fork.

=item * B<Images are kept.>  The images a run downloads stay, to make the
next run faster.  Set C<keep_images =E<gt> 0>, or use C<action-run cache
--prune>, to remove them.

=item * B<C<run> returns a status; it does not die for a failed job.>
Check the number: 0, 1 or 2.

=item * B<Unknown options are errors.>  A misspelt option name (C<job> for
C<jobs>) stops with C<Invalid arguments to App::Actions::new>.

=item * B<Run as yourself or root.>  With C<user> set to another user, the
job's files (secrets included) must be readable by every user of the
computer, and a warning says so.

=item * B<Only run workflows you trust.>  A workflow can mount any folder
of your computer into its containers, as it can on GitHub's own runners.

=item * B<Parallel jobs write to log files, not the terminal.>  With
C<parallel> above 1, read the output with C<action-run logs>.

=item * B<A configuration file or environment variable beats an argument.>
If F<~/.conf/local.yaml> has an C<App__Actions> section with C<parallel: 8>,
then C<parallel =E<gt> 2> (and C<action-run --parallel=2>) still runs eight
jobs at a time.  When an option seems to be ignored, look for an
C<App__Actions> section in those files and for C<App__Actions__*>
environment variables (C<env | grep App__Actions>).

=item * B<Values from those places are not checked.>  A misspelt or
nonsensical value there is not reported as an argument would be.

=item * B<A UNIVERSAL logger takes the messages off the terminal.>
L<Object::Configure> applies a C<UNIVERSAL> section of F<universal.yaml> to
every class that uses it, this one included.  If that section has a
C<logger> that writes to a file or to syslog, a failed step is reported
there and not on standard error.  Give this module its own C<logger> in an
C<App__Actions> section, or pass C<logger>, to choose where its messages go.

=back

=head1 ENCODING

Workflow and action files are read as UTF-8.  Their names, commands and
values may contain any Unicode text, including non-ASCII characters and
emoji.  File and folder names are used as bytes, as your system stores
them.  Commands, environment variables and secrets are passed to Docker as
bytes (UTF-8 for text from the workflow).  What the containers print is
passed through to your terminal unchanged.  Messages from this module are
in English unless C<ACTION_RUN_LANG> chooses French (C<fr>), German
(C<de>) or Chinese (C<zh>); those are character strings, so the terminal
should use UTF-8.  Settings in configuration files and C<App__Actions__*>
environment variables are used as L<Config::Abstraction> reads them; keep
option values there in ASCII.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>, which L</new>
uses to read configuration files and environment variables

=item * L<Config::Abstraction>, which finds and reads those files

=item * L<Test Dashboard|https://nigelhorne.github.io/App-Actions/coverage/>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf-8

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

	┌─ New ─────────────────────────────────────────────
	│ ΞFileSystem
	│ workflowFile? : optional PATH
	│ projectDir?   : optional PATH
	│ options?      : OPTION ⇸ VALUE
	│ actions!      : Actions
	├───────────────────────────────────────────────────
	│ dom options? ⊆ RUNNER_OPTIONS
	│ let settings == (args? ⊕ fileConfig(App__Actions)) ⊕ envConfig(App__Actions__)
	│     where args? == options? ∪ {workflow_file ↦ workflowFile?, project_dir ↦ projectDir?}
	│     -- dom fileConfig and dom envConfig are not checked against RUNNER_OPTIONS
	│ workflowFile? = ⊥ ⇒ raises WorkflowFileRequired
	│ abs(workflowFile?) ∉ regularFiles ⇒ raises WorkflowFileMissing
	│ projectDir? = ⊥ ∧ abs(workflowFile?) ∉ (PATH ⁀ "/.github/workflows/" ⁀ NAME)
	│     ⇒ raises ProjectDirRequired
	│ let root == (projectDir? ≠ ⊥ ⇒ abs(projectDir?))
	│             ∧ (projectDir? = ⊥ ⇒ repository(abs(workflowFile?)))
	│ root ∉ directories ⇒ raises ProjectDirMissing
	│ actions!.workflow = Workflow.Load(abs(workflowFile?))
	│ actions!.project_dir = root
	│ actions!.options = settings
	│ let logged == (logger? ≠ ⊥ ⇒ logger?)
	│             ∧ (logger? = ⊥ ∧ logger ∈ dom configured ⇒ configured(logger))
	│             ∧ (logger? = ⊥ ∧ logger ∉ dom configured ⇒ stderrLogger)
	│     where configured == fileConfig(App__Actions) ⊕ envConfig(App__Actions__)
	│     -- fileConfig includes the UNIVERSAL section of universal.yaml
	│ actions!.logger ∈ LogAbstraction
	│ logged = NULL ⇒ actions!.logger = silentLogger
	│ logged ≠ NULL ⇒ actions!.logger = toLogger(logged)
	└───────────────────────────────────────────────────

	The workflowFile? and projectDir? above are the values in settings, so a
	configuration file or environment variable can replace them too.

=head2 workflow, workflow_file, project_dir

	┌─ Accessor ────────────────────────────────────────
	│ ΞActions
	│ field? : {workflow, workflow_file, project_dir}
	│ value! : VALUE
	├───────────────────────────────────────────────────
	│ value! = θActions.field?
	└───────────────────────────────────────────────────

=head2 run

	┌─ Run ─────────────────────────────────────────────
	│ ΞActions
	│ overrides? : OPTION ⇸ VALUE
	│ exit!      : {0, 1, 2}
	├───────────────────────────────────────────────────
	│ dom overrides? ⊆ RUNNER_OPTIONS
	│ exit! = Runner.Run(options ⊕ overrides?)
	└───────────────────────────────────────────────────

=head2 preflight

	┌─ Preflight ───────────────────────────────────────
	│ ΞActions
	│ overrides? : OPTION ⇸ VALUE
	│ json?      : optional BOOLEAN
	│ result!    : Result
	├───────────────────────────────────────────────────
	│ dom overrides? ⊆ RUNNER_OPTIONS
	│ result! = Runner.Preflight(options ⊕ overrides?, json?)
	│ result!.exit ∈ {0, 2}
	│ json? ⇒ valid(result!.summary, PreflightSchema)
	└───────────────────────────────────────────────────

=head2 json_schema

	DOCUMENT ::= check | preflight | cache | logs

	┌─ JsonSchema ──────────────────────────────────────
	│ name?   : optional STRING
	│ schema! : KEY ⇸ VALUE
	├───────────────────────────────────────────────────
	│ name? ∈ {⊥, ⟨⟩} ⇒ raises DocumentRequired
	│ name? ∉ DOCUMENT ⇒ raises DocumentUnknown(name?)
	│ name? ∈ DOCUMENT ⇒ schema! = owner(name?).json_schema
	└───────────────────────────────────────────────────

=head2 list_jobs

	┌─ ListJobs ────────────────────────────────────────
	│ ΞActions
	│ overrides? : OPTION ⇸ VALUE
	│ exit!      : {0}
	├───────────────────────────────────────────────────
	│ output' = output ⁀ ⟨ j : selected(jobs ⊕ overrides?) • j.base_id ⁀ TAB ⁀ j.display_name ⟩
	│ exit! = 0
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

An App::Actions object only holds options; each call to L</run>,
L</preflight> or L</list_jobs> builds a new L<App::Actions::Runner> and goes
through these states (the full detail of each is in L<App::Actions::Runner>
and its parts):

	 new(%options)
	      |   options checked; then App__Actions settings from configuration
	      |   files and App__Actions__* environment variables merged over
	      |   them (not checked); workflow loaded (errors are thrown here)
	      v
	+-------------+
	|   READY     |<------------------------------------------------------+
	+-------------+                                                       |
	   |       |  list_jobs: print "id<TAB>display name" per job; return 0 |
	   |       +-------------------------------------------------------->-+
	   |
	   | run(%overrides) / preflight(%overrides)
	   v
	+----------------+  daemon unreachable, not Linux containers,
	| CHECK DOCKER   |  project not mountable -> print report; status 2
	| (skip_check:   |---------------------------------------------------+
	|  skipped)      |                                                   |
	+----------------+                                                   |
	   |                                                                 |
	   v                                                                 |
	+----------------+  an image cannot be pulled -> status 2            |
	| PREPARE IMAGES |------------------------------------------------->-+
	| (pull missing, |                                                   |
	|  N at a time)  |  preflight stops here: return { exit, summary }   |
	+----------------+------------------------------------------------->-+
	   |                                                                 |
	   | for each selected job (matrix expanded; non-Linux skipped;      |
	   | up to "parallel" at a time)                                     |
	   v                                                                 |
	+----------------+  network, services, job container                 |
	| START JOB      |  (a service that stops -> job fails)              |
	+----------------+                                                   |
	   |                                                                 |
	   v                                                                 |
	+----------------+  each step: if: condition -> docker exec;         |
	| RUN STEPS      |  GITHUB_ENV / PATH / OUTPUT / STATE honoured;     |
	|                |  a failed step fails the job (later steps run     |
	|                |  only with if: failure() / always())              |
	+----------------+                                                   |
	   |                                                                 |
	   v                                                                 |
	+----------------+  containers and network removed (unless keep);    |
	| CLEAN UP JOB   |  images kept unless keep_images is false          |
	+----------------+                                                   |
	   |                                                                 |
	   v                                                                 |
	+----------------+  status 0 = every job passed, 1 = a job failed    |
	| REPORT         |------------------------------------------------->-+
	+----------------+                     returns the status

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
