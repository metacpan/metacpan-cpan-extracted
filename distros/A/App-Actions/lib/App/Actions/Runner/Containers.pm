package App::Actions::Runner::Containers;

use strict;
use warnings;
use autodie qw(:all);

use Readonly;
use Sub::Private ();
use Text::ParseWords qw(shellwords);

use App::Actions::Access;
use App::Actions::Error;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Runner::Support qw(default_logger env_args resolve_env);

our $VERSION = '0.002.1';

# Where the project and the runner directory appear inside every container.
Readonly::Scalar my $WORKSPACE => '/github/workspace';
Readonly::Scalar my $RUNNER_DIR => '/github/actions-runner';

# The job container idles until the steps are run in it with docker exec.
Readonly::Scalar my $IDLE_ENTRYPOINT => '/bin/sh';
Readonly::Scalar my $IDLE_COMMAND => 'while :; do sleep 3600; done';

# The PATH a container is assumed to have when it will not say.
Readonly::Scalar my $DEFAULT_PATH => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

# Docker's own words for a request it could not satisfy because of the image.
# They are matched as phrases, in lower case, because they are Docker's
# output rather than this program's.
Readonly::Array my @IMAGE_COMPLAINTS => (
	'no such image', 'unable to find image', 'manifest unknown',
	'pull access denied', 'invalid reference format',
);

# Docker resource names may hold these characters and must fit in 63.
Readonly::Scalar my $NAME_UNSAFE => qr/[^A-Za-z0-9_.-]/;
Readonly::Scalar my $NAME_LENGTH => 63;
Readonly::Scalar my $JOB_NAME_LENGTH => 20;

=encoding utf-8

=head1 NAME

App::Actions::Runner::Containers - start, check and remove a run's containers

=head1 SYNOPSIS

	my $containers = App::Actions::Runner::Containers->new(
		docker => $docker,
		expression => $expression,
		project_dir => '/home/me/project',
		run_id => $run_id,
	);

	my $network = $containers->create_network($job);
	my @started;
	my $services = $containers->start_services($job, $network, $context, \@started);
	push @started, $containers->start_job($job, $network, $env, $context, $image, $temp);
	...
	$containers->cleanup_job($network, \@started);

Make sure nothing is left when a run fails part-way:

	my $ok = eval { run_the_jobs($containers); 1 };
	$containers->remove_all unless $keep;
	die $@ unless $ok;

List what a run that keeps its containers left behind:

	my $left = $containers->remaining;
	print "container $_\n" for @{ $left->{containers} };
	print "network   $_\n" for @{ $left->{networks} };

=head1 DESCRIPTION

B<In short:> this module starts and stops the Docker containers of a run,
and explains clearly when one will not start or will not stay up.  It is a
part of L<App::Actions::Runner>; you rarely use it on its own.

Each job gets its own Docker network, its own service containers, and a
long-lived job container that its steps are executed in.  This class starts
them, checks that they stay up, explains why when they do not, and removes
them.  It remembers every container and network it created, so the run can
remove whatever a failed job left behind.

A service has to stay up.  One that stops is reported with the status it
exited with and the last lines it printed; one that its restart policy keeps
bringing back is reported with the restart count, rather than being taken
for a working service because Docker says it is running.  A container the
daemon refuses to start is reported with the daemon's words and, when they
name it, the part of the request at fault: the image, the entrypoint, or a
published port.

=head1 METHODS

=head2 new

Creates the container manager for one run.

=head3 ARGUMENTS

=over 4

=item * C<docker> - the L<App::Actions::Docker> object.

=item * C<expression> - the L<App::Actions::Expression> evaluator.

=item * C<project_dir> - the project, mounted at F</github/workspace>.

=item * C<run_id> - the run's identifier, part of every resource name.

=item * C<platform>, C<user> - optional; passed to C<docker run>.

=item * C<quiet>, C<explain>, C<keep> - optional flags.

=item * C<logger> - optional; a L<Log::Abstraction> object (default:
L<App::Actions::Runner::Support/default_logger>, standard error).  A
service's C<credentials>, which are not supported, are logged at the
C<warn> level unless C<quiet> is set.

=back

=head3 RETURNS

An C<App::Actions::Runner::Containers> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

	my $containers = App::Actions::Runner::Containers->new(
		docker => App::Actions::Docker->new,
		expression => App::Actions::Expression->new,
		project_dir => '/home/me/project',
		run_id => sprintf('%x', time),
		keep => 1,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		docker      => { type => 'object', can => 'container_start' },
		expression  => { type => 'object', can => 'interpolate' },
		project_dir => { type => 'string', min => 1 },
		run_id      => { type => 'string', min => 1 },
		platform    => { type => 'string', optional => 1 },
		user        => { type => 'string', optional => 1 },
		quiet       => { type => 'boolean', optional => 1 },
		explain     => { type => 'boolean', optional => 1 },
		keep        => { type => 'boolean', optional => 1 },
		logger      => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Containers' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | A collaborator is missing or | Pass the documented objects |
	| ...Containers::new: REASON| an option has the wrong type |                             |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		docker => { type => 'object', can => 'container_start' },
		expression => { type => 'object', can => 'interpolate' },
		project_dir => { type => 'string', min => 1 },
		run_id => { type => 'string', min => 1 },
		platform => { type => 'string', optional => 1 },
		user => { type => 'string', optional => 1 },
		quiet => { type => 'boolean', optional => 1 },
		explain => { type => 'boolean', optional => 1 },
		keep => { type => 'boolean', optional => 1 },
		# Where warnings and errors go; standard error when none is given.
		logger => { type => 'object', can => [qw(warn error notice)], optional => 1 },
	});

	return bless { %{$params}, logger => $params->{logger} || default_logger(), containers => [], networks => [], counter => 0 }, $class;
}

