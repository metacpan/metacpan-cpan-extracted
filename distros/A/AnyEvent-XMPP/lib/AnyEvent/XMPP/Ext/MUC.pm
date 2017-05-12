package AnyEvent::XMPP::Ext::MUC;
use strict;
no warnings;
use AnyEvent::XMPP::Util qw/prep_bare_jid bare_jid stringprep_jid cmp_jid/;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Ext;
use AnyEvent::XMPP::Ext::MUC::Room;
use AnyEvent::XMPP::Ext::MUC::RoomInfo;

our @ISA = qw/AnyEvent::XMPP::Ext/;

=head1 NAME

AnyEvent::XMPP::Ext::MUC - Implements XEP-0045: Multi-User Chat

=head1 SYNOPSIS

   my $con = AnyEvent::XMPP::Connection->new (...);
   $con->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
   $con->add_extension (my $muc = AnyEvent::XMPP::Ext::MUC->new (disco => $disco));
   ...

=head1 DESCRIPTION

This module handles multi user chats and provides new events to catch
multi user chat messages. It intercepts messages from the connection
so they don't interfere with your other callbacks on the connection.

This extension requires the L<AnyEvent::XMPP::Ext::Disco> extension for service
discovery.

=cut

=head1 METHODS

=over 4

=item B<new>

This is the constructor for a MUC extension object.
It takes no further arguments.

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { join_timeout => 60, @_ }, $class;
   $self->{inhibit_forward} = { map { ($_ => 1) } qw/message presence/ };
   $self->init;
   $self
}

sub disco_feature { xmpp_ns ('muc') }

sub init {
   my ($self) = @_;

   my $proxy = sub {
      my ($self, @args) = @_;
      $self->event (@args);
   };

   $self->{disco}->enable_feature ($self->disco_feature);

   $self->reg_cb (
      join_error           => $proxy,
      subject_change_error => $proxy,
      message_error        => $proxy,
   );

   $self->reg_cb (
      ext_before_presence_xml => sub {
         my ($self, $con, $node) = @_;

         if (my $room = $self->get_room ($con, $node->attr ('from'))) {
            $self->stop_event;
            $room->handle_presence ($node);
         }
      },
      ext_before_message_xml => sub {
         my ($self, $con, $node) = @_;

         if (my $room = $self->get_room ($con, $node->attr ('from'))) {
            $self->stop_event;
            $room->handle_message ($node);
         }
      },
      ext_before_leave => sub {
         my ($self, $room) = @_;
         $self->uninstall_room ($room->connection, $room);
      },
      disconnect => sub {
         my ($self, $con, $h, $p, $msg) = @_;
         $self->cleanup_rooms ($con, "$h:$p: $msg");
      }
   );
}

sub cleanup_rooms {
   my ($self, $con, $msg) = @_;

   my $conjid = stringprep_jid $con->jid;

   for (keys %{$self->{rooms}->{$conjid}}) {
      my $room = delete $self->{rooms}->{$conjid}->{$_};
      $self->event (leave => $room, $room->get_me, "disconnected from server $msg");
   }
}

=item B<is_conference ($con, $jid, $cb)>

TODO

=cut

sub is_conference {
   my ($self, $con, $jid, $cb) = @_;

   $self->{disco}->request_info ($con, $jid, undef, sub {
      my ($disco, $info, $error) = @_;

      if ($error || !$info->features ()->{xmpp_ns ('muc')}) {
         $cb->(undef, $error);
      } else {
         $cb->($info, undef);
      }
   });
}

=item B<is_room ($con, $jid, $cb)>

This method sends a information discovery to the C<$jid>, via the connection
C<$con>.  C<$cb> is called when the information arrives or with an error after
the usual IQ timeout.

When the C<$jid> was a room C<$cb> is called with the first argument
being a L<AnyEvent::XMPP::Ext::MUC::RoomInfo> object. If the destination
wasn't reachable, the room doesn't exist or some other error happened
the first argument will be undefined and the second a L<AnyEvent::XMPP::Error::IQ>
object.

=cut

sub is_room {
   my ($self, $con, $jid, $cb) = @_;

   $self->{disco}->request_info ($con, $jid, undef, sub {
      my ($disco, $info, $error) = @_;

      if ($error || !$info->features ()->{xmpp_ns ('muc')}) {
         $cb->(undef, $error);
      } else {
         my $rinfo = AnyEvent::XMPP::Ext::MUC::RoomInfo->new (disco_info => $info);
         $cb->($rinfo, undef);
      }
   });
}

=item B<join_room ($con, $jid, $nick, %args)>

