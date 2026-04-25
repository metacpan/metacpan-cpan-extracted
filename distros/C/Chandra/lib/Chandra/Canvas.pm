package Chandra::Canvas;

use strict;
use warnings;

our $VERSION = '0.24';

use Chandra;

1;

__END__

=head1 NAME

Chandra::Canvas - 2D graphics for Chandra applications

=head1 SYNOPSIS

    use Chandra::App;
    use Chandra::Canvas;

    my $app = Chandra::App->new(title => 'Canvas Demo');
    my $canvas = Chandra::Canvas->new({
        width  => 800,
        height => 600,
        id     => 'gameCanvas',
    });

    # Draw shapes
    $canvas->fill_style('#ff0000')
           ->fill_rect(100, 100, 50, 50)
           ->fill_style('#00ff00')
           ->fill_circle(200, 200, 30)
           ->flush;

    $app->run;

=head1 DESCRIPTION

Chandra::Canvas provides a hardware-accelerated 2D graphics API for building
games and interactive applications. It wraps the HTML5 Canvas API through
Chandra's webview backend, with XS-accelerated command batching for optimal
performance.

All drawing methods return C<$self> for method chaining.

=head1 CONSTRUCTOR

=head2 new(\%options)

Create a new canvas instance.

    my $canvas = Chandra::Canvas->new({
        width  => 800,      # Canvas width in pixels (default: 800)
        height => 600,      # Canvas height in pixels (default: 600)
        id     => 'myCanvas', # Element ID (auto-generated if not provided)
        style  => 'border: 1px solid black',  # Optional CSS style
        class  => 'game-canvas',              # Optional CSS class
    });

=head1 ACCESSORS

=head2 width()

    my $w = $canvas->width;
    $canvas->width(1024);

Get or set the canvas width.

=head2 height()

    my $h = $canvas->height;
    $canvas->height(768);

Get or set the canvas height.

=head2 id()

    my $id = $canvas->id;

Get the canvas element ID.

=head1 STYLE METHODS

=head2 fill_style($color)

Set the fill color for subsequent fill operations.

    $canvas->fill_style('#ff0000');       # Hex color
    $canvas->fill_style('rgb(255,0,0)');  # RGB
    $canvas->fill_style('rgba(255,0,0,0.5)'); # RGBA

=head2 stroke_style($color)

Set the stroke color for subsequent stroke operations.

    $canvas->stroke_style('#0000ff');

=head2 line_width($width)

Set the line width for stroke operations.

    $canvas->line_width(2);

=head2 line_cap($style)

Set the line cap style: 'butt', 'round', or 'square'.

    $canvas->line_cap('round');

=head2 line_join($style)

Set the line join style: 'miter', 'round', or 'bevel'.

    $canvas->line_join('round');

=head2 miter_limit($limit)

Set the miter limit ratio for line joins.

    $canvas->miter_limit(10);

=head2 global_alpha($alpha)

Set global transparency (0.0 - 1.0).

    $canvas->global_alpha(0.5);

=head2 global_composite_operation($operation)

Set the compositing operation. Common values:

    'source-over'      # Default, draw over existing
    'source-atop'      # Draw only where overlapping
    'destination-over' # Draw behind existing
    'lighter'          # Additive blending
    'xor'              # XOR blend mode

    $canvas->global_composite_operation('lighter');

=head1 DRAWING METHODS

=head2 clear()

Clear the entire canvas.

    $canvas->clear;

=head2 fill_rect($x, $y, $width, $height)

Draw a filled rectangle.

    $canvas->fill_rect(10, 10, 100, 50);

=head2 stroke_rect($x, $y, $width, $height)

Draw a rectangle outline.

    $canvas->stroke_rect(10, 10, 100, 50);

=head2 clear_rect($x, $y, $width, $height)

Clear a rectangular area.

    $canvas->clear_rect(10, 10, 100, 50);

=head2 fill_circle($x, $y, $radius)

Draw a filled circle.

    $canvas->fill_circle(100, 100, 50);

=head2 stroke_circle($x, $y, $radius)

Draw a circle outline.

    $canvas->stroke_circle(100, 100, 50);

=head1 PATH METHODS

=head2 begin_path()

Start a new path.

    $canvas->begin_path;

=head2 close_path()

Close the current subpath.

    $canvas->close_path;

=head2 move_to($x, $y)

Move the pen to a new position without drawing.

    $canvas->move_to(50, 50);

=head2 line_to($x, $y)

