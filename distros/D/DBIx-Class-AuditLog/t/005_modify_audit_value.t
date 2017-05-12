use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $test_user;

$schema->populate(
    'UserModifyAuditvalue',
    [   [qw/name email phone/],
        [qw/JohnSample jsample@sample.com 999-888-7777/]
    ]
);

$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('UserModifyAuditvalue')
            ->find( { name => "JohnSample" } )->update(
            {   name  => 'JaneSample',
                phone => '123-456-7890',
                email => 'janesample@sample.com',
            }
            );
    },
    {   description => "updating user: JohnSample",
        user        => "TestAdminUser02",
    },
);

my $change = $al_schema->get_changes(
    { id => $test_user->id, table => 'user', field => 'name' } )->first;

ok $change, "name field is audited";

is $change->old_value, "johnsample", "old_value (name) was modified";

is $change->new_value, "janesample", "new_value (name) was modified";

is $test_user->name, "JaneSample", "actual db-record (name) is NOT modified";

$change = $al_schema->get_changes(
    { id => $test_user->id, table => 'user', field => 'phone' } )->first;

ok $change, "phone field is audited";

is $change->old_value, "9998887777", "old_value (phone) was modified";

is $change->new_value, "1234567890", "new_value (phone) was modified";

is $test_user->phone, "123-456-7890",
    "actual db-record (phone) is NOT modified";

$change = $al_schema->get_changes(
    { id => $test_user->id, table => 'user', field => 'email' } )->first;

ok $change, "email field is audited";

is $change->old_value, "jsample_at_sample.com",
    "old_value (email) was modified";

is $change->new_value, "janesample_at_sample.com",
    "new_value (email) was modified";

is $test_user->email, 'janesample@sample.com',
    "actual db-record (email) is NOT modified";

done_testing();
