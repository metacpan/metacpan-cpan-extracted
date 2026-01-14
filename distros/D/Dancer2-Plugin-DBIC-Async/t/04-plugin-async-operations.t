#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);

use Plack::Test;
use HTTP::Request::Common qw(GET POST PUT DELETE);
use DBI;

my $dir     = tempdir(CLEANUP => 1);
my $db_file = catfile($dir, 'test.db');

my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

$dbh->do(q{
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )
});

for my $i (1..10) {
    $dbh->do(qq{ INSERT INTO users (name) VALUES ('User$i') });
}

$dbh->disconnect;

{
    package TestApp;
    use Dancer2;
    use lib 't/lib';

    set(
        plugins => {
            'DBIC::Async' => {
                default => {
                    schema_class => 'Test::Schema',
                    dsn          => "dbi:SQLite:dbname=$db_file",
                    user         => '',
                    password     => '',
                    options      => { sqlite_unicode => 1 },
                    async        => { workers => 2 },
                },
            },
        }
    );

    use Dancer2::Plugin::DBIC::Async;

    get '/count' => sub {
        my $count = async_count('User')->get;
        content_type 'application/json';
        to_json({ count => $count });
    };

    get '/find/:id' => sub {
        my $user = async_find('User', route_parameters->get('id'))->get;
        content_type 'application/json';
        to_json($user);
    };

    get '/search' => sub {
        my $users = async_search('User', { name => { -like => 'User%' } })->get;
        content_type 'application/json';
        to_json({ count => scalar(@$users) });
    };

    post '/create' => sub {
        my $user = async_create('User', { name => body_parameters->get('name') })->get;
        content_type 'application/json';
        to_json($user);
    };

    put '/update/:id' => sub {
        my $result = async_update(
            'User',
            route_parameters->get('id'),
            { name => body_parameters->get('name') }
        )->get;
        content_type 'application/json';
        to_json({ success => $result });
    };

    del '/delete/:id' => sub {
        my $result = async_delete('User', route_parameters->get('id'))->get;
        content_type 'application/json';
        to_json({ success => $result });
    };
}

use lib 't/lib';

my $app = Plack::Test->create(TestApp->to_app);

subtest 'Count operation' => sub {

    my $res = $app->request(GET '/count');
    ok($res->is_success, 'Count request successful') or diag($res->content);
    like($res->content, qr/"count"\s*:\s*10/, 'Found all 10 users');
};

subtest 'Find operation' => sub {

    my $res = $app->request(GET '/find/1');
    ok($res->is_success, 'Find request successful') or diag($res->content);
    like($res->content, qr/"id"\s*:\s*1/, 'Found user with ID 1');
    like($res->content, qr/"name"\s*:\s*"User1"/, 'User has correct name');
};

subtest 'Search operation' => sub {

    my $res = $app->request(GET '/search');
    ok($res->is_success, 'Search request successful') or diag($res->content);
    like($res->content, qr/"count"\s*:\s*10/, 'Search found all matching users');
};

subtest 'Create operation' => sub {

    my $res = $app->request(POST '/create', [name => 'NewUser']);

    ok($res->is_success, 'Create request successful') or diag($res->content);
    like($res->content, qr/"name"\s*:\s*"NewUser"/, 'Created user has correct name');

    # Verify count increased
    $res = $app->request(GET '/count');
    like($res->content, qr/"count"\s*:\s*11/, 'Count increased to 11');
};

subtest 'Update operation' => sub {

    my $res = $app->request(PUT '/update/1', [name => 'UpdatedUser']);
    my $data= decode_json($res->content);
    is $data->{success}{id}, 1, 'ID is correct';
    is $data->{success}{name}, 'UpdatedUser', 'Name is updated';

    ok($res->is_success, 'Update request successful') or diag($res->content);
    #like($res->content, qr/"success"\s*:\s*1/, 'Update succeeded');

    # Verify update
    $res = $app->request(GET '/find/1');
    like($res->content, qr/"name"\s*:\s*"UpdatedUser"/, 'User was updated');
};

subtest 'Delete operation' => sub {

    my $res = $app->request(DELETE '/delete/2');
    ok($res->is_success, 'Delete request successful') or diag($res->content);
    like($res->content, qr/"success"\s*:\s*1/, 'Delete succeeded');

    # Verify count decreased
    $res = $app->request(GET '/count');
    like($res->content, qr/"count"\s*:\s*10/, 'Count decreased to 10');
};

done_testing();
