use strict;
use warnings;

use DBICx::TestDatabase;
use Test::More;

use lib 't/lib';

my $schema = DBICx::TestDatabase->new('AuditTestCascade::Schema');

$schema->audit_log_schema->deploy;

my $al_schema = $schema->audit_log_schema;

is $al_schema->resultset('AuditLogChangeset')->count, 0, 'log is empty';

$schema->populate('Title',[
    [qw/id name/],
    [qw/ 1 test/],
]);
$schema->populate('Book',[
    [qw/id isbn/],
    [qw/ 1 12345678/],
]);

my $title = $schema->resultset('Title')->first;
$schema->txn_do(sub {
    $title->book->delete;
    $title->update({name => 'test2'}); # update cascades to deleted book
});

is $al_schema->resultset('AuditLogChangeset')->count, 1, 'One changeset logged';

my $cset = $al_schema->resultset('AuditLogChangeset')->first ;
is $cset->Action_rs->count, 2, 'Two actions logged';

my $action = $cset->Action_rs->first;
is $action->Change_rs->count, 2, 'Two changes logged';

done_testing();
