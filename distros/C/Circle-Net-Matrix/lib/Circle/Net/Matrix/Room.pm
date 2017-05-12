#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2014-2017 -- leonerd@leonerd.org.uk

package Circle::Net::Matrix::Room;

use strict;
use warnings;
use base qw( Tangence::Object Circle::WindowItem );

our $VERSION = '0.03';

use Data::Dump qw( pp );
use Scalar::Util qw( weaken );

use Net::Async::Matrix::Utils qw( parse_formatted_message build_formatted_message );
use Circle::TaggedString;

use Circle::Net::Matrix::Utils qw( parse_markdownlike );

# To allow for out-of-tree development, use an inline Tangence class
# declaration instead of a .tan file
#
# class Circle.Net.Matrix.Room {
#   isa Circle.WindowItem;
#
#   smashed prop name = str;
#   smashed prop topic = str;
# }

sub DECLARE_TANGENCE
{
   Tangence::Class->declare( __PACKAGE__,
      props => {
         name => {
            dim  => Tangence::Constants::DIM_SCALAR,
            type => 'str',
         },
      },

      superclasses => [qw( Circle::WindowItem )],
   );
}

sub WEAKSELF_EVAL
{
   my ( $self, $method ) = @_;
   my $code = $self->can( $method ) or return sub {};

   weaken( $self );
   return sub {
      my @args = @_;
      eval { $self->$code( @args ); 1 } or
         warn $@;
   };
}

sub init_prop_topic { "" }

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( @_ );

   my $room = $self->{room} = $args{room};

   $self->set_prop_name( $room->room_id );
   $self->set_prop_tag( $room->room_id );

   $self->{root} = $args{root};
   $self->{net}  = $args{net};

   weaken( my $weakself = $self );
   $room->configure(
      on_synced_state => $self->WEAKSELF_EVAL( 'on_synced_state' ),

      on_message        => $self->WEAKSELF_EVAL( 'on_message' ),
      on_membership     => $self->WEAKSELF_EVAL( 'on_membership' ),
      on_state_changed  => $self->WEAKSELF_EVAL( 'on_state_changed' ),
      on_members_typing => $self->WEAKSELF_EVAL( 'on_members_typing' ),
      on_read_receipt   => $self->WEAKSELF_EVAL( 'on_read_receipt' ),
   );

   # TODO: this entire state-watching system likely wants to be migrated into
   # NaMatrix itself
   $self->{state_watches} = {
      'm.room.name'    => $self->can( 'on_state_name' ),
      'm.room.topic'   => $self->can( 'on_state_topic' ),
      'm.room.member*' => $self->can( 'on_state_members' ),

      'm.room.join_rules'         => $self->can( 'on_state_permission' ),
      'm.room.history_visibility' => $self->can( 'on_state_permission' ),
   };

   return $self;
}

# Convenience accessor
sub name
{
   my $self = shift;
   return $self->get_prop_name;
}

sub enumerable_name
{
   my $self = shift;
   return $self->name;
}

sub get_prop_tag
{
   my $self = shift;
   return $self->name;
}

sub parent
{
   my $self = shift;
   return $self->{net};
}

sub commandable_parent
{
   my $self = shift;
   return $self->parent;
}

sub on_synced_state
{
   my $self = shift;

   my $room = $self->{room};

   my $state = $room->live_state;

   my $watches = $self->{state_watches};
   foreach my $type ( keys %$watches ) {
      # TODO: avoid doing the name ones twice in here somehow
      my $code = $watches->{$type};

      if( $type =~ m/^(.*)\*$/ ) {
         $code->( $self, $state->get_events( $1 ) );
      }
      else {
         $code->( $self, $state->get_event( $type ) );
      }
   }

   my $name = $self->_generate_roomname( $state );

   $self->set_prop_name( $name );
   $self->set_prop_tag( $name );
}

sub on_state_name
{
   my $self = shift;

   my $state = $self->{room}->live_state;

   my $name = $self->_generate_roomname( $state );

   $self->set_prop_name( $name );
   $self->set_prop_tag( $name );
}

