#!/usr/bin/env perl

use strict;
use Test::More;
require "t/test_helper.pl";

plan tests => 27;

my ($kid_out, $kid_pid) = start_proggie('eg/counter.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech1 = Test::WWW::Mechanize->new;

$mech1->get_ok( $server );
$mech1->content_contains('Count: 0', 'Initial count');

$mech1->follow_link_ok({ text => '++' }, 'Click increment link');
$mech1->content_contains('Count: 1', 'Updated count');

# Now lets do our second counter
my $mech2 = Test::WWW::Mechanize->new;
$mech2->get_ok( $server );
$mech2->content_contains('Count: 0', '(2) Initial count');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->content_contains('Count: 5', '(2)Updated count');

$mech1->follow_link_ok({ text => '++' }, 'Click increment link');
$mech1->content_contains('Count: 2', 'Updated count');

$mech1->follow_link_ok({ text => '--' }, 'Click decrement link');
$mech1->content_contains('Count: 1', 'Updated count');

$mech1->follow_link_ok({ text => '--' }, 'Click decrement link');
$mech1->content_contains('Count: 0', 'Updated count');

$mech1->follow_link_ok({ text => '--' }, 'Click decrement link');
$mech1->content_contains('GO NEGATIVE', 'Go Negative Check');

# and some more checks on our second browser
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->follow_link_ok({ text => '++' }, '(2) Click increment link');
$mech2->content_contains('Count: 8', '(2) Updated count');

$mech1->follow_link_ok({ text => 'Yes' }, 'Lets go negative!');
$mech1->content_contains('Count: -1', 'Updated count');

kill 9, $kid_pid;

