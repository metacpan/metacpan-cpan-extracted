package AnyEvent::XMPP::Ext::MUC::Room;
use strict;
no warnings;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;
use AnyEvent::XMPP::Util qw/
   bare_jid prep_bare_jid cmp_jid split_jid join_jid is_bare_jid
   prep_res_jid prep_join_jid resourceprep
/;
use AnyEvent::XMPP::Ext::MUC::User;
use AnyEvent::XMPP::Ext::DataForm;
use AnyEvent::XMPP::Error::MUC;

use constant {
   JOIN_SENT => 1,
   JOINED    => 2,
   LEFT      => 3,
};

=head1 NAME

AnyEvent::XMPP::Ext::MUC::Room - Room class

=head1 SYNOPSIS

=head1 DESCRIPTION

This module represents a room handle for a MUC.

=head1 METHODS

=over 4

=item B<new (%args)>

=cut

sub new {
   my $this = shift;
   my $class = ref($this) || $this;
   my $self = bless { status => LEFT, @_ }, $class;
   $self->init;
   $self
}

sub init {
   my ($self) = @_;
   $self->{jid} = bare_jid ($self->{jid});
}

sub event {
   my ($self, $ev, @args) = @_;
   $self->{muc}->event ($ev, $self, @args);
}

sub handle_message {
   my ($self, $node) = @_;

   my $msg = AnyEvent::XMPP::Ext::MUC::Message->new (room => $self);

   if ($node->attr ('type') eq 'error') {
      my $error =
         AnyEvent::XMPP::Error::MUC->new (
            message_node => $node,
            message      => $msg
         );

      if ($error->type eq 'subject_change_forbidden') {
         $self->event (subject_change_error => $error);
      } else {
         $self->event (message_error => $error);
      }

   } else {
      $msg->from_node ($node);
      my $is_echo = cmp_jid ($msg->from, $self->nick_jid)
                    && $msg->type eq 'groupchat';

      if (not (defined $msg->any_body)
          && defined $msg->any_subject) { # subject change
         $self->event (subject_change => $msg, $is_echo);
         return;
      }

      $self->event (message => $msg, $is_echo);
   }
}

sub handle_presence {
   my ($self, $node) = @_;

   my $s = $self->{status};

   my $from = $node->attr ('from');
   my $type = $node->attr ('type');

   my $error;
   if ($type eq 'error') {
      $error = AnyEvent::XMPP::Error::Presence->new (node => $node);
   }

   my $stati = {};
   my $new_nick;

   if (my ($x) = $node->find_all ([qw/muc_user x/])) {
      for ($x->find_all ([qw/muc_user status/])) {
         $stati->{$_->attr ('code')}++;
      }

      if (my ($i) = $x->find_all ([qw/muc_user item/])) {
         $new_nick = $i->attr ('nick');
      }
   }

   my $nick_change = $stati->{'303'};

   if ($s == JOIN_SENT) {
      if ($error) {
         my $muce = AnyEvent::XMPP::Error::MUC->new (
            presence_error => $error,
            type           => 'presence_error'
         );
         $self->event (join_error => $muce);

      } else {
         if (cmp_jid ($from, $self->nick_jid)) {
            my $user = $self->add_user_xml ($node);
            $self->{status} = JOINED;
            $self->{me} = $user;

            if ($user->did_create_room) {
               if ($self->{locked_cb}) {
                  (delete $self->{locked_cb})->($self);

               } else {
                  $self->event ('locked');
               }
            } else {
               $self->event (enter => $user);
            }

         } else {
            $self->add_user_xml ($node);
         }
      }

   } elsif ($s == JOINED) { # nick changes?
      if ($error) {
         my $muce = AnyEvent::XMPP::Error::MUC->new (
            presence_error => $error,
            type           => 'presence_error'
         );
         $self->event (error => $muce);

      } elsif (!$nick_change && $type eq 'unavailable') {
         if (cmp_jid ($from, $self->nick_jid)) {
            $self->event ('leave', $self->get_me);
            $self->we_left_room ();

         } else {
            my $nick = prep_res_jid ($from);

            my $user = delete $self->{users}->{$nick};
            if ($user) {
               $user->update ($node);
               $self->event (part => $user);
            } else {
               warn "User with '$nick' not found in room $self->{jid}!\n";
            }
         }

      } elsif ($nick_change && $type eq 'unavailable') {
         my $nick = prep_res_jid ($from);
         my $nnick = resourceprep ($new_nick);

         my $user = $self->{users}->{$nnick} = delete $self->{users}->{$nick};
         if ($user) {
            $user->update ($node);
            $self->event (nick_change_leave => $user, $nick, $new_nick);
         } else {
            warn "User with '$nick' not found in room $self->{jid} for nickchange!\n";
         }

      } else {
         my $nick = prep_res_jid $from;
         my $pre  = $self->{users}->{$nick};
         my $in_nick_change = $pre ? $pre->is_in_nick_change : undef;
         my $user = $self->add_user_xml ($node);

         if ($pre) {
            if ($in_nick_change) {
               $self->event (nick_change => $user, $user->{old_nick}, $user->nick);
            } else {
               $self->event (presence => $user);
            }
         } else {
            $self->event (join => $user);
         }
      }
   }
}

