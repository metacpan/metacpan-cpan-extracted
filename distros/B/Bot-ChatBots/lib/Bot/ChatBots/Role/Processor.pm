package Bot::ChatBots::Role::Processor;
use strict;
use warnings;
{ our $VERSION = '0.012'; }

use Moo::Role;
requires 'process';

sub processor {
   my $self = shift;
   return sub { return $self->process(@_) };
}

1;
