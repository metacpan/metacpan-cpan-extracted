#!/usr/bin/perl

use strict;
use Test::More tests => 1;
use File::Spec;
use lib qw(t/lib);
use MyApp;

our $RESULT;

{
    local *ARGV = [ "fullargv" ];
    MyApp->dispatch;
}

ok(File::Spec->rel2abs($0) eq $RESULT);