sub we_left_room {
   my ($self) = @_;
   $self->{users}  = {};
   $self->{status} = LEFT;
   delete $self->{me};
}

=item B<get_user ($nick)>

This method returns the user with the C<$nick> in the room.

=cut

sub get_user {
   my ($self, $nick) = @_;
   $self->{users}->{$nick}
}

=item B<get_me>

This method returns the L<AnyEvent::XMPP::Ext::MUC::User> object of yourself
in the room. If will return undef if we are not in the room anymore.

=cut

sub get_me {
   my ($self) = @_;
   $self->{me}
}

=item B<get_user_jid ($jid)>

This method looks whether a user with the JID C<$jid> exists
in the room. That means whether the node and domain part of the
JID match the rooms node and domain part, and the resource part of the
JID matches a joined nick.

=cut

sub get_user_jid {
   my ($self, $jid) = @_;
   my ($room, $srv, $nick) = split_jid ($jid);
   return unless prep_join_jid ($room, $srv) eq prep_bare_jid $self->jid;
   $self->{users}->{$nick}
}

=item B<get_users>

This method returns the list of occupants as L<AnyEvent::XMPP::Ext::MUC::User> objects.

=cut

sub get_users {
   my ($self) = @_;
   values %{$self->{users}};
}

sub add_user_xml {
   my ($self, $node) = @_;
   my $from = $node->attr ('from');
   my $nick = prep_res_jid ($from);

   my $user = $self->{users}->{$nick};
   unless ($user) {
      $user = $self->{users}->{$nick} =
         AnyEvent::XMPP::Ext::MUC::User->new (room => $self);
   }

   $user->update ($node);

   $user
}

sub _join_jid_nick {
   my ($jid, $nick) = @_;
   my ($node, $host) = split_jid $jid;
   join_jid ($node, $host, $nick);
}

sub check_online {
   my ($self) = @_;
   unless ($self->is_connected) {
      warn "room $self not connected anymore!";
      return 0;
   }
   1
}

sub send_join {
   my ($self, $nick, $password, $history) = @_;
   $self->check_online or return;

   $self->{nick_jid} = _join_jid_nick ($self->{jid}, $nick);
   $self->{status}   = JOIN_SENT;

   my @chlds;
   if (defined $password) {
      push @chlds, { name => 'password', childs => [ $password ] };
   }

   if (defined $history) {
      my $h;
      push @{$h->{attrs}}, ('maxchars', $history->{chars})
         if defined $history->{chars};
      push @{$h->{attrs}}, ('maxstanzas', $history->{stanzas})
         if defined $history->{stanzas};
      push @{$h->{attrs}}, ('seconds', $history->{seconds})
         if defined $history->{seconds};

      if (defined $h->{attrs}) {
         $h->{name} = 'history';
         push @chlds, $h;
      }
   }

   my $con = $self->{connection};
   $con->send_presence (undef, {
      defns => 'muc', node => { ns => 'muc', name => 'x', childs => [ @chlds ] }
   }, to => $self->{nick_jid});
}

