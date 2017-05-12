#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyApp;

our $RESULT;
my $result = "banana";

{
    local *ARGV = ["config", "--color=yellow"];
    MyApp->dispatch;
}

ok($result eq $RESULT);

