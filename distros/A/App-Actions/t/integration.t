use strict;
use warnings;

# Black-box, end-to-end tests: each subtest drives a workflow through several
# modules at once - App::Actions, the runner and its parts, Docker, Cache,
# Logs, Check and Schema - and asserts on what their POD promises, as a user
# of the distribution would see it.  Docker is t/bin/fake-docker, which keeps
# its images and containers in a state directory, so a later step of a
# subtest sees what an earlier one left behind, as with a real daemon.

use Capture::Tiny qw(capture);
use Cwd ();
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP ();
use Readonly;
use Test::Mockingbird ();
use Test::Most;
use Test::Permissions qw(:revoke :guard);
use Test::Returns;
use Time::HiRes ();

BEGIN {
	use_ok('App::Actions');
	use_ok('App::Actions::Cache');
	use_ok('App::Actions::Docker');
	use_ok('App::Actions::Error');
	use_ok('App::Actions::Logs');
	use_ok('App::Actions::Schema');
}

# Every value a test compares against, so each one is named once.
Readonly::Hash my %config => (
	image => 'ubuntu:latest',
	other_image => 'alpine:3.20',
	service_images => [ 'first:1', 'second:1', 'third:1' ],
	step_status => 3,
	pull_sleep => 0.5,
	# Thirty days: an image last used this long ago is one --older-than 30d prunes.
	old_age => 30 * 24 * 60 * 60,
	parallel => 2,
	matrix => [ 'a', 'b' ],
	malformed_size => 'lots',
	malformed_os => '{"broken',
	malformed_record => '{"version": 1, "images": [',
	# An outage is reported long before this; it only catches a hang.
	hang_limit => 60,
	exit => { success => 0, failure => 1, infrastructure => 2 },
	optional_modules => [ 'JSON::XS', 'Cpanel::JSON::XS', 'YAML::XS' ],
);

Readonly::Scalar my $FAKE_DOCKER => File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), 'bin', 'fake-docker'));
Readonly::Scalar my $LIB => File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), File::Spec->updir, 'lib'));
Readonly::Scalar my $NO_FORK => $^O eq 'MSWin32';
# Runner::Images pulls one image at a time there, whatever pull_concurrency says.
Readonly::Scalar my $SERIAL_PULLS => $^O eq 'MSWin32';

# Object::Configure reads the developer's own configuration files, where a
# UNIVERSAL logger would take the messages these tests read; an empty
# directory leaves the defaults.  The record and logs a run keeps by default
# go to temporary places, so the suite never writes to the user's own.
local $ENV{CONFIG_DIR} = tempdir(CLEANUP => 1);
local $ENV{ACTION_RUN_CACHE_FILE} = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
local $ENV{ACTION_RUN_LOG_DIR} = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');
delete local $ENV{ACTION_RUN_LANG};
delete local $ENV{ACTION_RUN_PULL_CONCURRENCY};
delete local @ENV{ grep { /\AApp__Actions__/ } keys %ENV };

# A two-instance matrix and a plain job, all of which pass.
Readonly::Scalar my $PASSING => <<"YAML";
name: CI
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        n: [ @{[ join ', ', @{ $config{matrix} } ]} ]
    steps:
      - run: echo test
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: echo lint
YAML

# A failing job, one that needs it and one that does not.  The FAKE_EXIT
# marker makes the step fail where the fake daemon has no shell to run it.
Readonly::Scalar my $CASCADE => <<"YAML";
name: Cascade
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: |
          # FAKE_EXIT: $config{step_status}
          exit $config{step_status}
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo test
  docs:
    runs-on: ubuntu-latest
    steps:
      - run: echo docs
YAML

# One job whose services bring in several images, for the pull tests.
Readonly::Scalar my $SERVICES => <<"YAML";
name: Services
jobs:
  test:
    runs-on: ubuntu-latest
    services:
@{[ join '', map { my $name = (split /:/)[0]; "      $name:\n        image: $_\n" } @{ $config{service_images} } ]}    steps:
      - run: echo test
YAML

# Shows a value only under prove -v, where it helps to explain a failure.
sub verbose_diag {
	my ($label, $value) = @_;

	diag("$label: ", Test::More::explain($value)) if $ENV{TEST_VERBOSE};

	return;
}

# A repository holding the workflow in .github/workflows, so that the
# project directory is found from the workflow's own path.
sub project {
	my ($yaml) = @_;

	my $root = tempdir(CLEANUP => 1);
	my $directory = File::Spec->catdir($root, '.github', 'workflows');
	make_path($directory);
	my $workflow = File::Spec->catfile($directory, 'ci.yml');
	write_file($workflow, $yaml);

	return { root => $root, workflow => $workflow };
}

