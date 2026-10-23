package App::Actions::Runner::Steps;

use strict;
use warnings;
use autodie qw(:all);

use Readonly;
use Sub::Private ();
use Text::ParseWords qw(shellwords);

use App::Actions::Access;
use App::Actions::Action;
use App::Actions::I18N qw(i18n throw validate_args);
use App::Actions::Util ();
use App::Actions::Runner::Support qw(
	action_inputs boolean_value chomp_error env_args has_status_function
	local_action_dir redact resolve_env status_flags write_container_file
);

our $VERSION = '0.001.0';

# Where the project and the runner directory appear inside the container.
Readonly::Scalar my $WORKSPACE => '/github/workspace';
Readonly::Scalar my $RUNNER_DIR => '/github/actions-runner';

# How deeply local composite actions may use one another.
Readonly::Scalar my $MAX_DEPTH => 10;

# A step without a name is named after its command, cut to this length.
Readonly::Scalar my $NAME_LENGTH => 80;

# The step files a run gives every step, by kind: where each lives in the
# runner directory, its suffix, and the variable that tells the step.
Readonly::Hash my %STEP_FILE => (
	env => { dir => 'env', suffix => 'env', variable => 'GITHUB_ENV' },
	output => { dir => 'output', suffix => 'out', variable => 'GITHUB_OUTPUT' },
	path => { dir => 'path', suffix => 'path', variable => 'GITHUB_PATH' },
	summary => { dir => 'summary', suffix => 'md', variable => 'GITHUB_STEP_SUMMARY' },
	state => { dir => 'env', suffix => 'state', variable => 'GITHUB_STATE' },
);

# The shells a step may name, as GitHub runs them.  {0} is the script.
Readonly::Hash my %SHELL => (
	bash => { name => 'bash', command => 'bash --noprofile --norc -eo pipefail {0}', extension => '.sh', requires_bash => 1 },
	sh => { name => 'sh', command => 'sh -e {0}', extension => '.sh', requires_bash => 0 },
	perl => { name => 'perl', command => 'perl {0}', extension => '.pl', requires_bash => 0 },
	python => { name => 'python', command => 'python {0}', extension => '.py', requires_bash => 0 },
	pwsh => { name => 'pwsh', command => 'pwsh -File {0}', extension => '.ps1', requires_bash => 0 },
	powershell => { name => 'powershell', command => 'powershell -File {0}', extension => '.ps1', requires_bash => 0 },
);

# The shell a step gets when nothing names one: bash -e where the image has
# bash (a dry run assumes it does), sh -e where it has not.
Readonly::Hash my %DEFAULT_SHELL => (
	bash => { name => 'bash', command => 'bash -e {0}', extension => '.sh', requires_bash => 1 },
	sh => { name => 'sh', command => 'sh -e {0}', extension => '.sh', requires_bash => 0 },
);

# Well-known actions that need no running here: the repository is already
# mounted, the image already has the Perl that was asked for, and caching,
# artifacts and coverage uploads have nowhere to go.
Readonly::Scalar my $CHECKOUT => qr{\Aactions/checkout@}i;
Readonly::Scalar my $SETUP_PERL => qr{\A(?:shogo82148/actions-setup-perl|perl-actions/setup-perl)@}i;
Readonly::Scalar my $NO_OP => qr{
	\A
	(?:
		actions/cache (?: /restore | /save )?    # the cache, or half of it
		| actions/upload-artifact
		| actions/download-artifact
		| codecov/codecov-action
	)
	@                                          # any version
}xi;

=encoding utf-8

=head1 NAME

App::Actions::Runner::Steps - run the steps of one job in its container

=head1 SYNOPSIS

	my $steps = App::Actions::Runner::Steps->new(
		expression => $expression,
		docker => $docker,
		images => $images,
		containers => $containers,
		workflow => $workflow,
		project_dir => $project_dir,
		temp_path => $temp_path,
		job => $job,
		container => $container,
		network => $network,
		facts => $containers->inspect($container),
		job_env => $job_env,
		context => $context,
	);
	my $result = $steps->run;    # { result => 'success', env => {...} }

Decide what the job did:

	my $result = $steps->run;
	if ($result->{result} eq 'failure') {
		print "job failed\n";
	}
	print "TOKEN_SET\n" if exists $result->{env}{TOKEN};    # exported with GITHUB_ENV

=head1 DESCRIPTION

B<In short:> this module runs the steps of one job, one after another, in
the job's container, and passes values between them as GitHub does.  It is
a part of L<App::Actions::Runner>; you rarely use it on its own.

Executes a job's steps with C<docker exec> in its long-lived container, so
filesystem changes persist between steps while each step gets a fresh shell,
as on GitHub.  Each step gets its own C<GITHUB_ENV>, C<GITHUB_OUTPUT>,
C<GITHUB_PATH>, C<GITHUB_STEP_SUMMARY> and C<GITHUB_STATE> files, which are
read back after it: exported variables and C<PATH> additions reach the later
steps, outputs reach C<steps.ID.outputs>.

A step is a script (C<run>), a C<docker://> action, a local composite or
JavaScript action (C<uses: ./path>), or a well-known action that is a no-op
here.  Composite actions run their steps through the same machinery, one
level deeper.  JavaScript actions' C<pre> runs before C<main>, and C<post>
runs after the job's last step, in reverse order.

=head1 METHODS

=head2 new

Creates the executor for one job, after its container has started.

=head3 ARGUMENTS

=over 4

=item * C<expression>, C<docker>, C<images>, C<containers>, C<workflow> -
the run's collaborators.

=item * C<project_dir>, C<temp_path> - the project and the job's runner
directory on the host.

=item * C<job>, C<container>, C<network> - the job instance, its container
and its network.

=item * C<facts> - what L<App::Actions::Runner::Containers/inspect> found:
C<path>, C<has_bash>, C<has_node>.

=item * C<job_env>, C<context> - the job's environment and expression context.

=item * C<quiet>, C<verbose>, C<dry_run>, C<strict_actions> - optional flags;
C<user> - optional; the container user.

=back

=head3 RETURNS

An C<App::Actions::Runner::Steps> object.

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

See the L</SYNOPSIS>.

=head3 API SPECIFICATION

