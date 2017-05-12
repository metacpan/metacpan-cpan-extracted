#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyAppFailPackage;

our $RESULT;
my @argv = ("raiseerror", "--throw");

{
    local *ARGV = \@argv;
    MyAppFailPackage->dispatch;
}

ok($RESULT eq "App::CLI::Extension::Exception");