sub write_file {
	my ($path, $text) = @_;

	open my $handle, '>', $path or die "cannot write $path: $!";
	print {$handle} $text;
	close $handle;

	return $path;
}

sub read_file {
	my ($path) = @_;

	return '' unless -f $path;
	open my $handle, '<', $path or die "cannot read $path: $!";
	local $/;
	my $text = <$handle>;
	close $handle;

	return defined $text ? $text : '';
}

# A daemon of its own: the state directory is what it has, and the log is
# every command it was given.
sub daemon {
	my $state = tempdir(CLEANUP => 1);

	return { state => $state, log => File::Spec->catfile($state, 'docker.log') };
}

# Runs $code against $daemon, with the fake's knobs (FAKE_*) set for it alone.
sub with_daemon {
	my ($daemon, $knobs, $code) = @_;

	local $ENV{FAKE_DOCKER_STATE} = $daemon->{state};
	local $ENV{FAKE_DOCKER_LOG} = $daemon->{log};
	local @ENV{ keys %{$knobs} } = values %{$knobs};

	return $code->();
}

# The commands the daemon was given, each as its argument list; the timing
# lines FAKE_PULL_TIMING adds are left out.
sub commands {
	my ($daemon) = @_;

	return [ map { [ split /\t/ ] } grep { !/\Apull-(?:start|end)\t/ } split /\n/, read_file($daemon->{log}) ];
}

# The containers the daemon was asked to start for jobs (docker run -d),
# rather than the probe the check runs and removes (docker run --rm).
sub job_containers {
	my ($daemon) = @_;

	return [ map { $_->[3] } grep { $_->[0] eq 'run' && $_->[1] eq '-d' } @{ commands($daemon) } ];
}

# Runs $code, capturing what it prints, and returns that with its result.
sub captured {
	my ($code) = @_;

	my $result;
	my ($stdout, $stderr) = capture { $result = $code->() };
	s/\r\n/\n/g for $stdout, $stderr;

	return { result => $result, stdout => $stdout, stderr => $stderr };
}

# The result each job had, from the run's summary.
sub summary {
	my ($stdout) = @_;

	my ($block) = $stdout =~ /^=== Workflow summary ===\n(.*?)^Workflow /ms;
	return { map { /\A {2}(.+?)\s{2,}(\S+)\z/ ? ($1, $2) : () } split /\n/, defined $block ? $block : '' };
}

# The messages a logger array collected at one level.
sub messages {
	my ($logger, $level) = @_;

	return [ map { $_->{message} } grep { $_->{level} eq $level } @{$logger} ];
}

# An App::Actions for $project on the fake daemon, with its own cache record
# and log directory unless the caller names others.
sub actions {
	my ($project, %options) = @_;

	return new_ok('App::Actions' => [
		workflow_file => $project->{workflow},
		docker_bin => $FAKE_DOCKER,
		image => $config{image},
		cache_file => File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json'),
		log_dir => File::Spec->catdir(tempdir(CLEANUP => 1), 'logs'),
		logger => [],
		%options,
	]);
}

# A Docker program that passes every command on to the fake daemon except the
# one it has been told to break, as a daemon with a bug or a proxy in the way
# would: SABOTAGE=size gives an image size that is not a number, and
# SABOTAGE=os an operating system that is not one.  It is a Perl script, which
# App::Actions::Docker runs with the current Perl, so it works on Windows too.
sub saboteur {
	my $path = File::Spec->catfile(tempdir(CLEANUP => 1), 'docker-saboteur');

	write_file($path, <<"PERL");
#!/usr/bin/env perl
my \$mode = defined \$ENV{SABOTAGE} ? \$ENV{SABOTAGE} : '';
if (\$mode eq 'size' && grep { /Size/ } \@ARGV) {
	print "$config{malformed_size}\\n";
	exit 0;
}
if (\$mode eq 'os' && \$ARGV[0] eq 'info') {
	print '$config{malformed_os}', "\\n";
	exit 0;
}
exit system(\$^X, '$FAKE_DOCKER', \@ARGV) >> 8;
PERL
	chmod 0755, $path;

	return $path;
}

# The fake daemon's pull timing log, as the time each image started and
# finished downloading.
sub pull_times {
	my ($daemon) = @_;

	my (%start, %end);
	for my $line (split /\n/, read_file($daemon->{log})) {
		my ($event, $image, $at) = split /\t/, $line;
		$start{$image} = $at if $event eq 'pull-start';
		$end{$image} = $at if $event eq 'pull-end';
	}

	return (\%start, \%end);
}

