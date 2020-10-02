#!/usr/bin/perl
# 014_buildah.t - test running buildah commands

use strict;
use warnings;
use autodie;

use Test::More;
use Carp qw(croak);
use Container::Buildah;
use Data::Dumper;

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/011_prog.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# number of digits in test count (for text formatting)
my $test_digits = 2; # default to 2, count later

# test Container::Buildah::Subcommand::buildah()
my ($zero_flag, $nonzero_flag, $nonzero_value);
sub test_buildah
{
	my $cb = shift;
	my $number = shift; # test group number
	my $group = shift; # hash structure of test group parameters

	# loop through tests in group
	foreach my $test (@{$group->{tests}}) {
		$zero_flag = $nonzero_flag = 0;
		$nonzero_value = undef;
		my $opts = $group->{opts} // {};
		$opts->{label} = 'test';

		# generate name of test set including test group number
		(exists $test->{name})
			or croak "name not provided for test #$number";
		my $test_set = sprintf("%0".$test_digits."d %s", $number, $test->{name});

		# run test in exception handling wrapper
		my ($outstr, $retcode);
		if (not exists $test->{args}) {
			croak "missing args for test #$number";
		}
		if (ref $test->{args} ne "ARRAY") {
			croak "wrong type for args on test #$number - must be an array ref, got "
				.(ref $test->{args} ? ref $test->{args} : "scalar");
		}
		if (exists $test->{retcode}) {
			$opts->{save_retcode} = \$retcode;
		}
		eval {
			$outstr = $cb->buildah($opts, @{$test->{args}});
		};
		my $exception = $@;
		if ($exception) {
			($debug_level>0) and warn "exception: ".Dumper($exception);
		}

		# process results of test
		if (not exists $test->{expected_exception}) {
			# test: exception not expected
			is($exception, '', "$test_set: no exceptions");

			if (exists $test->{outstr}) {
				like($outstr, qr/$test->{outstr}/s, "$test_set: output text");
			}
		} else {
			# exception expected
			my $expected_exception = $test->{expected_exception};
			like($exception, qr/$expected_exception/s, "$test_set: expected exception");
		}

		# check return code
		if (exists $test->{retcode}) {
			is($retcode, $test->{retcode}, "$test_set: return code");
		}

		# return-code callback tests: test callbacks for zero flag, nonzero flag & nonzero value
		if ($test->{nonzero_set} // 0) {
			is($nonzero_flag, 1, "$test_set: nonzero flag set");
		}
		if ($test->{nonzero_unset} // 0) {
			is($nonzero_flag, 0, "$test_set: nonzero flag unset");
		}
		if ($test->{zero_set} // 0) {
			is($zero_flag, 1, "$test_set: zero flag set");
		}
		if ($test->{zero_unset} // 0) {
			is($zero_flag, 0, "$test_set: zero flag unset");
		}
		if (exists $test->{nonzero_value}) {
			is($nonzero_value, $test->{nonzero_value}, "$test_set: nonzero value");
		}
	}
}

# count tests for test plan
sub count_tests
{
	my @groups = @_;
	my $total = 0;
	foreach my $group (@groups) {
		foreach my $test (@{$group->{tests}}) {
			$total++;
			if (not exists $test->{expected_excetion}) {
				foreach my $argname (qw(outstr)) {
					if (exists $test->{$argname}) {
						$total++;
					}
				}
			}
			foreach my $argname (qw(retcode nonzero_value nonzero_set nonzero_unset zero_set zero_unset)) {
				if (exists $test->{$argname}) {
					$total++;
				}
			}
		}
	}
	return $total;
}

#
# main
#

# config for testing
Container::Buildah::init_config(
        basename => "buildah_test",
        testing_skip_yaml => 1,
);
my $cb = Container::Buildah->instance(($debug_level ? (debug => $debug_level) : ()));

## test fixtures
my @tests = (
	{
		opts => {
			suppress_output => 1,
			suppress_error => 1,
		},
		tests => [
			{
				name => "nonexistent subcommand",
				args => ["blarg"],
				retcode => 125,
				expected_exception => 'buildah: non-zero status \(125\) from cmd',
			},
			{
				name => "nonexistent option",
				args => ["--blarg"],
				retcode => 125,
				expected_exception => 'buildah: non-zero status \(125\) from cmd',
			},
		],
	},
	{
		opts => {
			capture_output => 1,
		},
		tests => [
			{
				name => "no args",
				args => [],
				retcode => 0,
				outstr => 'Usage:', # minimal text search for help output which software updates probably won't break
			},
			{
				name => "help subcommand",
				args => ["help"],
				retcode => 0,
				outstr => 'Usage:', # minimal text search for help output which software updates probably won't break
			},
			{
				name => "version subcommand",
				args => ["--version"],
				retcode => 0,
				outstr => 'buildah version [0-9]+\.[0-9]+\.[0-9]+',
			},
			{
				name => "info subcommand",
				args => ["info"],
				retcode => 0,
				outstr => '^\{.*"host":.*"os":.*"rootless":.*"store":.*"ContainerStore":.*"ImageStore":.*\}$',
			},
		],
	},
);
($debug_level>0) and warn Dumper(\@tests);

# count tests
# this optional test set requires buildah to be installed on the build/test system - skip if it's missing
my $buildah_found = 0;
for my $path (qw(/usr/bin /sbin /usr/sbin /bin)) {
	if (-x "$path/buildah") {
		$buildah_found = 1;
		last;
	}
}
my $test_total;
if (not $cb->container_compat_check()) {
	plan skip_all => 'kernel is not container-compatible';
} elsif (not $buildah_found) {
	plan skip_all => 'buildah command not available';
} else {
	$test_total = count_tests(@tests);
	plan tests => $test_total;
}
$test_digits = length("".$test_total);

# run tests
{
	for (my $i=0; $i<scalar @tests; $i++) {
		test_buildah($cb, $i+1, $tests[$i]);
	}
}
1;
