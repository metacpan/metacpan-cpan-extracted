#!/usr/bin/env perl

use strict;
use warnings;

use CGI;
use CGI::Snapp;

use Log::Handler;

use Test::Deep;
use Test::More tests => 4;

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

my($app) = CGI::Snapp -> new(logger => $logger, QUERY => CGI -> new, send_output => 0);

isa_ok($app, 'CGI::Snapp');

my($modes) = {finish => 'finisher', starter => 'starter'};

$app -> query -> param(rm => 'start');
$app -> run_modes($modes);

cmp_deeply({$app -> run_modes}, {%$modes, start => 'dump_html'}, 'Set/get run modes');

my($output) = $app -> run;

ok(length($output) > 0, "Output from $0 is not empty");
ok($app -> get_current_runmode eq 'start', "Current run mode is 'start'");
