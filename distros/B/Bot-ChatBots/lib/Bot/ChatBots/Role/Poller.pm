package Bot::ChatBots::Role::Poller;
use strict;
use warnings;
{ our $VERSION = '0.014'; }

use Ouch;
use Mojo::IOLoop ();
use Log::Any qw< $log >;
use Try::Tiny;

use Moo::Role;
use namespace::clean;

with 'Bot::ChatBots::Role::Source'; # requires normalize_record
requires qw< parse_response poll process_updates >;

has interval => (is => 'ro', required => 1);
has args => (is => 'ro', default => sub { return [] });

sub BUILD {
   my $self = shift;
   $self->schedule($self->interval, @{$self->args});
   return $self; # ignored
}

sub poller {
   my $self = shift;
   my $args = (@_ && ref($_[0]) ? $_[0] : {@_});

   # flag variable to avoid instances treading on each other
   my $is_busy;

   # callback where the poll function should push received data
   my $on_data = sub {
      my ($data) = @_;

      my @updates;
      try {
         @updates = $self->parse_response($data);
      }
      catch {
         $log->error(bleep $_);
         die $_ if $self->should_rethrow($args);
      };

      my @retval = $self->process_updates(
         refs => {
            data => $data,
         },
         source_pairs => { },
         updates => \@updates,
         %$args, # may override it all!
      );

      $self->processed(@retval) if $self->can('processed');
      $is_busy = 0;
   };

   # this is what should be scheduled
   return sub {
      return if $is_busy;
      $is_busy = 1; # $on_data below will reset $is_busy when ready
      $self->poll($on_data, $args);
   };
}

sub schedule {
   my ($self, $interval, @rest) = @_;
   my $poller = $self->poller(@rest);
   Mojo::IOLoop->timer(0 => $poller);
   Mojo::IOLoop->recurring($interval, $poller);
   return $self;
}

1;
