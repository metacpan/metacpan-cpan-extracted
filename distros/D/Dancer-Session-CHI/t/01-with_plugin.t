#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More tests => 5;
use Test::Exception;
use Dancer::Test;
use Dancer::Session::CHI;

Dancer::set( session_CHI => { use_plugin => 1 } );

my $class = "Dancer::Session::CHI";
throws_ok(
    sub { $class->create },
    qr/CHI plugin requested but not loaded/,
    "Requesting CHI plugin without it being loaded throws expection" );

Dancer::set(
    plugins => {
        "Cache::CHI" => { driver => "Memory", datastore => \ my %hash }
    }
);
Dancer::set( session_CHI => { use_plugin => 1 } );
Dancer::ModuleLoader->load("Dancer::Plugin::Cache::CHI");

my $session;
lives_ok { $session = $class->create } "CHI session with plugin created";
can_ok $session, qw(init create retrieve flush destroy id);
isa_ok $session, $class, "&create with plugin yields session engine that";

my $session_id = $session->id;
ok $session_id, "&create with plugin yields valid session ID ($session_id)";
