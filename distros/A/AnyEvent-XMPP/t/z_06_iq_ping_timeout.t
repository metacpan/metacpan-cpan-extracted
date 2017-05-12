#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (tests => 1, finish_count => 1);
my $C = $cl->client;
my $disco = $cl->instance_ext ('AnyEvent::XMPP::Ext::Disco');
my $ping  = $cl->instance_ext ('AnyEvent::XMPP::Ext::Ping');

$disco->enable_feature ($ping->disco_feature);

my $disconnect_reason = '';
my @ignore_ids;

$C->reg_cb (
   session_ready => sub {
      my ($C, $acc) = @_;
      my $con = $acc->connection;
      push @ignore_ids, $con->next_iq_id;
      $ping->enable_timeout ($con, 1);
   },
   disconnect => sub {
      my ($C, $acc, $h, $p, $reason) = @_;
      $disconnect_reason = $reason;
      $cl->finish;
   },
   before_recv_stanza_xml => sub {
      my ($C, $acc, $node, $rstop) = @_;

      if ($node->eq (client => 'iq')
          && ($node->attr ('type') eq 'result' || $node->attr ('type') eq 'error')
          && grep { $_ eq $node->attr ('id') } @ignore_ids)
      {
         $$rstop = 1;
      }
   }
);

$cl->wait;

ok ($disconnect_reason =~ /timeout/, "disconnected by timeout");
