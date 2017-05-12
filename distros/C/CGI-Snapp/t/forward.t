#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI;

use CGI::Snapp::ForwardTest;

use Log::Handler;

use Test::More;

# -----------------------------------------------

sub test_a
{
	# Test 1. Don't call forward().

	my($logger) = Log::Handler -> new;

	$logger -> add
		(
		 screen =>
		 {
			 maxlevel       => 'debug',
			 message_layout => '%m',
			 minlevel       => 'error',
			 newline        => 1, # When running from the command line.
		 }
		);

	my($app)         = CGI::Snapp::ForwardTest -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'r_m';
	my($run_mode)    = 'first_r_m';

	$app -> mode_param($mode_source);
	$app -> query(CGI -> new({$mode_source => $run_mode}) );
	$app -> run_modes({$run_mode => 'first_sub'});
	$app -> start_mode($run_mode);

	my($output) = $app -> run;

	ok($output =~ /first_sub/, 'Run mode first_sub returned its name');

	# Check run mode after run(). t/defaults.t checks run mode before run().

	is($app-> get_current_runmode, $run_mode, "Get run mode '$run_mode'");

	return 2;

} # End of test_a.

# -----------------------------------------------

sub test_b
{
	# Test 2. Call forward().

	my($logger) = Log::Handler -> new;

	$logger -> add
		(
		 screen =>
		 {
			 maxlevel       => 'debug',
			 message_layout => '%m',
			 minlevel       => 'error',
			 newline        => 1, # When running from the command line.
		 }
		);

	my($app)         = CGI::Snapp::ForwardTest -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'r_m';
	my($run_mode_1)  = 'second_rm';
	my($run_mode_2)  = 'third_rm';

	$app -> mode_param($mode_source);
	$app -> query(CGI -> new({$mode_source => $run_mode_1}) );
	$app -> run_modes({$run_mode_1 => 'second_sub', $run_mode_2 => 'third_sub'});
	$app -> start_mode($run_mode_1);

	my($output) = $app -> run;

	ok($output =~ /third_sub/, 'Run mode third_sub returned its name');

	# Check run mode after run(). t/defaults.t checks run mode before run().

	is($app-> get_current_runmode, $run_mode_2, "Got run mode '$run_mode_2' after forward()");

	return 2;

} # End of test_b.

# -----------------------------------------------

my($count) = 0;

$count += test_a;
$count += test_b;

done_testing($count);