subtest 'one object lists, rehearses and runs a workflow' => sub {
	# The same object answers list_jobs, a dry run and a real run, as the
	# command does for "action-run --list", "--dry-run" and a plain run.
	# Strategy: the list must be the workflow's own expansion, the dry run
	# must not touch Docker, and the real run must clean up everything it
	# started.
	my $project = project($PASSING);
	my $daemon = daemon();
	my $actions = actions($project);

	my @expanded = map { "$_->{base_id}\t$_->{display_name}" } @{ $actions->workflow->expand_jobs };
	my $listed = captured(sub { $actions->list_jobs });
	returns_ok($listed->{result}, { type => 'integer', memberof => [ 0 ] }, 'list_jobs returns as its POD says');
	is_deeply([ split /\n/, $listed->{stdout} ], \@expanded, 'and lists the expanded jobs of the workflow, in order');

	my $rehearsal = with_daemon($daemon, {}, sub { captured(sub { $actions->run(dry_run => 1) }) });
	is($rehearsal->{result}, $config{exit}{success}, 'a dry run succeeds');
	is_deeply(commands($daemon), [], 'without giving the daemon a single command');

	my $run = with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
	verbose_diag('run', $run);
	returns_ok($run->{result}, { type => 'integer', memberof => [ 0, 1, 2 ] }, 'run returns as its POD says');
	is($run->{result}, $config{exit}{success}, 'the real run succeeds');
	is_deeply(summary($run->{stdout}), { map { (split /\t/)[1] => 'success' } @expanded }, 'with every job a success');

	my $commands = commands($daemon);
	my @started = sort @{ job_containers($daemon) };
	my @removed = sort map { $_->[2] } grep { $_->[0] eq 'rm' && $_->[1] eq '-f' } @{$commands};
	is(scalar @started, scalar @expanded, 'one container was started for each job');
	is_deeply(\@removed, \@started, 'and each was removed afterwards');
	my @networks = sort map { $_->[2] } grep { $_->[0] eq 'network' && $_->[1] eq 'create' } @{$commands};
	is_deeply([ sort map { $_->[2] } grep { $_->[0] eq 'network' && $_->[1] eq 'rm' } @{$commands} ], \@networks,
		'as was each network');
	is($actions->run(dry_run => 1, quiet => 1), $config{exit}{success}, 'and the object can run again');
};

subtest 'the images a run pulls are recorded, listed and pruned' => sub {
	# Runner::Images records what a run pulled in the record Cache reads, and
	# Cache lists and prunes it through Docker: a round trip through three
	# modules and the daemon's own state.
	my $project = project($PASSING);
	my $daemon = daemon();
	my $record = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
	my $actions = actions($project, cache_file => $record);

	my $pulls = Test::Mockingbird::spy('App::Actions::Docker::pull_many');
	my $first = with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
	my $second = with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
	my @pulled = map { @{ $_->[2] } } $pulls->();
	Test::Mockingbird::restore_all();

	is($first->{result}, $config{exit}{success}, 'the first run succeeds');
	is($second->{result}, $config{exit}{success}, 'and so does the second');
	is_deeply(\@pulled, [ $config{image} ], 'the image is pulled once, by the first run, however many jobs use it');

	my $cache = App::Actions::Cache->new(file => $record);
	my $entries = $cache->entries;
	verbose_diag('record', $entries);
	is_deeply([ map { [ $_->{image}, $_->{pulls} ] } @{$entries} ], [ [ $config{image}, 1 ] ],
		'the record holds the image the run pulled');

	my $docker = App::Actions::Docker->new(bin => $FAKE_DOCKER, quiet => 1);
	with_daemon($daemon, {}, sub {
		my $document = $cache->document(docker => $docker, reachable => 1);
		is_deeply([ App::Actions::Schema::validate($document, App::Actions->json_schema('cache')) ], [],
			'its listing is a valid cache document');
		ok($document->{images}[0]{present}, 'that says the daemon has the image');
		like($cache->report(docker => $docker), qr/^\s+\Q$config{image}\E\s+\d/m, 'and the report gives its size');

		my $removals = Test::Mockingbird::spy('App::Actions::Docker::image_remove');
		my ($text, $status, $pruned) = $cache->prune(docker => $docker);
		my @removed = map { $_->[-1] } $removals->();
		Test::Mockingbird::restore_all();
		verbose_diag('prune', $pruned);

		is($status, 0, 'pruning succeeds');
		is_deeply(\@removed, [ $config{image} ], 'by asking Docker to remove the image');
		is($pruned->{removed}, 1, 'which it counts');
		ok(!$docker->image_exists($config{image}), 'the daemon no longer has the image');
	});
	is_deeply(App::Actions::Cache->new(file => $record)->entries, [], 'and a fresh look at the record finds it empty');
	ok(!-e $record, 'because the empty record was deleted');
};

