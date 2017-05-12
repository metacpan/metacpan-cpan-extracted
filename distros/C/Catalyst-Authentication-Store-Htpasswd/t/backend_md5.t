#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use File::Temp qw/tempfile/;

my $m; BEGIN { use_ok($m = "Catalyst::Authentication::Store::Htpasswd") }

(undef, my $tmp) = tempfile();

my $passwd = Authen::Htpasswd->new($tmp, { encrypt_hash => 'md5' });

$passwd->add_user("user", "s3cr3t");

can_ok($m, "new");
isa_ok(my $o = $m->new( { file => $passwd } ), $m);

can_ok($m, "file");
isa_ok( $o->file, "Authen::Htpasswd");

can_ok( $m, "user_supports");
ok( $m->user_supports(qw/password self_check/), "user_supports self check" );

can_ok($m, "find_user");
isa_ok( my $u = $o->find_user({username  => "user"}), "Catalyst::Authentication::Store::Htpasswd::User");
isa_ok( $u, "Catalyst::Authentication::User");

can_ok( $u, "check_password");
ok( $u->check_password( "s3cr3t" ), "password is s3cr3t");