=head4 INPUT

	{
		expression     => { type => 'object', can => 'interpolate' },
		docker         => { type => 'object', can => 'container_exec' },
		images         => { type => 'object', can => 'ensure' },
		containers     => { type => 'object', can => 'run_action' },
		workflow       => { type => 'object', can => 'defaults' },
		project_dir    => { type => 'string', min => 1 },
		temp_path      => { type => 'string', min => 1 },
		job            => { type => 'hashref' },
		container      => { type => 'string', min => 1 },
		network        => { type => 'string', min => 1 },
		facts          => { type => 'hashref' },
		job_env        => { type => 'hashref' },
		context        => { type => 'hashref' },
		user           => { type => 'string', optional => 1 },
		quiet          => { type => 'boolean', optional => 1 },
		verbose        => { type => 'boolean', optional => 1 },
		dry_run        => { type => 'boolean', optional => 1 },
		strict_actions => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::Actions::Runner::Steps' }

=head3 MESSAGES

	+---------------------------+------------------------------+-----------------------------+
	| Message                   | Meaning                      | Resolution                  |
	+---------------------------+------------------------------+-----------------------------+
	| Invalid arguments to      | A collaborator is missing or | Pass the documented objects |
	| ...Steps::new: REASON     | an option has the wrong type |                             |
	+---------------------------+------------------------------+-----------------------------+

=cut

sub new {
	my $class = shift;

	my $params = validate_args(__PACKAGE__ . '::new', \@_, {
		expression => { type => 'object', can => 'interpolate' },
		docker => { type => 'object', can => 'container_exec' },
		images => { type => 'object', can => 'ensure' },
		containers => { type => 'object', can => 'run_action' },
		workflow => { type => 'object', can => 'defaults' },
		project_dir => { type => 'string', min => 1 },
		temp_path => { type => 'string', min => 1 },
		job => { type => 'hashref' },
		container => { type => 'string', min => 1 },
		network => { type => 'string', min => 1 },
		facts => { type => 'hashref' },
		job_env => { type => 'hashref' },
		context => { type => 'hashref' },
		user => { type => 'string', optional => 1 },
		share_files => { type => 'boolean', optional => 1 },
		quiet => { type => 'boolean', optional => 1 },
		verbose => { type => 'boolean', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
		strict_actions => { type => 'boolean', optional => 1 },
	});

	my $counter = 0;
	my $facts = delete $params->{facts};
	my $context = delete $params->{context};

	return bless {
		%{$params},
		base_path => $facts->{path},
		has_bash => $facts->{has_bash} ? 1 : 0,
		has_node => $facts->{has_node} ? 1 : 0,
		ctx => { %{$context}, env => $params->{job_env}, job => { status => 'success' } },
		# These three are shared with the scopes of composite actions: a
		# nested step is numbered after the outer ones, its PATH additions
		# reach the outer steps, and its post steps run with the job's.
		counter => \$counter,
		path_additions => [],
		post_actions => [],
		depth => 0,
		failed => 0,
	}, $class;
}

=head2 run

	my $result = $steps->run;

Runs every step of the job, then the post steps the JavaScript actions
deferred, in reverse order.

=head3 RETURNS

C<< { result => 'success' | 'failure', env => \%job_env } >>.

=head3 SIDE EFFECTS

Runs commands in the container, prints the steps and their output, and
writes and removes the step files.

=head3 EXAMPLE

	my $result = $steps->run;
	print "job failed\n" if $result->{result} eq 'failure';

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			result => { type => 'string', memberof => [ 'success', 'failure' ] },
			env    => { type => 'hashref' },
		},
	}

=head3 MESSAGES

	+-----------------------------+------------------------------+-----------------------------+
	| Message                     | Meaning                      | Resolution                  |
	+-----------------------------+------------------------------+-----------------------------+
	| action-run: unable to       | A step's env, if or          | Fix the expression          |
	| evaluate environment / if / | continue-on-error does not   |                             |
	| continue-on-error ...: E    | evaluate                     |                             |
	| !! step exited with status N| A step failed                | Read its output above       |
	| !! Step failed but          | It failed and the job goes on| None needed                 |
	| continue-on-error is set    |                              |                             |
	| action-run: action 'X'      | The action cannot run here   | Use --strict-actions to make|
	| skipped: REASON             |                              | it fail instead             |
	| Shell 'bash' is not         | The image has no bash        | Use shell: sh, or an image  |
	| available in the container  |                              | with bash                   |
	+-----------------------------+------------------------------+-----------------------------+

=cut

sub run {
	my ($self) = @_;

	$self->_execute_step($_) for @{ $self->{job}{steps} };
	$self->_run_post_actions;

	return { result => $self->{failed} ? 'failure' : 'success', env => $self->{job_env} };
}

# _execute_step
# Purpose:     Run one step in this scope.  A scope holds the job-level
#              environment, the expression context and the PATH additions, so
#              a composite action's steps reuse the same machinery as the
#              workflow's.
# Entry:       $step - the normalised step.
# Exit status: Returns the outcome: 'success', 'failure' or 'skipped'.
# Side effects: Runs the step; updates the job env, PATH additions, the
#              steps context and the failed flag; prints progress.
sub _execute_step {
	my ($self, $step) = @_;

	my ($ctx, $job_env) = @{$self}{qw(ctx job_env)};
	my $prefix = '  ' x $self->{depth};
	my $step_number = ++${ $self->{counter} };
	my $step_id = $step->{id};
	my $internal_id = defined $step_id ? $step_id : "__step_$step_number";

	# A step whose environment cannot be evaluated fails before its
	# condition is looked at, because the condition may read that env.
	my $step_env = eval { resolve_env($self->{expression}, [ $job_env, $step->{env} ], $ctx) };
	if (!$step_env) {
		$self->_complain('runner.step.env_failed', { step => $internal_id, error => chomp_error($@) });
		$self->_fail_job;
		$self->_record($step_id, 'failure', 'failure', {});
		return 'failure';
	}

	my $status = status_flags($self->{failed});
	my %condition_context = (%{$ctx}, env => $step_env);

	my $should_run = eval { $self->_should_run($step->{if}, \%condition_context, $status) };
	if (!defined $should_run) {
		$self->_complain('runner.step.if_failed', { step => $internal_id, error => chomp_error($@) });
		$self->_fail_job;
		return 'failure';
	}

	my $step_name = redact($self->{docker}, $self->_step_name($step, $step_number, \%condition_context));
	if (!$should_run) {
		$self->_say($prefix . $self->i18n('runner.step.skipped', { name => $step_name }));
		$self->_record($step_id, 'skipped', 'skipped', {});
		return 'skipped';
	}
	$self->_say($prefix . $self->i18n('runner.step.start', { name => $step_name }));

	# An error while running is the step's failure, not the job's end.
	my $result;
	my $ran = eval {
		my $kind = defined $step->{run} ? '_run_script_step' : '_run_uses_step';
		$result = $self->$kind($step, $step_number, $step_env, \%condition_context, $status);
		1;
	};
	if (!$ran) {
		my $error = chomp_error($@);
		$self->_complain('runner.error', { error => $error });
		$result = { outcome => 'failure', error => $error };
	}

	my $outcome = $self->_conclude($step, $result, $prefix, \%condition_context, $status);
	$self->_record($step_id, $outcome, $self->{last_conclusion}, $result->{outputs} || {});

	if (defined $result->{summary} && $result->{summary} =~ /\S/) {
		$self->_say($prefix . $self->i18n('runner.step.summary_header') . "\n$result->{summary}");
	}

	return $outcome;
}

