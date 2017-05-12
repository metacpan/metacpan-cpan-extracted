package Gtk2::Ex::FileLocator::RecycleButton;
use strict;
use warnings;

use Gtk2;
use Glib qw(TRUE FALSE);
use Gnome2;

use File::Basename qw(dirname);

use Gtk2::Ex::FileLocator::Helper;
use Gtk2::Ex::FileLocator::FileChooser;

use Glib::Object::Subclass Gtk2::Ex::FileLocator::FileChooser::,
  properties => [
   Glib::ParamSpec->boolean(
      'existing_files',           'file_exists',
      'Show only existing files', TRUE,
      [qw/readable writable/]
   ),
  ],
  ;

sub INIT_INSTANCE {
   my ($this) = @_;

   $this->{iconsize} = "medium";

   my $image =
     Gtk2::Image->new_from_stock( 'gtk-refresh', "GTK_ICON_SIZE_BUTTON" );
   $image->show;

   my $button = new Gtk2::Button;
   $button->add($image);
   $button->show;
   $button->add_events('button-release-mask');
   $button->signal_connect(
      'button_release_event' => \&on_button_release_event,
      $this
   );

   $this->add($button);

   #popup menu
   $this->{menu} = new Gtk2::Menu;
   $this->{menu}->show;

   $this->signal_connect_after( 'map' => \&on_map );

   $this->get('chooser')->signal_connect( 'selection_changed', sub { $this->add_filename( $this->get_filename ) } );
}

sub on_map {
   my $this   = shift;
   my $height = $this->allocation->height + 5;
   $this->set_size_request( $height, 0 );
   return;
}

sub add_filename {
   my ( $this, $filename ) = @_;
   return unless $filename;

   $filename = string_shell_unescape($filename);

   return unless -e $filename or not $this->get('existing_files');

   if ( -d $filename ) {
      $filename =~ s|\.{1,2}/*$||o;    # remove ../ or ../ from end
      $filename .= "/";                # add a / at the end
      $filename =~ s|/+|/|sgo;         # remove double //
   }

   my $image = Gtk2::Image->new;
   image_set_file_icon( $image, $filename, $this->{iconsize} );

   $filename = Unicode::MapUTF8::from_utf8(
      { -string => $filename, -charset => 'ISO-8859-1' } );
   my @children = $this->{menu}->get_children;
   return
     if @children
        and grep { $_->get_child->get_text eq $filename } @children;

   $this->Debug($filename);

   my $menuItem = Gtk2::ImageMenuItem->new($filename);
   $menuItem->set_image($image);
   $menuItem->signal_connect_after( 'activate' => \&on_menu_activated, $this );
   $menuItem->show;

   $this->{menu}->append($menuItem);
   return;
}

sub on_button_release_event {
   my ( $button, $event, $this ) = @_;

   #printf "on_button_release_event %s\n", $this->get_filename;
   $this->{menu}
     ->popup( undef, undef, undef, undef, $event->button, $event->time );
   return;
}

sub on_menu_activated {
   my ( $item, $this ) = @_;

   my $path = $item->get_child->get_text;
   printf "on_menu_activated %s\n", $path;

   $this->set_uri( sprintf "file://%s", $path );

   $this->get_toplevel->present;
   1;
}

1;
__END__
Gtk2->main_iteration while Gtk2->events_pending;
