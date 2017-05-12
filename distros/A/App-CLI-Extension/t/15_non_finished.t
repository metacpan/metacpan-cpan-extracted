#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyAppFinish;

our $RESULT;
my @argv = ("finished");

{
    local *ARGV = \@argv;
    MyAppFinish->dispatch;
}

ok($RESULT eq "RUN");
