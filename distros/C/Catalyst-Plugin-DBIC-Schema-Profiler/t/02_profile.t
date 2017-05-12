use strict;
use warnings;

use FindBin;
use Test::More;
use Test::Warn;

use lib "$FindBin::Bin/lib";

BEGIN {
    eval { require DBD::SQLite }
      or plan skip_all => "DBD::SQLite is required for this test";

    eval { require Catalyst::Plugin::Session::State::Cookie }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie is required for this test";

    eval { require Catalyst::Model::DBIC::Schema }
      or plan skip_all =>
      "Catalyst::Model::DBIC::Schema is required for this test";

    eval { require Catalyst::Plugin::Session::Store::DBIC }
      or plan skip_all =>
      "Catalyst::Plugin::Session::Store::DBIC is required for this test";

    $ENV{TESTAPP_DB_FILE} = "$FindBin::Bin/session.db";

    $ENV{TESTAPP_CONFIG} = {
        name    => 'TestApp',
        session => {
            dbic_class => 'DBICSchema::Session',
            data_field => 'data',
        },
        'DBIC::Schema::Profiler' => { MODEL_NAME => 'DBICSchema', },
    };

    $ENV{TESTAPP_PLUGINS} = [
        qw/
          -Debug
          Session
          Session::State::Cookie
          Session::Store::DBIC
          DBIC::Schema::Profiler
          /
    ];
}

{
    use SetupDB;
    use Catalyst::Test 'TestApp';

    my $key   = 'schema';
    my $value = scalar localtime;

    is( get("/session/setup?key=$key&value=$value"), "ok" );
    is( get("/session/delete"),                      "ok" );
}

# Clean up
unlink $ENV{TESTAPP_DB_FILE};

done_testing();

