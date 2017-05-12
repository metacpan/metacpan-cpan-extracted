use strict;
use warnings;

use Test::More import => ['!pass'];
use File::Temp qw(tempdir);
use lib "t/lib";

use ok qw(Dancer :syntax);
use ok qw(Dancer::Plugin::DBIC);
use ok qw(Dancer::Plugin::Auth::RBAC);
use ok qw(Dancer::Plugin::Auth::RBAC::Credentials::DBIC);

my $dir = tempdir(CLEANUP => 1);
set appdir => $dir;

my @settings = <DATA>;
set session => "Simple";
set plugins => from_yaml("@settings");

schema->deploy;
my $dbic_user = schema->resultset('CustomUser')->find({ username => "barbaz" });

my $auth = auth("barbaz", "wobble");
isa_ok $auth, "Dancer::Plugin::Auth::RBAC";
ok !$auth->errors, "login successful, no errors";
my $user = session('user');

foreach (
    [id => "uid"],
    [name => "nickname"],
    [login => "username"],
) {
    my ($key, $field) = @{$_};
    is $user->{$key}, $dbic_user->$field, "user $key";
};

is_deeply $user->{roles}, ["user"], "user roles";

done_testing();

__DATA__
---
DBIC:
  Auth:
    schema_class: TestSchema
    dsn: "dbi:SQLite:dbname=:memory:"
Auth::RBAC:
  credentials:
    class: DBIC
    options:
      user_moniker: CustomUser
      id_field: uid
      name_field: nickname
      login_field: username
      password_field: passphrase
      password_type: self_check
      role_name_field: rolename
