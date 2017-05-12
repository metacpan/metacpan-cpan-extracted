use strict;
use warnings;
use Test::More;

plan skip_all => 'set EVDB_APP_KEY to enable this test' unless $ENV{EVDB_APP_KEY};
plan tests => 4;

use_ok('Catalyst::Model::EVDB');

Catalyst::Model::EVDB->config(
    app_key => $ENV{EVDB_APP_KEY},
);

ok(my $evdb = Catalyst::Model::EVDB->new, 'created model');

my $ID    = 'E0-001-000278174-6';
my $TITLE = 'Martini Tasting';

my $response = $evdb->call('events/get', { id => $ID });
is($response->{id},    $ID,    'event ID matches');
is($response->{title}, $TITLE, 'event title matches');
