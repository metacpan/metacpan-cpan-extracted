package Gtk2::Ex::FileLocator::PathnameField;
use strict;
use warnings;

use Gtk2;
use Gtk2::Gdk::Keysyms;
use Glib qw(TRUE FALSE);

use Gtk2::Ex::FileLocator::Helper;
use Gtk2::Ex::FileLocator::FileChooser;

use Glib::Object::Subclass Gtk2::Ex::FileLocator::FileChooser::,
  properties => [
   Glib::ParamSpec->object(
      'entry',             'entry',
      'The entry to use.', 'Gtk2::Entry',
      [qw/readable writable/]
   ),
  ],
  signals =>
  { scroll_offset_changed => { param_types => [qw(Glib::Scalar)], }, },
  ;

sub INIT_INSTANCE {
   my ($this) = @_;

   $this->{cursorPosition} = 0;

   my $entry = new Gtk2::Entry;
   $entry->add_events('key-release-mask');

   $entry->signal_connect(
      'key-release-event' => \&on_key_release_event,
      $this
   );

   #$entry->signal_connect_after( 'move-cursor' => \&on_move_cursor, $this );
   #$entry->signal_connect( 'event' => \&on_event, $this );
   $entry->show;

   $this->set( 'entry', $entry );
   $this->add($entry);

   $this->get('chooser')
     ->signal_connect( 'selection_changed', sub { $this->change_text } );
}

sub on_key_release_event {
   my ( $entry, $event, $this ) = @_;

   printf "on_key_release_event %s %s\n", $entry->get_text, $this->get_filename;

   #printf "%s\n", $event->keyval;

   return
     if ($event->keyval == $Gtk2::Gdk::Keysyms{Insert}
      or $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter}
      or $event->keyval == $Gtk2::Gdk::Keysyms{Return} )
     and $this->_auto_complete;

   return
     if $event->keyval == $Gtk2::Gdk::Keysyms{KP_Enter}
        and file_open( $this->get_filename );

   return
     if $event->keyval == $Gtk2::Gdk::Keysyms{Return}
        and file_open( $this->get_filename );

   $this->signal_emit( 'scroll_offset_changed', $entry->get("scroll-offset") );

   return if $this->get_filename eq $entry->get_text;

   $this->{cursorPosition} = $this->get('entry')->get_position;
   #$this->set_filename( $entry->get_text );

   my $uri = sprintf "file://%s", $entry->get_text;
	$this->set_uri( -e $entry->get_text ? $uri : "" );

   #Gtk2->main_iteration while Gtk2->events_pending;
   #$this->signal_emit( 'scroll_offset_changed', $entry->get("scroll-offset") );

   return;
}

sub _auto_complete {
   my $this = shift;
   printf "auto_complete %s\n", $this->get('entry')->get_text;

   my $string = $this->get('entry')->get_text;
   my $match  = string_shell_complete($string);

   if ( $string ne $match ) {
      $this->get('entry')->set_text($match);
      $this->get('entry')->set_position( length $match );

      my $uri = sprintf "file://%s", $this->get('entry')->get_text;
		
	   $this->{cursorPosition} = -1;

		$this->set_uri($uri);
      $this->signal_emit( 'file_activated', $uri );


      return TRUE;
   }

   return;
}

sub change_text {
   my ($this) = @_;

   printf "PF set_text %s\n", $this->get_filename;

   my $filename = string_shell_unescape($this->get_filename);
   $filename .= "/" if -d $filename;

   $filename =~ s|/+|/|sgo;

   $filename = Unicode::MapUTF8::from_utf8(
      { -string => $filename, -charset => 'ISO-8859-1' } );
   $this->{filename} = $filename;
   $this->get('entry')->set_text($filename);
   $this->get('entry')->set_position( $this->{cursorPosition} );

#   Gtk2->main_iteration while Gtk2->events_pending;
#   $this->signal_emit( 'scroll_offset_changed',
#      $this->get('entry')->get("scroll-offset") );
}

#sub on_move_cursor {
#   my ($this) = @_;
#   $this->{cursorPosition} = $this->get_position;
#   Gtk2->main_iteration while Gtk2->events_pending;
#   $this->signal_emit( 'scroll_offset_changed', $this->get("scroll-offset") );
#   return;
#}

#sub on_event {
#   my ( $this, $event ) = @_;
#   return unless $event->type eq 'motion-notify' or $event->type eq 'expose';
#
#   #printf "on_event %s %s\n", $event->type, $this->get("scroll-offset");
#   $this->{cursorPosition} = $this->get('entry')->get_position;
#   $this->signal_emit( 'scroll_offset_changed',
#      $this->get('entry')->get("scroll-offset") );
#   0;
#}

1;
__END__
sub on_key_release_event {
	my ($this) = @_;
	$this->set_text( $this->get_text );
	$this->signal_emit( 'file_activated', $this->get('entry')->get_text );
	0;
}

sub on_drag_data_received {
	my ( $this, $context, $x, $y, $data, $flags, $time ) = @_;
	my $type = $data->type->name;

	my $url = $data->data;
	$url = $this->get_text unless $url =~ s|^file://||sgo;
	$url =~ s/[\r\n]+.*//sgo if $type eq "text/uri-list";

	$url = $this->unescape($url);

	$this->set_text($url);
	$this->signal_emit( 'file_activated', $this->get_text );
	0;
}
sub auto_complete {
	my $this = shift;
	printf "auto_complete %s\n", $this->get_text;

	my $original = $this->get_text;

	my $string = $this->get_text;
	my $substr = substr $string, 0, $this->get('cursor-position');

	$string =~ s|/*$||sgo;

	printf "string %s\n", $string;
	printf "substr %s\n", $substr;

	if ( -e $substr ) {
		printf "v1\n";
		if ( -d $string ) {
			$string = "$string/";
			$string = "$ENV{HOME}/$string" unless $string =~ m|^/|o;
		}

		$this->set_text($string);
		$this->set_position( length $string );
	} else {
		printf "v2\n";
		return unless $substr =~ /([^\\]+)$/;

		my $match = $this->get_match($1);
		return unless $match;

		$string =~ s/\Q$substr/$match/;
		$string = "$ENV{HOME}/$string" unless $string =~ m|^/|o;

		$this->set_text($string);
		$this->set_position( length $match );
	}

	if ( $original ne $this->get_text ) {
		$this->signal_emit( 'file_activated', $this->get_text );
		return TRUE;
	}

	return;
}
