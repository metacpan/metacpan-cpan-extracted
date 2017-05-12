#!/usr/bin/perl

=head1 NAME

tango - slap people

=head1 USAGE

  ./tango <#channel> [<nick>]
  
Slaps someone in #channel. An option nick is the person to slap, otherwise
it'll slap leon.

Note that the server is hardcoded.

=cut

package Bot;
use base qw(Bot::BasicBot);
use warnings;
use strict;

my $ticked = 0;

sub tick {
  my $self = shift;
  exit if $ticked;
  $self->emote( { channel => ( $self->channels )[0], body => "slaps $self->{slapee}" } );
  $ticked = 1;
  return 1;
}
  
package main;

chomp(my $channel = shift);
die "no channel" unless $channel;

chomp(my $slapee = shift || "acme");

Bot->new(
  server => "london.irc.perl.org",
  channels => [ $channel ],
  nick => 'tango',
  slapee => $slapee,
)->run();

