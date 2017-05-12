#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch;
use CGI::Snapp::Dispatch::SubClass1;
use CGI::Snapp::Dispatch::SubClass2;
use CGI::Snapp::Dispatch::SubClass3;

use Test::More;

# ------------------------------------------------
# Check defaults from dispatch().

sub test_1
{
	my($app)  = CGI::Snapp::Dispatch -> new(return_type => 1);
	my($args) = $app -> dispatch;

	ok($$args{args_to_new} && ref $$args{args_to_new} eq 'HASH',  'dispatch: args_to_new defaults to hashref');
	ok($$args{default}                                eq '',      "dispatch: default defaults to ''");
	ok($$args{prefix}                                 eq '',      "dispatch: prefix defaults to ''");
	ok($$args{table}       && ref $$args{table}       eq 'ARRAY', 'dispatch: table defaults to arrayref');

	return 4;

} # End of test_1.

# ------------------------------------------------
# Check defaults from dispatch_args().

sub test_2
{
	my($app)  = CGI::Snapp::Dispatch -> new;
	my($args) = $app -> dispatch_args;

	ok($$args{args_to_new} && ref $$args{args_to_new} eq 'HASH',     'dispatch_args: args_to_new defaults to hashref');
	ok($$args{default}                                eq '',         "dispatch_args: default defaults to ''");
	ok($$args{prefix}                                 eq '',         "dispatch_args: prefix defaults to ''");
	ok($$args{table}       && ref $$args{table}       eq 'ARRAY',    'dispatch_args: table defaults to arrayref');
	ok($$args{table}[0]                               eq ':app',     'dispatch_args: table[0] defaults to :app');
	ok($$args{table}[2]                               eq ':app/:rm', 'dispatch_args: table[2] defaults to :app/:rm');

	return 6;

} # End of test_2.

# ------------------------------------------------
# Override defaults.

sub test_3
{
	my($app)   = CGI::Snapp::Dispatch -> new(return_type => 1);
	my($args)  = $app -> dispatch(args_to_new => {PARAMS => {one => 'one'}, user => 'ron'}, default => '/abc', prefix => 'CGI::Snapp::SubClass1');
	my($count) = 0;

	ok($$args{args_to_new}{PARAMS}{one} eq 'one',                   'Merged $$args{args_to_new}{PARAMS}{one}'); $count++;
	ok($$args{args_to_new}{user}        eq 'ron',                   'Merged $$args{args_to_new}{user}'); $count++;
	ok($$args{default}                  eq '/abc',                  'Merged $$args{default}'); $count++;
	ok($$args{prefix}                   eq 'CGI::Snapp::SubClass1', 'Merged $$args{prefix}'); $count++;

	return $count;

} # End of test_3.

# ------------------------------------------------
# Override defaults.

sub test_4
{
	my($app)   = CGI::Snapp::Dispatch::SubClass1 -> new(return_type => 1);
	my($args)  = $app -> dispatch(args_to_new => {PARAMS => {two => 'two'}, user => 'ron'}, prefix => 'CGI::Snapp::SubClass1');
	my($count) = 0;

	ok($$args{args_to_new}{PARAMS}{one} eq 'sub-one',               'Merged $$args{args_to_new}{PARAMS}{one}'); $count++;
	ok($$args{args_to_new}{PARAMS}{two} eq 'two',                   'Merged $$args{args_to_new}{PARAMS}{two}'); $count++;
	ok($$args{args_to_new}{user}        eq 'ron',                   'Merged $$args{args_to_new}{user}'); $count++;
	ok($$args{default}                  eq '',                      'Merged $$args{default}'); $count++;
	ok($$args{prefix}                   eq 'CGI::Snapp::SubClass1', 'Merged $$args{prefix}'); $count++;
	ok($$args{table}[0]                 eq '',                      'Merged $$args{table}[0]'); $count++;
	ok($$args{table}[1]{app}            eq 'Initialize',            'Merged $$args{table}[1]{app}'); $count++;
	ok($$args{table}[1]{rm}             eq 'display',               'Merged $$args{table}[1]{rm}'); $count++;
	ok($$args{table}[2]                 eq ':app',                  'Merged $$args{table}[2]'); $count++;
	ok($$args{table}[3]{rm}             eq 'report',                'Merged $$args{table}[3]{rm}'); $count++;
	ok($$args{table}[4]                 eq ':app/:rm/:id?',         'Merged $$args{table}[4]'); $count++;

	return $count;

} # End of test_4.

