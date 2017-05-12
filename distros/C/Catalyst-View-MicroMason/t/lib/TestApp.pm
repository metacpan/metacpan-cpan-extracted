#!/usr/bin/perl
# TestApp.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp;
use Catalyst;
use FindBin qw($Bin);
TestApp->config(root => "$Bin/root");
TestApp->setup;
1;
