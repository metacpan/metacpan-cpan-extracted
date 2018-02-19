package Bot::ChatBots::Auth;
use strict;
use warnings;
{ our $VERSION = '0.008'; }

use Log::Any qw< $log >;

use Moo;
with 'Bot::ChatBots::Role::Processor';

has channels => (is => 'rw', default => sub { return {} });
has name => (is => 'ro', default => sub { return ref($_[0]) || $_[0] });
has users => (is => 'rw', default => sub { return {} });

sub process {
   my ($self, $record) = @_;
   my $name = $self->name;

   my $users = $self->users;
   if (keys %$users) {
      my $id = $record->{sender}{id} // do {
         $log->info("$name: sender id is not present");
         return;
      };
      if (exists $users->{blacklist}{$id}) {
         $log->info("$name: sender '$id' is blacklisted, blocking");
         return;
      }
      if (scalar(keys %{$users->{whitelist}})
         && (!exists($users->{whitelist}{$id})))
      {
         $log->info("$name: sender '$id' not whitelisted, blocking");
         return;
      } ## end if (scalar(keys %{$users...}))
   } ## end if (keys %$users)

   my $channels = $self->channels;
   if (keys %$channels) {
      my $id = $record->{channel}{fqid} // $record->{channel}{id} // do {
         $log->info("$name: chat id is not present");
         return;
      };
      if (exists $channels->{blacklist}{$id}) {
         $log->info("$name: chat '$id' is blacklisted, blocking");
         return;
      }
      if (scalar(keys %{$channels->{whitelist}})
         && (!exists($channels->{whitelist}{$id})))
      {
         $log->info("$name: chat '$id' not whitelisted, blocking");
         return;
      } ## end if (scalar(keys %{$channels...}))
   } ## end if (keys %$channels)

   $log->info("$name: no reason to block, allowing");
   return $record;
} ## end sub process

42;
