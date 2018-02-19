package WH;
use strict;

use Moo;
with 'Bot::ChatBots::Role::WebHook';

# requires 'normalize_record';
# requires 'pack_source';
# requires 'parse_request';
# requires 'process';

has _processed => (
   is      => 'rw',
   default => sub { return [] },
);
sub processed { return @{shift->_processed} }
sub reset     { shift->_processed([]) }

sub normalize_record { return $_[1] }

sub parse_request {
   my $update = $_[1]->json or return;
   return $update;
}

sub process_updates {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   push @{$self->_processed}, $args;
   if (  exists($args->{updates})
      && (scalar @{$args->{updates}} > 0)
      && exists($args->{updates}[0]{answer}))
   {
      $args->{refs}{controller}->render(text => 'All OK!');
   } ## end if (exists($args->{updates...}))
   return $args;
} ## end sub process_updates

1;
