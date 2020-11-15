#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2020 -- leonerd@leonerd.org.uk

package App::Device::Chip::UI 0.01;

use v5.14;
use utf8;

use Syntax::Keyword::Try 0.18;

use App::Device::Chip::UI::GPIOBox;
use App::Device::Chip::UI::SPIBox;
use App::Device::Chip::UI::UARTBox;

use Tickit;
use Tickit::Widgets qw( VBox CheckButton );
use Tickit::Widgets qw( Tabbed );

=head1 NAME

C<App::Device::Chip::UI> - L<Tickit>-based UI for L<Device::Chip> drivers

=cut

Tickit::Style->load_style( <<'EOSTYLE' );
Entry {
  bg: "green"; fg: "black";
}
Choice {
  bg: "green"; fg: "black";
}
EOSTYLE

sub run
{
   shift;
   my ( $adapter, %args ) = @_;

   my $vbox = Tickit::Widget::VBox->new(
      style => {
         spacing => 1,
      },
   );

   my $protocol;

   $vbox->add(
      Tickit::Widget::CheckButton->new(
         label => "power",
         on_toggle => sub {
            my $self = shift;
            $protocol->power( $self->is_active )->get;
         },
      )
   );

   $vbox->add(
      my $tabbed = Tickit::Widget::Tabbed->new,
      expand => 1,
   );

   my $updatesub;
   my $initialtab;

   foreach my $protoname (qw( GPIO SPI UART )) {
      my $tab = $tabbed->add_tab( Tickit::Widget::VBox->new,
         label => $protoname,
      );

      $tab->set_on_activated( my $activatesub = sub {
         my ( $tab ) = @_;
         my $vbox = $tab->widget;

         try {
            $protocol = $adapter->make_protocol( $protoname )->get;
         }
         catch ( $e ) {
            # TODO: inspect $e
            $vbox->add( Tickit::Widget::Static->new(
               text => "$protoname is not supported",
               align => "centre",
               style => {
                  bg => "red",
               },
            ) );
            return;
         }

         my $method = "activate_$protoname";
         __PACKAGE__->$method( $protocol, $vbox, \$updatesub );
      } );

      $tab->set_on_deactivated( sub {
         my ( $tab ) = @_;
         my $widget = $tab->widget;

         $widget->remove( $_ ) for $widget->children;
         undef $updatesub;
      } );

      if( $protoname eq $args{startmode} ) {
         $tabbed->activate_tab( $tab->index );
         $activatesub->( $tab ) if !$tab->index; # ->activate_tab(0) won't run this
      }
   }

   my $tickit = Tickit->new( root => $vbox );
   $tickit->term->await_started( 0.5 );

   my $update;
   $update = sub {
      $updatesub and $updatesub->();
      $tickit->timer( after => 0.05, $update );
   };

   $update->();

   $tickit->run;
}

sub activate_GPIO
{
   shift;
   my ( $protocol, $vbox, $updateref ) = @_;

   $vbox->add( my $gpiobox = App::Device::Chip::UI::GPIOBox->new(
      protocol => $protocol,
   ) );

   $$updateref = sub { $gpiobox->update };
}

sub activate_SPI
{
   shift;
   my ( $protocol, $vbox, $updateref ) = @_;

   $vbox->add( my $spibox = App::Device::Chip::UI::SPIBox->new(
      protocol => $protocol,
   ) );
}

sub activate_UART
{
   shift;
   my ( $protocol, $vbox, $updateref ) = @_;

   $vbox->add( my $uartbox = App::Device::Chip::UI::UARTBox->new(
      protocol => $protocol,
   ) );

   $$updateref = sub { $uartbox->update };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
