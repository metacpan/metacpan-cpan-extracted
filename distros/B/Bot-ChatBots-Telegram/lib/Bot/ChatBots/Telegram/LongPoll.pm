package Bot::ChatBots::Telegram::LongPoll;
use strict;
use warnings;
{ our $VERSION = '0.012'; }

use Ouch;
use Try::Tiny;
use Log::Any qw< $log >;
use Mojo::IOLoop ();
use IO::Socket::SSL ();    # just to be sure to complain loudly in case
use List::Util qw< max >;

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Telegram::Role::Source';    # normalize_record, token
with 'Bot::ChatBots::Role::Source';              # processor, typename

has connect_timeout => (
   is      => 'ro',
   default => sub { return 20 },
);

has interval => (
   is      => 'ro',
   default => sub { return 0.1 },
);

has max_redirects => (
   is => 'ro',
   default => sub { return 5 },
);

has _start => (
   is       => 'ro',
   default  => sub { return 1 },
   init_arg => 'start',
);

has update_timeout => (
   is      => 'ro',
   default => sub { return 300 },
);

sub BUILD {
   my $self = shift;
   $self->start if $self->_start;
}

sub class_custom_pairs {
   my $self = shift;
   return (token => $self->token);
}

sub parse_response {
   my ($self, $res, $threshold_id) = @_;
   my $data = $res->json // {};
   if (!$data->{ok}) { # boolean flag from Telegram API
      $log->error('getUpdates error: ' .
         $data->{description} // 'unknown error');
      return;
   }

   return grep { $_->{update_id} >= $threshold_id } @{$data->{result}//[]};
}

sub poller {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $update_timeout = $self->update_timeout;
   my %query = (
      offset => 0,
      telegram_method => 'getUpdates',
      timeout => $update_timeout,
   );

   my $sender = $self->sender;
   $sender->telegram->agent->connect_timeout($self->connect_timeout)
     ->inactivity_timeout($update_timeout + 5)
     ->max_redirects($self->max_redirects);

   # this flag tells us whether we're in a call already, avoiding
   # duplicates. It is set before sending a request, and reset when the
   # response is managed
   my $is_busy;

   my $on_data = sub {
      my ($ua, $tx) = @_;

      my @updates;
      try {
         @updates = $self->parse_response($tx->res, $query{offset});
      }
      catch {
         $log->error(bleep $_);
         die $_ if $self->should_rethrow($args);
      };

      my @retval = $self->process_updates(
         refs => {
            sender => $sender,
            tx     => $tx,
            ua     => $ua,
         },
         source_pairs => {
            query => \%query,
         },
         updates => \@updates,
         %$args, # may override it all!
      );

      for my $item (@retval) {
         next unless defined $item;
         defined(my $record = $item->{record})            or next;
         defined(my $outcome = $item->{outcome})          or next;
         defined(my $message = $outcome->{send_response}) or next;
         $sender->send_message($message, record => $record);
      }

      # if we get here, somehow me managed to get past this call... Get
      # ready for the next one. Just to be on the safe side, we will
      # advance $query{offset} anyway
      $query{offset} = 1 + max map { $_->{update_id} } @updates
         if @updates;
      $is_busy = 0;
   };

   return sub {
      return if $is_busy;
      $is_busy = 1; # $on_data below will reset $is_busy when ready
      $sender->send_message(\%query, callback => $on_data);
   };
} ## end sub callback

around process => sub {
   my ($orig, $self, $record) = @_;
   my $outcome = $orig->($self, $record);
   $record->{source}{query}{offset} = $record->{update}{update_id} + 1;
   return $outcome;
};

sub start {
   my $self = shift;
   Mojo::IOLoop->recurring($self->interval, $self->poller(@_));
   Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
   return $self;
}

1;
