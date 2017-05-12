#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch;

use Log::Handler;

use Test::More;

use Try::Tiny;

# ------------------------------------------------
# Check log from dispatch().

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

	# Pass logger to CGI::Snapp sub-class.

	my($app)  = CGI::Snapp::Dispatch -> new -> as_psgi
	(
	args_to_new => {logger => $logger},
	prefix      => 'CGI::Snapp::Dispatch',
	table       =>
	[
		'/:app/:rm' => {},
	]);

	my($html);

	try
	{
		# This outputs log stuff, which we don't capture, but t/logs.t does.

		$html = $app -> ({PATH_INFO => 'PSGITest/start', REQUEST_METHOD => 'GET'});
	}
	catch
	{
		$html = $_;
	};

	ok(length $#$html > 0,            'as_psgi() returned something');
	ok($$html[2][0] eq 'Hello World', 'as_psgi() returned the expected HTML');

	return 2;

} # End of test_1.

# ------------------------------------------------

my($count) = 0;

$count += test_1;

done_testing($count);
