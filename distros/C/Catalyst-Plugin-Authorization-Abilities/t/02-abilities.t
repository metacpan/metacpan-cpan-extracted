#!/usr/bin/env perl

use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HTTP::Request::Common;

BEGIN{
  $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1;
  $ENV{CATALYST_CONFIG} = 't/conf/abilities.yml';
  eval {
        require Catalyst::Plugin::Authentication;
        require Catalyst::Plugin::Session;
        require Catalyst::Plugin::Session::State::Cookie;
        require CatalystX::SimpleLogin;
        require Catalyst::Plugin::Session::Store::FastMmap;
        require Catalyst::Authentication::Store::DBIx::Class;
    } or plan 'skip_all' => "A bunch of plugins and modules are required for this test... Look in the source if you really care... $@";
};


use Catalyst::Test 'MyApp';

my $cookie;

my $u = "http://localhost";
my $user = 'anonymous';


# anonymous can access to /
is_allowed("/");

# Must have right admin
is_denied("/admin");
is_denied("/admin/user");
is_denied("/with_role_admin");
is_denied("/with_role_member_and_moderator");
is_denied("/can_create_Page");
is_denied("/can_delete_Comment");


$user = 'admin';
login($user, 'admin');

is_allowed("/admin");
is_allowed("/admin/user");
is_allowed("/with_role_admin");
is_allowed("/with_role_member_and_moderator");
is_allowed("/can_create_Page");
is_allowed("/can_delete_Comment");
is_allowed("/can_recursive_roles");
is_allowed("/logout");


$user = 'joe';
login($user, 'joe');

is_denied("/with_role_admin");
is_allowed("/with_role_member_and_moderator");
is_allowed("/can_create_Page");
is_allowed("/can_delete_Comment");
is_allowed("/can_recursive_roles");
is_allowed("/logout");


$user = 'jack';
login($user, 'jack');

is_denied("/with_role_admin");
is_denied("/with_role_member_and_moderator");
is_denied("/can_create_Page");
is_allowed("/can_delete_Comment");
is_denied("/can_recursive_roles");
is_allowed("/logout");




sub is_denied {
        my $path = shift;
	my ($res,undef) = ctx_request(GET "$u/$path", Cookie => $cookie);
	is($res->header('Location'), '/access_denied', "Access denied $user -> $path ");
}

sub is_allowed {
        my ( $path, $contains ) = @_;
        $path ||= "";
	my ($res,undef) = ctx_request(GET "$u/$path", Cookie => $cookie);
	ok($res->is_success || $res->is_redirect, "$u/$path success");
}


sub login{
  my $login = shift;
  my $pass  = shift;

  my ($res, $c) = ctx_request(POST '/login', [username => $login, password => $pass]);
  $cookie = $res->header('Set-Cookie');
  my ($res2,undef) = ctx_request(GET $res->header('Location'), Cookie => $cookie);
  like($res2->content, qr/Welcome $user/, "Logged as $user");
}

done_testing();