subtest 'a kept image a run uses again is not pruned as an old one' => sub {
	# A run that finds a kept image, rather than pulling it, has still used
	# it: Runner::Images tells the record (Cache::touch), so the last use moves
	# on and "cache --prune --older-than" keeps it.  An image the user pulled
	# without action-run is never added, so a prune can never remove it.
	# Strategy: age the record between two runs on one daemon, in the serial
	# runner and the parallel one, whose jobs report what they used from a
	# child process.
	my $docker = App::Actions::Docker->new(bin => $FAKE_DOCKER, quiet => 1);
	my $now = time;
	my @runners = ([ 'serial', {} ]);
	push @runners, [ 'parallel', { parallel => $config{parallel} } ] unless $NO_FORK;

	for my $runner (@runners) {
		my ($label, $options) = @{$runner};
		my $daemon = daemon();
		my $record = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
		my $actions = actions(project($PASSING), cache_file => $record, %{$options});

		with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
		my $cache = App::Actions::Cache->new(file => $record);
		$cache->load->{images}{ $config{image} }{last_used} = $now - $config{old_age};
		$cache->save;

		my $again = with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
		is($again->{result}, $config{exit}{success}, "the second $label run succeeds");
		is(scalar(grep { $_->[0] eq 'pull' } @{ commands($daemon) }), 1, "having pulled the image once, in the first run ($label)");
		my $entry = App::Actions::Cache->new(file => $record)->entries->[0];
		verbose_diag("record after the $label run", $entry);
		is($entry->{pulls}, 1, "the image keeps its count of pulls ($label)");
		cmp_ok($entry->{last_used}, '>=', $now, "but its last use is this run's ($label)");

		with_daemon($daemon, {}, sub {
			my (undef, $status, $pruned) = App::Actions::Cache->new(file => $record)
				->prune(docker => $docker, older_than => $config{old_age} - 1);
			is_deeply([ $status, $pruned->{removed} ], [ 0, 0 ], "so a prune of old images leaves it ($label)");
			ok($docker->image_exists($config{image}), "on the daemon ($label)");
		});
	}

	SKIP: {
		skip('jobs run one at a time where fork() is not reliable', 2) if $NO_FORK;

		# An image only a job's own step can name is prepared in the child
		# that runs the job, so the parent hears of it with the job's result.
		my $daemon = daemon();
		my $record = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
		my $cache = App::Actions::Cache->new(file => $record);
		$cache->remember($config{other_image});
		$cache->load->{images}{ $config{other_image} }{last_used} = $now - $config{old_age};
		$cache->save;
		with_daemon($daemon, {}, sub { captured(sub { $docker->pull($config{other_image}) }) });

		my $deferred = $PASSING =~ s{(      - run: echo test\n)}{      - id: name\n        run: echo "image=$config{other_image}" >> "\$GITHUB_OUTPUT"\n      - uses: docker://\${{ steps.name.outputs.image }}\n}r;
		my $actions = actions(project($deferred), cache_file => $record, parallel => $config{parallel});
		my $run = with_daemon($daemon, {}, sub { captured(sub { $actions->run }) });
		verbose_diag('deferred image run', $run);
		is($run->{result}, $config{exit}{success}, 'a parallel run whose jobs name an image themselves succeeds');
		cmp_ok(App::Actions::Cache->new(file => $record)->entries->[0]{last_used}, '>=', $now,
			'and the image the jobs used is touched in the record');
	}

	my $daemon = daemon();
	my $record = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
	with_daemon($daemon, {}, sub { captured(sub { $docker->pull($config{image}) }) });
	my $run = with_daemon($daemon, {}, sub { captured(sub { actions(project($PASSING), cache_file => $record)->run }) });
	is($run->{result}, $config{exit}{success}, 'a run with an image the user pulled succeeds');
	is_deeply(App::Actions::Cache->new(file => $record)->entries, [], 'and does not add it to the record');
};

subtest 'a parallel matrix keeps one log per job, which Logs lists and prunes' => sub {
	plan skip_all => 'jobs run one at a time where fork() is not reliable' if $NO_FORK;

	# Runner::Parallel forks the jobs, copies their logs into log_dir, and
	# Logs reads that directory: the logs a run reports are the ones Logs
	# finds, and pruning them leaves nothing behind.
	my $project = project($PASSING);
	my $logs = File::Spec->catdir(tempdir(CLEANUP => 1), 'logs');
	my $actions = actions($project, parallel => $config{parallel}, log_dir => $logs);

	my $run = with_daemon(daemon(), {}, sub { captured(sub { $actions->run }) });
	verbose_diag('parallel run', $run);
	is($run->{result}, $config{exit}{success}, 'the parallel run succeeds');
	like($run->{stdout}, qr/^\[test \(n=$_\)\] /m, "the output of instance $_ is prefixed with its name")
		for @{ $config{matrix} };

	my $listing = App::Actions::Logs->new(directory => $logs);
	my $runs = $listing->entries;
	verbose_diag('logs', $runs);
	is(scalar @{$runs}, 1, 'one run of logs is kept');
	my @names = map { $_->{name} } @{ $runs->[0]{logs} };
	is(scalar @names, scalar @{ $config{matrix} }, 'with a log for each instance of the matrix');
	like($run->{stdout}, qr/^\s+test \(n=\Q$config{matrix}[0]\E\)\s+\Q$names[0]\E$/m, 'the names the run printed');
	ok((grep { -s $_->{path} } @{ $runs->[0]{logs} }) == @names, 'and none of them is empty');

	is_deeply([ App::Actions::Schema::validate($listing->document, App::Actions->json_schema('logs')) ], [],
		'the listing is a valid logs document');
	my (undef, $status) = $listing->prune;
	is($status, 0, 'pruning the logs succeeds');
	is_deeply(App::Actions::Logs->new(directory => $logs)->entries, [], 'and leaves none');
};

subtest 'independent objects do not interfere with each other' => sub {
	# Two objects, each with its own workflow, daemon, image, record and
	# logger, used in turn.  Strategy: whatever one does - an override, a
	# failure, a pull - must show only in its own record, logger and daemon.
	my ($passing, $failing) = (project($PASSING), project($CASCADE =~ s{^(\s+)runs-on: ubuntu-latest\n}{$1runs-on: ubuntu-latest\n$1container: $config{other_image}\n}mgr));
	my ($passing_daemon, $failing_daemon) = (daemon(), daemon());
	my ($passing_record, $failing_record) = map { File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json') } 1 .. 2;
	my (@passing_log, @failing_log);

	my $one = actions($passing, cache_file => $passing_record, logger => \@passing_log);
	my $two = actions($failing, cache_file => $failing_record, logger => \@failing_log);
	isnt($one->workflow, $two->workflow, 'each has its own workflow');

	my $only_lint = with_daemon($passing_daemon, {}, sub { captured(sub { $one->run(jobs => [ 'lint' ]) }) });
	my $cascade = with_daemon($failing_daemon, {}, sub { captured(sub { $two->run }) });
	my $whole = with_daemon($passing_daemon, {}, sub { captured(sub { $one->run }) });

	is_deeply([ sort keys %{ summary($only_lint->{stdout}) } ], [ 'lint' ], 'an override selects jobs for one run');
	is(scalar keys %{ summary($whole->{stdout}) }, scalar @{ $config{matrix} } + 1,
		'and does not stay behind for the next run of the same object');
	is($whole->{result}, $config{exit}{success}, 'the passing workflow passes');
	is($cascade->{result}, $config{exit}{failure}, 'while the other fails');

	is_deeply(\@passing_log, [], 'the failure is not reported to the other object\'s logger');
	ok(scalar @{ messages(\@failing_log, 'error') }, 'but to its own');

	is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $passing_record)->entries } ], [ $config{image} ],
		'one record holds only the image its object pulled');
	is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $failing_record)->entries } ], [ $config{other_image} ],
		'and the other only its own');
	ok(!(grep { grep { $_ eq $config{other_image} } @{$_} } @{ commands($passing_daemon) }),
		'and neither daemon was asked about the other\'s image');
};