Draw a line from the current position to the specified point.

    $canvas->line_to(150, 150);

=head2 arc($x, $y, $radius, $start_angle, $end_angle, $counterclockwise)

Draw an arc.

    $canvas->arc(100, 100, 50, 0, 3.14159);

=head2 arc_to($x1, $y1, $x2, $y2, $radius)

Draw an arc connected to the previous point with tangent lines.

    $canvas->move_to(50, 50)
           ->arc_to(100, 50, 100, 100, 20);  # Rounded corner

=head2 bezier_curve_to($cp1x, $cp1y, $cp2x, $cp2y, $x, $y)

Draw a cubic Bezier curve.

    $canvas->move_to(50, 50)
           ->bezier_curve_to(100, 0, 150, 100, 200, 50);

=head2 quadratic_curve_to($cpx, $cpy, $x, $y)

Draw a quadratic Bezier curve.

    $canvas->move_to(50, 50)
           ->quadratic_curve_to(100, 0, 150, 50);

=head2 rect($x, $y, $width, $height)

Add a rectangle to the current path.

    $canvas->rect(10, 10, 100, 50);

=head2 fill()

Fill the current path.

    $canvas->fill;

=head2 stroke()

Stroke the current path.

    $canvas->stroke;

=head2 clip()

Set the current path as the clipping region.

    $canvas->begin_path
           ->rect(50, 50, 100, 100)
           ->clip;
    # Further drawing is clipped to this region

=head1 STATE METHODS

=head2 save()

Save the current drawing state (styles, transforms) onto the stack.

    $canvas->save;

=head2 restore()

Restore the most recently saved drawing state.

    $canvas->restore;

=head1 TRANSFORM METHODS

=head2 translate($x, $y)

Move the canvas origin.

    $canvas->translate(100, 100);

=head2 rotate($angle)

Rotate the canvas around the origin (angle in radians).

    $canvas->rotate(0.785398);  # 45 degrees

=head2 scale($x, $y)

Scale the canvas.

    $canvas->scale(2, 2);  # Double size

=head2 transform($a, $b, $c, $d, $e, $f)

Multiply the current transformation matrix by the given matrix.

    # Skew transformation
    $canvas->transform(1, 0.5, 0.5, 1, 0, 0);

=head2 set_transform($a, $b, $c, $d, $e, $f)

Reset and set the transformation matrix directly.

    # Set identity matrix
    $canvas->set_transform(1, 0, 0, 1, 0, 0);

=head2 reset_transform()

Reset the transformation matrix to identity.

    $canvas->reset_transform;

=head1 CONVENIENCE METHODS

Helper methods for common drawing operations.

=head2 line($x1, $y1, $x2, $y2)

Draw a single line between two points.

    $canvas->line(10, 10, 100, 100);

=head2 polygon($points)

Draw a polygon outline from an arrayref of [x, y] pairs.

    $canvas->polygon([[50, 0], [100, 50], [50, 100], [0, 50]]);  # Diamond

=head2 fill_polygon($points)

Fill a polygon from an arrayref of [x, y] pairs.

    $canvas->fill_polygon([[50, 0], [100, 50], [50, 100], [0, 50]]);

=head2 rounded_rect($x, $y, $width, $height, $radius)

Draw a rounded rectangle outline.

    $canvas->rounded_rect(10, 10, 100, 50, 10);

=head2 fill_rounded_rect($x, $y, $width, $height, $radius)

Fill a rounded rectangle.

    $canvas->fill_rounded_rect(10, 10, 100, 50, 10);

=head1 BUFFER METHODS

=head2 flush()

Send all buffered drawing commands to the canvas and clear the buffer.
Call this once per frame after all drawing is complete.

    $canvas->clear
           ->fill_style('#f00')
           ->fill_rect(0, 0, 100, 100)
           ->flush;

=head2 render()

Generate the HTML for the canvas element.

    my $html = $canvas->render;

=head1 PERFORMANCE

Chandra::Canvas uses command batching to minimize JavaScript interop overhead.
Drawing commands are buffered in Perl (using XS) and sent as a single batch
when C<flush()> is called.

For optimal performance:

=over 4

=item *

Call C<flush()> once per frame, not after each draw call

=item *

Minimize state changes (fill_style, transforms)

=item *

Use C<save()>/C<restore()> for isolated state changes

=back

=head1 SEE ALSO

L<Chandra>, L<Chandra::App>, L<Chandra::Element>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
