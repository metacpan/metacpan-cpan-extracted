#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyAppFail;

our $RESULT;
my @argv = ("fail");

{
    local *ARGV = \@argv;
    MyAppFail->dispatch;
}

ok($RESULT eq "dying message");
