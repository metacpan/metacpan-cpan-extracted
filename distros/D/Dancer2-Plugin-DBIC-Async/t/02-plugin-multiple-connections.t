#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Plack::Test;
use HTTP::Request::Common;
use DBI;

my $dir      = tempdir(CLEANUP => 1);
my $db_file1 = catfile($dir, 'test1.db');
my $db_file2 = catfile($dir, 'test2.db');

# Set up first database
{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file1", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    });

    $dbh->do(q{
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
        )
    });

    $dbh->do(q{ INSERT INTO users (name) VALUES ('DB1-User1') });
    $dbh->do(q{ INSERT INTO users (name) VALUES ('DB1-User2') });
    $dbh->disconnect;
}

# Set up second database
{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file2", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
    });

    $dbh->do(q{
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
        )
    });

    $dbh->do(q{ INSERT INTO users (name) VALUES ('DB2-User1') });
    $dbh->disconnect;
}

{
    package TestApp;
    use Dancer2;
    use lib 't/lib';

    set(
        plugins => {
            'DBIC::Async' => {
                default => {
                    schema_class => 'Test::Schema',
                    dsn          => "dbi:SQLite:dbname=$db_file1",
                    user         => '',
                    password     => '',
                    options      => { sqlite_unicode => 1 },
                    async        => { workers => 2 },
                },
                secondary => {
                    schema_class => 'Test::Schema',
                    dsn          => "dbi:SQLite:dbname=$db_file2",
                    user         => '',
                    password     => '',
                    options      => { sqlite_unicode => 1 },
                    async        => { workers => 2 },
                },
            },
        }
    );

    use Dancer2::Plugin::DBIC::Async;

    get '/db1/count' => sub {
        my $count = async_count('User', 'default')->get;
        content_type 'application/json';
        to_json({ count => $count });
    };

    get '/db2/count' => sub {
        my $count = async_count('User', 'secondary')->get;
        content_type 'application/json';
        to_json({ count => $count });
    };

    get '/db1/find/:id' => sub {
        my $user = async_find('User', route_parameters->get('id'), 'default')->get;
        content_type 'application/json';
        to_json($user);
    };

    get '/db2/find/:id' => sub {
        my $user = async_find('User', route_parameters->get('id'), 'secondary')->get;
        content_type 'application/json';
        to_json($user);
    };

    post '/db1/create' => sub {
        my $result = async_create('User', { name => body_parameters->get('name') }, 'default')->get;
        content_type 'application/json';
        to_json($result);
    };

    post '/db2/create' => sub {
        my $result = async_create('User', { name => body_parameters->get('name') }, 'secondary')->get;
        content_type 'application/json';
        to_json($result);
    };
}

use lib 't/lib';

my $app = Plack::Test->create(TestApp->to_app);

subtest 'Default connection - count' => sub {

    my $res = $app->request(GET '/db1/count');
    ok($res->is_success, 'DB1 count request successful') or diag($res->content);
    like($res->content, qr/"count"\s*:\s*2/, 'DB1 has 2 users');
};

subtest 'Secondary connection - count' => sub {

    my $res = $app->request(GET '/db2/count');
    ok($res->is_success, 'DB2 count request successful') or diag($res->content);
    like($res->content, qr/"count"\s*:\s*1/, 'DB2 has 1 user');
};

subtest 'Default connection - find' => sub {

    my $res = $app->request(GET '/db1/find/1');
    ok($res->is_success, 'DB1 find request successful') or diag($res->content);
    like($res->content, qr/DB1-User1/, 'Found correct user from DB1');
};

subtest 'Secondary connection - find' => sub {

    my $res = $app->request(GET '/db2/find/1');
    ok($res->is_success, 'DB2 find request successful') or diag($res->content);
    like($res->content, qr/DB2-User1/, 'Found correct user from DB2');
};

subtest 'Create in both connections' => sub {

    # Create in DB1
    my $res1 = $app->request(POST '/db1/create', [name => 'DB1-User3']);
    ok($res1->is_success, 'DB1 create successful') or diag($res1->content);

    # Create in DB2
    my $res2 = $app->request(POST '/db2/create', [name => 'DB2-User2']);
    ok($res2->is_success, 'DB2 create successful') or diag($res2->content);

    # Verify counts
    my $count1 = $app->request(GET '/db1/count');
    like($count1->content, qr/"count"\s*:\s*3/, 'DB1 now has 3 users');

    my $count2 = $app->request(GET '/db2/count');
    like($count2->content, qr/"count"\s*:\s*2/, 'DB2 now has 2 users');

    # Verify new records exist
    my $find1 = $app->request(GET '/db1/find/3');
    like($find1->content, qr/DB1-User3/, 'New DB1 user found');

    my $find2 = $app->request(GET '/db2/find/2');
    like($find2->content, qr/DB2-User2/, 'New DB2 user found');
};

done_testing();