=head2 name

	my $name = $containers->name('svc', $job, 'postgres');

Makes a Docker resource name that is unique within the run and says what it
is: C<action-run-RUN-N-KIND-JOB-INDEX[-SUFFIX]>, with unsafe characters
replaced and cut to 63 characters.  RUN is the last eight characters of the
run id, N counts the names made so far, JOB is the job id (at most 20
characters), and INDEX is the job's C<matrix_index> (0 when it has none).

=head3 EXAMPLE

	$containers->name('net', { base_id => 'test', matrix_index => 0 });
	# action-run-6553f1a2-1-net-test-0

=head3 API SPECIFICATION

=head4 INPUT

	{
		kind   => { type => 'string', min => 1 },
		job    => { type => 'hashref' },
		suffix => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', min => 1, max => 63 }

=head3 MESSAGES

None.

=cut

sub name {
	my ($self, $kind, $job, $suffix) = @_;

	my $counter = ++$self->{counter};
	my $short_id = substr($self->{run_id}, -8);
	(my $base = $job->{base_id}) =~ s/$NAME_UNSAFE/-/g;
	$base = substr($base, 0, $JOB_NAME_LENGTH);

	# A job that is not one of a matrix has no index; it is the first.
	my $index = defined $job->{matrix_index} ? $job->{matrix_index} : 0;
	my $name = "action-run-$short_id-$counter-$kind-$base-$index";
	$name .= "-$suffix" if defined $suffix && length $suffix;
	$name =~ s/$NAME_UNSAFE/-/g;

	return substr($name, 0, $NAME_LENGTH);
}

=head2 create_network

	my $network = $containers->create_network($job);

Creates the job's own network and remembers it for the cleanup.

=head3 EXAMPLE

	my $network = $containers->create_network($job);

=head3 API SPECIFICATION

=head4 INPUT

	{ job => { type => 'hashref' } }

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Failed to create Docker     | docker network create failed | Check the daemon; remove    |
	| network 'X' (exit N)        |                              | stale action-run networks   |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub create_network {
	my ($self, $job) = @_;

	my $network = $self->name('net', $job);
	my $rc = $self->{docker}->network_create($network);
	$self->throw('runner.network_failed', { name => $network, status => $rc, location => 0 }) if $rc != 0;
	push @{ $self->{networks} }, $network;

	return $network;
}

=head2 start_services

	my $services = $containers->start_services($job, $network, $context, \@started);

Starts the job's service containers on its network, each reachable by its
id, and checks that each one stays up.

=head3 ARGUMENTS

=over 4

=item * C<$job>, C<$network>, C<$context> - the job, its network and its
expression context.

=item * C<\@started> - the job's container list; each started service is
added, so the job's cleanup removes it even if a later one fails.

=back

=head3 RETURNS

An array reference of C<[ id, container name ]> pairs, for L</check_services>.

=head3 SIDE EFFECTS

Starts containers; prints an explanation block per service in an explain run.

=head3 EXAMPLE

	my @started;
	my $services = $containers->start_services($job, $network, $context, \@started);

=head3 API SPECIFICATION

=head4 INPUT

	{
		job     => { type => 'hashref' },
		network => { type => 'string', min => 1 },
		context => { type => 'hashref' },
		started => { type => 'arrayref' },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Service 'X' must be a       | The service entry is neither | Give it an image            |
	| mapping / has no image      | a mapping nor an image name  |                             |
	| Unable to read the container| The options text has a quote | Close the quote, or escape  |
	| options 'X': a quote is not | that is not closed, so it    | it with a backslash         |
	| closed                      | cannot be split into words   |                             |
	| Failed to start service 'X' | docker run failed            | Check the image and options |
	| (exit N)                    |                              |                             |
	| Service 'X' did not stay    | It exited after starting     | Read the output quoted      |
	| running (exit N); ...       |                              | below the message           |
	| Service 'X' is restarting   | Its restart policy keeps     | Read the output quoted      |
	| (restart count N); ...      | bringing it back             | below the message           |
	| action-run: service 'X'     | Registry credentials are not | Log in with docker login    |
	| credentials are not         | passed on (a warning)        |                             |
	| supported; ...              |                              |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	for each service, sorted by id:
		check it has an image, and resolve the image name
		build docker run arguments: options, name, network and alias, user,
			volumes, environment, ports, image
		explain it, in an explain run
		start it and remember it, even if it failed to start
		fail if it did not start, is restarting, or has stopped

=cut

sub start_services {
	my ($self, $job, $network, $context, $started) = @_;

	my $services = $job->{services} || {};
	my @running;

	for my $id (sort keys %{$services}) {
		my $service = $services->{$id};
		$service = { image => $service } unless ref $service;
		$self->throw('runner.service.not_mapping', { id => $id }) unless ref $service eq 'HASH';
		$self->throw('runner.service.no_image', { id => $id })
			unless defined $service->{image} && length $service->{image};

		# The image was resolved and prepared by the job's own image check,
		# before its network existed.
		my $image = $self->{expression}->interpolate($service->{image}, $context);
		my $name = $self->name('svc', $job, $id);

		my @args = (
			@{ $self->_options_args($service->{options}, $context) },
			'--name', $name, '--network', $network, '--network-alias', $id,
			@{ $self->_user_args },
			@{ $self->_list_args('-v', $service->{volumes}, $context) },
			@{ env_args(resolve_env($self->{expression}, [ $service->{env} ], $context)) },
			@{ $self->_list_args('-p', $service->{ports}, $context) },
			$image,
		);

		$self->{logger}->warn($self->i18n('runner.service.credentials', { id => $id }))
			if defined $service->{credentials} && !$self->{quiet};

		$self->_explain(
			title => $self->i18n('runner.explain.service', { id => $id, job => $job->{base_id} }),
			container => $name,
			image => $image,
			entrypoint => $self->_service_entrypoint($service, $context),
		);

		# Remembered before the result is looked at, so a container that
		# was created but failed is still removed.
		my $rc = $self->{docker}->container_start(@args);
		push @{ $self->{containers} }, $name;
		push @{$started}, $name;
		$self->throw('runner.service.start_failed', { id => $id, status => $rc, location => 0 }) if $rc != 0;

		# Restarting is checked first: Docker reports a container between
		# restart attempts as running, and "restarting" is the better account.
		$self->check_services([ [ $id, $name ] ]);
		die $self->_stopped_message($self->i18n('runner.what.service', { id => $id }), $name)
			unless $self->{docker}->container_running($name);

		push @running, [ $id, $name ];
	}

	return \@running;
}

=head2 check_services

	$containers->check_services($services);

Fails if any service is restarting, or dead once its restart policy gave up.
Docker reports a container between restart attempts as running, so asking
only whether it runs would pass one that is backing off.  The job checks its
services again when its steps finish, because a service that restarted
during the run is not the one the steps talked to.

=head3 EXAMPLE

	$containers->check_services([ [ 'postgres', $name ] ]);

=head3 API SPECIFICATION

=head4 INPUT

	{ services => { type => 'arrayref' } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Containers' }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Service 'X' is restarting / | The container is backing off | Read the output quoted      |
	| is dead (restart count N);  | or its policy gave up        | below the message           |
	| its last output was: ...    |                              |                             |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub check_services {
	my ($self, $services) = @_;

	my $docker = $self->{docker};
	for my $entry (@{$services}) {
		my ($id, $name) = @{$entry};
		my $status = $docker->container_status($name);
		my $restarts = $docker->container_restart_count($name);

		next unless (defined $status && $status =~ /\A(?:restarting|dead)\z/)
			|| (defined $restarts && $restarts > 0);

		die $self->_restart_message($self->i18n('runner.what.service', { id => $id }), $status, $restarts, $name);
	}

	return $self;
}

=head2 start_job

	my $container = $containers->start_job($job, $network, $env, $context, $image, $temp_path);

Starts the job container: the project mounted at F</github/workspace>, the
runner directory at F</github/actions-runner>, the job's environment, and a
shell that idles until the steps are run in it.

=head3 ARGUMENTS

=over 4

=item * C<$job>, C<$network>, C<$env>, C<$context> - the job, its network,
its resolved environment and its expression context.

=item * C<$image> - the resolved image.

=item * C<$temp_path> - the job's runner directory on the host.

=back

=head3 RETURNS

The container name.

=head3 SIDE EFFECTS

Starts a container, which is remembered for the cleanup; removes it again if
it fails to start or stops at once.

=head3 EXAMPLE

	my $container = $containers->start_job($job, $network, $env, $context, 'perl:5.40', $temp);

=head3 API SPECIFICATION

=head4 INPUT

	{
		job       => { type => 'hashref' },
		network   => { type => 'string', min => 1 },
		env       => { type => 'hashref' },
		context   => { type => 'hashref' },
		image     => { type => 'string', min => 1 },
		temp_path => { type => 'string', min => 1 },
	}

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| Job container 'X' could not | The daemon refused it        | Fix what the quoted daemon  |
	| be started (exit N); at     |                              | message names               |
	| fault: ...; the daemon said:|                              |                             |
	| Job container 'X' did not   | /bin/sh is missing or exited | Use an image with a shell   |
	| stay running (exit N); ...  |                              |                             |
	| Unable to read the container| The options text has a quote | Close the quote, or escape  |
	| options 'X': a quote is not | that is not closed, so it    | it with a backslash         |
	| closed                      | cannot be split into words   |                             |
	+-----------------------------+------------------------------+-----------------------------+

=head3 PSEUDOCODE

	name the container
	build docker run arguments: the job's container options, name, network,
		hostname, user, the workspace and runner mounts, the job's volumes and
		ports, the working directory, the environment, and an idle shell
	explain it, in an explain run
	start it, capturing what the daemon says
	if the start failed, remove it and report the daemon's words
	if it is not running, read its output, remove it and report that

=cut

sub start_job {
	my ($self, $job, $network, $env, $context, $image, $temp_path) = @_;

	my $container = $self->name('job', $job);
	my $spec = ref $job->{container} eq 'HASH' ? $job->{container} : {};

	my @args = (
		@{ $self->_options_args($spec->{options}, $context) },
		'--name', $container, '--network', $network, '--hostname', _hostname($job->{base_id}),
		@{ $self->_user_args },
		'-v', "$self->{project_dir}:$WORKSPACE", '-v', "$temp_path:$RUNNER_DIR",
		@{ $self->_list_args('-v', $spec->{volumes}, $context) },
		@{ $self->_list_args('-p', $spec->{ports}, $context) },
		'-w', $WORKSPACE,
		@{ env_args($env) },
		'--entrypoint', $IDLE_ENTRYPOINT, $image, '-c', $IDLE_COMMAND,
	);

	$self->_explain(
		title => $self->i18n('runner.explain.job', { job => $job->{base_id} }),
		container => $container,
		image => $image,
		entrypoint => $IDLE_ENTRYPOINT,
		command => "-c '$IDLE_COMMAND'",
	);

	# Captured rather than run quietly: a daemon that refuses the container
	# says why in the message that would otherwise be discarded.
	my $docker = $self->{docker};
	my ($said, $rc) = $docker->container_start_captured(@args);
	my $what = $self->i18n('runner.what.job_container', { name => $container });

	my $failure = $rc != 0
		? $self->_start_failure_message($what, $rc, $said, image => $image, entrypoint => $IDLE_ENTRYPOINT)
		: !$docker->container_running($container)
			# Read before removing: "did not stay running" alone leaves the
			# reader unable to tell a bad image from a bad entrypoint.
			? $self->_stopped_message($what, $container)
			: undef;
	if (defined $failure) {
		$docker->container_remove($container);
		die $failure;
	}

	return $container;
}

=head2 inspect

	my $facts = $containers->inspect($container);

Asks a running job container what the steps will need to know: its C<PATH>,
with the runner's apt shims in front (and the sudo shim when the image has
no sudo and the job runs as root), and whether it has C<bash> and C<node>.

=head3 EXAMPLE

	my $facts = $containers->inspect($container);
	print "bash is missing\n" unless $facts->{has_bash};

=head3 API SPECIFICATION

=head4 INPUT

	{ container => { type => 'string', min => 1 } }

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			path     => { type => 'string', min => 1 },
			has_bash => { type => 'boolean' },
			has_node => { type => 'boolean' },
		},
	}

