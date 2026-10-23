use strict;
use warnings;
use utf8;

use File::Temp ();
use Test::Most;

use App::Actions::Expression;
use App::Actions::Runner;
use App::Actions::Runner::Containers;
use App::Actions::Runner::Images;
use App::Actions::Runner::Parallel;
use App::Actions::Runner::Report;
use App::Actions::Runner::Support qw(
	action_inputs boolean_value chomp_error env_args has_status_function local_action_path
	redact resolve_env status_flags trim_error write_container_file
);

# The runner's parts, each on its own: t/runner.t drives them together through
# a fake Docker daemon, and these tests pin down what each promises.

# A Docker object that records what it is asked and answers from a table.
{
	package Local::Docker;
	sub new { my ($class, %answers) = @_; return bless { calls => [], %answers }, $class }
	sub image_exists { my ($self, $image) = @_; push @{ $self->{calls} }, "exists $image"; return $self->{present}{$image} ? 1 : 0 }
	sub pull { my ($self, $image) = @_; push @{ $self->{calls} }, "pull $image"; return 0 }
	sub container_start { return 0 }
	sub container_exit_code { return $_[0]->{exit_code} }
	sub container_log_text { return $_[0]->{logs} }
	sub redact { my ($self, $text) = @_; $text =~ s/hunter2/***/g; return $text }
}

# A workflow object as far as the image preparer needs one.
{
	package Local::Workflow;
	sub new { return bless {}, $_[0] }
	sub container_image { return undef }
	sub expand_jobs { return [] }
}

my $expression = App::Actions::Expression->new;
my $temp = File::Temp->newdir;

subtest 'status flags and the status functions' => sub {
	is_deeply(status_flags(0), { success => 1, failure => 0, cancelled => 0 }, 'a job going well');
	is_deeply(status_flags(1), { success => 0, failure => 1, cancelled => 0 }, 'a job that has failed');
	ok(has_status_function('always() && matrix.os == "linux"'), 'always() is a status function');
	ok(has_status_function('${{ failure() }}'), 'so is failure(), inside an expression');
	ok(!has_status_function('matrix.os == "linux"'), 'a plain condition has none');
};

subtest 'errors are trimmed for a reader' => sub {
	is(chomp_error("went wrong\n\n"), 'went wrong', 'chomp_error drops the trailing space');
	is(trim_error("No job matched 'x' at lib/App/Actions/Runner.pm line 9.\n"), "No job matched 'x'",
		'trim_error drops the location too');
	is(trim_error(undef), undef, 'and has nothing to say about nothing');
};

subtest 'environment layers resolve in order and in terms of each other' => sub {
	my $env = resolve_env($expression, [ { A => 'x', C => 'first' }, undef, { B => '${{ env.A }}y', C => 'last' } ], {});
	is_deeply($env, { A => 'x', B => 'xy', C => 'last' }, 'a later layer wins, and refers to an earlier one');

	throws_ok { resolve_env($expression, [ { A => '${{ nosuch( }}' } ], {}) }
		qr/^Unable to evaluate environment variable 'A':/, 'an expression that cannot be evaluated is named';
};

subtest 'booleans are read as GitHub reads them' => sub {
	is(boolean_value($expression, 'true', {}, status_flags(0)), 1, 'true');
	is(boolean_value($expression, 'false', {}, status_flags(0)), 0, 'false');
	is(boolean_value($expression, '${{ matrix.experimental }}', { matrix => { experimental => 1 } }, status_flags(0)), 1,
		'an expression is evaluated');
};

subtest 'local action paths stay inside the project' => sub {
	is(local_action_path('./.github/actions/build/'), '.github/actions/build', 'the leading ./ and trailing / go');
	throws_ok { local_action_path('./') } qr/^Local action '\.\/' does not name a directory inside the project/,
		'an empty path is refused';
	throws_ok { local_action_path('./../elsewhere') } qr/^Local action '\.\/\.\.\/elsewhere' must not escape/,
		'a path out of the project is refused';
};

