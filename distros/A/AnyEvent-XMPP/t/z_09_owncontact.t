#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (tests => 1, finish_count => 1);
my $C = $cl->client;

my ($src, $dest);
my $recv_message = "";

$C->reg_cb (
   presence_update => sub {
      my ($C, $acc, $roster, $contact) = @_;

      if ($contact->is_me) {
         my ($first) = $contact->get_presences ();

         if ($first->show eq '') {
            $acc->connection->send_presence (
               undef, undef, show => 'xa', status => 'testing');
         } elsif ($first->show eq 'xa') {
            is ($first->status, 'testing', "extended away status is 'testing'");
            $cl->finish;
         }
      }
   }
);

$cl->wait;
