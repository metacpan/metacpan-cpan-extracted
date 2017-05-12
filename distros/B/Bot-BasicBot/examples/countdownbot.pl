=head1 NAME

countdownbot - a bot that will announce the time till an event

=head1 DESCRIPTION

This bot is incredibly annoying. Give it a date, and it'll periodically
announce how long until that date. I wrote this to annoy Arthur.

=cut

#!/usr/bin/perl
use warnings;
use strict;

# Create and run the bot

Bot->new(
  channels => [ '#2lmc' ],
  nick => 'countdownbot',
  server => 'irc.london.pm.org',
  date => 'Tue Jan  6 17:00:00 2004', # apple keynote Jan 2004
)->run;



# Here's the definition of the bot
package Bot;
use base qw(Bot::BasicBot);

use Date::Parse qw(str2time);
use Time::Duration;

# Called 5 seconds after bot startup, and then called again 'x' seconds
# later, where 'x' is whatever the function returns.
sub tick {
  my $self = shift;

  # How long till the event?
  my $secs = Date::Parse::str2time($self->{date}) - time;

  # What will we say?
  my $body = ($secs > 0) ? from_now($secs) : "Why are you still here?";

  # Say this thing in all our channels.
  $self->say( channel => $_, body => $body )
    for (@{$self->{channels}});

  # Now, depending on how long is left, wait a different amount of
  # time.
  if      ($secs > 60 * 30) {
    return 60 * 10
  } elsif ( $secs > 60 * 10 ) {
    return 60 * 5
  } elsif ( $secs > 60 ) {
    return 60
  } elsif ( $secs > 10 ) {
    return 10
  } elsif ( $secs > 0 ) {
    return 1
  } else {
    exit; # done.
  }
}