subtest 'container files and docker arguments' => sub {
	my $path = "$temp/script.sh";
	write_container_file($path, "echo hi\n", 'the step script');
	open my $handle, '<:raw', $path or die "cannot read $path: $!";
	is(do { local $/; <$handle> }, "echo hi\n", 'the file is written as given, with LF line ends');
	close $handle;

	throws_ok { write_container_file("$temp/no/such/dir/x", 'x', 'the test file') }
		qr/^Unable to write the test file:/, 'a file that cannot be written says which one';

	my $args = env_args({ B => 2, A => 1 });
	is_deeply([ map { "$_" } @{$args} ], [ '-e', 'A=1', '-e', 'B=2' ], 'variables become sorted -e arguments');
	isa_ok($args->[1], 'App::Actions::Docker::Variable', 'each variable');
	is_deeply([ $args->[1]->name, $args->[1]->value ], [ 'A', '1' ], 'which knows its name and value apart');
	is(redact(Local::Docker->new, 'token is hunter2'), 'token is ***', 'secrets are masked through Docker');
	is(redact(bless({}, 'Local::Plain'), 'as is'), 'as is', 'an object that cannot redact leaves the text alone');
};

subtest 'action inputs take the step value, then the default' => sub {
	{
		package Local::Action;
		sub new { return bless { inputs => $_[1] }, $_[0] }
		sub inputs { return $_[0]->{inputs} }
	}
	my $action = Local::Action->new({
		name => { required => 1 },
		greeting => { default => 'hello' },
	});

	my $inputs = action_inputs($expression, $action, { with => { name => 'x' } }, './greet', {}, status_flags(0));
	is($inputs->{name}, 'x', 'the step gives a value');
	is($inputs->{greeting}, 'hello', 'the action gives the default');

	throws_ok { action_inputs($expression, $action, { with => {} }, './greet', {}, status_flags(0)) }
		qr/^Action '\.\/greet' requires the input 'name'/, 'a required input that is missing is named';
};

subtest 'the report prints the summary and remembers failure' => sub {
	my $report = App::Actions::Runner::Report->new(docker => Local::Docker->new);
	ok(!$report->failed, 'nothing has failed yet');

	is($report->record('build hunter2', 'success'), $report, 'record returns the report');
	$report->record('test', 'failure')->fail;
	ok($report->failed, 'fail marks the workflow failed');

	my $printed = '';
	{
		open my $sink, '>', \$printed or die;
		my $old = select $sink;
		$report->print_summary;
		$report->report_images([
			{ image => 'perl:5.40', source => "job 'test'", status => 'present' },
			{ image => undef, expression => '${{ needs.a.outputs.image }}', source => undef, status => 'deferred', error => 'not yet' },
		]);
		$report->print_kept_resources({ containers => [ 'c1' ], networks => [ 'n1' ] }, '/tmp/x');
		select $old;
	}
	like($printed, qr/^=== Workflow summary ===$/m, 'the summary has its heading');
	like($printed, qr/^  build \*\*\*\s+success$/m, 'a job is listed with its result, its secrets masked');
	like($printed, qr/^Workflow FAILED$/m, 'and the workflow is said to have failed');
	like($printed, qr/^  image     perl:5\.40 \(job 'test'\): present$/m, 'a prepared image is listed');
	like($printed, qr/^  image     \$\{\{ needs\.a\.outputs\.image \}\} \(the workflow\): deferred$/m,
		'a deferred one by its expression, with the workflow as its source');
	like($printed, qr/^  deferred  not yet$/m, 'and why it was deferred');
	like($printed, qr/^Kept Docker resources:\n  container c1\n  network n1\n  temporary directory \/tmp\/x$/m,
		'what a kept run left behind is listed');

	my $quiet = App::Actions::Runner::Report->new(docker => Local::Docker->new, quiet => 1);
	my $silent = '';
	{
		open my $sink, '>', \$silent or die;
		my $old = select $sink;
		$quiet->record('x', 'success')->print_summary;
		select $old;
	}
	is($silent, '', 'a quiet report prints no summary');
};

