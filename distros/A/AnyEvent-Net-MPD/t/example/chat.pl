#!/usr/bin/env perl

use strict;
use warnings;

use PerlX::Maybe;
use AnyEvent::Net::MPD;
use AnyEvent;

my %accounts = (
  alice => AnyEvent::Net::MPD->new(
    maybe host => $ARGV[0],
  )->connect,
  bob => AnyEvent::Net::MPD->new(
    maybe host => $ARGV[0],
  )->connect,
);

# Accounts have a channel of their own that they send messages to
# Other accounts can follow them by subscribing to that channel

# Accounts subscribe to their own channel because sending a message to a
# channel without subscribers is an error.
foreach my $name (keys %accounts) {
  my @commands = map { [ subscribe => $_ ] } keys %accounts;
  $accounts{$name}->send( \@commands )->recv;
}

# Check for messages every X seconds
my $interval = 1;

# Check for messages in channels this account is subscribed to
my $timer = AnyEvent->timer(
  after => 1,
  interval => $interval,
  cb => sub {
    # We check for messages for all accounts
    foreach my $name (keys %accounts) {
      $accounts{$name}->send( 'read_messages', sub {
        # The message payload is an array of hashes. Each has the name of the
        # channel (= the sender) and an arrayref with the unseen messages
        foreach my $channel (@{shift->recv}) {
          # Print who said who, and reply. We don't want to be rude!
          my ($sender, $messages) = ($channel->{channel}, $channel->{message});

          # Ignore one's own messages
          next if $sender eq $name;

          foreach my $message (@{$messages}) {
            print "$sender says: $message\n";
            $accounts{$name}->send(
              send_message => $name, qq{"I hear you, $sender!"}
            );
          }
        }
      });
    };
  },
);

# Send the first message
$accounts{alice}->send( send_message => 'alice', '"Testing..."' );

AnyEvent->condvar->recv;