subtest 'a failing job is reported to the logger and does not bring down the others' => sub {
	# A step that fails is a job that fails: the jobs that need it are
	# skipped, an independent job still runs, and the error goes to the
	# logger rather than to standard error.
	my @logger;
	my $actions = actions(project($CASCADE), logger => \@logger);
	my $run = with_daemon(daemon(), {}, sub { captured(sub { $actions->run }) });
	verbose_diag('cascade', $run);

	is($run->{result}, $config{exit}{failure}, 'the run reports that a job failed');
	is_deeply(summary($run->{stdout}), { build => 'failure', test => 'skipped', docs => 'success' },
		'the job that needs the failed one is skipped, and the other one still runs');
	like(messages(\@logger, 'error')->[0], qr/\b$config{step_status}\b/, 'the logger is told the status the step exited with');
	is($run->{stderr}, '', 'and nothing is printed to standard error');
};

subtest 'preflight prepares the images and returns a valid document' => sub {
	# preflight runs the check and the image preparation a run makes before
	# its first job, without starting one.  Strategy: the first preflight
	# pulls, the second finds the image present, and both documents match
	# the published schema.
	my $actions = actions(project($PASSING));
	my $daemon = daemon();
	my $schema = App::Actions->json_schema('preflight');

	for my $expected (qw(pulled present)) {
		my $outcome = with_daemon($daemon, {}, sub { captured(sub { $actions->preflight(json => 1) }) });
		my $result = $outcome->{result};
		verbose_diag("preflight ($expected)", $result);
		returns_ok($result, { type => 'hashref' }, "the preflight returns a hash ($expected)");
		is($result->{exit}, $config{exit}{success}, "it succeeds ($expected)");
		is($outcome->{stdout}, '', "prints nothing with json ($expected)");
		ok($result->{summary}{ready}, "finds the environment ready ($expected)");
		is_deeply([ map { [ $_->{image}, $_->{status} ] } @{ $result->{summary}{images} } ], [ [ $config{image}, $expected ] ],
			"and says the image was $expected");
		is_deeply([ App::Actions::Schema::validate(JSON::PP->new->decode(JSON::PP->new->encode($result->{summary})), $schema) ],
			[], "in a document that matches its schema ($expected)");
	}
	is_deeply(job_containers($daemon), [], 'no job was started');
};

