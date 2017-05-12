package Bot::ChatBots::Whatever::Sender;
use strict;
use Moo;
with 'Bot::ChatBots::Role::Sender';

has _sent => (
   is      => 'rw',
   default => sub {return []},
);

sub reset { shift->_sent([]) }

sub send_message {
   my ($self, $message) = @_;
   push @{$self->_sent}, $message;
   return $message;
}

sub sent { return @{shift->_sent} }

1;
