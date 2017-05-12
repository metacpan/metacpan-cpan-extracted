use DBI;
use strict;
use lib 't/lib';
use Awesome::DB::User;
use Awesome::DB::Password;

use Test::More tests => 2;

use DBIx::Class::Bootstrap::Simple;
DBIx::Class::Bootstrap::Simple->build_relations;

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", '', '', {  RaiseError => 1 });

$dbh->do(qq{
CREATE TABLE users (
   user_id     int,   password_id int,    name        varchar(255)
)
});

$dbh->do(qq{
CREATE TABLE passwords (
   password_id int,    user_id     int,   password    varchar(255)
)
});

my $schema = DBIx::Class::Bootstrap::Simple->connect(sub { });
$schema->storage->connect_info([{  dbh_maker => sub { $dbh } }]);

my $user = $schema->model('users')->create({ name => 'Waffle Wizard' });
$user->password_id($schema->model('passwords')->create({ user_id => $user, password => 'sleep' }));

cmp_ok($user->name, 'eq', 'Waffle Wizard', 'Waffle Wizard is present');
cmp_ok($user->password->password, 'eq', 'sleep', 'Waffle Wizard password is present');

