#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid prep_bare_jid/;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (tests => 5, finish_count => 2);
my $C = $cl->client;
my $disco = $cl->instance_ext ('AnyEvent::XMPP::Ext::Disco');
my $vcard = $cl->instance_ext ('AnyEvent::XMPP::Ext::VCard');
$disco->enable_feature ($vcard->disco_feature);

my $test_vcard = {
   ADR      => [{ HOME => undef, LOCALITY => 'Hannover', PCODE => '23422' }],
   DESC     => ['Just a test vCard for AnyEvent::XMPP'],
   NICKNAME => ['elmex'],
   FN       => ['Robin'],
   _avatar  => do { open my $av, "t/n_xmpp2_avatar.png" or die "$!"; local $/; binmode $av; <$av> },
   _avatar_type => 'image/png'
};

my $error_free_store = 0;
my $returned_vcard;
my $cached_vcard;
my $discofeature;

$C->reg_cb (
   session_ready => sub {
      my ($C, $acc) = @_;

      $vcard->store ($acc->connection, $test_vcard, sub {
         if ($_[0]) { diag ("Couldn't store vcard: " . $_[0]->string); $cl->finish }
         unless ($_[0]) { $error_free_store = 1 }

         $vcard->retrieve ($acc->connection, undef, sub {
            my ($jid, $vc, $error) = @_;
            $returned_vcard = $vc;
            $cached_vcard = $vcard->cache->{prep_bare_jid $acc->jid};
            if ($error) { diag ("Couldn't retrieve vcard: " . $error->string) }
            $cl->finish;
         });
      });

      $disco->request_info ($acc->connection, $acc->jid, undef, sub {
         my ($disco, $info, $error) = @_;

         unless ($error) {
            ($discofeature) = grep { xmpp_ns ('vcard') eq $_ } keys %{$info->features};
         }

         $cl->finish;
      });
   }
);

$cl->wait;

sub match_value {
   my ($tv, $rv) = @_;
   if (ref $tv) {
      for my $tvk (keys (%$tv)) {
         if ($tv->{$tvk} ne $rv->{$tvk}) {
            return 0;
         }
      }
      return 1;
   } else {
      return $tv eq $rv;
   }
}

sub match_struct {
   my ($t, $r) = @_;
   my $ok = 1;

   for my $tk (keys %$t) {
     my $tv = $t->{$tk};
     my $rv = $r->{$tk};
     if (!ref $tv) {
        unless ($tv eq $rv) { return 0; }
        next;
     }
     for my $tav (@$tv) {
        unless (grep { match_value ($tav, $_) } @$rv) {
           require Data::Dumper;
           diag (Data::Dumper::Dumper ([$t,$r]));
           return 0;
        }
     }
   }
   return 1
}

ok ($error_free_store, 'stored the vcard error free');
ok ($returned_vcard,   'got a vcard back');
ok (match_struct ($test_vcard, $returned_vcard), 'the returned vcard has the same fields as the sent vcard');
ok (match_struct ($test_vcard, $cached_vcard), 'the cached vcard has the same fields as the sent vcard');
is ($discofeature, 'vcard-temp', 'vcard feature present on disco');
