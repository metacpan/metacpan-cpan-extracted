package Algorithm::Line::Bresenham::C;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'all' => [ qw(circle line) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.1';

bootstrap Algorithm::Line::Bresenham::C $VERSION;

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::Line::Bresenham::C - it is a C version Algorithm::Line::Bresenham to speed up a bit.

=head1 SYNOPSIS

 use Algorithm::Line::Bresenham::C qw/line/;
 my @points = line(3,3 => 5,0);
    # returns the list: [3,3], [4,2], [4,1], [5,0]

=head1 DESCRIPTION

Bresenham is one of the canonical line drawing algorithms for pixellated grids.
Given a start and an end-point, Bresenham calculates which points on the grid
need to be filled to generate the line between them.

Googling for 'Bresenham', and 'line drawing algorithms' gives some good
overview.  The code here takes its starting point from Mark Feldman's Pascal
code in his article I<Bresenham's Line and Circle Algorithms> at
L<http://www.gamedev.net/reference/articles/article767.asp>.

=head1 FUNCTIONS

=head2 C<line>

 line ($from_y, $from_x => $to_y, $to_x);

Generates a list of all the intermediate points.  This is returned as a list
of array references.

=head2 C<circle>

    my @points = circle ($y, $x, $radius)

Returns the points to draw a circle with

=head1 SEE ALSO

=over 8

=item Algorithm::Line::Bresenham

The original pure perl version.

=head1 AUTHOR and LICENSE

Lilo Huang, kenwu@cpan.org

Copyright (c) 2008 Lilo Huang. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut