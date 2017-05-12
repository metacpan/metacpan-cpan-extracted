#!perl

use strict;
no warnings;
use Test::More;
use AnyEvent::XMPP::TestClient;
use AnyEvent::XMPP::IM::Message;
use AnyEvent::XMPP::Util qw/bare_jid prep_bare_jid split_jid cmp_jid/;
use AnyEvent::XMPP::Ext::MUC;

my $MUC = $ENV{NET_XMPP2_TEST_MUC};

unless ($MUC) {
   plan skip_all => "environment var NET_XMPP2_TEST_MUC not set! Set it to a conference!";
   exit;
}

my $ROOM = "test_nxmpp2@".$MUC;

my $cl =
   AnyEvent::XMPP::TestClient->new_or_exit (
      tests => 26, two_accounts => 1, finish_count => 1
   );
my $C     = $cl->client;
my $disco = $cl->instance_ext ('AnyEvent::XMPP::Ext::Disco');
my $muc   = $cl->instance_ext ('AnyEvent::XMPP::Ext::MUC', disco => $disco);

my $sjr_error   = '';
my $sjr_created = '';

my $sr_error      = '';
my $sr_created    = 0;
my $sr_pass_field = 0;
my $sr_config_ok  = 0;

my $sjo_join_error_type = '';

my $sjop_error = '';
my $sjop_join  = 0;

my $nick_info = {};
my $second = 0;

$cl->state (['two_accounts_ready'], step_join => {}, undef, sub {
   $muc->join_room ($cl->{acc}->connection, $ROOM, "test1owner");
   my $guard;
   $guard = $muc->reg_cb (
      enter => sub {
         my ($muc, $room, $user) = @_;

         if ($user->did_create_room) {
            $sjr_created = 1;
            $cl->{room} = $room;
            $cl->state_done ('step_join_done');
         } else {
            $cl->finish;
         }

         undef $guard;
      }, join_error => sub {
         my ($muc, $room, $error) = @_;

         $sjr_error = $error->string;
         undef $guard;
      }
   );
});

my $room_cnt_after_leave;

$cl->state (['step_join_done'], step_rejoin => {}, undef, sub {
   $cl->{room}->send_part ("rejoin");
   my $guard;
   $guard = $muc->reg_cb (
      enter => sub {
         my ($muc, $room, $user) = @_;

         $cl->finish; # error!
         undef $guard;
      },
      after_leave => sub {
         my ($muc, $room) = @_;

         $muc->join_room ($cl->{acc}->connection, $ROOM, "test1owner",
                          create_instant => 0);
      },
      leave => sub {
         my ($muc, $room) = @_;

         $room_cnt_after_leave = scalar ($muc->get_rooms ($cl->{acc}->connection));
      },
      locked => sub {
         my ($muc, $room) = @_;

         $cl->{room} = $room;
         $sr_created = 1;
         $room->request_configuration (sub {
            my ($form, $error) = @_;

            if ($form) {

               if ($form->get_field ('muc#roomconfig_passwordprotectedroom')
                   && $form->get_field ('muc#roomconfig_roomsecret')) {

                  $sr_pass_field = 1;

                  my $af = AnyEvent::XMPP::Ext::DataForm->new;
                  $af->make_answer_form ($form);
                  $af->set_field_value ('muc#roomconfig_passwordprotectedroom', 1);
                  $af->set_field_value ('muc#roomconfig_roomsecret', "abc123");
                  $af->clear_empty_fields;

                  $room->send_configuration ($af, sub {
                     my ($ok, $error) = @_;
                     if ($error) {
                        $sr_error = $error->string;
                        $cl->finish;
                     } else {
                        $sr_config_ok = 1;
                        $cl->state_done ('step_rejoin_done');
                     }
                  });

               } else {
                  $cl->finish;
               }
            }
         });

         undef $guard;
      },
      join_error => sub {
         my ($muc, $room, $error) = @_;
         $sr_error = $error->string;
         undef $guard;
         $cl->finish;
      }
   );

});

$cl->state (['step_rejoin_done'], 'step_join_occ', {}, undef, sub {
   $muc->join_room ($cl->{acc2}->connection, $ROOM, "test2user");
   my $guard;
   $guard = $muc->reg_cb (
      enter => sub {
         my ($muc, $room, $user) = @_;
         undef $guard;
         $cl->finish
      },
      join_error => sub {
         my ($muc, $room, $error) = @_;
         undef $guard;

         $sjo_join_error_type = $error->type;

         if ($sjo_join_error_type eq 'password_required') {
            $cl->state_done ('step_join_occ_done');
         }
      }
   );
});