sub _generate_roomname
{
   my $self = shift;
   my ( $state ) = @_;

   my $event;

   $event = $state->get_event( 'm.room.name' ) and
      return $event->{content}{name};

   my $myself = $self->{net}{matrix}->myself;
   my $domain = ( $myself->user_id =~ m/:(.*)$/ )[0];

   # TODO: pick canonical alias if there is one

   my %aliasmap = %{ $state->get_events( 'm.room.aliases' ) };

   # Prefer an alias defined by my own homeserver
   my $local_aliases = $aliasmap{$domain};
   $local_aliases and
      return $local_aliases->{content}{aliases}[0];

   # TODO: try to stable-sort them
   my @aliases = map { @{ $_->{content}{aliases} } }
                 values %aliasmap;

   return $aliases[0] if @aliases;

   my @others = grep { $_->user->user_id ne $myself->user_id } $state->members;

   return $others[0]->displayname if @others == 1;

   warn "Did not find exactly one peer for ${\ $self->{room}->room_id }; bailing out\n";
   return $self->{room}->room_id;
}

sub on_state_topic
{
   my $self = shift;
   my ( $event ) = @_;

   my $topic = $event->{content}{topic};

   $self->get_widget_topic->set_prop_text( $topic );
}

sub on_state_members
{
   my $self = shift;
   my ( $eventmap ) = @_;

   # For now lets just count members by membership, but at some point we'd
   # like to consider powerlevel or something too
   my %members_by_membership;

   $members_by_membership{ $_->{content}{membership} }++ for values %$eventmap;

   my $count = "$members_by_membership{join} members";
   $count .= " + $members_by_membership{invite} invited" if $members_by_membership{invite};
   # Ignore "leave"

   $self->get_widget_membercount->set_prop_text( $count );

   my $my_userid = $self->{net}{matrix}->myself->user_id;

   $self->get_widget_displayname->set_prop_text(
      $eventmap->{$my_userid }{content}{displayname} // $my_userid
   );
}

