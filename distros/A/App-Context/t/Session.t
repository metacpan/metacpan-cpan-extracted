#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

use strict;

BEGIN {
   use_ok("App");
}

{
    my ($context, $session);
    #$App::DEBUG = 1;

    $context = App->context(
        #session_class => "App::Session::File",
        context_class => "App::Context::HTTP",
        session_class => "App::Session::HTMLHidden",
    );
    $session = $context->session();
    ok(defined $session, "Session constructor ok");
    isa_ok($session, "App::Session", "right class [derived from App::Session]");

    my $pi = 3.1416;
    my $e  = 2.7183;
    $session->set("num", $pi);
    is($session->get("num"), $pi,                           "get what I set ($pi) as num");
    is($session->get("default.num"), $pi,                   "get what I set ($pi) as default.num");
    is($session->get("SessionObject.default.num"), $pi,     "get what I set ($pi) as SessionObject.default.num");
    is($session->get("SessionObject","default","num"), $pi, "get what I set ($pi) as SessionObject(default).num");
    is($session->get("x.num"), undef,                       "get nothing");

    is($session->get("t1num",undef,undef,$pi), $pi,         "get default");
    is($session->get("t1num"), undef,                       "show that default didn't get stored");
    is($session->get("t1num",undef,undef,$pi,1), $pi,       "get and set default");
    is($session->get("t1num"), $pi,                         "show that default did get stored");
    is($session->get("t2.num",undef,undef,$pi), $pi,        "get default as default.num");
    is($session->get("SessionObject.t3.num",undef,undef,$pi), $pi, "get default as SessionObject.t3.num");
    is($session->get("SessionObject","t4","num",$pi), $pi,  "get default as SessionObject(t4).num");

    $session->set("t1num",undef,undef,$e);
    $session->set("t2.num",undef,undef,$e);
    $session->set("SessionObject.t3.num",undef,undef,$e);
    $session->set("SessionObject","t4","num",$e);

    is($session->get("t1num",undef,undef,$pi),        $e,   "set/get default as num with unused default");
    is($session->get("t2.num"),                       $e,   "set/get default as default.num");
    is($session->get("SessionObject.t3.num"),         $e,   "set/get default as SessionObject.t3.num");
    is($session->get("SessionObject","t4","num",$pi), $e,   "set/get default as SessionObject(t4).num with unused default");

    $session->set("Serializer", "main.app.toolbar.calc", "width", 50);
    is($session->get("Serializer.main.app.toolbar.calc.width"), 50, "set/get with dotted service name");
    $session->set("Serializer.main.app.toolbar.calc.width", 40);
    is($session->get("Serializer", "main.app.toolbar.calc", "width"), 40, "set/get with dotted service name (reverse)");

    $session->set("Serializer", "xyz", "{arr}[1][2]", 50);
    is($session->get("Serializer.xyz{arr}[1][2]"), 50, "set/get with compound/deep var");
    $session->set("Serializer.xyz{arr}[1][2]", 40);
    is($session->get("Serializer", "xyz", "{arr}[1][2]"), 40, "set/get with compound/deep var (reverse)");

    $session->set("Serializer", "xyz", "{arr.totals}", 50);
    is($session->get("Serializer.xyz{arr.totals}"), 50, "set/get with dotted var");
    $session->set("Serializer.xyz{arr.totals}", 40);
    is($session->get("Serializer", "xyz", "{arr.totals}"), 40, "set/get with dotted var (reverse)");

    my $session_id = $session->get_session_id();
    ok(defined $session_id, "got a defined session id");

    # dump old Context
    $context = undef;
    App->shutdown();
}

exit 0;

