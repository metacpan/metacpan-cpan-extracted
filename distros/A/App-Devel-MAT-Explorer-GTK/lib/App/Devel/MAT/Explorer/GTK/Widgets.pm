#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::Widgets;

use strict;
use warnings;

our $VERSION = '0.03';

use Glib qw( TRUE FALSE );
use Gtk2;

use List::Util qw( pairs );

use Exporter 'import';

our @EXPORT_OK = qw(
   framed
   label
   textarea
   vscrollable
);
our %EXPORT_TAGS = (
   all => [ @EXPORT_OK ],
);

sub framed
{
   my ( $widget ) = @_;
   my $frame = Gtk2::Frame->new;
   $frame->set_shadow_type( "in" );
   $frame->add( $widget );
   return $frame;
}

sub label
{
   my ( $text ) = @_;
   my $l = Gtk2::Label->new( $text );
   $l->set_alignment( 0, 0 );
   return $l;
}

sub textarea
{
   my ( $text ) = @_;
   my $l = label( $text );
   $l->set_selectable( TRUE );
   $l->set_can_focus( FALSE );
   return $l;
}

sub vscrollable
{
   my ( $widget ) = @_;

   my $win = Gtk2::ScrolledWindow->new;
   $win->set_policy( 'never', 'always' );
   $win->add( $widget );

   return $win;
}

sub Devel::MAT::UI::make_table
{
   shift;

   my $table = Gtk2::Table->new( 1, 2 );

   foreach ( pairs @_ ) {
      my ( $label, $widget ) = @$_;
      my ( $next_row ) = $table->get_size;

      $table->attach( label( $label ), 0, 1, $next_row, $next_row + 1, [ "expand", "fill" ], [ "fill" ], 0, 3 );
      $table->attach( $widget,         1, 2, $next_row, $next_row + 1, [ "expand", "fill" ], [ "fill" ], 0, 3 );
   }

   return $table;
}

sub Devel::MAT::UI::make_widget_text
{
   shift;
   my ( $text ) = @_;
   return textarea( $text );
}

sub Devel::MAT::UI::make_widget_text_icon
{
   my $self = shift;
   my ( $label, $icon ) = @_;

   my $hbox = Gtk2::HBox->new;

   $hbox->add( $self->make_widget_text( $label ) );
   $hbox->add( Gtk2::Image->new_from_pixbuf( get_icon( $icon ) ) );

   return $hbox;
}

0x55AA;
