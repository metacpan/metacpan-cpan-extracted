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

my $al_user = $al_schema->resultset('AuditLogUser')
    ->search( { name => 'TestAdminUser01' } )->first;

isa_ok(
    $al_user->Changeset->first,
    "DBIx::Class::Schema::AuditLog::Structure::Changeset",
    "Changeset found after CREATE"
);
subtest 'CREATE Tests' => sub {
    ok( $al_user->Changeset->first->description eq
            "adding new user: JohnSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_user->Changeset->first->Action->first->action_type eq "insert",
        "AuditLogAction has correct type" );
    ok( $al_user->Changeset->first->Action->first->Change,
        "AuditLogChange(s) found for CREATE" );
    ok( !$al_schema->resultset('AuditLogField')->search( { name => "email" } )
            ->count,
        "Field 'email' correctly ignored as per schema option"
    );
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

$al_user = $al_schema->resultset('AuditLogUser')
    ->search( { name => 'TestAdminUser02' } )->first;

isa_ok(
    $al_user->Changeset->first,
    "DBIx::Class::Schema::AuditLog::Structure::Changeset",
    "Changeset found after UPDATE"
);
subtest 'UPDATE Tests' => sub {
    ok( $al_user->Changeset->first->description eq
            "updating user: JohnSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_user->Changeset->first->Action->first->action_type eq "update",
        "AuditLogAction has correct type" );
    ok( $al_user->Changeset->first->Action->first->Change->first->old_value eq
            'JohnSample',
        "AuditLogChange OLD value correct"
    );
    ok( $al_user->Changeset->first->Action->first->Change->first->new_value eq
            'JaneSample',
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

$al_user = $al_schema->resultset('AuditLogUser')
    ->search( { name => 'TestAdminUser03' } )->first;

isa_ok(
    $al_user->Changeset->first,
    "DBIx::Class::Schema::AuditLog::Structure::Changeset",
    "Changeset found after DELETE"
);
subtest 'DELETE Tests' => sub {
    ok( $al_user->Changeset->first->description eq
            "deleting user: JaneSample",
        "AuditLogChangeset has correct description"
    );
    ok( $al_user->Changeset->first->Action->first->action_type eq "delete",
        "AuditLogAction has correct type" );
    my $field = $al_schema->resultset('AuditLogField')
        ->search( { name => 'name' } )->first;
    ok( $al_user->Changeset->first->Action->first->Change->search(
            { field_id => $field->id }
            )->first->old_value eq 'JaneSample',
        "AuditLogChange OLD value correct"
    );
    ok( !defined $al_user->Changeset->first->Action->first->Change->first
            ->new_value,
        "AuditLogChange NEW value correctly set to null"
    );
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

    $al_user = $al_schema->resultset('AuditLogUser')
        ->search( { name => 'TestAdminUser04' } )->first;

    ok(!$al_user, 'No audit log created when $DBIx::Class::AuditLog::enabled = 0');
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

$al_user = $al_schema->resultset('AuditLogUser')
    ->search( { name => 'TestAdminUser05' } )->first;

ok( $al_user->Changeset->first->Action->first->Change->first->new_value eq
        'Damian Conway',
    "Audit Logging again enabled outside of scoped local enabled = 0"
);

ok( $al_user->Changeset->first->Action->count == 1,
    'Locally scoped enabled = 0 inside transaction is not logged' );


done_testing();
