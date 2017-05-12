use strict;
use warnings FATAL => 'all';

use Test::More tests => 78;
use File::Temp qw(tempdir);
use File::Slurp;
use Carp;
use Data::Dumper;
use YAML;
use Apache::SWIT::Maker::Config;
use Apache::SWIT::Test::Request;
use Apache::SWIT::Test::Utils;

BEGIN { # $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
	use_ok('T::Apache::SWIT::Security::Role::Container');
	use_ok('Apache::SWIT::Security::Maker');
	use_ok('Apache::SWIT::Security::Role::Container');
	use_ok('Apache::SWIT::Security::Role::Loader'); 
	use_ok('Apache::SWIT::Security::Role::Manager'); 
	use_ok('Apache::SWIT::Security', qw(Sealed_Params Hash)); 
}

unlike(read_file('blib/conf/httpd.conf'), qr/SWITSecurityPermissions/);
is(ADMIN_ROLE, 1);
is(USER_ROLE, 2);

my $man = Apache::SWIT::Security::Role::Manager->new({
	"some/url/r" => {
		perms => [ Apache::SWIT::Security::Role::Manager::ALL ],
	}
});
ok($man);
is($man->access_control("some/strange/url"), undef);

is(Hash("foo\n"), 'd3b07384d113edec49eaa6238ad5ff00');

{
	local $ENV{AS_SECURITY_SALT} = 1234;
	is(Hash("foo\n"), '83414769c2c135aef8c4c821af5b4c5f');
};

my $ac = $man->access_control("some/url/r");
ok($ac);

is($ac->check_user, 1);

$ac->{_perms} = [ -1*Apache::SWIT::Security::Role::Manager::ALL ];
is($ac->check_user, undef);

$ac->{_perms} = [ 12 ];
is($ac->check_user, undef);

my @roles = (12);

package User;
sub role_ids { return @roles };

package main;
is($ac->check_user('User'), 1);
@roles = (13);
is($ac->check_user('User'), undef);

$ac->{_perms} = [ 12, 13 ];
is($ac->check_user('User'), 1);
$ac->{_perms} = [ -13, 13 ];
is($ac->check_user('User'), undef);

is($man->access_control("/dynamically/added"), undef);
$man->add_uri_access_control("/dynamically/added", { perms => [ 12, 13 ] });

$ac = $man->access_control("/dynamically/added");
ok($ac);
is_deeply($ac->{_perms}, [ 12, 13 ]);
is($ac->check_user('User'), 1);

my $sec_yaml_str = <<ENDS;
roles:
  1: admin
  2: user
pages: {}
ENDS
my $loader = Apache::SWIT::Security::Role::Loader->new;
my $tree = Load($sec_yaml_str);
bless($tree, 'Apache::SWIT::Maker::Config');
$loader->load_role_container($tree->{roles});
$loader->load($tree);

is($loader->roles_container->find_role_by_id(2)->name, 'user');
is($loader->roles_container->find_role_by_id(1)->id, 1);
eval { $loader->roles_container->find_role_by_id(3); };
like($@, qr/Unable to find/);
is($loader->roles_container->find_role_by_name('admin')->id, 1);

is_deeply([ $loader->roles_container->roles_list ], [ 
		[ 1, 'admin' ], [ 2, 'user' ] ]);
isa_ok($loader->url_manager, 'Apache::SWIT::Security::Role::Manager');

my $_class;

package P;

sub on_req {
	$_class = shift;
	return shift()->param('up');
}

package main;

my $sec_yaml_str2 = <<ENDS;
roles:
  1: admin
  2: user
  3: manager
  4: forbidden
root_location: /root
pages:
  some/url:
    entry_points:
      r:
        # role_permissions take precedence
        permissions: [ -all ]
      u:
        permissions: [ -user, +all ]
  other/url:
    entry_points:
      r:
        permissions: [ +manager ]
  ok/aga:
    entry_points:
      r:
        permissions: []
  han/page.txt:
    handler: momo
    permissions: [ +manager ]
  fun/empty:
    class: P
    handler: momo
    security_hook: on_req
  fun/bun:
    class: P
    handler: momo
    permissions: [ +manager ]
    security_hook: on_req
  old:
    entry_points:
      one: {}

  # check that security_hook works with rule_permissions
  guh:
    class: P
    entry_points:
      fuh:
         handler: h
         security_hook: on_req

  # check undef perms error everywhere
  ahh:
    handler: h

rule_permissions:
  # not going to work because of entry point permissions
  - [ '.*ahh.*' ]
  # second rule should not play
  - [ '/root/ahh.*', '+manager' ]
  - 
    - '.*some/url/r'
    - '+all'
  - 
    - '.*some/boo.*'
    - '-all'
  - [ '/root/foo/bah' ]
  - [ '.*txt', '-forbidden' ]
  - [ '.*boo.*', '+manager' ]
  - [ '.*/ok/.*', '+all' ]
  - [ '/root/foo/.*', '+all' ]
  - [ '.*guh.*', '+manager' ]

capabilities:
  moo_cap: [ +manager ]
  user_can: [ +user ]
