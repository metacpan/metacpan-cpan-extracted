#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
use lib 't/lib';
use lib 'lib';
BEGIN {  $ENV{LOGLEVEL} ||= "FATAL" }
BEGIN { require 'djabberd-test.pl' }

use DJabberd::Plugin::JabberIqVersion;

my $server = Test::DJabberd::Server->new(id => 1);

$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test', policy => 'accept'),
    DJabberd::Plugin::JabberIqVersion->new(name => 'Test name'),
    DJabberd::Authen::StaticPassword->new(password => 'test'),
]);

my $client;
    
$client = Test::DJabberd::Client->new(server => $server, name => "test");

$client->login("test");
pass("Client logged in");

my $h = $server->hostname;
$client->send_xml(qq{<iq type="get" id="1001" to="$h">
    <query xmlns="jabber:iq:version" />
</iq>});

my $xml = $client->recv_xml_obj;
bless $xml, 'DJabberd::IQ';
ok($xml->id eq '1001', 'IQ id');
ok($xml->type eq 'result', 'IQ type');
# verifier que name est la et == djabberd
ok($xml->signature eq "result-{jabber:iq:version}query", "Signature" );
# TODO more robust ( ie name is maybe not the first element ) 
ok($xml->first_element->first_element->element_name eq 'name', 'Name element');
ok($xml->first_element->first_element->first_child eq 'Test name', 'Name element value');
# TODO version ?




