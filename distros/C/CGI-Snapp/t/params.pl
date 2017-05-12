#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp;

use Data::Dumper::Concise; # For Dumper().

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
my($app)   = CGI::Snapp -> new(logger => $logger, send_output => 0);

# Get the default params, of which there are none.

diag 'Start test 1';
diag '-' x 20;
diag Dumper([$app -> param]);
diag '-' x 20;
diag Dumper([]);
diag '-' x 20;

cmp_deeply([$app -> param], [], 'No params are set by default'); $count++;

# Set/get a hash of params.

my(%old_params) = (one => 1, two => 2);

$app -> param(%old_params);

my(%new_params) = map{($_ => $app -> param($_) )} $app -> param;

diag 'Start test 2';
diag '-' x 20;
diag Dumper([sort %old_params]);
diag '-' x 20;
diag Dumper([sort %new_params]);
diag '-' x 20;

cmp_deeply([sort %old_params], [sort %new_params], 'Can set and get a hash of params'); $count++;

$app -> delete($_) for keys %old_params;

diag 'Start test 3';
diag '-' x 20;
diag Dumper([$app -> param]);
diag '-' x 20;
diag Dumper([]);
diag '-' x 20;

cmp_deeply([$app -> param], [], 'No params are set after mass delete'); $count++;

# Set/get a hashref of params.

my($old_params) = {one => 1, two => 2};

$app -> param($old_params);

%new_params = map{($_ => $app -> param($_) ) } $app -> param;

diag 'Start test 4';
diag '-' x 20;
diag Dumper([sort %$old_params]);
diag '-' x 20;
diag Dumper([sort %new_params]);
diag '-' x 20;

cmp_deeply([sort %$old_params], [sort %new_params], 'Can set and get a hash of params'); $count++;

$app -> delete($_) for keys %$old_params;

diag 'Start test 5';
diag '-' x 20;
diag Dumper([$app -> param]);
diag '-' x 20;
diag Dumper([]);
diag '-' x 20;

cmp_deeply([$app -> param], [], 'No params are set after mass delete'); $count++;

# Add params in stages.

%old_params = (one => 1, two => 2);

$app -> param(%old_params);

%old_params = (three => 3, four => 4);

$app -> param(%old_params);

%old_params = (five => 5);

my($value) = $app -> param(%old_params);

diag 'Start test 6';
diag '-' x 20;
diag Dumper($value);
diag '-' x 20;
diag Dumper(5);
diag '-' x 20;

ok($value == 5, 'param($key => $value) returns that value');                $count++;

diag 'Start test 7';
diag '-' x 20;
diag Dumper($value);
diag '-' x 20;
diag Dumper($app -> param('five') );
diag '-' x 20;

ok($value == $app -> param('five'), 'param($key) also returns that value'); $count++;

%old_params = (one => 1, two => 2, three => 3, four => 4, %old_params);

%new_params = map{($_ => $app -> param($_) )} $app -> param;

diag 'Start test 8';
diag '-' x 20;
diag Dumper([sort %old_params]);
diag '-' x 20;
diag Dumper([sort %new_params]);
diag '-' x 20;

cmp_deeply([sort %old_params], [sort %new_params], 'Params match after being added in stages'); $count++;

# What is returned after delete()?

my($key) = 'five';
$value   = $app -> delete($key);

diag 'Start test 9';
diag '-' x 20;
diag Dumper($value);
diag '-' x 20;
diag Dumper(5);
diag '-' x 20;

ok($value == 5, "delete($key) returns the corresponding value: $value");            $count++;

diag 'Start test 10';
diag '-' x 20;
diag Dumper($app -> param($key) );
diag '-' x 20;
diag 'undef';
diag '-' x 20;

ok(! defined $app -> param($key), "After delete($key), param($key) returns undef"); $count++;

$value = $app -> delete($key);

diag 'Start test 11';
diag '-' x 20;
diag Dumper($value);
diag '-' x 20;
diag 'undef';
diag '-' x 20;

ok(! defined $value, "After delete($key) twice, delete() returns undef"); $count++;

# Clean up before testing an arrayref.

$app -> delete($_) for keys %old_params;

$old_params = ['six' => 6, 'seven' => 7];

$app -> param($old_params);

%new_params = map{($_ => $app -> param($_) )} $app -> param;

diag 'Start test 12';
diag '-' x 20;
diag Dumper([sort @$old_params]);
diag '-' x 20;
diag Dumper([sort %new_params]);
diag '-' x 20;

cmp_deeply([sort @$old_params], [sort %new_params], 'Params match after being added via an arrayref'); $count++;

done_testing($count);
