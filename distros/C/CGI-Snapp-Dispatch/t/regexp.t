#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch::Regexp;

use Test::More;

# ------------------------------------------------
# See also CGI::Snapp's t/psgi.basic.pl.
# This demo is copied from CGI::Application V 4.50 t/run_as_psgi.t.
# The PATH_INFO translates to t/lib/CGI::Snapp::Dispatch::PSGITest.

sub test_1
{
	# Note: This uses PSGITest because it's convenient. We are /not/ doing a PSGI test!

	local $ENV{PATH_INFO} = '/CGI_snapp_dispatch_PSGITest';
	my($output)           = CGI::Snapp::Dispatch::Regexp -> new -> dispatch(args_to_new => {send_output => 0});

	ok($output =~ /Hello World/, 'CGI::Snapp::Dispatch::Regexp works with dispatch()');

	return 1;

} # End of test_1.

# ------------------------------------------------

my($count) = 0;

$count += test_1;

done_testing($count);
