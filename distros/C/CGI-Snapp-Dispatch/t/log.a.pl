#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch;

use Log::Handler;

use Test::More;

# ------------------------------------------------
# Check log from dispatch().

sub test_1
{
	local $ENV{PATH_INFO} = '/';
	my($logger)           = Log::Handler -> new;

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

	# Pass logger to CGI::Snapp::Dispatch, not CGI::Snapp.

	my($app)  = CGI::Snapp::Dispatch -> new(logger => $logger);
	my($html) = $app -> dispatch;

	ok(length($html) > 0,                        'dispatch() returned something');
	ok($html =~ m|<title>404 Not Found</title>|, 'dispatch() returned the expected HTML');

	return 2;

} # End of test_1.

# ------------------------------------------------

my($count) = 0;

$count += test_1;

done_testing($count);
