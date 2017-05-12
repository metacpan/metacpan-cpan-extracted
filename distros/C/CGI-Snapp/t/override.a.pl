#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Overrides;

use Log::Handler;

use Test::More;

# ------------------------------------------------

sub test_a
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

	my($app)    = CGI::Snapp::Overrides -> new(logger => $logger, send_output => 0);
	my($output) = $app -> run;

	ok($output =~ /Query parameters.+Query environment/s, 'run() produced the correct output');

	return 1;

} # End of test_a.

# ------------------------------------------------

my($count) = 0;

$count += test_a;

done_testing($count);

