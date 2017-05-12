#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyApp;

our $RESULT;
my $result = "banana";

{
    local *ARGV = [ "stash", $result ];
    MyApp->dispatch;
}

ok($result eq $RESULT);