=head3 MESSAGES

None.

=cut

sub inspect {
	my ($self, $container) = @_;

	my $docker = $self->{docker};
	my ($path, $path_rc) = $docker->capture_silent('exec', $container, 'sh', '-c', 'printf %s "$PATH"');
	$path = $DEFAULT_PATH if $path_rc != 0 || !defined $path || !length $path;
	$path = "$RUNNER_DIR/aptbin:$path";

	# Asked in this order, which is the order the container's log shows.
	my %facts = (
		has_bash => $self->_has_command($container, 'bash'),
		has_node => $self->_has_command($container, 'node'),
	);

	# A job running as root gets the sudo shim only when the image has no
	# sudo of its own; another user must not be given one that pretends.
	$path = "$RUNNER_DIR/bin:$path" if !defined $self->{user} && !$self->_has_command($container, 'sudo');

	return { %facts, path => $path };
}

=head2 run_action

	my $rc = $containers->run_action(%args);

Runs a C<docker://> action: a container of its own, removed when it exits,
on the job's network, with the workspace and runner directory mounted and
the step's environment.

=head3 ARGUMENTS

=over 4

=item * C<image>, C<network>, C<workdir>, C<temp_path> - where and what to run.

=item * C<env> - the step's environment.

=item * C<entrypoint> - optional; replaces the image's.

