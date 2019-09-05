#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.014;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start;

my $agent = Consul->agent(port => $tc->port);
ok $agent, "got Agent API object";

my $r;

lives_ok { $r = $agent->self } "call to 'self' succeeded";
is $r->member->name, $tc->node_name, "member name is expected";
is ref $r->config, "HASH", " config is a hashref";

lives_ok { $r = $agent->members } "call to 'members' succeeded";
ok scalar @$r > 0, "at least one member in cluster";

lives_ok { $r = $agent->checks } "call to 'checks' succeeded";
ok scalar @$r == 0, "no checks";

lives_ok { $r = $agent->maintenance(1) } "call to 'maintenance' with arg 'true' succeeded";

lives_ok { $r = $agent->checks } "call to 'checks' succeeded";
ok scalar @$r == 1, "one check";
is $r->[0]->id, "_node_maintenance", "found node maintenance check";
is $r->[0]->status, "critical", "node maintenance check is in critical state";

lives_ok { $r = $agent->maintenance(0) } "call to 'maintenance' with arg 'false' succeeded";

lives_ok { $r = $agent->checks } "call to 'checks' succeeded";
ok scalar @$r == 0, "no checks";

done_testing;
