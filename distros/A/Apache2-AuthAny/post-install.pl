#!/usr/bin/perl

use strict;
use warnings;

my $cmd;
unless ($ENV{AUTH_ANY_ROOT}) {
    die "Env variable AUTH_ANY_ROOT not defined";
}

if (-d $ENV{AUTH_ANY_ROOT}) {
    $cmd = "mv $ENV{AUTH_ANY_ROOT} $ENV{AUTH_ANY_ROOT}_$$";
    system("echo $cmd; $cmd");
}

$cmd = "mkdir $ENV{AUTH_ANY_ROOT}";
system("echo $cmd; $cmd");

unless (-d $ENV{AUTH_ANY_ROOT} && -w _) {
    die "bad directory, '$ENV{AUTH_ANY_ROOT}'";
}

$cmd = "cp -r bin db examples google startup.pl test $ENV{AUTH_ANY_ROOT}";
system("echo $cmd; $cmd");
  
