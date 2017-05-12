#!perl

use strict;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid split_jid/;
use AnyEvent::XMPP::Ext::Registration;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests        => 2,
      two_accounts => 1,
      finish_count => 2
   );
my $C = $cl->client;

my $reg_error   = "";
my $unregistered = 0;

$C->reg_cb (
   session_ready => sub {
      my ($C, $acc) = @_;
      my ($username) = split_jid ($acc->bare_jid);
      my $con = $acc->connection;

      my $reg = AnyEvent::XMPP::Ext::Registration->new (connection => $con);

      $reg->send_unregistration_request (sub {
         my ($reg, $ok, $error, $form) = @_;

         if ($ok) {
            $unregistered++;
         } else {
            $reg_error = $error->string;
         }

         $cl->finish;
      });
   },
);

$cl->wait;

is ($unregistered, 2, "unregistered 2 accounts");
is ($reg_error, '', 'no unregistration error');
if ($reg_error) {
   diag (
      "Error in unregistration: "
      . $reg_error
      . ", please unregister two accounts yourself for the next tests."
   );
}
