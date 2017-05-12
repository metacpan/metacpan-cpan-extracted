=head1 NAME

Algorithm::Line::Bresenham - simple pixellated line-drawing algorithm

=head1 SYNOPSIS

 use Algorithm::Line::Bresenham qw/line/;
 my @points = line(3,3 => 5,0);
    # returns the list: [3,3], [4,2], [4,1], [5,0]
 line(3,3 => 5,0,  \&draw_line);
    # calls draw_line on each point in turn

=head1 DESCRIPTION

Bresenham is one of the canonical line drawing algorithms for pixellated grids.
Given a start and an end-point, Bresenham calculates which points on the grid
need to be filled to generate the line between them.

Googling for 'Bresenham', and 'line drawing algorithms' gives some good
overview.  The code here takes its starting point from Mark Feldman's Pascal
code in his article I<Bresenham's Line and Circle Algorithms> at
L<http://www.gamedev.net/reference/articles/article767.asp>.

=head1 FUNCTIONS

=cut

package Algorithm::Line::Bresenham;
use strict; use warnings;
our $VERSION = 0.11;
use base 'Exporter';
our @EXPORT_OK = qw/line circle/;

=head2 C<line>

 line ($from_y, $from_x => $to_y, $to_x);

Generates a list of all the intermediate points.  This is returned as a list
of array references.

 line ($from_y, $from_x => $to_y, $to_x,  \&callback);

Calls the referenced function on each point in turn.  The callback could be
used to actually draw the point.  Returns the collated return values from the
callback.

=cut

sub line {
	my ($from_y, $from_x, $to_y, $to_x, $callback) = @_;
    $_ = int $_ for ($from_y, $from_x, $to_y, $to_x);
	my ($delta_y, $delta_x) = ($to_y-$from_y, $to_x-$from_x);
	my $dir = abs($delta_y) > abs($delta_x);
	my ($curr_maj, $curr_min, $to_maj, $to_min, $delta_maj, $delta_min) = 
		$dir ?
			($from_y, $from_x,  $to_y, $to_x,  $delta_y, $delta_x)
		:	($from_x, $from_y,  $to_x, $to_y,  $delta_x, $delta_y);
	my $inc_maj = sig($delta_maj);
	my $inc_min = sig($delta_min);
	($delta_maj, $delta_min) = (abs($delta_maj)+0, abs($delta_min)+0);
	my $d = (2 * $delta_min) - $delta_maj;
	my $d_inc1 = $delta_min * 2;
	my $d_inc2 = ($delta_min - $delta_maj) * 2;

	my @points;
	{
		my @point = 
			$dir ?
				($curr_maj, $curr_min)
			:	($curr_min, $curr_maj);
		push @points, 
			defined $callback ?
				$callback->(@point)
				: [@point];

		last if $curr_maj == $to_maj;
		$curr_maj += $inc_maj;
		if ($d < 0) {
			$d        += $d_inc1;
		} else {
			$d        += $d_inc2;
			$curr_min += $inc_min;
		}
		redo;
	}
	return @points;
}

=head2 C<circle>

    my @points = circle ($y, $x, $radius)

Returns the points to draw a circle with

=cut

sub circle {
	my ($y, $x, $radius) = @_;
	my ($curr_x, $curr_y) = (0, $radius);
	my $d = 3 - (2 * $radius);
	my @points;

	{
		push @points, [$y + $curr_y, $x + $curr_x];
		push @points, [$y + $curr_y, $x - $curr_x];
		push @points, [$y - $curr_y, $x + $curr_x];
		push @points, [$y - $curr_y, $x - $curr_x];
		push @points, [$y + $curr_x, $x + $curr_y];
		push @points, [$y + $curr_x, $x - $curr_y];
		push @points, [$y - $curr_x, $x + $curr_y];
		push @points, [$y - $curr_x, $x - $curr_y];
		last if $curr_x >= $curr_y;
		if ($d < 0) {
			$d += (4 * $curr_x) + 6;
		} else {
			$d += 4 * ($curr_x - $curr_y) + 10;
			$curr_y -= 1;
		}
		$curr_x++;
		redo;
	}
	return @points;
}


sub sig {
	# returns: +1, 0, -1 depending on sign
	$_[0] or return 0;
	return abs($_[0]) == $_[0] ? 1 : -1;
}
###
1;

__END__

=head1 TODO and BUGS

None currently.

=head1 THANKS

Patches for the circle algorithm and a float value bug contributed by Richard Clamp, thanks!

=head1 AUTHOR and LICENSE

osfameron, osfameron@cpan.org

Copyright (c) 2004-2006 osfameron. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
