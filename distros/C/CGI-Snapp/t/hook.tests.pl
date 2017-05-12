#!/usr/bin/env perl

use lib 't/lib';
use strict;
use warnings;

use CGI::Snapp::RunScript;

use File::Spec;

use Test::Deep;
use Test::More;

# -----------------------------------------------

sub test_a
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::Plugin::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::Plugin::HookTest1.init_sub_1_1()',
'CGI::Snapp::Plugin::HookTest1.init_sub_1_2()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_1()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_2()',
'CGI::Snapp::Plugin::HookTest1.teardown_sub()',
'CGI::Snapp::Plugin::HookTest2.teardown_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct class-level hooks");

	return 2;

} # End of test_a.

# -----------------------------------------------

sub test_b
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::Plugin::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::Plugin::HookTest2.init_sub_2_1()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_2()',
'CGI::Snapp::Plugin::HookTest1.init_sub_1_1()',
'CGI::Snapp::Plugin::HookTest1.init_sub_1_2()',
'CGI::Snapp::Plugin::HookTest2.teardown_sub()',
'CGI::Snapp::Plugin::HookTest1.teardown_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct class-level hooks");

	return 2;

} # End of test_b.

# -----------------------------------------------

sub test_c
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::Plugin::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::Plugin::HookTest::HookTest3.init_sub_1_1()',
'CGI::Snapp::Plugin::HookTest1.init_sub_1_2()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_1()',
'CGI::Snapp::Plugin::HookTest::HookTest3.init_sub_2_2()',
'CGI::Snapp::Plugin::HookTest1.teardown_sub()',
'CGI::Snapp::Plugin::HookTest2.teardown_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct class-level hooks");

	return 2;

} # End of test_c.

# -----------------------------------------------

sub test_d
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::Plugin::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::Plugin::HookTest1.init_sub_1_1()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_2()',
'CGI::Snapp::Plugin::HookTest1.init_sub_1_2()',
'CGI::Snapp::Plugin::HookTest2.init_sub_2_1()',
'CGI::Snapp::Plugin::HookTest1.teardown_sub()',
'CGI::Snapp::Plugin::HookTest2.teardown_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct class-level hooks");

	return 2;

} # End of test_d.

# -----------------------------------------------

sub test_e
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::HookTestA.setup()',
'CGI::Snapp::HookTestA.prerun_mode_sub_1()',
'CGI::Snapp::HookTestA.prerun_mode_sub_2()',
'CGI::Snapp::HookTestA.start_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct object-level hooks");

	return 2;

} # End of test_e.

# -----------------------------------------------

sub test_f
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::HookTestB.setup()',
'CGI::Snapp::HookTestB.prerun_mode_sub_1()',
'CGI::Snapp::HookTestB.start_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct object-level hooks");

	return 2;

} # End of test_f.

# -----------------------------------------------

sub test_g
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::HookTestC.setup()',
'CGI::Snapp::HookTestC.start_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct object-level hooks");

	return 2;

} # End of test_g.

# -----------------------------------------------

sub test_h
{
	my($runner, $script) = @_;
	my($output) = $runner -> run_script($script);

	chomp(@$output);

	$output     = [grep{/CGI::Snapp::HookTest/} @$output];
	my($expect) =
[
'CGI::Snapp::HookTestD.setup()',
'CGI::Snapp::HookTestD.start_sub()',
];
	ok($#$output >= 0, "$script returned real data");
	cmp_deeply($output, $expect, "$script ran the correct object-level hooks");

	return 2;

} # End of test_h.

# -----------------------------------------------

my($runner) = CGI::Snapp::RunScript -> new;
my($count)  = 0;

$count += test_a($runner, File::Spec -> catfile('t', 'hook.test.a.pl') );
$count += test_b($runner, File::Spec -> catfile('t', 'hook.test.b.pl') );
$count += test_c($runner, File::Spec -> catfile('t', 'hook.test.c.pl') );
$count += test_d($runner, File::Spec -> catfile('t', 'hook.test.d.pl') );
$count += test_e($runner, File::Spec -> catfile('t', 'hook.test.a.pl') );
$count += test_f($runner, File::Spec -> catfile('t', 'hook.test.b.pl') );
$count += test_g($runner, File::Spec -> catfile('t', 'hook.test.c.pl') );
$count += test_h($runner, File::Spec -> catfile('t', 'hook.test.d.pl') );

done_testing($count);
