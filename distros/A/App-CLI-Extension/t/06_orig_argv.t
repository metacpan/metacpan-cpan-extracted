#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyApp;

our $RESULT;

my @argv = ("origargv", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
my @local_argv = @argv;

{
    local *ARGV = \@local_argv;
    MyApp->dispatch;
}

is_deeply(\@argv, $RESULT);

