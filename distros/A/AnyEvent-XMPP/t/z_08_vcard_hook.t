#!perl

use strict;
no warnings;
use Test::More;
use Digest::SHA qw/sha1_hex/;
use AnyEvent::XMPP;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/bare_jid prep_bare_jid/;

my $cl    = AnyEvent::XMPP::TestClient->new_or_exit (tests => 3, finish_count => 1);
my $C     = $cl->client;
my $vcard = $cl->instance_ext ('AnyEvent::XMPP::Ext::VCard');

my $got_my_vcard;
my $my_avatar;
my $my_avatar_hash;

open AVATAR, "t/n_xmpp2_avatar.png" or die "Couldn't open avatar: $!";
my $real_avatar = do { local $/; binmode AVATAR; <AVATAR> };
my $real_avatar_hash = sha1_hex ($real_avatar);
close AVATAR;

$C->reg_cb (
   stream_ready => sub {
      my ($C, $acc) = @_;
      $vcard->reg_cb (
         vcard => sub {
            my ($vcard, $jid, $vc) = @_;
            if (my $vc = $vcard->my_vcard ($jid)) {
               $got_my_vcard = 1;
               $my_avatar = $vc->{_avatar};
               $my_avatar_hash = $vc->{_avatar_hash};
               $cl->finish;
            }
         }
      );
      $vcard->hook_on ($acc->connection);
   },
);

$cl->wait;

ok ($got_my_vcard, "retrieved my vcard on connect");
is ($my_avatar_hash, $real_avatar_hash, "hashes of the avatars match");
ok ($my_avatar eq $real_avatar, "avatar data matches");
