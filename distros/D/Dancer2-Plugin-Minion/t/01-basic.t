use strict;
use warnings;
 
use lib '.';
use t::lib::TestApp;
use Test::More import => ['!pass'];
use Test::WWW::Mechanize::PSGI;

my $app = TestApp->to_app;
is (ref $app, 'CODE', 'Got the test app');
 
my $mech = Test::WWW::Mechanize::PSGI->new( app => $app );

$mech->get_ok('/');
$mech->content_like( qr/^OK - job \d+ started$/, "Started a job for task Foo");

$mech->get_ok('/run');
$mech->content_is("OK - Task Running", "...and is now running");

$mech->get_ok("/state/1");
$mech->content_like(qr/State for 1 is finished$/, 
    "...and is now finished!");

done_testing();

