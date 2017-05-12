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
    'UserForceaudit',
    [   [qw/name email phone/],
        [qw/JohnSample jsample@sample.com 999-888-7777/]
    ]
);

$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('UserForceaudit')
            ->find( { name => "JohnSample" } )->update(
            {   name  => 'JaneSample',
                phone => '123-456-7890',
            }
            );
    },
    {   description => "updating user: JohnSample",
        user        => "TestAdminUser02",
    },
);

my $change = $al_schema->get_changes(
    { id => $test_user->id, table => 'user', field => 'email' } )->first;

ok $change, "email field is audited";

is $change->old_value, $change->new_value,
    "old_value (email) equals new_value (email)";

done_testing();
