#!perl

use strict;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid split_jid/;
use AnyEvent::XMPP::Ext::Registration;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests        => 3,
      two_accounts => 1,
      finish_count => 2
   );
my $C = $cl->client;

my $already_reg = 0;
my $reg_error   = "";
my $registered  = 0;
my $ready_session = 0;

$C->reg_cb (
   stream_pre_authentication => sub {
      my ($C, $acc) = @_;
      my ($username) = split_jid ($acc->bare_jid);
      my $con = $acc->connection;

      my $reg = AnyEvent::XMPP::Ext::Registration->new (connection => $con);

      $reg->send_registration_request (sub {
         my ($reg, $form, $error) = @_;

         if ($error) {
            $reg_error = $error->string;

         } else {
            my $af = $form->try_fillout_registration ($username, $cl->{password});

            $reg->submit_form ($af, sub {
               my ($reg, $ok, $error, $form) = @_;

               if ($ok) {
                  $registered = 1;
                  $acc->connection->authenticate;
               } else {
                  $reg_error = $error->string;
               }
            });
         }
      });

      0
   },
   session_ready => sub {
      my ($C, $acc) = @_;
      $ready_session++;
      $cl->finish
   }
);

$cl->wait;

SKIP: {
   skip "account already registered (please unregister!)"
      if $already_reg;

   ok ($registered, "registered account");
   is ($reg_error, '', 'no registration error');
   is ($ready_session, 2, 'sessions ready');
   if ($reg_error) {
      diag (
         "Error in registration: " 
         . $reg_error 
         . ", please register two accounts yourself for the next tests."
      );
   }
}
