#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 5;
use lib 't/lib';
use lib 'lib';
BEGIN {  $ENV{LOGLEVEL} ||= "FATAL" }
BEGIN { require 'djabberd-test.pl' }

use DJabberd::Plugin::Ping;

my $server = Test::DJabberd::Server->new(id => 1);

$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test', policy => 'accept'),
    DJabberd::Plugin::Ping->new(),
    DJabberd::Authen::StaticPassword->new(password => 'test'),
]);

my $client;
    
$client = Test::DJabberd::Client->new(server => $server, name => "test");

$client->login("test");
pass("Client logged in");

my $h = $server->hostname;
$client->send_xml(qq{<iq type="get" id="1001" to="$h">
    <ping xmlns="urn:xmpp:ping" />
</iq>});

my $xml = $client->recv_xml_obj;
bless $xml, 'DJabberd::IQ';
ok($xml->id eq '1001', 'IQ id');
ok($xml->type eq 'result', 'IQ type');
# TODO version ?

$client->send_xml(qq{<iq type="get" id="1002" >
    <ping xmlns="urn:xmpp:ping" />
</iq>});

$xml = $client->recv_xml_obj;
bless $xml, 'DJabberd::IQ';
ok($xml->id eq '1002', 'IQ id');
ok($xml->type eq 'result', 'IQ type');



