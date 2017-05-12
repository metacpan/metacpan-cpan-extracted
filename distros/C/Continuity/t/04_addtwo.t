#!/usr/bin/env perl

use strict;
use Test::More;
require "t/test_helper.pl";

plan tests => 5;

my ($kid_out, $kid_pid) = start_proggie('eg/addtwo.pl');
my $server = get_proggie_server_ok($kid_out);

my $mech = Test::WWW::Mechanize->new;

$mech->get_ok( $server );

my $num1 = int rand 1000;
my $num2 = int rand 1000;
my $sum  = $num1 + $num2;

$mech->content_contains("Enter first number");
$mech->field( num => $num1 );
$mech->submit;

$mech->content_contains("Enter second number");
$mech->field( num => $num2 );
$mech->submit;

$mech->content_contains("The sum of $num1 and $num2 is $sum!");

kill 9, $kid_pid;

