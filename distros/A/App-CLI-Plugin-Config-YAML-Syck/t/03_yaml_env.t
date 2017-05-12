#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use lib qw(t/lib);
use MyAppEnv;

our $RESULT;

my $result = {a => "var", b => {a => 1, b => 2, c => 3}, c => ["a", "b", "c"]};

{
    $ENV{APPCLI_CONFIGFILE} = "t/etc/config.yaml";
    local *ARGV = ["yaml"];
    MyAppEnv->dispatch;
}

is_deeply($result, $RESULT);