=item B<make_instant ($cb)>

If you just created a room you can create an instant room with this
method instead of going through room configuration for a reserved room.

If you want to create a reserved room instead don't forget to unset the
C<create_instant> argument of the C<join_room> method of L<AnyEvent::XMPP::Ext::MUC>!

See also the C<request_configuration> method below for the reserved room config.

C<$cb> is the callback that will be called when the instant room creation is
finished.  If successful the first argument will be this room object
(C<$self>), if unsuccessful the first argument will be undef and the second
will be a L<AnyEvent::XMPP::Error::IQ> object.

=cut

sub make_instant {
   my ($self, $cb) = @_;
   $self->check_online or return;

   my $df = AnyEvent::XMPP::Ext::DataForm->new;
   $df->set_form_type ('submit');
   my $sxl = $df->to_simxml;

   $self->{connection}->send_iq (
      set => {
         defns => 'muc_owner', node => {
            name => 'query', childs => [ $sxl ]
         }
      }, sub {
         my ($n, $e) = @_;

         if ($e) {
            $cb->(undef, $e);
         } else {
            $cb->($self, undef);
         }
      },
      to => $self->jid
   );
}

=item B<request_configuration ($cb)>

This method requests the room configuration. When the configuration
form or an error arrives C<$cb> will be called.
The first argument to the callback will be a L<AnyEvent::XMPP::Ext::DataForm>
with the room configuration form or undef in case of an error.
The second argument will be a L<AnyEvent::XMPP::Error::MUC> error object if an
error occurred or undef if no error occurred.

If you made an answer form you can send it via the C<send_configuration>
method below.

Here is an example:

   $room->request_configuration (sub {
      my ($form, $err) = @_;
      $form or return;

      my $af = AnyEvent::XMPP::Ext::DataForm->new;
      $af->make_answer_form ($form);
      $af->set_field_value ('muc#roomconfig_maxusers', 20);
      $af->clear_empty_fields;

      $roomhdl->send_configuration ($af, sub {
         # ...
      });
   });

=cut

sub request_configuration {
   my ($self, $cb) = @_;
   $self->check_online or return;

   $self->{connection}->send_iq (
      get => {
         defns => 'muc_owner', node => { name => 'query' }
      }, sub {
         my ($n, $e) = @_;
         if ($n) {
            if (my ($x) = $n->find_all ([qw/muc_owner query/], [qw/data_form x/])) {
               my $form = AnyEvent::XMPP::Ext::DataForm->new;
               $form->from_node ($x);
               $cb->($form, undef);
            } else {
               $e = AnyEvent::XMPP::Error::MUC->new (
                  type => 'no_config_form',
                  text => "The room didn't provide a configuration form"
               );
               $cb->(undef, $e);
            }
         } else {
            $cb->(undef, $e);
         }
      },
      to => $self->jid
   );
}

=item C<send_configuration ($answer_form, $cb)>

This method sends the answer form to a configuration request to the room.
C<$answer_form> should be a L<AnyEvent::XMPP::Ext::DataForm> object containig the
answer form with the changed configuration.

The first argument of C<$cb> will be a true value if the configuration change
was successful. The second argument of C<$cb> will be a C<AnyEvent::XMPP::Error::IQ>
object if the configuration change was not successful.

=cut

