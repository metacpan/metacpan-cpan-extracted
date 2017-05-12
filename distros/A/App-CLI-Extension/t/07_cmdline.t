#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyApp;

our $RESULT;
my @argv = ("cmdline", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, "--verbose");
my @local_argv = @argv;

{
    local *ARGV = \@local_argv;
    MyApp->dispatch;
}

my $cmdline = join " ", (File::Spec->rel2abs($0), @argv);
ok($cmdline eq $RESULT);

