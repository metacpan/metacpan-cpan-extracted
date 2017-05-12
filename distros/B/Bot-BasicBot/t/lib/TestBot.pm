package TestBot;
use warnings;
use strict;
use base qw( Bot::BasicBot );
use Test::More;

sub connected {
  my $self = shift;
  ok(1, "connected");
  is( $self->nick, "basicbot_$$", "right nick" );
}

# ..now wait for the first tick..

sub tick {
  my $self = shift;
  my $channel = [ $self->channels ]->[0];

  ok(1, "tick");
  $self->say( channel => $channel, body => "Hello $$" );

  ok(1, "now use a notice from within tick");
  $self->notice( channel => $channel, body => "This should be a notice ($$)" );

  exit;
}

1;
