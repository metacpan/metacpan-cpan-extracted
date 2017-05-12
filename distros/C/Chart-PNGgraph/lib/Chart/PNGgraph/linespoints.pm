#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::linespoints.pm
#
# $Id: linespoints.pm,v 1.1.1.1.2.2.2.1 2000/04/05 02:45:37 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph::linespoints;
use strict;
use Chart::PNGgraph;
use GD::Graph::linespoints;
@Chart::PNGgraph::linespoints::ISA = qw(GD::Graph::linespoints Chart::PNGgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
