#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $ANAL = $ENV{NET_XMPP2_TEST_ANAL};

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests => 1,
      connection_args => {
         disable_sasl => 1,
         stream_version_override => '0.9',
         resource => "AnyEvent::XMPP::TestClient",
         ($ANAL ? (anal_iq_auth => 1) : ())
      }
   );
my $C = $cl->client;

my $skip = 0;
my $got_session = 0;

$C->reg_cb (
   stream_pre_authentication => sub {
      my ($C, $acc) = @_;
      my $feat = $acc->connection->features;
      if ($ANAL) {
         if (!$feat->find_all ([qw/iqauth auth/])) {
            $skip = 1;
            $cl->finish;
         }
      }
      ()
   },
   session_ready => sub {
      $got_session = 1;
      $cl->finish
   }
);

$cl->wait;

SKIP: {
   skip "no IQ auth method found", $cl->tests if $skip;
   ok ($got_session, "iq authentication");
}