=item * C<arguments> - optional; an array reference of command arguments.

=item * C<title> - the name used in an explain run.

=back

=head3 RETURNS

The exit status of the container.

=head3 SIDE EFFECTS

Runs a container; prints an explanation block in an explain run.

=head3 EXAMPLE

	my $rc = $containers->run_action(
		image => 'alpine:3.20', network => $network, workdir => '/github/workspace',
		temp_path => $temp, env => \%env, arguments => [ 'echo', 'hi' ],
		title => "Action 'docker://alpine:3.20' in job 'test'",
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		image      => { type => 'string', min => 1 },
		network    => { type => 'string', min => 1 },
		workdir    => { type => 'string', min => 1 },
		temp_path  => { type => 'string', min => 1 },
		env        => { type => 'hashref' },
		entrypoint => { type => 'string', optional => 1 },
		arguments  => { type => 'arrayref', optional => 1 },
		title      => { type => 'string' },
	}

=head4 OUTPUT

	{ type => 'integer' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | A required argument is       | Pass the documented         |
	| ...run_action: REASON     | missing                      | arguments                   |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub run_action {
	my $self = shift;

	my $params = validate_args(__PACKAGE__ . '::run_action', \@_, {
		image => { type => 'string', min => 1 },
		network => { type => 'string', min => 1 },
		workdir => { type => 'string', min => 1 },
		temp_path => { type => 'string', min => 1 },
		env => { type => 'hashref' },
		entrypoint => { type => 'string', optional => 1 },
		arguments => { type => 'arrayref', optional => 1 },
		title => { type => 'string' },
	});
	my $entrypoint = $params->{entrypoint};
	my @arguments = @{ $params->{arguments} || [] };

	my @args = (
		'run', '--rm',
		@{ $self->_platform_args },
		'--network', $params->{network},
		'-v', "$self->{project_dir}:$WORKSPACE",
		'-v', "$params->{temp_path}:$RUNNER_DIR",
		'-w', $params->{workdir},
		@{ $self->_user_args },
		(defined $entrypoint ? ('--entrypoint', $entrypoint) : ()),
		@{ env_args($params->{env}) },
		$params->{image},
		@arguments,
	);

	$self->_explain(
		title => $params->{title},
		image => $params->{image},
		entrypoint => $entrypoint,
		command => @arguments ? join(' ', @arguments) : undef,
	);

	return $self->{docker}->run(@args);
}

=head2 cleanup_job

	$containers->cleanup_job($network, \@started);

Removes a finished job's containers, newest first, and its network, unless
the run keeps them.  Returns the object.

=head3 EXAMPLE

	$containers->cleanup_job($network, \@started);

=head3 API SPECIFICATION

=head4 INPUT

	{
		network    => { type => 'string', min => 1 },
		containers => { type => 'arrayref' },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Containers' }

=head3 MESSAGES

None; a removal that fails is left to the run's final cleanup.

=cut

sub cleanup_job {
	my ($self, $network, $containers) = @_;

	return $self if $self->{keep};

	my %gone = map { $_ => 1 } @{$containers};
	$self->{docker}->container_remove($_) for reverse @{$containers};
	$self->{containers} = [ grep { !$gone{$_} } @{ $self->{containers} } ];

	$self->{docker}->network_remove($network);
	$self->{networks} = [ grep { $_ ne $network } @{ $self->{networks} } ];

	return $self;
}

=head2 remaining

Returns C<< { containers => [...], networks => [...] } >>: what the run
created and has not removed.  A run that keeps its resources lists these.

=head3 EXAMPLE

	print "  container $_\n" for @{ $containers->remaining->{containers} };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub remaining {
	my ($self) = @_;

	return { containers => [ @{ $self->{containers} } ], networks => [ @{ $self->{networks} } ] };
}

=head2 remove_all

Removes every container and network the run created and has not removed,
newest first.  Returns the object.

=head3 EXAMPLE

	$containers->remove_all unless $keep;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Containers' }

=head3 MESSAGES

None.

=cut

sub remove_all {
	my ($self) = @_;

	$self->{docker}->container_remove($_) for reverse @{ $self->{containers} };
	$self->{docker}->network_remove($_) for reverse @{ $self->{networks} };
	@{$self}{qw(containers networks)} = ([], []);

	return $self;
}

# _platform_args
# Purpose:     The --platform option, when one was asked for.
# Entry:       None.
# Exit status: Returns an array reference, empty without a platform.
# Side effects: None.
sub _platform_args {
	my ($self) = @_;

	my $platform = $self->{platform};

	return (defined $platform && length $platform) ? [ '--platform', $platform ] : [];
}

# _user_args
# Purpose:     The --user option, when the run asks for a container user.
# Entry:       None.
# Exit status: Returns an array reference, empty without a user.
# Side effects: None.
sub _user_args {
	my ($self) = @_;

	return defined $self->{user} ? [ '--user', $self->{user} ] : [];
}

# _options_args
# Purpose:     Turn a container's `options` string into docker arguments,
#              after the platform option, which they may override.
# Entry:       $options - the workflow's text, or undef; $context.
# Exit status: Returns an array reference.
# Side effects: None.
sub _options_args {
	my ($self, $options, $context) = @_;

	return [ @{ $self->_platform_args }, @{ $self->_option_words($options, $context) } ];
}

# _option_words
# Purpose:     Split a container's `options` into words, as a shell would.
# Entry:       $options - the workflow's text, or undef; $context.
# Exit status: Returns an array reference, empty for no options.  Throws
#              runner.options_invalid when the text cannot be split (an
#              unclosed quote): shellwords then returns nothing at all,
#              and every option, --read-only and --user among them, would
#              be dropped without a word.
# Side effects: None.
sub _option_words {
	my ($self, $options, $context) = @_;

	return [] unless defined $options;

	my $text = $self->{expression}->interpolate("$options", $context);
	my @words = shellwords($text);
	# The text is quoted as the workflow wrote it, so a secret the
	# interpolation filled in is not printed.
	$self->throw('runner.options_invalid', { options => "$options", location => 0 })
		if !@words && $text =~ /\S/;

	return \@words;
}

# _list_args
# Purpose:     Turn a list of volumes or ports into repeated docker options.
# Entry:       $flag - '-v' or '-p'; $values - a scalar, a list or undef; $context.
# Exit status: Returns an array reference of flag, value pairs.
# Side effects: None.
sub _list_args {
	my ($self, $flag, $values, $context) = @_;

	# A single volume may be written as a scalar rather than a one-item list.
	my @values = !defined $values ? () : ref $values eq 'ARRAY' ? @{$values} : ($values);

	return [ map { ($flag, $self->{expression}->interpolate("$_", $context)) } @values ];
}

# _has_command
# Purpose:     Ask a running container whether it has a command.
# Entry:       $container; $command - a name such as 'bash'.
# Exit status: Returns 1 or 0.
# Side effects: Runs docker exec.
sub _has_command {
	my ($self, $container, $command) = @_;

	# The name is the script's first argument rather than part of its text,
	# so no value of it can be read as shell syntax.
	my (undef, $rc) = $self->{docker}->capture_silent(
		'exec', $container, 'sh', '-c', 'command -v "$1" >/dev/null 2>&1', 'sh', $command,
	);

	return $rc == 0 ? 1 : 0;
}

# _service_entrypoint
# Purpose:     The entrypoint a service's options give it, for an explain run.
# Entry:       $service - the mapping; $context.
# Exit status: Returns the entrypoint, or undef when the image's own is used.
# Side effects: None.
sub _service_entrypoint {
	my ($self, $service, $context) = @_;

	return undef unless defined $service->{options};    ## no critic (ProhibitExplicitReturnUndef)

	my @tokens = @{ $self->_option_words($service->{options}, $context) };
	my $entrypoint;
	for my $index (0 .. $#tokens) {
		# --entrypoint X and --entrypoint=X both say it; the first one wins.
		if ($tokens[$index] eq '--entrypoint' && defined $tokens[ $index + 1 ]) {
			$entrypoint = $tokens[ $index + 1 ];
		} elsif ($tokens[$index] =~ /\A--entrypoint=(.*)\z/s) {
			$entrypoint = $1;
		}
		last if defined $entrypoint;
	}

	return $entrypoint;
}

# _explain
# Purpose:     In an explain run, say what a container would be told to run.
#              A stopped service's diagnosis needs this: a service has no
#              command in the workflow, so its entrypoint and command are
#              the image's own.
# Entry:       %what - title, image, and optionally container, entrypoint, command.
# Exit status: Returns nothing.
# Side effects: Prints a block in an explain run.
sub _explain {
	my ($self, %what) = @_;

	return unless $self->{explain};

	my $own = $self->i18n('runner.explain.image_own');
	print $self->i18n('runner.explain.title', { title => $what{title} }), "\n";
	print $self->i18n('runner.explain.container', { name => $what{container} }), "\n" if defined $what{container};
	print $self->i18n('runner.explain.image', { image => $what{image} }), "\n";
	print $self->i18n('runner.explain.entrypoint', { entrypoint => defined $what{entrypoint} ? $what{entrypoint} : $own }), "\n";
	print $self->i18n('runner.explain.command', { command => defined $what{command} ? $what{command} : $own }), "\n";

	return;
}

# _restart_message
# Purpose:     Account for a restarting service: the state the daemon reports,
#              how many attempts its policy has made, and its last output,
#              which says whether the image or its command is at fault.
# Entry:       $what - "Service 'x'"; $status; $restarts; $name - the container.
# Exit status: Returns an App::Actions::Error (see _with_output).
# Side effects: Reads the container's log.
sub _restart_message {
	my ($self, $what, $status, $restarts, $name) = @_;

	my $state = $self->i18n((defined $status && $status eq 'dead') ? 'runner.container.dead' : 'runner.container.restarting', { what => $what });
	$state = $self->i18n('runner.container.with_count', { state => $state, count => $restarts })
		if defined $restarts && $restarts > 0;
	$state = $self->i18n('runner.container.count_unknown', { state => $state }) unless defined $restarts;

	return $self->_with_output('runner.container.restarting', $state, $self->{docker}->container_log_text($name),
		'runner.container.silent', 'runner.container.output');
}

# _stopped_message
# Purpose:     Account for a container that started and stopped: its exit
#              status and its last output.  "Did not stay running" alone
#              cannot tell a command that exited from an entrypoint that failed.
# Entry:       $what - "Service 'x'" or "Job container 'y'"; $name - the container.
# Exit status: Returns an App::Actions::Error (see _with_output).
# Side effects: Reads the container's exit code and log.
sub _stopped_message {
	my ($self, $what, $name) = @_;

	my $docker = $self->{docker};
	my $status = $docker->container_exit_code($name);
	my $state = defined $status
		? $self->i18n('runner.container.stopped', { what => $what, status => $status })
		: $self->i18n('runner.container.stopped_unknown', { what => $what });

	return $self->_with_output('runner.container.stopped', $state, $docker->container_log_text($name),
		'runner.container.silent', 'runner.container.output');
}

# _start_failure_message
# Purpose:     Account for a container the daemon refused to start.  It has no
#              output of its own, so the daemon's message is quoted, with the
#              part of the request it names; when it names nothing, no cause
#              is invented.
# Entry:       $what; $rc - docker's exit status; $said - the daemon's output;
#              %ran - the image and entrypoint the container was given.
# Exit status: Returns an App::Actions::Error (see _with_output).
# Side effects: None.
sub _start_failure_message {
	my ($self, $what, $rc, $said, %ran) = @_;

	my $state = $self->i18n('runner.container.start_failed', { what => $what, status => $rc });
	my $fault = $self->_start_fault($said, %ran);
	$state = $self->i18n('runner.container.at_fault', { state => $state, fault => $fault }) if defined $fault;

	return $self->_with_output('runner.container.start_failed', $state, $said,
		'runner.container.daemon_silent', 'runner.container.daemon_said');
}

# _start_fault
# Purpose:     Name the part of a start request the daemon's message blames:
#              the image ("No such image", "manifest unknown" ...), a port
#              ("port is already allocated"), or an entrypoint the image lacks.
# Entry:       $said - the daemon's output; %ran - image and entrypoint.
# Exit status: Returns the fault as a phrase, or undef when none is named.
# Side effects: None.
sub _start_fault {
	my ($self, $said, %ran) = @_;

	return undef unless defined $said && length $said;    ## no critic (ProhibitExplicitReturnUndef)

	my $lowered = lc $said;
	my $entrypoint = $ran{entrypoint};

	# The image is the commonest fault and the most specific complaint, so
	# it is looked for first; an entrypoint is only blamed when the message
	# names the one this container was given.
	return (grep { index($lowered, $_) >= 0 } @IMAGE_COMPLAINTS)
		? $self->i18n('runner.fault.image', { image => $ran{image} })
		: $said =~ /port is already allocated|address already in use/i
		? $self->i18n('runner.fault.port')
		: (defined $entrypoint && length $entrypoint && index($said, $entrypoint) >= 0
			&& $said =~ /no such file or directory|executable file not found/i)
		? $self->i18n('runner.fault.entrypoint', { entrypoint => $entrypoint })
		: undef;
}

# _with_output
# Purpose:     End a failure message with the container's (or daemon's) last
#              lines, or with a note that there were none.
# Entry:       $code - the error's code; $state - the message so far;
#              $output - the text to quote; $silent_key, $quoted_key - the
#              catalogue keys for the two endings.
# Exit status: Returns an App::Actions::Error with no source location, so it
#              stringifies to the message and a newline, as the plain string
#              it replaces did, and a caller can still ask for its code.
# Side effects: None.
sub _with_output {
	my ($self, $code, $state, $output, $silent_key, $quoted_key) = @_;

	# No CR from a Windows capture, and no trailing blank lines.
	my @lines = defined $output && length $output ? split /\n/, $output, -1 : ();
	pop @lines while @lines && $lines[-1] =~ /\A\s*\z/;
	s/\r\z// for @lines;

	my $message = @lines
		? $self->i18n($quoted_key, { state => $state }) . "\n" . join("\n", map { "  $_" } @lines)
		: $self->i18n($silent_key, { state => $state });

	return App::Actions::Error->new(code => $code, message => $message, location => "\n");
}

# _hostname
# Purpose:     A valid hostname for the job container, from the job's id.
# Entry:       $value - the job id.
# Exit status: Returns a name of at most 63 safe characters, with no hyphen
#              or dot at either end; 'local' if none is left.
# Side effects: None.
sub _hostname {
	my ($value) = @_;

	$value = '' unless defined $value;
	$value =~ s/[^A-Za-z0-9.-]/-/g;

	# A hostname may not begin or end with a hyphen or a dot, so a job id
	# such as _build or build_ loses them.  Each end separately, and the
	# end after the cut, which can leave one last.
	$value =~ s/\A[.-]+//;
	$value = substr($value, 0, $NAME_LENGTH);
	$value =~ s/[.-]+\z//;

	return length $value ? $value : 'local';
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

=item * Service credentials are not used: the local Docker login is.

=item * A container that a parallel job started outlives the run when that
job's process is killed, because only the process that started a container
knows its name.

=item * The fault named in a start failure comes from matching Docker's
English messages.  A daemon that reports in another language, or a future
Docker that rewords them, gets the quotation without a verdict.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Always call L</remove_all> at the end of a run>, even after an
error, unless the run keeps its containers.  Otherwise containers and
networks are left on the computer.

=item * B<Pass the same C<\@started> list to the start and clean-up
calls.>  L</cleanup_job> removes what is in that list, newest first.

=item * B<A service must keep running.>  A database image that exits at
once (for example because a required password variable is missing) fails
the job, with its last log lines in the message.

=item * B<Service ports are not published.>  Steps reach a service by its
id on the job's network (C<postgres:5432>), not on C<localhost>.  Only
C<ports:> mappings in the workflow publish ports on your computer.

=item * B<Container options from the workflow are passed to Docker as they
are.>  C<container.options> and C<container.volumes> can mount any folder
of your computer.  Run only workflows you trust.

=item * B<Names are cut to 63 characters.>  Very long job ids are
shortened, so do not rely on the full id being in the name.

=back

=head1 ENCODING

Container and network names are made ASCII: unsafe characters in job and
service ids are replaced.  Image names are ASCII, as Docker requires.
Environment values and C<options> come from the workflow as Perl character
strings and are passed to Docker as UTF-8 bytes, so non-ASCII text and emoji
work in values.  The project path is used as bytes.  The log lines quoted in
a failure message are what the container printed, as bytes.

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

	┌─ Containers ──────────────────────────────────────
	│ containers : seq NAME     -- started and not yet removed
	│ networks   : seq NAME     -- created and not yet removed
	│ counter    : ℕ           -- resource names issued
	├───────────────────────────────────────────────────
	│ containers and networks have no duplicates
	└───────────────────────────────────────────────────

=head2 name

	┌─ Name ────────────────────────────────────────────
	│ ΔContainers
	│ kind?, suffix? : seq CHAR
	│ name!          : seq CHAR
	├───────────────────────────────────────────────────
	│ counter' = counter + 1
	│ #name! ≤ 63 ∧ name! ∉ issued
	└───────────────────────────────────────────────────

=head2 create_network

	┌─ CreateNetwork ───────────────────────────────────
	│ ΔContainers
	│ job?  : JOB
	│ net!  : NAME
	├───────────────────────────────────────────────────
	│ networks' = networks ⁀ ⟨net!⟩
	└───────────────────────────────────────────────────

=head2 start_services

	┌─ StartServices ───────────────────────────────────
	│ ΔContainers
	│ job?     : JOB
	│ started! : seq (ID × NAME)
	├───────────────────────────────────────────────────
	│ dom started! = sorted(dom job?.services)
	│ ∀ (id, n) : ran started! • running(n) ∧ ¬ restarting(n)
	│ containers' = containers ⁀ ⟨n : ran started! • second n⟩
	└───────────────────────────────────────────────────

=head2 check_services

	┌─ CheckServices ───────────────────────────────────
	│ ΞContainers
	│ services? : seq (ID × NAME)
	├───────────────────────────────────────────────────
	│ (∃ (id, n) : ran services? • status(n) ∈ {restarting, dead} ∨ restarts(n) > 0)
	│     ⇒ raises Restarting(id)
	└───────────────────────────────────────────────────

=head2 start_job

	┌─ StartJob ────────────────────────────────────────
	│ ΔContainers
	│ image? : IMAGE
	│ c!     : NAME
	├───────────────────────────────────────────────────
	│ running(c!) ⇒ containers' = containers
	│ ¬ started(c!) ∨ ¬ running(c!) ⇒ raises StartFailure ∧ removed(c!)
	└───────────────────────────────────────────────────

=head2 inspect

	┌─ Inspect ─────────────────────────────────────────
	│ ΞContainers
	│ c?     : NAME
	│ facts! : FACTS
	├───────────────────────────────────────────────────
	│ facts!.path = aptbin ⁀ ":" ⁀ (if root ∧ ¬ has(c?, sudo) then bin ⁀ ":" else ⟨⟩) ⁀ path(c?)
	│ facts!.has_bash ⇔ has(c?, bash) ∧ facts!.has_node ⇔ has(c?, node)
	└───────────────────────────────────────────────────

=head2 run_action

	┌─ RunAction ───────────────────────────────────────
	│ ΞContainers
	│ image?  : IMAGE
	│ rc!     : ℤ
	├───────────────────────────────────────────────────
	│ rc! = exitStatus(docker run --rm ... image? arguments?)
	└───────────────────────────────────────────────────

=head2 cleanup_job

	┌─ CleanupJob ──────────────────────────────────────
	│ ΔContainers
	│ net?  : NAME
	│ cs?   : seq NAME
	├───────────────────────────────────────────────────
	│ keep ⇒ θContainers' = θContainers
	│ ¬ keep ⇒ containers' = containers ∖ ran cs? ∧ networks' = networks ∖ {net?}
	└───────────────────────────────────────────────────

=head2 remaining

	┌─ Remaining ───────────────────────────────────────
	│ ΞContainers
	│ r! : RESOURCES
	├───────────────────────────────────────────────────
	│ r!.containers = containers ∧ r!.networks = networks
	└───────────────────────────────────────────────────

=head2 remove_all

	┌─ RemoveAll ───────────────────────────────────────
	│ ΔContainers
	├───────────────────────────────────────────────────
	│ containers' = ⟨⟩ ∧ networks' = ⟨⟩
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object keeps a list of the networks and containers the run created and
has not yet removed.  One job's resources go through these states:

	  create_network($job)
	        |
	        v
	+----------------+
	| NETWORK MADE   |  recorded for remove_all
	+----------------+
	        |
	        | start_services($job, $network, ...)
	        v
	+----------------+  daemon refuses (bad image, entrypoint, port):
	| SERVICES       |  error quoting the daemon, naming the fault
	| STARTING       |--------------------------------------------+
	+----------------+                                            |
	        |                                                     |
	        | check_services: each still running, no restarts     |
	        v                                                     |
	+----------------+  exited / dead / restarting:               |
	| SERVICES UP    |  error with status, restart count and      |
	+----------------+  last log lines --------------------------->+
	        |                                                     |
	        | start_job($job, $network, $env, ...)                |
	        v                                                     |
	+----------------+  start refused --------------------------->+
	| JOB CONTAINER  |                                            |
	| RUNNING (idle) |  inspect: PATH, bash?, node? (for Steps)   |
	+----------------+                                            |
	        |                                                     |
	        | steps run (App::Actions::Runner::Steps);            |
	        | run_action for a docker:// step (own container,     |
	        | removed when it exits); check_services again at end |
	        v                                                     v
	+----------------+                                   +----------------+
	| JOB FINISHED   |                                   | JOB FAILED     |
	+----------------+                                   +----------------+
	        |                                                     |
	        +---------------------------+-------------------------+
	                                    |
	                cleanup_job($network, \@started)
	                                    |
	              keep? ---yes---> left running; listed by remaining()
	                |
	                no
	                v
	+----------------------------------+
	| REMOVED: containers newest first,|
	| then the network                 |
	+----------------------------------+

	At the end of the run, remove_all() removes anything still recorded
	(for example after an error or Ctrl-C), newest first.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
