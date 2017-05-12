#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid prep_bare_jid split_jid cmp_jid/;
use AnyEvent::XMPP::Ext::MUC;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests => 4, two_accounts => 1, muc_test => 1, finish_count => 1
   );
my $C = $cl->client;

my ($nickjids, $users_r1, $users_r2) = ("nonickjids", "nousers", "nootherusers");

my $discoerror;
my $discofeat;

$C->reg_cb (
   two_rooms_joined => sub {
      my ($C) = @_;
      $nickjids = join '', sort ($cl->{room}->nick_jid, $cl->{room2}->nick_jid);
      $users_r1 = join '', sort map { $_->jid } $cl->{room}->users;
      $users_r2 = join '', sort map { $_->jid } $cl->{room2}->users;

      $cl->{disco}->request_info ($cl->{acc}->connection, $cl->{jid2}, undef, sub {
         my ($disco, $info, $error) = @_;

         if ($error) {
            $discoerror = $error;
         } else {
            ($discofeat) = grep { xmpp_ns ('muc') eq $_ } keys %{$info->features};
         }
         $cl->finish;
      });
   }
);

$cl->wait;

is ($users_r1, $nickjids, 'room only has our two test bots');
is ($users_r1, $users_r2, 'the room lists match for both extensions');
ok (!$discoerror, 'disco was successful');
is ($discofeat, 'http://jabber.org/protocol/muc', 'disco feature of client ok');
