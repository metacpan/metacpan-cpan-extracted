#!perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Consul 0.005;

use Consul;

Test::Consul->skip_all_if_no_bin;

my $tc = Test::Consul->start;

skip "consul test environment not available", 13 unless $tc;

my $session = Consul->session(port => $tc->port);
ok $session, "got Session API object";

my ($r, $id);

lives_ok { $id = $session->create } "call to 'create' succeeded";
ok $id, "got session id";

lives_ok { $r = $session->info($id) } "call to 'info' succeeded";
isa_ok $r, "Consul::API::Session::Session", "got session object";
is $r->id, $id, "returned session id matches created id";

lives_ok { $r = $session->destroy($id) } "call to 'destroy' succeeded";

lives_ok { $r = $session->info($id) } "call to 'info' succeeded";
is $r, undef, "session not found";

my ($id1, $id2);
lives_ok { $id1 = $session->create } "call to 'create' succeeded";
lives_ok { $id2 = $session->create } "call to 'create' succeeded";

lives_ok { $r = $session->list } "call to 'list' succeeded";
is_deeply([ sort ($id1, $id2) ], [ sort map { $_->id } @$r ], "returned session list matches created session list");

done_testing;
