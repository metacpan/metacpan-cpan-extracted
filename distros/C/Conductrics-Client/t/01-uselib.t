#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $env_found;
CHECK_ENV: {
    my @cvars = qw/ apikey Mng_apikey ownerCode /;
    for my $v (@cvars) {
	unless (exists $ENV{"Conductrics_$v"}) {
	    plan skip_all=> join ("\n",
				  "\$ENV{Conductrics_$v} has to be defined for this test",
				  "environment vars required:",
				  map {"Conductrics_$_"} @cvars);
	    last CHECK_ENV;
	}
    }
    $env_found=1;
}

if ($env_found) {
    plan tests=>4;
}



use_ok('Conductrics::Client');
my $client = Conductrics::Client->new(apiKey=>$ENV{Conductrics_Mng_apikey}, ownerCode=>$ENV{Conductrics_ownerCode}, baseUrl=>'http://api.conductrics.com/');

ok($client, "Management Client created");
isa_ok($client, 'Conductrics::Client');
can_ok($client, qw/create_agent delete_agent/);

exit;
