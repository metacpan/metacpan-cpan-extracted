#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI;

use CGI::Snapp::HookTestA;

use Log::Handler;

# ------------------------------------------------

sub test_1
{
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

	my($app)         = CGI::Snapp::HookTestA -> new(logger => $logger, send_output => 0);
	my($mode_source) = 'rm';
	my($run_mode)    = 'start_sub';
	my(%run_modes)   = $app -> run_modes;

	$app -> query(CGI -> new({$mode_source => $run_mode}) );

	my($output) = $app -> run;

} # End of test_1.

# ------------------------------------------------

test_1;
