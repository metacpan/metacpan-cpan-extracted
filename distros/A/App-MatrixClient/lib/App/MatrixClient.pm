#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::MatrixClient;

use strict;
use warnings;

our $VERSION = '0.01';

use curry;

use Event::Distributor 0.04; # actions
use IO::Async::Loop;

use Tickit::Async;
use Tickit::Console 0.07; # time/datestamp format
use Tickit::Widgets qw( FloatBox Static VBox );
use String::Tagged 0.11; # ->clone

# Presence list scrolling requires Tickit 0.48 to actually work properly
use Tickit 0.48;

use Data::Dump 'pp';

use App::MatrixClient::RoomTab;
use App::MatrixClient::Matrix;

=head1 NAME

C<App::MatrixClient> - a C<Tickit>-based terminal UI client for F<Matrix>

=head1 EMITTED SIGNALS

   * start()

   do_upload( file => $file, content_type => $type )

   do_get_displayname( ?$user_id ) => $displayname
   do_set_displayname( $displayname )

   do_set_presence( $state, ?$msg )

   do_add_alias( $alias, $room_id )
   do_del_alias( $alias )

   do_room_create( $name ) => $event
   do_room_join( $name )
   do_room_leave( $room_id )
   do_room_msg( $room_id, $message )

=head1 CONSUMED SIGNALS

   * log( $str )
   * logerr( $str )

   on_invite( $event )

   on_user_displayname( $user, $oldname )
   on_user_presence( $user )

   on_room_new( $room )
   on_room_del( $room )

=head1 CONSTRUCTOR

=cut

=head2 new

   $client = App::MatrixClient->new( %args )

Takes the following named arguments:

=over 8

=item loop => IO::Async::Loop

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = $args{loop} // IO::Async::Loop->new;
   my $dist = $args{dist} // Event::Distributor->new;

   $dist->declare_signal( $_ ) for
      qw( start log logerr );

   my $console = Tickit::Console->new(
      timestamp_format => String::Tagged->new_tagged( "%H:%M ", fg => undef )
         ->apply_tag( 0, 5, fg => "hi-blue" ),
      datestamp_format => String::Tagged->new_tagged( "-- day is now %Y/%m/%d --",
         fg => "grey" ),
   );

   my $self = bless {
      loop    => $loop,
      dist    => $dist,
      console => $console,

      ( map { $_ => $args{$_} } qw( server ssl ) ),
   }, $class;

   $dist->subscribe_sync( log => sub {
      shift;
      $self->log( @_ );
   });

   $dist->subscribe_sync( logerr => sub {
      shift;
      $self->append_line_colour( red => join " ", @_ );
   });

   $dist->subscribe_sync( $_ => $self->${\"curry::$_"} ) for
      qw( on_invite on_user_displayname on_user_presence on_room_new on_room_del );

   my $globaltab = $self->{globaltab} = $console->add_tab(
      name => "Global",
      on_line => sub {
         my ( $tab, $line ) = @_;
         $self->do_command( $line, $tab );
      },
   );

   $self->{tickit} = Tickit::Async->new( root => $console );
   $loop->add( $self->{tickit} );

   my %tabs_by_roomid;

   push @{ $self->{components} }, App::MatrixClient::Matrix->new(
      loop => $loop,
      dist => $dist,

      ( map { $_ => $args{$_} } qw( server ssl user_id password ) ),
   );

   {
      # Much hackery in here...
      my $entry = $console->{entry};

      my $old_on_key = Tickit::Widget::Entry->can( 'on_key' );
      no warnings 'redefine';
      *Tickit::Widget::Entry::on_key = sub {
         my $ret = $old_on_key->( @_ );
         if( $ret and $_[0] == $entry ) {
            my $tab = $console->active_tab;
            $tab->still_typing if $tab->can( 'still_typing' );
         }
         return $ret;
      };
   }

   return $self;
}

sub run
{
   my $self = shift;

   local $SIG{__WARN__} = sub {
      my $msg = join " ", @_;
      $self->append_line_colour( orange => join " ", @_ );
   };

   $self->{dist}->fire_sync( start => );

   $self->{tickit}->run;
}


# Signal handlers

sub on_invite
{
   my $self = shift;
   my ( undef, $event ) = @_;

   $self->{globaltab}->append_line( String::Tagged->new
      ->append_tagged( " ** " )
      ->append_tagged( $event->{inviter}, fg => "grey" )
      ->append_tagged( " invites you to " )
      ->append_tagged( $event->{room_id}, fg => "cyan" )
   );

   # TODO: consider whether we should look up user displayname, room name,
   # etc...
}

sub on_user_displayname
{
   my $self = shift;
   my ( undef, $user, $oldname ) = @_;

   $self->append_line_colour( yellow => " * $oldname is now called " . make_username($user) );
}

sub on_user_presence
{
   my $self = shift;
   my ( undef, $user ) = @_;

   $self->append_line_colour( yellow => " * " . make_username($user) . " now " . $user->presence );
}

sub on_room_new
{
   my $self = shift;
   my ( undef, $room ) = @_;

   $self->new_room( $room );
}

sub on_room_del
{
   my $self = shift;
   my ( undef, $room ) = @_;

   my $roomtab = delete $self->{tabs_by_roomid}{ $room->room_id } or return;

   $self->{console}->remove_tab( $roomtab );
}


