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

use Test::More tests => 2;
use Test::NoWarnings;

use App::SpreadRevolutionaryDate;
use App::SpreadRevolutionaryDate::Target::Liberachat::Bot;

{
    no strict 'refs';
    no warnings 'redefine';

    *App::SpreadRevolutionaryDate::Target::Liberachat::Bot::tick = sub {
      my $self = shift;

      $self->{nb_ticks} = 1 unless $self->{nb_ticks};
      if ($nb_ticks == 2) {
        ok(1, 'Liberachat no authentication with fake credentials');
        $self->shutdown('Shutdown overridden tick');
      };
      return 1;
    };

    *App::SpreadRevolutionaryDate::Target::Liberachat::Bot::said = sub {
        my ($self, $message) = @_;

        return if $message->{who} ne 'NickServ';
        ok($message->{who} eq 'NickServ' && $message->{body} !~ /You are now identified for/, 'Liberachat no authentication with fake credentials');
        $self->shutdown('Shutdown overridden said');
    };
}

my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new(\*DATA);

$spread_revolutionary_date->targets->{liberachat}->spread('test');

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

[liberachat]
# See https://libera.chat/guides/registration to register
nickname      = 'NickName'
password      = 'Password'
test_channels = '#TestChannel1'
test_channels = '#TestChannel2'
channels      = '#Channel1'
channels      = '#Channel2'
channels      = '#Channel3'
