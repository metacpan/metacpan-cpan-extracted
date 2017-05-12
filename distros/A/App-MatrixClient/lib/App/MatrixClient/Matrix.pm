#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::MatrixClient::Matrix;

use strict;
use warnings;

our $VERSION = '0.01';

use Future;
use Net::Async::Matrix;
use curry;

=head1 EMITTED SIGNALS

   log( $str )
   logerr( $str )

   * on_invite( $event )

   * on_user_displayname( $user, $oldname )
   * on_user_presence( $user )

   * on_room_new( $room )
   * on_room_del( $room )

=head1 CONSUMED SIGNALS

   start

   * do_upload( file => $file, content_type => $type )

   * do_get_displayname( ?$user_id ) => $displayname
   * do_set_displayname( $displayname )

   * do_set_presence( $state, ?$msg )

   * do_add_alias( $alias, $room_id )
   * do_del_alias( $alias )

   * do_room_create( $name ) => $event
   * do_room_join( $name )
   * do_room_leave( $room_id )
   * do_room_msg( $room_id, $message )

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = $args{loop};
   my $dist = $args{dist};

   my $self = bless {
      loop => $loop,
      dist => $dist,

      ( map { $_ => $args{$_} } qw( user_id password ) ),
   }, $class;

   $dist->declare_signal( $_ ) for
      qw( on_invite on_user_displayname on_user_presence on_room_new on_room_del );

   $dist->declare_action( $_ ) for qw(
      do_upload do_get_displayname do_set_displayname do_set_presence
      do_add_alias do_del_alias
      do_room_create do_room_join do_room_leave do_room_msg
   );

   $dist->subscribe_async( $_ => $self->${\"curry::$_"} ) for qw(
      start
      do_upload do_get_displayname do_set_displayname do_set_presence
      do_add_alias do_del_alias
      do_room_create do_room_join do_room_leave do_room_msg
   );

   $self->{matrix} = Net::Async::Matrix->new(
      server => $args{server},
      ( $args{ssl} ? (
         SSL             => 1,
         SSL_verify_mode => 0,
      ) : () ),

      on_log => $dist->curry::fire_sync( 'log' ),

      on_presence => sub {
         my ( undef, $user, %changes ) = @_;

         if( exists $changes{presence} ) {
            $dist->fire_sync( on_user_presence => $user );
         }
         elsif( exists $changes{displayname} ) {
            $dist->fire_sync( on_user_displayname => $user, $changes{username}[0] );
         }
      },
      on_room_new => sub {
         my ( undef, $room ) = @_;
         $dist->fire_sync( on_room_new => $room );
      },
      on_room_del => sub {
         my ( undef, $room ) = @_;
         $dist->fire_sync( on_room_del => $room );
      },
      on_error => sub {
         my ( undef, $failure, $name ) = @_;

         $dist->fire_sync( logerr => "Error: $failure" );

         if( $name eq "http" ) {
            my ( undef, undef, undef, $response, $request ) = @_;
            $dist->fire_sync( logerr => "  ".$request->uri->path_query );
            $dist->fire_sync( logerr => "  ".$response->content );
         }
      },

      on_invite => sub {
         my ( undef, $event ) = @_;
         $dist->fire_sync( on_invite => $event );
      },
   );

   $loop->add( $self->{matrix} );

   return $self;
}

# Signal handlers

sub start
{
   my $self = shift;

   defined $self->{user_id} or
      return Future->done;

   print STDERR "Logging in as $self->{user_id}...\n";
   $self->{matrix}->login(
      map { $_ => $self->{$_} } qw( user_id password )
   );
}

sub do_upload
{
   my $self = shift;
   my ( undef, %args ) = @_;

   $self->{matrix}->upload(
      file         => $args{file},
      content_type => $args{content_type},
   );
}

sub do_get_displayname
{
   my $self = shift;
   my ( undef, $user_id ) = @_;

   $self->{matrix}->get_displayname( $user_id );
}

sub do_set_displayname
{
   my $self = shift;
   my ( undef, $displayname ) = @_;

   $self->{matrix}->set_displayname( $displayname );
}

sub do_set_presence
{
   my $self = shift;
   my ( undef, $state, $msg ) = @_;

   $self->{matrix}->set_presence( $state, $msg );
}

sub do_add_alias
{
   my $self = shift;
   my ( undef, $alias, $room_id ) = @_;

   $self->{matrix}->add_alias( $alias, $room_id );
}

sub do_del_alias
{
   my $self = shift;
   my ( undef, $alias ) = @_;

   $self->{matrix}->delete_alias( $alias );
}

sub do_room_create
{
   my $self = shift;
   my ( undef, $name ) = @_;

   $self->{matrix}->create_room( $name );
}

sub do_room_join
{
   my $self = shift;
   my ( undef, $name ) = @_;

   $self->{matrix}->join_room( $name );
}

sub do_room_leave
{
   my $self = shift;
   my ( undef, $room_id ) = @_;

   $self->{matrix}->leave_room( $room_id );
}

sub do_room_msg
{
   my $self = shift;
   my ( undef, $room_id, $msg ) = @_;

   $self->{matrix}->send_room_message( $room_id, $msg );
}

0x55AA;
