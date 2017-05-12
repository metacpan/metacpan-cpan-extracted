package Data::Turtle;
our $AUTHORITY = 'cpan:GENE';

use Moo;
use POSIX qw( ceil );

our $VERSION = '0.0104';

use constant K => 3.14159265358979323846 / 180;


sub _init_x {
    my $self = shift;
    return $self->width / 2;
}

sub _init_y {
    my $self = shift;
    return $self->height / 2;
}

sub _init_heading {
    my $self = shift;
    return -90 % 360;
}


has width => (
    is => 'rw',
    default => sub { 500 },
);
has height => (
    is => 'rw',
    default => sub { 500 },
);


has x => (
    is => 'rw',
    lazy => 1,
    builder => \&_init_x,
);
has y => (
    is => 'rw',
    lazy => 1,
    builder => \&_init_y,
);
has heading => (
    is => 'rw',
    builder => \&_init_heading,
);


has pen_status => (
    is => 'rw',
    default => sub { 1 }, # Pen down
);
has pen_color => (
    is => 'rw',
    default => sub { 'black' },
);
has pen_size => (
    is => 'rw',
    default => sub { 1 },
);


sub home {
    my $self = shift;
    $self->x( $self->_init_x );
    $self->y( $self->_init_y );
    $self->heading( $self->_init_heading );
}


sub pen_up {
    my $self = shift;
    $self->pen_status(0);
}


sub pen_down {
    my $self = shift;
    $self->pen_status(1);
}


sub turn {
    my $self = shift;
    my $degrees = shift // 0;
    $self->heading( ( $self->heading + $degrees ) % 360 );
}


sub right {
    my $self = shift;
    $self->turn(@_);
}


sub left {
    my $self = shift;
    my $degrees = shift // 0;
    $self->heading( ( $self->heading - $degrees ) % 360 );
}


sub position {
    my $self = shift;
    return ceil($self->x), ceil($self->y);
}


sub get_state {
    my $self = shift;
    return
        ceil($self->x),
        ceil($self->y),
        $self->heading,
        $self->pen_status,
        $self->pen_color,
        $self->pen_size;
}


sub set_state {
    my $self = shift;
    my ( $x, $y, $heading, $pen_status, $pen_color, $pen_size ) = @_;
    $self->x($x);
    $self->y($y);
    $self->heading($heading);
    $self->pen_status($pen_status);
    $self->pen_color($pen_color);
    $self->pen_size($pen_size);
}


sub forward {
    my $self = shift;
    my $step = shift // 1;

    my $x = $step * cos( $self->heading * K );
    my $y = $step * sin( $self->heading * K );

    my $xo = $self->x;
    my $yo = $self->y;

    $self->x( $x + $xo );
    $self->y( $y + $yo );

    if ( $self->pen_status == 1 ) {
        return
            ceil($xo), ceil($yo),
            ceil($self->x), ceil($self->y),
            $self->pen_color, $self->pen_size;
    }
}


sub backward {
    my $self = shift;
    my $step = shift;
    $self->forward( - $step )
}


sub mirror {
    my $self = shift;
    $self->heading( $self->heading * -1 );
}


sub goto {
    my $self = shift;
    my ( $x, $y ) = @_;

    my $xo = $self->x;
    my $yo = $self->y;

    $self->x($x);
    $self->y($y);

    if ( $self->pen_status == 1 ) {
        return
            ceil($xo), ceil($yo),
            ceil($self->x), ceil($self->y),
            $self->pen_color, $self->pen_size;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Turtle

=head1 VERSION

version 0.0104

=head1 SYNOPSIS

  use Data::Turtle;
  my $turtle = Data::Turtle->new;
  $turtle->pen_up;
  $turtle->turn(45);
  $turtle->forward(10);
  $turtle->goto(100, 100);
  $turtle->mirror;
  $turtle->backward(10);
  $turtle->pen_down;
  my ($x, $y, $heading, $status, $color, $size) = $turtle->get_state;
  $turtle->set_state($x, $y, $heading, $status, $color, $size);
  for my $i (1 .. 4) {
      my @line = $turtle->forward(50);
      # If there is a line and the pen is down, draw it!
      $turtle->right(90);
  }

=head1 DESCRIPTION

This module enables basic turtle movement and state operations without requiring
any particular graphics package.

The methods don't draw anything per se.  They set or output coordinates and
values for line drawing by your favorite graphics package.

Please see the F<eg/> distribution directory for example code, with L<GD> and
L<Imager>.

=head1 NAME

Turtle - Turtle Movement and State Operations

=head1 METHODS

=head2 new

  Data::Turtle->new();
  Data::Turtle->new(
    width      => $width,
    height     => $height,
    x          => $x0,
    y          => $y0,
    heading    => $heading,
    pen_status => $pen_status,
    pen_color  => $pen_color,
    pen_size   => $pen_size,
  );

Return a C<Data::Turtle> object.

Attributes:

=over 4

=item * width, height

Drawing surface dimensions.  Defaults:

  width  = 500
  height = 500

=back

=over 4

=item * x, y, heading

Coordinate parameters.  Defaults:

  x       = width / 2
  y       = height / 2
  heading = 0 (degrees)

=back

=over 4

=item * pen_status, pen_color, pen_size

Is the pen is up or down?  Default: 1 (down position)

Pen properties.  Defaults: pen_color = the string 'black', pen_size = 1 (pixel)

=back

=head2 home

  $turtle->home;

Move the turtle cursor to the starting x,y position and heading.

=head2 pen_up

  $turtle->pen_up;

Raise the pen head to stop drawing.

=head2 pen_down

  $turtle->pen_down;

Lower the pen head to begin drawing.

=head2 turn

  $turtle->right($degrees);

Set the heading to the given degrees.

=head2 right

  $turtle->right($degrees);

Turn to the right.

=head2 left

  $turtle->left($degrees);

Turn to the left.

=head2 position

  @pos = $turtle->position;

Return the current pen position as a list of the x and y values.

=head2 get_state

  @state = $turtle->get_state;

Return the following settings as a list:

 x, y, heading, pen_status, pen_color, pen_size

=head2 set_state

  $turtle->set_state( $x, $y, $heading, $pen_status, $pen_color, $pen_size );

Set the turtle state with the given parameters.

=head2 forward

  @line = $turtle->forward($steps);

Move forward the given number of steps.

=head2 backward

  @line = $turtle->backward($steps);

Move backward the given number of steps.

=head2 mirror

  $turtle->mirror;

Reflect the heading by multiplying by -1.

=head2 goto

  @line = $turtle->goto( $x, $y );

Move the pen to the given coordinate.

=head1 SEE ALSO

L<https://metacpan.org/source/YVESP/llg-1.07/Turtle.pm>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
