package Gtk2::Ex::FileLocator;
use strict;
use warnings;

use Gtk2;
use Glib qw(TRUE FALSE);

use Gtk2::Ex::FileLocator::DropPocket;
use Gtk2::Ex::FileLocator::PathBar;
use Gtk2::Ex::FileLocator::PathnameField;
use Gtk2::Ex::FileLocator::RecycleButton;

use Glib::Object::Subclass Gtk2::Ex::FileLocator::FileChooser::,
  properties => [
	Glib::ParamSpec->boolean(
		'stdout', 'stdout', 'Output filename to stdout',
		FALSE, [qw/readable writable/]
	),
  ],
  ;

sub INIT_INSTANCE {
	my ($this) = @_;

	$this->{filename} = "";

	my $hbox = new Gtk2::HBox;
	$hbox->set_spacing(2);

	$this->{dropPocket} = new Gtk2::Ex::FileLocator::DropPocket;
	$hbox->pack_start( $this->{dropPocket}, FALSE, FALSE, 0 );

	my $vbox = new Gtk2::VBox;
	$vbox->set_spacing(0);

	$this->{pathBar} = new Gtk2::Ex::FileLocator::PathBar;
	$vbox->pack_start( $this->{pathBar}, TRUE, TRUE, 0 );

	$this->{pathnameField} = new Gtk2::Ex::FileLocator::PathnameField;
	$vbox->pack_start( $this->{pathnameField}, FALSE, FALSE, 0 );

	$hbox->pack_start( $vbox, TRUE, TRUE, 0 );

	$this->{recycleButton} = new Gtk2::Ex::FileLocator::RecycleButton;
	$hbox->pack_start( $this->{recycleButton}, FALSE, FALSE, 0 );

	$this->pack_start( $hbox, TRUE, TRUE, 0 );

	$this->{dropPocket}->signal_connect( 'selection-changed'    => \&on_child_selection_changed, $this );
	$this->{pathBar}->signal_connect( 'selection-changed'       => \&on_child_selection_changed, $this );
	$this->{pathnameField}->signal_connect( 'selection-changedd' => \&on_child_selection_changed, $this );
	$this->{recycleButton}->signal_connect( 'selection-changed' => \&on_child_selection_changed, $this );

	$this->{pathnameField}->signal_connect( 'scroll-offset-changed' => sub { $this->{pathBar}->set_scroll_offset( $_[1] ) } );
	$this->{pathnameField}->signal_connect_after( 'size-request' => sub { $this->{pathBar}->configure_buttons } );
}

sub on_child_selection_changed {
	my ( $widget, $this) = @_;

	my $uri = $widget->get_uri;
   return unless $uri;
   #return if ( $this->get_uri || "" ) eq $uri;

   $this->Debug($this, $widget, $uri);

	$this->{dropPocket}->set_uri($uri)    unless $widget == $this->{dropPocket};
	$this->{pathBar}->set_uri($uri)       unless $widget == $this->{pathBar};
	$this->{pathnameField}->set_uri($uri) unless $widget == $this->{pathnameField};
	$this->{recycleButton}->set_uri($uri) unless $widget == $this->{recycleButton};

	#printf "%s\n", $filename if $this->get('stdout');
}

sub get_droppocket {
	my ($this) = @_;
	return $this->{dropPocket};
}

sub get_pathbar {
	my ($this) = @_;
	return $this->{pathBar};
}

sub get_pathnamefield {
	my ($this) = @_;
	return $this->{pathnameField};
}

sub get_recyclebutton {
	my ($this) = @_;
	return $this->{recycleButton};
}

1;
__END__