subtest 'a run degrades cleanly when its directories refuse access' => sub {
	# The record and the logs are a convenience: a run that cannot write them
	# must still run its jobs, succeed, and say why (the record only when
	# verbose, as Runner::Images documents).  Reading them back from a
	# directory that cannot be searched gives nothing rather than an error.
	my $locked = tempdir(CLEANUP => 1);

	SKIP: {
		skip(why_not('create', $locked), 3) unless can_revoke_create($locked);

		my @logger;
		my $actions = actions(project($PASSING), cache_file => File::Spec->catfile($locked, 'cache.json'),
			logger => \@logger, verbose => 1);
		my $run = with_revoked(create => $locked, sub { with_daemon(daemon(), {}, sub { captured(sub { $actions->run }) }) });
		verbose_diag('cache unwritable', \@logger);
		is($run->{result}, $config{exit}{success}, 'a run whose record cannot be created still succeeds');
		ok((grep { /could not update the image cache/ } @{ messages(\@logger, 'warn') }), 'and warns that the record was not kept');
		is_deeply(App::Actions::Cache->new(file => File::Spec->catfile($locked, 'cache.json'))->entries, [],
			'which then has no images');
	}

	SKIP: {
		skip(why_not('search', $locked), 4) unless can_revoke_search($locked);

		my $record = File::Spec->catfile($locked, 'kept.json');
		App::Actions::Cache->new(file => $record)->remember($config{other_image});
		my @logger;
		my $actions = actions(project($PASSING), cache_file => $record, logger => \@logger, verbose => 1);

		my ($run, $entries, $logs) = with_revoked(search => $locked, sub {
			my $outcome = with_daemon(daemon(), {}, sub { captured(sub { $actions->run }) });
			my $listing = App::Actions::Logs->new(directory => File::Spec->catdir($locked, 'logs'));
			return ($outcome, App::Actions::Cache->new(file => $record)->entries, $listing->entries);
		});
		is($run->{result}, $config{exit}{success}, 'a run whose record cannot be reached still succeeds');
		ok(scalar @{ messages(\@logger, 'warn') }, 'and warns');
		is_deeply([ $entries, $logs ], [ [], [] ], 'a record or logs that cannot be reached read as empty');
		is_deeply([ map { $_->{image} } @{ App::Actions::Cache->new(file => $record)->entries } ], [ $config{other_image} ],
			'and the record is intact once it can be reached again');
	}

	SKIP: {
		skip('jobs run one at a time where fork() is not reliable', 2) if $NO_FORK;
		skip(why_not('create', $locked), 2) unless can_revoke_create($locked);

		my @logger;
		my $actions = actions(project($PASSING), parallel => $config{parallel},
			log_dir => File::Spec->catdir($locked, 'logs'), logger => \@logger);
		my $run = with_revoked(create => $locked, sub { with_daemon(daemon(), {}, sub { captured(sub { $actions->run }) }) });
		verbose_diag('logs unwritable', \@logger);
		is($run->{result}, $config{exit}{success}, 'a parallel run whose logs cannot be kept still succeeds');
		ok((grep { /could not keep the job logs/ } @{ messages(\@logger, 'warn') }), 'and warns that they were not kept');
	}
};

