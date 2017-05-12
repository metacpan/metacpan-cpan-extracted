#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::SubClass;

use Log::Handler;

use Test::Deep;
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
my($app)   = CGI::Snapp::SubClass -> new(logger => $logger, send_output => 0, verbose => 1);

# Get the subclass's verbose value.

ok($app -> verbose == 1, 'Subclass has its own params to new() and methods'); $count++;

# Set/get a hash of params.

my(%old_params) = (one => 1, two => 2);

$app -> param(%old_params);

my(%new_params) = map{($_ => $app -> param($_) )} $app -> param;

cmp_deeply(\%old_params, \%new_params, 'Can set and get a hash of params'); $count++;

$app -> delete($_) for keys %old_params;

cmp_deeply([$app -> param], [], 'No params are set after mass delete'); $count++;

done_testing($count);
