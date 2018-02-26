#!/usr/bin/perl

use Test::More;

$ENV{PERL_B_HOOKS_ATRUNTIME} = "filter";

require B::Hooks::AtRuntime;
is B::Hooks::AtRuntime::USE_FILTER(), 1,    "env var enforces filter";

no warnings "redefine";
my $dt = \&Test::More::done_testing;
*done_testing = *Test::More::done_testing = sub { 1; };

require "./t/basic.t";
require "./t/timing.t";
require "./t/destroy.t";
require "./t/scope.t";
require "./t/stuff.t";

$dt->();
