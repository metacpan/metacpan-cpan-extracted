package Gtk2::Ex::FileLocator::PathBar;
use strict;
use warnings;

use Gtk2;
use Glib qw(TRUE FALSE);

use Gtk2::Ex::FileLocator::Helper;

use Glib::Object::Subclass Gtk2::Ex::FileLocator::FileChooser::,
  properties => [
   Glib::ParamSpec->object(
      'scrolledWindow', 'scrolledWindow',
      '',               'Gtk2::ScrolledWindow',
      [qw/readable writable/]
   ),
  ],
  ;

sub INIT_INSTANCE {
   my ($this) = @_;

   $this->set( 'scrolledWindow', new Gtk2::ScrolledWindow );
   $this->get('scrolledWindow')->set_policy( 'never', 'never' );
	$this->add($this->get('scrolledWindow'));

   $this->{hbox} = new Gtk2::HBox;
   $this->{hbox}->set_size_request( -1, 10 );
   $this->{hbox}->set_spacing(0);
   $this->{hbox}->show;

   $this->signal_connect_after( 'map' => \&on_map );
}

sub on_map {
   my $this = shift;

   $this->get('scrolledWindow')->add_with_viewport( $this->{hbox} );
   $this->get('scrolledWindow')->child->set_shadow_type('none');
   1;
}

sub get_uri {
   my ($this) = @_;
   printf "PathBar %s\n", $this->get_filename;
   return sprintf "file://%s", $this->get_filename;
}

sub get_filename {
   my $this = shift;
   my $filename = join "/", map { $_->{string} } $this->{hbox}->get_children;
   $filename =~ s|/+|/|sgo;
   $filename =~ s|/*$|/|o if -d $filename;
   return $filename;
}

sub set_uri {
   my ( $this, $uri ) = @_;
   $uri =~ s|^.*?\://||o;
   printf "set_filename %s\n", $uri;
   $this->set_filename($uri);
}

sub set_filename ($$) {
   my ( $this, $filename ) = @_;

   $this->clear_all;
   return unless $filename;
   printf "set_filename %s\n", $filename if -e $filename;

   my @filename = split '/', $filename;

   unless ( $filename[0] ) {
      shift @filename;
      $this->{hbox}->pack_start( $this->make_button("/"), FALSE, FALSE, 0 )
        if @filename;
   }

   $this->{hbox}
     ->pack_end( $this->make_button( pop @filename || '/' ), TRUE, TRUE, 0 );
   $this->{hbox}->pack_start( $this->make_button($_), FALSE, FALSE, 0 )
     foreach @filename;

   $this->configure_buttons;

   return;
}

sub clear_all {
   my $this = shift;
   $this->{hbox}->remove($_) foreach $this->{hbox}->get_children;
   return;
}

sub make_button {
   my ( $this, $string ) = @_;

   my $button = new Gtk2::Button;
   $button->{string} = $string || '';
   $button->show;
   $button->signal_connect_after( 'clicked' => \&on_click, $this );
   return $button;
}

sub configure_buttons {
   my ($this) = @_;

   #printf "configure_buttons\n";
   return unless $this->{hbox}->get_children;

   my $separator = $this->get_separator_width;

   foreach ( $this->{hbox}->get_children ) {
      my $layout = $this->get('scrolledWindow')->create_pango_layout( $_->{string} );
      $_->set_size_request( ( $layout->get_pixel_size )[0] + $separator, 0 );
   }

   $this->queue_resize;
}

sub get_separator_width {
   my $this   = shift;
   my $layout = $this->get('scrolledWindow')->create_pango_layout('/');
   return ( $layout->get_pixel_size )[0];
}

sub on_click {
   my ( $button, $this ) = @_;

   my @children = $this->{hbox}->get_children;
   file_open( $this->{filename} ) if $button == $children[$#children];

   foreach ( reverse @children ) {
      last if $_ == $button;
      $this->{hbox}->remove($_);
   }
   $this->{hbox}->set_child_packing( $button, TRUE, TRUE, 0, 'end' );

   #printf "%s\n", $this->get_filename;
   $this->signal_emit( 'selection-changed' );
   0;
}

sub set_scroll_offset {
   my ( $this, $scrollOffset ) = @_;

   #printf "%s\n", $scrollOffset;
   $this->get('scrolledWindow')->get_hadjustment->set_value($scrollOffset);
   return;
}

1;
__END__