subtest 'the image preparer pulls once and honours --no-pull' => sub {
	my $docker = Local::Docker->new(present => { 'have:1' => 1 });
	my %common = (
		docker => $docker, expression => $expression, workflow => Local::Workflow->new,
		project_dir => "$temp", context => sub { {} }, quiet => 1,
	);

	my $images = App::Actions::Runner::Images->new(%common);
	ok($images->ensure('have:1'), 'an image that is present is ready');
	ok($images->ensure('want:1'), 'one that is not is pulled');
	ok($images->ensure('want:1'), 'and is ready the second time without a second pull');
	is(scalar(grep { $_ eq 'pull want:1' } @{ $docker->{calls} }), 1, 'it was pulled once');
	is_deeply($images->pulled, [ 'want:1' ], 'and is remembered as pulled by this run');
	is_deeply($images->note_pulled('probe:1', '', undef)->pulled, [ 'probe:1', 'want:1' ],
		'an image pulled elsewhere can be noted, and empty names are ignored');

	my $offline = App::Actions::Runner::Images->new(%common, no_pull => 1);
	throws_ok { $offline->ensure('want:2') }
		qr/^Docker image 'want:2' is not available locally \(--no-pull\)\n\z/, '--no-pull refuses to fetch it';

	is($images->failure_message({ image => 'x:1', source => "job 'a'", error => 'denied' }),
		"cannot prepare the image 'x:1', needed by job 'a': denied", 'a failure names the image, its user and the cause');
	like($images->concurrency, qr/\A[1-9][0-9]*\z/, 'the pull concurrency is a positive integer');
};

subtest 'container names and failure accounts' => sub {
	my $docker = Local::Docker->new(exit_code => 3, logs => "line one\r\nline two\n\n");
	my $containers = App::Actions::Runner::Containers->new(
		docker => $docker, expression => $expression, project_dir => "$temp", run_id => '0123456789abcdef', quiet => 1,
	);

	my $job = { base_id => 'build & test', matrix_index => 2 };
	my $first = $containers->name('job', $job);
	is($first, 'action-run-89abcdef-1-job-build---test-2', 'a name is safe for Docker and says whose it is');
	isnt($containers->name('job', $job), $first, 'every name is new');
	ok(length($containers->name('svc', { base_id => 'x' x 100, matrix_index => 0 }, 'y' x 100)) <= 63,
		'and short enough to be a hostname');

	local $Sub::Private::BYPASS = 1;
	my $stopped = $containers->_stopped_message("Service 'db'", 'c1');
	ok(App::Actions::Error->caught($stopped), 'a container that stopped is reported as an error object');
	ok($stopped->is('runner.container.stopped'), 'with a code that says what happened');
	is("$stopped", "Service 'db' did not stay running (exit 3); its last output was:\n  line one\n  line two\n",
		'and the last lines it printed, without carriage returns or trailing blank lines');

	my $refused = $containers->_start_failure_message("Job container 'j'", 125,
		"docker: Error response from daemon: No such image: nope:1\n", image => 'nope:1');
	ok($refused->is('runner.container.start_failed'), 'a refused start has its own code');
	like("$refused", qr/\AJob container 'j' could not be started \(exit 125\); at fault: the image 'nope:1'; the daemon said:\n/,
		'and names the part of the request the daemon blamed');

	my $dead = $containers->_restart_message("Service 'db'", 'dead', undef, 'c1');
	ok($dead->is('runner.container.restarting'), 'a service its restart policy gave up on is a restart failure');
	like("$dead", qr/\AService 'db' is dead \(its restart count could not be read\); its last output was:\n/,
		'and says when the count is unknown');

	$docker->{logs} = '';
	my $silent = $containers->_restart_message("Service 'db'", 'restarting', 4, 'c1');
	is("$silent", "Service 'db' is restarting (restart count 4); it printed nothing\n",
		'a restarting service says how often, and that it printed nothing');
};