ENDS
my $loader2 = Apache::SWIT::Security::Role::Loader->new;
$tree = Load($sec_yaml_str2);
bless($tree, 'Apache::SWIT::Maker::Config');
$loader2->load_role_container($tree->{roles});
$loader2->load($tree);
$man = $loader2->url_manager;

$ac = $man->access_control("/root/some/url/r");
ok($ac);
is($ac->check_user('User'), 1);

# only absolute urls going to work. For relative ones see URI->abs in Session
is($man->access_control("other/url/r"), undef);

is($man->access_control("/root/foo/bah"), undef);
isnt($man->access_control("/root/ahh"), undef); # set through role_permissions
is($man->access_control("ok/aga/r"), undef);

$ac = $man->access_control("/root/some/url/u");
ok($ac);
is($ac->check_user('User'), 1);

$ac = $man->access_control("/root/other/url/r");
ok($ac);
is($ac->check_user('User'), undef);

@roles = (2, 3);
$ac = $man->access_control("/root/other/url/r");
is($ac->check_user('User'), 1);

$ac = $man->access_control("/root/some/url/u");
is($ac->check_user('User'), undef) or diag(Dumper($ac));

$ac = $man->access_control("/root/han/page.txt");
isnt($ac, undef);
is($ac->check_user('User'), 1);

@roles = (2, 3, 4);
is($ac->check_user('User'), undef) or diag(Dumper($ac));

@roles = (2, 3);
$ac = $man->access_control('moo_cap');
is($ac, undef);

$ac = $man->capability_control('moo_cap');
isnt($ac, undef);
is($ac->check_user('User'), 1);

eval { $man->capability_control('foo_cap'); };
like($@, qr/capability foo_cap/);

$ac = $man->access_control("/strange/boo");
isnt($ac, undef);
is($ac->check_user('User'), 1);

$ac = $man->access_control("/some/boo"); # deny for all works here
isnt($ac, undef);
is($ac->check_user('User'), undef);

$ac = $man->access_control("/root/fun/bun");
isnt($ac, undef);
my @r = @roles;
@roles = (13);

my $req = Apache::SWIT::Test::Request->new;
is($ac->check_user('User', $req), undef);
is($_class, 'P');

$req->set_params({ up => 1 });
is($ac->check_user('User', $req), 1);
is($ac->check_user(undef, $req), 1);

$ac = $man->access_control("/root/fun/empty");
isnt($ac, undef);
is($ac->check_user('User', $req), 1);

$req->set_params({ up => undef });
is($ac->check_user('User', $req), undef);

$ac = $man->access_control("/root/guh/fuh");
isnt($ac, undef);
is($ac->check_user('User', $req), undef);

$req->set_params({ up => 1 });
is($ac->check_user('User', $req), 1);

@roles = @r;
$req->set_params({ up => undef });
is($ac->check_user('User', $req), 1);

$ac = $man->access_control("/ok/ggg");
isnt($ac, undef);

# +all should open the resource even for user with no cookie
is($ac->check_user, 1);

$ac = $man->access_control("/root/old/one");
is($ac, undef);

$ac = $man->access_control("/root/foo/a.txt");
isnt($ac, undef);

my $td = tempdir("/tmp/100_manager_t_XXXXXX", CLEANUP => 1);
chdir $td;

mkdir 'conf';
mkdir 'blib';
mkdir 'blib/conf';
write_file('conf/swit.yaml', $sec_yaml_str2);

$tree = Apache::SWIT::Maker::Config->instance;
$tree->{env_vars}->{AS_SECURITY_MANAGER} = 'R::C::Role::Manager';
$tree->{env_vars}->{AS_SECURITY_CONTAINER} = 'R::C::Role::Container';
$tree->{env_vars}->{AS_SECURITY_USER_CLASS}
	= 'Apache::SWIT::Security::DB::User';
Apache::SWIT::Security::Maker->new->write_sec_modules;
ok(require("blib/lib/R/C/Role/Container.pm"));

eval { require("blib/lib/R/C/Role/Manager.pm"); };
is($@, '') or ASTU_Wait("blib/lib/R/C/Role/Manager.pm at $td");

my $rcc = R::C::Role::Container->create;
is_deeply($rcc, $loader2->roles_container);
isa_ok($rcc, 'R::C::Role::Container');
is($rcc->find_role_by_id(1)->name, 'admin');

my $mcc = R::C::Role::Manager->create;
is_deeply($mcc, $loader2->url_manager);

chdir('/');

package Apache2::Request;
sub new { return $_[1]; }

package main;

HTML::Tested::Seal->instance('bbb');
$req->set_params({ a => HTML::Tested::Seal->instance->encrypt('A'), b => 'B' });
is_deeply([ Sealed_Params($req, 'a', 'b', 'c') ], [ 'A', undef, undef ]);

$req->set_params({ c => HTML::Tested::Seal->instance->encrypt('A') });
my @res = Sealed_Params($req, 'a', 'b', 'c');
is_deeply(\@res, [ undef, undef, 'A' ]);
