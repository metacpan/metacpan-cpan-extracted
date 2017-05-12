#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2014-2017 -- leonerd@leonerd.org.uk

package Circle::Net::Matrix;

use strict;
use warnings;
use base qw( Circle::Net );

our $VERSION = '0.03';

require Circle;
Circle->VERSION( '0.142470' );  # require late-loading of Tangence::Class

use constant NETTYPE => 'matrix';

use Circle::Widget::Box;
use Circle::Widget::Label;

use Data::Dump qw( pp );
use Scalar::Util qw( weaken );

=head1 NAME

C<Circle::Net::Matrix> - use C<Circle> as a I<Matrix> client

=head1 SYNOPSIS

On the global tab:

 /networks add -type matrix Matrix

On the newly-added "Matrix" tab:

 /set homeserver example.com
 /set user_id @me:example.com
 /set access_token MDAxABCDE...

 /connect

(for now you'll have to log in and steal and access token from another Matrix
client; for example L<App::MatrixTool>).

=cut

# To allow for out-of-tree development, use an inline Tangence class
# declaration instead of a .tan file
#
# class Circle.Net.Matrix {
#   isa Circle.WindowItem;
# }

sub DECLARE_TANGENCE
{
   Tangence::Class->declare( __PACKAGE__,
      superclasses => [qw( Circle::WindowItem )],
   );

   # Also load the other classes
   require Circle::Net::Matrix::Room;
   Circle::Net::Matrix::Room->DECLARE_TANGENCE;

   require Net::Async::Matrix;
   Net::Async::Matrix->VERSION( '0.18003' );
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

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{root} = $args{root};
   my $loop = $self->{loop} = $args{loop};

   # For WindowItem
   $self->set_prop_tag( $args{tag} );

   weaken( my $weakself = $self );
   my $matrix = $self->{matrix} = Net::Async::Matrix->new(
      on_log => sub { }, # TODO
      on_presence => $self->WEAKSELF_EVAL( 'on_presence' ),
      on_room_new => $self->WEAKSELF_EVAL( 'on_room_new' ),
      on_room_del => $self->WEAKSELF_EVAL( 'on_room_del' ),

      on_error => $self->WEAKSELF_EVAL( 'on_error' ),
   );

   $loop->add( $matrix );

   $self->set_network_status( "disconnected" );

   return $self;
}

sub on_error
{
   my $self = shift; shift;
   my ( $message ) = @_;

   $self->push_displayevent( error => { text => $message } );
   $self->bump_level( 3 );
}

sub parent
{
   my $self = shift;
   return $self->{root};
}

sub enumerable_name
{
   my $self = shift;
   return $self->get_prop_tag;
}

sub commandable_parent
{
   my $self = shift;
   return $self->{root};
}

sub get_room_or_create
{
   my $self = shift;
   my ( $room ) = @_;

   my $room_id = $room->room_id;

   return $self->{rooms}{$room_id} if exists $self->{rooms}{$room_id};

   my $registry = $self->{registry};
   my $root = $self->{root};

   my $roomobj = $registry->construct(
      "Circle::Net::Matrix::Room",
      root => $root,
      net  => $self,
      room => $room,
   );
   $self->{rooms}{$room_id} = $roomobj;

   $root->broadcast_sessions( new_item => $roomobj );

   return $roomobj;
}

sub on_room_new
{
   my $self = shift; shift;
   my ( $room ) = @_;

   $self->get_room_or_create( $room );
}

sub on_room_del
{
   my $self = shift; shift;
   my ( $room ) = @_;

   my $roomobj = delete $self->{rooms}{$room->room_id} or return;
   
   $self->{root}->broadcast_sessions( delete_item => $roomobj );
   $roomobj->destroy;
}

sub on_presence
{
   my $self = shift; shift;
   my ( $user, %changes ) = @_;

   # Ignore for now
   #$self->push_displayevent( "text", {
   #      text => "User ${\$user->user_id} presence change " . pp(\%changes),
   #});
}

__PACKAGE__->APPLY_Setting( homeserver =>
   description => "Hostname of the homeserver",
   type        => 'str',
);

__PACKAGE__->APPLY_Setting( user_id =>
   description => "User ID to use",
   type        => 'str',
);

__PACKAGE__->APPLY_Setting( access_token =>
   description => "Access Token of the user",
   type        => 'str',
);

__PACKAGE__->APPLY_Setting( initial_backlog =>
   description => "Initial size of backlog to request per room",
   type        => "int",
   default     => 100,
);

sub command_connect
   : Command_description("Connect to the homeserver")
   : Command_arg('homeserver?')
{
   my $self = shift;
   my ( $homeserver, $cinv ) = @_;

   $homeserver = $self->{homeserver} unless defined $homeserver;

   my $matrix = $self->{matrix};
   $matrix->configure(
      server           => $homeserver,
      first_sync_limit => $self->{initial_backlog},
   );

   # TODO: would be nice if Circle could cope with Future-returning
   # command subs...

   $self->push_displayevent( "status", { text => "logging in" } );
   $self->set_network_status( "logging in" );

   my $f = $matrix->login(
      user_id      => $self->{user_id},
      access_token => $self->{access_token},
   )->on_done( sub {
      $self->push_displayevent( "status", { text => "syncing..." } );
      $self->set_network_status( "syncing" );

      $matrix->start->on_done( sub {
         $self->set_network_status( "" );
      });
   });

   $matrix->adopt_future( $f );

   return ();
}

sub command_join
   : Command_description("Join a named room")
   : Command_arg('roomname')
{
   my $self = shift;
   my ( $roomname, $cinv ) = @_;

   my $matrix = $self->{matrix};

   $matrix->join_room( $roomname );

   return;
}

###
# Widgets
###

sub get_widget_my_displayname
{
   my $self = shift;

   return $self->{widget_displayname} ||= do {
      my $registry = $self->{registry};

      my $widget = $registry->construct(
         "Circle::Widget::Label",
         classes => [qw( nick )],
      );

      $widget->set_prop_text( $self->{matrix}->myself->displayname );

      $widget;
   };
}

sub get_widget_statusbar
{
   my $self = shift;

   my $registry = $self->{registry};

   my $statusbar = $registry->construct(
      "Circle::Widget::Box",
      classes => [qw( status )],
      orientation => "horizontal",
   );

   $statusbar->add( $self->get_widget_netname );

   $statusbar->add( $self->get_widget_my_displayname );

   # $statusbar->add( $self->get_widget_presence );

   return $statusbar;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
