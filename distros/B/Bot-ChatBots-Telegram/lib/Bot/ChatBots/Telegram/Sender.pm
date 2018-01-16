package Bot::ChatBots::Telegram::Sender;
use strict;
use warnings;
use Ouch;
use 5.010;
{ our $VERSION = '0.010'; }

use WWW::Telegram::BotAPI ();

use Moo;
use namespace::clean;
with 'Bot::ChatBots::Role::Sender';

has start_loop => (
   is => 'rw',
   default => sub { return 0 },
);

has telegram => (
   is      => 'rw',
   lazy    => 1,
   default => sub {
      my $self = shift;
      my $tg   = WWW::Telegram::BotAPI->new(
         token => $self->token,
         async => 1,
      );
      return $tg;
   }
);

has token => (
   is       => 'ro',
   required => 1,
);

# copied from Bot::ChatBot::Role::UserAgent
sub may_start_loop {
   my $self = shift;
   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   my $start_loop =
     exists($args{start_loop})
     ? $args{start_loop}
     : $self->start_loop;
   Mojo::IOLoop->start if $start_loop && (!Mojo::IOLoop->is_running);
   return $self;
} ## end sub may_start_loop

sub send_message {
   my ($self, $message) = splice @_, 0, 2;
   ouch 500, 'no output to send' unless defined $message;

   my %args = (@_ && ref($_[0])) ? %{$_[0]} : @_;

   # message normalization
   $message =
     ref($message)
     ? {%$message}
     : {text => $message, telegram_method => 'sendMessage'};
   my $method = delete($message->{telegram_method}) // do {
      state $method_for = {
         send        => 'sendMessage',
         sendMessage => 'sendMessage',
      };

      my $name = delete(local $message->{method}) // 'send';
      $method_for->{$name}
        or ouch 500, $self->name . ": unsupported method $name";
   };

   if (($method eq 'sendMessage') && (!exists $message->{chat_id})) {
      if (defined $args{record}) {    # take from $record
         $message->{chat_id} = $args{record}{channel}{id};
      }
      elsif ($self->has_recipient) {
         $message->{chat_id} = $self->recipient;
      }
      else {                          # no more ways to figure it out
         ouch 500, 'no chat identifier for message';
      }
   } ## end if (!exists $message->...)

   my @callback;
   if ($args{callback}) {
      @callback = $args{callback};
   }
   elsif ($self->can('callback')) {
      my $has_callback = $self->can('has_callback') // sub { return 1 };
      @callback = $self->callback if $has_callback->($self);
   }

   my $res = $self->telegram->api_request($method => $message, @callback);

   $self->may_start_loop(%args) if @callback;

   return $res;
} ## end sub send_message

1;
