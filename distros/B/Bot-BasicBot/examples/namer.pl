=head1 NAME

namer - read out url titles in the channel

=cut

#!/usr/bin/perl
package Bot;
use base qw(Bot::BasicBot);
use warnings;
use strict;
use URI::Title qw( title );
use URI::Find::Simple qw( list_uris );

sub said {
  my $self = shift;
  my $message = shift;
  my $body = $message->{body};
  return unless my @urls = list_uris($message->{body});
  $self->reply($message, title($_)) for (@urls);
}

Bot->new(
  server => "irc.perl.org",
  channels => [ '#jerakeen' ],
  nick => 'namer',
)->run();

