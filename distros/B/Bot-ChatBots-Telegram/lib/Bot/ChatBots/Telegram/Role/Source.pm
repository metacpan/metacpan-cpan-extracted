package Bot::ChatBots::Telegram::Role::Source;
use strict;
use warnings;
{ our $VERSION = '0.014'; }

use Ouch;
use Log::Any;

use Moo::Role;

has token => (
   is => 'ro',
   lazy => 1,
   predicate => 1,
   default => sub { ouch 500, 'token is not defined' }
);

has sender => (
   is      => 'ro',
   lazy    => 1,
   default => sub {    # prefer has-a in this case
      my $self = shift;
      require Bot::ChatBots::Telegram::Sender;
      return Bot::ChatBots::Telegram::Sender->new(token => $self->token);
   },
);

{
   my %data_type_for = (
      message => 'Message',
      edited_message => 'Message',
      channel_post => 'Message',
      edited_channel_post => 'Message',
      inline_query => 'InlineQuery',
      chosen_inline_result => 'ChosenInlineResult',
      callback_query => 'CallbackQuery',
      shipping_query => 'ShippingQuery',
      pre_checkout_query => 'PreCheckoutQuery',
   );

   sub normalize_record {
      my ($self, $record) = @_;

      my $update = $record->{update} or ouch 500, 'no update found!';
      $record->{source}{technology} = 'telegram';
      $record->{source}{token} //= $record->{source}{object_token};

      my ($type) = grep { $_ ne 'update_id' } keys %$update;
      $record->{type} = $type;

      $record->{data_type} = $data_type_for{$type} || 'unknown';

      my $payload = $record->{payload} = $update->{$type};

      $record->{sender} = $payload->{from};

      return $self->_normalize_record_chan($record);
   }
}

sub _normalize_record_chan {
   my ($self, $record) = @_;
   my ($dtype, $payload) = @{$record}{qw< data_type payload >};
   my $chan;
   if ($dtype eq 'Message') {
      $chan = {%{$payload->{chat}}};
   }
   elsif ($dtype eq 'CallbackQuery') {
      if (exists $payload->{message}) {
         $chan = {%{$payload->{message}{chat}}};
      }
      else { # FIXME guessing correctly here?
         $chan = {id => $payload->{chat_instance}};
      }
   }
   if ($chan) {
      $chan->{fqid} = "$chan->{type}/$chan->{id}" if exists $chan->{id};
      $record->{channel} = $chan;
   }

   return $record;
}

1;
