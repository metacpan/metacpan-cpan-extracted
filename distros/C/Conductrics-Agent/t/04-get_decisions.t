#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

$ENV{Conductrics_agent_name}='YourSite' unless (exists $ENV{Conductrics_agent_name});

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
    plan tests=>14;
}

use_ok('Conductrics::Agent');

my $agent = Conductrics::Agent->new(apiKey=>$ENV{Conductrics_apikey}, ownerCode=>$ENV{Conductrics_ownerCode}, baseUrl=>'http://api.conductrics.com/', name=>$ENV{Conductrics_agent_name});

ok($agent);
isa_ok($agent, "Conductrics::Agent");

my $home_decisions = $agent->get_decisions("first_sessionId", 'home');
ok($home_decisions, "get_decisions() for 'home' colour: '$home_decisions->{decisions}{colour}{code}' font: '$home_decisions->{decisions}{font}{code}'");
like($home_decisions->{decisions}{colour}{code}, qr/red|green|blue/ );

my $auction_decisions = $agent->get_decisions("first_sessionId", 'auction');
ok($auction_decisions, "get_decisions() for 'auction' mood: '$auction_decisions->{decisions}{mood}{code}' product: '$auction_decisions->{decisions}{product}{code}'");
like($auction_decisions->{decisions}{mood}{code}, qr/entusiastic|winning|gambling/ );

my $decision2 = $agent->get_decisions("second_sessionId", 'home');
ok($decision2, "get_decisions() for 'home' colour: '$decision2->{decisions}{colour}{code}' font: '$decision2->{decisions}{font}{code}'");
like($decision2->{decisions}{colour}{code}, qr/red|green|blue/ );

my $decision2_a = $agent->get_decisions("second_sessionId", 'auction');
ok($decision2_a, "get_decisions() for 'auction' mood: '$decision2_a->{decisions}{mood}{code}' product: '$decision2_a->{decisions}{product}{code}'");
like($decision2_a->{decisions}{mood}{code}, qr/entusiastic|winning|gambling/ );

my $reward2 = $agent->reward('second_sessionId', 'sold', 1);

ok(1 == $reward2->{reward}, 'rewarded');

my $expire1 = $agent->expire('second_sessionId');
ok($expire1, "session1 expired");

my $expire2 = $agent->expire('first_sessionId');
ok($expire2, "session2 expired");

exit;