subtest 'an unreachable daemon stops the run before any job' => sub {
	# An outage upstream: the daemon does not answer.  Strategy: the run and
	# the preflight must both fail fast with the infrastructure status, start
	# no container, and say what is wrong in a document that is still valid.
	my $daemon = daemon();
	my @logger;
	my $actions = actions(project($PASSING), logger => \@logger);

	my $start = Time::HiRes::time();
	my $run = with_daemon($daemon, { FAKE_NO_DAEMON => 1 }, sub { captured(sub { $actions->run }) });
	my $preflight = with_daemon($daemon, { FAKE_NO_DAEMON => 1 }, sub { captured(sub { $actions->preflight(json => 1) }) });
	cmp_ok(Time::HiRes::time() - $start, '<', $config{hang_limit}, 'neither hangs waiting for the daemon');
	verbose_diag('outage', [ \@logger, $preflight->{result} ]);

	is($run->{result}, $config{exit}{infrastructure}, 'the run cannot start');
	like($run->{stdout}, qr/daemon is not reachable/, 'the check report says why');
	ok((grep { /environment is not ready/ } @{ messages(\@logger, 'error') }), 'and the logger is told the run did not start');
	is($preflight->{result}{exit}, $config{exit}{infrastructure}, 'the preflight fails the same way');
	ok(!$preflight->{result}{summary}{ready}, 'its document says the environment is not ready');
	is_deeply([ App::Actions::Schema::validate(JSON::PP->new->decode(JSON::PP->new->encode($preflight->{result}{summary})),
		App::Actions->json_schema('preflight')) ], [], 'in a document that still matches its schema');
	is_deeply(job_containers($daemon), [], 'and no job container was started');
};

subtest 'slow and failing pulls overlap and stop the run before any job' => sub {
	# Injected latency: every pull takes a while.  The images of a job are
	# pulled several at a time, so the run is not as slow as its slowest
	# pulls added together - except on Windows, where Runner::Images
	# documents that they are pulled one at a time.  A failed pull is
	# reported against the job before any container starts.  Overlap is read
	# from the daemon's own timestamps rather than a wall clock, so a slow
	# machine cannot fail it.
	my @images = @{ $config{service_images} };
	my %knobs = (FAKE_PULL_SLEEP => $config{pull_sleep}, FAKE_PULL_TIMING => 1);

	my $daemon = daemon();
	my $actions = actions(project($SERVICES), pull_concurrency => @images + 1);
	my $result = with_daemon($daemon, \%knobs, sub { captured(sub { $actions->preflight(json => 1) }) })->{result};
	my ($start, $end) = pull_times($daemon);
	verbose_diag('pull times', [ $start, $end ]);
	is($result->{exit}, $config{exit}{success}, 'slow pulls still succeed');
	is_deeply([ sort keys %{$end} ], [ sort $config{image}, @images ], 'every image was pulled');
	my $last_start = (sort { $b <=> $a } map { $start->{$_} } @images)[0];
	my $first_end = (sort { $a <=> $b } map { $end->{$_} } @images)[0];
	if ($SERIAL_PULLS) {
		cmp_ok($last_start, '>=', $first_end, 'and the service images were pulled one at a time, as documented here');
	} else {
		cmp_ok($last_start, '<', $first_end, 'and the service images were all under way before the first finished');
	}

	my $failing = daemon();
	my @logger;
	my $broken = actions(project($SERVICES), pull_concurrency => @images + 1, logger => \@logger);
	my $run = with_daemon($failing, { %knobs, FAKE_PULL_FAILURE => $images[1] }, sub { captured(sub { $broken->run }) });
	verbose_diag('failed pull', \@logger);
	is($run->{result}, $config{exit}{infrastructure}, 'a pull that fails stops the run');
	like(messages(\@logger, 'error')->[0], qr/\Q$images[1]\E.*\btest\b/, 'naming the image and the job that needed it');
	is_deeply(job_containers($failing), [], 'before any job container was started');
};