sub send_configuration {
   my ($self, $form, $cb) = @_;
   $self->check_online or return;

   $self->{connection}->send_iq (
      set => {
         defns => 'muc_owner', node => { name => 'query', childs => [
            $form->to_simxml
         ]}
      }, sub {
         my ($n, $e) = @_;
         if ($e) {
            $cb->(undef, $e);
         } else {
            $cb->(1, undef);
         }
      },
      to => $self->jid
   );
}

sub message_class { 'AnyEvent::XMPP::Ext::MUC::Message' }

=item B<make_message (%args)>

This method constructs a L<AnyEvent::XMPP::Ext::MUC::Message> with
a connection to this room.

C<%args> are further arguments for the constructor of L<AnyEvent::XMPP::Ext::MUC::Message>.
The default C<to> argument for the message is the room and the
C<type> will be 'groupchat'.

=cut

sub make_message {
   my ($self, %args) = @_;

   $self->message_class ()->new (
      room       => $self,
      to         => $self->jid,
      type       => 'groupchat',
      %args
   )
}

=item B<send_part ($msg, $cb, $timeout)>

This lets you part the room, C<$msg> is an optional part message
and can be undef if no custom message should be generated.

C<$cb> is called when we successfully left the room or after
C<$timeout> seconds. The default for C<$timeout> is 60.

The first argument to the call of C<$cb> will be undef if
we successfully parted, or a true value when the timeout hit.
Even if we timeout we consider ourself parted (and a 'leave' event
is generated).

=cut

sub send_part {
   my ($self, $msg, $cb, $timeout) = @_;
   $self->check_online or return;
   $timeout ||= 60;

   my $con = $self->{connection};
   my $timeouted = 0;

   if ($cb) {
      $self->{_part_timeout} =
         AnyEvent->timer (after => $timeout, cb => sub {
            delete $self->{_part_timeout};
            $timeouted = 1;
            $self->event ('leave', $self->get_me);
         });

      $self->{muc}->reg_cb (ext_after_leave => sub {
         my ($muc, $room) = @_;
         return unless cmp_jid ($room->nick_jid, $self->nick_jid);

         delete $self->{_part_timeout};
         $cb->($timeouted) if $cb;
         $muc->unreg_me;
      });
   }

   $con->send_presence (
      'unavailable', undef,
      (defined $msg ? (status => $msg) : ()),
      to => $self->{nick_jid}
   );
}

=item B<users>

Returns a list of L<AnyEvent::XMPP::Ext::MUC::User> objects
which are in this room.

=cut

sub users {
   my ($self) = @_;
   values %{$self->{users}}
}

=item B<jid>

Returns the bare JID of this room.

=cut

sub jid      { $_[0]->{jid} }

=item B<nick_jid>

Returns the full JID of yourself in the room.

=cut

sub nick_jid { $_[0]->{nick_jid} }

=item B<is_connected>

Returns true if this room is still connected (but maybe not joined (yet)).

=cut

sub is_connected {
   my ($self) = @_;
   $self->{muc} && $self->{connection} && $self->{connection}->is_connected
}

=item B<connection>

If the room is still joined this method will return the connection
on which the room is connected.

=cut

sub connection {
   my ($self) = @_;
   $self->{connection}
}

=item B<is_joined>

Returns true if this room is still joined (and connected).

=cut

sub is_joined {
   my ($self) = @_;
   $self->is_connected
   && $self->{status} == JOINED
}

=item B<change_nick ($newnick)>

This method lets you change your nickname in this room.

=cut

sub change_nick {
   my ($self, $newnick) = @_;
   my ($room, $srv) = split_jid $self->jid;
   $self->{connection}->send_presence (
      undef, undef, to => join_jid ($room, $srv, $newnick)
   );
}

=item B<change_subject ($newsubject)>

This methods changes the subject of the room.

=cut

sub change_subject {
   my ($self, $newsubject) = @_;
   my $msg = $self->make_message (subject => $newsubject);
   $msg->send;
}

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex at ta-sa.org> >>, JID: C<< <elmex at jabber.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
