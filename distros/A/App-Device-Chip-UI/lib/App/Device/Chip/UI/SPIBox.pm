#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.32;

package App::Device::Chip::UI::SPIBox 0.01;
class App::Device::Chip::UI::SPIBox
   extends Tickit::Widget::GridBox
   implements App::Device::Chip::UI::WithWrite;

use Syntax::Keyword::Try 0.18;

use Tickit;
use Tickit::Widgets qw( GridBox Button Static Entry Choice );

Tickit::Style->load_style( <<'EOSTYLE' );
Static.readout {
  bg: "green"; fg: "black";
}
EOSTYLE

sub BUILDARGS ( $class, %args )
{
   return (
      %args,
      style => {
         row_spacing => 1,
         col_spacing => 1,
      },
   );
}

has $_protocol;

has $_readresultlabel;

BUILD ( %args )
{
   $_protocol = $args{protocol};

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Mode",
            valign => "middle",
         ),

         Tickit::Widget::Choice->new(
            choices => [
               [ 0, "Mode 0" ],
               [ 1, "Mode 1" ],
               [ 2, "Mode 2" ],
               [ 3, "Mode 3" ],
            ],
            on_changed => sub {
               my ( undef, $mode ) = @_;
               $_protocol->configure( mode => $mode );
            },
         ),
      ]
   );

   # Default to mode 0
   $_protocol->configure( mode => 0 );

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Write",
            valign => "middle",
         ),

         my $writeentry = Tickit::Widget::Entry->new,

         my $writebutton = Tickit::Widget::Button->new(
            label => "Write",
         ),
      ]
   );

   $writeentry->set_on_enter( sub {
      $writebutton->click;
   });
   $writebutton->set_on_click( sub {
      my $text = $writeentry->text;
      $writeentry->set_text( "" );

      try {
         $self->write( $text );
      }
      catch ( $e ) {
         print STDERR "TODO: Error $e";
      }
   });

   $self->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Read",
            valign => "middle",
         ),

         my $readsizeentry = Tickit::Widget::Entry->new,

         my $readbutton = Tickit::Widget::Button->new(
            label => "Read",
         ),
      ]
   );

   $readsizeentry->set_on_enter( sub {
      $readbutton->click;
   });
   $readbutton->set_on_click( sub {
      $self->read( $readsizeentry->text );
      $readsizeentry->set_text( "" );
   });

   $self->add( $self->rowcount, 1,
      $_readresultlabel = Tickit::Widget::Static->new(
         text  => "",
         class => "readout",
      ),
      col_expand => 1,
      row_expand => 1,
   );

   # TODO: selection of SS GPIO line
}

method read ( $len )
{
   $self->_do_write( "\x00" x $len );
}

method _do_write ( $words_out )
{
   my $words_in = $_protocol->readwrite( $words_out )->get;

   $_readresultlabel->set_text(
      join " ", map { sprintf "0x%02X", ord } split m//, $words_in,
   );
}

0x55AA;
