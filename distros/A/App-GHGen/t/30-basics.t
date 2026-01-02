#!/usr/bin/env perl
use v5.36;
use Test::More;

use_ok('App::GHGen');
use_ok('App::GHGen::Generator', qw(generate_workflow list_workflow_types));
use_ok('App::GHGen::Analyzer', qw(analyze_workflow));

# Test workflow generation
{
	my $yaml = generate_workflow('perl');
	ok($yaml, 'Generated Perl workflow');
	like($yaml, qr/name: Perl CI/, 'Contains workflow name');
	like($yaml, qr/shogo82148\/actions-setup-perl/, 'Uses Perl setup action');
	like($yaml, qr/AUTOMATED_TESTING/, 'Sets environment variables');
}

# Test list_workflow_types
{
	my %types = list_workflow_types();
	ok(exists $types{perl}, 'Perl type exists');
	ok(exists $types{node}, 'Node type exists');
	ok(exists $types{python}, 'Python type exists');
	is(scalar keys %types, 11, 'Has 11 workflow types');
}

# Test workflow analysis
{
	my $workflow = {
		name => 'Test',
		on => { push => {} },
		jobs => {
			test => {
				'runs-on' => 'ubuntu-latest',
				steps => [
					{ uses => 'actions/checkout@v4' },
					{ run => 'npm test' },
				],
			},
		},
	};
	
	my @issues = analyze_workflow($workflow, 'test.yml');
	ok(@issues > 0, 'Found issues in test workflow');
	
	my @caching_issues = grep { $_->{type} eq 'performance' } @issues;
	ok(@caching_issues > 0, 'Found caching issue');
}

# Test invalid workflow type
{
	my $yaml = generate_workflow('invalid-type');
	ok(!defined $yaml, 'Returns undef for invalid type');
}

done_testing();
