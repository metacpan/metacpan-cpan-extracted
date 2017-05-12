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
   AnyEvent::XMPP::TestClient->new_or_exit (tests => 3, two_accounts => 1, finish_count => 2);
my $C = $cl->client;
my $disco = $cl->instance_ext ('AnyEvent::XMPP::Ext::Disco');
my $ping  = $cl->instance_ext ('AnyEvent::XMPP::Ext::Ping');
$ping->auto_timeout (1);

$disco->enable_feature ($ping->disco_feature);

my $ping_error = '';
my $response_time;
my $feature = 0;

$C->reg_cb (
   two_accounts_ready => sub {
      my ($C) = @_;
      my $con = $cl->{acc}->connection;

      $disco->request_info ($con, $cl->{jid2}, undef, sub {
         my ($disco, $info, $error) = @_;
         $feature = ! ! ($info->features->{xmpp_ns ('ping')});
         $cl->finish;
      });

      $ping->ping ($con, $cl->{jid2}, sub {
         my ($time, $error) = @_;
         if ($error) {
            $ping_error = $error->string;
         }
         $response_time = $time;
         $cl->finish;
      });
   }
);

$cl->wait;

is ($ping_error,         '', 'no ping error');
ok ($feature               , 'ping feature advertised');
ok ($response_time > 0.0001, 'got a reasonable response time');
