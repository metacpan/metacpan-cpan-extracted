use Test::More;

use lib qw(t/lib);

use HTTP::Request::Common;

use Test::WWW::Mechanize::Catalyst 'MyAppT';

my $mech = Test::WWW::Mechanize::Catalyst->new();

$mech->get_ok('/foobar/start', 'start recorder');

$mech->get_ok('/foo', 'get index');

$mech->get_ok('/foobar/stop', 'stop recorder');

is($mech->content, 'foo', 'custom template');

done_testing;