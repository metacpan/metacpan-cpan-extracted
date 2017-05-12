use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTest::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

is $al_schema->resultset('AuditLogChangeset')->count, 0, 'log is empty';

$schema->populate('User',[
    [qw/id name/],
    [qw/ 0 test/],
]);

my $updates = {
    name => 'test2',
};

my $user = $schema->resultset('UserForceaudit')->first;
$schema->txn_do(sub{ $user->update($updates)});
is $al_schema->resultset('AuditLogChangeset')->count, 1, 'One changeset logged';

my $cset = $al_schema->resultset('AuditLogChangeset')->first ;
is $cset->Action_rs->count, 1, 'One action logged';

my $action = $cset->Action_rs->first;
is $action->Change_rs->count, 2, 'Two changes logged';

my $phonefield = $al_schema->resultset('AuditLogField')->find({name => 'phone'});
ok !$phonefield , 'AuditLogField "phone" NOT created';

my $namefield = $al_schema->resultset('AuditLogField')->find({name => 'name'});
ok $namefield , 'AuditLogField "name" created';
ok $action->Change_rs->find({field_id => $namefield->id}), 'changed name column logged';

my $mailfield = $al_schema->resultset('AuditLogField')->find({name => 'email'});
ok $mailfield , 'AuditLogField "email" created';
ok $action->Change_rs->find({field_id => $mailfield->id}), 'changed mail column logged';

done_testing();
