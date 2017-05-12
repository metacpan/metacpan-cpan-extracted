use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

my $al_user
    = $al_schema->resultset('AuditLogUser')->create( { name => "TestUser" } );

# ensure that we are getting the value from the db rather than just the dbic
# object just created
$al_user->get_from_storage;

isa_ok(
    $al_user,
    "DBIx::Class::Schema::AuditLog::Structure::User",
    "AuditLogUser created."
);

ok( $al_user->name eq "TestUser", "AuditLogUser name is correct" );

done_testing();
