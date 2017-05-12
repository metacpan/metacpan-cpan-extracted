use strict;
use warnings;

use Test::More 0.89;
use HTTP::Request::Common qw/GET POST DELETE/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp;

ok(TestApp->installdb, 'Setup Database');
ok(TestApp->deploy_dbfixtures, 'Fixtures Deployed');

ok my $schema = TestApp->model('Schema'),
  'got the schema';

ok my @users = &get_ordered_users($schema),
  'got users';

is_deeply [map {$_->email} @users], [
    'john@shutterstock.com',
    'james@shutterstock.com',
    'jay@shutterstock.com',
    'vanessa@shutterstock.com',
    'error@error.com',
], 'Got expected emails';

ok my @roles = &get_ordered_roles($schema),
  'got roles';

is_deeply [map {$_->name} @roles], [
    'member',
    'admin',
], 'Got expected role names';

ok my($john, $james, $jay, $vanessa) = @users,
  'broke out users';

is_deeply [sort map {$_->name} $john->roles->all] ,[qw(admin member)],
  'roles for john';

is_deeply [sort map {$_->name} $james->roles->all] ,[qw(admin member)],
  'roles for james';

is_deeply [sort map {$_->name} $jay->roles->all] ,[qw(member)],
  'roles for jay';

is_deeply [sort map {$_->name} $vanessa->roles->all] ,[qw(admin)],
  'roles for vanessa';

sub get_ordered_users {
    (shift)->
        resultset('User')->
        search({}, {order_by => {-asc=>'user_id'}})->
        all;
}

sub get_ordered_roles {
    (shift)->
        resultset('Role')->
        search({}, {order_by => {-asc=>'role_id'}})->
        all;
}

use Catalyst::Test 'TestApp';

ok my $users = request(GET '/dbic/users')->content,
  'Got store content';

is_deeply [split ',', $users], [
    'john@shutterstock.com',
    'james@shutterstock.com',
    'jay@shutterstock.com',
    'vanessa@shutterstock.com',
    'error@error.com',
], 'Got expected emails';

ok my $roles = request(GET '/dbic/roles')->content,
  'Got store content';

is_deeply [split ',', $roles], [
    'member',
    'admin',
], 'Got expected emails';

is request(GET '/dbic/user_roles/100')->content, 'member,admin',
  'right roles';

is request(GET '/dbic/user_roles/101')->content, 'member,admin',
  'right roles';

is request(GET '/dbic/user_roles/102')->content, 'member',
  'right roles';

is request(GET '/dbic/user_roles/103')->content, 'admin',
  'right roles';

done_testing;

