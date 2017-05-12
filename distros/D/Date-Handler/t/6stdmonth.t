#!/usr/bin/perl
use strict;
use Data::Dumper;
use Date::Handler::Test;

my $test_config = LoadTestConfig() || SkipTest(); 

Date::Handler::Test::StandardMonths();


1;
