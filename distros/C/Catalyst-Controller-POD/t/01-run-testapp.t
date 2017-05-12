use strict;
use warnings;

use Test::More tests => 12;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('/test');
$mech->content_contains("here I am");

$mech->get_ok("/");
$mech->content_contains("Pod::Browser");

$mech->content_contains("http://localhost//static/docs.css", "correct root directory");

$mech->get_ok("http://localhost//static/docs.css");
$mech->content_contains(".pod ol");


$mech->get_ok("/docs");
$mech->content_contains("Pod::Browser");



$mech->content_contains("http://localhost/docs/static/docs.css", "correct root directory in subdir");

$mech->get_ok("http://localhost/docs/static/docs.css");
$mech->content_contains(".pod ol");
