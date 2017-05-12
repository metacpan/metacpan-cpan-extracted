#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;
use lib 't/lib';
use lib 'lib';
BEGIN {  $ENV{LOGLEVEL} ||= "FATAL" }
BEGIN { require 'djabberd-test.pl' }

use DJabberd::Authen::UserLimit;

my $server = Test::DJabberd::Server->new(id => 1);

$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Authen::UserLimit->new(userlimit => 2),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test1 test2 test3', policy => 'accept'),
    Test::DJabberd::Authen::StaticPasswordOverloaded->new(password => 'test'),
]);

my ($client1,$client2,$client3);
    
$client1 = Test::DJabberd::Client->new(server => $server, name => "test1");
$client2 = Test::DJabberd::Client->new(server => $server, name => "test2");
$client3 = Test::DJabberd::Client->new(server => $server, name => "test3");

$client1->login("test");
pass("Client logged in");

$client2->login("test");
pass("Client logged in");
eval {
    $client3->login("test");
};
like($@, qr/bad password/);

eval {
    $server = Test::DJabberd::Server->new(id => 2);
    $server->start([
        DJabberd::Authen::UserLimit->new(userlimit => 'invalid value'),
    ]);
};
like($@, qr/Not a number/);


