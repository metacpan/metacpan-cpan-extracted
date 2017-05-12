#!/usr/bin/perl

use strict;
use Test::More tests => 9;
use File::Spec;
use lib qw(t/lib);
use MyAppActionChain;

our %RESULT;
my @argv = ("chain");

{
    local *ARGV = \@argv;
    MyAppActionChain->dispatch;
}

ok($RESULT{setup1} eq "MyAppActionChain::Plugin::Setup1");
ok($RESULT{setup2} eq "MyAppActionChain::Plugin::Setup2");
ok($RESULT{prerun1} eq "MyAppActionChain::Plugin::Prerun1");
ok($RESULT{prerun2} eq "MyAppActionChain::Plugin::Prerun2");
ok($RESULT{run} eq "MyAppActionChain::ChainTest");
ok($RESULT{postrun1} eq "MyAppActionChain::Plugin::Postrun1");
ok($RESULT{postrun2} eq "MyAppActionChain::Plugin::Postrun2");
ok($RESULT{finish1} eq "MyAppActionChain::Plugin::Finish1");
ok($RESULT{finish2} eq "MyAppActionChain::Plugin::Finish2");
