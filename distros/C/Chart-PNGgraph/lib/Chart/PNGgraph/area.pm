#==========================================================================
#			   Copyright (c) 1995-2000 Martien Verbruggen
#--------------------------------------------------------------------------
#
#	Name:
#		Chart::PNGgraph::area.pm
#
# $Id: area.pm,v 1.1.1.1.2.2.2.1 2000/04/05 02:45:37 sbonds Exp $
#
#==========================================================================

package Chart::PNGgraph::area;
use strict;
use Chart::PNGgraph;
use GD::Graph::area;
@Chart::PNGgraph::area::ISA = qw(GD::Graph::area Chart::PNGgraph);

sub plot 
{ 
	my $self = shift;
	my $gd   = $self->SUPER::plot(@_);
	$self->_old_plot($gd);
}

1;
