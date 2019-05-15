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

use Test::More;
use File::HomeDir;

unless(   -f File::HomeDir->my_home . '/.config/spread-revolutionary-date/spread-revolutionary-date.conf'
       || -f File::HomeDir->my_home . '/.spread-revolutionary-date.conf') {
  plan skip_all => 'No user config file found';
  } else {
  plan tests => 3;
}

use App::SpreadRevolutionaryDate;

{
  package TestWatcherBot;
  use parent 'Bot::BasicBot';
  use Test::More;

  my %channels_said;
  my $nb_ticks = 0;

  sub log {
    # do nothing!
  }

  sub connected {
    my $self = shift;

    foreach my $channel ($self->channels) {
      $channels_said{$channel} = 0;
    }
  }

  sub said {
    my ($self, $message) = @_;

    return if $message->{who} eq 'freenode-connect';

    if ($message->{who} eq 'RevolutionaryBot') {
      like($message->{body}, qr/^Nous sommes le.*, il est/, 'Spread to Freenode for channel ' . $message->{channel});
      $channels_said{$message->{channel}}++;
    }

    if (scalar(grep { $channels_said{$_} } keys %channels_said) == scalar($self->channels)) {
      ok(1, "Spread to all Freenode channels");
      $self->shutdown;
    }

    return;
  }

  sub tick {
    my $self = shift;

    $nb_ticks++;
    if ($nb_ticks > 5) {
      ok(0, "Spread only to " . scalar(grep { $channels_said{$_} } keys %channels_said) . "/" . scalar($self->channels) . " Freenode channels");
      $self->shutdown if ($nb_ticks > 3);
    }
    return 5;
  }
}

package main;
@ARGV = ('--test', '--freenode');
my $spread_revolutionary_date = App::SpreadRevolutionaryDate->new;

my $port = 6667;
my $ssl = 0;
# Switch to SSL if module POE::Component::SSLify is available
if (eval { require POE::Component::SSLify; 1 }) {
  $port = 6697;
  $ssl = 1;
}
my $channels = $spread_revolutionary_date->config->freenode_test_channels;
my $watcher_bot = TestWatcherBot->new(
  server   => 'irc.freenode.net',
  port     => $port,
  nick     => 'BotWatcher',
  name     => 'Revolutionary Calendar bot watcher',
  useipv6  => 1,
  ssl      => $ssl,
  charset  => 'utf-8',
  channels => $channels,
  no_run   => 1,
)->run();

$spread_revolutionary_date->spread();
