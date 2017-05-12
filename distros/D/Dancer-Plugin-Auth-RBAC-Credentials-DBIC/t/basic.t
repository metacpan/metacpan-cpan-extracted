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
    is( $user->{$_}, $dbic_user->$_, "user $_" )
};

is_deeply $user->{roles}, [], "no roles";

done_testing;

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
      role_relation:
