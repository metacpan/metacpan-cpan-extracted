#!/usr/bin/env perl

use v5.36;
use Test::Most;
use Path::Tiny;
use File::Temp qw(tempdir);

use_ok('App::GHGen::Analyzer', qw(analyze_workflow));
use_ok('App::GHGen::Fixer',	qw(apply_fixes));

# Minimal workflow missing timeout-minutes
my $workflow_missing = {
	name => 'Test CI',
	on   => { push => {} },
	jobs => {
		test => {
			'runs-on' => 'ubuntu-latest',
			steps	 => [
				{ uses => 'actions/checkout@v6' },
				{ run  => 'echo "Hello"' },
			],
		},
	},
};

# Minimal workflow WITH timeout-minutes
my $workflow_with = {
	name => 'Test CI',
	on   => {
		push => { branches => ['main'] },
		pull_request => { branches => ['main'] },
	},
	concurrency => {
		group => '${{ github.workflow }}-${{ github.ref }}',
		'cancel-in-progress' => 'true',
	},
	permissions => { contents => 'read' },
	jobs => {
		test => {
			'runs-on'		=> 'ubuntu-latest',
			'timeout-minutes' => 20,
			steps			=> [
				{ uses => 'actions/checkout@v6' },
				{ uses => 'actions/cache@v5' },
				{ run  => 'echo "Hello"' },
			],
		},
	},
};

subtest 'Detect missing timeout-minutes' => sub {
	my @issues = analyze_workflow($workflow_missing, 'test.yml');

	my $has_timeout_issue = grep {
		ref $_ eq 'HASH'
			&& ($_->{message} // '') =~ /missing timeout-minutes/
	} @issues;

	ok($has_timeout_issue, 'Analyzer detects missing timeout-minutes');
};

subtest 'Fix missing timeout-minutes' => sub {
	my @issues = analyze_workflow($workflow_missing, 'test.yml');
	my $modified = apply_fixes($workflow_missing, \@issues);

	ok($modified > 0, 'Fixer reports modification');
	is(
		$workflow_missing->{jobs}{test}{'timeout-minutes'},
		30,
		'Fixer inserts default timeout-minutes = 30'
	);
};

subtest 'Do not overwrite existing timeout-minutes' => sub {
	my @issues = analyze_workflow($workflow_with, 'test.yml');
	my $modified = apply_fixes($workflow_with, \@issues);

	ok($modified == 0, 'Fixer makes no changes when timeout already exists');
	is(
		$workflow_with->{jobs}{test}{'timeout-minutes'},
		20,
		'Existing timeout-minutes preserved'
	);
};

done_testing();
