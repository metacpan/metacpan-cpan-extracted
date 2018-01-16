package Bot::ChatBots::Telegram::WebHook;
use strict;
use warnings;
{ our $VERSION = '0.010'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;
use Mojo::URL;
use Mojo::Path;

use Moo;
use namespace::clean;

with 'Bot::ChatBots::Telegram::Role::Source';    # has normalize_record
with 'Bot::ChatBots::Role::WebHook';

has auto_register => (is => 'ro', default => 0, init_arg => 'register');
has auto_unregister => (is => 'rw', default => 0, init_arg => 'unregister');
has certificate => (is => 'rw', default => undef);

sub BUILD {
   my $self = shift;
   $self->install_route;
   $self->register if $self->auto_register;
}

sub DEMOLISH {
   my $self = shift;
   $self->unregister if $self->auto_unregister;
}

sub parse_request {
   my ($self, $req) = @_;
   return $req->json;
}

around process => sub {
   my ($orig, $self, $record) = @_;
   my $outcome = $orig->($self, $record);

   # $record and $outcome might be the same, but the flag is
   # namely supported in $record
   if (  (ref($outcome) eq 'HASH')
      && exists($outcome->{send_response})
      && (!$record->{source}{flags}{rendered}))
   {
      my $message = $outcome->{sent_response} = {
         method  => 'sendMessage',
         chat_id => $record->{channel}{id},

         ref($outcome->{send_response}) eq 'HASH'
         ? (%{$outcome->{send_response}})    # shallow copy suffices
         : (text => $outcome->{send_response})
      };
      $record->{source}{refs}{controller}->render(json => $message);
      $record->{source}{flags}{rendered} = 1;
   } ## end if ((ref($outcome) eq ...))

   return $outcome;
};

sub register {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $app   = $args->{app}   // $self->app;
   my $token = $args->{token} // $self->token;

   my $wh_url;
   if (my $url = $args->{url} // $self->url) {
      $wh_url = Mojo::URL->new($url);
   }
   else {
      my $path = $args->{path} // $self->path;
      $path = Mojo::Path->new($path);

      my $c = $args->{controller} // $app->build_controller;
      $wh_url = $c->url_for($path);
   } ## end else [ if (my $url = $args->{...})]

   my $wh_url_string = $wh_url->to_abs->to_string;
   my $form = {url => $wh_url_string};

   if (my $certificate = $args->{certificate} // $self->certificate) {
      $certificate = {content => $certificate} unless ref $certificate;
      $form->{certificate} = $certificate;
   }

   $log->info("registering bot URI $wh_url_string");
   $self->_register($args->{token} // $self->token, $form);

   return $self;
} ## end sub register

sub unregister {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   $self->_register($args->{token} // $self->token);
   return $self;
} ## end sub unregister

sub _register {
   my ($self, $token, $form) = @_;
   require WWW::Telegram::BotAPI;
   my $outcome = WWW::Telegram::BotAPI->new(token => $token)
     ->setWebhook($form // {url => ''});
   $log->info($outcome->{description} // 'unknown result');
   return;
} ## end sub _register

1;
