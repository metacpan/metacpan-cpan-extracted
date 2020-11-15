#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.32;

package App::Device::Chip::UI::UARTBox 0.01;
class App::Device::Chip::UI::UARTBox
   extends Tickit::Widget::VBox
   implements App::Device::Chip::UI::WithWrite;

use App::Device::Chip::UI::GPIOBox;

use Syntax::Keyword::Try;

use Tickit::Widgets qw( Static Choice );

Tickit::Style->load_style( <<'EOSTYLE' );
VBox.gpio {
  spacing: 1;
}
EOSTYLE

sub BUILDARGS ( $class, %args )
{
   my @classes = defined $args{class}   ? ( $args{class} ) :
                 defined $args{classes} ? @{ $args{classes} } : ();
   push @classes, "gpio";

   return (
      %args,
      classes => \@classes,
   );
}

has $_protocol;

has $_gpiobox;

BUILD ( %args )
{
   $_protocol = $args{protocol};

   $self->add(
      $_gpiobox = App::Device::Chip::UI::GPIOBox->new( protocol => $_protocol ),
      expand => 1,
   );

   # Fill the GridBox before adding it to $self to avoid a warning about undef
   my $gridbox = Tickit::Widget::GridBox->new( class => "gpio" );

   $gridbox->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Baud",
            valign => "middle",
         ),

         Tickit::Widget::Choice->new(
            choices => [
               map { [ $_, $_ ] } qw( 300 600 1200 2400 4800 9600 19200 38400 57600 115200 )
            ],
            on_changed => sub {
               my ( undef, $baud ) = @_;
               $_protocol->configure( baudrate => $baud )->get;
            },
         ),
      ]
   );

   # TODO: bits

   $gridbox->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Parity",
            valign => "middle",
         ),

         Tickit::Widget::Choice->new(
            choices => [
               map { [ $_, $_ ] } qw( none odd even ),
            ],
            on_changed => sub {
               my ( undef, $parity ) = @_;
               $_protocol->configure( parity => substr $parity, 0, 1 )->get;
            },
         ),
      ]
   );

   $gridbox->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Stop",
            valign => "middle",
         ),

         Tickit::Widget::Choice->new(
            choices => [
               map { [ $_, $_ ] } qw( 1 2 ),
            ],
            on_changed => sub {
               my ( undef, $stop ) = @_;
               $_protocol->configure( stop => $stop )->get;
            },
         ),
      ]
   );

   $gridbox->append_row(
      [
         Tickit::Widget::Static->new(
            text   => "Write",
            valign => "middle",
         ),

         {
            child => my $writeentry = Tickit::Widget::Entry->new,
            col_expand => 1,
         },

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
      catch {
         print STDERR "TODO: Error $@";
      }
   });

   $self->add( $gridbox, expand => 1 );
}

method _do_write ( $bytes )
{
   $_protocol->write( $bytes )->get;
}

method update ()
{
   $_gpiobox->update;
}

0x55AA;
