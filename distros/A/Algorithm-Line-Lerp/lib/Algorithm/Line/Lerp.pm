package Algorithm::Line::Lerp;
our $VERSION = '0.02';
use Exporter 'import';
our @EXPORT_OK = qw(bline line);
require XSLoader;
XSLoader::load( 'Algorithm::Line::Lerp', $VERSION );
1;
__END__
=head1 NAME

Algorithm::Line::Lerp - 2D grid line drawing via linear interpolation

=head1 SYNOPSIS

    use Algorithm::Line::Lerp 'line';

    my $points = line( [0,0], [2,11] );
    for my $p (@$points) { ...

=head1 DESCRIPTION

This module offers both Bresenham and linear interpolation line drawing
algorithms. See C<eg/bench> for a comparison.

Caveats of B<line> include potential floating point portability problems
or "aesthetic issues" depending on how C<lround> in B<line> behaves.
B<bline> is probably more predictable, but may be slower.

=head1 FUNCTIONS

These are not exported by default.

=over 4

=item B<bline> I<p1> I<p2>

Same interface as B<line> but uses the traditional Bresenham algorithm.

Since version 0.02.

=item B<line> I<p1> I<p2>

Given two points (array references of x, y values) returns an array
reference of the points between the two points using linear
interpolation. This may simply be a copy of point I<p1> (when I<p1> and
I<p2> are equal) or a longer list of points.

=back

=head1 SEE ALSO

L<Algorithm::Line::Bresenham> - pure perl, plus support for other shapes.

L<Game::Xomb> has a custom Bresenham implementation that deals with
various gameplay elements.

L<https://www.redblobgames.com/grids/line-drawing.html>

=head1 AUTHOR

Jeremy Mates, C<< <jmates@thrig.me> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
