use strict;
use warnings;
use Test::More;

plan skip_all => 'set EVDB_APP_KEY to enable this test' unless $ENV{EVDB_APP_KEY};
plan tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";
use_ok('Catalyst::Test', 'TestApp');

my $ID    = 'E0-001-000278174-6';
my $TITLE = 'Martini Tasting';

ok((my $response = request("/events/get?id=$ID"))->is_success, 'made request');
like($response->content, qr/'id'\s*=>\s*'$ID'/, 'event ID matches');
like($response->content, qr/'title'\s*=>\s*'$TITLE'/, 'event title matches');
