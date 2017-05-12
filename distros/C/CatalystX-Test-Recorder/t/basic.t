use Test::More;

use lib qw(t/lib);


use HTTP::Request::Common;

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->get_ok('/foo', 'get index');

$mech->get_ok('/recorder/start', 'start recorder');

$mech->get_ok('/foo', 'get index');

$mech->get_ok('/foo', 'get index');

$mech->get_ok('/static/foo', 'get static file');

$mech->get_ok('/recorder/stop', 'stop recorder');

$mech->get_ok('/foo', 'get index');

$mech->get_ok('/recorder/stop', 'stop recorder');

$mech->content_like(qr/2 requests/, '2 requests recorded');

done_testing;