#!/usr/bin/perl
use strict;
use Data::Dumper;
use Date::Handler::Test;

my $test_config = LoadTestConfig() || SkipTest(); 

if(defined $test_config->{locale})
{
	Date::Handler::Test::locale();
}
else
{
	SkipTest();
}


1;
