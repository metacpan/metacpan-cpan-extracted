#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyApp;

our $RESULT;

my $result = {a => "var", b => {a => 1, b => 2, c => 3}, c => ["a", "b", "c"], config_file => "t/etc/config.yaml"};

{
    local *ARGV = ["yaml"];
    MyApp->dispatch;
}

is_deeply($result, $RESULT);

