#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Basename;
use lib qw(t/lib);
use MyApp;

our $RESULT;
my $result = basename($0);

{
    local *ARGV = [ "argv" ];
    MyApp->dispatch;
}

ok($result eq $RESULT);

