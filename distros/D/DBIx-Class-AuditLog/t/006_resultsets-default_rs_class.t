use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $users = $schema->resultset('User');
my $changesets;

$schema->txn_do(
    sub {
        $users->create(
            {   name  => "JohnSample",
                email => 'jsample@sample.com',
                phone => '999-888-7777',
            },
        );
        $users->create(
            {   name  => "Jane Sample",
                email => 'jane.sample@sample.com',
                phone => '123.456.7890',
            },
        );
        $users->create(
            {   name  => "The Hulk",
                email => 'bbanner@avengers.com',
                phone => '555-555-5555',
            },
        );
    },
    {   description => "adding a number of new users",
        user        => "TestAdminUser01",
    },
);

is( $users->count, 3, "3 users created" );
subtest "check changesets after initial user creation" => sub {
    $changesets = $al_schema->resultset('AuditLogChangeset');
    is( $changesets->count,                1, "1 changeset created" );
    is( $changesets->first->Action->count, 3, "3 actions created" );
};

$schema->txn_do(
    sub {
        $users->delete;
    },
    {   description => "deleting all users in resultset",
        user        => "TestAdminUser01",
    },
);

is( $users->count, 0, "0 users after deletion via resultset" );
subtest "check changesets after user deletion" => sub {
    $changesets = $al_schema->resultset('AuditLogChangeset');
    is( $changesets->count, 2, "2 changesets after deletion" );
    my $actions = $al_schema->resultset('AuditLogAction');
    is( $actions->count, 6, "6 actions after deletion" );
};

done_testing();
