use strict;
use warnings;
use Test::More;

plan skip_all => 'set EVDB_APP_KEY, EVDB_USERNAME, and EVDB_PASSWORD to enable this test'
    unless $ENV{EVDB_APP_KEY} and $ENV{EVDB_USERNAME} and $ENV{EVDB_PASSWORD};
plan tests => 3;

use_ok('Catalyst::Model::EVDB');

Catalyst::Model::EVDB->config(
    app_key  => $ENV{EVDB_APP_KEY},
    username => $ENV{EVDB_USERNAME},
    password => $ENV{EVDB_PASSWORD},
);

ok(my $evdb = Catalyst::Model::EVDB->new, 'created model');
ok($evdb->login, 'logged in using username and password from config');
