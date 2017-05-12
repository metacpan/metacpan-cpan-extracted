#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI;

use CGI::Snapp::RunModes;

use Log::Handler;

use Test::Deep;
use Test::More tests => 11;

use Try::Tiny;

# ------------------------------------------------

sub test_1
{
	# Test 1. Various.

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

	my($app)         = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'r_m';
	my($run_mode)    = 'first_r_m';

	$app -> mode_param($mode_source);
	$app -> query(CGI -> new({$mode_source => $run_mode}) );
	$app -> run_modes({first_r_m => 'first_sub'});

	my($output) = $app -> run;

	ok($output =~ /first_sub/, 'Run mode first_sub returned its name');

	# Check run mode after run(). t/defaults.t checks run mode before run().

	is($app-> get_current_runmode, $run_mode, "Get run mode '$run_mode' using old CGI object");

	# Check a new CGI object does not reset the run mode.

	my($q) = CGI -> new;

	$app -> query($q);

	is($app -> get_current_runmode, $run_mode,    "Get run mode $run_mode using new CGI object");
	is($app -> _run_mode_source,    $mode_source, 'Get current mode source');

} # End of test_1.

# ------------------------------------------------

sub test_2
{
	# Test 2. Check a run mode of 0 works.

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

	my($app)         = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'rr_mm';
	my($run_mode)    = 0;

	$app -> mode_param($mode_source);
	$app -> query -> param($mode_source => $run_mode);
	$app -> run_modes({$run_mode => 'second_sub'});

	my($output) = $app -> run;

	ok($output =~ /second_sub/, 'Run mode second_sub returned its name');

	is($app -> get_current_runmode, $run_mode, "Get run mode $run_mode");

} # End of test_2.

# ------------------------------------------------

sub test_3
{
	# Test 3. Check set and get run modes; preserving start. C.f. test 4.

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

	my($app)         = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'rr_mm';
	my($run_mode)    = 'first_r_m';

	$app -> mode_param($mode_source);
	$app -> query -> param($mode_source => $run_mode);
	$app -> run_modes({first_r_m => 'first_sub'});
	$app -> run_modes([qw/one/]);
	$app -> start_mode($run_mode);
	$app -> run;

	my(%run_modes) = $app -> run_modes;

	cmp_deeply([map{($_ => $run_modes{$_})} sort keys %run_modes], [qw/first_r_m first_sub one one start dump_html/], 'Set and retrieve run modes; preserving start');

} # End of test_3.

# ------------------------------------------------

sub test_4
{
	# Test 4. Check set and get run modes; replacing start. C.f. test 3.

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

	my($app)         = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'rm';
	my($run_mode)    = 'second_rm';
	my(%run_modes)   = (one => 'one_rm', $run_mode => 'second_sub');

	$app -> query -> param($mode_source => $run_mode);
	$app -> run_modes(%run_modes);
	$app -> start_mode($run_mode);
	$app -> run;

	%run_modes = $app -> run_modes;

	cmp_deeply([map{($_ => $run_modes{$_})} sort keys %run_modes], [qw/one one_rm second_rm second_sub start dump_html/], 'Set and retrieve run modes, replacing start');

	$app -> run_modes({});

	my(%same_modes) = $app -> run_modes;

	cmp_deeply(\%run_modes, \%same_modes, 'Check $app -> run_modes({}) is a no-op');

} # End of test_4.

# ------------------------------------------------

sub test_5
{
	# Test 5. Test the AUTOLOAD option.

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

	my($app) = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);

	$app -> query -> param(rm => 'runner_bean');
	$app -> run_modes(AUTOLOAD => 'autoload_sub');

	my($output) = $app -> run;

	ok($output =~ /autoload_sub/, 'Run mode autoload_sub returned its name');

} # End of test_5.

# ------------------------------------------------

sub test_6
{
	# Test 6: Set the run mode to a method which croaks, so as to trigger a call to error_mode.

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

	my($app)      = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($run_mode) = 'third_rm';

	$app -> add_callback('error', 'error_hook_sub');
	$app -> error_mode('error_mode_sub');
	$app -> query -> param(rm => $run_mode);
	$app -> run_modes($run_mode => 'third_sub');
	$app -> start_mode($run_mode);

	my($output) = $app -> run;

	ok($output =~ /error_mode_sub/, 'Run mode error_mode_sub returned its name');

} # End of test_6.

