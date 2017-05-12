#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests => 6, two_accounts => 1, finish_count => 2
   );
my $C = $cl->client;

my ($src, $dest);
my $recv_message = "";

$C->reg_cb (
   two_accounts_ready => sub {
      my ($C) = @_;
      my $con = $cl->{acc}->connection;

      $src  = bare_jid $cl->{jid};
      $dest = bare_jid $cl->{jid2};

      my $msg = AnyEvent::XMPP::IM::Message->new (
         body    => "test body",
         to      => $cl->{jid2},
         subject => "Just a test",
         type    => 'headline',
      );

      $msg->send ($con);
      $cl->finish;
   },
   message => sub {
      my ($C, $acc, $msg) = @_;

      if (bare_jid ($msg->from) eq $src) {
         is ($acc->bare_jid,        $dest,         "arriving destination");
         is (bare_jid ($msg->from), $src,          "message source");
         is (bare_jid ($msg->to),   $dest,         "message destination");
         is ($msg->type,            'headline',    "message type");
         is ($msg->any_subject,     'Just a test', "message subject");
         is ($msg->any_body,        'test body',   "message body");

         $cl->finish;
      }
   }
);

$cl->wait;
