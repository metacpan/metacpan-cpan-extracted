#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2020 -- leonerd@leonerd.org.uk

use Object::Pad 0.09;

class Tickit::Widget::Button 0.29
   extends Tickit::Widget;

use Tickit::Style;
use Tickit::RenderBuffer qw( LINE_SINGLE LINE_DOUBLE LINE_THICK );

use Tickit::Utils qw( textwidth );

use constant CAN_FOCUS => 1;

=head1 NAME

C<Tickit::Widget::Button> - a widget displaying a clickable button

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Button;

 my $button = Tickit::Widget::Button->new(
    label => "Click Me!",
    on_click => sub {
       my ( $self ) = @_;

       # Do something!
    },
 );

 Tickit->new( root => $button )->run;

=head1 DESCRIPTION

This class provides a widget which displays a clickable area with a label.
When the area is clicked, a callback is invoked.

=head1 STYLE

The default style pen is used as the widget pen. The following style keys are
used:

=over 4

=item linetype => STRING

What kind of border to draw around the button; one of

 none single double thick

=item marker_left => STRING

A two-character string to place just before the button label

=item marker_right => STRING

A two-character string to place just after the button label

=back

The following style tags are used:

=over 4

=item :active

Set when the mouse is being held over the button, before it is released

=back

The following style actions are used:

=over 4

=item click

The main action to activate the C<on_click> handler.

=back

=cut

style_definition base =>
   fg => "black",
   bg => "blue",
   linetype => "single",
   marker_left => "> ",
   marker_right => " <",
   '<Enter>' => "click";

style_definition ':focus' =>
   marker_left => ">>",
   marker_right => "<<";

style_definition ':active' =>
   rv => 1;

style_reshape_keys qw( linetype );
style_redraw_keys qw( marker_left marker_right );

use constant WIDGET_PEN_FROM_STYLE => 1;
use constant KEYPRESSES_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $entry = Tickit::Widget::Button->new( %args )

Constructs a new C<Tickit::Widget::Button> object.

Takes the following named arguments:

=over 8

=item label => STR

Text to display in the button area

=item on_click => CODE

Optional. Callback function to invoke when the button is clicked.

=back

=cut

has $_label;
has $_on_click;

method BUILD
{
   my %params = @_;

   $_label = $params{label} if defined $params{label};
   $_on_click = $params{on_click} if $params{on_click};

   $self->set_align ( $params{align}  // 0.5 );
   $self->set_valign( $params{valign} // 0.5 );
}

method lines
{
   my $has_border = ( $self->get_style_values( "linetype" ) ) ne "none";
   return 1 + 2*$has_border;
}

method cols
{
   my $has_border = ( $self->get_style_values( "linetype" ) ) ne "none";
   return 4 + textwidth( $self->label ) + 2*$has_border;
}

=head1 ACCESSORS

=cut

=head2 $label = $button->label

=cut

method label { $_label }

=head2 $button->set_label( $label )

Return or set the text to display in the button area.

=cut

method set_label
{
   ( $_label ) = @_;
   $self->redraw;
}

=head2 $on_click = $button->on_click

=cut

method on_click { $_on_click }

=head2 $button->set_on_click( $on_click )

Return or set the CODE reference to be called when the button area is clicked.

 $on_click->( $button )

=cut

method set_on_click
{
   ( $_on_click ) = @_;
}

=head2 $button->click

Behave as if the button has been clicked; running its C<on_click> handler.
This is provided for convenience of activating its handler programmatically
via other parts of code.

=cut

method click
{
   $_on_click->( $self );
}

# Activation by key should "flash" the button briefly on the screen as a
# visual feedback
method key_click
{
   $self->click;
   if( my $window = $self->window ) {
      $self->set_style_tag( active => 1 );
      $window->tickit->timer( after => 0.1, sub { $self->set_style_tag( active => 0 ) } );
   }
   return 1;
}

method _activate
{
   my ( $active ) = @_;
   $self->{active} = $active;
   $self->set_style_tag( active => $active );
}

=head2 $align = $button->align

=head2 $button->set_align( $align )

=head2 $valign = $button->valign

=head2 $button->set_valign( $valign )

Accessors for the horizontal and vertical alignment of the label text within
the button area. See also L<Tickit::WidgetRole::Alignable>.

=cut

use Tickit::WidgetRole::Alignable name => "align",  style => "h";
use Tickit::WidgetRole::Alignable name => "valign", style => "v";

method reshape
{
   my $win = $self->window or return;
   my $lines = $win->lines;
   my $cols  = $win->cols;

   my $width = textwidth $self->label;

   my $has_border = ( $self->get_style_values( "linetype" ) ) ne "none";

   my ( $lines_before, undef, $lines_after ) = $self->_valign_allocation( 1, $lines - (2 * $has_border) );
   my ( $cols_before, undef, $cols_after ) = $self->_align_allocation( $width + 2, $cols - 2 );

   $self->{label_line} = $lines_before + $has_border;
   $self->{label_col}  = $cols_before + 2;
   $self->{label_end}  = $cols_before + $width + 2;

   $win->cursor_at( $self->{label_line}, $self->{label_col} );
}

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   my $win = $self->window or return;
   my $lines = $win->lines;
   my $cols  = $win->cols;

   my ( $linetype, $marker_left, $marker_right ) =
      $self->get_style_values(qw( linetype marker_left marker_right ));

   my $linestyle = $linetype eq "single" ? LINE_SINGLE :
                   $linetype eq "double" ? LINE_DOUBLE :
                   $linetype eq "thick"  ? LINE_THICK  :
                   undef;

   if( defined $linestyle ) {
      $rb->hline_at( 0,        0, $cols-1, $linestyle );
      $rb->hline_at( $lines-1, 0, $cols-1, $linestyle );
      $rb->vline_at( 0, $lines-1, 0,       $linestyle );
      $rb->vline_at( 0, $lines-1, $cols-1, $linestyle );

      foreach my $line ( $rect->linerange( 1, $lines-2 ) ) {
         $rb->erase_at( $line, 1, $cols-2 );
      }
   }
   else {
      foreach my $line ( $rect->linerange( 0, $lines-1 ) ) {
         $rb->erase_at( $line, 0, $cols );
      }
   }

   $rb->text_at( $self->{label_line}, $self->{label_col} - 2, $marker_left );
   $rb->text_at( $self->{label_line}, $self->{label_end}, $marker_right );

   $rb->text_at( $self->{label_line}, $self->{label_col}, $self->label );
}

method on_mouse
{
   my ( $args ) = @_;

   my $type = $args->type;
   my $button = $args->button;

   return if $type eq "wheel" or $button != 1;

   if( $type eq "press" ) {
      $self->_activate( 1 );
   }
   elsif( $type eq "drag_start" ) {
      $self->{dragging_on_self} = 1;
   }
   elsif( $type eq "drag_stop" ) {
      $self->{dragging_on_self} = 0;
   }
   elsif( $type eq "drag" ) {
      # TODO: This could be neater with an $arg->srcwin
      $self->_activate( 1 ) if $self->{dragging_on_self} and !$self->{active};
   }
   elsif( $type eq "drag_outside" ) {
      $self->_activate( 0 ) if $self->{active};
   }
   elsif( $type eq "release" ) {
      if( $self->{active} ) {
         $self->_activate( 0 );
         $self->click;
      }
   }

   return 1;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
