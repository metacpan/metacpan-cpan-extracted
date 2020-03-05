package HelloWorldWidget;
use base 'Tickit::Widget';

sub lines {  1 }
sub cols  { 12 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );
   $rb->text_at( 0, 0, "Hello, world" );
}

1;
