#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More tests => 5;
use Test::Exception;
use Dancer::Test;
use Dancer::Session::CHI;
use Dancer::Plugin::Cache::CHI;

throws_ok(
    sub { Dancer::Session::CHI->create },
    qr/CHI session options not found/,
    "CHI session without any options throws expection"
);

Dancer::set( session_CHI => { driver => "Memory", datastore => \ my %hash } );
my $class = "Dancer::Session::CHI";
my $session;
lives_ok(
    sub { $session = $class->create },
    "CHI session without plugin created"
);
can_ok $session, qw/init create retrieve flush destroy id/;
isa_ok $session, $class, "&create without plugin yields session engine that";

my $sess_id = $session->id;
ok $sess_id, "&create without plugin yields valid session ID ($sess_id)";
