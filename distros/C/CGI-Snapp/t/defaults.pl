#!/usr/bin/env perl

use strict;
use warnings;

use CGI::Snapp;

use Log::Handler;

use Test::More;

# ------------------------------------------------

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

my($count) = 0;
my($app)   = CGI::Snapp -> new(logger => $logger); # Not new(send_output => 0)!

# Check defaults for various things. Note: run() has not been called.

is($app -> error_mode,			'',			'Get default error mode');  $count++;
is($app -> get_current_runmode,	'',			'Get default run mode');    $count++;
is($app -> header_type,			'header',	'Get default header type'); $count++;
is($app -> _run_mode_source,	'rm',		'Get default mode source'); $count++;
is($app -> send_output,			1,			'Get default send_output'); $count++;
is($app -> start_mode,			'start',	'Get default start mode');  $count++;

done_testing($count);
