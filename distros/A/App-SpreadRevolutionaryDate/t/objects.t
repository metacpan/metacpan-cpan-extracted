#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019 by Gérald Sédrati-Dinet.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    $ENV{PERL_UNICODE} = 'AS';
}
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 9;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;

my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

isa_ok($spread_revolutionary_date->targets->{twitter}, 'App::SpreadRevolutionaryDate::Target::Twitter', 'Twitter class constructor');
isa_ok($spread_revolutionary_date->targets->{twitter}->obj, 'Net::Twitter::Lite::WithAPIv1_1', 'Twitter object');
isa_ok($spread_revolutionary_date->targets->{mastodon}, 'App::SpreadRevolutionaryDate::Target::Mastodon', 'Mastodon class constructor');
isa_ok($spread_revolutionary_date->targets->{mastodon}->obj, 'Mastodon::Client', 'Mastodon object');
isa_ok($spread_revolutionary_date->targets->{freenode}, 'App::SpreadRevolutionaryDate::Target::Freenode', 'Freenode class constructor');
isa_ok($spread_revolutionary_date->targets->{freenode}->obj, 'App::SpreadRevolutionaryDate::Target::Freenode::Bot', 'Freenode object');

eval { $spread_revolutionary_date->targets->{twitter}->obj->verify_credentials };
is($@, '401: Authorization Required', 'Twitter no connection with fake credentials');

eval { $spread_revolutionary_date->targets->{mastodon}->obj->get_account };
like($@, qr/^Could not complete request: 500 Can't connect to Instance/, 'Mastodon no connection with fake credentials');

__DATA__

test

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'

[mastodon]
# Get these values from https://<your mastodon instance>/settings/applications
instance        = 'Instance'
client_id       = 'ClientId'
client_secret   = 'ClientSecret'
access_token    = 'AccessToken'

[freenode]
# See https://freenode.net/kb/answer/registration to register
nickname      = 'NickName'
password      = 'Password'
test_channels = '#TestChannel1'
test_channels = '#TestChannel2'
channels      = '#Channel1'
channels      = '#Channel2'
channels      = '#Channel3'
