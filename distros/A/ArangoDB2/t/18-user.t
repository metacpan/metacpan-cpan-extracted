use strict;
use warnings;

use Data::Dumper;
use Test::More;

use ArangoDB2;

my $res;

my $arango = ArangoDB2->new("http://localhost:8529", $ENV{ARANGO_USER}, $ENV{ARANGO_PASS});
my $user = $arango->database->user;

# test required methods
my @api_methods = qw(
    create
    delete
    get
    replace
    update
);

my @methods = qw(
    active
    changePassword
    extra
    name
    passwd
);

for my $method (@methods, @api_methods) {
    can_ok($user, $method);
}

# skip tests against the actual ArangoDB server unless
# LIVE_TEST env param is set
if (!$ENV{LIVE_TEST}) {
    diag("Skipping live API tests - set LIVE_TEST=1 to enable");
    done_testing();
    exit;
}

# delete user
$arango->database->user("foo")->delete;

# create user
$user = $arango->database->user("foo")->passwd("bar")->create;
ok($user, "create user");
is($user->name, "foo", "user: name");
ok($user->active, "user: active");
ok(!$user->changePassword, "user: changePassword");

# try get again
$user = $arango->database->user->get({name => "foo"});
ok($user, "get user");
is($user->name, "foo", "user: name");
ok($user->active, "user: active");
ok(!$user->changePassword, "user: changePassword");

# path
$res = $user->active(0)->update;
ok($res, "path");

# try get again
$user = $arango->database->user->get({name => "foo"});
ok(!$user->active, "user not active");

# replace
$res = $user->replace({
    changePassword => 1,
    passwd => "test",
    active => 1,
});
ok($res, "replace");

# try get again
$user = $arango->database->user->get({name => "foo"});
ok($user->active, "user: active");
ok($user->changePassword, "user: changePassword");

# delete
$res = $user->delete;
ok($res, "delete");

# try get again
$user = $arango->database->user->get({name => "foo"});
ok(!$user, "user deleted");

done_testing();
