#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Callback;

use Log::Handler;

use Test::Deep;
use Test::More;

# ------------------------------------------------
# The point of using Callback.pm instead of Snapp.pm is that the former
# installs some hooked methods, which return the __PACKAGE__ variable
# as part of their output, in a way that Snapp.pm's defaults subs don't.

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
my($app)   = CGI::Snapp::Callback -> new(logger => $logger, send_output => 0);

isa_ok($app, 'CGI::Snapp::Callback'); $count++;

my($modes) = {finish => 'finisher', start => 'starter'};

$app -> run_modes($modes);

cmp_deeply({$app -> run_modes}, $modes, 'Set/get run modes'); $count++;

ok(length($app -> run) > 0, "Output from $0 is not empty"); $count++;
isa_ok($app -> query, 'CGI::Simple');                       $count++;
isa_ok($app -> cgiapp_get_query, 'CGI::Simple');            $count++;

my($callbacks) = $app -> get_callbacks('class', 'init');

ok(ref $callbacks eq 'HASH', 'get_callbacks() returned a hashref');                               $count++;
ok(ref $$callbacks{'CGI::Snapp'} eq 'ARRAY', 'get_callbacks() returned an arrayref');             $count++;
ok($#{$$callbacks{'CGI::Snapp'} } == 0, 'get_callbacks() returned an arrayref of 1 element');     $count++;
ok($$callbacks{'CGI::Snapp'}[0] eq 'cgiapp_init', 'get_callbacks() returned the correct method'); $count++;

my($hook) = 'crook';

$app -> new_hook($hook);
$app -> add_callback($hook, 'sub_one');
$app -> add_callback($hook, sub{'two'} );
$app -> add_callback($hook, 'sub_three');

$callbacks = $app -> get_callbacks('object', $hook);

ok(ref $callbacks eq 'ARRAY', 'get_callbacks() returned an arrayref');            $count++;
ok($#$callbacks == 2, 'get_callbacks() returned an arrayref of 3 elements');      $count++;
ok($$callbacks[0] eq 'sub_one', 'get_callbacks() returned the correct method');   $count++;
ok($$callbacks[2] eq 'sub_three', 'get_callbacks() returned the correct method'); $count++;

done_testing($count);
