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
$mech->content_is("OK - Task Added", "Added a new task to Minion");

$mech->get_ok('/start');
$mech->content_like( qr/^OK - job \d+ started$/, "...and started a job for that task");

$mech->get_ok("/state/1");
$mech->content_like(qr/State for 1 is inactive$/, 
    "...but its inactive because there are no workers");

done_testing();