# Internal API

sub append_line_colour
{
   my $self = shift;
   my ( $fg, $text ) = @_;

   $self->{globaltab}->append_line(
      String::Tagged->new( $text )->apply_tag( 0, -1, fg => $fg )
   );
}

sub log
{
   my $self = shift;
   my ( $line ) = @_;

   $self->append_line_colour( green => ">> $line" );
}

sub new_room
{
   my $self = shift;
   my ( $room ) = @_;

   my $floatbox;
   my $headline;

   # Until Tickit::Widget::Tabbed supports a 'tab_class' argument to add_tab,
   # we'll have to cheat
   no warnings 'redefine';
   local *Tickit::Widget::Tabbed::TAB_CLASS = sub { "App::MatrixClient::RoomTab" };

   my $roomtab = $self->{console}->add_tab(
      name => $room->room_id,
      make_widget => sub {
         my ( $scroller ) = @_;

         my $vbox = Tickit::Widget::VBox->new;

         $vbox->add( $headline = Tickit::Widget::Static->new(
               text => "",
               style => { bg => "blue" },
            ),
            expand => 0
         );
         $vbox->add( $scroller, expand => 1 );

         return $floatbox = Tickit::Widget::FloatBox->new(
            base_child  => $vbox,
         );
      },
      on_line => sub {
         my ( $tab, $line ) = @_;
         if( $line =~ s{^/}{} ) {
            my ( $cmd, @args ) = split m/\s+/, $line;
            if( my $code = $tab->can( "cmd_$cmd" ) ) {
               $room->adopt_future( $tab->$code( @args ) );
            }
            else {
               $self->do_command( $line, $tab );
            }
         }
         else {
            $room->adopt_future( $room->send_message( $line ) );
            $room->typing_stop;
         }
      },
   );

   $self->{tabs_by_roomid}->{ $room->room_id } = $roomtab;

   $roomtab->_setup(
      room     => $room,
      dist     => $self->{dist},
      url_base => ( $self->{ssl} ? "https" : "http" ) . "://$self->{server}",
      floatbox => $floatbox,
      headline => $headline,
   );
}

sub make_username
{
   # function
   my ( $user ) = @_;

   if( defined $user->displayname ) {
      return "${\$user->displayname} (${\$user->user_id})";
   }
   else {
      return $user->user_id;
   }
}

sub do_command
{
   my $self = shift;
   my ( $line, $tab ) = @_;

   # For now all commands are simple methods on __PACKAGE__
   my ( $cmd, @args ) = split m/\s+/, $line;

   $tab->append_line(
      String::Tagged->new( '$ ' . join " ", $cmd, @args )
         ->apply_tag( 0, -1, fg => "cyan" )
   );

   my $method = "cmd_$cmd";
   $self->{cmd_f} = Future->call( sub { $self->$method( @args ) } )
      ->on_done( sub {
         my @result = @_;
         $tab->append_line( $_ ) for @result;

         undef $self->{cmd_f};
      })
      ->on_fail( sub {
         my ( $failure ) = @_;

         $tab->append_line(
            String::Tagged->new( "Error: $failure" )
               ->apply_tag( 0, -1, fg => "red" )
         );

         undef $self->{cmd_f};
      });
}


## Command handlers

sub cmd_dname_get
{
   my $self = shift;
   my ( $user_id ) = @_;

   $self->{dist}->fire_async( do_get_displayname => $user_id );
}

sub cmd_dname_set
{
   my $self = shift;
   my ( $name ) = @_;

   $self->{dist}->fire_async( do_set_displayname => $name )
      ->then_done( "Set" );
}

sub cmd_offline
{
   my $self = shift;

   $self->{dist}->fire_async( do_set_presence => "offline", @_ )
      ->then_done( "Set" );
}

sub cmd_busy
{
   my $self = shift;

   $self->{dist}->fire_async( do_set_presence => "unavailable", "Busy" )
      ->then_done( "Set" );
}

sub cmd_away
{
   my $self = shift;

   $self->{dist}->fire_async( do_set_presence => "unavailable", "Away" )
      ->then_done( "Set" );
}

sub cmd_online
{
   my $self = shift;

   $self->{dist}->fire_async( do_set_presence => "online", @_ )
      ->then_done( "Set" );
}

sub cmd_createroom
{
   my $self = shift;
   my ( $room_name ) = @_;

   $self->{dist}->fire_async( do_room_create => $room_name )->then( sub {
      my ( $response ) = @_;
      Future->done( pp($response) );
   });
}

sub cmd_join
{
   my $self = shift;
   my ( $room_name ) = @_;

   $self->{dist}->fire_async( do_room_join => $room_name )
      ->then_done( "Joined" );
}

sub cmd_leave
{
   my $self = shift;
   my ( $roomid ) = @_;

   $self->{dist}->fire_async( do_room_leave => $roomid )
      ->then_done( "Left" );
}

sub cmd_msg
{
   my $self = shift;
   my ( $roomid, @msg ) = @_;

   my $msg = join " ", @msg;

   $self->{dist}->fire_async( do_room_msg => $roomid, $msg )
      ->then_done(); # suppress output

}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
