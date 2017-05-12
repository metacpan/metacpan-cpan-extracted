#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::Dispatch::RunScript;

use File::Spec;

use Test::Deep;
use Test::More;

# ------------------------------------------------

sub test_a
{
	my($runner, $script)  = @_;
	local $ENV{PATH_INFO} = '/';
	my($output)           = $runner -> run_script($script);

	chomp(@$output);

	my($expect) = <<EOS;
dispatch(...)
_merge_args(...)
_clean_path(/, ...)
Path info '/'
_parse_path(/, ...)
Original rule ':app'
Rule is now   '/:app/'
Rule is now   '/([^/]*)/'
Names in rule [app]
Trying to match path info '/' against rule ':app' using regexp '/([^/]*)/'
Original rule ':app/:rm'
Rule is now   '/:app/:rm/'
Rule is now   '/([^/]*)/([^/]*)/'
Names in rule [app, rm]
Trying to match path info '/' against rule ':app/:rm' using regexp '/([^/]*)/([^/]*)/'
Nothing matched
_http_error(..., 404)
Processing HTTP error 404
ok 1 - dispatch() returned something
ok 2 - dispatch() returned the expected HTML
1..2
EOS
	my(@expect) = split(/\n/, $expect);

	ok($#$output >= 0, "$script returned real data from dispatch()");

	cmp_deeply($output, \@expect, "$script returned the correct log content from dispatch()");

	return 2;

} # End of test_a.

# ------------------------------------------------

sub test_b
{
	my($runner, $script) = @_;
	my($output)          = $runner -> run_script($script);

	chomp(@$output);

	my($expect) = <<EOS;
call_hook(init, ...)
cgiapp_init()
run_modes(...)
mode_param(...)
run()
_determine_output()
_determine_run_mode() => start
call_hook(prerun, ...)
cgiapp_prerun()
_generate_output()
run_modes(...)
call_hook(postrun, ...)
cgiapp_postrun()
_determine_psgi_header()
_query()
header_type()
header_props(...)
call_hook(teardown, ...)
teardown()
ok 1 - as_psgi() returned something
ok 2 - as_psgi() returned the expected HTML
1..2
EOS
	my(@expect) = split(/\n/, $expect);

	ok($#$output >= 0, "$script returned real data from as_psgi()");

	cmp_deeply($output, \@expect, "$script returned the correct log content from as_psgi()");

	return 2;

} # End of test_b.

# ------------------------------------------------

my($runner) = CGI::Snapp::Dispatch::RunScript -> new;
my($count)  = 0;

$count += test_a($runner, File::Spec -> catfile('t', 'log.a.pl') );
$count += test_b($runner, File::Spec -> catfile('t', 'log.b.pl') );

done_testing($count);
