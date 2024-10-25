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
<html><head><title>Balancer Manager</title>
<style type='text/css'>
table {
 border-width: 1px;
 border-spacing: 3px;
 border-style: solid;
 border-color: gray;
 border-collapse: collapse;
 background-color: white;
 text-align: center;
}
th {
 border-width: 1px;
 padding: 2px;
 border-style: dotted;
 border-color: gray;
 background-color: lightgray;
 text-align: center;
}
td {
 border-width: 1px;
 padding: 2px;
 border-style: dotted;
 border-color: gray;
 background-color: white;
 text-align: center;
}
</style>
</head>
<body><h1>Load Balancer Manager for localhost</h1>

<dl><dt>Server Version: Apache/2.4.51 (Win64) OpenSSL/1.1.1l</dt>
<dt>Server Built: Oct  7 2021 16:27:02</dt>
<dt>Balancer changes will NOT be persisted on restart.</dt><dt>Balancers are inherited from main server.</dt><dt>ProxyPass settings are inherited from main server.</dt></dl>
<hr />
<h3>LoadBalancer Status for <a href="/balancer-manager?b=balancer_name&amp;nonce=488d6558-fe13-6927-de4f-de761f8f7d74">balancer://balancer_name</a> [pdcfd1ba5_balancer_name]</h3>


<table><tr><th>MaxMembers</th><th>StickySession</th><th>DisableFailover</th><th>Timeout</th><th>FailoverAttempts</th><th>Method</th><th>Path</th><th>Active</th></tr>
<tr><td>2 [2 Used]</td>
<td> (None) </td><td>Off</td>
<td>0</td><td>31</td>
<td>byrequests</td>
<td>/</td>
<td>Yes</td>
</tr>
</table>
<br />

<table><tr><th>Worker URL</th><th>Route</th><th>RouteRedir</th><th>Factor</th><th>Set</th><th>Status</th><th>Elected</th><th>Busy</th><th>Load</th><th>To</th><th>From</th></tr>
<tr>
<td><a href="/balancer-manager?b=balancer_name&amp;w=http://127.0.0.1:5001&amp;nonce=488d6558-fe13-6927-de4f-de761f8f7d74">http://127.0.0.1:5001</a></td><td>route</td><td>redir</td><td>1.50</td><td>3.5</td><td>Init Dis </td><td>41</td><td>0</td><td>100</td><td>  15K </td><td>  1.0K </td></tr>
<tr>
<td><a href="/balancer-manager?b=balancer_name&amp;w=http://127.0.0.1:5002&amp;nonce=488d6558-fe13-6927-de4f-de761f8f7d74">http://127.0.0.1:5002</a></td><td></td><td></td><td>1.00</td><td>0</td><td>Init Ok </td><td>43</td><td>0</td><td>100</td><td>  16K </td><td>1.5K</td></tr>
</table>
<hr />
<h3>LoadBalancer Status for <a href="/balancer-manager?b=second_balancer&amp;nonce=0e761cdb-a55e-c0c4-b5f7-16f46e063ca6">balancer://second_balancer</a> [pdcfd1ba5_second_balancer]</h3>


<table><tr><th>MaxMembers</th><th>StickySession</th><th>DisableFailover</th><th>Timeout</th><th>FailoverAttempts</th><th>Method</th><th>Path</th><th>Active</th></tr>
<tr><td>1 [1 Used]</td>
<td> (None) </td><td>Off</td>
<td>0</td><td>0</td>
<td>byrequests</td>
<td>/cert</td>
<td>Yes</td>
</tr>
</table>
<br />

<table><tr><th>Worker URL</th><th>Route</th><th>RouteRedir</th><th>Factor</th><th>Set</th><th>Status</th><th>Elected</th><th>Busy</th><th>Load</th><th>To</th><th>From</th></tr>
<tr>
<td><a href="/balancer-manager?b=second_balancer&amp;w=http://127.0.0.1:5000&amp;nonce=0e761cdb-a55e-c0c4-b5f7-16f46e063ca6">http://127.0.0.1:5000</a></td><td></td><td></td><td>1.00</td><td>0</td><td>Init Ok </td><td>0</td><td>0</td><td>0</td><td>  0 </td><td>  0 </td></tr>
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
my $nonce = '488d6558-fe13-6927-de4f-de761f8f7d74';

is($mgr->name, 'balancer_name', 'name is correct');
is($mgr->nonce, $nonce, 'nonce is correct');
is($mgr->member_count, 2, 'member_count is correct');
is($mgr->get_member_by_index(0)->location, 'http://127.0.0.1:5001', 'member 0 is what we expect');
is($mgr->get_member_by_index(1)->location, 'http://127.0.0.1:5002', 'member 1 is what we expect');

my $m1 = $mgr->get_member_by_location('http://127.0.0.1:5001');
my $m2 = $mgr->get_member_by_location('http://127.0.0.1:5002');

is($m1->load_factor, '1.50', 'm1 load_factor is correct');
is($m2->load_factor, '1.00', 'm2 load_factor is correct');

is($m1->lb_set, '3.5', 'm1 lb_set is correct');
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

cmp_deeply($a->_post, [
   'http://127.0.0.1/balancer-manager', {
      nonce => $nonce,
      b => 'balancer_name',
      w => 'http://127.0.0.1:5001',
      w_status_D => 1, # disable on = disabled
      w_status_H => 0,
      w_status_I => 0,
      w_status_N => 0,
      w_status_R => 0,
      w_status_S => 0,
      w_lf => '1.50',
      w_ls => '3.5',
      w_rr => 'redir',
      w_wr => 'route'
   }],
'update $m1 contains the correct parameters');

$m2->update;

cmp_deeply($a->_post, [
   'http://127.0.0.1/balancer-manager', {
      nonce => $nonce,
      b => 'balancer_name',
      w => 'http://127.0.0.1:5002',
      w_status_D => 0, # disable off = enabled
      w_status_H => 0,
      w_status_I => 0,
      w_status_N => 0,
      w_status_R => 0,
      w_status_S => 0,
      w_lf => '1.00',
      w_ls => 0,
      w_rr => '',
      w_wr => ''
   }],
'update $m2 contains the correct parameters');

$m1->enable;
$m2->disable;

$m1->update;

cmp_deeply($a->_post, [
   'http://127.0.0.1/balancer-manager', {
      nonce => $nonce,
      b => 'balancer_name',
      w => 'http://127.0.0.1:5001',
      w_status_D => 0, # disable off = enabled
      w_status_H => 0,
      w_status_I => 0,
      w_status_N => 0,
      w_status_R => 0,
      w_status_S => 0,
      w_lf => '1.50',
      w_ls => '3.5',
      w_rr => 'redir',
      w_wr => 'route'
   }],
'update $m1 contains the correct parameters');

$m2->update;

cmp_deeply($a->_post, [
   'http://127.0.0.1/balancer-manager', {
      nonce => $nonce,
      b => 'balancer_name',
      w => 'http://127.0.0.1:5002',
      w_status_D => 1, # disable on = disabled
      w_status_H => 0,
      w_status_I => 0,
      w_status_N => 0,
      w_status_R => 0,
      w_status_S => 0,
      w_lf => '1.00',
      w_ls => 0,
      w_rr => '',
      w_wr => ''
   }],
'update $m2 contains the correct parameters');

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

sub post {
   my $self = shift;
   my ($uri, $form) = @_;

   $self->_post(["$uri", $form]);
}

has _get => ( is => 'rw' );
has _post => ( is => 'rw' );
}