sub on_state_permission
{
   my $self = shift;
   # Ignore the passed event because we combine multiple

   my $state = $self->{room}->live_state;

   my $ev;
   my @parts;

   # TODO: something about my own power level?

   push @parts, "J=" . ( $state->join_rule // "?" );

   $ev = $state->get_event( "m.room.history_visibility" );
   push @parts, "V=" . ( ( $ev && $ev->{content}{history_visibility} ) // "?" );

   $self->get_widget_permission->set_prop_text( join "|", @parts );
}

sub on_message
{
   my $self = shift; shift;
   my ( $member, $content, $event ) = @_;
   my $member_id = $member->user->user_id;

   $self->{latest_event_id} = $event->{event_id};

   my $tstamp = $event->{origin_server_ts} / 1000;
   my $type = $content->{msgtype};

   my $formatted_body = parse_formatted_message( $content );
   my $text = Circle::TaggedString->new_from_formatting( $formatted_body );

   my ( $etype, $args );
   if( $type eq "m.text" ) {
      ( $etype, $args ) = ( "matrix.text" => {
         name => $member->displayname,
         user_id => $member_id,
         text => $text,
      });
   }
   elsif( $type eq "m.notice" ) {
      ( $etype, $args ) = ( "matrix.notice" => {
         name => $member->displayname,
         user_id => $member_id,
         text => $text,
      });
   }
   elsif( $type eq "m.emote" ) {
      ( $etype, $args ) = ( "matrix.emote" => {
         name => $member->displayname,
         user_id => $member_id,
         text => $text,
      });
   }
   else {
      ( $etype, $args ) = ( "text" => {
         text => "Unrecognised Matrix event msgtype <$type>"
      });
   }

   $self->push_displayevent( $etype, $args, time => $tstamp );
   $self->bump_level( 2 );
}

sub on_membership
{
   my $self = shift; shift;
   my ( $member, $event, $subject, %changes ) = @_;
   my $member_id = $member->user->user_id;

   $self->{latest_event_id} = $event->{event_id};

   $self->on_state_members( $self->{room}->live_state->get_events( "m.room.member" ) );

   my $tstamp = $event->{origin_server_ts} / 1000;

   if( my $membership = $changes{membership} ) {
      if( ( $membership->[0]//"") ne "join" and $membership->[1] eq "join" ) {
         $self->push_displayevent( "matrix.join" => {
            name    => $member->displayname,
            user_id => $member_id,
         }, time => $tstamp );
         $self->bump_level( 1 );
      }
      elsif( $membership->[0] eq "join" and !defined $membership->[1] ) {
         # $member->displayname won't be set any more
         $self->push_displayevent( "matrix.leave" => {
            name    => $changes{displayname}[0] // $member->displayname,
            user_id => $member_id,
         }, time => $tstamp );
         $self->bump_level( 1 );
      }
      elsif( $membership->[1] eq "invite" ) {
         $self->push_displayevent( "matrix.invite" => {
            name    => $member->displayname,
            user_id => $member_id,
            invitee => $subject->displayname,
            invitee_id => $subject->user->user_id,
         }, time => $tstamp );
         $self->bump_level( 1 );
      }
      else {
         $self->push_displayevent( "matrix.member" => {
            name    => $member->displayname,
            user_id => $member_id,
            subject => $subject->displayname // $subject->user->user_id,
            state   => "membership",
            oldval  => $membership->[0],
            newval  => $membership->[1],
         }, time => $tstamp );
      }

      return;
   }

   # As a text-only client we don't care about avatar_url
   delete $changes{avatar_url};

   if( my $displayname = $changes{displayname} ) {
      $self->push_displayevent( "matrix.rename" => {
         oldname => $displayname->[0],
         newname => $displayname->[1],
         user_id => $member_id,
      }, time => $tstamp );
      $self->bump_level( 1 );
   }
   elsif( my $level = $changes{level} ) {
      $self->push_displayevent( "matrix.member" => {
         name    => $member->displayname,
         user_id => $member_id,
         subject => $subject->displayname // $subject->user->user_id,
         state   => "level",
         oldval  => $level->[0],
         newval  => $level->[1],
      }, time => $tstamp );
      $self->bump_level( 1 );
   }
   elsif( keys %changes ) { # ignore "empty" changes e.g. avatar_url
      # TODO for debugging
      $self->push_displayevent( text => {
         text => "Member $member changed to ${\pp \%changes}"
      }, time => $tstamp );

      $self->bump_level( 2 );
   }
}

my %key_for_event = (
   "m.room.guest_access"       => "guest_access",
   "m.room.history_visibility" => "history_visibility",
   "m.room.join_rules"         => "join_rule",  # sic
   "m.room.name"               => "name",
   "m.room.topic"              => "topic",
);

sub on_state_changed
{
   my $self = shift; shift;
   my ( $member, $event, %changes ) = @_;
   my $member_id = $member ? $member->user->user_id : undef;

   my $type = $event->{type};

   $self->{latest_event_id} = $event->{event_id};

   my $watches = $self->{state_watches};
   if( my $code = $watches->{$type} ) {
      $code->( $self, $event );
   }

   my $tstamp = $event->{origin_server_ts} / 1000;

   # TODO: m.room.create event arrives before the m.room.member event for its
   #   creator, so we don't yet have a way to display it
   return if $type eq "m.room.create";

   # As a text-only client we don't care about the room avatar
   return if $type eq "m.room.avatar_url";

   if( my $key = $key_for_event{$type} ) {
      return unless my $values = $changes{$key};

      $self->push_displayevent( "matrix.state" => {
         name    => $member ? $member->displayname : undef,
         user_id => $member_id,
         state   => $key,
         oldval  => $values->[0],
         newval  => $values->[1],
      }, time => $tstamp );

      $self->bump_level( 1 );
   }
   else {
      # TODO for debugging
      $self->push_displayevent( text => {
         text => "Member $member changed room state $type to ${\pp \%changes}"
      }, time => $tstamp );
   }
}

sub on_members_typing
{
   my $self = shift; shift;
   my @members = @_;

   my $widget = $self->get_widget_typing;

   if( !@members ) {
      $widget->set_prop_text( "" );
      return;
   }

   $widget->set_prop_text( "(Typing: " .
      join( ", ", map { $_->displayname // $_->user->user_id } @members ) .
      ")"
   );
}

sub on_read_receipt
{
   my $self = shift; shift;
   my ( $member, $event_id, $content ) = @_;

   # TODO: maybe someday we'll care about other users, but not today
   my $my_userid = $self->{net}{matrix}->myself->user_id;
   return unless $member->user->user_id eq $my_userid;

   if( $event_id eq $self->{latest_event_id} ) {
      # Reset level to zero; because another client has read up until latest
      # message
      $self->set_prop_level( 0 );
   }
}

sub method_reset_level
{
   my $self = shift;
   $self->SUPER::method_reset_level;

   my $room = $self->{room};

   my $f = $room->send_read_receipt(
      event_id => $self->{latest_event_id},
   );
   $room->adopt_future( $f );
}

sub enter_text
{
   my $self = shift;
   my ( $text ) = @_;

   my $content = build_formatted_message( parse_markdownlike( $text ) );

   my $room = $self->{room};
   my $f = $room->send_message( type => "m.text", %$content );

   $room->adopt_future( $f );
}

sub command_leave
   : Command_description("Leave the room")
{
   my $self = shift;
   my ( $cinv ) = @_;

   my $matrix = $self->{net}{matrix};

   $matrix->leave_room( $self->{room}->room_id );

   return;
}

sub command_say
   : Command_description("Quote text directly as a text message")
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $text ) = @_;

   # No markdown parsing

   $self->enter_text( $text );

   return;
}

sub command_me
   : Command_description("Send an emote message")
   : Command_arg('text', eatall => 1)
{
   my $self = shift;
   my ( $text ) = @_;

   my $content = build_formatted_message( parse_markdownlike( $text ) );

   my $room = $self->{room};
   my $f = $room->send_message( type => "m.emote", %$content );

   $room->adopt_future( $f );

   return;
}

sub get_widget_topic
{
   my $self = shift;
   return $self->{topic_widget} //= $self->{registry}->construct(
      "Circle::Widget::Entry",
      classes => [qw( topic )],
      # on_enter => sub { $self->topic( $_[0] ) },
   );
}

sub get_widget_displayname
{
   my $self = shift;
   return $self->{displayname_widget} //= $self->{registry}->construct(
      "Circle::Widget::Label",
   );
}

sub get_widget_permission
{
   my $self = shift;
   return $self->{permission_widget} //= $self->{registry}->construct(
      "Circle::Widget::Label",
   );
}

sub get_widget_typing
{
   my $self = shift;
   return $self->{typing_widget} //= $self->{registry}->construct(
      "Circle::Widget::Label",
      classes => [qw( transient )],
   );
}

sub get_widget_membercount
{
   my $self = shift;
   return $self->{membercount_widget} //= $self->{registry}->construct(
      "Circle::Widget::Label",
   );
}

sub make_widget_pre_scroller
{
   my $self = shift;
   my ( $box ) = @_;

   $box->add( $self->get_widget_topic );
}

sub get_widget_statusbar
{
   my $self = shift;

   my $registry = $self->{registry};
   my $net = $self->{net};

   my $statusbar = $registry->construct(
      "Circle::Widget::Box",
      classes => [qw( status )],
      orientation => "horizontal",
   );

   $statusbar->add( $net->get_widget_netname );

   $statusbar->add( $self->get_widget_displayname );

   $statusbar->add( $self->get_widget_permission );

   $statusbar->add_spacer( expand => 1 );

   $statusbar->add( $self->get_widget_typing );

   $statusbar->add( $self->get_widget_membercount );

   return $statusbar;
}

0x55AA;
