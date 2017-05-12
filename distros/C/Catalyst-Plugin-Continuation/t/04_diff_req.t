#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib "t/lib";

use ok "Test::WWW::Mechanize::Catalyst" => "ContTestApp";

my $m = Test::WWW::Mechanize::Catalyst->new;

$m->get_ok("http://localhost/foo/counter");
my ( $count1, $up1, $down1 ) = split( " ", $m->content );
is( $count1, 0, "count 1 is 0");

$m->get_ok("http://localhost/foo/counter");
my ( $count2, $up2, $down2 ) = split( " ", $m->content );
is( $count2, 0, "count 2 is 0");


$m->get_ok($up1);
( $count1, $up1, $down1 ) = split( " ", $m->content );
is( $count1, 1, "count 1 incremented");

$m->get_ok($up1);
( $count1, $up1, $down1 ) = split( " ", $m->content );
is( $count1, 2, "count 1 incremented");

$m->get_ok($up2);
( $count2, $up2, $down2 ) = split( " ", $m->content );
is( $count2, 1, "count 2 incremented");

$m->get_ok($down1);
( $count1, $up1, $down1 ) = split( " ", $m->content );
is( $count1, 1, "count 1 decremented" );


$m->get_ok($up2);
( $count2, $up2, $down2 ) = split( " ", $m->content );
is( $count2, 2, "count 2 incremented");

$m->get_ok("http://localhost/foo/counter");
my ( $count3, $up3, $down3 ) = split( " ", $m->content );
is( $count3, 0, "count 3 is 0");
