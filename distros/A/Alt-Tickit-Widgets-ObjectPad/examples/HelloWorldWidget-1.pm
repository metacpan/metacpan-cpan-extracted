use Object::Pad 0.08;

class HelloWorldWidget
   extends Tickit::Widget;

method lines {  1 }
method cols  { 12 }

method render_to_rb
{
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );
   $rb->text_at( 0, 0, "Hello, world" );
}

1;