# _should_run
# Purpose:     Decide a step's condition.  An `if` without a status function
#              gets an implicit success(), as on GitHub.
# Entry:       $condition - the step's if, or undef; $context; $status.
# Exit status: Returns 1 or 0; croaks when the condition does not evaluate.
# Side effects: None.
sub _should_run {
	my ($self, $condition, $context, $status) = @_;

	# No condition is an implicit success(), and so is a condition that names
	# no status function: either way a failed job skips the step.
	my $result = defined $condition ? ($self->{expression}->condition($condition, $context, $status) ? 1 : 0) : 1;
	my $implicit = !defined $condition || !has_status_function($condition);

	return ($result && $self->{failed} && $implicit) ? 0 : $result;
}

# _conclude
# Purpose:     Apply a step's result to the job: continue-on-error, the
#              failure message, exported variables, PATH additions and the
#              job status.
# Entry:       $step; $result - what the step returned; $prefix - indentation;
#              $context, $status - for evaluating continue-on-error.
# Exit status: Returns the outcome; leaves the conclusion in last_conclusion.
# Side effects: Updates the job env, PATH additions, ctx and failed flag;
#              prints the failure.
sub _conclude {
	my ($self, $step, $result, $prefix, $context, $status) = @_;

	my $continue = 0;
	if (defined $step->{'continue-on-error'}) {
		$continue = eval { boolean_value($self->{expression}, $step->{'continue-on-error'}, $context, $status) };
		$self->_complain('runner.step.continue_failed', { error => chomp_error($@) }) unless defined $continue;
	}

	my $outcome = $result->{outcome} || 'success';
	my $conclusion = $outcome;
	if ($outcome eq 'failure' && $continue) {
		$conclusion = 'success';
		$self->_say($prefix . $self->i18n('runner.step.continued'));
	} elsif ($outcome eq 'failure') {
		$self->{failed} = 1;
		my $message = $result->{error} || $self->i18n('runner.step.failed_default');
		print STDERR $self->i18n('runner.step.failure', { message => $message }), "\n" unless $self->{quiet};
	}

	# What the step exported is the job's from now on, and a path it added
	# goes in front of the ones added before it.
	my $job_env = $self->{job_env};
	$job_env->{$_} = $result->{env}{$_} for keys %{ $result->{env} || {} };
	unshift @{ $self->{path_additions} }, @{ $result->{path} || [] };

	$self->{ctx}{env} = $job_env;
	$self->{ctx}{job}{status} = $self->{failed} ? 'failure' : 'success';
	$self->{last_conclusion} = $conclusion;

	return $outcome;
}

# _record
# Purpose:     Make a step's result visible as steps.ID.* to the later steps.
# Entry:       $step_id - or undef, for a step without an id; $outcome;
#              $conclusion; $outputs.
# Exit status: Returns nothing.
# Side effects: Updates the steps context.
sub _record {
	my ($self, $step_id, $outcome, $conclusion, $outputs) = @_;

	$self->{ctx}{steps}{$step_id} = { outputs => $outputs, outcome => $outcome, conclusion => $conclusion }
		if defined $step_id;

	return;
}

# _fail_job
# Purpose:     Mark the job as failed, in the flag and in job.status.
# Entry:       None.
# Exit status: Returns nothing.
# Side effects: Sets failed; changes the context's job status.
sub _fail_job {
	my ($self) = @_;

	$self->{failed} = 1;
	$self->{ctx}{job}{status} = 'failure';

	return;
}

# _run_post_actions
# Purpose:     Run the post steps JavaScript actions deferred, in reverse
#              order, as GitHub does, each under its own condition.
# Entry:       None.
# Exit status: Returns nothing.
# Side effects: Runs node in the container; may mark the job failed.
sub _run_post_actions {
	my ($self) = @_;

	my $ctx = $self->{ctx};
	my $status = status_flags($self->{failed});

	for my $post (reverse @{ $self->{post_actions} }) {
		my %post_ctx = (
			%{$ctx},
			inputs => $post->{inputs},
			env => $self->{job_env},
			github => { %{ $ctx->{github} || {} }, action_path => $post->{action_path} },
		);

		my $should_run = eval { $self->{expression}->condition($post->{condition}, \%post_ctx, $status) };
		if (!defined $should_run) {
			$self->_complain('runner.post.if_failed', { uses => $post->{uses}, error => chomp_error($@) });
			next;
		}
		next unless $should_run;

		$self->_say($self->i18n('runner.post.start', { uses => $post->{uses} }));

		my $rc = eval {
			my $files = $self->_prepare_step_files(${ $self->{counter} } += 1, '-post');
			my %post_env = (%{ $self->{job_env} }, %{ $files->{vars} });
			$post_env{"STATE_$_"} = $post->{state}{$_} for keys %{ $post->{state} || {} };
			$self->_run_node_script($post->{script}, \%post_env, $post->{step_id}, $post->{action_path}, $post->{inputs});
		};

		# A failed post step fails the job, and later posts see failure().
		if (!defined $rc) {
			$self->_complain('runner.post.failed', { uses => $post->{uses}, error => chomp_error($@) });
		} elsif ($rc != 0) {
			print STDERR $self->i18n('runner.post.exited', { uses => $post->{uses}, status => $rc }), "\n"
				unless $self->{quiet};
		}
		next if defined $rc && $rc == 0;
		$self->{failed} = 1;
		$status = status_flags(1);
	}

	return;
}

