#!/usr/bin/perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

BEGIN {
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
}
binmode(DATA, ":encoding(UTF-8)");

use Test::More tests => 14;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;

my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

isa_ok($spread_revolutionary_date->targets->{bluesky}, 'App::SpreadRevolutionaryDate::Target::Bluesky', 'Bluesky class constructor');
isa_ok($spread_revolutionary_date->targets->{bluesky}->obj, 'App::SpreadRevolutionaryDate::BlueskyLite', 'Bluesky object');
isa_ok($spread_revolutionary_date->targets->{twitter}, 'App::SpreadRevolutionaryDate::Target::Twitter', 'Twitter class constructor');
isa_ok($spread_revolutionary_date->targets->{twitter}->obj, 'Twitter::API__WITH__Twitter::API::Trait::ApiMethods', 'Twitter object');
isa_ok($spread_revolutionary_date->targets->{mastodon}, 'App::SpreadRevolutionaryDate::Target::Mastodon', 'Mastodon class constructor');
isa_ok($spread_revolutionary_date->targets->{mastodon}->obj, 'Mastodon::Client', 'Mastodon object');
isa_ok($spread_revolutionary_date->targets->{freenode}, 'App::SpreadRevolutionaryDate::Target::Freenode', 'Freenode class constructor');
isa_ok($spread_revolutionary_date->targets->{freenode}->obj, 'App::SpreadRevolutionaryDate::Target::Freenode::Bot', 'Freenode object');
isa_ok($spread_revolutionary_date->targets->{liberachat}, 'App::SpreadRevolutionaryDate::Target::Liberachat', 'Liberachat class constructor');
isa_ok($spread_revolutionary_date->targets->{liberachat}->obj, 'App::SpreadRevolutionaryDate::Target::Liberachat::Bot', 'Liberachat object');

ok(!$spread_revolutionary_date->targets->{bluesky}->obj->{did}, 'Bluesky no connection with fake credentials');

eval { $spread_revolutionary_date->targets->{twitter}->obj->verify_credentials };
like($@, qr/^(?:Invalid or expired token|599 Internal Exception)/, 'Twitter no connection with fake credentials');

eval { $spread_revolutionary_date->targets->{mastodon}->obj->get_account };
like($@, qr/^Could not complete request: (?:500 Can't connect to Instance|599 Internal Exception|404 Not Found)/, 'Mastodon no connection with fake credentials');

__DATA__

test

[bluesky]
# Get these values from https://bsky.app/
identifier = 'Identifier'
password   = 'Password'

[twitter]
# Get these values from https://apps.twitter.com/
consumer_key        = 'ConsumerKey'
consumer_secret     = 'ConsumerSecret'
access_token        = 'AccessToken'
access_token_secret = 'AccessTokenSecret'
api                 = 1

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

[liberachat]
# See https://libera.chat/guides/registration to register
nickname      = 'NickName'
password      = 'Password'
test_channels = '#TestChannel1'
test_channels = '#TestChannel2'
channels      = '#Channel1'
channels      = '#Channel2'
channels      = '#Channel3'
