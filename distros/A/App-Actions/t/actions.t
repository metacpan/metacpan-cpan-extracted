use strict;
use warnings;

use Capture::Tiny qw(capture_stdout);
use Cwd ();
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use App::Actions;

delete local $ENV{ACTION_RUN_LANG};

my $project = tempdir(CLEANUP => 1);
my $workflows = File::Spec->catdir($project, '.github', 'workflows');
make_path($workflows);
my $workflow_file = File::Spec->catfile($workflows, 'ci.yml');
open my $handle, '>', $workflow_file or die "$workflow_file: $!";
print {$handle} <<'YAML';
name: CI
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        perl: ['5.38', '5.40']
    steps:
      - run: prove -l t
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: perlcritic lib
YAML
close $handle;

subtest 'new' => sub {
	my $actions = App::Actions->new(workflow_file => $workflow_file);
	isa_ok($actions, 'App::Actions');
	is($actions->project_dir, Cwd::abs_path($project), 'the project is the repository holding .github/workflows');
	is($actions->workflow->name, 'CI', 'the workflow is loaded');

	my $hashref = App::Actions->new({ workflow_file => $workflow_file });
	is($hashref->workflow_file, $actions->workflow_file, 'a hash reference of arguments is accepted');

	throws_ok { App::Actions->new } qr/^workflow_file is required/, 'the workflow is required';
	throws_ok { App::Actions->new(workflow_file => "$project/absent.yml") }
		qr/^Workflow file '.*absent\.yml' does not exist/, 'a missing workflow is reported';
	throws_ok { App::Actions->new(workflow_file => $workflow_file, project_dir => "$project/absent") }
		qr/^Project directory '.*absent' does not exist/, 'a missing project is reported';
	throws_ok { App::Actions->new(workflow_file => $workflow_file, verbos => 1) }
		qr/^Invalid arguments to App::Actions::new: Unknown parameter 'verbos'/,
		'a misspelt option is refused rather than ignored';
	throws_ok { App::Actions->new(workflow_file => $workflow_file, env => 'A=1') }
		qr/Invalid arguments to App::Actions::new/, 'a mistyped option is refused';

	# The workflow is outside .github/workflows, so nothing says where the
	# project is.
	my $loose = File::Spec->catfile($project, 'loose.yml');
	require File::Copy;
	File::Copy::copy($workflow_file, $loose) or die $!;
	throws_ok { App::Actions->new(workflow_file => $loose) } qr/^project_dir is required/,
		'a workflow outside a repository needs project_dir';
};

subtest 'the options reach the runner' => sub {
	my $cache = File::Spec->catfile($project, 'cache.json');
	my $actions = App::Actions->new(
		workflow_file => $workflow_file,
		cache_file => $cache,
		log_dir => $project,
		verbose => 1,
	);

	# White-box: the runner is what every public method builds.  _runner is
	# protected, so outside a harness the bypass has to be asked for.
	local $Sub::Protected::BYPASS = 1;
	my $runner = $actions->_runner({});
	is($runner->{cache_file}, $cache, 'cache_file is forwarded (it used to be dropped)');
	is($runner->{log_dir}, $project, 'log_dir is forwarded');
	is($runner->{verbose}, 1, 'a flag is forwarded');
	is($actions->_runner({ verbose => 0 })->{verbose}, 0, 'an override replaces the option for one call');
	is($actions->_runner({ verbose => undef })->{verbose}, 0, 'an undef override is still an override');
};

subtest 'list_jobs' => sub {
	my $actions = App::Actions->new(workflow_file => $workflow_file);

	my $exit;
	my $out = capture_stdout { $exit = $actions->list_jobs };
	is($exit, 0, 'listing succeeds');
	like($out, qr/^test\ttest \(perl=5\.38\)$/m, 'a matrix instance is listed');
	like($out, qr/^lint\tlint$/m, 'a plain job is listed');

	$out = capture_stdout { $actions->list_jobs(jobs => [ 'lint' ]) };
	unlike($out, qr/^test/m, 'the jobs override selects jobs');

	throws_ok { $actions->list_jobs(bogus => 1) } qr/Invalid arguments to App::Actions::list_jobs/,
		'an unknown override is refused';
};

subtest 'json_schema' => sub {
	for my $name (qw(check preflight cache logs)) {
		is(ref App::Actions->json_schema($name), 'HASH', "$name has a schema");
	}
	throws_ok { App::Actions->json_schema } qr/^A document name is required/, 'a name is required';
	throws_ok { App::Actions->json_schema('workflow') }
		qr/^Unknown document 'workflow'; expected check, preflight, cache or logs/,
		'an unknown name lists the ones that exist';

	local $ENV{ACTION_RUN_LANG} = 'de';
	throws_ok { App::Actions->json_schema('workflow') }
		qr/^Unbekanntes Dokument 'workflow'; erwartet: check, preflight, cache oder logs/,
		'and does so in the language of the run';
};

done_testing();