# _run_script_step
# Purpose:     Run a `run:` step: write the script into the runner directory
#              and execute it in the job container with the step's shell.
# Entry:       $step; $step_number; $env - the step's environment;
#              $context, $status - for interpolation.
# Exit status: Returns a step result hash.
# Side effects: Writes the script; runs docker exec; reads the step files.
sub _run_script_step {
	my ($self, $step, $step_number, $env, $context, $status) = @_;

	my $shell = $self->_shell_for($step, $context, $status);
	return $self->_result(outcome => 'failure', error => $self->i18n('runner.shell.missing', { shell => $shell->{name} }))
		if $shell->{requires_bash} && !$self->{has_bash};

	my $script = $self->{expression}->interpolate($step->{run}, $context, $status);
	$script .= "\n" unless $script =~ /\n\z/;

	my $files = $self->_prepare_step_files($step_number);
	my $exec_env = $self->_exec_env($env, $files, defined $step->{id} ? $step->{id} : "__step_$step_number", $context->{github}{action_path});
	my $workdir = $self->_working_directory($step, $context, $status);

	# The script lives in the runner directory, which the container mounts.
	my $script_name = "step-$step_number$shell->{extension}";
	my $host_script = "$self->{temp_path}/scripts/$script_name";
	write_container_file($host_script, $script, $self->i18n('runner.what.step_script', { file => $host_script }));
	$self->_chmod_private($host_script);

	my $command = $shell->{command};
	my $quoted_script = _shell_quote("$RUNNER_DIR/scripts/$script_name");
	$command =~ s/\{0\}/$quoted_script/g or $command .= " $quoted_script";

	if ($self->{dry_run} && $self->{verbose}) {
		print $self->i18n('runner.script.begin'), "\n", redact($self->{docker}, $script), $self->i18n('runner.script.end'), "\n";
	}

	my $rc = $self->{docker}->container_exec('-w', $workdir, @{ env_args($exec_env) }, $self->{container}, 'sh', '-c', $command);

	return $self->_collected($files, $rc, 'runner.step.exited');
}