# ------------------------------------------------
# Check default module name & run mode with empty path info.

sub test_5
{
	local $ENV{PATH_INFO} = '';
	my($app)        = CGI::Snapp::Dispatch::SubClass1 -> new(return_type => 2);
	my($named_args) = $app -> dispatch;
	my($count)      = 0;

	ok($$named_args{app} eq 'Initialize', "Matched app '$$named_args{app}' to path info '$ENV{PATH_INFO}'"); $count++;
	ok($$named_args{rm}  eq 'display',    "Matched rm '$$named_args{rm}' to path info '$ENV{PATH_INFO}'"); $count++;

	return $count;

} # End of test_5.

# ------------------------------------------------
# Check default module name & run mode with / in path info.

sub test_6
{
	local $ENV{PATH_INFO} = '/';
	my($app)        = CGI::Snapp::Dispatch::SubClass1 -> new(return_type => 2);
	my($named_args) = $app -> dispatch;
	my($count)      = 0;

	ok($$named_args{app} eq 'Initialize', "Matched app '$$named_args{app}' to path info '$ENV{PATH_INFO}'"); $count++;
	ok($$named_args{rm}  eq 'display',    "Matched rm '$$named_args{rm}' to path info '$ENV{PATH_INFO}'"); $count++;

	return $count;

} # End of test_6.

# ------------------------------------------------
# Check extraction of module name & run mode from path info.

sub test_7
{
	local $ENV{PATH_INFO} = '/module_name/rm1';
	my($app)        = CGI::Snapp::Dispatch::SubClass1 -> new(return_type => 2);
	my($named_args) = $app -> dispatch;
	my($count)      = 0;

	ok($$named_args{app} eq 'module_name', "Matched app '$$named_args{app}' to path info '$ENV{PATH_INFO}'"); $count++;
	ok($$named_args{rm}  eq 'rm1',         "Matched rm '$$named_args{rm}' to path info '$ENV{PATH_INFO}'"); $count++;

	return $count;

} # End of test_7.

# ------------------------------------------------
# Check extraction of module name & run mode with leading / in path info.

