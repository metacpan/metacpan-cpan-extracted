#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::Shell;

use strict;
use warnings;

our $VERSION = '0.06';

use Glib qw( TRUE FALSE );
use String::Tagged 0.15;  # sprintf
use Commandable::Invocation;

Devel::MAT->VERSION( '0.35' ); # Commandable::Invocation

# The perl bindings don't make this very easy
use constant PANGO_WEIGHT_BOLD => 700;

my ( $pmat, $buffer, $textview, $endmark, $scrolledwindow, $prompt );
my ( @styletags, $errortag, $svtag, $valuetag, $symboltag );

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

   foreach my $colour ( '#0000C0', '#008000', '#8000C0' ) {
      push @styletags, $buffer->create_tag( undef,
         foreground => $colour,
         style      => 'italic',
      );
   }

   $svtag = $buffer->create_tag( undef,
      foreground => "#0000D0",
   );

   $valuetag = $buffer->create_tag( undef,
      foreground => "#B000B0",
   );

   $symboltag = $buffer->create_tag( undef,
      foreground => "#00B000",
   );

   $endmark = $buffer->create_mark( 'end', $buffer->get_end_iter, FALSE );

   $vbox->pack_start( my $hbox = Gtk2::HBox->new, FALSE, FALSE, 0 );

   $prompt = Gtk2::Label->new( "pmat>" );

   $hbox->pack_start( $prompt, FALSE, FALSE, 0 );

   my $entry = Gtk2::Entry->new;

   $hbox->pack_start( $entry, TRUE, TRUE, 0 );

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

   my $inv = Commandable::Invocation->new( $line );
   my $cmd = $inv->pull_token;

   append_output( join( " ", "pmat>", $cmd, $inv->remaining ) . "\n" );

   eval {
      $pmat->load_tool_for_command( $cmd,
         progress => \&::progress,
      )->run_cmd( $inv );
      1;
   } or do {
      my $err = $@;
      chomp $err;
      append_output( "ERR: $err\n", $errortag );
   };

   $prompt->set_text( sprintf "pmat%s>", Devel::MAT::Tool::more->can_more ? " [more]" : "" );
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

   my $str = String::Tagged->from_sprintf( $fmt, @args );

   $str->iter_substr_nooverlap( sub {
      my ( $s, %tags ) = @_;
      append_output( $s, @{ $tags{tags} // [] } );
   });
}

sub Devel::MAT::Cmd::format_note
{
   shift;
   my ( $str, $idx ) = @_;
   $idx //= 0;
   return String::Tagged->new_tagged(
      $str,
      tags => [ $styletags[$idx % 3] ]
   );
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

sub Devel::MAT::Cmd::format_sv
{
   shift;
   my ( $sv ) = @_;

   my $ret = String::Tagged->new
      ->append_tagged( $sv->desc, tags => [ $svtag ] );

   if( my $blessed = $sv->blessed ) {
      $ret->append( "=" );
      $ret->append_tagged( $blessed->stashname, tags => [ $svtag, _make_navtag( $blessed ) ] );
   }

   $ret->append( " at " );
   $ret->append_tagged( sprintf( "%#x", $sv->addr ), tags => [ $svtag, _make_navtag( $sv ) ] );

   if( my $rootname = $sv->rootname ) {
      $ret->append( "=" );
      $ret->append_tagged( $rootname, tags => [ $styletags[1] ] );
   }

   return $ret;
}

sub Devel::MAT::Cmd::_format_value
{
   shift;
   my ( $val ) = @_;

   return String::Tagged->new_tagged(
      $val,
      tags => [ $valuetag ],
   );
}

sub Devel::MAT::Cmd::format_symbol
{
   shift;
   my ( $name, $sv ) = @_;

   $sv or die "TODO: Will have to look up '$name' symbol";

   return String::Tagged->new_tagged( $name,
      tags => [ $symboltag, _make_navtag( $sv ) ],
   );
}

0x55AA;