# _run_uses_step
# Purpose:     Run a `uses:` step: a well-known no-op, a docker:// action or
#              a local action; anything else is unsupported.
# Entry:       As _run_script_step.
# Exit status: Returns a step result hash.
# Side effects: As the action it runs.
sub _run_uses_step {
	my ($self, $step, $step_number, $env, $context, $status) = @_;

	my $action = $self->{expression}->interpolate($step->{uses}, $context, $status);
	my $with = $step->{with} || {};

	if ($action =~ $CHECKOUT) {
		# The repository is mounted, so what checkout would fetch is ignored;
		# each option that would have changed the checkout says so.
		$self->_complain('runner.checkout.path') if defined $with->{path} && length $with->{path};
		$self->_complain('runner.checkout.submodules') if defined $with->{submodules} && $with->{submodules} ne 'false';
		$self->_complain('runner.checkout.ref') if defined $with->{ref} || defined $with->{repository};
		return $self->_noop_result($self->i18n('runner.noop.checkout'));
	}

	if ($action =~ $SETUP_PERL) {
		my $version = $with->{'perl-version'};
		$version = $self->{expression}->interpolate($version, $context, $status) if defined $version;
		return $self->_noop_result(defined $version
			? $self->i18n('runner.noop.perl_version', { version => $version })
			: $self->i18n('runner.noop.perl'));
	}

	return $self->_noop_result($self->i18n('runner.noop.cache')) if $action =~ $NO_OP;
	return $self->_run_docker_action($step, $step_number, $1, $env, $context, $status) if $action =~ m{\Adocker://(.+)\z};
	return $self->_run_local_action($step, $step_number, $action, $env, $context, $status) if $action =~ m{\A\.\.?/};

	return $self->_unsupported_action($action, $self->i18n('runner.unsupported.remote'));
}

# _run_docker_action
# Purpose:     Run a docker:// action in a container of its own on the job's
#              network.  An image a step output decides is first known here,
#              so it is checked and prepared here.
# Entry:       $step; $step_number; $image - the text after docker://;
#              $env; $context; $status.
# Exit status: Returns a step result hash.
# Side effects: May pull the image; runs a container; reads the step files.
sub _run_docker_action {
	my ($self, $step, $step_number, $image, $env, $context, $status) = @_;

	my $job_id = $self->{job}{base_id};
	$image = $self->{expression}->interpolate($image, $context, $status);

	# It must be a real name before a container is started from it.
	$self->throw('runner.docker_action.no_image', { uses => $step->{uses}, job => $job_id }) unless length $image;
	$self->throw('runner.docker_action.bad_image', { uses => $step->{uses}, job => $job_id, image => $image })
		if $image =~ /\{\{/;

	$self->{images}->ensure($image);

	my $files = $self->_prepare_step_files($step_number);
	my $exec_env = $self->_exec_env($env, $files, defined $step->{id} ? $step->{id} : "__step_$step_number", $context->{github}{action_path});
	my $with = $step->{with} || {};

	my $rc = $self->{containers}->run_action(
		image => $image,
		network => $self->{network},
		workdir => $self->_working_directory($step, $context, $status),
		temp_path => $self->{temp_path},
		env => $exec_env,
		(defined $with->{entrypoint}
			? (entrypoint => $self->{expression}->interpolate("$with->{entrypoint}", $context, $status))
			: ()),
		arguments => [ defined $with->{args} ? shellwords($self->{expression}->interpolate("$with->{args}", $context, $status)) : () ],
		title => $self->i18n('runner.explain.action', { uses => $step->{uses}, job => $job_id }),
	);

	return $self->_collected($files, $rc, 'runner.docker_action.exited');
}

# _run_local_action
# Purpose:     Run an action that lives inside the project, such as
#              "uses: ./.github/actions/test".
# Entry:       $step; $step_number; $uses - the resolved reference; $env;
#              $context; $status.
# Exit status: Returns a step result hash.
# Side effects: Reads the action's metadata; runs it.
sub _run_local_action {
	my ($self, $step, $step_number, $uses, $env, $context, $status) = @_;

	# Resolved on the host and checked to be inside the project, links and all.
	my ($relative, $host_dir) = @{ local_action_dir($self->{project_dir}, $uses) }{qw(relative dir)};
	$self->throw('runner.local_action.missing', { uses => $uses, dir => $host_dir }) unless -d $host_dir;

	# A metadata error is already an exception with a code of its own, and
	# is passed on as it is.
	my $action = App::Actions::Action->load_from_dir($host_dir);
	my $container_path = "$WORKSPACE/$relative";
	my $inputs = action_inputs($self->{expression}, $action, $step, $uses, $context, $status);

	return $self->_run_composite_action($action, $step, $container_path, $inputs, $env, $context)
		if $action->is_composite;
	return $self->_run_javascript_action($action, $step, $step_number, $container_path, $inputs, $env, $context, $status)
		if $action->is_javascript;

	return $self->_unsupported_action($uses, $self->i18n('runner.unsupported.using', { using => $action->using }));
}

# _run_composite_action
# Purpose:     Run a composite action's steps in a scope one level deeper,
#              with its inputs, and an empty steps context of its own.
# Entry:       $action; $step; $container_path - where the action is inside
#              the container; $inputs; $env; $context.
# Exit status: Returns a step result hash with the action's outputs.
# Side effects: Runs the nested steps; variables they export reach the job.
sub _run_composite_action {
	my ($self, $action, $step, $container_path, $inputs, $env, $context) = @_;

	my $uses = $step->{uses};
	$self->throw('runner.composite.too_deep', { uses => $uses, depth => $MAX_DEPTH }) if $self->{depth} >= $MAX_DEPTH;

	my %nested_ctx = (
		%{$context},
		inputs => $inputs,
		steps => {},
		job => { status => $self->{failed} ? 'failure' : 'success' },
		github => { %{ $context->{github} || {} }, action_path => $container_path, action => $uses },
	);

	# The nested scope shares the counter, the PATH additions and the post
	# steps (they are references), and has its own env, context and failure.
	my $nested = bless {
		%{$self},
		ctx => \%nested_ctx,
		job_env => { %{$env} },
		depth => $self->{depth} + 1,
		failed => 0,
	}, ref $self;
	$nested->_execute_step($_) for @{ $action->steps };

	my %output_ctx = (%nested_ctx, env => $nested->{job_env});
	my $declared = $action->outputs || {};
	my %outputs = map { $_ => $self->{expression}->interpolate($declared->{$_}{value}, \%output_ctx) } keys %{$declared};

	# Variables exported inside the action belong to the caller's job env.
	for my $key (keys %{ $nested->{job_env} }) {
		next if exists $env->{$key} && "$env->{$key}" eq "$nested->{job_env}{$key}";
		$self->{job_env}{$key} = $nested->{job_env}{$key};
	}

	return $self->_result(
		outcome => $nested->{failed} ? 'failure' : 'success',
		outputs => \%outputs,
		error => $nested->{failed} ? $self->i18n('runner.composite.failed', { uses => $uses }) : undef,
	);
}

# _run_javascript_action
# Purpose:     Run a JavaScript action with node in the job container: its
#              pre step (under pre-if), its main step, and register its post
#              step (under post-if) for the end of the job.
# Entry:       $action; $step; $step_number; $container_path; $inputs; $env;
#              $context; $status.
# Exit status: Returns a step result hash merging what pre and main wrote.
# Side effects: Runs node; reads the step files; may queue a post step.
sub _run_javascript_action {
	my ($self, $action, $step, $step_number, $container_path, $inputs, $env, $context, $status) = @_;

	my $runs = $action->runs;
	my $uses = $step->{uses};
	$self->throw('runner.javascript.no_node', { uses => $uses }) unless $self->{has_node};

	my $step_id = defined $step->{id} ? $step->{id} : "__step_$step_number";
	my %merged = (env => {}, outputs => {}, path => [], summary => '', state => {});

	my $pre = $runs->{pre};
	if (defined $pre && length "$pre") {
		my $condition = defined $runs->{'pre-if'} ? $runs->{'pre-if'} : 'always()';
		my $should_run = eval { $self->{expression}->condition($condition, $context, $status) };
		if (!defined $should_run) {
			$self->_complain('runner.javascript.pre_if_failed', { uses => $uses, error => chomp_error($@) });
		} elsif ($should_run) {
			my $rc = $self->_run_node_phase("$container_path/$pre", "$step_number-pre", $env, $step_id, $container_path, $inputs, \%merged);
			return $self->_result(
				%merged,
				outcome => 'failure',
				exit_code => $rc,
				error => $self->i18n('runner.javascript.pre_exited', { uses => $uses, status => $rc }),
			) if $rc != 0;
		}
	}

	my $rc = $self->_run_node_phase("$container_path/$runs->{main}", $step_number, $env, $step_id, $container_path, $inputs, \%merged);

	my $post = $runs->{post};
	push @{ $self->{post_actions} }, {
		uses => $uses,
		script => "$container_path/$post",
		condition => defined $runs->{'post-if'} ? $runs->{'post-if'} : 'always()',
		inputs => $inputs,
		action_path => $container_path,
		step_id => $step_id,
		state => { %{ $merged{state} } },
	} if defined $post && length "$post";

	return $self->_result(
		%merged,
		outcome => $rc == 0 ? 'success' : 'failure',
		exit_code => $rc,
		error => $rc == 0 ? undef : $self->i18n('runner.javascript.exited', { uses => $uses, status => $rc }),
	);
}

# _run_node_phase
# Purpose:     Run one phase (pre or main) of a JavaScript action and fold
#              what it wrote into the action's result so far.
# Entry:       $script; $file_number - names the step files; $env; $step_id;
#              $container_path; $inputs; $merged - the running result,
#              including the saved state that later phases read as STATE_*.
# Exit status: Returns node's exit status.
# Side effects: Runs node; reads and removes the step files; updates $merged.
sub _run_node_phase {
	my ($self, $script, $file_number, $env, $step_id, $container_path, $inputs, $merged) = @_;

	my $files = $self->_prepare_step_files($file_number);
	my %exec_env = (%{$env}, %{ $files->{vars} });
	$exec_env{"STATE_$_"} = $merged->{state}{$_} for keys %{ $merged->{state} };

	my $rc = $self->_run_node_script($script, \%exec_env, $step_id, $container_path, $inputs);
	my $collected = $self->_collect_step_files($files, 1);

	# Later phases add to what the earlier ones wrote.
	%{ $merged->{env} } = (%{ $merged->{env} }, %{ $collected->{env} });
	%{ $merged->{outputs} } = (%{ $merged->{outputs} }, %{ $collected->{outputs} });
	push @{ $merged->{path} }, @{ $collected->{path} };
	$merged->{summary} .= $collected->{summary};
	%{ $merged->{state} } = (%{ $merged->{state} }, %{ $collected->{state} });

	return $rc;
}

# _run_node_script
# Purpose:     Execute a JavaScript entry point with the job environment, its
#              inputs as INPUT_* variables, and GITHUB_ACTION_PATH set.
# Entry:       $script - path in the container; $env - including the step
#              file variables; $step_id; $action_path; $inputs.
# Exit status: Returns node's exit status.
# Side effects: Runs docker exec.
sub _run_node_script {
	my ($self, $script, $env, $step_id, $action_path, $inputs) = @_;

	my $exec_env = $self->_exec_env($env, undef, $step_id, $action_path);
	for my $name (keys %{$inputs}) {
		(my $key = uc $name) =~ s/[^A-Z0-9_]/_/g;
		$exec_env->{"INPUT_$key"} = $inputs->{$name};
	}

	return $self->{docker}->container_exec('-w', $WORKSPACE, @{ env_args($exec_env) }, $self->{container}, 'node', $script);
}

# _exec_env
# Purpose:     The environment a command in the container runs with: the
#              step's variables, its step files, PATH with the additions in
#              front, and the GITHUB_ACTION values.
# Entry:       $env; $files - from _prepare_step_files, or undef when $env
#              already holds them; $action_id; $action_path - or undef.
# Exit status: Returns a new hash reference.
# Side effects: None.
sub _exec_env {
	my ($self, $env, $files, $action_id, $action_path) = @_;

	my %exec_env = (%{$env}, $files ? %{ $files->{vars} } : ());
	my $base = defined $exec_env{PATH} ? $exec_env{PATH} : $self->{base_path};
	$exec_env{PATH} = join ':', @{ $self->{path_additions} }, $base;
	$exec_env{GITHUB_ACTION} = $action_id;
	$exec_env{GITHUB_ACTION_PATH} = defined $action_path ? $action_path : '';

	return \%exec_env;
}

# _result
# Purpose:     A step result with every field present.
# Entry:       %fields - those that differ from a quiet success.
# Exit status: Returns a hash reference.
# Side effects: None.
sub _result {
	my (undef, %fields) = @_;

	return { outcome => 'success', env => {}, outputs => {}, path => [], summary => '', %fields };
}

# _collected
# Purpose:     The result of a step that ran one command: its exit status and
#              what it wrote to its step files.
# Entry:       $files; $rc; $error_key - the message for a non-zero status.
# Exit status: Returns a step result hash.
# Side effects: Reads and removes the step files.
sub _collected {
	my ($self, $files, $rc, $error_key) = @_;

	my $collected = $self->_collect_step_files($files, 0);

	return $self->_result(
		%{$collected},
		outcome => $rc == 0 ? 'success' : 'failure',
		exit_code => $rc,
		error => $rc == 0 ? undef : $self->i18n($error_key, { status => $rc }),
	);
}

# _noop_result
# Purpose:     The result of a well-known action that has nothing to do here.
# Entry:       $message - why, shown under the step.
# Exit status: Returns a successful step result.
# Side effects: Prints the reason unless quiet.
sub _noop_result {
	my ($self, $message) = @_;

	$self->_say($self->i18n('runner.noop', { message => $message }));

	return $self->_result;
}

# _unsupported_action
# Purpose:     The result of an action that cannot be run here: skipped, or a
#              failure under --strict-actions.
# Entry:       $action - the reference; $reason.
# Exit status: Returns a step result hash.
# Side effects: Prints the reason.
sub _unsupported_action {
	my ($self, $action, $reason) = @_;

	my $message = $self->i18n('runner.unsupported.skipped', { action => $action, reason => $reason });
	$self->_complain('runner.error', { error => $message });

	return $self->_result(outcome => 'failure', error => $message) if $self->{strict_actions};

	$self->_say($self->i18n('runner.unsupported.note', { reason => $reason }));

	return $self->_result(outcome => 'skipped');
}

# _shell_for
# Purpose:     Choose the shell a script step runs in: the step's, the job's
#              default, the workflow's default, or bash/sh.
# Entry:       $step; $context; $status.
# Exit status: Returns a shell description { name, command, extension, requires_bash }.
# Side effects: None.
sub _shell_for {
	my ($self, $step, $context, $status) = @_;

	my $shell = $self->_default_for($step, 'shell');
	return $DEFAULT_SHELL{ ($self->{dry_run} || $self->{has_bash}) ? 'bash' : 'sh' } unless defined $shell;

	$shell = $self->{expression}->interpolate("$shell", $context, $status);
	my $known = App::Actions::Util::trim(lc $shell);

	# Anything else is a command line of its own, with {0} for the script.
	return $SHELL{$known} || {
		name => 'custom',
		command => $shell =~ /\{0\}/ ? $shell : "$shell {0}",
		extension => '.sh',
		requires_bash => 0,
	};
}

# _working_directory
# Purpose:     The directory a step runs in, inside the container.
# Entry:       $step; $context; $status.
# Exit status: Returns an absolute path; a relative one is under the workspace.
# Side effects: None.
sub _working_directory {
	my ($self, $step, $context, $status) = @_;

	my $workdir = $self->_default_for($step, 'working-directory');
	$workdir = $WORKSPACE unless defined $workdir && length $workdir;

	$workdir = $self->{expression}->interpolate("$workdir", $context, $status);
	$workdir = $WORKSPACE unless length $workdir;

	return $workdir =~ m{\A/} ? $workdir : "$WORKSPACE/$workdir";
}

# _default_for
# Purpose:     A run setting from the step, else the job's defaults.run,
#              else the workflow's defaults.run.
# Entry:       $step; $key - 'shell' or 'working-directory'.
# Exit status: Returns the value, or undef when none of them sets it.
# Side effects: None.
sub _default_for {
	my ($self, $step, $key) = @_;

	my ($value) = grep { defined } (
		$step->{$key},
		$self->{job}{defaults}{run}{$key},
		$self->{workflow}->defaults->{run}{$key},
	);

	return $value;
}

# _step_name
# Purpose:     The name a step is shown with: its name, its uses, the first
#              80 characters of its script, or "Step N".
# Entry:       $step; $number; $context.
# Exit status: Returns the name, interpolated when it can be.
# Side effects: None.
sub _step_name {
	my ($self, $step, $number, $context) = @_;

	my $name = defined $step->{name} ? $step->{name} : $step->{uses};
	if (!defined $name && defined $step->{run}) {
		($name = $step->{run}) =~ s/\s+/ /g;
		$name = App::Actions::Util::trim($name);
		$name = substr($name, 0, $NAME_LENGTH - 3) . '...' if length $name > $NAME_LENGTH;
	}
	$name = $self->i18n('runner.step.default_name', { number => $number }) unless defined $name && length $name;

	# A name with an expression the context cannot evaluate is shown as written.
	my $value = eval { $self->{expression}->interpolate($name, $context) };

	return defined $value ? $value : $name;
}

# _prepare_step_files
# Purpose:     Create a step's empty GITHUB_ENV, GITHUB_OUTPUT, GITHUB_PATH,
#              GITHUB_STEP_SUMMARY and GITHUB_STATE files.
# Entry:       $number - names the files; $suffix - optional, such as '-post'.
# Exit status: Returns { host => { kind => path }, vars => { VARIABLE => container path } }.
# Side effects: Creates the files, private unless the container runs as
#              another user.
sub _prepare_step_files {
	my ($self, $number, $suffix) = @_;

	my $prefix = 'step-' . $number . (defined $suffix ? $suffix : '');
	my (%host, %vars);

	for my $kind (keys %STEP_FILE) {
		my $file = "$STEP_FILE{$kind}{dir}/$prefix.$STEP_FILE{$kind}{suffix}";
		$host{$kind} = "$self->{temp_path}/$file";
		$vars{ $STEP_FILE{$kind}{variable} } = "$RUNNER_DIR/$file";

		# Created exclusively, as every file of the run is: see
		# App::Actions::Runner::Support::write_container_file.
		write_container_file($host{$kind}, '', $self->i18n('runner.what.step_file', { file => $host{$kind} }));
		$self->_chmod_private($host{$kind});
	}

	return { host => \%host, vars => \%vars };
}

# _collect_step_files
# Purpose:     Read what a step wrote to its files, then remove them.
# Entry:       $files - from _prepare_step_files; $keep_state - read and keep
#              GITHUB_STATE, for a JavaScript action's later phases.
# Exit status: Returns { env, outputs, path, summary, state }.
# Side effects: Removes the files (the state file only when it was not kept).
sub _collect_step_files {
	my (undef, $files, $keep_state) = @_;

	my $host = $files->{host};
	my %collected = (
		env => _parse_kv_file($host->{env}),
		outputs => _parse_kv_file($host->{output}),
		path => _read_lines($host->{path}),
		summary => _read_file($host->{summary}),
		state => $keep_state ? _parse_kv_file($host->{state}) : {},
	);

	# A file the step removed itself is not an error.
	my @remove = grep { -e $_ } map { $host->{$_} } grep { !($keep_state && $_ eq 'state') } keys %{$host};
	{
		no autodie qw(unlink);
		unlink @remove;
	}

	return \%collected;
}

# _parse_kv_file
# Purpose:     Read a GITHUB_ENV or GITHUB_OUTPUT file: NAME=value lines and
#              NAME<<DELIMITER blocks.
# Entry:       $path - the file, which may not exist.
# Exit status: Returns a hash reference; empty for a missing file.
# Side effects: None.
sub _parse_kv_file {
	my ($path) = @_;

	my %values;
	my $handle = _open_if_readable($path);
	return \%values unless $handle;

	while (defined(my $line = <$handle>)) {
		$line =~ s/\r?\n\z//;
		if ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s) {
			$values{$1} = $2;
		} elsif ($line =~ /\A([A-Za-z_][A-Za-z0-9_]*)<<(\S+)\z/) {
			# A heredoc: every line up to the delimiter is the value.
			my ($name, $delimiter, @lines) = ($1, $2);
			while (defined(my $body = <$handle>)) {
				$body =~ s/\r?\n\z//;
				last if $body eq $delimiter;
				push @lines, $body;
			}
			$values{$name} = join "\n", @lines;
		}
	}
	close $handle;

	return \%values;
}

# _read_lines
# Purpose:     Read a GITHUB_PATH file: one directory per non-blank line.
# Entry:       $path - the file, which may not exist.
# Exit status: Returns an array reference of trimmed lines.
# Side effects: None.
sub _read_lines {
	my ($path) = @_;

	my $handle = _open_if_readable($path);
	return [] unless $handle;

	my @lines;
	while (defined(my $line = <$handle>)) {
		$line = App::Actions::Util::trim($line);    # the newline is trailing white space too
		push @lines, $line if length $line;
	}
	close $handle;

	return \@lines;
}

# _read_file
# Purpose:     Read a GITHUB_STEP_SUMMARY file whole.
# Entry:       $path - the file, which may not exist.
# Exit status: Returns the contents, or '' for a missing file.
# Side effects: None.
sub _read_file {
	my ($path) = @_;

	my $handle = _open_if_readable($path);
	return '' unless $handle;

	my $contents = do { local $/; <$handle> };
	close $handle;

	return defined $contents ? $contents : '';
}

# _open_if_readable
# Purpose:     Open a step file for reading if the step left one.
# Entry:       $path - or undef.
# Exit status: Returns a handle, or undef when there is nothing to read.
# Side effects: None.
sub _open_if_readable {
	my ($path) = @_;

	return undef unless defined $path && -f $path;    ## no critic (ProhibitExplicitReturnUndef)

	# A file that vanished or cannot be read holds nothing for the job.
	no autodie qw(open);
	my $opened = open(my $handle, '<', $path);

	return $opened ? $handle : undef;
}

# _chmod_private
# Purpose:     Make a runner file private, unless the container runs as
#              another user, who must be able to write it.  The files may hold
#              secrets from the environment.
# Entry:       $path.
# Exit status: Returns nothing.
# Side effects: Changes the file's mode; a failure is ignored, as the run
#              can go on with the mode it has.
sub _chmod_private {
	my ($self, $path) = @_;

	no autodie qw(chmod);
	chmod($self->{share_files} ? oct('0666') : oct('0600'), $path);

	return;
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
# Purpose:     Print a warning from the catalogue unless the run is quiet.
# Entry:       $key; $args - optional.
# Exit status: Returns nothing.
# Side effects: Prints to standard error.
sub _complain {
	my ($self, $key, $args) = @_;

	print STDERR $self->i18n($key, $args), "\n" unless $self->{quiet};

	return;
}

# _shell_quote
# Purpose:     Quote a path for sh.
# Entry:       $value.
# Exit status: Returns the value in single quotes, with its own quotes escaped.
# Side effects: None.
sub _shell_quote {
	my ($value) = @_;

	($value = defined $value ? $value : '') =~ s/'/'\\''/g;

	return "'$value'";
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

=item * Remote actions (C<uses: owner/repo@ref>) are not fetched, and a local
action that uses C<docker> is not built; both are skipped, or fail under
C<strict_actions>.

=item * C<pre> and C<post> run only for JavaScript actions; a composite
action has neither, as on GitHub, but a C<docker> action's
C<pre-entrypoint> and C<post-entrypoint> would have them and are not run.

=item * C<timeout-minutes> is not applied to steps.

=item * A step that changes its working directory with C<cd> does not change
the next step's: each step starts where its C<working-directory> says.

=back

=head1 COMMON PITFALLS

=over 4

=item * B<Each step starts a new shell.>  A C<cd> or an C<export> in one
step does not reach the next.  Use C<working-directory:>, or write
C<NAME=value> to C<$GITHUB_ENV>.

=item * B<C<bash> must be in the image for C<shell: bash>.>  A plain Alpine
image has only C<sh>; the step then fails with C<Shell 'bash' is not
available>.

=item * B<JavaScript actions need C<node> in the image.>

=item * B<A failed step stops the job's later steps>, except those with
C<if: failure()> or C<if: always()>, and except when the step has
C<continue-on-error: true>.

=item * B<Some well-known actions do nothing here.>  C<actions/checkout>
(your project is already mounted), setup-perl (the image already has Perl),
cache, artifact and Codecov actions are skipped as successes.

=item * B<Secrets are in the step files.>  The script of each step is
written to the runner folder; it is private to you unless the job runs as
another user (see L<App::Actions::Runner/LIMITATIONS>).

=back

=head1 ENCODING

Step commands, environment values, inputs and outputs are Perl character
strings; they may contain any Unicode text, including non-ASCII characters
and emoji.  Step scripts and the C<GITHUB_*> files are written as UTF-8,
with LF line endings, and the files a step writes back (C<GITHUB_ENV>,
C<GITHUB_OUTPUT>, ...) are read as UTF-8.  What a step prints goes to your
terminal as bytes, unchanged.

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

	┌─ Steps ───────────────────────────────────────────
	│ ctx       : CONTEXT
	│ jobEnv    : NAME ⇸ seq CHAR
	│ pathAdds  : seq PATH
	│ counter   : ℕ
	│ posts     : seq POST
	│ depth     : ℕ
	│ failed    : 𝔹
	├───────────────────────────────────────────────────
	│ depth ≤ 10 ∧ ctx.env = jobEnv
	└───────────────────────────────────────────────────

=head2 run

	┌─ Run ─────────────────────────────────────────────
	│ ΔSteps
	│ result! : {success, failure}
	├───────────────────────────────────────────────────
	│ result! = (if failed' then failure else success)
	│ failed' ⇔ (∃ s : job.steps • outcome(s) = failure ∧ ¬ continueOnError(s))
	│           ∨ (∃ p : posts • failed(p))
	└───────────────────────────────────────────────────

=head1 STATE DIAGRAM

One call to L</run> takes each step through these states:

	  run()
	    |
	    v
	+---------------------+
	| NEXT STEP           |<-------------------------------------------+
	+---------------------+                                            |
	    |  none left -> RUN POSTS                                      |
	    v                                                              |
	+---------------------+  if: is false (by default: the job has     |
	| EVALUATE if:        |  not failed) -> SKIPPED ------------------>+
	+---------------------+                                            |
	    |  true                                                        |
	    v                                                              |
	+---------------------+  fresh GITHUB_ENV, GITHUB_OUTPUT,          |
	| PREPARE STEP FILES  |  GITHUB_PATH, GITHUB_STATE,                |
	| (O_EXCL, mode 0600) |  GITHUB_STEP_SUMMARY files                 |
	+---------------------+                                            |
	    |                                                              |
	    v                                                              |
	  what kind of step?                                               |
	    +-- run: ------------> script written; docker exec SHELL script |
	    +-- docker://IMAGE --> Containers->run_action (own container)   |
	    +-- ./local composite-> its steps, through this same machine    |
	    +-- ./local javascript-> pre now; main now; post queued         |
	    +-- known no-op -----> success without running anything         |
	    +-- other remote ----> skipped (strict_actions: failure)        |
	    |                                                              |
	    v                                                              |
	+---------------------+  exported env -> later steps;              |
	| READ BACK FILES     |  PATH additions; outputs ->                |
	+---------------------+  steps.ID.outputs; summary kept            |
	    |                                                              |
	    v                                                              |
	  status 0? --yes--> SUCCESS ------------------------------------->+
	    | no                                                           |
	    v                                                              |
	  continue-on-error? --yes--> warned; job still succeeding ------->+
	    | no                                                           |
	    v                                                              |
	  JOB FAILING: later steps run only if their if: says so --------->+

	+---------------------+  queued JavaScript post steps,
	| RUN POSTS           |  last queued first
	+---------------------+
	    |
	    v
	  return { result => 'success' | 'failure', env => job env }

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
