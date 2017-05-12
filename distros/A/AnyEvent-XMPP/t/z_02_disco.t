#!perl

use strict;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests => 3, two_accounts => 1, finish_count => 2
   );
my $C = $cl->client;
my $disco = $cl->instance_ext ('AnyEvent::XMPP::Ext::Disco');
$disco->set_identity (client => bot => "net xmpp2 test");

my $disco_error = '';

$C->reg_cb (
   two_accounts_ready => sub {
      my ($C) = @_;

      $disco->request_info ($cl->{acc}->connection, $cl->{jid2}, undef, sub {
         my ($disco, $info, $error) = @_;

         if ($error) {
            $disco_error = $error->string;

         } else {
            my (@ids) = $info->identities ();
            ok (
               (grep {
                  $_->{category} eq 'client'
                  && $_->{type} eq 'bot'
                  && $_->{name} eq 'net xmpp2 test'
               } @ids),
               "has bot identity"
            );

            ok (
               (grep {
                  $_->{category} eq 'client'
                  && $_->{type} eq 'console'
                  && $_->{name} eq 'net xmpp2 test'
               } @ids),
               "has default identity"
            );

            ok (
               (grep { 'jabber:x:data' eq $_ } keys %{$info->features}),
               "has data forms feature"
            );
         }
         $cl->finish;
      });

      $cl->finish;
   }
);

$cl->wait;