subtest 'parallel jobs run beside each other and report in plan order' => sub {
	plan skip_all => 'jobs run one at a time where fork() is not reliable' if $^O eq 'MSWin32';

	my @noted;
	my $parallel = App::Actions::Runner::Parallel->new(
		capacity => 3,
		temp_path => "$temp",
		quiet => 1,
		run_job => sub { my ($entry) = @_; return { result => $entry->{plan}{display_name} =~ /bad/ ? 'failure' : 'success', pulled => [ 'img' ] } },
		on_result => sub { push @noted, $_[0] },
	);

	my @plans = map { { display_name => "test (n=$_)", max_parallel => undef } } qw(one bad three);
	my $outcomes = $parallel->run(\@plans, 0);
	is(scalar @{$outcomes}, 3, 'one outcome per plan');
	is_deeply([ map { $_->{plan}{display_name} } @{$outcomes} ], [ map { $_->{display_name} } @plans ], 'in plan order');
	is_deeply([ map { $_->{result}{result} } @{$outcomes} ], [qw(success failure success)], 'with each job\'s result');
	is(scalar @noted, 3, 'and each result was handed back as it arrived');
	is(scalar @{ $parallel->logs }, 3, 'every job kept a log');

	is($parallel->run([ $plans[0] ], 0), undef, 'a single job is left to the caller to run');
	is($parallel->run([ map { { %{$_}, max_parallel => 1 } } @plans ], 0), undef, 'and so is a group capped at one');

	local $Sub::Private::BYPASS = 1;
	is(App::Actions::Runner::Parallel::_log_name(2, 'test (n=bad)'), 'job-2-test_n_bad.log', 'a log is named after its job');
	is(App::Actions::Runner::Parallel::_log_name(4, '()'), 'job-4.log', 'or after its slot alone');
};

subtest 'the runner shares its option rules and checks its values' => sub {
	my $rules = App::Actions::Runner->option_rules;
	ok(exists $rules->{$_}, "$_ is an option") for qw(jobs image parallel pull_concurrency keep_images cache_file);
	$rules->{jobs}{type} = 'string';
	is(App::Actions::Runner->option_rules->{jobs}{type}, 'arrayref', 'the rules are handed out as a copy');

	my $workflow = Local::Workflow->new;
	my %base = (workflow => $workflow, project_dir => "$temp", docker => Local::Docker->new);

	throws_ok { App::Actions::Runner->new(project_dir => "$temp") } qr/^A workflow is required/, 'a workflow is required';
	throws_ok { App::Actions::Runner->new(workflow => $workflow) } qr/^A project directory is required/,
		'so is a project directory';
	throws_ok { App::Actions::Runner->new(%base, project_dir => "$temp/missing") }
		qr/^Project directory '.+missing' does not exist/, 'which must exist';
	throws_ok { App::Actions::Runner->new(%base, pull_concurrency => 'lots') }
		qr/^pull concurrency must be a positive integer, not 'lots'/, 'the pull concurrency is a positive integer';
	throws_ok { App::Actions::Runner->new(%base, pull => 1, no_pull => 1) }
		qr/^--pull and --no-pull cannot be used together/, '--pull and --no-pull conflict';
	throws_ok { App::Actions::Runner->new(%base, colour => 'red') } qr/^Invalid arguments/, 'an unknown option is refused';

	my $runner = App::Actions::Runner->new(%base, parallel => 'many');
	isa_ok($runner, 'App::Actions::Runner');
	is($runner->workflow, $workflow, 'the runner keeps its workflow');
};

done_testing();
