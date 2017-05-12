#!/usr/bin/perl
use strict;
use warnings;
# 19 per backend
use Test::More tests => 57;
use File::Temp qw/tempdir tempfile/;
use lib 't/lib';
use lib 'lib';
BEGIN {  $ENV{LOGLEVEL} ||= "FATAL" }
BEGIN { require 'djabberd-test.pl' }

use_ok('DJabberd::Plugin::PrivateStorage::InMemoryOnly');
use_ok('DJabberd::Plugin::PrivateStorage::SpoolDirectory');
use_ok('DJabberd::Plugin::PrivateStorage::DBI');

# TODO label for each message
sub test_server($) {
    my ($server) = @_;
    my $client;

    $client = Test::DJabberd::Client->new(server => $server, name => "test");

    $client->login("test");

    #test d'écriture
    # de lecture
    $client->send_xml(qq{<iq type="set" id="1001">
        <query xmlns="jabber:iq:private">
        <test xmlns="djabberd:test">
        <defaultnick>Hamlet</defaultnick>
        </test>
        </query>
        </iq>});

    my $xml = $client->recv_xml_obj;
    bless $xml, 'DJabberd::IQ';
    ok($xml->id eq '1001');
    ok($xml->type eq 'result');

    $client->send_xml(qq{<iq type="get" id="1002">
        <query xmlns="jabber:iq:private">
        <test xmlns="djabberd:test"/>
        </query>
        </iq>});

    $xml = $client->recv_xml_obj;
    bless $xml, 'DJabberd::IQ';
    ok($xml->id eq '1002', "ID");
    ok($xml->first_element->inner_ns eq "jabber:iq:private", "Namespace");
    ok($xml->signature eq "result-{jabber:iq:private}query", "Signature" );
    ok($xml->first_element->first_element->inner_ns eq 'djabberd:test', "Inner namespace");
    ok($xml->first_element->first_element->element_name eq 'test', "Element name");
    ok($xml->first_element->first_element->first_element->element_name eq 'defaultnick');
    ok($xml->first_element->first_element->first_element->first_child eq 'Hamlet', "Inner data");

    # send a new one
    $client->send_xml(qq{<iq type="set" id="1003">
        <query xmlns="jabber:iq:private">
        <test xmlns="djabberd:test">
        <defaultnick>Romeo</defaultnick>
        </test>
        </query>
        </iq>});

    $xml = $client->recv_xml_obj;
    bless $xml, 'DJabberd::IQ';
    ok($xml->id eq '1003');
    ok($xml->type eq 'result');

    $client->send_xml(qq{<iq type="get" id="1004">
        <query xmlns="jabber:iq:private">
        <test xmlns="djabberd:test"/>
        </query>
        </iq>});

    $xml = $client->recv_xml_obj;
    bless $xml, 'DJabberd::IQ';
    ok($xml->id eq '1004', "ID update");
    ok($xml->first_element->inner_ns eq "jabber:iq:private", "Namespace update");
    ok($xml->signature eq "result-{jabber:iq:private}query", "Signature update" );
    ok($xml->first_element->first_element->inner_ns eq 'djabberd:test', "Inner namespace update");
    ok($xml->first_element->first_element->element_name eq 'test', "Element name update");
    ok($xml->first_element->first_element->first_element->element_name eq 'defaultnick');
    ok($xml->first_element->first_element->first_element->first_child eq 'Romeo', "Inner data update");

}


my $server = Test::DJabberd::Server->new(id => 1);

$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Plugin::PrivateStorage::InMemoryOnly->new(),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test', policy => 'accept'),
    DJabberd::Authen::StaticPassword->new(password => 'test'),
]);

test_server($server);
my  $tempdir = tempdir( '/tmp/djabberd_test_XXXXXX' );
$server = Test::DJabberd::Server->new(id => 2);

$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Plugin::PrivateStorage::SpoolDirectory->new(directory => $tempdir),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test', policy => 'accept'),
    DJabberd::Authen::StaticPassword->new(password => 'test'),
]);

test_server($server);

$server = Test::DJabberd::Server->new(id => 3);

my (undef, $tempfile) = tempfile();
$server->start([
    DJabberd::RosterStorage::InMemoryOnly->new(),
    DJabberd::Plugin::PrivateStorage::DBI->new(datasource => "SQLite:dbname=$tempfile"),
    DJabberd::Authen::AllowedUsers->new(allowedusers => 'test', policy => 'accept'),
    DJabberd::Authen::StaticPassword->new(password => 'test'),
]);

test_server($server);

