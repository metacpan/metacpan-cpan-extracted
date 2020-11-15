#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.31;

package App::Device::Chip::UI::GPIOBox 0.01;
class App::Device::Chip::UI::GPIOBox
   extends Tickit::Widget::GridBox;

use Tickit;
use Tickit::Widgets qw( GridBox Button CheckButton Static );

Tickit::Style->load_style( <<'EOSTYLE' );
Button.gpio {
  bg: "black"; fg: "white";
}
Button.gpio:current {
  bg: "white"; fg: "black";
}
Button.gpio:read {
  bg: "red"; fg: "black";
}
GridBox.gpio {
  row_spacing: 1;
  col_spacing: 1;
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

BUILD ( %args )
{
   $_protocol = $args{protocol};

   # Depend on this as a required method now
   my @GPIOs = $_protocol->meta_gpios;

   foreach my $idx ( 0 .. int( ( $#GPIOs + 7 ) / 8 ) ) {
      my $row = $self->rowcount;

      foreach my $col ( 0 .. 7 ) {
         my $def = $GPIOs[$idx*8 + $col] or next;

         $self->add( $row, $col,
            Tickit::Widget::Static->new(
               text    => $def->name,
               classes => [ $self->style_classes ],
            )
         );

         my ( $hi, $lo, $read ) = $self->make_buttons( $def );

         $self->add( $row+1, $col, $hi );
         $self->add( $row+2, $col, $lo );
         $self->add( $row+3, $col, $read ) if $read;

         $read->activate if $read;
      }
   }

   # All pins inputs
   $_protocol->tris_gpios( [ map { $_->name } @GPIOs ] )->get;
}

has %_levelbuttons;
has %_readmode;

method make_buttons ( $def )
{
   my $gpio = $def->name;
   my $dir  = $def->dir;

   my $check;
   my @buttons;
   @{ $_levelbuttons{$gpio} } = @buttons = map {
      my $hi = ( $_ eq "HI" );

      Tickit::Widget::Button->new(
         label    => $_,
         classes => [ $self->style_classes ],
         on_click => sub {
            my $btn = shift;
            return if $_readmode{$gpio};

            $_protocol->write_gpios( { $gpio => $hi ? 0xFF : 0 } )->get;

            $_->set_style_tag( current => 0 ) for @buttons;
            $btn->set_style_tag( current => 1 );
         },
      )
    } qw( HI LO );

    $check = Tickit::Widget::CheckButton->new(
       label => "read",
       classes => [ $self->style_classes ],
       on_toggle => sub {
          my $check = shift;
          if( $check->is_active ) {
             $_readmode{$gpio} = 1;
             $_->set_style_tag( current => 0 ) for @buttons;
             $_protocol->tris_gpios( [ $gpio ] )->get;
          }
          else {
             $_readmode{$gpio} = 0;
             $_->set_style_tag( read => 0 ) for @buttons;
             $_protocol->write_gpios( { $gpio =>  0 } )->get;
          }
       },
    ) if $dir eq "rw";

    $_readmode{$gpio} = 1 if $dir eq "r";

    return @buttons, $check;
}

method update ()
{
   my @read_gpios = grep { $_readmode{$_} } $_protocol->list_gpios;

   $_protocol->read_gpios( \@read_gpios )->on_done( sub {
      my ( $vals ) = @_;

      foreach my $gpio ( keys %$vals ) {
         next unless $_readmode{$gpio};
         my $bitval = $vals->{$gpio};

         # HI
         $_levelbuttons{$gpio}[0]->set_style_tag(
            read => !!$bitval,
         );
         # LO
         $_levelbuttons{$gpio}[1]->set_style_tag(
            read =>  !$bitval,
         );
      }
   })->get; # Yes, synchronous
}

0x55AA;
