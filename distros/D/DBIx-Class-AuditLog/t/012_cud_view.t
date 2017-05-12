use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $test_user;

# CREATE
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
        user_id     => "TestAdminUser01",
    },
);

my $al_view = $al_schema->resultset('AuditLogView')->search(
    { user_name => 'TestAdminUser01' },
    { order_by  => { -desc => 'change_id' } }
)->first;

subtest 'CREATE Tests' => sub {
    ok( $al_view, "View row exists" );
    ok( $al_view->description eq "adding new user: JohnSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_view->action_type eq "insert",
        "AuditLogAction has correct type" );
    done_testing();
};

# UPDATE
$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('User')->find( { name => "JohnSample" } )
            ->update( { name => 'JaneSample', } );
    },
    {   description => "updating user: JohnSample",
        user_id     => "TestAdminUser02",
    },
);

$al_view = $al_schema->resultset('AuditLogView')->search(
    { user_name => 'TestAdminUser02' },
    { order_by  => { -desc => 'change_id' } }
)->first;

subtest 'UPDATE Tests' => sub {
    ok( $al_view, "View row exists" );
    ok( $al_view->description eq "updating user: JohnSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_view->action_type eq "update",
        "AuditLogAction has correct type" );
    ok( $al_view->old_value eq 'JohnSample',
        "AuditLogChange OLD value correct"
    );
    ok( $al_view->new_value eq 'JaneSample',
        "AuditLogChange NEW value correct"
    );
    done_testing();
};

# DELETE
$schema->txn_do(
    sub {
        $test_user
            = $schema->resultset('User')->find( { name => "JaneSample" } )
            ->delete;
    },
    {   description => "deleting user: JaneSample",
        user_id     => "TestAdminUser03",
    },
);

$al_view
    = $al_schema->resultset('AuditLogView')
    ->search( { user_name => 'TestAdminUser03', field_name => 'name' },
    { order_by => { -desc => 'change_id' } } )->first;

subtest 'DELETE Tests' => sub {
    ok( $al_view, "View row exists" );
    ok( $al_view->description eq "deleting user: JaneSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_view->action_type eq "delete",
        "AuditLogAction has correct type" );
    ok( $al_view->old_value eq 'JaneSample',
        "AuditLogChange OLD value correct"
    );
    ok( !defined $al_view->new_value,
        "AuditLogChange NEW value correctly set to null" );
    done_testing();
};

# Disable audit logging when local variable set
{
    no warnings 'once';
    local $DBIx::Class::AuditLog::enabled = 0;

    $schema->txn_do(
        sub {
            $test_user = $schema->resultset('User')->create(
                {   name  => "Larry Wall",
                    email => 'lwall@perl.org',
                    phone => '123-457-7890',
                }
            );
        },
        {   description => "adding new user: Lary Wall",
            user_id     => "TestAdminUser04",
        },
    );

    $al_view = $al_schema->resultset('AuditLogView')->search(
        { user_name => 'TestAdminUser04' },
        { order_by  => { -desc => 'change_id' } }
    )->first;

    ok( !$al_view,
        'No audit log created when $DBIx::Class::AuditLog::enabled = 0' );
}

# Audit logging again enabled outside of scope
$schema->txn_do(
    sub {
        $test_user->name('Damian Conway');
        $test_user->update;
        {
            no warnings 'once';
            local $DBIx::Class::AuditLog::enabled = 0;

            $test_user->email('dconway@perl.org');
            $test_user->update;
        }
    },
    {   description => "updating user: Lary Wall -> name = Damian Conway",
        user_id     => "TestAdminUser05",
    },
);

$al_view = $al_schema->resultset('AuditLogView')->search(
    { user_name => 'TestAdminUser05' },
    { order_by  => { -desc => 'change_id' } }
)->first;

ok( $al_view->new_value eq 'Damian Conway',
    "Audit Logging again enabled outside of scoped local enabled = 0" );

done_testing();

