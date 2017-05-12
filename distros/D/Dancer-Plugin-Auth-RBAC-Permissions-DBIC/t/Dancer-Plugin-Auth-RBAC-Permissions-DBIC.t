use strict;
use warnings;

use Test::More;
# import => ['!pass'];
use File::Temp qw(tempdir);
use lib "t/lib";

use ok qw(Dancer :syntax);
use ok qw(Dancer::Plugin::DBIC);
use ok qw(Dancer::Plugin::Auth::RBAC);
use ok qw(Dancer::Plugin::Auth::RBAC::Credentials::DBIC);
use ok qw(Dancer::Plugin::Auth::RBAC::Permissions::DBIC);

my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;

my @settings = <DATA>;
set session => "Simple";
set plugins => from_yaml("@settings");

schema->deploy;

my $dbic_user = schema->resultset('User')->find({ login => "foobar" });
foreach my $args ([], [qw(foobar)], [qw(foobar warble)]) {
    my $fail = auth(@{$args});
    ok $fail->errors, "has errors, login failed";
}

my $auth = auth("foobar", "wibble");
isa_ok $auth, "Dancer::Plugin::Auth::RBAC";
ok !$auth->errors, "login successful, no errors";
my $user = session('user');

foreach (qw(id name login)) {
    is( $user->{$_}, $dbic_user->$_, "user $_" );
}

is_deeply $user->{roles}, [], "no roles";

ok $auth->revoke, "Login revoked";
ok ! session('user')->{id}, "Session user element no longer exists";

$auth = auth("barbaz", "wobble");
isa_ok $auth, "Dancer::Plugin::Auth::RBAC";
ok !$auth->errors, "2nd login successful, no errors";
$user = session('user');

is_deeply $user->{roles}, ["user"], "user roles";

ok auth->asa('user'), "asa method";
ok auth->can('products', 'view'), "can method";
ok !auth->can('products', 'update'), "user can not!";

done_testing;

__DATA__
---
DBIC:
  Auth:
    schema_class: TestSchema
    dsn: "dbi:SQLite:dbname=:memory:"
  default:
    schema_class: TestSchema
    dsn: "dbi:SQLite:dbname=:memory:"
Auth::RBAC:
  credentials:
    class: DBIC
  permissions:
    class: DBIC
