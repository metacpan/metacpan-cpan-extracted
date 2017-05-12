#!/usr/bin/perl

use strict;
use Test::More tests => 2;
use File::Spec;
use lib qw(t/lib);
use MyAppCallback;

our %RESULT;
my @argv = ("callback", "--callback=any_phase");

{
    local *ARGV = \@argv;
    MyAppCallback->dispatch;
}

ok($RESULT{_test_callback1} eq "any_phase execute 1", "_test_callback1");
ok($RESULT{_test_callback2} eq "any_phase execute 2", "_test_callback2");
