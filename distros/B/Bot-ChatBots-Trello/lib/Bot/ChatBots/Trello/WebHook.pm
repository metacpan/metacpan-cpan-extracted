package Bot::ChatBots::Trello::WebHook;
use strict;
use warnings;
{ our $VERSION = '0.002'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;
use Mojo::URL;
use Mojo::Path;

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Role::WebHook';

sub BUILD {
   my $self = shift;

   # this installs the real webhook route
   $self->install_route;

   # this makes Trello happy upon webhook registration
   $self->install_route(
      method  => 'get',
      handler => sub { shift->render(text => 'OK') }
   );
} ## end sub BUILD

sub normalize_record {
   my ($self, $record) = @_;

   my $update = $record->{update} or ouch 500, 'no update found';
   $record->{source}{technology} = 'trello';
   $record->{source}{token} //= $record->{source}{object_token};

   $record->{payload} = $update;
   $record->{sender}  = 'unknown';

   return $self->_normalize_action($record);
} ## end sub normalize_record

sub parse_request { return $_[1]->json }

# paranoid: ensure we return a "200" with some response
around process => sub {
   my ($orig, $self, $record) = @_;
   my $outcome = $orig->($self, $record);
   $record->{source}{refs}{controller}->render(text => 'OK')
     unless $record->{source}{flags}{rendered}++;
   return $outcome;
};

sub _normalize_action {
   my ($self, $record) = @_;
   my $A = $record->{payload}{action};
   $record->{action} = \my %action;
   my $type = $action{type} = $A->{type};
   $action{subtype} = $A->{display}{translationKey};
   if (my ($item_type) = $type =~ m{(Card | List | Board)$}mxs) {
      $item_type = lc $item_type;
      $action{item} = {%{$A->{data}{$item_type}}, type => $item_type};
   }
   return $record;
} ## end sub _normalize_action

1;
