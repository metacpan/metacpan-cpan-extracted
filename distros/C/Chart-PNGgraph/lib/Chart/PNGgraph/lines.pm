#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::lines.pm
#
# $Id: lines.pm,v 1.1.1.1.2.2.2.1 2000/04/05 02:45:37 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph::lines;
use strict;
use Chart::PNGgraph;
use GD::Graph::lines;
@Chart::PNGgraph::lines::ISA = qw(GD::Graph::lines Chart::PNGgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
