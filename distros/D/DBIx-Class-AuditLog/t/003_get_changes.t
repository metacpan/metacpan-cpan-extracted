use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $test_user;
my $changes;

$schema->txn_do(
    sub {
        $test_user = $schema->resultset('User')->create(
            {   name  => "JohnSample",
                email => 'jsample@sample.com',
                phone => '999-888-7777',
            }
        );
    },
    {   description => "adding new user: JohnSample",
        user        => "TestAdminUser01",
    },
);

my $test_user_id = $test_user->id;

my @change_fields = qw< name phone >;    # the email field isn't being logged

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user->id, table => 'user', field => $field } )->first;
    ok( defined $change->new_value && !defined $change->old_value,
        "After insert change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
    ok( defined $change->Action->Changeset->User
             && $change->Action->Changeset->User->name eq 'TestAdminUser01',
        "Changes properly attributed to user 'TestAdminUser01'"
    );
}

$al_schema->resultset('AuditLogChangeset')->delete_all;

$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('User')->find( { name => "JohnSample" } )
            ->update(
            {   name  => 'JaneSample',
                phone => '123-456-7890',
            }
            );
    },
    {   description => "updating user: JohnSample",
        user        => "TestAdminUser02",
    },
);

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user->id, table => 'user', field => $field } )->first;
    ok( defined $change->new_value && defined $change->old_value,
        "After update change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
}

$al_schema->resultset('AuditLogChangeset')->delete_all;

$schema->txn_do(
    sub {
        $test_user->delete;
    },
    {   description => "deleting user: JaneSample",
    },
);

foreach my $field (@change_fields) {
    my $change = $al_schema->get_changes(
        { id => $test_user_id, table => 'user', field => $field } )->first;
    ok( defined $change->old_value,
        "After delete change for field '$field'\t: old_value = '"
            . ( $change->old_value ? $change->old_value : '' )
            . "', new_value = '"
            . ( $change->new_value ? $change->new_value : '' ) . "'"
    );
    ok( !defined $change->Action->Changeset->User,
        "Changes properly not attributed to any user"
    );
}

# field names that don't exist should not return results
$changes = $al_schema->get_changes(
    { id => $test_user_id, table => 'user', field => 'bad_field' } );
is( $changes->count, 0,
    "Correctly found no changes when searching for field 'bad_field'" );

# email is an ignored field, should not show up in audit log
is( $al_schema->resultset("AuditLogField")->search( { name => "email" } )
        ->count,
    0,
    "Email field hasn't been added to AuditLogField table."
);

$changes = $al_schema->get_changes(
    { id => $test_user_id, table => 'user', field => "email" } );
is( $changes->count, 0,
    "Getting changes on field 'email' returns 0 when calling get_changes." );


done_testing();
