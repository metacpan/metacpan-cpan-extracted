package Gtk2::Ex::FileLocator::DropPocket;
use strict;
no warnings;

use Gtk2;
use Glib qw(TRUE FALSE);

use Gtk2::Ex::FileLocator::Helper;
use Gtk2::Ex::FileLocator::FileChooser;

use Glib::Object::Subclass Gtk2::Ex::FileLocator::FileChooser::,;

our @targets = (
   { target => "text/uri-list", flags => [], info => 0 },
   { target => "STRING",        flags => [], info => 0 },
   { target => "text/plain",    flags => [], info => 0 },
);

sub INIT_INSTANCE {
   my $this = shift;

   $this->{iconsize} = "small";

   $this->{image} = Gtk2::Image->new;
   $this->{image}->show;

   my $button = new Gtk2::Button;
   $button->set_border_width(1);
   $button->add( $this->{image} );
   $button->drag_source_set( [ 'button1_mask', 'button3_mask' ],
      [qw'copy link'], $targets[0] );
   $button->signal_connect( 'drag_data_get', \&on_drag_data_get, $this );
   $button->signal_connect_after( 'clicked' => \&on_click, $this );
   $button->show;
   $button->set_reallocate_redraws(FALSE);
   $button->set_resize_mode('parent');

   #$this->set_shadow_type('in');
   $this->add($button);

   $this->drag_dest_set( 'all', [qw(copy move link)], @targets );
   $this->signal_connect_after( 'map' => \&on_map );
   $this->signal_connect_after(
      'drag_data_received' => \&on_drag_data_received );

   $this->signal_connect( 'selection-changed', sub { $this->change_image } );
}

sub on_map {
   my $this = shift;
   $this->set_size_request( $this->allocation->height + 5, 0 );
   0;
}

sub change_image {
   my ($this) = @_;

   #$this->Debug("###### ", $this->get_filename);

   image_set_file_icon( $this->{image}, string_shell_unescape($this->get_filename),
      $this->{iconsize} );

   return;
}

sub on_click {
   my ( $widget, $this ) = @_;
   $this->get('chooser')->show;
   return;
}

sub on_drag_data_received {
   my ( $this, $context, $x, $y, $data, $flags, $time ) = @_;

   #$this->Debug($data->data, $data->type->name);

   if ( $data->type->name eq "text/uri-list" ) {
      my @uri = split "\r\n", $data->data;
      printf "uri  %s\n", $uri[0];

      $this->set_uri( $uri[0] );
   }
   0;
}

sub on_drag_data_get {
   my ( $button, $context, $data, $info, $time, $this ) = @_;
   my $uri = $this->get_uri;
   $data->set( $data->target, 8, " $uri\r\n" );
   0;
}

1;
__END__
