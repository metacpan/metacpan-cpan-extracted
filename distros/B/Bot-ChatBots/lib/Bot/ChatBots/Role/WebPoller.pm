package Bot::ChatBots::Role::WebPoller;
use strict;
use warnings;
{ our $VERSION = '0.014'; }

use Ouch;
use IO::Socket::SSL ();
use Mojo::UserAgent;
use Log::Any qw< $log >;
use Try::Tiny;

use Moo::Role;
use namespace::clean;

with 'Bot::ChatBots::Role::Poller';

has ua => (is => 'ro', default => sub { return Mojo::UserAgent->new });
has tx_args => (is => 'ro', required => 1);

sub poll {
   my ($self, $on_data, $args) = @_;
   my $ua = $self->ua;
   my $tx = $ua->build_tx(@{$self->tx_args});
   my $cb = sub {
      my ($ua, $tx) = @_;
      return $on_data->({tx => $tx, ua => $ua});
   };
   return $ua->start($tx, $cb);
}

1;
