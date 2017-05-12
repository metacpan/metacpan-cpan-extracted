package Bot::ChatBots::Messenger::WebHook;
use strict;
use warnings;
{ our $VERSION = '0.004'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Role::WebHook';

has no_routes => (
   is      => 'ro',
   default => sub { return 0 },
);

has verify_token => (
   is      => 'ro',
   lazy    => 1,
   default => sub { ouch 500, 'you MUST set verify_token by yourself' },
);

sub BUILD {
   my $self = shift;
   if (!$self->no_routes) {
      $self->install_route;        # the main POST one
      $self->install_get_route;    # the FB back-authentication route
   }
} ## end sub BUILD

sub install_get_route {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   my $r    = $args->{routes} // $self->app->routes;
   my $p    = $args->{path} // $self->path;
   return $r->get(
      $p => sub {
         my $c     = shift;
         my $qp    = $c->req->query_params;
         my $hmode = $qp->param('hub.mode') // '';
         my $hvt   = $qp->param('hub.verify_token') // '';
         if (($hmode eq 'subscribe') && ($hvt eq $self->verify_token)) {
            $log->info('received correct challenge request');
            my $challenge = $qp->param('hub.challenge') // '';
            $c->render(text => $challenge);
         }
         else {
            $log->error('GET request not accepted');
            $c->rendered(403);
         }
         return;
      }
   );
} ## end sub install_get_route

sub normalize_record {
   my ($self, $record) = @_;
   my $update = $record->{update} or ouch 500, 'no update found!';

   $record->{source}{technology} = 'messenger';

   $record->{type}    = 'message';
   $record->{payload} = $record->{update}{message};

   $record->{sender} = $record->{update}{sender};

   my $chan = $record->{channel} = {%{$record->{update}{sender}}};
   $chan->{fqid} = $chan->{id};

   return $record;
} ## end sub normalize_record

sub parse_request {
   my ($self, $req) = @_;

   my $data = $req->json;
   return unless $data->{object} eq 'page';

   local $Data::Dumper::Indent = 1;
   my @updates;
   for my $entry (@{$data->{entry}}) {
      my $page_id    = $entry->{id};
      my $event_time = $entry->{time};

    EVENT:
      for my $event (@{$entry->{messaging}}) {
         if (exists $event->{message}) {
            push @updates, $event;
         }
         else {
            $log->warn('unknown event: ' . Dumper($event));
         }
      } ## end EVENT: for my $event (@{$entry...})
   } ## end for my $entry (@{$data->...})

   return @updates;
} ## end sub parse_request

1;