subtest 'a malformed answer from the daemon is not taken for something else' => sub {
	# Malformed payloads: the daemon answers, but with nonsense.  A size that
	# is not a number does not mean the image is gone - the record must not
	# call it missing, and a prune must remove it rather than forget it.  An
	# operating system that is not one is not taken for Linux.
	my $saboteur = saboteur();
	my $daemon = daemon();
	my $record = File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json');
	my $actions = actions(project($PASSING), cache_file => $record, docker_bin => $saboteur);
	is(with_daemon($daemon, {}, sub { captured(sub { $actions->run }) })->{result}, $config{exit}{success},
		'a run through the wrapper succeeds');

	my $docker = App::Actions::Docker->new(bin => $saboteur, quiet => 1);
	my $cache = App::Actions::Cache->new(file => $record);
	with_daemon($daemon, { SABOTAGE => 'size' }, sub {
		is($docker->image_size($config{image}), undef, 'a size that is not a number is no size');

		my $report = $cache->report(docker => $docker);
		verbose_diag('report', $report);
		unlike($report, qr/no longer on the daemon/, 'the report does not call the image missing');
		my $document = $cache->document(docker => $docker, reachable => 1);
		is_deeply([ map { [ $_->{present} ? 1 : 0, $_->{size} ] } @{ $document->{images} } ], [ [ 1, undef ] ],
			'the document has it present, of unknown size');
		is_deeply([ App::Actions::Schema::validate($document, App::Actions->json_schema('cache')) ], [],
			'and is valid');

		my (undef, $status, $pruned) = $cache->prune(docker => $docker);
		verbose_diag('prune', $pruned);
		is($status, 0, 'pruning succeeds');
		is_deeply([ @{$pruned}{qw(removed forgotten freed)} ], [ 1, 0, 0 ], 'by removing the image, which frees no known size');
		ok(!$docker->image_exists($config{image}), 'and the daemon no longer has it');
	});

	my @logger;
	my $confused = actions(project($PASSING), docker_bin => $saboteur, logger => \@logger);
	my $fresh = daemon();
	my $run = with_daemon($fresh, { SABOTAGE => 'os' }, sub { captured(sub { $confused->run }) });
	is($run->{result}, $config{exit}{infrastructure}, 'a daemon that names no real operating system is not used');
	like($run->{stdout}, qr/\Q$config{malformed_os}\E' containers/, 'the report quotes what it said');
	is_deeply(job_containers($fresh), [], 'and no job container was started');
};

subtest 'malformed files are survived or refused, as documented' => sub {
	# A record that is not JSON counts as empty (Cache POD) and is replaced by
	# the next run; a workflow that is not YAML is refused by new() with a
	# coded error, before anything else happens.
	my $record = write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'cache.json'), $config{malformed_record});
	is_deeply(App::Actions::Cache->new(file => $record)->entries, [], 'a broken record reads as empty');

	my $run = with_daemon(daemon(), {}, sub { captured(sub { actions(project($PASSING), cache_file => $record)->run }) });
	is($run->{result}, $config{exit}{success}, 'a run with a broken record succeeds');
	my $rewritten = eval { JSON::PP->new->decode(read_file($record)) };
	ok($rewritten, 'and leaves a record that is JSON again');
	is_deeply([ keys %{ $rewritten->{images} || {} } ], [ $config{image} ], 'holding the image the run pulled');

	my $broken = project("name: [\n");
	my $error;
	throws_ok { App::Actions->new(workflow_file => $broken->{workflow}, logger => 'NULL') } 'App::Actions::Error',
		'a workflow that is not YAML is refused';
	$error = $@;
	ok($error->is('workflow.parse_failed'), 'with the code that says why');
	# new() names the workflow by its absolute path, which on Windows is
	# written with forward slashes.
	like($error->message, qr/\Q@{[ Cwd::abs_path($broken->{workflow}) ]}\E/, 'naming the file');
};

subtest 'no optional module is needed, and none changes the outcome' => sub {
	# App::Actions declares no optional dependencies: JSON::PP and YAML::PP
	# are used directly.  Strategy: hide every combination of the faster
	# modules other distributions often pick up when present, in a fresh
	# Perl each time, and check that a run and a schema lookup behave alike.
	my @optional = @{ $config{optional_modules} };
	my $project = project($PASSING);
	# A script file, not perl -e: Windows rebuilds a command line from the
	# arguments, and a program of several lines does not survive that.
	my $program = write_file(File::Spec->catfile(tempdir(CLEANUP => 1), 'optional.pl'), <<'PERL');
use App::Actions;
my ($workflow, $docker) = @ARGV;
my $schema = App::Actions->json_schema('check');
my $exit = App::Actions->new(workflow_file => $workflow, docker_bin => $docker, dry_run => 1, quiet => 1, logger => 'NULL')->run;
print "$exit $schema->{title}\n";
PERL

	my %seen;
	for my $mask (0 .. 2**@optional - 1) {
		my @hidden = map { $optional[$_] } grep { $mask & (1 << $_) } 0 .. $#optional;
		my @switches = @hidden ? ('-MTest::Without::Module=' . join(',', @hidden)) : ();
		my ($stdout, $stderr, $status) = capture {
			system($^X, "-I$LIB", @switches, $program, $project->{workflow}, $FAKE_DOCKER);
		};
		my $label = @hidden ? 'without ' . join(', ', @hidden) : 'with everything installed';
		is($status, 0, "a run $label works") or diag($stderr);
		$seen{$stdout}++;
	}
	is(scalar keys %seen, 1, 'and every combination gives the same answer');
	verbose_diag('outcomes', \%seen);
};

done_testing();