$cl->state (['step_join_occ_done'], 'step_join_occ_pass', {}, undef, sub {
   $muc->join_room ($cl->{acc2}->connection, $ROOM, "test2user", password => 'abc123');

   my $guard;
   $guard = $muc->reg_cb (
      enter => sub {
         my ($muc, $room, $user) = @_;
         $sjop_join++;
         $cl->{room2} = $room;
         $cl->state_done ('step_join_occ_pass_done');
         undef $guard;
      }, join_error => sub {
         my ($muc, $room, $error) = @_;
         $sjop_error = $error->string;
         $cl->finish;
         undef $guard;
      }
   );
});

my $ni = $nick_info;

$cl->state (['step_join_occ_pass_done'], 'step_change_nick1', {}, undef, sub {
   my $cnt = 0;

   $muc->reg_cb (
      nick_change => sub {
         my ($muc, $room, $user, $oldnick, $newnick) = @_;

         return unless cmp_jid ($room->nick_jid, $cl->{room}->nick_jid);

         my (@other) = grep $_->jid ne $cl->{room}->get_me->jid, $cl->{room}->users;

         $ni->{user1}->{own}      = $cl->{room}->get_me->jid;
         $ni->{user1}->{other}    = $other[0]->jid;
         $ni->{user1}->{old_nick} = $oldnick;
         $ni->{user1}->{new_nick} = $newnick;
         $cl->state_check;
      }
   );

   $muc->reg_cb (
      nick_change => sub {
         my ($muc, $room, $user, $oldnick, $newnick) = @_;

         return unless cmp_jid ($room->nick_jid, $cl->{room2}->nick_jid);

         my (@other) = grep $_->jid ne $cl->{room2}->get_me->jid, $cl->{room2}->users;

         $ni->{user2}->{own}      = $cl->{room2}->get_me->jid;
         $ni->{user2}->{other}    = $other[0]->jid;
         $ni->{user2}->{old_nick} = $oldnick;
         $ni->{user2}->{new_nick} = $newnick;
         $cl->state_check;
      }
   );

   $cl->{room2}->change_nick ("test2");
});

$cl->state ('step_change_nick2', {}, sub {
   $nick_info->{user1} && $nick_info->{user2}
}, sub {
   $ni = $nick_info->{second} = {};
   $cl->{room2}->change_nick ("test2nd");
});

$cl->state (['step_change_nick2'], 'step_end', {}, sub {
      $nick_info->{user1}
   && $nick_info->{user2}
   && $nick_info->{second}->{user1}
   && $nick_info->{second}->{user2}
}, sub { $cl->finish });

$cl->wait;

is ($sjr_error        ,        '', "creator joined without error");
ok ($sjr_created                 , "creator created room");
ok ($sr_created                  , "rejoin created room");
is ($sr_error         ,        '', "rejoin created without error");
ok ($sr_pass_field               , "configuration form has password fields");
ok ($sr_config_ok                , "configuration form was successfully sent");
is ($sjo_join_error_type, 'password_required', "occupant joined without error");
is ($sjop_error       ,        '', "rejoin with password no error");
is ($sjop_join        ,         1, "joined successfully with password");

is ($nick_info->{user1}->{own}     , "$ROOM/test1owner", 'observed own JID of user1');
is ($nick_info->{user1}->{other}   , "$ROOM/test2"     , 'observed other JID of user1');
is ($nick_info->{user1}->{old_nick}, "test2user"       , 'observed old nick of user1');
is ($nick_info->{user1}->{new_nick}, "test2"           , 'observed new nick of user1');

is ($nick_info->{user2}->{own}     , "$ROOM/test2"     , 'observed own JID of user2');
is ($nick_info->{user2}->{other}   , "$ROOM/test1owner", 'observed other JID of user2');
is ($nick_info->{user2}->{old_nick}, "test2user"       , 'observed old nick of user2');
is ($nick_info->{user2}->{new_nick}, "test2"           , 'observed new nick of user2');

$nick_info = $nick_info->{second};
is ($nick_info->{user1}->{own}     , "$ROOM/test1owner", '2nd observed own JID of user1');
is ($nick_info->{user1}->{other}   , "$ROOM/test2nd"   , '2nd observed other JID of user1');
is ($nick_info->{user1}->{old_nick}, "test2"           , '2nd observed old nick of user1');
is ($nick_info->{user1}->{new_nick}, "test2nd"         , '2nd observed new nick of user1');

is ($nick_info->{user2}->{own}     , "$ROOM/test2nd"   , '2nd observed own JID of user2');
is ($nick_info->{user2}->{other}   , "$ROOM/test1owner", '2nd observed other JID of user2');
is ($nick_info->{user2}->{old_nick}, "test2"           , '2nd observed old nick of user2');
is ($nick_info->{user2}->{new_nick}, "test2nd"         , '2nd observed new nick of user2');
is ($room_cnt_after_leave,           0,                , 'after leaving the room list was empty');
