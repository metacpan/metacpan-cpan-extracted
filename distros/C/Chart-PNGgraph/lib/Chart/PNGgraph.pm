#==========================================================================
#              Copyright (c) 1995-1998 Martien Verbruggen
#              Copyright (c) 1999 Steve Bonds
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph.pm
#
#	Description:
#       Module to create graphs from a data set, outputting
#		PNG format graphics.
#
#		Package of a number of graph types:
#		Chart::PNGgraph::bars
#		Chart::PNGgraph::lines
#		Chart::PNGgraph::points
#		Chart::PNGgraph::linespoints
#		Chart::PNGgraph::area
#		Chart::PNGgraph::pie
#		Chart::PNGgraph::mixed
#
# $Id: PNGgraph.pm,v 1.1.1.1.2.7.2.6 2000/04/09 00:13:18 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph;

use strict;
use Carp;

use GD::Graph;
use Chart::PNGgraph::Convert;

$Chart::PNGgraph::VERSION = '1.21';
@Chart::PNGgraph::ISA = qw(GD::Graph);

# Old plot returned PNG data. GD::Graph::plot returns GD data
sub _old_plot
{
	my $self = shift;
	my $gd   = shift;

	for ($self->export_format)
	{
		/^gif$/ and 
			return Chart::PNGgraph::Convert::gif2png($gd->gif);

		/^png$/ and 
			return $gd->png;

		croak 'Cannot deal with GD export format. Please contact author';
	}
}

sub plot_to_png # ("file.png", \@data)
{
	my $self = shift;
	my $file = shift;
	my $data = shift;
	local(*PLOT);
	my $img_data;

	$img_data = $self->plot($data) or
		croak "GIFgraph::plot_to_png: Cannot get image data";

	open (PLOT,">$file") or 
		carp "Cannot open $file for writing: $!", return;
	binmode PLOT;
	print PLOT $img_data;
	close(PLOT);
}

$Chart::PNGgraph::VERSION;

__END__

=head1 NAME

Chart::PNGgraph - Graph Plotting Module (deprecated)

=head1 SYNOPSIS

use Chart::PNGgraph::moduleName;

=head1 DESCRIPTION

B<Chart::PNGgraph> is a I<perl5> module to create PNG output
for a graph.

Chart::PNGgraph is nothing more than a wrapper around GD::Graph, and its
use is deprecated. It only exists for backward compatibility. The
documentation for all the functionality can be found in L<GD::Graph>.

This module should work with all versions of GD, but it has only been
tested with version 1.19 and above. Version 1.19 is the last version
that produces GIF output, and requires a conversion step. The default
distribution of Chart::PNGgraph uses Image::Magick for this. If you'd
like to use something else, please replace the sub png2gif in
Chart::PNGgraph::Convert with something more to your liking.

=head1 NOTES

Note that if you use Chart::PNGgraph with a GD version 1.19 or lower
that any included logos will have to be in the GIF format. The only time
that PNG comes into play is _after_ GD has done its work, and the GIF
gets converted to PNG. There are no plans to change that behaviour; it's
too much work, and you should really be upgrading to a version of GD
that produces PNG directly.

=head1 SEE ALSO

GD::Graph(3), GIFgraph(3).

=head1 AUTHOR

Martien Verbruggen
ported to GD 1.20+ (PNG) by Steve Bonds

=head2 Contact info

for Chart::PNGgraph questions:
email: sbonds@agora.rdrop.com

for GIFgraph or GD::Graph questions:
email: mgjv@comdyn.com.au

=head2 Copyright

Copyright (c) 1999 Steve Bonds
Copyright (c) 1995-1999 Martien Verbruggen.
All rights reserved.  This package is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut


