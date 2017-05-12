#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::RunScript;

use File::Spec;

use Test::More;

# -----------------------------------------------

sub process_output
{
	my($script, $test_count, $output) = @_;

	ok(length(join('', @$output) ) > 0, "run() in $script returned real data");

	# We need to set this to 0 in case Test::Pod is not installed,
	# because in that case there is no output, and $count is undef.

	my($count) = 0;

	for my $line (@$output)
	{
		# This returns the final value from all matching lines.

		$count = $1 if ($line =~ /^ok\s(\d+)/);
	}

	is($count, $test_count, "$script ran $count test" . ($count == 1 ? '' : 's') );

	# Return the # of tests in /this/ script.

	return 2;

} # End of process_output;

# -----------------------------------------------

my($runner) = CGI::Snapp::RunScript -> new;
my($count)  = 0;
my(%test)   =
(
	'basic.pl'      =>  4,
	'callbacks.pl'  => 13,
	'defaults.pl'   =>  6,
	'headers.pl'    => 17,
	'hook.tests.pl' => 16,
	'isa.pl'        =>  1,
	'overrides.pl'  =>  2,
	'params.pl'     => 12,
	'psgi.basic.pl' =>  4,
	'run.modes.pl'  => 11,
	'subclass.pl'   =>  3,
);

for my $script (sort keys %test)
{
	$count += process_output($script, $test{$script}, $runner -> run_script(File::Spec -> catfile('t', $script) ) );
}

done_testing($count);
