package Bot::ChatBots::Telegram::Role::Source;
use strict;
use warnings;
{ our $VERSION = '0.010'; }

use Ouch;
use Log::Any;

use Moo::Role;

has token => (
   is => 'ro',
   lazy => 1,
   predicate => 1,
   default => sub { ouch 500, 'token is not defined' }
);

sub normalize_record {
   my ($self, $record) = @_;

   my $update = $record->{update} or ouch 500, 'no update found!';
   $record->{source}{technology} = 'telegram';
   $record->{source}{token} //= $record->{source}{object_token};

   my ($type) = grep { $_ ne 'update_id' } keys %$update;
   $record->{type} = $type;

   my $payload = $record->{payload} = $update->{$type};

   $record->{sender} = $payload->{from};

   my $chan = $record->{channel} = {%{$payload->{chat}}};
   $chan->{fqid} = "$chan->{type}/$chan->{id}";

   return $record;
}

1;
