use strict;
use warnings;

use Test::More tests => 5;

use lib qw(t/lib);
use DBIC::Test;

my $schema = DBIC::Test->init_schema;
my $row;

my $test_userid = '666';
$schema->current_user_id($test_userid);

$row = $schema->resultset('DBIC::Test::Schema::Accessor')
    ->create({ display_name => 'test record' });

ok $row->u_created, 'created userstamp';
is $row->u_created, $test_userid, 'user id is correct';
is $row->u_updated, $row->u_created, 'update and create userstamp are equal';

# emulate some other user 
my $test2_userid = '777';
$schema->current_user_id($test2_userid);

$row->display_name('test record again');
$row->update;

is $row->u_created, $test_userid, 'create only field isnt changed';
is $row->u_updated, $test2_userid, 'update field is updated correctly';

