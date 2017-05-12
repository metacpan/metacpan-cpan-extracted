#!/usr/bin/env perl

use strict;
use Test::More;
require "t/test_helper.pl";

plan tests => 11;

my ($kid_out, $kid_pid) = start_proggie('eg/cookies.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( $server );
$mech->content_contains("Setting 'continuity-cookie-demo' to 10");

$mech->get_ok( $server );
$mech->content_contains("Got 'continuity-cookie-demo' == 10");

$mech->get_ok( $server );
$mech->content_contains("... still got 'continuity-cookie-demo' == 10");
$mech->content_contains("Setting 'continuity-cookie-demo' to 20");

$mech->get_ok( $server );
$mech->content_contains("Got 'continuity-cookie-demo' == 20");
$mech->content_contains("All done with cookie demo!");

kill 9, $kid_pid;

