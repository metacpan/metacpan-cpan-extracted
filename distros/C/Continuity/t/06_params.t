#!/usr/bin/env perl

use strict;
use Test::More;
require "t/test_helper.pl";

plan tests => 7;

my ($kid_out, $kid_pid) = start_proggie('eg/params.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( $server );

my $name = int rand 100000;
my $thing1 = int rand 100000;
my $thing2 = int rand 100000;
my $thing3 = int rand 100000;

$mech->content_contains("Parameter Passing Example");
$mech->field( name => $name );
$mech->field( favorite => $thing1, 1 );
$mech->field( favorite => $thing2, 2 );
$mech->field( favorite => $thing3, 3 );
$mech->submit;

# For now we'll just make sure it didn't crash
$mech->content_contains($name);
$mech->content_contains($thing1);
$mech->content_contains($thing2);
$mech->content_contains($thing3);

kill 9, $kid_pid;


