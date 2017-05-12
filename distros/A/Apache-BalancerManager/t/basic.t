#!/usr/bin/env perl

use strict;
use warnings;

use Test::LWP::UserAgent;
use Test::More;
use Test::Deep;
use URI;

use Apache::BalancerManager;

my $content = <<'CONTENT';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html><head><title>Balancer Manager</title></head>
<body><h1>Load Balancer Manager for localhost</h1>

<dl><dt>Server Version: Apache/2.2.22 (Win32) mod_ssl/2.2.22 OpenSSL/0.9.8t</dt>
<dt>Server Built: Jan 28 2012 11:16:39
</dt></dl>
<hr />
<h3>LoadBalancer Status for balancer://balancer_name</h3>



<table border="0" style="text-align: left;"><tr><th>StickySession</th><th>Timeout</th><th>FailoverAttempts</th><th>Method</th></tr>
<tr><td> - </td><td>0</td><td>31</td>
<td>byrequests</td>
</table>
<br />

<table border="0" style="text-align: left;"><tr><th>Worker URL</th><th>Route</th><th>RouteRedir</th><th>Factor</th><th>Set</th><th>Status</th><th>Elected</th><th>To</th><th>From</th></tr>
<tr>
<td><a
href="/balancer-manager?b=balancer_name&w=http://127.0.0.1:5001&nonce=balancer_nonce">http://127.0.0.1:5001</a></td><td>route</td><td>redir</td><td>0.5</td><td>0.5</td><td>Dis</td><td>41</td><td> 15K</td><td>1.0K</td></tr>
<tr>
<td><a href="/balancer-manager?b=balancer_name&w=http://127.0.0.1:5002&nonce=balancer_nonce">http://127.0.0.1:5002</a></td><td></td><td></td><td>1</td><td>0</td><td>Ok</td><td>43</td><td> 16K</td><td>1.5K</td></tr>
</table>
<hr />
</body></html>
CONTENT

Test::LWP::UserAgent->map_response( qr(127.0.0.1/balancer-manager),
HTTP::Response->new(200, "OK", ["Content-Type" => "text/html"], $content));

my $a = AgentMocker->new;
my $mgr = Apache::BalancerManager->new(
   url => 'http://127.0.0.1/balancer-manager',
   user_agent => $a,
);

is($mgr->name, 'balancer_name', 'name is correct');
is($mgr->nonce, 'balancer_nonce', 'nonce is correct');
is($mgr->member_count, 2, 'member_count is correct');
is($mgr->get_member_by_index(0)->location, 'http://127.0.0.1:5001', 'member 0 is what we expect');
is($mgr->get_member_by_index(1)->location, 'http://127.0.0.1:5002', 'member 1 is what we expect');

my $m1 = $mgr->get_member_by_location('http://127.0.0.1:5001');
my $m2 = $mgr->get_member_by_location('http://127.0.0.1:5002');

is($m1->load_factor, '0.5', 'm1 load_factor is correct');
is($m2->load_factor, 1, 'm2 load_factor is correct');

is($m1->lb_set, '0.5', 'm1 lb_set is correct');
is($m2->lb_set, 0, 'm2 lb_set is correct');

is($m1->route, 'route', 'm1 route is correct');
is($m2->route, '', 'm2 route is correct');

is($m1->route_redirect, 'redir', 'm1 route_redirect is correct');
is($m2->route_redirect, '', 'm2 route_redirect is correct');

is($m1->status, '', 'm1 status is correct');
is($m2->status, 1, 'm2 status is correct');

is($m1->times_elected, 41, 'm1 times_elected is correct');
is($m2->times_elected, 43, 'm2 times_elected is correct');

is($m1->from, '1.0K', 'm1 from is correct');
is($m2->from, '1.5K', 'm2 from is correct');

is($m1->location, 'http://127.0.0.1:5001', 'm1 location is correct');
is($m2->location, 'http://127.0.0.1:5002', 'm2 location is correct');

is($m1->to, '15K', 'm1 to is correct');
is($m2->to, '16K', 'm2 to is correct');

$m1->status(0);
$m2->status(1);

$m1->update;

cmp_deeply(URI->new($a->_get)->query_form_hash, {
  b => 'balancer_name',
  dw => 'Disable',
  lf => '0.5',
  ls => '0.5',
  nonce => 'balancer_nonce',
  rr => 'redir',
  w => 'http://127.0.0.1:5001',
  wr => 'route'
}, 'update $m1 contains the correct parameters');

$m2->update;

cmp_deeply(URI->new($a->_get)->query_form_hash, {
  b => "balancer_name",
  dw => "Enable",
  lf => 1,
  ls => 0,
  nonce => "balancer_nonce",
  rr => "",
  w => "http://127.0.0.1:5002",
  wr => ""
}, 'update $m2 contains the correct parameters');

$m1->enable;
$m2->disable;

$m1->update;

cmp_deeply(URI->new($a->_get)->query_form_hash, {
  b => 'balancer_name',
  dw => 'Enable',
  lf => '0.5',
  ls => '0.5',
  nonce => 'balancer_nonce',
  rr => 'redir',
  w => 'http://127.0.0.1:5001',
  wr => 'route'
}, 'update $m1 contains the correct parameters');

$m2->update;

cmp_deeply(URI->new($a->_get)->query_form_hash, {
  b => "balancer_name",
  dw => "Disable",
  lf => 1,
  ls => 0,
  nonce => "balancer_nonce",
  rr => "",
  w => "http://127.0.0.1:5002",
  wr => ""
}, 'update $m2 contains the correct parameters');

done_testing;

BEGIN {
package AgentMocker;

use Moo;
extends 'Test::LWP::UserAgent';

sub get {
   my $self = shift;

   $self->_get($_[0]);

   $self->next::method(@_);
}

has _get => ( is => 'rw' );
}
