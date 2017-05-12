#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyAppFail;

my @argv = ("fail");

{
    local *ARGV = \@argv;
    MyAppFail->dispatch;
}

ok($MyAppFail::EXIT_VALUE == 1);
