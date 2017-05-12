#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

$ENV{Conductrics_agent_name}='Agent-1' unless (exists $ENV{Conductrics_agent_name});

my $env_found;
CHECK_ENV: {
    my @cvars = qw/ apikey ownerCode agent_name /;
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
    plan tests=>10;
}

use_ok('Conductrics::Agent');

my $agent = Conductrics::Agent->new(apiKey=>$ENV{Conductrics_apikey}, ownerCode=>$ENV{Conductrics_ownerCode}, baseUrl=>'http://api.conductrics.com/', name=>$ENV{Conductrics_agent_name});

ok($agent);
isa_ok($agent, "Conductrics::Agent");

#####
my $client;
SKIP: {
    skip "tests of first release of this library", 7 unless($client);
    my $decision1 = $agent->decide("first_sessionId", 'home','colour');
    ok($decision1, "decide()");
    like($decision1, qr/red|green/ );
    
    my $decision2 = $agent->decide("second_sessionId", qw/rosso giallo/);
    ok($decision2, "decide()");
    like($decision2, qr/giallo|rosso/ );
    
    my $reward2 = $agent->reward('12345678900', 'goal-1', 1);
    ok($reward2, 'rewarded');
    
    my $expire2 = $agent->expire('12345678900');
    ok($expire2, "session2 expired");
    my $expire1 = $agent->expire('123456789');
    ok($expire1, "session1 expired");
}
exit;
