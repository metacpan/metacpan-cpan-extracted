package Gtk2::Ex::FileLocator::FileChooser;
use strict;
use warnings;

our $VERSION = 0.01;
our $DEBUG   = 1;

use Gtk2;
use Glib qw(TRUE FALSE);

use Glib::Object::Subclass Gtk2::HBox::,
  properties => [
   Glib::ParamSpec->object(
      'chooser',                         'chooser',
      'The file chooser dialog to use.', 'Gtk2::FileChooserDialog',
      [qw/readable writable/]
   ),
  ],
  signals => {
   current_folder_changed => {},
   selection_changed      => {},
   file_activated         => {},
  },
  ;

sub INIT_INSTANCE {
   my $this = shift;

   $this->{path} = "";

   $this->set_border_width(0);

   $this->set( 'chooser', new Gtk2::FileChooserDialog( '', undef, 'open' ) );
   $this->get('chooser')->set_local_only(FALSE);

   $this->get('chooser')
     ->signal_connect( 'delete-event', \&on_delete_event, $this );

   $this->get('chooser')
     ->signal_connect( 'current_folder_changed',
      sub { $this->signal_emit('current_folder_changed') } );
   $this->get('chooser')
     ->signal_connect( 'selection_changed',
      sub { $this->signal_emit('selection_changed') } );
   $this->get('chooser')
     ->signal_connect( 'file_activated',
      sub { $this->signal_emit('file_activated') } );
}

sub on_delete_event {
   my ( $widget, $event, $this ) = @_;
   $widget->hide;
   return 1;
}

sub get_current_folder {
   my ($this) = @_;
   $this->get('chooser')->get_current_folder;
}

sub set_current_folder {
   my ( $this, $folder ) = @_;
   $this->get('chooser')->set_current_folder( $folder || "" );
}

sub get_filename {
   my ($this) = @_;
   my $uri = $this->get('chooser')->get_uri || "";
   $uri =~ s|^.+?\://||o if $uri;
   return $uri;
}

sub set_filename {
   my ( $this, $filename ) = @_;

   return unless $filename;
   return if ( $this->get('chooser')->get_filename || "" ) eq $filename;

   #$this->Debug($filename);
   $this->get('chooser')->set_filename( $this->{path} );

   return;
}

sub get_uri {
   my ($this) = @_;
   $this->get('chooser')->get_uri;
}

sub set_uri {
   my ( $this, $uri ) = @_;

   return unless $uri;
   return if ( $this->get('chooser')->get_uri || "" ) eq $uri;

   $this->Debug($this, $uri);
   $this->get('chooser')->set_uri($uri);

   return;
}

sub Debug {
   my ( $this, @values ) = @_;
   return unless $DEBUG;
   printf "# %s %s\n", &caller_subroutine, @values
     ? join " ", map { defined $_ ? $_ : "" } @values
     : "";
}

sub caller_subroutine { ( caller(2) )[3] || "" }
1;
__END__