This method joins a room.

C<$con> should be the L<AnyEvent::XMPP::IM::Connection> object that
is to be used to send the necessary stanzas.
C<$jid> should be the bare JID of the room.
C<$nick> should be your desired nickname in the room.

When you successfully entered the room a C<enter> event is emitted.  In case
you created the room, and it is locked, a C<locked> event is emitted.  Please
look in the C<EVENTS> section below for more details about how to handle
C<locked> rooms. (You won't have to care about locked rooms if you
didn't disable the C<create_instant> flag in C<%args>).

If an error occurred and we couldn't join the room, the first two arguments are
undef and the third is a L<AnyEvent::XMPP::Error::MUC> object signalling the error.

C<%args> hash can contain one of the following keys:

=over 4

=item timeout => $timeout_in_secs

This is the timeout for joining the room.
The default timeout is 60 seconds if the timeout is not specified.

=item history => {}

Manage MUC-history from XEP-0045 (7.1.16)
Hash can contain of the following keys: C<chars>, C<stanzas>, C<seconds>

Example:

	history => {chars => 0} # don't load history
	history => {stanzas => 3} # load last 3 history elements
	history => {seconds => 300, chars => 500}
		# load history in last 5 minutes, but max 500 characters

TODO: add C<since> attributes

=item create_instant => $bool

If you set C<$bool> to a true value we try to establish an instant room
on joining if it doesn't already exist.

XXX XXX XXX 
XXX XXX XXX 
XXX XXX XXX 
XXX XXX XXX 

The default for this flag is true! So if you want to create an reserved room
with custom creation in the beginning you have to pass a false value as C<$bool>.

B<PLEASE NOTE:> If you set C<$bool> to a B<false> value you have to check the
C<did_create_room> status flag on your own instance of
L<AnyEvent::XMPP::Ext::MUC::User> (provided as the second argument to the
callback) to see whether you need to finish room creation! If you don't do this
the room B<may stay LOCKED for ever>.

See also the C<make_instant> and C<request_configuration> methods of
L<AnyEvent::XMPP::Ext::MUC>.

=item password => $password

The password for the room.

=item nickcollision_cb => $cb

If the join to the room results in a nickname collision the C<$cb>
will be called with the nickname that collided and the return value will
be used as alternate nickname and the join is retried.

This function is called I<everytime> the nickname collides on join, so you
should take care of possible endless retries.

=back

=cut

sub join_room {
   my ($self, $con, $jid, $nick, %args) = @_;

   unless (exists $args{create_instant}) {
      $args{create_instant} = 1;
   }

   my $timeout = $args{timeout} || $self->{join_timeout};

   my $room = $self->install_room ($con, $jid);

   $room->{locked_cb} =
      $args{create_instant} ? sub {
         my ($room) = @_;

         $room->make_instant (sub {
            my ($room, $error) = @_;

            if ($error) {
               $self->event (join_error => $room, $error);
            } else {
               $self->event (enter => $room, $room->get_me);
            }
         });
      } : undef;

   $room->{room_join_timer} =
      AnyEvent->timer (after => $timeout, cb => sub {
         delete $room->{room_join_timer};
         $self->uninstall_room ($con, $room);

         my $muce = AnyEvent::XMPP::Error::MUC->new (
            type => 'join_timeout',
            text => "Couldn't join room in time, timeout after $timeout\n"
         );
         
         $self->event (join_error => $room, $muce);
      });

   my $rcb_id;
   $rcb_id = $self->reg_cb (
      join_error => sub {
         my ($muc, $eroom, $error) = @_;
         return unless cmp_jid ($eroom->nick_jid, $room->nick_jid);

         if ($error->type eq 'nickname_in_use'
             && exists $args{nickcollision_cb}) {

            $nick = $args{nickcollision_cb}->($nick);
            $room->send_join ($nick, $args{password}, $args{history});
            return;
         }

         delete $room->{room_join_timer};
         $self->uninstall_room ($con, $room);
         $muc->unreg_cb ($rcb_id);
      },
      enter => sub {
         my ($muc, $eroom, $user) = @_;
         return unless cmp_jid ($eroom->nick_jid, $room->nick_jid);

         delete $room->{room_join_timer};
         $muc->unreg_cb ($rcb_id);
      }
   );

   $room->send_join ($nick, $args{password}, $args{history});
}

sub install_room {
   my ($self, $con, $room_jid) = @_;

   my $room
      = $self->{rooms}->{stringprep_jid $con->jid}->{prep_bare_jid $room_jid}
         = AnyEvent::XMPP::Ext::MUC::Room->new (
            muc        => $self,
            connection => $con,
            jid        => $room_jid
         );

   $room
}

sub uninstall_room {
   my ($self, $con, $room) = @_;
   my $r =
      delete $self->{rooms}->{stringprep_jid $con->jid}->{prep_bare_jid $room->jid};
   delete $r->{muc};
}

=item B<get_room ($con, $jid)>

This returns the L<AnyEvent::XMPP::Ext::MUC::Room> object
for the bare part of the C<$jid> if we are joining or have
joined such a room.

If we are not joined undef is returned.

=cut

sub get_room {
   my ($self, $con, $jid) = @_;
   $self->{rooms}->{stringprep_jid $con->jid}->{prep_bare_jid $jid}
}

=item B<get_rooms ($con)>

Returns a list of L<AnyEvent::XMPP::Ext::MUC::Room> objects
for the connection C<$con>.

=cut

sub get_rooms {
   my ($self, $con) = @_;
   values %{$self->{rooms}->{stringprep_jid $con->jid} || {}}
}

=back

=head1 EVENTS

These are the events that are issued by this MUC extension:

C<$room> is the L<AnyEvent::XMPP::Ext::MUC::Room> object which
the event belongs to.

=over 4

=item message => $room, $msg, $is_echo

This event is emitted when a message was received from the room.
C<$msg> is a L<AnyEvent::XMPP::Ext::MUC::Message> object and C<$is_echo>
is true if the message is an echo.

B<NOTE:> Please note that some conferences send messages already
before you have finished joining a room. That means that you might
already get a C<message> event for a room that you haven't got an C<enter>
for event yet. That means that methods like C<get_me> might return undef.

=item subject_change => $room, $msg, $is_echo

This event is emitted when a user changes the room subject.
C<$msg> is a L<AnyEvent::XMPP::Ext::MUC::Message> object and C<$is_echo>
is true if the message is an echo.

The room subject is the subject of that C<$msg>.

=item subject_change_error => $room, $error

If you weren't allowed to change the subject or some other error
occurred you will receive this event.
C<$error> is a L<AnyEvent::XMPP::Error::MUC> object.

=item error => $room, $error

This event is emitted when any error occurred.
C<$error> is a L<AnyEvent::XMPP::Error::MUC> object.

=item join_error => $room, $error

This event is emitted when a error occurred when joining a room.
C<$error> is a L<AnyEvent::XMPP::Error::MUC> object.

=item locked => $room

This event is emitted when you disabled the 'create_instant'
flag when calling C<join_room>. It means that you just created
a new room, which is locked. You need to configure it before
it is unlocked and others can enter.

Please consult the methods C<make_instant>, C<request_configuration> and
C<send_configuration> of L<AnyEvent::XMPP::Ext::MUC::Room> for more information
about how to configure a room.

B<NOTE:> You won't get another event when you finished configuring the room, so
you maybe want to call this on the C<AnyEvent::XMPP::Ext::MUC> object when you
finished configuring the room successfully:

   $muc->event (enter => $room, $room->get_me);

That could be helpful if you want to place some generic
stuff in your C<enter> event handlers.

B<NOTE2:> If you didn't disable the C<create_instant> flag of C<join_room> you
won't have to care about a C<locked> event, as everything will be internally
handled for you and you will get an C<enter> event if the room is finally
setted up.

=item enter => $room, $user

This event is emitted when we successfully joined the room.
C<$user> is a L<AnyEvent::XMPP::Ext::MUC::User> object which is
the user handle for ourself.

=item join => $room, $user

This event is emitted when a new user joins the room.
C<$user> is the L<AnyEvent::XMPP::Ext::MUC::User> object of that user.

=item nick_change => $room, $user, $oldnick, $newnick

This event is emitted when a user changed his nickname.
C<$user> is the L<AnyEvent::XMPP::Ext::MUC::User> object of that user.
C<$oldnick> is the old nickname and C<$newnick> is the new nickname.

=item presence => $room, $user

This event is emitted when a user changes it's presence status
(eg. affiliation or role, or away status).
C<$user> is the L<AnyEvent::XMPP::Ext::MUC::User> object of that user.

=item part => $room, $user

This event is emitted when a user leaves the channel.  C<$user> is the
L<AnyEvent::XMPP::Ext::MUC::User> of that user, but please note that you shouldn't
send any messages to this user anymore.

=item leave => $room, $user

This event is emitted when we leave the room. C<$user> is your
L<AnyEvent::XMPP::Ext::MUC::User> handle.

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AnyEvent::XMPP::Ext::MUC
