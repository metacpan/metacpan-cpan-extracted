#!/usr/bin/perl
# 010_config.t - tests for Container::Buildah configuration data management

use strict;
use warnings;
use autodie;

use Test::More;
use Container::Buildah;
use Data::Dumper;

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/010_config.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# number of digits in test count (for text formatting)
my $test_digits = 2; # default to 2, count later

# test Container::Buildah::prog()
sub test_config
{
	my $cb = shift;
	my $number = shift;
	my $params = shift; # hash structure of test parameters

	# navigate down object's hash tree - code similar to Container::Buildah::get_config() tree traversal
	my @path = @{$params->{path}};
	my $key = pop @path; # last entry of path is target node

	# generate path string for test naming and error reporting
	my $full_path = (@path?join("/", @path):"(*)")."->".$key
		.($params->{get_config}?" from config":"");
	my $name = sprintf("%0".$test_digits."d %s",
		$number, (exists $params->{name}) ? $params->{name} : "check $full_path");

	# traverse path
	my $diag;
	my $node = $cb;
	while (@path) {
			my $subnode = shift @path;
			if (exists $node->{$subnode} and ref $node->{$subnode} eq "HASH") {
				$node = $node->{$subnode};
			} else {
				$diag = "$subnode not found in search for $full_path";
				last;
			}
	}

	# test for existence (or non-existence) of the path
	if ($diag) {
		# fail test and report diagnostics if the path didn't exist
		if ($params->{path_fail_expected} // 0) {
			pass($name);
		} else {
			fail($name);
			diag($diag);
		}
		return;
	}

	# test for existence (or non-existence) of the node
	if ($params->{exists_fail_expected} // 0) {
		ok(!exists $node->{$key}, "$name: should not exist");
		return; # no other tests make any sense when we don't expect the node to exist
	}
	ok(exists $node->{$key}, "$name: should exist");

	SKIP: {
		skip "$name: node doesn't exist" if !exists $node->{$key};

		# additional tests if configured
		if (exists $params->{ref}) {
			is(ref $node->{$key}, $params->{ref}, "$name: ".$params->{ref}." ref");
		}
		if (exists $params->{isa}) {
			my $obj = $node->{$key};
			isa_ok($obj, $params->{isa});
		}
		if (exists $params->{value}) {
			my $value = $node->{$key};
			if ($params->{get_config}) {
				my @path = @{$params->{path}};
				if ($path[0] ne "config") {
					die "$name: get_config test cannot be done on item outside config tree";
				}
				shift @path;
				$value = $cb->get_config(@path);
			}
			is($value, $params->{value} , "$name: value = $value");
		}
		if (exists $params->{array}) {
			if (ref $params->{array} ne "ARRAY") {
				die "test $name: array parameter must be an ARRAY, got "
					.((ref $params->{array})?(ref $params->{array}):"scalar");
			}
			my @values;
			if ($params->{get_config}) {
				# get values from get_config()
				my @path = @{$params->{path}};
				if ($path[0] ne "config") {
					die "$name: get_config test cannot be done on item outside config tree";
				}
				shift @path; # remove config from the path
				my $get_config = $cb->get_config(@path);
				@values = ((ref $get_config eq "ARRAY") ? @$get_config : ());
			} else {
				# get values from test fixture
				@values = @{$node->{$key}};
			}
			for(my $i=0; $i < scalar @values; $i++) {
				is($values[$i], $params->{array}[$i], "$name: value[$i] = ".$values[$i]);
			}
		}
	}
}

# count tests for plan directive
sub count_tests
{
	my @tests = @_;
	my $total = 0;
	foreach my $test (@tests) {
		my $subtotal = 1; # minimum 1 test per set
		if (!exists $test->{path_fail_expected} and !exists $test->{exists_fail_expected}) {
			foreach my $key (qw(ref value isa)) {
				if (exists $test->{$key}) {
					$subtotal++;
				}
			}
			if (exists $test->{array}) {
				if (ref $test->{array} eq "ARRAY") {
					$subtotal += scalar @{$test->{array}};
				} else {
					# array parameter isn't an ARRAY ref?
					# ignore this error for now because it can be reported better during the test run
				}
			}
		}
		$test->{tests} = $subtotal;
		$total += $subtotal;
	}
	return $total;
}

