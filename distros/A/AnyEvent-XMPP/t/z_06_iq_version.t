#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (tests => 4, two_accounts => 1, finish_count => 2);
my $C = $cl->client;
my $vers = $cl->instance_ext ('AnyEvent::XMPP::Ext::Version');

$vers->set_os ('GNU/Virtual 0.23 x86_128');

my $recv_error;
my $recv_error_2;
my $recv_vers_error = '';
my $recv_vers;

my $dest;

$C->reg_cb (
   two_accounts_ready => sub {
      my ($C) = @_;
      my $con = $cl->{acc}->connection;

      $dest = $cl->{jid2};

      $vers->request_version ($con, $cl->{jid2}, sub {
         my ($version, $error) = @_;

         if ($error) {
            $recv_error = $error;

         } else {
            $recv_vers =
               sprintf "(%s) %s/%s/%s",
                  $version->{jid}, $version->{name}, $version->{version}, $version->{os};
         }
         $cl->finish;
      });

      $con->send_iq ('get', {
         defns => 'broken:iq:request',
         node => { ns => 'broken:iq:request', name => 'query' }
      }, sub {
         my ($n, $e) = @_;
         $recv_error_2 = $e;
         $cl->finish;
      }, to => $cl->{jid2});
   }
);

$cl->wait;

ok ((not defined $recv_error), 'no service unavailable error on first request');
is ($recv_error_2->condition (), 'service-unavailable', 'service unavailable error for second request');
is ($recv_vers_error         , ''                   , 'no software version error');
is ($recv_vers,
    "($dest) AnyEvent::XMPP/$AnyEvent::XMPP::VERSION/GNU/Virtual 0.23 x86_128",
    'software version reply');