# ------------------------------------------------

sub test_7
{
	# Test 7: Call mode_param(\&sub).

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

	my($app)      = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($run_mode) = 'fourth_rm';

	$app -> query -> param('mode_param_sub_rm' => $run_mode);
	$app -> run_modes($run_mode => 'fourth_sub');
	$app -> set_mode_param_1;

	my($output) = $app -> run;

	ok($output =~ /fourth_sub/, 'Run mode fourth_sub returned its name');

} # End of test_7.

# ------------------------------------------------

sub test_8
{
	# Test 8: Call mode_param(path_info => $integer).

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

	my($run_mode)   = 'fifth_rm';
	$ENV{PATH_INFO} = "$run_mode/sixth_rm";
	my($app)        = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);

	$app -> mode_param(path_info => 1);
	$app -> run_modes($run_mode => 'fifth_sub', sixth_rm => 'sixth_sub');

	my(%run_modes) = $app -> run_modes;
	my($output)    = $app -> run;

	ok($output =~ /fifth_sub/, 'Run mode fifth_sub returned its name');

	$app -> mode_param(path_info => 2);

	$output = $app -> run;

	ok($output =~ /sixth_sub/, 'Run mode sixth_sub returned its name');

	$app -> mode_param([qw/path_info -2/]);

	$output = $app -> run;

	ok($output =~ /fifth_sub/, 'Run mode fifth_sub returned its name');

} # End of test_8.

# ------------------------------------------------

sub test_9
{
	# Test 9: Call prerun_mode() at the wrong time, and so croak.

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

	my($app) = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);

	$app -> query -> param(rm => 'start');
	$app -> run_modes(start => 'eighth_sub');

	my($output);

	try
	{
		# This line will croak.

		$app -> set_mode_param_2;
		$output = $app -> run;

	}
	catch
	{
		$output = 'Calling prerun_mode() from within a run mode croaks';
	};

	ok($output =~ /within a run mode/, 'Croaked as expected from calling prerun_mode() from a run mode');

} # End of test_9.

# ------------------------------------------------

sub test_10
{
	# Test 10: Test use of nested try/catch in _generate_output() by croaking within a error mode method.

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

	my($app)      = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($run_mode) = 'rm';

	$app -> error_mode('faulty_error_mode_sub');
	$app -> query -> param(rm => $run_mode);
	$app -> run_modes($run_mode => 'faulty_run_mode_sub');
	$app -> start_mode($run_mode);

	my($output);

	try
	{
		# This line will croak.

		$output = $app -> run;

	}
	catch
	{
		$output = 'Croaking in faulty_error_mode_sub';
	};


	ok($output =~ /Croaking in faulty_error_mode_sub/, 'Caught croak in faulty_error_mode_sub');

} # End of test_10.

# ------------------------------------------------

sub test_11
{
	# Test 11. Set run mode to a non-existant method.

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

	my($app)      = CGI::Snapp::RunModes -> new(logger => $logger, send_output => 0);
	my($run_mode) = 'runner_bean';

	$app -> query -> param(rm => $run_mode);
	$app -> run_modes($run_mode => 'does_not_exist');

	my($output);

	try
	{
		# This line will croak.

		$output = $app -> run;
	}
	catch
	{
		$output = "Can't locate object method ...";
	};

	ok($output =~ /Can't locate object method/, 'Run mode points to a non-existant method');

} # End of test_11.

# ------------------------------------------------

subtest  'test_1' => \&test_1;
subtest  'test_2' => \&test_2;
subtest  'test_3' => \&test_3;
subtest  'test_4' => \&test_4;
subtest  'test_5' => \&test_5;
subtest  'test_6' => \&test_6;
subtest  'test_7' => \&test_7;
subtest  'test_8' => \&test_8;
subtest  'test_9' => \&test_9;
subtest 'test_10' => \&test_10;
subtest 'test_11' => \&test_11;