sub test_8
{
	local $ENV{PATH_INFO} = '/CGI_snapp_app1/rm1';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /I am rm1/, "Matched output to return value from rm1(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_8.

# ------------------------------------------------
# Check extraction of module name & run mode without leading / in path info.

sub test_9
{
	local $ENV{PATH_INFO} = 'CGI_snapp_app1/rm1';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /I am rm1/, "Matched output to return value from rm1(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_9.

# ------------------------------------------------
# Check prefix option.

sub test_10
{
	local $ENV{PATH_INFO} = '/app1/rm1';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, prefix => 'CGI::Snapp');
	my($count)  = 0;

	ok($output =~ /I am rm1/, "Matched output to return value from rm1(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_10.

# ------------------------------------------------
# Check attempt to load non-existent class.

sub test_11
{
	local $ENV{PATH_INFO} = '/does-not-exist/rm1';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, prefix => 'CGI::Snapp');
	my($count)  = 0;

	ok($output =~ /404 Not Found/, "Matched output to croak message for class not found. Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_11.

# ------------------------------------------------
# Check // in path info => Missing module name.

sub test_12
{
	local $ENV{PATH_INFO} = '//';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, prefix => 'CGI::Snapp');
	my($count)  = 0;

	ok($output =~ /404 Not Found/, "Matched output to croak for missing class. Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_12.

# ------------------------------------------------
# Check passing params to new().

sub test_13
{
	local $ENV{PATH_INFO} = '/app1/rm2';
	my($app)    = CGI::Snapp::Dispatch -> new;
	my($output) = $app -> dispatch(args_to_new => {PARAMS => {key1 => 'value1'}, send_output => 0}, prefix => 'CGI::Snapp');
	my($count)  = 0;

	ok($output =~ /key1 => value1/, "Matched output to return value from rm2(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_13.

# ------------------------------------------------
# Check missing run mode in path info is provided by app's setup().

sub test_14
{
	local $ENV{PATH_INFO} = '/app2';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm1 hum=electra_2000/, "Matched output from default rm1(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_14.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_15
{
	local $ENV{PATH_INFO} = '/app2/rm2';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm2 hum=electra_2000/, "Matched output from default rm2(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_15.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_16
{
	local $ENV{PATH_INFO} = '/app2/rm3/stuff';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm3 my_param=stuff hum=electra_2000/, "Matched output from default rm3(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_16.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_17
{
	local $ENV{PATH_INFO} = '/app2/bar/stuff';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm3 my_param=stuff hum=electra_2000/, "Matched output from default rm3(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_17.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_18
{
	local $ENV{PATH_INFO} = '/foo/bar';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm2 hum=electra_2000/, "Matched output from default rm2(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_18.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_19
{
	local $ENV{PATH_INFO} = '/app2/foo';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm3 my_param= hum=electra_2000/, "Matched output from default rm2(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_19.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_20
{
	local $ENV{PATH_INFO} = '/app2/foo/weird';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /CGI::Snapp::App2 -> rm3 my_param=weird hum=electra_2000/, "Matched output from default rm3(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_20.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_21
{
	local $ENV{PATH_INFO} = '/app2/baz/this/is/extra';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ m|CGI::Snapp::App2 -> rm5 dispatch_url_remainder=this/is/extra|, "Matched output from default rm5(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_21.

# ------------------------------------------------
# Check complex dispatch_args in sub-class.

sub test_22
{
	local $ENV{PATH_INFO} = '/app2/bap/this/is/extra';
	my($app)    = CGI::Snapp::Dispatch::SubClass2 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ m|CGI::Snapp::App2 -> rm5 the_rest=this/is/extra|, "Matched output from default rm5(). Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_22.

# ------------------------------------------------
# Check invalid chars in run mode.

sub test_23
{
	local $ENV{PATH_INFO} = '/foo/!';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /400 Bad Request/, "Matched output from illegal chars in run mode: Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_23.

# ------------------------------------------------
# Check customised error document.

sub test_24
{
	local $ENV{PATH_INFO} = '/foo/xyz';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, error_document => '"HTTP error: %s');
	my($count)  = 0;

	ok($output =~ /500 Internal Server Error/, "Matched output from customised error document. Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_24.

# ------------------------------------------------
# Check non-existent error document.

sub test_25
{
	local $ENV{PATH_INFO} = '/foo/xyz';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0});
	my($count)  = 0;

	ok($output =~ /500 Internal Server Error/, "Matched output from non-existent error document. Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_25.

# ------------------------------------------------
# Check customised error document file.

sub test_26
{
	local $ENV{DOCUMENT_ROOT} = '';
	local $ENV{PATH_INFO}     = '/foo/xyz';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, error_document => '<t/args.txt');
	my($count)  = 0;

	ok($output =~ /Customised error document file/, "Matched output from customised error document file. Path info: $ENV{PATH_INFO}"); $count++;

	return $count;

} # End of test_26.

# ------------------------------------------------
# Check auto_rest with $ENV{REQUEST_METHOD}.

sub test_27
{
	local $ENV{PATH_INFO}      = '/app2/rm6';
	local $ENV{REQUEST_METHOD} = 'GET';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, auto_rest => 1);
	my($count)  = 0;

	ok($output =~ /I am rm6_GET/, "Matched output from HTTP GET in table. Path info: $ENV{PATH_INFO}. HTTP method: $ENV{REQUEST_METHOD}"); $count++;

	return $count;

} # End of test_27.

# ------------------------------------------------
# Check auto_rest with $ENV{REQUEST_METHOD}.

sub test_28
{
	local $ENV{PATH_INFO}      = '/app2/rm7';
	local $ENV{REQUEST_METHOD} = 'PUT';
	my($app)    = CGI::Snapp::Dispatch::SubClass3 -> new;
	my($output) = $app -> dispatch(args_to_new => {send_output => 0}, auto_rest => 1, auto_rest_lc => 1);
	my($count)  = 0;

	ok($output =~ /I am rm7_put/, "Matched output from HTTP put in table. Path info: $ENV{PATH_INFO}. HTTP method: $ENV{REQUEST_METHOD}"); $count++;

	return $count;

} # End of test_28.

# ------------------------------------------------

my($count) = 0;

$count += test_1;
$count += test_2;
$count += test_3;
$count += test_4;
$count += test_5;
$count += test_6;
$count += test_7;
$count += test_8;
$count += test_9;
$count += test_10;
$count += test_11;
$count += test_12;
$count += test_13;
$count += test_14;
$count += test_15;
$count += test_16;
$count += test_17;
$count += test_18;
$count += test_19;
$count += test_20;
$count += test_21;
$count += test_22;
$count += test_23;
$count += test_24;
$count += test_25;
$count += test_26;
$count += test_27;
$count += test_28;

done_testing($count);
