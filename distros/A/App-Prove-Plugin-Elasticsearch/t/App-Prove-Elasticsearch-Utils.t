use strict;
use warnings;

use Test::More tests => 23;
use Test::Fatal;
use Test::Deep;

use FindBin;
use App::Prove::Elasticsearch::Utils;

CONF: {
    no warnings qw{redefine once};
    local *Config::Simple::import_from = sub {  $_[2]->{'server.host'} = 'zippy.test'; $_[2]->{'server.port'} = '666'; return 1 };
    local *File::HomeDir::my_home      = sub { return $FindBin::Bin };
    use warnings;

    my $expected = { 'server.host' => 'zippy.test', 'server.port' => 666 };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration([]),$expected,"Config file parsed correctly");

    $expected = { 'server.host' => 'hug.test', 'server.port' => 333 };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration(['server.host=hug.test','server.port=333']),$expected,"Config file parsed correctly, overridden correctly");

    no warnings qw{redefine once};
    local *File::HomeDir::my_home      = sub { return '/bogus' };
    is_deeply(App::Prove::Elasticsearch::Utils::process_configuration(['server.host=hug.test','server.port=333']),$expected,"No Config file OK too");
    use warnings;
}

REQUIRE: {
    is(exception { App::Prove::Elasticsearch::Utils::require_indexer({}) },undef,"Indexer load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_indexer({ 'client.indexer' => 'Bogus' }) },qr/INC/,"Indexer load fails on bogus module");

    like(exception { App::Prove::Elasticsearch::Utils::require_searcher({}) },qr/INC/,"searcher load croaks by default");
    is(exception { App::Prove::Elasticsearch::Utils::require_indexer({ 'client.searcher' => 'ByName' }) },undef,"searcher load OK on existing module");

    is(exception { App::Prove::Elasticsearch::Utils::require_blamer({}) },undef,"Blamer load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_blamer({ 'client.blamer' => 'Bogus' }) },qr/INC/,"Blamer load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_planner({}) },undef,"Planner load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_planner({ 'client.planner' => 'Bogus' }) },qr/INC/,"Planner load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_platformer({}) },undef,"Platformer load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_platformer({ 'client.platformer' => 'Bogus' }) },qr/INC/,"Platformer load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_queue({}) },undef,"Queue load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_queue({ 'client.queue' => 'Bogus' }) },qr/INC/,"Queue load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_versioner({}) },undef,"Versioner load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_versioner({ 'client.versioner' => 'Bogus' }) },qr/INC/,"Versioner load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_runner({}) },undef,"Runner load OK: defaults");
    like(exception { App::Prove::Elasticsearch::Utils::require_runner({ 'client.runner' => 'Bogus' }) },qr/INC/,"Runner load fails on bogus module");

    is(exception { App::Prove::Elasticsearch::Utils::require_provisioner('Git') },undef,"Provisioner load OK: using existing module");
    like(exception { App::Prove::Elasticsearch::Utils::require_provisioner('Bogus') },qr/INC/,"Provisioner load fails on bogus module");

}

GET_LAST_ID: {
    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [] } } };
    use warnings;

    my $e = bless({},'Search::Elasticsearch');
    is(App::Prove::Elasticsearch::Utils::get_last_index($e,'zippy'), 0, "Can get last index when there are no hits.");

    no warnings qw{redefine once};
    local *Search::Elasticsearch::search = sub { return { 'hits' => { 'hits' => [1], total => 3 } } };
    use warnings;

    is(App::Prove::Elasticsearch::Utils::get_last_index($e,'zippy'), 3, "Can get last index when there are 3 hits.");

}


