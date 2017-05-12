#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

use Catalyst::Plugin::Session;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session::State::Cookie" ) }

my $cookie_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
my $cookie = $cookie_meta->name->new;
$cookie_meta->add_method( value => sub { "the session id" } );

my $req_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
my %req_cookies;
$req_meta->add_method( cookies => sub { \%req_cookies } );
my $req = $req_meta->name->new;

my $res_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
my %res_cookies;
my $cookies_called = 0;
$res_meta->add_method( cookies => sub { $cookies_called++; \%res_cookies });
my $res = $res_meta->name->new;

my $cxt_meta = Class::MOP::Class->create_anon_class(
    superclasses => [qw/
        Catalyst::Plugin::Session
        Catalyst::Plugin::Session::State::Cookie
        Moose::Object
    /],
);

my $config = {};
$cxt_meta->add_method( config   => sub { $config });
$cxt_meta->add_method( request  => sub { $req });
$cxt_meta->add_method( response => sub { $res });
$cxt_meta->add_method( session  => sub { { } } );
$cxt_meta->add_method( session_expires => sub { 123 });
$cxt_meta->add_method("debug" => sub { 0 });
my $sessionid;
$cxt_meta->add_method( sessionid => sub { shift; $sessionid = shift if @_; $sessionid } );

can_ok( $m, "setup_session" );

my $cxt = $cxt_meta->name->new;
$cxt->setup_session;

like( $config->{'Plugin::Session'}{cookie_name},
    qr/_session$/, "default cookie name is set" );

$config->{'Plugin::Session'}{cookie_name} = "session";

can_ok( $m, "get_session_id" );

ok( !$cxt->get_session_id, "no session id yet");

$cxt = $cxt_meta->name->new;

%req_cookies = ( session => $cookie );

is( $cxt->get_session_id, "the session id", "session ID was restored from cookie" );

$cxt_meta->name->new;
%res_cookies = ();

can_ok( $m, "set_session_id" );
$cxt->set_session_id("moose");

ok( $cookies_called, "created a cookie on set" );
$cookies_called = 0;

$cxt_meta->name->new;
%res_cookies = ();

$cxt->set_session_id($sessionid);

ok( $cookies_called, "response cookie was set when sessionid changed" );
is_deeply(
    \%res_cookies,
    { session => { value => $sessionid, httponly => 1, expires => 123 } },
    "cookie was set correctly"
);

$cxt_meta->name->new;

can_ok( $m, "cookie_is_rejecting" );

%req_cookies = ( path => '/foo' );
my $path = '';
$req_meta->add_method( path => sub { $path } );
ok( $cxt->cookie_is_rejecting(\%req_cookies), "cookie is rejecting" );
$path = 'foo/bar';
ok( !$cxt->cookie_is_rejecting(\%req_cookies), "cookie is not rejecting" );