# config for testing
my $basename = __FILE__;
$basename =~ s/\W+/_/g;
my $version = "1.1";
my %local_config = (
	basename => $basename,
	testing_skip_yaml => 1,
	version => $version,
	software_version => "[% version %]",
	stages => {
		build => {
			from => "nowhere",
			produces => [qw(/usr/local /opt/build-dir)],
			func_deps => sub {},
			func_exec => sub {},
		},
		runtime => {
			from => "foo",
			consumes => [qw(build)],
			func_deps => sub {},
			func_exec => sub {},
			commit => ["[% basename %]:[% software_version %]", "[% basename %]:latest"],
		},
	},
);
Container::Buildah::init_config(%local_config);

# fixtures for config tests
my @config_tests = (
	{
		name => "path fails as expected",
		path => [qw(not_found_path not_found_node)],
		path_fail_expected => 1,
	},
	{
		name => "node not found as expected",
		path => [qw(config not_found_node)],
		exists_fail_expected => 1,
	},
	{
		path => [qw(oldstdout)],
		ref => "GLOB",
	},
	{
		path => [qw(oldstderr)],
		ref => "GLOB",
	},
	{
		path => [qw(template)],
		ref => "Template",
	},
	{
		path => [qw(config)],
		ref => "HASH",
	},
	{
		path => [qw(config basename)],
		value => $basename,
	},
	{
		path => [qw(config basename)],
		value => $basename,
		get_config => 1,
	},
	{
		path => [qw(config version)],
		value => $version,
	},
	{
		path => [qw(config version)],
		value => $version,
		get_config => 1,
	},
	{
		path => [qw(config software_version)],
		value => $local_config{software_version},
	},
	{
		path => [qw(config software_version)],
		value => $version,
		get_config => 1,
	},
	{
		path => [qw(config testing_skip_yaml)],
		value => 1,
	},
	{
		path => [qw(config testing_skip_yaml)],
		value => 1,
		get_config => 1,
	},
	{
		path => [qw(config stages)],
		ref => "HASH",
	},
	{
		path => [qw(config stages build)],
		ref => "HASH",
	},
	{
		path => [qw(config stages build func_deps)],
		ref => "CODE",
	},
	{
		path => [qw(config stages build func_exec)],
		ref => "CODE",
	},
	{
		path => [qw(config stages build from)],
		value => $local_config{stages}{build}{from},
	},
	{
		path => [qw(config stages build produces)],
		array => $local_config{stages}{build}{produces},
	},
	{
		path => [qw(config stages runtime)],
		ref => "HASH",
	},
	{
		path => [qw(config stages runtime func_deps)],
		ref => "CODE",
	},
	{
		path => [qw(config stages runtime func_exec)],
		ref => "CODE",
	},
	{
		path => [qw(config stages runtime from)],
		value => $local_config{stages}{runtime}{from},
	},
	{
		path => [qw(config stages runtime from)],
		value => $local_config{stages}{runtime}{from},
		get_config => 1,
	},
	{
		path => [qw(config stages runtime consumes)],
		array => $local_config{stages}{runtime}{consumes},
	},
	{
		path => [qw(config stages runtime consumes)],
		array => $local_config{stages}{runtime}{consumes},
		get_config => 1,
	},
	{
		path => [qw(config stages runtime commit)],
		array => $local_config{stages}{runtime}{commit},
	},
	{
		path => [qw(config stages runtime commit)],
		array => ["$basename:$version", "$basename:latest"],
		get_config => 1,
	},
);

my $test_total = count_tests(@config_tests);
plan tests => $test_total;
$test_digits = length("".$test_total);

# run tests
my $cb = Container::Buildah->instance(($debug_level ? (debug => $debug_level) : ()));
($debug_level>0) and warn Dumper(\@config_tests);
{
	for (my $i=0; $i<scalar @config_tests; $i++) {
		test_config($cb, $i+1, $config_tests[$i]);
	}
}

1;
