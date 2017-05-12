use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 25;
use Test::WWW::Mechanize::Catalyst;


# go to the home page
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp');
$mech->get_ok('/');

$mech->get_ok('/encrypt/91134');
$mech->content_is("1789bbe2570f0c19", "Correct content");

$mech->get_ok('/decrypt/1789bbe2570f0c19');
$mech->content_is("91134", "Correct content");

$mech->get_ok('/encrypt/0');
$mech->content_is("31b1774551359936", "Correct content");

$mech->get_ok('/decrypt/31b1774551359936');
$mech->content_is("0", "Correct content");

$mech->get_ok('/encrypt/Hello');
$mech->content_is("18aa1a4b3b51427a", "Correct content");

$mech->get_ok('/decrypt/18aa1a4b3b51427a');
$mech->content_is("Hello", "Correct content");

$mech->get_ok('/encrypt/d4nc3r^$');
$mech->content_is("d2d3f3d040766f71", "Correct content");

$mech->get_ok('/decrypt/d2d3f3d040766f71');
$mech->content_is('d4nc3r^$', "Correct content");

$mech->get_ok('/encrypt/OnTheCatalystFloor');
$mech->content_is("2de1cf49193325f2043a39422646dc24f05e787c0fb7564f", "Correct content");

$mech->get_ok('/decrypt/2de1cf49193325f2043a39422646dc24f05e787c0fb7564f');
$mech->content_is('OnTheCatalystFloor', "Correct content");

$mech->get_ok('/validhash/2de1cf49193325f2043a39422646dc24f05e787c0fb7564f');
$mech->content_is('1', "Correct content");

$mech->get_ok('/validhash/2de1cf49193325f2043a39422646dc24f05e787c0fb756');
$mech->content_is('0', "Correct content");
