package Bot::ChatBots::Role::Sender;
use strict;
use warnings;
{ our $VERSION = '0.008'; }

use Moo::Role;
with 'Bot::ChatBots::Role::Processor';
requires 'send_message';

has recipient => (
   is        => 'rw',
   lazy      => 1,
   predicate => 1,
   clearer   => 1,
);

sub process {
   my ($self, $record) = @_;

   $record->{sent_message} = $self->send_message($record->{send_message})
     if (ref($record) eq 'HASH') && exists($record->{send_message});

   return $record;    # pass-through anyway
} ## end sub process

1;
