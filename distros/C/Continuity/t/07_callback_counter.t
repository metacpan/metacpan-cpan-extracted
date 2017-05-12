#!/usr/bin/env perl

use strict;
use Test::More;
require "t/test_helper.pl";

plan tests => 11;

my ($kid_out, $kid_pid) = start_proggie('eg/callback_counter.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( $server );
$mech->content_contains('Count: 0', 'Initial count');

$mech->follow_link_ok({ text => '++' }, 'Click increment link');
$mech->content_contains('Count: 1', 'Updated count');

$mech->follow_link_ok({ text => '++' }, 'Click increment link');
$mech->content_contains('Count: 2', 'Updated count');

$mech->follow_link_ok({ text => '--' }, 'Click decrement link');
$mech->content_contains('Count: 1', 'Updated count');

$mech->follow_link_ok({ text => '--' }, 'Click decrement link');
$mech->content_contains('Count: 0', 'Updated count');

kill 9, $kid_pid;

