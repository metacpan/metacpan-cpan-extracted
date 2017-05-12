#!/usr/bin/env perl

use FindBin;
use Test::Most;
use Test::WWW::Mechanize::Catalyst;
use lib "$FindBin::Bin/lib";

ok my $mech = Test::WWW::Mechanize::Catalyst->new(
  catalyst_app => 'TestApp');

$mech->get_ok("/welcome");
$mech->content_is("Welcome to Catalyst: 1");

$mech->get_ok("/welcome");
$mech->content_is("Welcome to Catalyst: 2");

$mech->get_ok("/welcome");
$mech->content_is("Welcome to Catalyst: 3");

done_testing;
