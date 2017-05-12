#!/usr/bin/env perl

use strict;
use Test::More;

require "t/test_helper.pl";

plan tests => 4;

my ($kid_out, $kid_pid) = start_proggie('eg/query_session.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( $server );
$mech->follow_link_ok({ text => 'Click here to continue' }, 'Link-based (GET) query');
$mech->click_button( value => 'Click here to continue' );
$mech->follow_link_ok({ text => 'Click here to get a new one' }, 'Begin again');

kill 9, $kid_pid;

