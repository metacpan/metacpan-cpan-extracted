#!/usr/bin/perl
# 011_prog.t - tests for Container::Buildah prog() function

use strict;
use warnings;
use autodie;

use Test::More;
use Container::Buildah;
use Data::Dumper;

# detect debug level from environment
# run as "DEBUG=4 perl -Ilib t/011_prog.t" to get debug output to STDERR
my $debug_level = (exists $ENV{DEBUG}) ? int $ENV{DEBUG} : 0;

# number of digits in test count (for text formatting)
my $test_digits = 2; # default to 2, count later

# expand parameter variable names in parameters
sub expand
{
	my $varhash = shift;
	my $varname = shift;
	my $cb = Container::Buildah->instance();
	my $prog = $cb->{prog};
	my $varname_re = join('|', (keys %$varhash, keys %$prog));
	my $value = $varhash->{$varname} // "";
	if (ref $value eq "ARRAY") {
		for (my $i=0; $i<scalar @$value; $i++) {
			(defined $value->[$i]) or next;
			while ($value->[$i] =~ /\$($varname_re)/) {
				my $match = $1;
				my $subst = $varhash->{$match} // $prog->{$match};
				$value->[$i] =~ s/\$$match/$subst/g;
			}
		}
	} else {
		while ($value =~ /\$($varname_re)/) {
			my $match = $1;
			my $subst = $varhash->{$match} // $prog->{$match};
			$value =~ s/\$$match/$subst/g;
		}
	}
	return $value;
}

# find a program's expected location to verify Container::Buildah::prog()
sub find_prog
{
        my $prog = shift;

        foreach my $path ("/usr/bin", "/sbin", "/usr/sbin", "/bin") {
                if (-x "$path/$prog") {
                        return "$path/$prog";
                }
        }
        # return undef value by default
}

# test Container::Buildah::prog()
sub test_prog
{
	my $cb = shift;
	my $number = shift; #test number
	my $params = shift; # hash structure of test parameters
	my $prog = $cb->{prog};
	my $progname = expand($params, "progname");
	my ($progpath, $exception);

	# set test-fixture data in environment if provided
	my %saved_env;
	my $need_restore_env = 0;
	if ((exists $params->{env}) and (ref $params->{env} eq "HASH")) {
		foreach my $key (keys %{$params->{env}}) {
			if (exists $ENV{$key}) {
				$saved_env{$key} = $ENV{$key};
			}
			$ENV{$key} = $params->{env}{$key};
		}
		$need_restore_env = 1;
	}

	# run the prog function to locate the selected program's path
	($debug_level>0) and warn "prog test for $progname";
	eval { $progpath = Container::Buildah::prog($progname) };
	$exception = $@;

	# test and report results
	my $test_set = sprintf("path %0".$test_digits."d", $number);
	if ($debug_level>0) {
		if (exists $prog->{$progname}) {
			warn "comparing ".$prog->{$progname}." eq $progpath";
		} else {
			warn "$progname cache missing\n".Dumper($prog);
		}
	}
	if (!exists $params->{expected_exception}) {
		is($prog->{$progname}, $progpath, "$test_set: path in cache: $progname -> ".($progpath // "(undef)"));
		if (defined $progpath) {
			ok(-x $progpath, "$test_set: path points to executable program");
		} else {
			fail("$test_set: path points to executable program (undefined)");
		}
		is($exception, '', "$test_set: no exceptions");

		# verify program is in expected location
		my $expected_path = find_prog($progname);
		my $envprog = Container::Buildah::Subcommand::envprog($progname);
		my $reason = "default";
		if (exists $ENV{$envprog} and -x $ENV{$envprog}) {
			if (-x $expected_path) {
				$reason = "default, ignore ENV{$envprog}";
			} else {
				$expected_path = $ENV{$envprog};
				$reason = "ENV{$envprog}";
			}
		}
		is($progpath, $expected_path, "$test_set: expected at $expected_path by $reason");
	} else {
		ok(!exists $prog->{$progname}, "$test_set: path not in cache as expected after exception");
		is($progpath, undef, "$test_set: path undefined after expected exception");
		my $expected_exception = expand($params, "expected_exception");
		like($exception, qr/$expected_exception/, "$test_set: expected exception");
		pass("$test_set: $progname has no location due to expected exception");
	}

	# restore environment and remove test-fixture data from it
	if ($need_restore_env) {
		foreach my $key (keys %{$params->{env}}) {
			if (exists $ENV{$key}) {
				$ENV{$key} = $saved_env{$key};
			} else {
				delete $ENV{$key};
			}
		}
	}
}

#
# lists of tests
#

# strings used for tests
# test string: uses Latin text for intention to appear obviously out of place outside the context of these tests
my $test_string = "Ad astra per alas porci";
# (what it means: Latin for "to the stars on the wings of a pig", motto used by author John Steinbeck after a teacher
# once told him he'd only be a successful writer when pigs fly)

# test Container::Buildah::prog() and check for existence of prerequisite programs for following tests
my $trueprog = find_prog("true");
if (!defined $trueprog) {
	BAIL_OUT("This system doesn't have a 'true' program? Tests were counting on one to be there.");
}

# test fixtures for program path tests
# these also fill the path cache for commands used in later fork-exec tests
my @prog_tests = (
	{ progname => "true" },
	{ progname => "false" },
	{ progname => "cat" },
	{ progname => "echo" },
	{ progname => "sh" },
	{ progname => "kill" },
	{ progname => "tar" },
	{
		progname => "xyzzy-notfound",
		expected_exception => "unknown secure location for \$progname",
	},
	{
		env => { XYZZY_NOTFOUND_PROG => $trueprog },
		progname => "xyzzy-notfound",
	},
	{
		env => { ECHO_PROG => $trueprog },
		progname => "echo",
	},
);

my $test_total = (scalar @prog_tests)*4;
plan tests => $test_total;
$test_digits = length("".$test_total);

# config for testing
Container::Buildah::init_config(
	basename => "prog_test",
	testing_skip_yaml => 1,
);

# run tests
my $cb = Container::Buildah->instance(($debug_level ? (debug => $debug_level) : ()));
Container::Buildah::prog(); # init cache
{
	for (my $i=0; $i<scalar @prog_tests; $i++) {
			test_prog($cb, $i+1, $prog_tests[$i]);
	}
}

($debug_level>0) and warn Dumper($cb);

1;
