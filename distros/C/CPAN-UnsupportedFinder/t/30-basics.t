#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::HTML::Lint;
use Test::JSON;

use Test::RequiresInternet ('fastapi.metacpan.org' => 'https', 'api.cpantesters.org' => 'https');

BEGIN {
	plan(skip_all => 'NO_NETWORK_TESTING set') if $ENV{'NO_NETWORK_TESTING'};
	plan(tests => 22);
	use_ok('CPAN::UnsupportedFinder')
}

# Create a test instance of CPAN::UnsupportedFinder
my $finder = CPAN::UnsupportedFinder->new(verbose => $ENV{'TEST_VERBOSE'} ? 1 : 0);

# Test that the module initializes correctly
ok($finder, 'CPAN::UnsupportedFinder object created');

# Mock module to analyze
my @modules = ('Test-MockModule', 'Old-Unused-Module');

# Test that the analyze method returns an arrayref
my $results = $finder->analyze(@modules);
ok(ref($results) eq 'ARRAY', 'analyze returns an arrayref');

# Test the content of the returned arrayref (assuming it's structured correctly)
foreach my $module (@{$results}) {
	foreach my $key('module', 'failure_rate', 'last_update', 'recent_tests', 'reverse_deps', 'has_unsupported_deps') {
		ok(exists($module->{$key}), "$key exists");
	}
}

# Test that the failure rate calculation is between 0 and 1
foreach my $module (@{$results}) {
	ok($module->{failure_rate} >= 0 && $module->{failure_rate} <= 1, 'Failure rate is between 0 and 1');
}

# Test that the last update is a valid date (assuming you expect a YYYY-MM-DD format)
foreach my $module (@$results) {
	if($module->{'module'} eq 'Old-Unused-Module') {
		cmp_ok($module->{'last_update'}, 'eq', 'Unknown', 'Unknown module has no valid date');
	} else {
		like($module->{'last_update'}, qr/^\d{4}-\d{2}-\d{2}/, 'Last update is a valid date');
	}
}

# Test the output format methods
my $json_report = $finder->output_results($results, 'json');
# like( $json_report, qr/^\{.*\}$/, 'Output is valid JSON' );
is_valid_json($json_report, 'Output is valid JSON');

my $html_report = $finder->output_results($results, 'html');
like($html_report, qr/<html>/, 'Output contains <html> tag for HTML format');
html_ok($html_report, 'Output is valid HTML');
