#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::Shell;

use strict;
use warnings;

our $VERSION = '0.04';

use Glib qw( TRUE FALSE );
use Text::ParseWords;

# The perl bindings don't make this very easy
use constant PANGO_WEIGHT_BOLD => 700;

my ( $pmat, $buffer, $textview, $endmark, $scrolledwindow );
my ( @styletags, $errortag, $svtag );

sub build_widget
{
   my $class = shift;
   ( $pmat ) = @_;

   my $vbox = Gtk2::VBox->new;

   $vbox->pack_start( $scrolledwindow = Gtk2::ScrolledWindow->new, TRUE, TRUE, 0 );
   $scrolledwindow->set_policy( 'never', 'always' );

   $scrolledwindow->add( $textview = Gtk2::TextView->new );

   $textview->set_editable( FALSE );
   $textview->set_cursor_visible( FALSE );
   $textview->set_wrap_mode( 'word-char' );
   $textview->modify_font( Gtk2::Pango::FontDescription->from_string( 'monospace' ) );

   $buffer = $textview->get_buffer;

   $errortag = $buffer->create_tag( undef,
      foreground => "#FF0000",
      weight     => PANGO_WEIGHT_BOLD,
   );

   foreach my $colour ( '#0000FF', '#00A000', '#8000C0' ) {
      push @styletags, $buffer->create_tag( undef,
         foreground => $colour,
         style      => 'italic',
      );
   }

   $svtag = $buffer->create_tag( undef,
      foreground => "#0000D0",
   );

   $endmark = $buffer->create_mark( 'end', $buffer->get_end_iter, FALSE );

   my $entry = Gtk2::Entry->new;

   $vbox->pack_start( $entry, FALSE, FALSE, 0 );

   $entry->modify_font( Gtk2::Pango::FontDescription->from_string( 'monospace' ) );

   $entry->signal_connect( activate => sub {
      my $cmd = $entry->get_text;
      $entry->set_text( "" );

      invoke_command( $cmd );
   });

   return $vbox;
}

sub invoke_command
{
   my ( $line ) = @_;

   my ( $cmd, @args ) = Text::ParseWords::shellwords( $line );

   append_output( join( " ", "pmat>", $cmd, @args ) . "\n" );

   eval {
      $pmat->load_tool_for_command( $cmd,
         progress => \&::progress,
      )->run_cmd( @args );
      1;
   } or do {
      my $err = $@;
      chomp $err;
      append_output( "ERR: $err\n", $errortag );
   };
}

my $linefeed_pending;

sub append_output
{
   my ( $str, @tags ) = @_;

   my $adj = $scrolledwindow->get_vadjustment;
   my $at_end = $adj->get_value == ( $adj->upper - $adj->page_size );

   if( $linefeed_pending ) {
      $buffer->insert( $buffer->get_end_iter, "\n" );
      undef $linefeed_pending;
   }

   if( chomp $str ) {
      $linefeed_pending = 1;
   }

   $buffer->insert_with_tags( $buffer->get_end_iter, $str, @tags );

   $textview->scroll_mark_onscreen( $endmark ) if $at_end;

   return length $str;
}

sub Devel::MAT::Cmd::printf
{
   shift;
   my ( $fmt, @args ) = @_;
   append_output( sprintf( $fmt, @args ) );
}

sub Devel::MAT::Cmd::print_note
{
   shift;
   my ( $str, $idx ) = @_;
   $idx //= 0;
   append_output( $str, $styletags[$idx % 3] );
}

sub _make_navtag
{
   my ( $sv ) = @_;

   my $navtag = $buffer->create_tag( undef,
      underline  => 'single',
   );
   $navtag->signal_connect( event => sub {
      my ( undef, undef, $ev, undef, $sv ) = @_;
      return unless $ev->type eq 'button-release' and $ev->button == 1;
      ::history_nav( $sv );
   }, $sv );

   return $navtag;
}

sub Devel::MAT::Cmd::print_sv
{
   shift;
   my ( $sv ) = @_;

   my $len = append_output( $sv->desc, $svtag );

   if( my $blessed = $sv->blessed ) {
      $len += append_output( "=" );
      $len += append_output( $blessed->stashname, $svtag, _make_navtag( $blessed ) );
   }

   $len += append_output( " at " );
   $len += append_output( sprintf( "%#x", $sv->addr ), $svtag, _make_navtag( $sv ) );

   return $len;
}

0x55AA;
