#!perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use Test::BDD::Cucumber::StepFile;
use Business::OnlinePayment::BitPay::Client;
use Try::Tiny;
use Env;
require Business::OnlinePayment::BitPay::KeyUtils;
require 'features/step_definitions/helpers.pl';

my $pairingCode;
my $client;
my $token;
our $error;
my $pem;
my $uri;

$client = setClient();

Given 'the user pairs with BitPay with a valid pairing code', sub{
    sleep 2;
    my $response = $client->get(path => "tokens");
    my @data = $client->process_response($response);
    for my $mapp (values @data[0]){
        for my $key (keys %$mapp) {
            $token =  %$mapp{$key} if $key eq "merchant";
        }
    }
    my $params = {token => $token, facade => "pos", id => $client->{id}};
    $response = $client->post(path => "tokens", params => $params);
    @data = $client->process_response($response);
    $pairingCode = shift(shift(@data))->{'pairingCode'};
    ok($pairingCode);
};

Then 'the user is paired with BitPay', sub {
    my $params = {pairingCode => $pairingCode, id => $client->{id}};
    my @data = $client->pair_pos_client($pairingCode);
    my $facade = shift(shift(@data))->{'facade'};
    ok($facade eq "pos");
};

Given 'the user requests a client-side pairing', sub{
    sleep 2;
    my @data = $client->pair_client(facade => 'pos');
    $pairingCode = shift(shift(@data))->{'pairingCode'};
};

Then 'they will receive a claim code', sub{
    ok($pairingCode =~ /\w{7}/);
};

Given qr/the user fails to pair with "(.+)"/, sub {
    try {
        $client->pair_pos_client($1);
    } catch {
        $error = $_;
    }
};

Then qr/they will receive an error matching "(.+)"/, sub {
    ok($error =~ /$1/i);
}
