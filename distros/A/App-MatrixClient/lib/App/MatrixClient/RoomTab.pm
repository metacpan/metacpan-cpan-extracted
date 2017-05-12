package App::MatrixClient::RoomTab;

use 5.014; # s///r
use strict;
use warnings;

use base qw( Tickit::Console::Tab );

use List::Util 1.33 qw( any );
use POSIX qw( strftime );

use Convert::Color::XTerm;
use Future;
use Image::ExifTool;
use IO::Async::Timer::Countdown;
use Net::Async::Matrix::Utils qw( parse_formatted_message );

use Tickit::Widgets qw( Frame GridBox ScrollBox Static VBox );
Tickit::Widget::Frame->VERSION( '0.31' ); # bugfix to linetypes in constructor

use constant TYPING_GRACE_SECONDS => 5;

my %PRESENCE_STATE_TO_COLOUR = (
   offline     => "grey",
   unavailable => "orange",
   online      => "green",
);

sub _setup
{
   my $self = shift;
   my %args = @_;

   my $room     = $self->{room} = $args{room};
   my $floatbox = $args{floatbox};

   $self->{$_} = $args{$_} for qw( dist url_base );

   $self->{headline} = $args{headline};

   $self->{presence_table} = my $presence_table = Tickit::Widget::GridBox->new(
      col_spacing => 1,
   );

   $self->{presence_userids} = \my @presence_userids;
   $presence_table->add( 0, 0, Tickit::Widget::Static->new( text => "Name" ) );
   $presence_table->add( 0, 1, Tickit::Widget::Static->new( text => "Since" ) );
   $presence_table->add( 0, 2, Tickit::Widget::Static->new( text => "Lvl" ) );

   # Create an abstract widget tree during initial loading to avoid the
   # O(n^2) overhead of resizing the gridbox after -every- user is added.
   my $vbox = Tickit::Widget::VBox->new;

   $vbox->add(
      Tickit::Widget::ScrollBox->new(
         child => $presence_table,
         vertical   => "on_demand",
         horizontal => 0,
      ),
      expand => 1,
   );

   $vbox->add(
      my $presence_summary = Tickit::Widget::Static->new( text => "" )
   );

   my $presence_float;
   my $visible = 0;
   $self->bind_key( 'F2' => sub {
      $visible ? ( $presence_float->hide, $visible = 0 )
               : ( $presence_float->show, $visible = 1 );
   });

   $room->configure(
      on_synced_state => sub {
         $self->set_name( $room->name );
         $self->update_headline;

         # Fetch initial presence state of users
         foreach my $member ( $room->joined_members ) {
            $self->update_member_presence( $member );
         }

         $presence_summary->set_text(
            sprintf "Total: %d users", scalar $room->joined_members
         );

         $room->paginate_messages( limit => 150 );

         # Only now should we add the presence table to the floatbox
         $presence_float = $floatbox->add_float(
            child => Tickit::Widget::Frame->new(
               style => {
                  linetype => "none",
                  linetype_left => "single",

                  frame_fg => "white", frame_bg => "purple",
               },
               child => $vbox,
            ),

            top => 0, bottom => -1, right => -1,
            left => -44,

            # Initially hidden
            hidden => 1,
         );
      },

      on_message => sub {
         my ( undef, $member, $content, $event ) = @_;

         $self->append_line( $self->format_message( $content, $member ),
            indent => 10,
            time   => ( $event->{origin_server_ts} // $content->{hsob_ts} ) / 1000,
         );
      },
      on_back_message => sub {
         my ( undef, $member, $content, $event ) = @_;

         $self->prepend_line( $self->format_message( $content, $member ),
            indent => 10,
            time   => ( $event->{origin_server_ts} // $content->{hsob_ts} ) / 1000,
         );
      },

      on_membership => sub {
         my ( undef, $action_member, $event, $target_member, %changes ) = @_;

         $self->update_member_presence( $target_member );

         if( $changes{membership} and ( $changes{membership}[1] // "" ) eq "invite" ) {
            $self->append_line( format_invite( $action_member, $target_member ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         elsif( $changes{membership} ) {
            # On a LEAVE event they no longer have a displayname
            $target_member->displayname = $changes{displayname}[0] if !defined $changes{membership}[1];

            $self->append_line( format_membership( $changes{membership}[1] // "leave", $target_member ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         elsif( $changes{displayname} ) {
            $self->append_line( format_displayname_change( $target_member, @{ $changes{displayname} } ) );
         }
         elsif( $changes{level} ) {
            $self->append_line( format_memberlevel_change( $action_member, $target_member, $changes{level}[1] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }

         $presence_summary->set_text(
            sprintf "Total: %d users", scalar $room->joined_members
         );
      },
      on_back_membership => sub {
         my ( undef, $action_member, $event, $target_member, %changes ) = @_;

         if( $changes{membership} and ( $changes{membership}[0] // "" ) eq "invite" ) {
            $self->prepend_line( format_invite( $action_member, $target_member ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         elsif( $changes{membership} ) {
            # On a JOIN event they don't yet have a displayname
            $target_member->displayname = $changes{displayname}[0] if $changes{membership}[0] // '' eq "join";

            $self->prepend_line( format_membership( $changes{membership}[0] // "leave", $target_member ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         elsif( $changes{displayname} ) {
            $self->prepend_line( format_displayname_change( $target_member, reverse @{ $changes{displayname} } ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         elsif( $changes{level} ) {
            $self->prepend_line( format_memberlevel_change( $action_member, $target_member, $changes{level}[0] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
      },

      on_state_changed => sub {
         my ( undef, $member, $event, %changes ) = @_;

         if( $changes{name} ) {
            $self->append_line( format_name_change( $member, $changes{name}[1] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
            $self->set_name( $room->name );
         }
         if( $changes{aliases} ) {
            $self->append_line( $_,
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            ) for format_alias_changes( $event->{user_id}, @{ $changes{aliases} }[0,1] );
         }
         if( $changes{topic} ) {
            $self->append_line( format_topic_change( $member, $changes{topic}[1] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
            $self->update_headline;
         }
         foreach ( map { m/^level\.(.*)/ ? ( $1 ) : () } keys %changes ) {
            $self->append_line( format_roomlevel_change( $member, $_, $changes{"level.$_"}[1] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
      },
      on_back_state_changed => sub {
         my ( undef, $member, $event, %changes ) = @_;

         if( $changes{name} ) {
            $self->prepend_line( format_name_change( $member, $changes{name}[0] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         if( $changes{aliases} ) {
            $self->prepend_line( $_,
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            ) for format_alias_changes( $event->{user_id}, @{ $changes{aliases} }[1,0] );
         }
         if( $changes{topic} ) {
            $self->prepend_line( format_topic_change( $member, $changes{topic}[0] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
         foreach ( map { m/^level\.(.*)/ ? ( $1 ) : () } keys %changes ) {
            $self->prepend_line( format_roomlevel_change( $member, $_, $changes{"level.$_"}[0] ),
               time => ( $event->{origin_server_ts} // $event->{ts} ) / 1000,
            );
         }
      },

      on_presence => sub {
         my ( undef, $member, %changes ) = @_;
         $self->update_member_presence( $member );
      },

      on_members_typing => sub {
         my ( undef, @members ) = @_;

         @members or
            $self->set_typing_line( undef ), return;

         my $s = String::Tagged->new
            ->append_tagged( " # currently typing: ", fg => "magenta" );

         my $last_member = pop @members;
         $s->append_tagged( format_displayname( $_ ) )
           ->append( ", " ) for @members;
         $s->append_tagged( format_displayname( $last_member ) );

         $self->set_typing_line( $s );
      },
   );

   $room->add_child( $self->{typing_grace_timer} = IO::Async::Timer::Countdown->new(
      delay => TYPING_GRACE_SECONDS,
      on_expire => sub { $room->typing_stop },
   ) );
}

sub append_line
{
   my $self = shift;

   if( $self->{typing_line} ) {
      my @after = $self->{scroller}->pop;
      $self->SUPER::append_line( @_ );
      $self->{scroller}->push( @after );
   }
   else {
      $self->SUPER::append_line( @_ );
   }
}

sub set_typing_line
{
   my $self = shift;
   my ( $line ) = @_;

   $self->{scroller}->pop if delete $self->{typing_line};

   # No timestamp
   local $self->{timestamp_format};
   $self->SUPER::append_line( $self->{typing_line} = $line ) if $line;
}

sub still_typing
{
   my $self = shift;

   my $timer = $self->{typing_grace_timer};
   if( $timer->is_running ) {
      $timer->reset;
   }
   else {
      $self->{room}->typing_start;
      $timer->start;
   }
}

sub update_headline
{
   my $self = shift;
   my $room = $self->{room};

   $self->{headline}->set_text( $room->topic // "" );
}

sub update_member_presence
{
   my $self = shift;
   my ( $member ) = @_;

   return; # TODO

   my $user = $member->user;
   my $user_id = $user->user_id;

   my $presence_userids = $self->{presence_userids};

   # Find an existing row if we can
   my $rowidx;
   $presence_userids->[$_] eq $user_id and $rowidx = $_, last
      for 0 .. $#$presence_userids;

   my $presence_table = $self->{presence_table};

   if( defined $rowidx and !defined $member->membership ) {
      splice @$presence_userids, $rowidx, 1, ();
      $presence_table->delete_row( $rowidx+1 );
      return;
   }

   my ( $w_name, $w_since, $w_power );
   if( defined $rowidx ) {
      ( $w_name, $w_since, $w_power ) = $presence_table->get_row( $rowidx+1 );
   }
   else {
      $presence_table->append_row( [
         $w_name  = Tickit::Widget::Static->new( text => "" ),
         $w_since = Tickit::Widget::Static->new( text => "" ),
         $w_power = Tickit::Widget::Static->new( text => "-", class => "level" ),
      ] );
      push @$presence_userids, $user_id;
   }

   $w_name->set_style( fg => $PRESENCE_STATE_TO_COLOUR{$user->presence} )
      if defined $user->presence;

   my $dname = defined $member->displayname ? $member->displayname : "[".$user->user_id."]";
   $dname = substr( $dname, 0, 17 ) . "..." if length $dname > 20;
   $w_name->set_text( $dname );

   if( defined $user->last_active ) {
      $w_since->set_text( strftime "%Y/%m/%d %H:%M", localtime $user->last_active );
   }
   else {
      $w_since->set_text( "    --    " );
   }

   if( defined( my $level = $self->{room}->member_level( $user_id ) ) ) {
      $w_power->set_text( $level );
      $w_power->set_style( fg => ( $level > 0 ) ? "yellow" : undef );
   }
   else {
      $w_power->set_text( "-" );
   }
}

sub format_message
{
   my $self = shift;
   my ( $content, $member ) = @_;

   my $s = String::Tagged->new;

   my $formatted_body = parse_formatted_message( $content );
   my $msgtype = $content->{msgtype};

   # Convert $body into something Tickit::Widget::Scoller will understand
   my $body = String::Tagged->clone( $formatted_body,
      only_tags => [qw( bold under italic reverse fg bg )],
      convert_tags => {
         bold    => "b",
         under   => "u",
         italic  => "i",
         reverse => "rv",
         fg      => sub { fg => $_[1]->as_xterm->index },
         bg      => sub { bg => $_[1]->as_xterm->index },
      },
   );

   my $content_url;
   if( $content->{url} ) {
      my $uri = URI->new( $content->{url} );
      if( $uri->scheme eq "mxc" ) {
         $content_url = $self->{url_base} . "/_matrix/media/v1/download/" . $uri->authority . $uri->path;
      }
      else {
         $content_url = "$uri";
      }
   }

   if( $msgtype eq "m.text" ) {
      return $s
         ->append_tagged( "<", fg => "magenta" )
         ->append( format_displayname( $member ) )
         ->append_tagged( "> ", fg => "magenta" )
         ->append       ( $body );
   }
   elsif( $msgtype eq "m.emote" ) {
      return $s
         ->append_tagged( "* ", fg => "magenta" )
         ->append( format_displayname( $member ) )
         ->append_tagged( " " )
         ->append       ( $body );
   }
   elsif( $msgtype eq "m.notice" ) {
      return $s
         ->append_tagged( "--", fg => "red" )
         ->append( format_displayname( $member ) )
         ->append_tagged( "-- ", fg => "red" )
         ->append       ( $body );
   }
   # Handle all the four attachment-style messages similarly
   elsif( any { $msgtype eq $_ } qw( m.image m.audio m.video m.file ) ) {
      my $info = $content->{info} // $content->{body}; # cope with older message format

      $s->append_tagged( "[" )
        ->append( format_displayname( $member ) )
        ->append_tagged( "] " )
        ->append_tagged( $msgtype =~ s/^m\.//r, fg => "yellow" );

      if( defined $info->{mimetype} ) {
         $s->append_tagged( "; $info->{mimetype}", fg => "grey" );
      }
      if( defined( my $bytes = $info->{size} ) ) {
         $s->append_tagged( "; " . format_bytes( $bytes ), fg => "grey" );
      }

      if( $msgtype eq "m.image" ) {
          $s->append_tagged( " ($info->{w}x$info->{h})", fg => "grey" );
      }
      elsif( $msgtype eq "m.audio" ) {
          $s->append_tagged( " (" . format_msec( $info->{duration} ) . ")", fg => "grey" );
      }
      elsif( $msgtype eq "m.video" ) {
          $s->append_tagged( " ($info->{w}x$info->{h}, " . format_msec( $info->{duration} ) . ")", fg => "grey" );
      }

      $s->append_tagged( " " )
        ->append_tagged( $content_url, fg => "hi-blue", u => 1 );

      # filename comes from content, not info
      if( defined $content->{filename} ) {
         $s->append_tagged( " - $content->{filename}" );
      }

      return $s;
   }
   else {
      return $s
         ->append_tagged( "[" )
         ->append_tagged( $msgtype, fg => "yellow" )
         ->append_tagged( " from " )
         ->append( format_displayname( $member ) )
         ->append_tagged( "]: " )
         ->append       ( Data::Dump::pp $body );
   }
}

sub format_bytes
{
   my ( $v ) = @_;
   return sprintf "%d bytes", $v if $v < 1024; $v /= 1024;
   return sprintf "%.1f KiB", $v if $v < 1024; $v /= 1024;
   return sprintf "%.1f MiB", $v if $v < 1024; $v /= 1024;
   return sprintf "%.1f GiB", $v if $v < 1024; $v /= 1024;
   return sprintf "%.1f TiB", $v;
}

sub format_msec
{
   my ( $v ) = @_;
   return sprintf "%.3f sec", $v / 1000        if $v < 1000*10; $v /= 1000;
   return sprintf "%.1f sec", $v               if $v < 60;      $v /= 60;
   return sprintf "%dm%02ds", $v / 60, $v % 60 if $v < 60;      $v /= 60;
   return sprintf "%dh%02dm", $v / 60, $v % 60;
}

sub format_membership
{
   my ( $membership, $member ) = @_;

   my $s = String::Tagged->new;

   if( $membership eq "join" ) {
      return $s
         ->append_tagged( " => ", fg => "magenta" )
         ->append       ( format_displayname( $member, 1 ) )
         ->append       ( " " )
         ->append_tagged( "joined", fg => "green" );
   }
   elsif( $membership eq "leave" ) {
      return $s
         ->append_tagged( " <= ", fg => "magenta" )
         ->append       ( format_displayname( $member, 1 ) )
         ->append       ( " " )
         ->append_tagged( "left", fg => "red" );
   }
   else {
      return $s
         ->append       ( " [membership " )
         ->append_tagged( $membership, fg => "yellow" )
         ->append       ( "] " )
         ->append       ( format_displayname( $member, 1 ) );
   }
}

sub format_invite
{
   my ( $inviting_member, $invitee ) = @_;

   return String::Tagged->new
      ->append       ( " ** " )
      ->append       ( format_displayname( $inviting_member ) )
      ->append       ( " invites " )
      ->append_tagged( $invitee->user->user_id, fg => "grey" );
}

sub format_displayname_change
{
   my ( $member, $oldname, $newname ) = @_;

   my $s = String::Tagged->new
      ->append_tagged( "  ** ", fg => "magenta" );

   defined $oldname ?
      $s->append_tagged( $oldname, fg => "cyan" ) :
      $s->append_tagged( "[".$member->user->user_id."]", fg => "grey" );

   $s->append_tagged( " is now called " );

   defined $newname ?
      $s->append_tagged( $newname, fg => "cyan" ) :
      $s->append_tagged( "[".$member->user->user_id."]", fg => "grey" );

   return $s;
}

sub format_name_change
{
   my ( $member, $name ) = @_;

   return String::Tagged->new
      ->append       ( " ** " )
      ->append       ( format_displayname( $member ) )
      ->append       ( " sets the room name to: " )
      ->append_tagged( $name, fg => "cyan" );
}

sub format_alias_changes
{
   my ( $hs_domain, $old, $new ) = @_;

   my %deleted = map { $_ => 1 } @$old;
   delete $deleted{$_} for @$new;

   my %added   = map { $_ => 1 } @$new;
   delete $added{$_} for @$old;

   return
      ( map { String::Tagged->new
                     ->append_tagged( " # ", fg => "yellow" )
                     ->append_tagged( $hs_domain, fg => "red" )
                     ->append       ( " adds room alias " )
                     ->append_tagged( $_, fg => "cyan" ) } sort keys %added ),
      ( map { String::Tagged->new
                     ->append_tagged( " # ", fg => "yellow" )
                     ->append_tagged( $hs_domain, fg => "red" )
                     ->append       ( " deletes room alias " )
                     ->append_tagged( $_, fg => "cyan" ) } sort keys %deleted );
}

sub format_topic_change
{
   my ( $member, $topic ) = @_;

   return String::Tagged->new
      ->append       ( " ** " )
      ->append       ( format_displayname( $member ) )
      ->append       ( " sets the topic to: " )
      ->append_tagged( $topic, fg => "cyan" );
}

sub format_roomlevel_change
{
   my ( $member, $name, $level ) = @_;

   return String::Tagged->new
      ->append       ( " ** " )
      ->append       ( format_displayname( $member ) )
      ->append       ( " changes required level for " )
      ->append_tagged( $name, fg => "green" )
      ->append       ( " to " )
      ->append_tagged( $level, $level > 0 ? ( fg => "yellow" ) : () );
}

sub format_memberlevel_change
{
   my ( $changing_member, $target_member, $level ) = @_;

   return String::Tagged->new
      ->append       ( " ** " )
      ->append       ( format_displayname( $changing_member ) )
      ->append       ( " changes power level of " )
      ->append       ( format_displayname( $target_member ) )
      ->append       ( " to " )
      ->append_tagged( $level, $level > 0 ? ( fg => "yellow" ) : () );
}

sub format_displayname
{
   my ( $member, $full ) = @_;

   if( defined $member->displayname ) {
      my $s = String::Tagged->new
         ->append_tagged( $member->displayname, fg => "cyan" );

      $s->append_tagged( " [".$member->user->user_id."]", fg => "grey" ) if $full;

      return $s;
   }
   else {
      return String::Tagged->new
         ->append_tagged ( $member->user->user_id, fg => "grey" );
   }
}

sub cmd_me
{
   my $self = shift;
   my ( @args ) = @_;

   my $text = join " ", @args;
   my $room = $self->{room};

   $room->send_message( type => "m.emote", body => $text );
}

sub cmd_notice
{
   my $self = shift;
   my ( @args ) = @_;

   my $text = join " ", @args;
   my $room = $self->{room};

   $room->send_message( type => "m.notice", body => $text );
}

sub cmd_image
{
   my $self = shift;
   my ( $file ) = @_;

   my $dist = $self->{dist};
   my $room = $self->{room};

   unless( -e $file ) {
      $self->append_line( "File $file not found!" );
      return Future->done;
   }

   my $exifTool = Image::ExifTool->new;
   $exifTool->ImageInfo( $file );

   my $content_type = $exifTool->GetValue( 'MIMEType' ) //
      "application/octet-stream";

   $dist->fire_async( do_upload => file => $file, content_type => $content_type )->then( sub {
      my ( $uri ) = @_;

      $room->send_message( type => "m.image", body => "image attachment",
         url      => $uri,
         filename => $file,
         info     => {
            size     => $exifTool->GetValue( "FileSize", "ValueConv" ),
            w        => $exifTool->GetValue( "ImageWidth" ),
            h        => $exifTool->GetValue( "ImageHeight" ),
            mimetype => $content_type,
         },
      );
   });
}

sub cmd_audio
{
   my $self = shift;
   my ( $file ) = @_;

   my $dist = $self->{dist};
   my $room = $self->{room};

   unless( -e $file ) {
      $self->append_line( "File $file not found!" );
      return Future->done;
   }

   my $exifTool = Image::ExifTool->new;
   $exifTool->ImageInfo( $file );

   my $content_type = $exifTool->GetValue( "MIMEType" ) //
      "application/octet-stream";

   $dist->fire_async( do_upload => file => $file, content_type => $content_type )->then( sub {
      my ( $uri ) = @_;

      $room->send_message( type => "m.audio", body => "audio attachment",
         url      => $uri,
         filename => $file,
         info     => {
            size     => $exifTool->GetValue( "FileSize", "ValueConv" ),
            duration => int( $exifTool->GetValue( "Duration", "ValueConv" ) * 1000 ), # msec
            mimetype => $content_type,
         },
      );
   });
}

sub cmd_video
{
   my $self = shift;
   my ( $file ) = @_;

   my $dist = $self->{dist};
   my $room = $self->{room};

   unless( -e $file ) {
      $self->append_line( "File $file not found!" );
      return Future->done;
   }

   my $exifTool = Image::ExifTool->new;
   $exifTool->ImageInfo($file);

   my $content_type = $exifTool->GetValue( "MIMEType" ) //
      "application/octet-stream";

   $dist->fire_async( do_upload => file => $file, content_type => $content_type )->then( sub {
      my ( $uri ) = @_;

      $room->send_message( type => "m.video", body => "video attachment",
         url      => $uri,
         filename => $file,
         info     => {
            size     => $exifTool->GetValue( "FileSize", "ValueConv" ),
            duration => int( $exifTool->GetValue( "Duration", "ValueConv" ) * 1000 ), # msec
            w        => $exifTool->GetValue( "ImageWidth" ),
            h        => $exifTool->GetValue( "ImageHeight" ),
            mimetype => $content_type,
         },
      );
   });
}

sub cmd_file
{
   my $self = shift;
   my ( $file ) = @_;

   my $dist = $self->{dist};
   my $room = $self->{room};

   unless( -e $file ) {
      $self->append_line( "File $file not found!" );
      return Future->done;
   }

   my $exifTool = Image::ExifTool->new;
   $exifTool->ImageInfo($file);

   my $content_type = $exifTool->GetValue( "MIMEType" ) //
      "application/octet-stream";

   $dist->fire_async( do_upload => file => $file, content_type => $content_type )->then( sub {
      my ( $uri ) = @_;

      $room->send_message( type => "m.file", body => "file attachment",
         url      => $uri,
         filename => $file,
         info     => {
            size     => $exifTool->GetValue( "FileSize", "ValueConv" ),
            mimetype => $content_type,
         },
      );
      Future->done;
   });
}

sub cmd_leave
{
   my $self = shift;

   my $room = $self->{room};
   $room->leave;
}

sub cmd_invite
{
   my $self = shift;
   my ( $user_id ) = @_;

   my $room = $self->{room};

   $room->invite( $user_id );
}

sub cmd_level
{
   my $self = shift;
   my $delete = $_[0] eq "-del" ? shift : 0;
   my ( $user_id, $level ) = @_;

   defined $level or $delete or
      Future->fail( "Require a power level, or -del" );

   my $room = $self->{room};

   $room->change_member_levels( $user_id => $level );
}

sub cmd_roomlevels
{
   my $self = shift;

   my %levels;
   foreach (@_) {
      m/^(.*)=(\d+)$/ and $levels{$1} = $2;
   }

   my $room = $self->{room};
   $room->change_levels( %levels );
}

sub cmd_topic
{
   my $self = shift;
   my $topic = join " ", @_; # TODO

   my $room = $self->{room};

   if( length $topic ) {
      $room->set_topic( $topic )
   }
   else {
      my $room_topic = $room->topic;
      my $room_name = $room->name;
      $self->append_line( "Topic for $room_name is: $room_topic" );
      Future->done;
   }
}

sub cmd_roomname
{
   my $self = shift;
   my $name = join " ", @_; # TODO

   my $room = $self->{room};

   if( length $name ) {
      $room->set_name( $name )
   }
   else {
      my $room_name = $room->name;
      $self->append_line( "Room name is: $room_name" );
      Future->done;
   }
}

sub cmd_roomid
{
   my $self = shift;

   my $roomid = $self->{room}->room_id;
   $self->append_line( "Room ID is: $roomid" );

   Future->done;
}

sub cmd_add_alias
{
   my $self = shift;
   my ( $alias ) = @_;

   my $room_id = $self->{room}->room_id;

   $self->{dist}->fire_async( do_add_alias => $alias, $room_id );
}

sub cmd_list_aliases
{
   my $self = shift;

   map { $self->append_line( "Room alias: $_" ) } $self->{room}->aliases;
   Future->done;
}

sub cmd_delete_alias
{
   my $self = shift;
   my ( $alias ) = @_;

   grep { $_ eq $alias } $self->{room}->aliases or
      return Future->fail( "$alias is not an alias of this room" );

   $self->{dist}->fire_async( do_del_alias => $alias );
}

0x55AA;
